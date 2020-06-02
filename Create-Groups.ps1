$CSVPath = ".\group-creation.csv"
$NameHeader = "Name"
$PathHeader = "Path"
$GroupCategoryHeader = "GroupCategory"
$GroupScopeHeader = "GroupScope"


# iterate through each entry of the csv
Import-Csv $CSVPath | ForEach-Object {

    # check if group already exists and skips that loop if it does
    if (Get-ADGroup -Identity $($_.$NameHeader) -ErrorAction SilentlyContinue) {
        return
    }

    # prompt action and create group
    Write-Host "Creating -Name $($_.$NameHeader) -Path $($_.$PathHeader) -GroupCategory $($_.$GroupCategoryHeader) -GroupScope $($_.$GroupScopeHeader)"
    New-ADGroup -Name $($_.$NameHeader) -Path $($_.$PathHeader) -GroupCategory $($_.$GroupCategoryHeader) -GroupScope $($_.$GroupScopeHeader)

    # check if existant, prompt if not
    if (! (Get-ADGroup -Identity $($_.$NameHeader) -ErrorAction SilentlyContinue)) {
        Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR : Group "$($_.$NameHeader)" was not created"
    }
}