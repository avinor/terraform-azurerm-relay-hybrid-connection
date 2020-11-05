# Azure Relay Hybrid Connection

Module to create an Azure Relay Hybrid Connection Namespace with set of relay hybrid connections


## Usage
Example showing deployment of a namespace with a singe hybrid connection using [tau](https://github.com/avinor/tau)

```hcl-terraform
module {
    source = "github.com/avinor/terraform-azurerm-relay-hybrid-connection?ref=master"
}

inputs {
    name                = "simple"
    location            = "westeurope"
    resource_group_name = "simple-hyco-rg"

    relay_hybrid_connections = [
      {
        name          = "hyco1",
        user_metadata = null,
        keys = [
          {
            name   = "rule1",
            rights = "Listen Manage Send",
          }
       ]
      },
    ]
}
```

Output from the module is the namespace_id, map of hybrid connections and their id

```hcl-terraform
id = /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/simple-hyco-rg/providers/Microsoft.Relay/namespaces/simple-rhcn

name = simple-rhcn

relay_hybrid_connections_ids = {
  "hyco1" = "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/simple-hyco-rg/providers/Microsoft.Relay/namespaces/simple-rhcn/hybridConnections/hyco1"
}


```

## Diagnostics

Diagnostics settings can be sent to either storage account, event hub or Log Analytics workspace. The variable `diagnostics.destination` is the id of receiver, ie. storage account id, event namespace authorization rule id or log analytics resource id. Depending on what id is it will detect where to send. Unless using event namespace the `eventhub_name` is not required, just set to `null` for storage account and log analytics workspace.

Setting `all` in logs and metrics will send all possible diagnostics to destination. If not using `all` type name of categories to send.

## Known issues
Shared Access Polices on hybrid connection is not handle well because if of issue [https://github.com/terraform-providers/terraform-provider-azurerm/issues/7218](https://github.com/terraform-providers/terraform-provider-azurerm/issues/7218)

This is implemented with the use of az relay command as a workaround for the lack of support in the azurerm terraform provider. 

