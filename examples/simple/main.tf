module "simple" {
  source = "../../"

  name                = "simple"
  resource_group_name = "simple-hyco-rg"
  location            = "westeurope"

  hybrid_connections = [
    {
      name          = "hyco1",
      user_metadata = null,
    }
  ]
}