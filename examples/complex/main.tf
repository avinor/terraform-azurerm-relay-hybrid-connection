module "simple" {
  source = "../../"

  name                = "complex"
  resource_group_name = "complex-hyco-rg"
  location            = "westeurope"

  hybrid_connections = [
    {
      name          = "hyco1",
      user_metadata = null,
      //keys =  [
      //    {
      //      name   = "rule1",
      //      listen = true,
      //      send   = false,
      //      manage = false,
      //    }
    },
    {
      name          = "hyco2",
      user_metadata = null,
    },
  ]

  //  authorization_rules = [
  //    {
  //      name   = "rule1",
  //      listen = true,
  //      send   = false,
  //      manage = false,
  //    }
  //  ]

  diagnostics = {
    destination   = "some destination"
    eventhub_name = "diagnostics"
    logs          = ["all"]
    metrics       = ["all"]
  }

  tags = {
    tag1 = "value1"
  }
}