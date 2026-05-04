# ══════════════════════════════════════════════════════════════
# CUSTOMER METRICS - Aggregated customer performance from sales
# One row per customer with lifetime spend, frequency, recency
# ══════════════════════════════════════════════════════════════

view: customer_metrics {
  derived_table: {
    sql:
      SELECT
        LOWER(sr.customer.CustomerId)                        AS customer_id,
        MIN(sr.Date_Part)                                   AS first_purchase_date,
        MAX(sr.Date_Part)                                   AS last_purchase_date,
        DATE_DIFF(CURRENT_DATE(), MAX(sr.Date_Part), DAY)   AS days_since_last_purchase,
        COUNT(DISTINCT sr.sale.UniversalNo)                 AS lifetime_transaction_count,
        SUM(sr.sale.NetSalesAmt)                            AS lifetime_net_sales,
        SUM(sr.sale.GrossSalesAmt)                          AS lifetime_gross_sales,
        SUM(sr.sale.COGS)                                   AS lifetime_cogs,
        SUM(sr.sale.MarginAmt)                              AS lifetime_margin,
        SUM(sr.sale.Qty)                                    AS lifetime_qty,
        SUM(sr.sale.DiscountAmt)                            AS lifetime_discount,
        SUM(CASE WHEN sr.sale.IsReturn THEN ABS(sr.sale.NetSalesAmt) ELSE 0 END) AS lifetime_return_amount,
        SUM(CASE WHEN sr.sale.IsReturn THEN ABS(sr.sale.Qty) ELSE 0 END)         AS lifetime_return_qty,
        COUNT(DISTINCT sr.location.LocationId)              AS distinct_locations_shopped,
        SAFE_DIVIDE(
          DATE_DIFF(MAX(sr.Date_Part), MIN(sr.Date_Part), DAY),
          NULLIF(COUNT(DISTINCT sr.sale.UniversalNo) - 1, 0)
        )                                                   AS avg_days_between_purchases
      FROM `@{schema_name}.external_datamart_1.SalesReceipt_view` sr
      WHERE sr.customer.CustomerId IS NOT NULL
        AND sr.customer.CustomerId != ''
      GROUP BY 1
    ;;
  }

  # ── Identifiers ──

  dimension: customer_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.customer_id ;;
  }

  # ── Dates ──

  dimension_group: first_purchase {
    description: "Date of the customer's first purchase across all locations."
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.first_purchase_date ;;
  }

  dimension_group: last_purchase {
    description: "Date of the customer's most recent purchase."
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.last_purchase_date ;;
  }

  dimension: days_since_last_purchase {
    description: "Number of days from the customer's last purchase to today. Higher values = more lapsed."
    type: number
    sql: ${TABLE}.days_since_last_purchase ;;
  }

  dimension: avg_days_between_purchases {
    description: "Average days between consecutive purchases for this customer (NULL if only one transaction)."
    type: number
    sql: ${TABLE}.avg_days_between_purchases ;;
    value_format_name: decimal_0
  }

  # ── Tiers ──

  dimension: lifetime_spend_tier {
    description: "Lifetime spend bucketed into tiers ($0-100, $100-500, $500-1k, $1k-5k, $5k+). Use for cohort views."
    type: tier
    tiers: [0, 100, 500, 1000, 5000]
    style: relational
    sql: ${TABLE}.lifetime_net_sales ;;
    value_format_name: usd_0
  }

  dimension: purchase_frequency_tier {
    description: "Lifetime transaction count bucketed (1, 2-5, 6-10, 11-25, 26+). Use to segment one-time vs. repeat customers."
    type: tier
    tiers: [1, 2, 6, 11, 26]
    style: relational
    sql: ${TABLE}.lifetime_transaction_count ;;
  }

  dimension: recency_tier {
    description: "Days-since-last-purchase bucketed (0-30, 31-90, 91-180, 181-365, 365+). Use for active/lapsed segmentation."
    type: tier
    tiers: [0, 31, 91, 181, 366]
    style: relational
    sql: ${TABLE}.days_since_last_purchase ;;
  }

  dimension: distinct_locations_shopped {
    description: "Number of distinct locations the customer has transacted at. 1 = single-store loyal, higher = roaming."
    type: number
    sql: ${TABLE}.distinct_locations_shopped ;;
  }

  # ══════════════════════════════════════════════════
  # MEASURES
  # ══════════════════════════════════════════════════

  measure: total_lifetime_spend {
    description: "Sum of lifetime net sales across customers in the selected slice. Net of discounts and returns. USD."
    type: sum
    sql: ${TABLE}.lifetime_net_sales ;;
    value_format_name: usd
  }

  measure: total_lifetime_gross_sales {
    description: "Sum of lifetime gross sales (pre-discount, pre-return) across customers. USD."
    type: sum
    sql: ${TABLE}.lifetime_gross_sales ;;
    value_format_name: usd
  }

  measure: total_lifetime_margin {
    description: "Sum of lifetime margin (net sales − COGS) across customers. USD."
    type: sum
    sql: ${TABLE}.lifetime_margin ;;
    value_format_name: usd
  }

  measure: avg_margin_percent {
    description: "Margin as a percentage of net spend across customers (Total Lifetime Margin / Total Lifetime Spend)."
    type: number
    sql: SAFE_DIVIDE(${total_lifetime_margin}, ${total_lifetime_spend}) ;;
    value_format_name: percent_1
  }

  measure: total_lifetime_cogs {
    label: "Total Lifetime COGS"
    description: "Sum of lifetime COGS across customers. Valued FIFO (cost of oldest on-hand units at time of sale). USD."
    type: sum
    sql: ${TABLE}.lifetime_cogs ;;
    value_format_name: usd
  }

  measure: total_transactions {
    description: "Sum of lifetime transaction counts across customers."
    type: sum
    sql: ${TABLE}.lifetime_transaction_count ;;
    value_format_name: decimal_0
  }

  measure: total_items_purchased {
    description: "Sum of lifetime units purchased across customers."
    type: sum
    sql: ${TABLE}.lifetime_qty ;;
    value_format_name: decimal_0
  }

  measure: avg_transaction_value {
    label: "Avg Transaction Value"
    description: "Average net sales per transaction (Total Lifetime Spend / Total Transactions). USD."
    type: number
    sql: SAFE_DIVIDE(${total_lifetime_spend}, ${total_transactions}) ;;
    value_format_name: usd
  }

  measure: avg_items_per_transaction {
    label: "Avg Items per Transaction"
    description: "Average units per transaction across customers (Total Items Purchased / Total Transactions)."
    type: number
    sql: SAFE_DIVIDE(${total_items_purchased}, ${total_transactions}) ;;
    value_format_name: decimal_1
  }

  measure: total_lifetime_discount {
    description: "Sum of lifetime discount applied across customers. USD."
    type: sum
    sql: ${TABLE}.lifetime_discount ;;
    value_format_name: usd
  }

  measure: total_return_amount {
    description: "Sum of lifetime return amounts (positive value) across customers. USD."
    type: sum
    sql: ${TABLE}.lifetime_return_amount ;;
    value_format_name: usd
  }

  measure: return_rate {
    description: "Returned units as a share of total units handled across customers (returned / (sold + returned))."
    type: number
    sql: SAFE_DIVIDE(
      SUM(${TABLE}.lifetime_return_qty),
      SUM(${TABLE}.lifetime_qty) + SUM(${TABLE}.lifetime_return_qty)
    ) ;;
    value_format_name: percent_1
  }

  measure: avg_customer_spend {
    description: "Average spend per customer"
    type: number
    sql: SAFE_DIVIDE(${total_lifetime_spend}, ${customer_count}) ;;
    value_format_name: usd
  }

  measure: avg_customer_transactions {
    description: "Average transactions per customer"
    type: number
    sql: SAFE_DIVIDE(${total_transactions}, ${customer_count}) ;;
    value_format_name: decimal_1
  }

  measure: customer_count {
    description: "Distinct customers (one row per customer in this view; count of rows in the selected slice)."
    type: count
    drill_fields: [customer_id]
  }

  measure: avg_days_since_last_purchase {
    description: "Average days since last purchase across customers. Higher = more lapsed customer base."
    type: average
    sql: ${TABLE}.days_since_last_purchase ;;
    value_format_name: decimal_0
  }

  measure: avg_distinct_locations {
    description: "Average number of locations each customer shops at"
    type: average
    sql: ${TABLE}.distinct_locations_shopped ;;
    value_format_name: decimal_1
  }
}