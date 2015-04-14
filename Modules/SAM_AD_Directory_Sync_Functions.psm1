Function EliminateSuffixFromLastName($LastName) {
	$temp1 = $LastName.Split(",")
	If ( $temp1.length -gt 1 ) {
		$LastName = $temp1[0]
	} Else {
		$temp2 = $LastName.Split(" ")
		If ( $temp2.length -gt 1 ) {
			$LastName = $temp2[0]
		}
	}
	
	return $LastName
}

#This function checks to see if a user exists.
# If it does exist, it updates it's information and moves it to the correct OU
# If it does not exist, it creates the user with the correct info and in the correct OU
Function CreateOrUpdateUsers($Users) {
	$Objs =@() #blank array to hold output for CSV
	ForEach($User in $Users){
        # If the user already exists, check for any updates and if there are any, make them
		If(dsquery user -samid $User.sAMAccountName) {
            $ComparisonUser = Get-ADUser $User.sAMAccountName -properties "*"
            If (Compare-Object -ReferenceObject $ComparisonUser -DifferenceObject $User -Property SamAccountName,GivenName,SurName,DisplayName,EmailAddress,UserPrincipalName,EmployeeId,Department,Organization,Path)
            {
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
            }
			
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

Function DisableUsersNotInSIS ($Users) {
    
}