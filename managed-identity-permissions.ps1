# Run this script only once to give the azure automation managed identity the required graph permissions

# Define the Object ID of your Automation Account's Managed Identity
$ManagedIdentityObjectId = "AUTOMATION_ACCOUNT_OBJECT_ID"

# Connect to Graph as a Global Admin to grant the permissions
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All", "Application.Read.All", "RoleManagement.ReadWrite.Directory"

# Define the Graph API permissions we need for onboarding
$GraphAppId = "00000003-0000-0000-c000-000000000000" # This is the universal ID for Microsoft Graph
$RequiredPermissions = @(
    "User.ReadWrite.All",                   # To create the user account
    "GroupMember.ReadWrite.All",            # To add the user to the HR group
    "UserAuthenticationMethod.ReadWrite.All",# To generate the Temporary Access Pass
    "Organization.Read.All"                 # To read the tenant's license SKUs
)

# Find the Microsoft Graph Service Principal in your tenant
$GraphServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$GraphAppId'"

# Loop through and grant each permission
foreach ($PermissionName in $RequiredPermissions) {
    $AppRole = $GraphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $PermissionName }
    
    if ($AppRole) {
        $AppRoleAssignment = @{
            principalId = $ManagedIdentityObjectId
            resourceId = $GraphServicePrincipal.Id
            appRoleId = $AppRole.Id
        }
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId -BodyParameter $AppRoleAssignment
        Write-Host "Successfully assigned $PermissionName to Managed Identity." -ForegroundColor Green
    } else {
        Write-Host "Could not find permission $PermissionName." -ForegroundColor Red
    }
}

Disconnect-MgGraph
