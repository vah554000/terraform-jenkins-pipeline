terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}


provider "aci" {
  # APIC Username
  username = "admin"
  # APIC Password
  password = "!@#123QWEqwe"
  # APIC URL
  url      = "https://ddns554.ddns.net"
  insecure = true
}

resource "aci_tenant" "tenants" {
  count = length(local.tenants)
  name  = local.tenants[count.index]
}
