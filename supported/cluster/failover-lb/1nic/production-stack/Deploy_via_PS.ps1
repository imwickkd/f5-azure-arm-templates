## Script parameters being asked for below match to parameters in the azuredeploy.json file, otherwise pointing to the ##
## azuredeploy.parameters.json file for values to use.  Some options below are mandatory, some (such as region) can    ##
## be supplied inline when running this script but if they aren't then the default will be used as specified below.    ##
## Example Command: .\Deploy_via_PS.ps1 -licenseType PAYG -licensedBandwidth 200m -numberOfInstances 2 -adminUsername azureuser -authenticationType password -adminPasswordOrKey <value> -uniqueLabel <value> -instanceType Standard_DS2_v2 -imageName Best -bigIpVersion 13.1.0200 -vnetName <value> -vnetResourceGroupName <value> -mgmtSubnetName <value> -mgmtIpAddressRangeStart <value> -ntpServer 0.pool.ntp.org -timeZone UTC -customImage OPTIONAL -allowUsageAnalytics Yes -resourceGroupName <value>

param(
  [string] [Parameter(Mandatory=$True)] $licenseType,
  [string] $licensedBandwidth = $(if($licenseType -eq "PAYG") { Read-Host -prompt "licensedBandwidth"}),
  [string] $licenseKey1 = $(if($licenseType -eq "BYOL") { Read-Host -prompt "licenseKey1"}),
  [string] $licenseKey2 = $(if($licenseType -eq "BYOL") { Read-Host -prompt "licenseKey2"}),

  [string] [Parameter(Mandatory=$True)] $numberOfInstances,
  [string] [Parameter(Mandatory=$True)] $adminUsername,
  [string] [Parameter(Mandatory=$True)] $authenticationType,
  [string] [Parameter(Mandatory=$True)] $adminPasswordOrKey,
  [string] [Parameter(Mandatory=$True)] $uniqueLabel,
  [string] [Parameter(Mandatory=$True)] $instanceType,
  [string] [Parameter(Mandatory=$True)] $imageName,
  [string] [Parameter(Mandatory=$True)] $bigIpVersion,
  [string] [Parameter(Mandatory=$True)] $vnetName,
  [string] [Parameter(Mandatory=$True)] $vnetResourceGroupName,
  [string] [Parameter(Mandatory=$True)] $mgmtSubnetName,
  [string] [Parameter(Mandatory=$True)] $mgmtIpAddressRangeStart,
  [string] [Parameter(Mandatory=$True)] $ntpServer,
  [string] [Parameter(Mandatory=$True)] $timeZone,
  [string] [Parameter(Mandatory=$True)] $customImage,
  [string] $restrictedSrcAddress = "*",
  $tagValues = '{"application": "APP", "cost": "COST", "environment": "ENV", "group": "GROUP", "owner": "OWNER"}',
  [string] [Parameter(Mandatory=$True)] $allowUsageAnalytics,
  [string] [Parameter(Mandatory=$True)] $resourceGroupName,
  [string] $region = "West US",
  [string] $templateFilePath = "azuredeploy.json",
  [string] $parametersFilePath = "azuredeploy.parameters.json"
)

Write-Host "Disclaimer: Scripting to Deploy F5 Solution templates into Cloud Environments are provided as examples. They will be treated as best effort for issues that occur, feedback is encouraged." -foregroundcolor green
Start-Sleep -s 3

# Connect to Azure, right now it is only interactive login
try {
    Write-Host "Checking if already logged in!"
    Get-AzureRmSubscription | Out-Null
    Write-Host "Already logged in, continuing..."
    }
    catch {
      Write-Host "Not logged in, please login..."
      Login-AzureRmAccount
    }

# Create Resource Group for ARM Deployment
New-AzureRmResourceGroup -Name $resourceGroupName -Location "$region"

$adminPasswordOrKeySecure = ConvertTo-SecureString -String $adminPasswordOrKey -AsPlainText -Force

(ConvertFrom-Json $tagValues).psobject.properties | ForEach -Begin {$tagValues=@{}} -process {$tagValues."$($_.Name)" = $_.Value}

# Create Arm Deployment
if ($licenseType -eq "BYOL") {
  if ($templateFilePath -eq "azuredeploy.json") { $templateFilePath = ".\byol\azuredeploy.json"; $parametersFilePath = ".\byol\azuredeploy.parameters.json" }
  $deployment = New-AzureRmResourceGroupDeployment -Name $resourceGroupName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose -numberOfInstances $numberOfInstances -adminUsername $adminUsername -authenticationType $authenticationType -adminPasswordOrKey $adminPasswordOrKeySecure -uniqueLabel $uniqueLabel -instanceType $instanceType -imageName $imageName -bigIpVersion $bigIpVersion -vnetName $vnetName -vnetResourceGroupName $vnetResourceGroupName -mgmtSubnetName $mgmtSubnetName -mgmtIpAddressRangeStart $mgmtIpAddressRangeStart -ntpServer $ntpServer -timeZone $timeZone -customImage $customImage -restrictedSrcAddress $restrictedSrcAddress -tagValues $tagValues -allowUsageAnalytics $allowUsageAnalytics  -licenseKey1 "$licenseKey1" -licenseKey2 "$licenseKey2"
} elseif ($licenseType -eq "PAYG") {
  if ($templateFilePath -eq "azuredeploy.json") { $templateFilePath = ".\payg\azuredeploy.json"; $parametersFilePath = ".\payg\azuredeploy.parameters.json" }
  $deployment = New-AzureRmResourceGroupDeployment -Name $resourceGroupName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose -numberOfInstances $numberOfInstances -adminUsername $adminUsername -authenticationType $authenticationType -adminPasswordOrKey $adminPasswordOrKeySecure -uniqueLabel $uniqueLabel -instanceType $instanceType -imageName $imageName -bigIpVersion $bigIpVersion -vnetName $vnetName -vnetResourceGroupName $vnetResourceGroupName -mgmtSubnetName $mgmtSubnetName -mgmtIpAddressRangeStart $mgmtIpAddressRangeStart -ntpServer $ntpServer -timeZone $timeZone -customImage $customImage -restrictedSrcAddress $restrictedSrcAddress -tagValues $tagValues -allowUsageAnalytics $allowUsageAnalytics  -licensedBandwidth "$licensedBandwidth"
} else {
  Write-Error -Message "Please select a valid license type of PAYG or BYOL."
}

# Print Output of Deployment to Console
$deployment