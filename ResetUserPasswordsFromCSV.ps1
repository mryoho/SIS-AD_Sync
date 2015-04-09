Import-Module ActiveDirectory

Function SetUserPassword($Users, $ChangePasswordAtLogon, $PasswordNeverExpires, $CannotChangePassword) {
	$Objs = @()
	
	ForEach($User in $Users){
		If(dsquery user -samid $User.sAMAccountName) {
			$SecurePassword = $User.password | ConvertTo-SecureString -AsPlainText -Force
			#Set-ADAccountPassword -Identity $User.sAMAccountName -NewPassword $SecurePassword -Reset -PassThru
			Set-ADAccountControl -Identity $User.sAMAccountName -CannotChangePassword $CannotChangePassword -PasswordNeverExpires $PasswordNeverExpires
			Set-ADUser -Identity $User.sAMAccountName -ChangePasswordAtLogon $ChangePasswordAtLogon #$True #[bool]$ChangePasswordAtLogon
			net user $User.sAMAccountName $User.Password
			$Hash = @{
					sAMAccountName = $User.sAMAccountName
					#Grade = $User.ADAGrade
					DefaultPassword = $User.password
					DefaultPasswordSet = "True"
			}
			$Obj = New-Object -TypeName PSObject -Property $Hash
			$Objs += $Obj			
		} Else {
			$Hash = @{
					sAMAccountName = $User.sAMAccountName
					#Grade = $User.ADAGrade
					DefaultPassword = $User.password
					DefaultPasswordSet = "False"
			}
			$Obj = New-Object -TypeName PSObject -Property $Hash
			$Objs += $Obj			
		}
	}
	Return $Objs
}

Write-Output "
**************************************************************************
** Program Name: reset_passwords_from_csv_fromCSV
** Patrick Yoho - 1/26/2015
** Description: Use this program to update user passwords.
** This should be run on a Domain Controller.
** CSV Format: Your CSV must include a column whose first row is headed
** with 'sAMAccountName' and a column that is headed as 'password'.
************************************************************************** `n`n"

$FilePath = Read-Host "Enter the full path for your CSV"

$UserCannotChangePW = Read-Host "Users CANNOT change their passwords (enter 't' for true or 'f' for false; Default: False)"
If($UserCannotChangePW -eq 't') {
	$UserCannotChangePW = $true
} ElseIF($UserCannotChangePW -eq 'f') {
	$UserCannotChangePW = $false
} Else {
	Write-Output "Invalid Entry, Exiting"
	Exit
}

$UserPWNeverExpires = Read-Host "User passwords should never expire (enter 't' for true or 'f' for false; Default: False)"
If($UserPWNeverExpires -eq 't') {
	$UserPWNeverExpires = $true
} ElseIF($UserPWNeverExpires -eq 'f') {
	$UserPWNeverExpires = $false
} Else {
	Write-Output "Invalid Entry, Exiting"
	Exit
}

$UserMustChangePWAtLogon = Read-Host "Users must change their passwords next time they log on (enter 't' for true or 'f' for false; Default: True)"
If($UserMustChangePWAtLogon -eq 't') {
	$UserMustChangePWAtLogon = $true
} ElseIF($UserMustChangePWAtLogon -eq 'f') {
	$UserMustChangePWAtLogon = $false
} Else {
	Write-Output "Invalid Entry, Exiting"
	Exit
}

$UsersToSet = Import-CSV $FilePath

$Results = SetUserPassword $UsersToSet $UserMustChangePWAtLogon $UserPWNeverExpires $UserCannotChangePW

#Output Results to CSV
$ResultsFilePath = [string]$FilePath -replace "(.*)(\.csv)",'$1_PasswordUpdate_RESULTS$2'
$Results | Export-CSV $ResultsFilePath

