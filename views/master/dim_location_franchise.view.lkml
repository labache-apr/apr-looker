# ══════════════════════════════════════════════════════════════
# DIM LOCATION FRANCHISE - Supplemental location data from bi_star
# Provides FranchiseGroupCode/Name not available in embedded
# location STRUCTs from external_datamart_1
# Join to STRUCT-based explores on location.LocationId
# ══════════════════════════════════════════════════════════════

view: dim_location_franchise {
  sql_table_name: `@{schema_name}.bi_star.dim_Location_view` ;;

  # ── User Access / Row-Level Security ──

  dimension: location_code_rls {
    group_label: "User Access"
    type: string
    description: "Location code for row-level security."
    sql: LOWER(${TABLE}.LocationCode) ;;
    case_sensitive: no
  }

  dimension: franchise_code_rls {
    group_label: "User Access"
    type: string
    description: "Franchise code for row-level security. Maps to FranchiseGroupCode."
    sql: LOWER(${TABLE}.FranchiseGroupCode) ;;
    case_sensitive: no
  }

  # ── Location ──

  dimension: location_id {
    primary_key: yes
    description: "Internal identifier for the location. Primary key of this view; join target from STRUCT-based location keys."
    type: string
    sql: ${TABLE}.LocationId ;;
  }

  dimension: location_code {
    description: "Short code (e.g. store number) for the location."
    type: string
    sql: ${TABLE}.LocationCode ;;
  }

  dimension: location_name {
    description: "Friendly name of the location."
    type: string
    sql: ${TABLE}.LocationName ;;
  }

  # ── Franchise ──

  dimension: franchise_group_code {
    description: "Short code identifying the franchise group the location belongs to."
    type: string
    sql: ${TABLE}.FranchiseGroupCode ;;
  }

  dimension: franchise_group_name {
    description: "Friendly name of the franchise group the location belongs to."
    type: string
    sql: ${TABLE}.FranchiseGroupName ;;
  }
}