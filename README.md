## Creating Nextcloud instances with Azure App Services
Following this here for some of what I need to do, but not following it to the letter:
https://blog.alanlai.me/azure/app-service/app-service-linux/docker/nextcloud/mariadb/2020/10/14/nextcloud-azure-part-1.html

In the end, I mostly ended up following that guide. Unfortunately, it is not possible to deploy the Azure App Service with bicep if you are using a docker_compose file. 

You can use the azure-pipelines.yml to deploy all resources (Deploy the Bicep for Storage Account, Azure Files and Azure Database for MySql Flexible Server) and then deploy and mostly configure the app service. 

You can also use deployNecessaryServices.ps1 followed by deployAndConfigAppService.ps1

After either of the two, you will need to go to the App Service fully-qualified domain names to start up the app. Then enter in your Nextcloud admin username/password, database username, password, database name and the fully qualified domain name for the database. A

After that, you will get an error, so you will need to connect to the app service with SFTP (using the password you supplied to deployAndConfigAppService.ps1). You can find the username and SFTP URL on the App Service resource. Then you will download config.php and add the following line to the end.

'check_data_directory_permissions' => false,

I did try to finish up the configuration, but the Nextcloud Docker image does not allow you to SSH into it. So attempting to sure Azure App Service's SSH feature does not work. I tried to create my own Docker image that was based on the Nextcloud image that started up an sshd server, but it only resulted in errors. I need to work on my Docker skills!