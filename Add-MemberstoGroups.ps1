# from a CSV file, this will add members to specific groups, one member at a time
$CSVPath = ".\group-membership.csv"
$GroupNameHeader = "group"
$AddtoGroupHeader = "addto"

Import-Csv $CSVPath | ForEach-Object {
    if (! (Get-ADGroup -Identity $($_.$GroupNameHeader))) {
        Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR : Group "$($_.$GroupNameHeader)" doesn't exist"
        Write-Host "Skipping adding $($_.$GroupNameHeader) to $($_.$AddtoGroupHeader)"
        return
    }
    if (! (Get-ADGroup -Identity $($_.$AddtoGroupHeader))) {
        Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR : Group "$($_.$AddtoGroupHeader)" doesn't exist"
        Write-Host "Skipping adding $($_.$GroupNameHeader) to $($_.$AddtoGroupHeader)"
        return
    }
    if ((Get-ADGroupMember -Identity $($_.$AddtoGroupHeader) | Select -ExpandProperty Name) -contains $($_.$GroupNameHeader) ) {
        Write-Host -ForegroundColor White -BackgroundColor Yellow "WARNING : Group "$($_.$GroupNameHeader)" is already a member of "$($_.$AddtoGroupHeader)
        Write-Host "Skipping adding $($_.$GroupNameHeader) to $($_.$AddtoGroupHeader)"
        return
    }


    Write-Host "Adding $($_.$GroupNameHeader) to $($_.$AddtoGroupHeader)"
    Add-ADGroupMember -Identity $($_.$AddtoGroupHeader) -Members $($_.$GroupNameHeader)
}