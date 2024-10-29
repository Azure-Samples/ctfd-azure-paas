# CTFd on Azure PaaS

This project sets up a self-hosted, secured [CTFd][ctfd] environment, using Azure PaaS, that is easy to maintain.
It supports the *Capture-the-Flag with CTFd on Azure PaaS* content on the [Azure Architecture Center][azure-arch-ctfd-paas].

## Features

![CTFd architecture](/assets/architecture-with-vnet.png)

This project provides the following features:

* Infrastructure as Code with [Azure Bicep][bicep].
* High scale that meets different team sizes with [Azure App Service Web App for Containers][app-service].
* Backend database and cache provided with Azure PaaS [Database for MySQL][mysql] and [Cache for Redis][redis].
* Persistent file storage provided with [Azure Files][azure-files] using a [mounted SMB share][app-service-connect-storage]
* Secrets management using [Azure Key Vault][keyvault].
* Log Management with [Azure Log Analytics][log-analytics].
* Adjustable level of network isolation: The solution can be provisioned either with or without virtual network. Private networking is provided using [Private Endpoints][private-endpoint] and [App Service VNet Integration][vnet-integration].
* Custom CTFd container image built and hosted on [Azure Container Registry][container-registry] with certificates to allow TLS connectivity to [Azure Database for MySQL][mysql].
  * The image is based off the community CTFd image layered with the certificate required to communicate with Azure [Database for MySQL over TLS](https://learn.microsoft.com/en-us/azure/mysql/single-server/how-to-configure-ssl).

## Getting Started

### Prerequisites

* [Azure CLI][az-cli-installation]
* Azure Subscription with at least a Resource-Group's Contributor access

### Quickstart

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fctfd-azure-paas%2Fmain%2Fazuredeploy.json)

```bash
git clone https://github.com/Azure-Samples/ctfd-azure-paas.git
cd ctfd-azure-paas

# This is bash syntax. if using Powershell, add $ sign before the assignments (i.e. $DB_PASSWORD='YOUR PASSWORD')
DB_PASSWORD='YOUR PASSWORD'
RESOURCE_GROUP_NAME='RESOURCE GROUP NAME'

az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file ctfd.bicep --parameters administratorLoginPassword=$DB_PASSWORD 
```

### Access and Configure CTFd

* Navigate your browser to the App Service URL, in the form of `*https://[YOUR APP SERVICE NAME].azurewebsites.net*`
* Configure your Capture the Flag event using the administrator dashboard. more info [here](https://docs.ctfd.io/tutorials/getting-started)

### Troubleshooting and debugging

* Navigate to the Log Analytics workspace in the resource group.
* Check logs from CTFd container(s) using the table AppServiceConsoleLogs

### Adjustable Network Isolation

By default the solution isolates network traffic from the CTFd App Service to the internal services (database, cache and key management) using a virtual network.
You may reduce the solution complexity and potentially optimize cost by provisioning it without network isolation using the following command:

```bash
az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file ctfd.bicep --parameters administratorLoginPassword=$DB_PASSWORD --parameters vnet=False
```

When provisioning the solution without a virtual network, the architecture diagram should look like this:

![CTFd architecture without vnet](/assets/architecture-without-vnet.png)

### Cleanup

Delete the resource group using the following command

```bash
az group delete -n $RESOURCE_GROUP_NAME
```

### Additional Configuration Options

The template deployment can be further configured using the following parameters:

* **resourcesLocation** - Location for all resources. Defaults to the resource group location.
* **vnet** - Deploy the solution with VNet. Defaults to True
* **redisSkuName** - Azure Cache for Redis SKU Name. More info at [Azure Cache for Redis Pricing][redis-pricing]
* **redisSkuSize** - Azure Cache for Redis SKU Size. More info at [Azure Cache for Redis Pricing][redis-pricing]
* **administratorLogin** - Admin Login of Azure Database for MySQL
* **administratorLoginPassword** - Admin Password of Azure Database for MySQL
* **mysqlType** - Azure Database for MySQL Workload Type. Can be either Development, SmallMedium or BusinessCritical. This affects the underlying virtual machine size as well as the storage capacity. More info at [Azure Database for MySQL Pricing][mysql-pricing]
* **appServicePlanSkuName** - Azure App Service Plan SKU Name. More info at [Azure App Service Pricing][app-service-pricing]
* **webAppName** - Azure App Service Name. Controls the DNS name of the CTF site.

## Contribute to this project

Follow the [Contribution Guide](./CONTRIBUTING.md)

## Resources

* [App Services - Web App for container][app-service]
* [Azure Database for MySQL][mysql]
* [Azure Cache for Redis][redis]
* [Azure Key Vault][keyvault]
* [Azure Log Analytics][log-analytics]
* [Azure Networking][azure-networking]
* [Azure Container Registry][container-registry]
* [Azure Files][azure-files]

<!-- Links -->
[ctfd]: https://github.com/CTFd/CTFd
[bicep]: https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview?tabs=bicep
[app-service]: https://azure.microsoft.com/products/app-service/containers/
[mysql]: https://azure.microsoft.com/services/mysql/
[redis]: https://www.microsoft.com/azure/redis-cache/cache-overview
[keyvault]: https://azure.microsoft.com/services/key-vault
[log-analytics]: https://learn.microsoft.com/azure/azure-monitor/log-query/log-analytics-overview
[private-endpoint]: https://learn.microsoft.com/azure/private-link/private-endpoint-overview
[vnet-integration]: https://learn.microsoft.com/azure/app-service/overview-vnet-integration
[az-cli-installation]: https://learn.microsoft.com/cli/azure/install-azure-cli
[azure-networking]: https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
[container-registry]: https://learn.microsoft.com/azure/container-registry/
[redis-pricing]: https://azure.microsoft.com/pricing/details/cache/
[mysql-pricing]: https://learn.microsoft.com/en-gb/azure/mysql/single-server/concepts-pricing-tiers
[app-service-pricing]: https://azure.microsoft.com/pricing/details/app-service/linux/
[azure-files]: https://learn.microsoft.com/en-us/azure/storage/files/storage-files-introduction
[app-service-connect-storage]: https://learn.microsoft.com/en-us/azure/app-service/configure-connect-to-azure-storage
[azure-arch-ctfd-paas]: https://learn.microsoft.com/en-us/azure/architecture/example-scenario/apps/capture-the-flag-platform-on-azure-paas