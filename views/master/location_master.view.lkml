# ══════════════════════════════════════════════════════════════
# LOCATION MASTER - from bi_star.dim_Location_view (82 columns)
# Sourced from bi_star instead of external_datamart_1 to include
# FranchiseGroupCode and FranchiseGroupName fields
# ══════════════════════════════════════════════════════════════

view: location_master {
  sql_table_name: `aefc-prod-us-twc-b1bc.bi_star.dim_Location_view` ;;

  dimension: franchise_group_code {
    group_label: "Franchise"
    description: "Short code identifying the franchise group the location belongs to. Drives RLS via dim_location_franchise."
    type: string
    sql: ${TABLE}.FranchiseGroupCode ;;
  }

  dimension: franchise_group_name {
    group_label: "Franchise"
    description: "Friendly name of the franchise group the location belongs to."
    type: string
    sql: ${TABLE}.FranchiseGroupName ;;
  }

  # ── Identifiers ──

  dimension: location_id {
    primary_key: yes
    group_label: "Location Identifiers"
    description: "Internal identifier for the location. Primary key of this view."
    type: string
    sql: ${TABLE}.LocationId ;;
  }

  dimension: surrogate_location_id {
    group_label: "Location Identifiers"
    type: number
    sql: ${TABLE}.SurrogateLocationId ;;
    hidden: yes
    description: "INT64 surrogate key - use for high-performance joins"
  }

  dimension: location_code {
    group_label: "Location Identifiers"
    description: "Short code (e.g. store number) used to identify the location in operational systems."
    type: string
    sql: ${TABLE}.LocationCode ;;
  }

  dimension: location_name {
    group_label: "Location Identifiers"
    description: "Friendly name of the location."
    type: string
    sql: ${TABLE}.LocationName ;;
  }

  dimension: label {
    group_label: "Location Identifiers"
    description: "Display label for the location, typically combining code and name."
    type: string
    sql: ${TABLE}.Label ;;
  }

  # ── Address ──

  dimension: address    { group_label: "Location Address" description: "Street address of the location." type: string sql: ${TABLE}.Adress ;; }  # Note: source column is 'Adress' (typo)
  dimension: city       { group_label: "Location Address" description: "City of the location." type: string sql: ${TABLE}.City ;; }
  dimension: state      { group_label: "Location Address" description: "State or province of the location." type: string sql: ${TABLE}.State ;; }
  dimension: country    { group_label: "Location Address" description: "Country of the location." type: string sql: ${TABLE}.Country ;; }
  dimension: country_id { group_label: "Location Address" type: string sql: ${TABLE}.CountryId ;; hidden: yes }
  dimension: postal_code { group_label: "Location Address" description: "Postal/ZIP code of the location." type: string sql: ${TABLE}.PostalCode ;; }

  # ── Contact ──

  dimension: phone_no { group_label: "Location Contact" description: "Primary phone number for the location." type: string sql: ${TABLE}.PhoneNo ;; }
  dimension: email    { group_label: "Location Contact" description: "Primary email address for the location." type: string sql: ${TABLE}.Email ;; }

  # ── Pricing ──

  dimension: price_group_id { group_label: "Pricing" type: string sql: ${TABLE}.PriceGroupId ;; hidden: yes }
  dimension: price_group    { group_label: "Pricing" description: "Pricing group the location is assigned to (drives regional pricing variants)." type: string sql: ${TABLE}.PriceGroup ;; }

  # ── Time Zone ──

  dimension: time_zone_name { group_label: "Time Zone" description: "IANA time zone name for the location (e.g. America/New_York). Use when interpreting POS timestamps in local time." type: string sql: ${TABLE}.TimeZoneName ;; }
  dimension: utc_offset     { group_label: "Time Zone" label: "UTC Offset" description: "Hours offset from UTC for the location (negative for west of UTC)." type: number sql: ${TABLE}.UTCOffset ;; }

  # ── Custom Fields (42 fields) ──
  # Lookups
  dimension: custom_lookup_1  { group_label: "Location Custom Lookups" label: "Custom Lookup 1"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup1 ;; }
  dimension: custom_lookup_2  { group_label: "Location Custom Lookups" label: "Custom Lookup 2"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup2 ;; }
  dimension: custom_lookup_3  { group_label: "Location Custom Lookups" label: "Custom Lookup 3"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup3 ;; }
  dimension: custom_lookup_4  { group_label: "Location Custom Lookups" label: "Custom Lookup 4"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup4 ;; }
  dimension: custom_lookup_5  { group_label: "Location Custom Lookups" label: "Custom Lookup 5"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup5 ;; }
  dimension: custom_lookup_6  { group_label: "Location Custom Lookups" label: "Custom Lookup 6"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup6 ;; }
  dimension: custom_lookup_7  { group_label: "Location Custom Lookups" label: "Custom Lookup 7"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup7 ;; }
  dimension: custom_lookup_8  { group_label: "Location Custom Lookups" label: "Custom Lookup 8"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup8 ;; }
  dimension: custom_lookup_9  { group_label: "Location Custom Lookups" label: "Custom Lookup 9"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup9 ;; }
  dimension: custom_lookup_10 { group_label: "Location Custom Lookups" label: "Custom Lookup 10" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup10 ;; }
  dimension: custom_lookup_11 { group_label: "Location Custom Lookups" label: "Custom Lookup 11" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup11 ;; }
  dimension: custom_lookup_12 { group_label: "Location Custom Lookups" label: "Custom Lookup 12" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup12 ;; }

  # Flags
  dimension: custom_flag_1 { group_label: "Location Custom Flags" label: "Custom Flag 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag1 ;; }
  dimension: custom_flag_2 { group_label: "Location Custom Flags" label: "Custom Flag 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag2 ;; }
  dimension: custom_flag_3 { group_label: "Location Custom Flags" label: "Custom Flag 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag3 ;; }
  dimension: custom_flag_4 { group_label: "Location Custom Flags" label: "Custom Flag 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag4 ;; }
  dimension: custom_flag_5 { group_label: "Location Custom Flags" label: "Custom Flag 5" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag5 ;; }
  dimension: custom_flag_6 { group_label: "Location Custom Flags" label: "Custom Flag 6" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag6 ;; }

  # ── Measures ──

  measure: location_count {
    description: "Count of locations in the master."
    type: count
    drill_fields: [location_id, location_code, location_name, city, state]
  }
}
