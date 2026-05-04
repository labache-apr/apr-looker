# ══════════════════════════════════════════════════════════════
# DIM CUSTOMER LOCATION - All customer-to-location associations
# Combines: home/preferred, created-at, and purchase locations
# One row per customer per location per association type
# ══════════════════════════════════════════════════════════════

view: dim_customer_location {
  derived_table: {
    sql:
      -- Home / Preferred Location
      SELECT
        LOWER(c.CustomerId)         AS customer_id,
        c.LocationCode              AS location_code,
        c.Location                  AS location_name,
        'Home'                      AS association_type
      FROM `@{schema_name}.external_datamart_1.Customer_view` c
      WHERE c.CustomerId IS NOT NULL
        AND c.CustomerId != ''
        AND c.LocationCode IS NOT NULL
        AND c.LocationCode != ''

      UNION DISTINCT

      -- Created-At Location
      SELECT
        LOWER(c.CustomerId)         AS customer_id,
        c.CreatedAtCode             AS location_code,
        c.CreatedAt                 AS location_name,
        'Created'                   AS association_type
      FROM `@{schema_name}.external_datamart_1.Customer_view` c
      WHERE c.CustomerId IS NOT NULL
        AND c.CustomerId != ''
        AND c.CreatedAtCode IS NOT NULL
        AND c.CreatedAtCode != ''

      UNION DISTINCT

      -- Purchase Locations (distinct locations where customer transacted)
      SELECT
        LOWER(sr.customer.CustomerId) AS customer_id,
        sr.location.LocationCode    AS location_code,
        sr.location.LocationName    AS location_name,
        'Purchased'                 AS association_type
      FROM `@{schema_name}.external_datamart_1.SalesReceipt_view` sr
      WHERE sr.customer.CustomerId IS NOT NULL
        AND sr.customer.CustomerId != ''
        AND sr.location.LocationCode IS NOT NULL
      GROUP BY 1, 2, 3, 4

      UNION DISTINCT

      -- Last Receipt Location (stores LocationId)
      SELECT
        LOWER(ca.CustomerId)          AS customer_id,
        loc.LocationCode              AS location_code,
        loc.LocationName              AS location_name,
        'Last Receipt'                AS association_type
      FROM `@{schema_name}.bi_star.CHQCustomerAttributes` ca
      LEFT JOIN `@{schema_name}.bi_star.dim_Location_view` loc
        ON ca.LastReceiptLocation = loc.LocationId
      WHERE ca.CustomerId IS NOT NULL
        AND ca.CustomerId != ''
        AND ca.LastReceiptLocation IS NOT NULL
        AND ca.LastReceiptLocation != ''

      UNION DISTINCT

      -- Preferred Location (stores LocationName)
      SELECT
        LOWER(ca.CustomerId)             AS customer_id,
        loc.LocationCode                 AS location_code,
        loc.LocationName                 AS location_name,
        'Preferred'                      AS association_type
      FROM `@{schema_name}.bi_star.CHQCustomerAttributes` ca
      LEFT JOIN `@{schema_name}.bi_star.dim_Location_view` loc
        ON ca.PreferredStoreLocation = loc.LocationName
      WHERE ca.CustomerId IS NOT NULL
        AND ca.CustomerId != ''
        AND ca.PreferredStoreLocation IS NOT NULL
        AND ca.PreferredStoreLocation != ''
    ;;
  }

  # ── Primary Key (composite) ──

  dimension: pk {
    primary_key: yes
    hidden: yes
    type: string
    sql: CONCAT(${customer_id}, '|', ${location_code}, '|', ${association_type}) ;;
  }

  # ── Dimensions ──

  dimension: customer_id {
    type: string
    hidden: yes
    sql: ${TABLE}.customer_id ;;
  }

  dimension: location_code {
    group_label: "Location"
    description: "Short code of a location associated with the customer."
    type: string
    sql: ${TABLE}.location_code ;;
  }

  dimension: location_name {
    group_label: "Location"
    description: "Friendly name of a location associated with the customer."
    type: string
    sql: ${TABLE}.location_name ;;
  }

  dimension: association_type {
    label: "Location Association Type"
    description: "How the customer is related to this location: Home (preferred), Created (record created at), or Purchased (transacted at)"
    type: string
    sql: ${TABLE}.association_type ;;
  }

  dimension: is_home_location {
    group_label: "Association Flags"
    description: "Yes when this row represents the customer's stated home location."
    type: yesno
    sql: ${association_type} = 'Home' ;;
  }

  dimension: is_created_location {
    group_label: "Association Flags"
    description: "Yes when this row represents the location where the customer record was originally created."
    type: yesno
    sql: ${association_type} = 'Created' ;;
  }

  dimension: is_purchase_location {
    group_label: "Association Flags"
    description: "Yes when this row represents a location where the customer has actually transacted."
    type: yesno
    sql: ${association_type} = 'Purchased' ;;
  }

  dimension: is_last_receipt_location {
    group_label: "Association Flags"
    description: "Yes when this row represents the location of the customer's most recent receipt."
    type: yesno
    sql: ${association_type} = 'Last Receipt' ;;
  }

  dimension: is_preferred_location {
    group_label: "Association Flags"
    description: "Yes when this row represents the customer's preferred store from CHQ Customer Attributes."
    type: yesno
    sql: ${association_type} = 'Preferred' ;;
  }

  # ── Measures ──

  measure: location_count {
    description: "Count of distinct locations associated with customers"
    type: count_distinct
    sql: ${location_code} ;;
  }

  measure: customer_count {
    description: "Count of distinct customers"
    type: count_distinct
    sql: ${customer_id} ;;
  }

  measure: association_count {
    description: "Total customer-location associations"
    type: count
    drill_fields: [customer_id, location_code, location_name, association_type]
  }
}