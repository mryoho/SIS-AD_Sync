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