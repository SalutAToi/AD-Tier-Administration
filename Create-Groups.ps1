$CSVPath = ".\group-creation.csv"
$NameHeader = "Name"
$PathHeader = "Path"
$GroupCategoryHeader = "GroupCategory"
$GroupScopeHeader = "GroupScope"

function Test-Group ($GroupName) {
    
    $ErrorActionPreference = "silentlycontinue"
    $Group = Get-ADGroup -Identity $GroupName

    if ($Group -eq $null) {
        return $false
    }
    else {
        return $true
    }
}


# iterate through each entry of the csv
Import-Csv $CSVPath | ForEach-Object {

    # check if group already exists and skips that loop if it does
    if (Test-Group $_.$NameHeader) {
        Write-Host "$($_.$NameHeader) exists, skipping."
        return
    }

    # prompt action and create group
    Write-Host "Creating $($_.$NameHeader) at $($_.$PathHeader), category $($_.$GroupCategoryHeader), scope $($_.$GroupScopeHeader)"
    New-ADGroup -Name $($_.$NameHeader) -Path $($_.$PathHeader) -GroupCategory $($_.$GroupCategoryHeader) -GroupScope $($_.$GroupScopeHeader)

    # check if existant, prompt if not
    if (! (Test-Group $_.$NameHeader)) {
        Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR : Group $($_.$NameHeader) was not created"
    }
}