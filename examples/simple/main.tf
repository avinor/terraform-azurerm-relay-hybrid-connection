module "simple" {

  source = "../../"

  name                = "simple"
  resource_group_name = "simple-arhc-rg"
  location            = "westeurope"

  hybrid_connections = [
    {
      name          = "arch"
      user_metadata = null
      keys = [
        {
          name   = "rule"
          rights = "Listen Manage Send"
        }
      ]
    }
  ]
}