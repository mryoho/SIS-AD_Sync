Import-Module ActiveDirectory

#This function checks to see if a user exists.
# If it does exist, it updates it's information and moves it to the correct OU
# If it does not exist, it creates the user with the correct info and in the correct OU
Function CreateOrUpdateUsers($Users) {
	$Objs =@() #blank array to hold output for CSV
	ForEach($User in $Users){
		If(dsquery user -samid $User.sAMAccountName) {
			$HashOfParameters = @{
				Identity = $User.sAMAccountName
				givenName = $User.givenName
				surName = $User.surName
				displayName = $User.displayName
				emailAddress = $User.emailAddress
				userPrincipalName = $User.userPrincipalName
				employeeID = $User.employeeID
				department = $User.department
				organization = $User.organization
				enable = $True
			}
			Set-Aduser @HashOfParameters
			
			$HashOfParameters = @{
				TargetPath = $User.path
			}
			Get-ADUser $User.sAMAccountName | Move-ADObject @HashOfParameters
			
		} Else {
			#$SecurePassword = $User.password | ConvertTo-SecureString -AsPlainText -Force
			$HashOfParameters = @{
				sAMAccountName = $User.sAMAccountName
				givenName = $User.givenName
				name = $User.displayName
				surName = $User.surName
				displayName = $User.displayName
				emailAddress = $User.emailAddress
				userPrincipalName = $User.userPrincipalName
				path = $User.path
				employeeID = $User.employeeID
				department = $User.department
				organization = $User.organization
				accountPassword = $User.password | ConvertTo-SecureString -AsPlainText -Force
				enabled = $True
			}
			New-ADUser @HashOfParameters
			
			#Create the contents of a CSV that will be output of only the newly created users.
			#These users will need to be run through a password reset once they've been added
			#to Google Apps with Google Apps Directory Sync (GADS)
			$HashOfParameters.Add("password", $User.password)
			$Obj = New-Object -TypeName PSObject -Property $HashOfParameters
			$Objs += $Obj
			#trigger a password change so new default password is synced with Google Apps
			#won't work because user does not yet exist in google docs
			#net user $User.sAMAccountName $User.password
		}
	}
	Return $Objs
}

Function GetUserCreateOrUpdateResults($Users) {
	$OutputObjects = @()	#Array of results from get-aduser that will be saved as a CSV once returned
	
	ForEach($User in $Users) {
		#$HashOfParameters = @{
		#	Identity = $User.sAMAccountName
		#	Properties = "displayName,mail,employeeID,department,organization"
		#}
		#$HashOfParameters = @{
		#	Identity = "pyoho"
		#	Properties = "displayName, mail"
		#}
		#$Result = Get-ADUser @HashOfParameters
		$Result = Get-ADUser $User.sAMAccountName -Properties displayName,mail,employeeID,department,organization
		$HashOfOutput = @{
			sAMAccountName = $Result.sAMAccountName
			givenName = $Result.givenName
			surName = $Result.surName
			displayName = $Result.displayName
			emailAddress = $Result.mail
			userPrincipalName = $Result.userPrincipalName
			distinguishedName = $Result.distinguishedName
			employeeID = $Result.employeeID
			department = $Result.department
			organization = $Result.organization
			enabled = $Result.enabled
		}
		$OutputObject = New-Object -TypeName PSObject -Property $HashOfOutput
		$OutputObjects += $OutputObject
	}
	
	Return $OutputObjects
}

Function GetEmployeeID($Users) {
	ForEach($User in $Users){
		Get-ADUser -Identity $User.sAMAccountName -Properties 'employeeID'
	}
}

Write-Output "
**************************************************************************
** Program Name: Create_Or_Update_AD_Users_From_CSV
** Patrick Yoho - 2/10/2015
** DESCRIPTION: 
**   This program will read user information from a CSV and will updates
**   or create AD users such that the users in Active Directory match
**   the users in the CSV that is input into this program.
** REQUIRED INPUT:
**   A CSV file with the following columns:
**		sAMAccountName
**		givenName
**		surName
**		displayName
**		emailAddress
**		userPrincipalName
**		path
**		employeeID
**		department
**		organization
************************************************************************** `n`n"

# Read in and perform the create or update
$FilePath = Read-Host "Enter the full path for your CSV"

$UsersToCreateOrUpdate = Import-CSV $FilePath

$CreatedUsers = CreateOrUpdateUsers $UsersToCreateOrUpdate

#Output List of CreatedUsers to CSV
$CreatedUsersFilePath = [string]$FilePath -replace "(.*)(\.csv)",'$1_CreateOrUpdateUsers_NEWUSERS$2'
IF($CreatedUsers) {
	$CreatedUsers | Export-CSV $CreatedUsersFilePath
}

# Retrieve the values from AD and output the info to a CSV for the user to check
$Results = GetUserCreateOrUpdateResults $UsersToCreateOrUpdate

#Output Results to CSV
$ResultsFilePath = [string]$FilePath -replace "(.*)(\.csv)",'$1_CreateOrUpdateUsers_RESULTS_ALLUSERS$2'
$Results | Export-CSV $ResultsFilePath
