MacADUtility

AppleScript (main.scpt) with custom Cocoa status applications and many bash scripts called from main.scpt for binding Macs to Genentech and Roche Active Directories (includes live migration of a local account to a mobile account)

Detailed Overview:

Here is a high-level overview of what is happening behind the scenes when you run the MacADUtility on a Genentech or Roche Mac:

* Ensures that the computer is plugged into power
* Verifies the Mac is on the Genentech or Roche LAN over wireless or ethernet, if not notifies the user to connect to RANGE or gConnect to proceed.
* Prompts for current local Mac password and then the Genentech or Roche domain credentials (verifies that both sets of credentials are valid)
* Backup of current user account details is created; backup account created with the user's current Mac password
* Checks for the installation of the CentrifyDC plug-in; uninstalls it if exists
* Based on the user’s AD information and image configuration it will automatically bind the system to the appropriate domain (GNE <Genentech>, NALA <Roche North America/Latin America>, EMEA <Roche Europe, Middle East, and Africa>, or ASIA <Asia>.) If the user information is unavailable, it will provide a pulldown with a list of domains to choose from.
* Binding is done with the following naming convention:  username-last6ssn@domain or username-last6en0macaddress@domain if serial number not set on logic board.  This happens in rare cases where a replacement logic board is not serialized.
* Renames the user account and home directory to match the domain username if does not 
* Deletes the local user account (performs a dscl . -delete /Users/old_username)
* Creates a new mobile account and caches credential upon successful validation against Active Directory on the respective domain
* Updates ownership of the home directory to match the domain username and new UID # from Active Directory
* Looks for files on hard drive owned by the old user and updates each applicable file to the domain username and UID #
* Updates the ownership and password of the user's login keychain 
* Sends a SUCCESS or FAILURE email to a distribution list 
*Displays a success screen with a RESTART button (informs user they will need to use the GNE username and password at the login screen)
* On login after reboot
if plugged into the network on campus - checks credentials against AD for login authorization
* if on wireless or off-site - checks against cached credentials for login authorization
Login, unlock from screen saver and any password authorization request thereafter (i.e. installing software) will now used live or cached AD credentials depending on networking connectivity (if the Mac can reach the respective Genentech or Roche domain)



