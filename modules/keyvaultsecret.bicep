@description('Name of Azure Key Vault')
param keyVaultName string

@description('Name of the secret')
param secretName string

@description('Value of the secret')
@secure()
param secretValue string

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${keyVaultName}/${secretName}'
  properties: {
    value: secretValue
  }
}
