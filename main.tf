terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}


#variable "x1" { 
# type=number
#}

# Configure the provider with your Cisco APIC credentials.
provider "aci" {
  # APIC Username
  username = "admin"
  # APIC Password
  password = "!@#123QWEqwe"
  # APIC URL
  url      = "https://ddns554.ddns.net"
  insecure = true
}


#locals {
#  tenants = [for i in range(var.x1) : "Tenant-${i + 1}"]
#  
#}
#
#resource "aci_tenant" "tenants" {
#  count = length(local.tenants)
#  name  = local.tenants[count.index]
#}


resource "aci_vlan_pool" "vlan_pool_vahid_120" {
  name        = "vlan_pool_vahid_120"
  alloc_mode  = "dynamic"   # static | dynamic
  description = "Production VLAN Pool created via Terraform"
}


resource "aci_vlan_pool" "vlan_pool_vahid" {
  name        = "vlan_pool_vahid"
  alloc_mode  = "dynamic"   # static | dynamic
  description = "Production VLAN Pool created via Terraform"
}

resource "aci_ranges" "vlan_ranges" {
  vlan_pool_dn = aci_vlan_pool.vlan_pool_vahid.id  # link to the pool
  from         = "vlan-1000"
  to           = "vlan-2000"
  alloc_mode   = "inherit"
  role         = "external"       # internal or external
}


resource "aci_physical_domain" "dom_phy_vahid" {
  name        = "dom_phy_vahid"
  annotation  = "tag_domain"
  name_alias  = "vlan_pool_vahid"
  relation_infra_rs_vlan_ns = (aci_vlan_pool.vlan_pool_vahid.id)
}

resource "aci_attachable_access_entity_profile" "aep_vahid" {
  description = "AAEP description"
  name        = "aep_vahid"
  annotation  = "tag_entity"
  name_alias  = "aep_vahid"
}

resource "aci_aaep_to_domain" "aep_to_domain_vahid" {
  attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.aep_vahid.id
  domain_dn                           = aci_physical_domain.dom_phy_vahid.id
}


resource "aci_leaf_access_port_policy_group" "access_port_policy_group_vahid" {
    description = "From Terraform"
    name        = "access_port_policy_group_vahid"
    annotation  = "tag_ports"
    name_alias  = "name_alias"
	relation_infra_rs_att_ent_p = (aci_attachable_access_entity_profile.aep_vahid.id)
} 


resource "aci_leaf_access_bundle_policy_group" "port_channel_policy_group_vahid" {
  name        = "port_channel_policy_group_vahid"
  annotation  = "bundle_policy_example"
  description = "From Terraform"
  lag_t       = "link"
  name_alias  = "bundle_policy"
  relation_infra_rs_att_ent_p = (aci_attachable_access_entity_profile.aep_vahid.id)

}

resource "aci_leaf_access_bundle_policy_group" "Virtual_port_channel_policy_group_vahid" {
  name        = "Virtual_port_channel_policy_group_vahid"
  annotation  = "bundle_policy_example"
  description = "From Terraform"
  lag_t       = "node"
  name_alias  = "bundle_policy"
  relation_infra_rs_att_ent_p = (aci_attachable_access_entity_profile.aep_vahid.id)

}


resource "aci_leaf_interface_profile" "int_profile_vahid" {
    description = "From Terraform"
    name        = "int_profile_vahid"
    annotation  = "tag_leaf"
    name_alias  = "int_profile_vahid"
}



resource "aci_access_port_selector" "int_port_selector_vahid" {
    leaf_interface_profile_dn = aci_leaf_interface_profile.int_profile_vahid.id
    description               = "from terraform"
    name                      = "int_port_selector_vahid"
    access_port_selector_type = "range"
    annotation                = "tag_port_selector"
    name_alias                = "int_port_selector_vahid"
#	relation_infra_rs_acc_base_grp = aci_leaf_access_port_policy_group.access_port_policy_group_vahid.id
#	relation_infra_rs_acc_base_grp = aci_leaf_access_bundle_policy_group.port_channel_policy_group_vahid.id
	relation_infra_rs_acc_base_grp = aci_leaf_access_bundle_policy_group.Virtual_port_channel_policy_group_vahid.id
	
	
}

resource "aci_access_port_block" "interface_port_block_vahid" {
  access_port_selector_dn           = aci_access_port_selector.int_port_selector_vahid.id
  name                              = "interface_port_block_vahid"
  description                       = "From Terraform"
  annotation                        = "tag_port_block"
  from_port                         = "13"
  name_alias                        = "alias_port_block"
  to_port                           = "14"
  
}


resource "aci_leaf_profile" "Leaf_101_profile_vahid" {
  name        = "Leaf_101_profile_vahid"
  description  = "From Terraform"
  annotation  = "example"
  name_alias  = "Leaf_101_profile_vahid"
  leaf_selector {
    name                    = "one"
    switch_association_type = "range"
    node_block {
      name  = "blk1"
      from_ = "101"
      to_   = "101"
    }
   
    }
  }
  
  


resource "aci_rest" "leaf_profile_to_int_profile_association" {
 path		= "/api/mo/${aci_leaf_profile.Leaf_101_profile_vahid.id}/rsaccPortP-[${aci_leaf_interface_profile.int_profile_vahid.id}].json"
 class_name = "infraRsAccPortP"
 content = {
  "tDn" : aci_leaf_interface_profile.int_profile_vahid.id
 }

}


##########################################################################################
#create VPC domain
##########################################################################################

resource "aci_vpc_explicit_protection_group" "VPC_domain_vahid" {
  name                              = "VPC_domain_vahid"
  annotation                        = "tag_vpc"
  switch1                           = "101"
  switch2                           = "102"
  vpc_domain_policy                 = "default"
  vpc_explicit_protection_group_id  = "100"
}


##########################################################################################
#create Tenant
##########################################################################################

resource "aci_tenant" "Tenant_vahid" {
  name = "Tenant_vahid"
}

##########################################################################################
#create VRFF
##########################################################################################

resource "aci_vrf" "VRF_vahid" {
  parent_dn = aci_tenant.Tenant_vahid.id
  name      = "VRF_vahid"
  pc_enf_dir = "egress"
  pc_enf_pref = "unenforced"
}

##########################################################################################
#create Bridge Doamain
##########################################################################################

resource "aci_bridge_domain" "bd_vahid" {
  name      = "bd_vahid"
  tenant_dn = aci_tenant.Tenant_vahid.id

  arp_flood = "no"
  unicast_route = "yes"
  relation_to_vrf = {
    annotation = "annotation_1"
    vrf_name   = aci_vrf.VRF_vahid.name
      }
}


##########################################################################################
#create Subnet
##########################################################################################


resource "aci_subnet" "subnet_vahid" {
  parent_dn     = aci_bridge_domain.bd_vahid.id
  ip            = "10.10.10.1/24"
  scope         = ["public"]     # private, public, shared
  preferred     = "yes"
  virtual       = "no"
}



##########################################################################################
#create Application profile
##########################################################################################


resource "aci_application_profile" "App_Profile_vahid" {
  parent_dn   = aci_tenant.Tenant_vahid.id
  annotation  = "annotation"
  description = "description_1"
  name        = "App_Profile_vahid"
  name_alias  = "App_Profile_vahid"
  owner_key   = "owner_key_1"
  owner_tag   = "owner_tag_1"
  priority    = "level1"
}



##########################################################################################
#create EPG
##########################################################################################


resource "aci_application_epg" "EPG_Vahid" {
  parent_dn = aci_application_profile.App_Profile_vahid.id
  name      = "EPG_Vahid"
  pc_enf_pref = "unenforced"
  pref_gr_memb = "include"
  relation_fv_rs_bd = aci_bridge_domain.bd_vahid.id
}

resource "aci_epg_to_domain" "epg_to_domain_vahid" {
  application_epg_dn    = aci_application_epg.EPG_Vahid.id
  tdn                   = aci_physical_domain.dom_phy_vahid.id
 }

##########################################################################################
#create EPG static port
##########################################################################################

#!---Static port Trunk
resource "aci_epg_to_static_path" "epg_static_port_trunk_vahid" {
  application_epg_dn  = aci_application_epg.EPG_Vahid.id
  tdn  = "topology/pod-1/paths-101/pathep-[eth1/1]"  
  annotation = "annotation"
  encap  = "vlan-1100"
  instr_imedcy = "lazy"
  mode  = "regular"
  primary_encap ="vlan-1200"
}


#!---Static port untagged
resource "aci_epg_to_static_path" "epg_static_port_Access_vahid" {
  application_epg_dn  = aci_application_epg.EPG_Vahid.id
  tdn  = "topology/pod-1/paths-101/pathep-[eth1/2]"
  annotation = "annotation"
  encap  = "vlan-1300"
  instr_imedcy = "lazy"
  mode  = "untagged"
  primary_encap ="vlan-1200"
}


#!---Static port VPC Trunk
resource "aci_epg_to_static_path" "epg_static_port_vpc_trunk_vahid" {
  application_epg_dn  = aci_application_epg.EPG_Vahid.id
  tdn = "topology/pod-1/protpaths-101-102/pathep-[Virtual_port_channel_policy_group_vahid]"
  annotation = "annotation"
  encap  = "vlan-1400"
  instr_imedcy = "lazy"
  mode  = "regular"
  primary_encap ="vlan-1200"
}


#!---Static port Port-channel Trunk
resource "aci_epg_to_static_path" "epg_static_port_Port-Channel_trunk_vahid" {
  application_epg_dn  = aci_application_epg.EPG_Vahid.id
  tdn = "topology/pod-1/paths-101/pathep-[port_channel_policy_group_vahid]"  
  annotation = "annotation"
  encap  = "vlan-1500"
  instr_imedcy = "lazy"
  mode  = "regular"
  primary_encap ="vlan-1200"
}

##########################################################################################
#create Contract-Subject-Filter
##########################################################################################

 resource "aci_contract" "contract_vahid" {
  tenant_dn   =  aci_tenant.Tenant_vahid.id
  description = "From Terraform"
  name        = "contract_vahid"
  annotation  = "tag_contract"
  name_alias  = "contract_vahid"
  prio        = "level1"
  scope       = "tenant"
  target_dscp = "unspecified"
 }
 
resource "aci_contract_subject" "subject2_vahid" {
  contract_dn = aci_contract.contract_vahid.id
  name        = "subject2_vahid"

  # Apply filter
  relation_vz_rs_subj_filt_att = [
    aci_filter.filter1_vahid.id
  ]

  # Enable "Apply Both Directions" checkbox
  apply_both_directions = "yes"
  rev_flt_ports = "yes"
}
	

resource "aci_filter" "filter1_vahid" {
  tenant_dn   = aci_tenant.Tenant_vahid.id
  description = "From Terraform"
  name        = "filter1_vahid"
  annotation  = "tag_filter"
  name_alias  = "filter1_vahid"
}
	
resource "aci_filter_entry" "filter_entry1_vahid" {
        filter_dn     = aci_filter.filter1_vahid.id
        description   = "From Terraform"
        name          = "filter_entry1_vahid"
        annotation    = "tag_entry"
        apply_to_frag = "no"
        arp_opc       = "unspecified"
        d_from_port   = "80"
        d_to_port     = "80"
        ether_t       = "ipv4"
        icmpv4_t      = "unspecified"
        icmpv6_t      = "unspecified"
        match_dscp    = "CS0"
        name_alias    = "filter_entry1_vahid"
        prot          = "tcp"
        s_from_port   = "0"
        s_to_port     = "0"
        stateful      = "no"
        tcp_rules     = ["ack","rst"]
    }
	
 
 
###########################################################################################
##create L3out
###########################################################################################
#
#
#resource "aci_vlan_pool" "vlan_pool_L3out_vahid" {
#  name        = "vlan_pool_L3out_vahid"
#  alloc_mode  = "static"   # static | dynamic
#  description = "Production VLAN Pool created via Terraform"
#}
#
#resource "aci_ranges" "vlan_ranges_L3out_vahid" {
#  vlan_pool_dn = aci_vlan_pool.vlan_pool_L3out_vahid.id  # link to the pool
#  from         = "vlan-2001"
#  to           = "vlan-2999"
#  alloc_mode   = "inherit"
#  role         = "external"       # internal or external
#}
#
#resource "aci_l3_domain_profile" "l3_domain_profile_vahid" {
#  name  = "l3_domain_profile_vahid"
#  annotation  = "l3_domain_profile_tag"
#  name_alias  = "l3_domain_profile_vahid"
#  relation_infra_rs_vlan_ns = (aci_vlan_pool.vlan_pool_L3out_vahid.id)
#}
#
#resource "aci_attachable_access_entity_profile" "aep_L3out_vahid" {
#  description = "AAEP description"
#  name        = "aep_L3out_vahid"
#  annotation  = "tag_entity"
#  name_alias  = "aep_L3out_vahid"
#}
#
#resource "aci_aaep_to_domain" "aep_to_domain_L3out_vahid" {
#  attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.aep_L3out_vahid.id
#  domain_dn                           = aci_l3_domain_profile.l3_domain_profile_vahid.id
#}
#
#
#
#
#resource "aci_l3_outside" "l3_outside_vahid" {
#  tenant_dn      = aci_tenant.Tenant_vahid.id
#  name           = "l3_outside_vahid"
#  enforce_rtctrl = ["export", "import"]
#  target_dscp    = "unspecified"
#  mpls_enabled   = "yes"
#
##  // Target VRF object should belong to the parent tenant or be a shared object.
#  relation_l3ext_rs_ectx = aci_vrf.VRF_vahid.id
#
##  // Relation to L3 Domain
#  relation_l3ext_rs_l3_dom_att = aci_l3_domain_profile.l3_domain_profile_vahid.id
#}
#
#resource "aci_logical_node_profile" "L3out_node_prof_vahid" {
#  l3_outside_dn = aci_l3_outside.l3_outside_vahid.id
#  name          = "L3out_node_prof_vahid"
#}
#
#resource "aci_logical_node_to_fabric_node" "L3out_node-101_vahid" {
#  logical_node_profile_dn = aci_logical_node_profile.L3out_node_prof_vahid.id
#  tdn                     = "topology/pod-1/node-101"
#  rtr_id                  = "10.10.10.101"
#  rtr_id_loop_back        = "yes"
#}
#
#
#
#
#resource "aci_logical_interface_profile" "L3out_logical_int_profile_vahid" {
#  logical_node_profile_dn = aci_logical_node_profile.L3out_node_prof_vahid.id
#  name                    = "L3out_logical_int_profile_vahid"
#}


















#---------------------------
# # variable.tf file
# variable "num_vlan_pools" {
#   type        = number
#   description = "Number of VLAN pools to create"
# }
# 
# variable "vlan_start" {
#   type        = number
#   description = "Starting VLAN ID for the first pool"
# }
# 
# variable "vlans_per_pool" {
#   type        = number
#   description = "Number of VLANs in each pool"
# }
# 
# variable "vlan_pool_prefix" {
#   type    = string
#   default = "VLAN-Pool"
# }
# 
# ################ main.tf
# #1. Generate VLAN pool names
# locals {
#   vlan_pools = [
#     for i in range(var.num_vlan_pools) : "${var.vlan_pool_prefix}-${i + 1}"
#   ]
# }
# 
# #2. Create VLAN pools dynamically
# resource "aci_vlan_pool" "pools" {
#   for_each   = toset(local.vlan_pools)
#   name       = each.value
#   alloc_mode = "dynamic"
# }
# 
# #3. Calculate VLAN ranges for each pool
# locals {
#   vlan_ranges = flatten([
#     for i in range(var.num_vlan_pools) : [
#       for j in range(var.vlans_per_pool) : {
#         pool_name = local.vlan_pools[i]
#         vlan_id   = var.vlan_start + i * var.vlans_per_pool + j
#       }
#     ]
#   ])
# }
# 
# 
# #4. Create VLAN ranges dynamically
# resource "aci_ranges" "vlan_ranges" {
#   for_each = {
#     for r in local.vlan_ranges : "${r.pool_name}-${r.vlan_id}" => r
#   }
# 
#   vlan_pool_dn = aci_vlan_pool.pools[each.value.pool_name].id
#   from         = "vlan-${each.value.vlan_id}"
#   to           = "vlan-${each.value.vlan_id}"
#   alloc_mode   = "inherit"
#   role         = "external"
# }
# 
# 
# 
# 
# #example
# terraform apply \
#   -var="num_vlan_pools=3" \
#   -var="vlan_start=100" \
#   -var="vlans_per_pool=5"
#   
#   
# Result:
# 3 VLAN Pools: VLAN-Pool-1, VLAN-Pool-2, VLAN-Pool-3
# 
# Each pool has 5 VLANs:
# 
# VLAN-Pool-1 → 100–104
# 
# VLAN-Pool-2 → 105–109
# 
# VLAN-Pool-3 → 110–114
