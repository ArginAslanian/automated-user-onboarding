<#
.SYNOPSIS
    Automated User Onboarding via Microsoft Graph API
.DESCRIPTION
    Triggered by an Azure Logic App. Provisions a user, assigns manager, 
    adds to groups, assigns licenses, and generates a Temporary Access Pass (TAP).
#>

param (
    [Parameter(Mandatory=$true)] [string]$FirstName,
    [Parameter(Mandatory=$true)] [string]$LastName,
    [Parameter(Mandatory=$true)] [string]$Department,
    [Parameter(Mandatory=$true)] [string]$JobTitle,
    [Parameter(Mandatory=$true)] [string]$ManagerUPN
)

try {
    # ==========================================
    # 1. AUTHENTICATION & VARIABLE SETUP
    # ==========================================
    Write-Host "Connecting to Microsoft Graph via Managed Identity..."
    Connect-MgGraph -Identity -NoWelcome | Out-Null
    
    # Define your domain here
    $Domain = "DOMAIN" 
    
    # Construct UPN (e.g., jdoe@yourdomain.com)
    $CleanFirstName = $FirstName -replace '[^a-zA-Z0-9]', ''
    $CleanLastName = $LastName -replace '[^a-zA-Z0-9]', ''
    $FirstInitial = $CleanFirstName.Substring(0,1)
    $Alias = "$FirstInitial$CleanLastName".ToLower()
    $UPN = "$Alias@$Domain"
    
    # Define Target GUIDs
    $E3LicenseSku = "6fd2c87f-b296-42f0-b197-1e91e994b900"
    $P2LicenseSku = "84a661c4-e949-4bd2-a560-ed7766fcaf2b"

    # Dynamic Department-to-Group Mapping Table
    $DepartmentGroupMap = @{
        "Human Resources"        = "GROUP_ID"
        "Facilities"             = "GROUP_ID"
        "Marketing"              = "GROUP_ID"
        "Information Technology" = "GROUP_ID"
    }

    # ==========================================
    # 2. COLLISION CHECK
    # ==========================================
    Write-Host "Checking if user $UPN already exists..."
    $ExistingUser = Get-MgUser -Filter "userPrincipalName eq '$UPN'" -ErrorAction SilentlyContinue
    if ($ExistingUser) {
        throw "A user with the UPN $UPN already exists in Entra ID. Halting automation."
    }

    # ==========================================
    # 3. USER CREATION
    # ==========================================
    Write-Host "Creating new user account for $UPN..."
    
    $RandomPassword = ConvertTo-SecureString -String ("$(New-Guid)@A1") -AsPlainText -Force

    $NewUserParams = @{
        AccountEnabled = $true
        DisplayName = "$FirstName $LastName"
        MailNickname = $Alias
        UserPrincipalName = $UPN
        Department = $Department
        JobTitle = $JobTitle
        UsageLocation = "US" 
        PasswordProfile = @{
            Password = $RandomPassword
            ForceChangePasswordNextSignIn = $false
        }
    }
    
    $NewUser = New-MgUser @NewUserParams
    Write-Host "Successfully created user object ID: $($NewUser.Id)"

    # ==========================================
    # 4. SET MANAGER
    # ==========================================
    Write-Host "Linking manager $ManagerUPN..."
    $ManagerObj = Get-MgUser -UserId $ManagerUPN
    if ($ManagerObj) {
        $ManagerPayload = @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($ManagerObj.Id)"
        }
        # Out-Null added to silence the output stream
        Set-MgUserManagerByRef -UserId $NewUser.Id -BodyParameter $ManagerPayload | Out-Null
        Write-Host "Manager successfully linked."
    } else {
        Write-Warning "Manager $ManagerUPN not found. Proceeding without manager link."
    }

    # ==========================================
    # 5. ASSIGN LICENSES & GROUPS
    # ==========================================
    Write-Host "Assigning Licenses and Department Group..."
    
    $TargetGroupId = $DepartmentGroupMap[$Department]

    if ($TargetGroupId) {
        Write-Host "Mapping found. Adding user to $Department group..."
        # Out-Null added to silence the output stream
        New-MgGroupMember -GroupId $TargetGroupId -DirectoryObjectId $NewUser.Id | Out-Null
        Write-Host "Successfully added to $Department group."
    } else {
        Write-Warning "No specific Entra ID group mapped for Department: '$Department'."
    }

    $AddLicenses = @(
        @{ SkuId = $E3LicenseSku }
        @{ SkuId = $P2LicenseSku }
    )
    
    Write-Host "Applying O365 E3 and Entra ID P2 licenses..."
    # Out-Null added to silence the output stream (Removes the giant property block)
    Set-MgUserLicense -UserId $NewUser.Id -AddLicenses $AddLicenses -RemoveLicenses @() | Out-Null
    Write-Host "Licenses successfully applied."

    # ==========================================
    # 6. GENERATE TEMPORARY ACCESS PASS (TAP)
    # ==========================================
    Write-Host "Waiting 15 seconds for Entra ID replication before generating credentials..."
    Start-Sleep -Seconds 15

    Write-Host "Generating Temporary Access Pass..."
    $TapParams = @{
        LifetimeInMinutes = 480 # 8 Hours
        IsUsableOnce = $true
    }
    
    # Generate the TAP (Crash if it fails, rather than sending null)
    $Tap = New-MgUserAuthenticationTemporaryAccessPassMethod -UserId $NewUser.Id -BodyParameter $TapParams -ErrorAction Stop
    Write-Host "Temporary Access Pass successfully generated!"  

    # ==========================================
    # 7. OUTPUT SECURE PAYLOAD TO LOGIC APP
    # ==========================================
    Write-Host "Automation Complete. Formatting output for Logic Apps..."
    
    $OutputPayload = [PSCustomObject]@{
        NewUserUPN = $UPN
        ManagerUPN = $ManagerUPN
        TapCode = $Tap.TemporaryAccessPass 
        TapExpiration = (Get-Date).AddMinutes(480).ToString("g") 
    }

    # THIS IS THE ONLY WRITE-OUTPUT IN THE SCRIPT
    Write-Output ($OutputPayload | ConvertTo-Json)

} catch {
    Write-Error "Onboarding Automation Failed: $_"
    throw $_
}
