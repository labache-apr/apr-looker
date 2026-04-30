view: location_struct {
  extension: required  # Cannot be used standalone - must be extended

  # ══════════════════════════════════════════════════
  # IDENTIFIERS
  # ══════════════════════════════════════════════════

  dimension: location_id {
    group_label: "Location Identifiers"
    description: "Internal identifier for the location of the transaction. Snapshot from time of transaction."
    type: string
    sql: ${TABLE}.location.LocationId ;;
  }

  dimension: location_code {
    group_label: "Location Identifiers"
    description: "Short code (e.g. store number) for the transaction location."
    type: string
    sql: ${TABLE}.location.LocationCode ;;
  }

  dimension: location_name {
    group_label: "Location Identifiers"
    description: "Friendly name of the transaction location."
    type: string
    sql: ${TABLE}.location.LocationName ;;
  }

  dimension: location_label {
    group_label: "Location Identifiers"
    description: "Display label for the location, typically combining code and name."
    type: string
    sql: ${TABLE}.location.Label ;;
  }

  dimension: location_sort_order {
    group_label: "Location Identifiers"
    type: number
    sql: ${TABLE}.location.SortOrder ;;
    hidden: yes
  }

  # ══════════════════════════════════════════════════
  # ADDRESS
  # ══════════════════════════════════════════════════

  dimension: address {
    group_label: "Location Address"
    description: "Street address of the location."
    type: string
    sql: ${TABLE}.location.Adress ;;  # Note: 'Adress' is the actual BQ column name (typo in source)
  }

  dimension: city {
    group_label: "Location Address"
    description: "City of the location."
    type: string
    sql: ${TABLE}.location.City ;;
  }

  dimension: state {
    group_label: "Location Address"
    description: "State or province of the location."
    type: string
    sql: ${TABLE}.location.State ;;
  }

  dimension: country_id {
    group_label: "Location Address"
    type: string
    sql: ${TABLE}.location.CountryId ;;
    hidden: yes
  }

  dimension: country {
    group_label: "Location Address"
    description: "Country of the location."
    type: string
    sql: ${TABLE}.location.Country ;;
  }

  dimension: postal_code {
    group_label: "Location Address"
    description: "Postal/ZIP code of the location."
    type: string
    sql: ${TABLE}.location.PostalCode ;;
  }

  # ══════════════════════════════════════════════════
  # CONTACT
  # ══════════════════════════════════════════════════

  dimension: phone_no {
    group_label: "Location Contact"
    description: "Primary phone number for the location."
    type: string
    sql: ${TABLE}.location.PhoneNo ;;
  }

  dimension: email {
    group_label: "Location Contact"
    description: "Primary email address for the location."
    type: string
    sql: ${TABLE}.location.Email ;;
  }

  # ══════════════════════════════════════════════════
  # PRICING
  # ══════════════════════════════════════════════════

  dimension: price_group_id {
    group_label: "Location Pricing"
    type: string
    sql: ${TABLE}.location.PriceGroupId ;;
    hidden: yes
  }

  dimension: price_group {
    group_label: "Location Pricing"
    description: "Pricing group the location was assigned to at time of transaction."
    type: string
    sql: ${TABLE}.location.PriceGroup ;;
  }

  # ══════════════════════════════════════════════════
  # TIME ZONE
  # ══════════════════════════════════════════════════

  dimension: time_zone_name {
    group_label: "Location Time Zone"
    description: "IANA time zone name for the location (e.g. America/New_York). Use when interpreting POS timestamps in local time."
    type: string
    sql: ${TABLE}.location.TimeZoneName ;;
  }

  dimension: utc_offset {
    group_label: "Location Time Zone"
    label: "UTC Offset"
    description: "Hours offset from UTC for the location (negative for west of UTC)."
    type: number
    sql: ${TABLE}.location.UTCOffset ;;
  }
}
