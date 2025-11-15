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

resource "aci_tenant" "Tenant_vahid_1" {
  name = "Tenant_vahid_1"
}

