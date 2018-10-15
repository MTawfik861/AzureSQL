#Requires -Version 3.0 
 
Param(
    [string] $Path = "C:\Users\mtawfik\source\repos\AzureSQL\AzureSQL",
    [string] $azureAccountName = 'mtawfik@hotmail.es',
    [Security.SecureString] [Parameter(Mandatory=$True)] $password,
    [string] $SubscriptionId = 'd66f13b7-4a33-4d7c-9d5c-f7b2650d5236',
    [string] $TenantId  = '20349a5c-df19-401c-8e6c-bade0c468dd9',
    [string] $ResourceGroupLocation = 'West Europe',
    [string] $ResourceGroupName = 'AzureSQLResourceGroup',
    [string] $TemplateFile_Single = 'Single.json',
	[string] $TemplateFile_MI = 'MI.json',
	[string] $TemplateFile_Elastic = 'Elastic.json',
    [string] $TemplateParametersFile_Single = 'Single.parameters.json',
	[string] $TemplateParametersFile_MI = 'MI.parameters.json',
	[string] $TemplateParametersFile_Elastic = 'Elastic.parameters.json',
	[string][Parameter(Mandatory=$True)][ValidateSet("Single","MI","Elastic")]  $Solution_Type)

 
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
if ($Solution_Type -eq 'Single')
{
New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                   -ResourceGroupName $ResourceGroupName `
                                   -TemplateFile $TemplateFile_Single `
                                   -TemplateParameterFile $TemplateParametersFile_Single `
                                   -Force -Verbose `
                                   -ErrorVariable ErrorMessages
}
else	if ($Solution_Type -eq 'MI')
{
New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                   -ResourceGroupName $ResourceGroupName `
                                   -TemplateFile $TemplateFile_MI `
                                   -TemplateParameterFile $TemplateParametersFile_MI `
                                   -Force -Verbose `
                                   -ErrorVariable ErrorMessages
}
else if ($Solution_Type -eq 'Elastic')
{
New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                   -ResourceGroupName $ResourceGroupName `
                                   -TemplateFile $TemplateFile_Elastic `
                                   -TemplateParameterFile $TemplateParametersFile_Elastic `
                                   -Force -Verbose `
                                   -ErrorVariable ErrorMessages
}

else {#Solution Type selected is not valid}
 if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
  