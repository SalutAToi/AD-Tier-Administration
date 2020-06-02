Import-Module ActiveDirectory

$ENV = $args[0]
$JSONACESkelPath = ".\ACESkel.json"
$JSONPermissionsPath = ".\Permissions.json"
$LogFilePath = (Get-Location).Path
$LogFileName = "ACEDelegation.log"
$LogFileFullPath = $LogFilePath + "\" + $LogFileName
$ADDrive = "AD:"

# hashtable declaration
$GUIDMap = @{ } # hashtable that will contain the LDAP name and related GUID for each schema class attribute
$ExtendedRightsMap = @{ } # hashtable that will contain name and GUID for extended permissions

$RootDSE = Get-ADRootDSE # representation of the root of the directory tree providing configuration infos and capabilities

$ActiveDirectoryRightsList = @(
    "AccessSystemSecurity",
    "CreateChild",
    "Delete",
    "DeleteChild",
    "DeleteTree",
    "ExtendedRight",
    "GenericAll",
    "GenericExecute",
    "GenericRead",
    "GenericWrite",
    "ListChildren",
    "ListObject",
    "ReadControl",
    "ReadProperty",
    "Self",
    "Synchronize",
    "WriteDacl",
    "WriteOwner",
    "WriteProperty"
    )
$InheritanceTypeList = @(
        "All",
        "Children",
        "Descendents",
        "None",
    "SelfAndChildren"
)
$AccessControlTypeList = @(
    "Allow",
    "Deny"
)

function Get-ExtendedRightsMap ($ExtendedRightsMap) {
    # returns a hashtable of all extendedrights guids

    # in the schema, get all class definition for extended rights and return displayname and guids
    $ExtendedRightsClass = Get-ADObject -SearchBase ($RootDSE.ConfigurationNamingContext
    ) -LDAPFilter "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties DisplayName, RightsGUID

    # populate $ExtendedRightsMap hashtable with all extended rights guids
    $ExtendedRightsClass | ForEach-Object {
        $ExtendedRightsMap[$_.DisplayName] = [System.GUID]$_.RightsGUID
    }

    return $ExtendedRightsMap
}


function Write-Log 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory=$false)] 
        [Alias('LogPath')] 
        [string]$Path=$LogFileFullPath, 
         
        [Parameter(Mandatory=$true)]
        [Alias('LogLevel')] 
        [ValidateSet("Error","Warn","Info")]
        [string]$Level
    ) 
 
    Begin 
    { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'Continue' 
    } 
    Process 
    { 
         
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        if (!(Test-Path $Path)) { 
            Write-Verbose "Creating $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
            } 
 
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level) { 
            'Error' { 
                Write-Error $Message 
                $LevelText = 'ERROR:' 
                } 
            'Warn' { 
                Write-Warning $Message 
                $LevelText = 'WARNING:' 
                } 
            'Info' { 
                Write-Verbose $Message 
                $LevelText = 'INFO:' 
                } 
            } 
         
        # Write log entry to $Path 
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append 
    } 
    End
    { 
    }
}


function Get-GUIDMap ($GUIDMap) {
    # returns a hashtable of all attributes and objects guids in AD

    # in the schema, get all class definition for attributes and objects, return ldapdisplaynames and guids
    $AttributeClass = Get-ADObject -SearchBase ($RootDSE.SchemaNamingContext
    ) -LDAPFilter "(schemaidguid=*)" -Properties LDAPDisplayName, SchemaIDGUID

    # populate $GUIDMap hashtable with all guids
    $AttributeClass | ForEach-Object {
        $GUIDMap[$_.LDAPDisplayName] = [System.GUID]$_.SchemaIDGUID
    }

    return $GUIDMap
}


function Add-SpecificPermissions ($IdentityReference, $ActiveDirectoryRights, $AccessControlType, 
                                    $InheritedObjectTypes, $InheritanceType, $ObjectGUID, $ACL) {
    
    foreach ($InheritedObjectType in $InheritedObjectTypes) {
        # loop through every InheritedObjectType to create one ACE per InheritedObjectType

        # determine in which hashtable we should look for the InheritedObjectTypeGUID : extended
        # rights has its own table as it is in a different location on the schema
        if ($ActiveDirectoryRights -eq "ExtendedRight") {
            $InheritedObjectTypeGUID = $ExtendedRightsMap[$InheritedObjectType]
        }
        else {
            $InheritedObjectTypeGUID = $GUIDMap[$InheritedObjectType]
        }

        # create ACE and add to all ACEs in ACL (backtick to break)
        $ACE = New-SpecificPermission $IdentityReference $ActiveDirectoryRights $AccessControlType `
                                    $InheritedObjectTypeGUID $InheritanceType $ObjectGUID

        $ACL.addAccessRule($ACE)

    }

    return $ACL
}


function Add-ContainerPermissions ($IdentityReference, $ActiveDirectoryRights, $AccessControlType, 
                                    $InheritedObjectTypes, $InheritanceType, $ACL) {
    
    foreach ($InheritedObjectType in $InheritedObjectTypes) {
        # loop through every InheritedObjectType to create one ACE per InheritedObjectType

        # determine in which hashtable we should look for the InheritedObjectTypeGUID : extended
        # rights has its own table as it is in a different location on the schema
        if ($ActiveDirectoryRights -eq "ExtendedRight") {
            $InheritedObjectTypeGUID = $ExtendedRightsMap[$InheritedObjectType]
        }
        else {
            $InheritedObjectTypeGUID = $GUIDMap[$InheritedObjectType]
        }

        # create ACE and add to all ACEs in ACL (backtick to break)
        $ACE = New-ContainerPermission $IdentityReference $ActiveDirectoryRights $AccessControlType `
                                    $InheritedObjectTypeGUID $InheritanceType
        $ACL.addAccessRule($ACE)

    }

    return $ACL
}


function Add-GeneralPermissions ($IdentityReference, $ActiveDirectoryRights, $AccessControlType, 
                                    $InheritanceType, $ObjectGUID, $ACL) {
    
        # create ACE and add to all ACEs in ACL (bactick to break)
        $ACE = New-GeneralPermission $IdentityReference $ActiveDirectoryRights $AccessControlType `
                                    $InheritanceType $ObjectGUID
        $ACL.addAccessRule($ACE)
        
        return $ACL
}

function Add-CreateDeletePermissions ($IdentityReference, $ActiveDirectoryRights, $AccessControlType, 
                                    $ObjectGUID, $ACL) {
    
        # create ACE and add to all ACEs in ACL (bactick to break)
        $ACE = New-CreateDeletePermission $IdentityReference $ActiveDirectoryRights $AccessControlType `
                                    $ObjectGUID
        $ACL.addAccessRule($ACE)
        
        return $ACL
}


function Get-CompleteACL ($IdentityReference, $ACESkelName, $ACL) {
    # comment here

    $ACESkel.$ACESkelName | ForEach-Object {

        # constructor parameters common to all constructors
        $ActiveDirectoryRights = Resolve-ActiveDirectoryRights $_.ACE.ActiveDirectoryRights
        $AccessControlType = Resolve-AccessControlType $_.ACE.AccessControlType
        $InheritanceType = Resolve-InheritanceType $_.ACE.InheritanceType
        $ObjectName = $_.ACE.ObjectName
        $InheritedObjectTypes = $_.ACE.InheritedObjectTypes  # list of object types for function returning ACE

        switch ($_.Type) {
            "SpecificPermission" {

                # other constructor parameters specific to that permission
                $ObjectGUID = $GUIDMap[$ObjectName]

                # (backtick to break)
                $ACL  = Add-SpecificPermissions $IdentityReference $ActiveDirectoryRights $AccessControlType `
                                            $InheritedObjectTypes $InheritanceType $ObjectGUID $ACL
            }
            "GeneralPermission" {
                # other constructor parameters specific to that permission
                $ObjectGUID = $GUIDMap[$ObjectName]

                # (backtick to break)
                $ACL  = Add-GeneralPermissions $IdentityReference $ActiveDirectoryRights $AccessControlType `
                                            $InheritanceType $ObjectGUID $ACL

            }
            "ContainerPermission" {

                # (backtick to break)
                $ACL  = Add-ContainerPermissions $IdentityReference $ActiveDirectoryRights $AccessControlType `
                                            $InheritedObjectTypes $InheritanceType $ACL

                
            }
            "CreateDeletePermission" {
                # other constructor parameters specific to that permission
                $ObjectGUID = $GUIDMap[$ObjectName]

                # (backtick to break)
                $ACL  = Add-CreateDeletePermissions $IdentityReference $ActiveDirectoryRights $AccessControlType `
                                            $ObjectGUID $ACL

            }

        }
    }
    return $ACL
}


##############################################################################################################
#                                                                                                            #
#                                   CONSTRUCTOR FUNCTIONS FOR SINGLE ACES                                    #                      
#                                                                                                            #
##############################################################################################################

# the ACEs correponds to a specific class in powershell/.net that must be used to create an ACE object to
# be applied to a container (OU, container)
# below are the constructors required to create 3 flavours of ACE, created according to MS documentation
# on constructor for the ActiveDirectoryAccessRule class

# documentation for the ActiveDirectoryAccessRule class
# can be found here :
# https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.activedirectoryaccessrule?redirectedfrom=MSDN&view=dotnet-plat-ext-3.1

# documentation for the ActiveDirectoryAccessRule class constructors
# can be found here :
# https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.activedirectoryaccessrule.-ctor?view=dotnet-plat-ext-3.1&viewFallbackFrom=dotnet-plat-ext-3.1ce_System_DirectoryServices_ActiveDirectoryRights_System_Security_AccessControl_AccessControlType_System_DirectoryServices_ActiveDirectorySecurityInheritance_

function New-GeneralPermission ($IdentityReference, $ActiveDirectoryRights, $AccessControlType,
                                $InheritanceType, $ObjectGUID) {
    # Class constructor for an ActiveDirectoryAccess for general permission (write/read all, generic all,...),
    # that is, permission applying on the whole object in $ObjectGUID

    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $IdentityReference,
                                                                        $ActiveDirectoryRights,
                                                                        $AccessControlType,
                                                                        $InheritanceType,
                                                                        $ObjectGUID
    return $ACE
}

function New-SpecificPermission ($IdentityReference, $ActiveDirectoryRights, $AccessControlType, 
                                    $InheritedObjectTypeGUID, $InheritanceType, $ObjectGUID) {
    # Class constructor for an ActiveDirectoryAccess for specific permission on a given attribute ($InheritedObjectTypeGUID) or an AD
    # extended right if $ActiveDirectoryRights is ExtendedRight

    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $IdentityReference,
                                                                        $ActiveDirectoryRights,
                                                                        $AccessControlType,
                                                                        $InheritedObjectTypeGUID,
                                                                        $InheritanceType,
                                                                        $ObjectGUID

    return $ACE
}

function New-ContainerPermission ($IdentityReference, $ActiveDirectoryRights, $AccessControlType,
                                    $InheritedObjectTypeGUID, $InheritanceType) {
    # Class constructor for an ActiveDirectoryAccess for specific or general permission on a OU or container ($InheritedObjectTypeGUID)

    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $IdentityReference,
                                                                        $ActiveDirectoryRights,
                                                                        $AccessControlType,
                                                                        $InheritedObjectTypeGUID,
                                                                        $InheritanceType
    return $ACE
}

function New-CreateDeletePermission ($IdentityReference, $ActiveDirectoryRights, $AccessControlType,
                                $ObjectGUID) {
    # Class constructor for an ActiveDirectoryAccess for creation and deletion permission of the targeted object

    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $IdentityReference,
                                                                        $ActiveDirectoryRights,
                                                                        $AccessControlType,
                                                                        $ObjectGUID
    return $ACE
}

function Update-ACL ($GroupSID, $Permissions, $ObjectDN)
{
    # as permissions are a list in the JSON file structure, iterating through each of them
    foreach ($Permission in $Permissions) {

        $CurrentACL = Get-ACL -Path $ObjectDN
        $NewACL = Get-CompleteACL $GroupSID $Permission $CurrentACL
        if ($ENV -eq "LIVE") {
            $SetACLLog = Set-ACL -Path $ObjectDN -AclObject $NewACL -Verbose 4>&1
            Write-Log -LogContent $SetACLLog.Message[0] -Level "Info"
        }
        else {
            Write-Host "Set-ACL -Path $ObjectDN -AclObject $NewACL -Verbose"
        }
        

    }
}

function Resolve-Container ($ObjectDN) {
    # check that the container given is valid, if not, write to log and send continue to skip that container entry
    # is called container an AD object that can contain users, groups, computers. That can be a container or an OU


    try
    {
        $Container = Get-ADObject -Identity $ObjectDN # check if existent in AD
        $ContainerPath = $ADDrive + '\' + $Container.DistinguishedName # assigning a value with AD basepath

    }
    catch
    {
        Write-Log -LogContent "Cannot find the object (container or OU) $ObjectDN" -LogLevel "Error"
        Write-Log -LogContent "Skipping $ObjectDN. No permission will be applied there" -LogLevel "Warn"
        continue # skips to next element in innermost loop
    }

    return $ContainerPath
}


function Resolve-Group ($GroupName, $ACESkelName) {
    # check that the group given is valid, if not, write to log and send continue to skip that group entry
    try
    {
        $Group = Get-ADGroup -Identity $GroupName # check if existent in AD
        $GroupSID = $Group.SID # getting SID for group

    }
    catch
    {
        Write-Log -LogContent "Cannot find the group $GroupName" -LogLevel "Warn"
        Write-Log -LogContent "Skipping permissions for $GroupName. No permission will be applied to it" -LogLevel "Warn"
        continue # skips to next element in innermost loop
    }

    return $GroupSID
}

function Resolve-AccessControlType ($AccessControlType, $ACESkelName) {
    # check that the AccessControlType value provided is in the list, and therefore valid
    # returns the value if it is, jump to next iteration if it's not

    if ($AccessControlTypeList -Contains $AccessControlType) {
        return $AccessControlType
    }
    else {
        Write-Log -LogContent "AccessControlType $AccessControlType is invalid (on ACESkel.json file $ACESkelName entry) Skipping" -LogLevel "Error"
        return
    }


}


function Resolve-InheritanceType ($InheritanceType, $ACESkelName) {
    # check that the InheritanceType value provided is in the list, and therefore valid
    # returns the value if it is, jump to next iteration if it's not
    
    if ($InheritanceTypeList -Contains $InheritanceType) {
        return $InheritanceType
    }
    elseif (! ($InheritanceType)) {
        return $InheritanceType
    }
    else {
        Write-Log -LogContent "InheritanceType $InheritanceType is invalid (on ACESkel.json file $ACESkelName entry) Skipping" -LogLevel "Error"
        return
    }
}


function Resolve-ActiveDirectoryRights ($ActiveDirectoryRights) {
    # check that the ActiveDirectoryRights value(s) provided is in the list, and therefore valid
    # returns the value if it is, jump to next iteration if it's not
    # split to commas if present

    # ActiveDirectoryRights can contain several rights separated by comma, splitting at comma
    $Separator = ","
    $AllActiveDirectoryRights = $ActiveDirectoryRights.Split($Separator)

    foreach ($ActiveDirectoryRight in $AllActiveDirectoryRights) {

        if (! ($ActiveDirectoryRightsList -Contains $ActiveDirectoryRight)) {
            Write-Log -LogContent "ActiveDirectoryRights $ActiveDirectoryRights is invalid (on ACESkel.json file $ACESkelName entry) Skipping" -LogLevel "Error"
            return
        }
    }
    return $ActiveDirectoryRights

    
}
# hashtable declaration
$GUIDMap = @{ } # hashtable that will contain the LDAP name and related GUID for each schema class attribute
$ExtendedRightsMap = @{ } # hashtable that will contain name and GUID for extended permissions

$RootDSE = Get-ADRootDSE # representation of the root of the directory tree providing configuration infos and capabilities

# import JSON files
$ACESkel = Get-Content -Path $JSONACESkelPath | ConvertFrom-Json
$Permissions = Get-Content -Path $JSONPermissionsPath | ConvertFrom-Json

$ExtendedRightsMap = Get-ExtendedRightsMap $ExtendedRightsMap
$GUIDMap = Get-GUIDMap $GUIDMap


# main script

# iteration through all element of the JSON file
foreach ($Object in $Permissions) {

    # check of supplied DN, skips to next one if invalid
    $ObjectPath = Resolve-Container $Object.DistinguishedName

    # iterating through each ACEs (permissions per group)
    foreach ($ACE in $Object.ACEs) {

        # check of supplied group, skips to next one if invalid
        $GroupSID = [System.Security.Principal.IdentityReference] (Resolve-Group $ACE.Group)
        $PermissionList = $ACE.Permissions
     
        Update-ACL $GroupSID $PermissionList $ObjectPath
    }
    
}