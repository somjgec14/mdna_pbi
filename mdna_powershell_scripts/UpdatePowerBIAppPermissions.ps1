# Power BI App permission update script
# This script updates an app's permission from member to admin in multiple workspaces

# App details - with corrected Object ID
$appObjectId = "717bf139-a660-4b20-9c4b-f69cc7ea9f0f"
$appDisplayName = "Refresh Power BI dataset- API"

# Array of workspace IDs to process
$workspaceIds = @(
    "ea84a7c0-0f9d-405f-a5cd-b5005dd2b2c2",
    "3907cf62-4712-4e13-8bf1-0c1532910e4c",
    "efcc1ed7-dfb0-4d02-b94c-953009510e81",
    "a4ef288f-2c8a-40a7-91ca-33bdc35e0b40",
    "185ddafe-6525-414a-a7cf-ba207ba75f7c",
    "d3c2576b-a609-43a8-929e-0c051430026d",
    "098aaab6-cb19-48c7-bf51-779626173e5c",
    "10336e49-6f51-4762-b324-b42548897017",
    "0399394e-c052-4a68-83c9-55f44615a45c",
    "95118fb3-a965-4e32-b0cc-80f2602814e1",
    "4fa866d6-de86-43b8-86a0-bec44739e346",
    "eab78882-557f-46f8-9999-d18ea1ad8996",
    "06c6bfa9-8813-4486-894b-93dc108b9e9e",
    "7e16a1b6-9323-43a7-b811-1219a317982d",
    "5606e029-1a86-43d8-b045-ea36eec3f09d",
    "7fe21039-3910-427e-a3b0-f0ff980c8a88",
    "3b6ffdfb-b9d8-4563-a1b3-9cb5c97728e0",
    "9864ff61-3cb9-47bc-a70f-8817bde3cfee",
    "8b7fae9b-ffdd-40fc-86c5-28827ebaf696",
    "f7315654-4439-4327-99c3-9c197ddd0a2a",
    "a116b82c-c125-4c05-8681-86762a36845b",
    "ebb07ed0-c088-47cd-865a-aec110826433",
    "2dda6bb0-3b70-4ba4-a6ac-89c4203c69bd",
    "8abf9289-8c60-41b4-85b1-91d00365c505",
    "8ec8c675-0e06-4841-b765-3e0e509dc0f7",
    "eafa8a77-e2ad-4c07-bf63-c4b5b5c60986",
    "01652151-9293-4091-b394-982290d04257",
    "9296ee1b-2f65-4b75-9d0a-972ff25c1529",
    "055cb5dc-5729-4e8e-be04-2dc54b3a9c51",
    "3b409d67-00dd-45e1-8de7-3c0c5b210634",
    "a729c393-a738-4474-b965-18d58ad970d8",
    "4eb61d51-5eaf-4230-b73b-47e224fb9d25",
    "34170875-cf6b-41de-8980-beb63896dcc5",
    "3c6be9e7-f708-49af-88a4-583ad7c1dabb",
    "fc4458c1-499d-4847-aeea-ed0e6d387a13",
    "b172d8d7-a339-4ab6-b79b-9bc09a61f448",
    "f0964cf5-e641-42c1-a7df-4d526e79db0b",
    "f431b36f-5083-4b79-bdc5-6744562e6bda",
    "35ff91e8-e8e2-4628-8427-10db9c9f7d37",
    "c909435f-12ce-4fc9-9577-e8350c4d54b3",
    "9817d928-6d31-4431-8963-22a9ab1317b5",
    "7150d7eb-1636-46d2-8a12-ddc2494e76ab",
    "1eb9061b-2646-4be6-a45a-e11886b1f960",
    "63058aa0-9fd4-4f97-9291-fb419115d21b",
    "311c2f32-68fe-4d1f-be45-b4b674e03d1f",
    "28862d2e-c1a5-4a31-abc9-1ecfb6726e5c",
    "d75fb889-5d5b-419e-bf12-de169b836d9d",
    "14b44c0a-e3c3-41eb-b31f-c2a7d90ce593",
    "38b7b249-4870-48aa-8a2d-07f310d4902d",
    "c64e7c94-8bd2-47c1-94e4-a13c59b1d6fc",
    "f983cccb-4e28-4e5c-8b21-60397348aad7",
    "6b1399a9-be93-4773-9d2f-7282b4506667",
    "9ee6df4e-45b0-49ad-b95b-4ffbcea05c88",
    "9ab54efc-38b3-400b-81a5-f0cdb62176a4",
    "0f4df0cc-6d5e-467b-a568-c6a7d14b7fd7",
    "3f45eb43-f3d7-4f87-bc75-4bcb9b715b0a",
    "70666f26-c2ec-4a22-aace-449cf1128ede",
    "017af395-f0f8-4ca5-bf23-879774a226de",
    "2409e012-16d8-4725-a48f-759046cdc53f",
    "8e6c3138-d4d9-4b40-b082-13188d050b23",
    "90630c3d-cae7-49ff-844d-1a7cb68b686a",
    "4776110d-3352-4d4b-beb9-99790cda7026",
    "97c1ef88-1df7-4602-a943-248bb7a2623b",
    "902edbdc-6079-4337-bc66-24e7330d32f9",
    "633661d5-e95f-48c3-94ff-67b86c7adba2",
    "e14a55ae-800b-4096-8aef-e1bae7d7bad8",
    "28ee0dcc-febf-41b3-9dd7-b35ecf09880e",
    "ff544d1b-1588-4639-9fb0-b245d48f0658",
    "62681bbc-5145-4f03-8231-ad5112c9007a",
    "b6001a12-fe83-4bbe-93a9-7156a8d5ff4d",
    "8ff2d645-8bad-49d4-baf9-9e27f0b3e5c5",
    "2fbf2754-e29f-4b1e-aeed-5f16a817d5f8",
    "bd6c903d-8884-43d6-9fe7-8bf0115f6e10",
    "d6a20bab-dba5-4f6e-82cf-af878e5c790a",
    "3f3c4385-a084-424f-a57d-7cc71c5a377e",
    "97026e6e-6df7-4966-9bb2-f9bd606423f4",
    "db113388-0ee7-4ddd-9056-4148dce09d2a",
    "22ba33a0-7fbc-42e7-a432-df8d5297e201",
    "6992b54d-9be3-4573-a5cc-89face4aa423",
    "882017bd-8fdd-45e6-9a73-6eecf1290913",
    "53b73990-4eb6-4d89-849c-cfd93c7992f9",
    "28316c79-9772-4afa-96bd-f1da7535a887",
    "d48f0591-ccb3-4041-8ed7-b0f0d96e0759",
    "a4dae710-98b4-463c-98fd-bdf51a077bab",
    "6125acbc-5708-4832-b44d-3227351107d9",
    "988af805-bf1a-463a-b41d-e26a774f7a32"
)

# Log file
$logFile = "PowerBI_Permission_Update_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
"Starting permission update process at $(Get-Date)" | Out-File -FilePath $logFile

# Alternative approach using Power BI PowerShell modules
Write-Host "Checking for Power BI PowerShell module..."
if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Write-Host "Installing Power BI PowerShell module..."
    Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser -Force
}

# Import the module
Import-Module MicrosoftPowerBIMgmt

# Connect to Power BI service
Write-Host "Connecting to Power BI service..."
Connect-PowerBIServiceAccount

# Process each workspace
foreach ($workspaceId in $workspaceIds) {
    try {
        # API endpoint for updating the specific user in this workspace
        $apiUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/users"
        
        # Request body - changing permission to Admin
        $body = @{
            identifier = $appObjectId
            principalType = "App"
            groupUserAccessRight = "Admin"
        } | ConvertTo-Json
        
        # Log the current operation
        "Processing workspace: $workspaceId for app: $appDisplayName" | Out-File -FilePath $logFile -Append
        Write-Host "Processing workspace: $workspaceId" -ForegroundColor Cyan
        
        # Make the API call to update the user's permission
        # Using the Invoke-PowerBIRestMethod which handles the auth token automatically
        $response = Invoke-PowerBIRestMethod -Url "groups/$workspaceId/users" -Method Post -Body $body
        
        # Log success
        "SUCCESS: Updated app permission to Admin in workspace $workspaceId" | Out-File -FilePath $logFile -Append
        Write-Host "SUCCESS: Updated app permission in workspace $workspaceId" -ForegroundColor Green
    }
    catch {
        # Log any errors
        $errorMessage = "ERROR: Failed to update app permission in workspace $workspaceId. Error: $($_.Exception.Message)"
        $errorMessage | Out-File -FilePath $logFile -Append
        Write-Host $errorMessage -ForegroundColor Red
        
        # Additional error details if available
        if ($_.ErrorDetails) {
            $errorDetails = "Error Details: $($_.ErrorDetails.Message)"
            $errorDetails | Out-File -FilePath $logFile -Append
            Write-Host $errorDetails -ForegroundColor Red
        }
    }
    
    # Small delay to avoid throttling
    Start-Sleep -Milliseconds 500
}

"Completed permission update process at $(Get-Date)" | Out-File -FilePath $logFile -Append
Write-Host "Process completed. See $logFile for details." -ForegroundColor Green