$BasePath = "OU=Corp,DC=contoso,DC=com"

$OUList = Get-ADOrganizationalUnit -SearchBase $BasePath -Filter *
$ContainerList = Get-ADObject -SearchBase $BasePath -Filter 'ObjectClass -like "container"'

Foreach ($OU in $OUList){
    Write-Host "operating on $OU"
    $OU | Set-ADObject -ProtectedFromAccidentalDeletion $false
}

Foreach ($Container in $ContainerList){
    Write-Host "operating on $Container"
    $Container | Set-ADObject -ProtectedFromAccidentalDeletion $false
}


