# PSScriptAnalyzer settings for PowerShell code quality
@{
    # Enable all rules by default
    IncludeDefaultRules = $true

    # Severity levels to include
    Severity = @(
        'Error',
        'Warning',
        'Information'
    )

    # Rules to exclude (none by default - maintain high standards)
    ExcludeRules = @(
        # Uncomment to exclude specific rules if needed
        # 'PSAvoidUsingCmdletAliases',
        # 'PSUseShouldProcessForStateChangingFunctions'
    )

    # Custom rules configuration
    Rules = @{
        # Enforce cmdlet alias usage restrictions
        PSAvoidUsingCmdletAliases = @{
            # Allow common aliases in scripts but warn
            allowlist = @()
        }

        # Function parameter rules
        PSReviewUnusedParameter = @{
            # Check for unused parameters
            CommandsToTraverse = @(
                'function',
                'filter',
                'workflow'
            )
        }

        # String literal rules
        PSAvoidUsingDoubleQuotesForConstantString = @{
            # Prefer single quotes for constant strings
            Enable = $true
        }

        # Variable naming rules
        PSUseDeclaredVarsMoreThanAssignments = @{
            # Ensure variables are used after assignment
            Enable = $true
        }

        # Best practices enforcement
        PSUseSingularNouns = @{
            # Enforce singular nouns for function names
            Enable = $true
        }

        PSUseApprovedVerbs = @{
            # Enforce approved PowerShell verbs
            Enable = $true
        }

        # Security rules
        PSAvoidUsingPlainTextForPassword = @{
            # Prevent plain text passwords
            Enable = $true
        }

        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            # Avoid insecure SecureString conversion
            Enable = $true
        }

        # Performance rules
        PSUsePSCredentialType = @{
            # Use PSCredential type for credentials
            Enable = $true
        }

        # Output and formatting rules
        PSAvoidUsingWriteHost = @{
            # Prefer Write-Output over Write-Host
            Enable = $true
        }
    }
}
