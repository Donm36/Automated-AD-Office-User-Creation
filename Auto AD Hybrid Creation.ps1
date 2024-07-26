Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Input Parameters"
$form.Size = New-Object System.Drawing.Size(500, 675)
$form.StartPosition = "CenterScreen"

# Create labels and text boxes for parameters
$controls = @{}

$fields = @{
    "First Name" = ""
    "Last Name" = ""
    "Name" = ""
    "UserPrincipalName" = ""
    "PrimarySmtpAddress Prefix" = ""
    "OU" = ""
    "SamAccountName" = ""
    "City" = ""
    "Title" = ""
    "Manager" = ""
    "Company" = ""
    "Department" = ""
    "StreetAddress" = ""
    "StateOrProvince" = ""
    "CountryOrRegion" = ""
    "Postalcode" = ""
    "DC Hostname" = ""
    "Source User" = ""
    "License Type" = ""
}

$yPos = 20
foreach ($labelText in $fields.Keys) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $labelText
    $label.Location = New-Object System.Drawing.Point(10, $yPos)
    $form.Controls.Add($label)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(150, $yPos)
    $textbox.Size = New-Object System.Drawing.Size(200, 20)
    $textbox.Text = $fields[$labelText]
    $form.Controls.Add($textbox)

    $controls[$labelText] = $textbox

    $yPos += 30
}

# Create OK button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(150, $yPos)
$okButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($okButton)

# Show the form
$form.ShowDialog()

# Retrieve the values from the text boxes
$params = @{}
foreach ($labelText in $controls.Keys) {
    $params[$labelText] = $controls[$labelText].Text
}

# Construct the Primary SMTP Address and Remote Routing Address
$primarySmtpAddress = "$($params["PrimarySmtpAddress Prefix"])@<Domain>.com"
$remoteRoutingAddress = "$($params["PrimarySmtpAddress Prefix"])@<Domain>.mail.onmicrosoft.com"

# Use the parameters in the script
$UserCredential = Get-Credential

Import-Module ActiveDirectory

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://<servername>/PowerShell/ -Credential $UserCredential

Import-PSSession $Session -DisableNameChecking

New-RemoteMailbox -Firstname $params["First Name"] -Lastname $params["Last Name"] -Name $params["Name"] `
-UserPrincipalName $params["UserPrincipalName"] -PrimarySmtpAddress $primarySmtpAddress `
-RemoteRoutingAddress $remoteRoutingAddress -OnPremisesOrganizationalUnit $params["OU"]

Set-User -Identity $params["Name"] -SamAccountName $params["SamAccountName"] -City $params["City"] `
-Title $params["Title"] -Manager $params["Manager"] -Company $params["Company"] `
-Department $params["Department"] -StreetAddress $params["StreetAddress"] `
-StateOrProvince $params["StateOrProvince"] -CountryOrRegion $params["CountryOrRegion"] `
-Postalcode $params["Postalcode"]

$DCHostname = $params["DC Hostname"]
$DCSession = New-PSSession -ComputerName $DCHostname -Credential $UserCredential

Invoke-Command -Session $DCSession -ScriptBlock {
    Start-ADSyncSyncCycle -PolicyType Delta
}

Start-Sleep -Seconds 60

$sourceUser = $params["Source User"]
$targetUser = $params["SamAccountName"]

$sourceGroups = Get-ADUser -Identity $sourceUser -Properties MemberOf | Select-Object -ExpandProperty MemberOf

foreach ($group in $sourceGroups) {
    Add-ADGroupMember -Identity $group -Members $targetUser
}

Write-Host "Group memberships copied from $sourceUser to $targetUser successfully."

Remove-PSSession -Session $DCSession
Remove-PSSession $Session


Connect-MgGraph
# Additional script to assign license
# Retrieve the SKU details for the license
$e33ku = Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -eq $params["License Type"] ` }

# Create an array containing the SPE_E3 SKU ID for license assignment
$addLicenses = @(
    @{ SkuId = $e33ku.SkuId }
)

# Define the user ID from the input form
$userId = $params["UserPrincipalName"]

# Set the usage location to United States and enable the user account
Update-MgUser -UserId $userId -UsageLocation "US" -AccountEnabled:$true

# Assign the SPE_E3 license to the specified user, and remove no licenses
Set-MgUserLicense -UserId $userId -AddLicenses $addLicenses -RemoveLicenses @()
