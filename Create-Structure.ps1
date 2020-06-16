# Script to create an OU structure from an array of hashtables

$OUs = @(
    @{
        name="Corp";
        path="DC=contoso,DC=com"
    },
    @{
        name="Users";
        path="OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Service";
        path="OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Administration";
        path="OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Computers";
        path="OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Tier 2";
        path="OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Tier 1";
        path="OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Tier 0";
        path="OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Terminal servers";
        path="OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="PKI";
        path="OU=Tier 0,OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Shared";
        path="OU=Tier 2,OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Desktops";
        path="OU=Tier 2,OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Laptops";
        path="OU=Tier 2,OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Network";
        path="OU=Tier 1,OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Application";
        path="OU=Tier 1,OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="File";
        path="OU=Tier 1,OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Update";
        path="OU=Tier 1,OU=Computers,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Adelaide";
        path="OU=Users,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Melbourne";
        path="OU=Users,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Sydney";
        path="OU=Users,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Perth";
        path="OU=Users,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Brisbane";
        path="OU=Users,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Offsite";
        path="OU=Users,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Contractors";
        path="OU=Users,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Tier 0";
        path="OU=Service,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Tier 1";
        path="OU=Service,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Users";
        path="OU=Tier 0,OU=Service,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Users";
        path="OU=Tier 1,OU=Service,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Tier 0";
        path="OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Tier 1";
        path="OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Tier 2";
        path="OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Users";
        path="OU=Tier 0,OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Users";
        path="OU=Tier 1,OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Users";
        path="OU=Tier 2,OU=Administration,OU=Corp,DC=contoso,DC=com"
    }
)

$Containers = @(
    @{
        name="Security groups";
        path="OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Access Control";
        path="CN=Security groups,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Roles";
        path="CN=Security groups,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Access Control";
        path="OU=Tier 0,OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Roles";
        path="OU=Tier 0,OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Access Control";
        path="OU=Tier 1,OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Roles";
        path="OU=Tier 1,OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Access Control";
        path="OU=Tier 2,OU=Administration,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Roles";
        path="OU=Tier 2,OU=Administration,OU=Corp,DC=contoso,DC=com"
    }
    @{
        name="Access Control";
        path="OU=Tier 1,OU=Service,OU=Corp,DC=contoso,DC=com"
    },
    @{
        name="Access Control";
        path="OU=Tier 0,OU=Service,OU=Corp,DC=contoso,DC=com"
    }
)

Foreach ($OU in $OUs)
{
    Write-Host "Creating OU"$OU['name']"in"$OU['path']
    New-ADOrganizationalUnit -Name $OU['name'] -Path $OU['path']
    if (! (Get-ADObject -Identity $OU['path'])) {
        Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR : OU $OU['path'] was not created"
    }
}

Foreach ($Container in $Containers)
{
    Write-Host "Creating Container"$Container['name']"in"$Container['path']
    New-AdObject -Name $Container['name'] -Type container -path $Container['path'] -ProtectedFromAccidentalDeletion $true
    if (! (Get-ADObject -Identity $Container['path'])) {
        Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR : Container $Container['path'] was not created"
    }
}