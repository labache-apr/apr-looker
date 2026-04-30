include: "/views/master/customer_master.view.lkml"
include: "/views/custom_fields/customer_custom_fields.view.lkml"
include: "/views/operational/customer_metrics.view.lkml"
include: "/views/operational/dim_customer_location.view.lkml"
include: "/views/operational/customer_attributes.view.lkml"
include: "/views/operational/customer_location_lookups.view.lkml"

# ══════════════════════════════════════════════════════════════
# CUSTOMERS - Customer master data with contacts and addresses
# ══════════════════════════════════════════════════════════════

explore: customer_master {
  label: "Customers"
  description: "Customer master data with contacts and addresses."
  group_label: "Master Data"

  persist_with: master_refresh

  join: customer_contacts {
    view_label: "Customer Contacts"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_master.customer_id} = ${customer_contacts.customer_id} ;;
  }

  join: customer_addresses {
    view_label: "Customer Addresses"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_master.customer_id} = ${customer_addresses.customer_id} ;;
  }

  join: dim_customer_location {
    view_label: "Customer Locations"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_master.customer_id} = ${dim_customer_location.customer_id} ;;
  }

  join: customer_attributes {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: one_to_one
    sql_on: ${customer_master.customer_id} = ${customer_attributes.customer_id} ;;
  }

  join: last_receipt_location {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: many_to_one
    sql_on: ${customer_attributes.last_receipt_location_id} = ${last_receipt_location.location_id} ;;
  }

  join: preferred_location {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: many_to_one
    sql_on: ${customer_attributes.preferred_location_name_raw} = ${preferred_location.location_name} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# CUSTOMER PERFORMANCE - Customer metrics & performance analysis
# ══════════════════════════════════════════════════════════════

explore: customer_performance {
  from: customer_master
  view_label: "Customer Profile"
  label: "Customer Performance"
  description: "Customer master data enriched with lifetime performance metrics: spend, frequency, recency, margin, and return rates."
  group_label: "Customers"

  persist_with: daily_refresh

  # ── Customer Metrics (aggregated from sales receipts) ──
  join: customer_metrics {
    view_label: "Customer Metrics"
    type: left_outer
    relationship: one_to_one
    sql_on: ${customer_performance.customer_id} = ${customer_metrics.customer_id} ;;
  }

  # ── Contacts & Addresses ──
  join: customer_contacts {
    view_label: "Customer Contacts"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_performance.customer_id} = ${customer_contacts.customer_id} ;;
  }

  join: customer_addresses {
    view_label: "Customer Addresses"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_performance.customer_id} = ${customer_addresses.customer_id} ;;
  }

  # ── All Customer-Location Associations ──
  join: dim_customer_location {
    view_label: "Customer Locations"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_performance.customer_id} = ${dim_customer_location.customer_id} ;;
  }

  join: customer_attributes {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: one_to_one
    sql_on: ${customer_performance.customer_id} = ${customer_attributes.customer_id} ;;
  }

  join: last_receipt_location {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: many_to_one
    sql_on: ${customer_attributes.last_receipt_location_id} = ${last_receipt_location.location_id} ;;
  }

  join: preferred_location {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: many_to_one
    sql_on: ${customer_attributes.preferred_location_name_raw} = ${preferred_location.location_name} ;;
  }
}
