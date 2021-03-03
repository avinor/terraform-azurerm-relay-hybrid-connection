module "simple" {

  source = "../../"

  name                = "complex"
  resource_group_name = "complex-arch-rg"
  location            = "westeurope"

  hybrid_connections = [
    {
      name          = "arhc1"
      user_metadata = null
      keys = [
        {
          name   = "rule1"
          rights = "Listen Manage Send"
        }
      ]
    },
    {
      name          = "arhc2"
      user_metadata = null
      keys = [
        {
          name   = "rule2"
          rights = "Listen Manage Send"
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