#Requires -Version 3.0 

 

Param(
    [string] $Path = "C:\Users\mtawfik\source\repos\AzureSQL\AzureSQL",
    [string] $azureAccountName = 'mtawfik@hotmail.es',
    [Security.SecureString] [Parameter(Mandatory=$True)] $password,
    [string] $SubscriptionId = 'd66f13b7-4a33-4d7c-9d5c-f7b2650d5236',
    [string] $TenantId  = '20349a5c-df19-401c-8e6c-bade0c468dd9',
    [string] [Parameter(Mandatory=$True)] $ResourceGroupLocation,
    [string] $ResourceGroupName = 'AzureSQLResourceGroup',
    [string] $TemplateFile_Single = 'Single.json',
	[string] $TemplateFile_MI = 'MI.json',
	[string] $TemplateFile_Elastic = 'Elastic.json',
    [string] $TemplateParametersFile = 'azuredeploy.parameters.json',
    [string] $StorageAccountName= 'stage' + $SubscriptionId.Replace('-', '').substring(0, 19),
    [string] $StorageContainerName = $ResourceGroupName.ToLowerInvariant() + '-stageartifacts')
 
Set-Location -Path $Path
$OptionalParameters = New-Object -TypeName Hashtable
$TemplateFile = $Path + '\' + $TemplateFile
$TemplateParametersFile = $Path + '\' + $TemplateParametersFile

$ErrorView = "NormalView" 
$ErrorActionPreference = 'Stop'
$VerbosePreference="SilentlyContinue"
Set-StrictMode -Version 3
$formatenumerationlimit = 20
 

$Credential = New-Object System.Management.Automation.PSCredential($azureAccountName, $password) 
Login-AzureRmAccount -Credential $Credential -TenantId $TenantId -SubscriptionId $SubscriptionId -ErrorVariable ErrorMessages

Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorVariable ErrorMessages -ErrorAction SilentlyContinue 

if ($ErrorMessages)
{
    # ResourceGroup doesn't exist
    # Create or update the resource group using the specified template file and template parameters file
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force -ErrorVariable ErrorMessages  
}
else
{
    # ResourceGroup exist
}

    $StorageAccount = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName})

    # Create the storage account if it doesn't already exist
    if ($StorageAccount -eq $null) {
        $StorageAccount = New-AzureRmStorageAccount -kind BlobStorage -AccessTier Hot -StorageAccountName $StorageAccountName -Type 'Standard_LRS'  -ResourceGroupName $ResourceGroupName -Location $ResourceGroupLocation
    }

    # Copy files from the local storage staging location to the storage account container
    New-AzureStorageContainer  -Name $StorageContainerName -Context $StorageAccount.Context -ErrorAction Continue -Verbose -Debug
    
    $ArtifactStagingDirectory = $Path  
    $ArtifactFilePaths = Get-ChildItem $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process {$_.FullName}
    foreach ($SourcePath in $ArtifactFilePaths) {
    Set-AzureStorageBlobContent -File $SourcePath -Blob $SourcePath.Substring($ArtifactStagingDirectory.length + 1) `
    -Container $StorageContainerName -Context $StorageAccount.Context -Force
    }


    $ArtifactsLocationName = '_artifactsLocation'
    $ArtifactsLocationSasTokenName = '_artifactsLocationSasToken'
    $OptionalParameters[$ArtifactsLocationName] = $StorageAccount.Context.BlobEndPoint + $StorageContainerName
    
    # Generate a 4 hour SAS token for the artifacts location 
    $OptionalParameters[$ArtifactsLocationSasTokenName] = ConvertTo-SecureString -AsPlainText -Force `
    (New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddHours(4))
    

New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                   -ResourceGroupName $ResourceGroupName `
                                   -TemplateFile $TemplateFile `
                                   -TemplateParameterFile $TemplateParametersFile `
                                   @OptionalParameters `
                                   -Force -Verbose `
                                   -ErrorVariable ErrorMessages
 if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
  