Function EliminateSuffix($LastName) {
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

Function EliminateSuffixForUserSet($Users) {
	$Objs =@() #blank array to hold output for CSV
	ForEach($User in $Users){
		
		$User.User_Name = "$($User.First_Name.Substring(0,1).ToLower())$(EliminateSuffix($User.Last_Name).ToLower())$($User.Student_ID.Substring(($User.Student_ID.length - 4), 4))"
		
			#Create the contents of a CSV that will be output of only the newly created users.
			#These users will need to be run through a password reset once they've been added
			#to Google Apps with Google Apps Directory Sync (GADS)
			#$HashOfParameters.Add("password", $User.password)
			#$Obj = New-Object -TypeName PSObject -Property $HashOfParameters
			#$Objs += $Obj
			#trigger a password change so new default password is synced with Google Apps
			#won't work because user does not yet exist in google docs
			#net user $User.sAMAccountName $User.password
	}
	Return $Objs
}