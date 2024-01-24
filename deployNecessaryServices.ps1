#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates all the resources we need to create an Nextcloud instance on Azure Web Apps using Containers

.Example
    ./deployNecessaryServices.ps1 -ResourceBaseName nextcloud -ResourceGroupName nextcloud -Location "Central US" -VNetName nextcloud-vnet -DBdminName ncadmin -DBPassword <password>
#>
param(
    [Parameter(Mandatory=$true)][string]$ResourceBaseName,
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$Location,
    [Parameter(Mandatory=$true)][string]$VNetName,
    [Parameter(Mandatory=$true)][string]$DBAdminName,
    [Parameter(Mandatory=$true)][string]$DBPassword,
)

New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location

$DBAdminPassword = ConvertTo-SecureString $DBPassword -AsPlainText -Force

New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name main -TemplateFile ./bicep/main.bicep `
    -resourceBaseName $ResourceBaseName -location $Location -vnetName $VNetName -storageAccountSkuName "Standard_LRS" `
    -storageAccountKind "StorageV2" -administratorLogin $DBAdminName ` -administratorLoginPassword $DBAdminPassword


$mySQlServerName = $ResourceBaseName
$storageAccountName = "${ResourceBaseName}jimmystorage"
$appName = "${ResourceBaseName}jimmy"

# Turns off require secure transport on the mysql database flexible server
$requireSecureTransport = Update-AzMySqlFlexibleServerConfiguration -Name require_secure_transport -ResourceGroupName $ResourceGroupName `
    -ServerName $mySQlServerName -Value OFF

# Creates the service plan
az appservice plan create --name $appName --resource-group $ResourceGroupName --is-linux --location $Location --sku P1V2

# Creates the web app
az webapp create --name $appName --plan $appName --resource-group $ResourceGroupName --multicontainer-config-type compose --multicontainer-config-file docker_compose.yml

# Stops the Web app
az webapp stop --name $appName --rg $ResourceGroupName

az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings WEBSITES_CONTAINER_START_TIME_LIMIT=1800
az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings WEBSITES_ENABLE_APP_SERVICE_STORAGE=true


# Gets the storage account key, then mounts it as a storage path on the web app
$key = az storage account keys list  --account-name $storageAccountName --resource-group $ResourceGroupName --query [0].value

az webapp config storage-account add --name $appName --resource-group $ResourceGroupName --account-name $storageAccountName --access-key $key --share-name 'nextcloud-data' --custom-id 'data' --storage-type AzureFiles --mount-path '/var/www/html/data'

# Creates a connection for mysql-flexible for the web app
# This allows the web app and the mysql-flexible server to connect to each other
# Without opening the mysql-flexible server to be open to every Azure IP
az webapp connection create mysql-flexible --name $appName --resource-group $ResourceGroupName --server $mySQlServerName --database $ResourceBaseName --target-resource-group $ResourceGroupName --client-type none --secret name=$DBAdminName secret=$DBPassword

az webapp deployment user set --user-name $appName --password $SFTPPassword

az webapp start --name $appName --rg $ResourceGroupName