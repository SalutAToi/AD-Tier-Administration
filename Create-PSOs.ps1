$PSOs = @(
    @{
        Name = "PSO_AT0_Administrator";
        ComplexityEnabled = $true;
        MaxPasswordAge = "120";
        MinPasswordAge = "1";
        MinPasswordLength = "20";
        PasswordHistoryCount = "20";
        Precedence = "10";
        Appliesto = "PSO_Tier 0 ADM Users_APPLY"
    },
    @{
        Name = "PSO_AT1_Administrator";
        ComplexityEnabled = $true;
        MaxPasswordAge = "120";
        MinPasswordAge = "1";
        MinPasswordLength = "20";
        PasswordHistoryCount = "20";
        Precedence = "20";
        Appliesto = "PSO_Tier 1 ADM Users_APPLY"
    },
    @{
        Name = "PSO_AT2_Administrator";
        ComplexityEnabled = $true;
        MaxPasswordAge = "120";
        MinPasswordAge = "1";
        MinPasswordLength = "16";
        PasswordHistoryCount = "20";
        Precedence = "30";
        Appliesto = "PSO_Tier 2 ADM Users_APPLY"
    },
    @{
        Name = "PSO_ST0_Service User";
        ComplexityEnabled = $true;
        MaxPasswordAge = "100000";
        MinPasswordAge = "1";
        MinPasswordLength = "100";
        PasswordHistoryCount = "20";
        Precedence = "10";
        Appliesto = "PSO_Tier 0 Service Users_APPLY"
    },
    @{
        Name = "PSO_ST1_Service user";
        ComplexityEnabled = $true;
        MaxPasswordAge = "100000";
        MinPasswordAge = "1";
        MinPasswordLength = "100";
        PasswordHistoryCount = "20";
        Precedence = "20";
        Appliesto = "PSO_Tier 1 Service Users_APPLY"
    }
)

function Create-PSO ($Name, $ComplexityEnabled, $MaxPasswordAge, $MinPasswordAge, $MinPasswordLength, $Precedence) {
    
    New-ADFineGrainedPasswordPolicy -Name $Name -ComplexityEnabled $ComplexityEnabled -MaxPasswordAge $MaxPasswordAge -MinPasswordAge $MinPasswordAge -MinPasswordLength $MinPasswordLength -Precedence $Precedence
}


foreach ($PSO in $PSOs) {
    Create-PSO $PSO.Name $PSO.ComplexityEnabled $PSO.MaxPasswordAge $PSO.MinPasswordAge $PSO.MinPasswordLength $PSO.Precedence

    Add-ADFineGrainedPasswordPolicySubject -Identity $PSO.Name -Subjects $PSO.Appliesto
}