# This script works in conjunction with both hybrid Exchange, and Office 365 cloud. 

It will remote into a on-prem exchange server, provision a remote mailbox that syncs up with AD, runs a sync script on the DC you state, copies permissions from a user in AD and auto-assigns a license that you choose. Go to the following website to figure out which license you will need to state. https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference
After running the script, it will use a form to input the data which will auto-populate.

Lines #71 and #72 need to be adjusted to the domain name you want the emails to sync up too. 
Line #79 needs to have the domain name of the exchange server hardcoded as well. these are the only hardcoded variables of the script you need to adjust before using the form. 

If information for the Enterprise stays the same regarding address, city etc, you can write down the information into the strings and they will be hardcoded into the form fields moving forward.

This will fully automate your user creation and sync process. 

"UserPrincipalName" Needs to be the email you want the user to have moving forward.
"PrimarySmtpAddressPrefix" needs to be populated with the beginning of the email set before the @. 
"Source User" Copies permissions from an AD username that you specify. 


