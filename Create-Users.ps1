$UserCSVPath = ".\user-creation.csv"
$UsernameHeader = "SAMAccountName"
$Tier0Header = "Tier 0"
$Tier1Header = "Tier 1"
$Tier2Header = "Tier 2"

$CSVObject = Import-CSV -Path $UserCSVPath

$CSVObject | ForEach-Object {

    if ($_.$Tier0Header -eq $true) {
        $Username = "AT0_" + $_.$UsernameHeader
        New-ADUser -Path "OU=Users,OU=Tier 0,OU=Administration,OU=Corp,DC=CATERCARE,DC=LOCAL" -Name $Username -Enabled $false
        Write-Host "Created user $Username"
        Add-ADGroupMember -Identity 'ROLE_Tier 0 Admin' -Members $Username
    }

    if ($_.$Tier1Header -eq $true) {
        $Username = "AT1_" + $_.$UsernameHeader
        New-ADUser -Path "OU=Users,OU=Tier 1,OU=Administration,OU=Corp,DC=CATERCARE,DC=LOCAL" -Name $Username -Enabled $false
        Write-Host "Created user $Username"
        Add-ADGroupMember -Identity 'ROLE_Tier 1 Admin' -Members $Username
    }

    if ($_.$Tier2Header -eq $true) {
        $Username = "AT2_" + $_.$UsernameHeader
        New-ADUser -Path "OU=Users,OU=Tier 2,OU=Administration,OU=Corp,DC=CATERCARE,DC=LOCAL" -Name $Username -Enabled $false
        Write-Host "Created user $Username"
        Add-ADGroupMember -Identity 'ROLE_Tier 2 Admin' -Members $Username  
    }
}