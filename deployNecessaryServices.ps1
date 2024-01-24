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
    [Parameter(Mandatory=$true)][string]$DBPassword
)

New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location

$DBAdminPassword = ConvertTo-SecureString $DBPassword -AsPlainText -Force

New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name main -TemplateFile ./bicep/main.bicep `
    -resourceBaseName $ResourceBaseName -location $Location -vnetName $VNetName -storageAccountSkuName "Standard_LRS" `
    -storageAccountKind "StorageV2" -administratorLogin $DBAdminName ` -administratorLoginPassword $DBAdminPassword


$mySQlServerName = $ResourceBaseName

# Turns off require secure transport on the mysql database flexible server
$requireSecureTransport = Update-AzMySqlFlexibleServerConfiguration -Name require_secure_transport -ResourceGroupName $ResourceGroupName `
    -ServerName $mySQlServerName -Value OFF