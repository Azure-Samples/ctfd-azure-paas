# CTFd on Azure PaaS

This project sets up a self-hosted, secured [CTFd][ctfd] environment, using Azure PaaS, that is easy to maintain.
It supports the *Capture-the-Flag with CTFd on Azure PaaS* content on the [Azure Architecture Center](link.com TODO:).

## Features

![CTFd architecture](/assets/architecture-with-vnet.png)

This project provides the following features:

* Infrastructure as Code with [Azure Bicep][bicep].
* High scale that meets different team sizes with [Azure App Service Web App for Containers][app-service].
* Backend database and cache provided with Azure PaaS [Database for MariaDB][mariadb] and [Cache for Redis][redis].
* Secrets management using [Azure Key Vault][keyvault].
* Log Management with [Azure Log Analytics][log-analytics].
* Adjustable level of network isolation: The solution can be provisioned either with or without virtual network. Private networking is provided using [Private Endpoints][private-endpoint] and [App Service VNet Integration][vnet-integration].
* Custom CTFd container image built and hosted on [Azure Container Registry][container-registry] with certificates to allow TLS connectivity to [Azure Database for MariaDB][mariadb].
  * The image is based off the community CTFd image layered with the certificate required to communicate with Azure [Database for MariaDB over TLS](https://learn.microsoft.com/en-us/azure/mariadb/concepts-ssl-connection-security).

## Getting Started

### Prerequisites

* [Azure CLI][az-cli-installation]
* Azure Subscription with at least a Resource-Group's Contributor access

### Quickstart

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fctfd-azure-paas%2Fmain%2Fazuredeploy.json)


```bash
git clone https://github.com/Azure-Samples/ctfd-azure-paas.git
cd ctfd-azure-paas

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

By default the solution isolates network traffic from the CTFd App Service to the internal services (database, cache and key mangement) using a virtual network.
You may reduce the solution complexity and potentially optimize cost by provisioning it without network isolation using the following command:

```bash
az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file ctfd.bicep --parameters administratorLoginPassword=$DB_PASSWORD  --vnet False
```

When provisioing the solution without a virtual network, the archicture diagram should look like this:

![CTFd architecture without vnet](/assets/architecture-without-vnet.png)

### Cleanup

Delete the resource group using the following command

```bash
az group delete -n $RESOURCE_GROUP_NAME
```

### Additinal Configuratin Options

The template deployment can be further configured using the following parameters:

* **resourcesLocation** - Location for all resources. Defaults to the resource group location.
* **vnet** - Deploy the solution with VNet. Defaults to True
* **redisSkuName** - Azure Cache for Redis SKU Name. More info at [Azure Cache for Redis Pricing][redis-pricing]
* **redisSkuSize** - Azure Cache for Redis SKU Size. More info at [Azure Cache for Redis Pricing][redis-pricing]
* **administratorLogin** - Admin Login of Azure Database for MariaDB
* **administratorLoginPassword** - Admin Password of Azure Database for MariaDB
* **databaseVCores** -Azure Database for MariaDB VCores. More info at [Azure Database for MariaDB Pricing][mariadb-pricing]
* **appServicePlanSkuName** - Azure App Service Plan SKU Name. More info at [Azure App Service Pricing][app-service-pricing]
* **webAppName** - Azure App Service Name. Controls the DNS name of the CTF site.

## Contribute to this project

Follow the [Contribution Guide](./CONTRIBUTING.md)

## Resources

* [App Services - Web App for container][app-service]
* [Azure Database for MariaDB][mariadb]
* [Azure Cache for Redis][redis]
* [Azure Key Vault][keyvault]
* [Azure Log Analytics][log-analytics]
* [Azure Networking][azure-networking]
* [Azure Container Registry][container-registry]

<!-- Links -->
[ctfd]: https://github.com/CTFd/CTFd
[bicep]: https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview?tabs=bicep
[app-service]: https://azure.microsoft.com/products/app-service/containers/
[mariadb]: https://azure.microsoft.com/services/mariadb/
[redis]: https://www.microsoft.com/azure/redis-cache/cache-overview
[keyvault]: https://azure.microsoft.com/services/key-vault
[log-analytics]: https://learn.microsoft.com/azure/azure-monitor/log-query/log-analytics-overview
[private-endpoint]: https://learn.microsoft.com/azure/private-link/private-endpoint-overview
[vnet-integration]: https://learn.microsoft.com/azure/app-service/overview-vnet-integration
[az-cli-installation]: https://learn.microsoft.com/cli/azure/install-azure-cli
[azure-networking]: https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview
[container-registry]: https://learn.microsoft.com/azure/container-registry/
[redis-pricing]: https://azure.microsoft.com/pricing/details/cache/
[mariadb-pricing]: https://learn.microsoft.com/azure/mariadb/concepts-pricing-tiers
[app-service-pricing]: https://azure.microsoft.com/pricing/details/app-service/linux/