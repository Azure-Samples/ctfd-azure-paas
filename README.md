# CTFd on Azure PaaS

This project sets up a self-hosted, scalable, secured, and easy to maintain [CTFd][ctfd] environment using Azure PaaS.

## Features

![CTFd architecture](/assets/ctfd.svg)

This project provides the following features:

* Infrastructure as Code with [Azure Bicep][bicep].
* High scale that meets different team sizes with [Azure App Service Web App for Containers][app-service].
* Backend database and cache provided with Azure PaaS [Database for MariaDB][mariadb] and [Cache for Redis][redis].
* Secrets management using [Azure Key Vault][keyvault].
* Log Management with [Azure Log Analytics][log-analytics].
* Private networking with [Private Endpoints][private-endpoint] and [App Service VNet Integration][vnet-integration].

## Getting Started

### Prerequisites

* [Azure CLI][az-cli-installation]
* Azure Subscription with Contributor access
* Azure Active Directory access

### Quickstart

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fctfd-azure-paas%2Fmaster%2Fazuredeploy.json)


```bash
git clone https://github.com/Azure-Samples/ctfd-azure-paas.git
cd ctfd-azure-paas

export DB_PASSWORD='YOUR PASSWORD'
export RESOURCE_GROUP_NAME='RESOURCE GROUP NAME'

az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file ctfd.bicep --parameters administratorLoginPassword=$DB_PASSWORD 
```

## Resources

* [App Services - Web App for container][app-service]
* [Azure Database for MariaDB][mariadb]
* [Azure Cache for Redis][redis]
* [Azure Key Vault][keyvault]
* [Azure Log Analytics][log-analytics]
* [Azure Networking][azure-networking]

<!-- Links -->
[ctfd]: https://github.com/CTFd/CTFd
[bicep]: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep
[app-service]: https://azure.microsoft.com/en-us/products/app-service/containers/
[mariadb]: https://azure.microsoft.com/services/mariadb/
[redis]: https://www.microsoft.com/azure/redis-cache/cache-overview
[keyvault]: https://azure.microsoft.com/services/key-vault
[log-analytics]: /azure/azure-monitor/log-query/log-analytics-overview
[private-endpoint]: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview
[vnet-integration]: https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration
[az-cli-installation]: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
[azure-networking]: /azure/virtual-network/virtual-networks-overview