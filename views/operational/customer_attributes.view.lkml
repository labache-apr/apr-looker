# ══════════════════════════════════════════════════════════════
# CHQ CUSTOMER ATTRIBUTES - Customer behavioral & RFMP data
# One row per customer from bi_star.CHQCustomerAttributes
# ARRAY fields (CategoryPurchases, ConceptPurchases, SpentByLocation)
# are NOT unnested here — use dedicated views for those.
# ══════════════════════════════════════════════════════════════

view: customer_attributes {
  sql_table_name: `@{schema_name}.bi_star.CHQCustomerAttributes` ;;

  # ── Identifiers ──

  dimension: customer_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: LOWER(${TABLE}.CustomerId) ;;
  }

  dimension: eid {
    hidden: yes
    group_label: "Identifiers"
    label: "EID"
    type: string
    sql: ${TABLE}.EID ;;
  }

  # ── Membership ──

  dimension: membership_level_label {
    group_label: "Membership"
    description: "Customer's current membership tier (e.g. Gold, Platinum) from the CHQ attributes feed."
    type: string
    sql: ${TABLE}.MembershipLevelLabel ;;
  }

  dimension: customer_status_label {
    group_label: "Membership"
    description: "Friendly customer status (Active, Lapsed, Churned, etc.) from the CHQ attributes feed."
    type: string
    sql: ${TABLE}.CustomerStatusLabel ;;
  }

  # ── Behavioral ──

  dimension: type {
    group_label: "Behavioral"
    description: "Customer behavioral type tag from the CHQ attributes feed (e.g. New, Repeat, VIP)."
    type: string
    sql: ${TABLE}.Type ;;
  }

  dimension: omnichannel {
    group_label: "Behavioral"
    description: "Omnichannel behavior label — indicates whether the customer shops across both retail and e-commerce channels."
    type: string
    sql: ${TABLE}.Omnichannel ;;
  }

  dimension: returning {
    group_label: "Behavioral"
    description: "Returning customer flag/segment — see Returning Etail / Returning Retail for channel-specific scores."
    type: string
    sql: ${TABLE}.Returning ;;
  }

  dimension: returning_etail {
    group_label: "Behavioral"
    description: "Returning-customer score for the e-commerce channel."
    type: number
    sql: ${TABLE}.ReturningEtail ;;
  }

  dimension: returning_retail {
    group_label: "Behavioral"
    description: "Returning-customer score for the retail (in-store) channel."
    type: number
    sql: ${TABLE}.ReturningRetail ;;
  }

  # ── RFMP Scores ──

  dimension: rfmp_recency {
    group_label: "RFMP Scores"
    label: "RFMP Recency"
    description: "Recency component of the RFMP score — how recently the customer last purchased."
    type: string
    sql: ${TABLE}.RFMPRecency ;;
  }

  dimension: rfmp_frequency {
    group_label: "RFMP Scores"
    label: "RFMP Frequency"
    description: "Frequency component of the RFMP score — how often the customer transacts."
    type: string
    sql: ${TABLE}.RFMPFrequency ;;
  }

  dimension: rfmp_monetary {
    group_label: "RFMP Scores"
    label: "RFMP Monetary"
    description: "Monetary component of the RFMP score — total spend size."
    type: string
    sql: ${TABLE}.RFMPMonetary ;;
  }

  dimension: rfmp_product {
    group_label: "RFMP Scores"
    label: "RFMP Product"
    description: "Product diversity component of the RFMP score — breadth of categories purchased."
    type: string
    sql: ${TABLE}.RFMPProduct ;;
  }

  # ── Spend Summary ──

  dimension: total_spend_12m {
    group_label: "Spend Summary"
    label: "Total Spend 12m"
    description: "Customer's total net spend over the trailing 12 months. USD."
    type: number
    sql: ${TABLE}.TotalSpend12m ;;
    value_format_name: usd
  }

  dimension: total_spend_36m {
    group_label: "Spend Summary"
    label: "Total Spend 36m"
    description: "Customer's total net spend over the trailing 36 months. USD."
    type: number
    sql: ${TABLE}.TotalSpend36m ;;
    value_format_name: usd
  }

  # ── Transaction Summary ──

  dimension: number_sales_12m_receipts {
    group_label: "Transaction Summary"
    label: "Sales Receipts (12m)"
    description: "Number of sales receipts the customer generated in the trailing 12 months."
    type: number
    sql: ${TABLE}.NumberSales12mReceipts ;;
  }

  dimension: number_sales_receipts {
    group_label: "Transaction Summary"
    label: "Sales Receipts (Lifetime)"
    description: "Lifetime count of sales receipts attributed to the customer."
    type: number
    sql: ${TABLE}.NumberSalesReceipts ;;
  }

  # ── Rates ──

  dimension: articles_discount_percentage {
    group_label: "Rates"
    description: "Share of the customer's articles that were sold at a discount."
    type: number
    sql: ${TABLE}.ArticlesDiscountPercentage ;;
    value_format_name: percent_1
  }

  dimension: return_sum_rate_percentage {
    group_label: "Rates"
    label: "Return Sum Rate %"
    description: "Returned dollar value as a share of the customer's total purchases."
    type: number
    sql: ${TABLE}.ReturnSumRatePercentage ;;
    value_format_name: percent_1
  }

  dimension: return_cnt_rate_percentage {
    group_label: "Rates"
    label: "Return Count Rate %"
    description: "Number of returned items as a share of the customer's total purchased items."
    type: number
    sql: ${TABLE}.ReturnCntRatepercentage ;;
    value_format_name: percent_1
  }

  # ── Key Dates ──

  dimension_group: first_order {
    group_label: "Key Dates"
    description: "Date of the customer's first order (sales order, may include unfulfilled orders)."
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.FirstOrderDate ;;
  }

  dimension_group: last_order {
    group_label: "Key Dates"
    description: "Date of the customer's most recent order."
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.LastOrderDate ;;
  }

  dimension_group: first_receipt {
    group_label: "Key Dates"
    description: "Date of the customer's first sales receipt (POS-completed transaction)."
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.FirstReceiptDate ;;
  }

  dimension_group: last_receipt {
    group_label: "Key Dates"
    description: "Date of the customer's most recent sales receipt."
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.LastReceiptDate ;;
  }

  dimension_group: first_purchase {
    group_label: "Key Dates"
    description: "Date of the customer's first purchase across any channel."
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.FirstPurchaseDate ;;
  }

  dimension_group: last_purchase {
    group_label: "Key Dates"
    description: "Date of the customer's most recent purchase."
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.LastPurchaseDate ;;
  }

  dimension_group: rec_modified {
    group_label: "Audit"
    label: "Record Modified"
    description: "Timestamp the record was last modified in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.RecModified ;;
  }

  # ── Last Receipt Location (stores LocationId; ID/code/name resolved via join) ──

  dimension: last_receipt_location_id {
    group_label: "Last Receipt Location"
    label: "Location ID"
    description: "LocationId of the customer's most recent receipt. Join to last_receipt_location for the friendly name."
    type: string
    sql: ${TABLE}.LastReceiptLocation ;;
  }

  # ── Preferred Location (stores LocationName; ID/code/name resolved via join) ──

  dimension: preferred_location_name_raw {
    group_label: "Preferred Location"
    label: "Location Name (Raw)"
    hidden: yes
    type: string
    sql: ${TABLE}.PreferredStoreLocation ;;
  }

  # ══════════════════════════════════════════════════
  # MEASURES
  # ══════════════════════════════════════════════════

  measure: customer_count {
    description: "Distinct customers in the selected slice."
    type: count_distinct
    sql: ${customer_id} ;;
    drill_fields: [customer_id, membership_level_label, customer_status_label, total_spend_12m]
  }

  measure: avg_spend_12m {
    label: "Avg Spend 12m"
    description: "Average per-customer net spend in the trailing 12 months. USD."
    type: average
    sql: ${TABLE}.TotalSpend12m ;;
    value_format_name: usd
  }

  measure: avg_spend_36m {
    label: "Avg Spend 36m"
    description: "Average per-customer net spend in the trailing 36 months. USD."
    type: average
    sql: ${TABLE}.TotalSpend36m ;;
    value_format_name: usd
  }

  measure: avg_transactions_12m {
    label: "Avg Transactions 12m"
    description: "Average number of receipts per customer in the trailing 12 months."
    type: average
    sql: ${TABLE}.NumberSales12mReceipts ;;
    value_format_name: decimal_1
  }

  measure: avg_transactions_lifetime {
    label: "Avg Transactions Lifetime"
    description: "Average lifetime number of receipts per customer."
    type: average
    sql: ${TABLE}.NumberSalesReceipts ;;
    value_format_name: decimal_1
  }

  measure: avg_discount_rate {
    description: "Average share of articles sold at a discount across customers."
    type: average
    sql: ${TABLE}.ArticlesDiscountPercentage ;;
    value_format_name: percent_1
  }

  measure: avg_return_rate {
    description: "Average return-sum rate across customers."
    type: average
    sql: ${TABLE}.ReturnSumRatePercentage ;;
    value_format_name: percent_1
  }

  measure: sum_spend_12m {
    label: "Total Spend 12m (Sum)"
    description: "Total 12-month spend across customers in the selected slice. USD."
    type: sum
    sql: ${TABLE}.TotalSpend12m ;;
    value_format_name: usd
  }

  measure: sum_spend_36m {
    label: "Total Spend 36m (Sum)"
    description: "Total 36-month spend across customers in the selected slice. USD."
    type: sum
    sql: ${TABLE}.TotalSpend36m ;;
    value_format_name: usd
  }

  measure: omnichannel_customer_count {
    description: "Count of customers with a non-empty Omnichannel tag (active across both retail and e-commerce)."
    type: count_distinct
    sql: ${customer_id} ;;
    filters: [omnichannel: "-NULL,-EMPTY"]
  }
}