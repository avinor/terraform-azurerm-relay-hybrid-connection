module "simple" {
  source = "../../"

  name                = "complex"
  resource_group_name = "complex-hyco-rg"
  location            = "westeurope"

  hybrid_connections = [
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
    {
      name          = "hyco2",
      user_metadata = null,
      keys = [
        {
          name   = "rule1",
          rights = "Listen Manage Send",
        }
      ]
    },
  ]

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