#Set up directories
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CSVsDir  = Join-Path -Path $ScriptDir -ChildPath CSVs

# Import email settings from config file
[xml]$ConfigFile = Get-Content "$ScriptDir\config.xml"

# Import Modules
Import-Module "$ScriptDir\Modules\join-object.psm1"
Import-Module "$ScriptDir\Modules\SAM_AD_Directory_Sync_Functions.psm1"
Import-Module ActiveDirectory

# Load CSVs
$Students = $ConfigFile.config.settings.FileNames.Students
$Students = Import-Csv "$CSVsDir\$Students"
$Staff = $ConfigFile.config.settings.FileNames.Staff
$Staff = Import-Csv "$CSVsDir\$Staff"
$Rosters = $ConfigFile.config.settings.FileNames.Rosters
$Rosters = Import-Csv "$CSVsDir\$Rosters"
$Classes = $ConfigFile.config.settings.FileNames.Classes
$Classes = Import-Csv "$CSVsDir\$Classes"
$Schools = $ConfigFile.config.settings.FileNames.Schools
$Schools = Import-Csv "$CSVsDir\$Schools"
$OrganizationalUnits = $ConfigFile.config.settings.FileNames.OrganizationalUnits
$OrganizationalUnits = Import-Csv "$CSVsDir\$OrganizationalUnits"

Function CreateStudentUserName($User) {
    return "$($User.First_Name.Substring(0,1).ToLower())$(EliminateSuffixFromLastName($User.Last_Name).ToLower())$($User.Student_ID.Substring(($User.Student_ID.length - 4), 4))"
}

Function CreateStudentPassword($User) {
    # Set Elementary Password Version for grades lower than 4 or for PK or K (62, and 64)
    If (([int]$User.grade_level -lt 5) -or ([int]$User.grade_level -gt 60)) {
        #08/01/2007
        $temp = $User.date_of_birth.split("/")
        return "$($temp[0])$($temp[1])$($User.First_Name.Substring(0,1).ToLower())"
    } 
    # Otherwise set password version for grades 5-12
    Else {
        return "$($User.Student_ID.Substring(($User.Student_ID.length - 7), 7))-$($User.First_Name.Substring(0,1).ToLower())"
    }
}

# Create Full Student Object
$Students = Join-Object -Left $Students -Right $OrganizationalUnits -Where {($args[0].school_id -eq $args[1].school_id) -and ($args[0].grade_level -eq $args[1].grade_level)} -LeftProperties "*" -RightProperties "Path" -Type OnlyIfInBoth
$Students = Join-Object -Left $Students -Right $Schools -Where {$args[0].school_id -eq $args[1].school_id} –LeftProperties "*" –RightProperties "school_name" -Type OnlyIfInBoth

ForEach ($Student in $Students){
    $Student.User_Name = CreateStudentUserName $Student
    $Student.Pass_Word = CreateStudentPassword $Student

    Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'SamAccountName' -Value $Student.user_name
    Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'Password' -Value $Student.pass_word
    Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'GivenName' -Value $Student.first_name
    Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'SurName' -Value $Student.last_name
    Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'DisplayName' -Value "$($Student.First_Name) $($Student.Last_Name)"
    Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'EmailAddress' -Value "$($Student.User_Name)@$($ConfigFile.config.DomainSettings.StudentDomain)"
    Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'UserPrincipalname' -Value "$($Student.User_Name)@$($ConfigFile.config.DomainSettings.ActiveDirectoryDomain)"
    Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'EmployeeID' -Value $Student.Student_ID.Substring(($Student.Student_ID.length - 7), 7)
    # Conditional Logic to replace the grade codes 62 and 64 with the grade name, "PK" and "K"
    If ($Student.grade_level -eq 62) {Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'Department' -Value "PK" }
    ElseIf ($Student.grade_level -eq 64) { Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'Department' -Value "K" }
    Else { Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'Department' -Value $Student.grade_level }
    Add-Member -InputObject $Student -MemberType "NoteProperty" -Name 'Organization' -Value $Student.school_name

}

$Students