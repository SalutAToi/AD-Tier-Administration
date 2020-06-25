$GPOAdminLevelGroups = @{
    Tier0Global = "GPO_Tier 0 Global GPO_MOD";
    Tier0PKIServers = "GPO_Tier 0 PKI SRV_MOD";
    Tier0PrivilegedAccessWorkstations = "GPO_Tier 0 Privileged Access Workstations_MOD";
    Tier1AllServers = "GPO_Tier 1 All SRV_MOD";
    Tier1ADMUsers = "GPO_Tier 1 ADM Users_MOD";
    Tier1ServiceUsers = "GPO_Tier 1 Service_MOD";
    Tier1NetServers = "GPO_Tier 1 Network SRV_MOD";
    Tier1AppServers = "GPO_Tier 1 Application SRV_MOD";
    Tier1FileServers = "GPO_Tier 1 File SRV_MOD";
    Tier1UpdateServers = "GPO_Tier 1 Update SRV_MOD";
    Tier1TermServers = "GPO_Tier 1 Terminal SRV_MOD";
    Tier1PrivilegedAccessWorkstations = "GPO_Tier 1 Privileged Access Workstations_MOD";
    Tier2Workstations = "GPO_Tier 2 Workstations_MOD";
    CorporateUsers = "GPO_Corporate Users_MOD"
}

$CSVNameHeader = "GPOName"
$CSVAdminLevelHeader = "AdminLevel"

function Check-Argument ($arg) {

    if ($arg -ne $null) {
        if ((Test-Path -Path $arg) -eq $true) {
            Write-Host "You entered a valid path as an argument, using file mode`n"
            $Mode = "file"
        }
        else {
            Write-Host "The supplied path is invalid.`n"
            exit
        }
    }
    else {
        Write-Host "Using interactive mode as there is no path supplied.`n"
        $Mode = "interactive"
    }
    return $Mode
}

function Change-GPOPermission ($GPOName, $GPOAdminLevel) {

    Set-GPPermission -DomainName $Domain -Name $GPOName -TargetType "Group" -TargetName $GPOAdminLevelGroups[$GPOAdminLevel] -PermissionLevel "GpoEditDeleteModifySecurity"
}

function Check-GPONamingCompliance ($GPOName) {
    
    if ($GPOName -match '(?:C|U|UC|CU)_[a-zA-Z]{2,15}_.+') {
      $GPONamingCompliance = $true
    }
    else {
        $GPONamingCompliance = $false
    }

    return $GPONamingCompliance
}

function Get-InteractiveLevel () {

    Write-Host "Available options for administration level of your GPO :`n"
    $GPOAdminLevelGroups.Keys | ForEach-Object {
        Write-Host "         $_"
    }
    $UserInput = Read-Host -Prompt "`nPlease type one of these options  "

    if (! ($GPOAdminLevelGroups.Keys -Contains $UserInput)) {
        Write-Host "`nInvalid entry, exiting...`n"
        exit
    }
    else {
        return $UserInput
    }
}

function Get-InteractiveName () {

    $UserInput = Read-Host -Prompt "Please type your GPO name. It must be compliant with the naming convention  "

    if (Check-GPONamingCompliance $UserInput) {
        return $UserInput
    }
    else {
        Write-Host "GPO name is not compliant with the naming policy. Exiting...`n"
        exit
    }
}

$Mode = Check-Argument $args[0]
#$Domain = Get-ADdomain.DNSRoot

if ($Mode -eq "interactive") {

    $GPOName = Get-InteractiveName
    $AdministrationLevel = Get-InteractiveLevel

    New-GPO -Name $GPOName
    Change-GPOPermission $GPOName $AdministrationLevel
}
elseif ($Mode -eq "file") {
    write-host $args[0]
    $CSVFile = Import-CSV -Path $args[0]

    $CSVFile | ForEach-Object {
        
        if ((Check-GPONamingCompliance $_.$CSVNameHeader) -And ($GPOAdminLevelGroups.Keys -Contains  $_.$CSVAdminLevelHeader)) {
            
            Write-Host "`nCreating GPO $($_.$CSVNameHeader)"
            New-GPO -Name $_.$CSVNameHeader
            Write-Host "`nSetting permission to GPO $($_.$CSVNameHeader)"
            Change-GPOPermission $_.$CSVNameHeader $_.$CSVAdminLevelHeader
        }
        else {
            Write-Host "The entry for GPO $($_.$CSVNameHeader) is invalid (either the naming convention is not respected, or the admin level is not in the list), skipping...`n"
        }
    }
}
