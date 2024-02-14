#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates all the resources we need to create an Nextcloud instance on Azure Web Apps using Containers

.Example
    ./deployandConfigAppService.ps1 -ResourceBaseName nextcloud -ResourceGroupName nextcloud -Location "Central US" -DBdminName ncadmin -DBPassword <password> -SFTPPassword <password>
#>
param(
    [Parameter(Mandatory=$true)][string]$ResourceBaseName,
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$Location,
    [Parameter(Mandatory=$true)][string]$DBAdminName,
    [Parameter(Mandatory=$true)][string]$DBPassword,
    [Parameter(Mandatory=$true)][string]$SFTPPassword,
    [Parameter(Mandatory=$true)][string]$NextcloudAdminName,
    [Parameter(Mandatory=$true)][string]$NextcloudAdminPassword,
    [Parameter(Mandatory=$true)][bool]$UseDockerCompose
)

$mySQlServerName = $ResourceBaseName
$storageAccountName = "${ResourceBaseName}jimmystorage"
$appName = "${ResourceBaseName}jimmy"

# Creates the service plan
az appservice plan create --name $appName --resource-group $ResourceGroupName --is-linux --location $Location --sku P1V2

# Creates the web app
if($UseDockerCompose)
{
    az webapp create --name $appName --plan $appName --resource-group $ResourceGroupName --multicontainer-config-type compose --multicontainer-config-file docker_compose.yml
}
else
{
    az webapp create --name $appName --plan $appName --resource-group $ResourceGroupName --deployment-container-image-name nextcloud:stable
}

# Stops the Web app
az webapp stop --name $appName --resource-group $ResourceGroupName

az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings WEBSITES_CONTAINER_START_TIME_LIMIT=1800
az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings WEBSITES_ENABLE_APP_SERVICE_STORAGE=true

az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings MYSQL_PASSWORD=$DBPassword
az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings MYSQL_DATABASE=nextcloud


az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings MYSQL_USER=$DBAdminName
az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings MYSQL_HOST=nextcloud.mysql.database.azure.com

az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings NEXTCLOUD_ADMIN_USER=$NextcloudAdminName
az webapp config appsettings set --name $appName --resource-group $ResourceGroupName --settings NEXTCLOUD_ADMIN_PASSWORD=$NextcloudAdminPassword

# Gets the storage account key, then mounts it as a storage path on the web app
$key = az storage account keys list  --account-name $storageAccountName --resource-group $ResourceGroupName --query [0].value

Write-Host $key

az webapp config storage-account add --name $appName --resource-group $ResourceGroupName --account-name $storageAccountName --access-key $key --share-name 'nextcloud-data' --custom-id 'data' --storage-type AzureFiles --mount-path '/var/www/html/data'

# Allows our webapp to connect to the server
az mysql flexible-server firewall-rule create --resource-group $ResourceGroupName --name $mySQlServerName --rule-name "AllowAllWindowsAzureIps" --start-ip-address "0.0.0.0" --end-ip-address "0.0.0.0"

az webapp deployment user set --user-name $appName --password $SFTPPassword

az webapp start --name $appName --resource-group $ResourceGroupName