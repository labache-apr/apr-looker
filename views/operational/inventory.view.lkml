# ══════════════════════════════════════════════════════════════
# INVENTORY - Daily inventory snapshot (flat, 17 columns)
# Uses FK joins to Item_view and Location_view master tables
# ══════════════════════════════════════════════════════════════

view: inventory {
  sql_table_name: `@{schema_name}.external_datamart_1.Inventory_view` ;;

  # ── Keys ──

  dimension: item_id {
    type: string
    sql: ${TABLE}.ItemId ;;
    hidden: yes
  }

  dimension: surrogate_item_id {
    type: number
    sql: ${TABLE}.SurrogateItemId ;;
    hidden: yes
    description: "INT64 surrogate key - prefer for joins"
  }

  dimension: location_id {
    type: string
    sql: ${TABLE}.LocationId ;;
    hidden: yes
  }

  dimension: surrogate_location_id {
    type: number
    sql: ${TABLE}.SurrogateLocationId ;;
    hidden: yes
    description: "INT64 surrogate key - prefer for joins"
  }

  dimension: date_part {
    description: "Snapshot date — each row reflects inventory state as of this date. BigQuery partition column; filter on this for performance."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── Primary Key (composite) ──

  dimension: inventory_pk {
    primary_key: yes
    hidden: yes
    type: string
    sql: CONCAT(${TABLE}.ItemId, '|', ${TABLE}.LocationId, '|', CAST(${TABLE}.Date_Part AS STRING)) ;;
  }

  # ── Inventory Measures ──

  dimension: current_qty {
    hidden: yes
    type: number
    sql: ${TABLE}.current_qty ;;
  }

  dimension: current_cost {
    hidden: yes
    type: number
    sql: ${TABLE}.current_cost ;;
  }

  dimension: current_retail {
    hidden: yes
    type: number
    sql: ${TABLE}.current_retail ;;
  }

  dimension: sold_qty {
    hidden: yes
    type: number
    sql: ${TABLE}.sold_qty ;;
  }

  dimension: sold_cost {
    hidden: yes
    type: number
    sql: ${TABLE}.sold_cost ;;
  }

  dimension: sold_net_sales {
    hidden: yes
    type: number
    sql: ${TABLE}.net_sales_amt ;;
  }

  dimension: sold_margin {
    hidden: yes
    type: number
    sql: ${TABLE}.sold_margin ;;
  }

  # ── Aggregate Measures ──

  measure: total_on_hand_qty {
    description: "Total units on hand as of the snapshot date."
    type: sum
    sql: ${TABLE}.current_qty ;;
    value_format_name: decimal_0
  }

  measure: total_on_hand_cost {
    description: "Total cost value of on-hand inventory. USD."
    type: sum
    sql: ${TABLE}.current_cost ;;
    value_format_name: usd
  }

  measure: total_on_hand_retail {
    description: "Total retail (selling price) value of on-hand inventory. USD."
    type: sum
    sql: ${TABLE}.current_retail ;;
    value_format_name: usd
  }

  measure: total_sold_qty {
    description: "Total units sold on the snapshot date (units leaving stock)."
    type: sum
    sql: ${TABLE}.sold_qty ;;
    value_format_name: decimal_0
  }

  measure: total_sold_cost {
    description: "Total cost value of units sold on the snapshot date. USD."
    type: sum
    sql: ${TABLE}.sold_cost ;;
    value_format_name: usd
  }

  measure: total_sold_net_sales {
    label: "Total Sold Net Sales"
    description: "Net sales of units sold on the snapshot date — same definition as Sales Receipts → Total Net Sales but pre-aggregated to the inventory grain. USD."
    type: sum
    sql: ${TABLE}.net_sales_amt ;;
    value_format_name: usd
  }

  measure: total_sold_margin {
    description: "Margin (net sales − cost) on units sold on the snapshot date. USD."
    type: sum
    sql: ${TABLE}.sold_margin ;;
    value_format_name: usd
  }

  measure: avg_unit_cost {
    description: "Weighted average unit cost of on-hand inventory (Total On Hand Cost / Total On Hand Qty). USD."
    type: number
    sql: SAFE_DIVIDE(${total_on_hand_cost}, ${total_on_hand_qty}) ;;
    value_format_name: usd
  }

  measure: sku_location_count {
    label: "SKU-Location Count"
    description: "Count of (item × location × day) rows in the snapshot."
    type: count
  }

  measure: sku_count {
    label: "SKU Count"
    description: "Distinct SKUs (count of unique ItemId) in the snapshot."
    type: count_distinct
    sql: ${TABLE}.ItemId ;;
  }

  measure: location_count {
    description: "Distinct locations represented in the snapshot."
    type: count_distinct
    sql: ${TABLE}.LocationId ;;
  }

  # ══════════════════════════════════════════════════
  # MERCHANDISE KPIs
  # All measures below assume a Date_Part filter is applied.
  # The snapshot is daily; for multi-day periods we use
  # SUM(current_*) / DISTINCT snapshot days as the average.
  # ══════════════════════════════════════════════════

  measure: snapshot_day_count {
    label: "Snapshot Days"
    description: "Distinct snapshot dates in the result. Used as the denominator when averaging on-hand inventory across a period."
    type: count_distinct
    sql: ${TABLE}.Date_Part ;;
    hidden: yes
  }

  measure: avg_inventory_qty {
    label: "Avg Inventory Units"
    description: "Average on-hand units across the snapshot dates in the result (Total On Hand Qty / Snapshot Days). Use this — not Total On Hand Qty — when computing turn, GMROI, sell-through, or supply over a multi-day period."
    type: number
    sql: SAFE_DIVIDE(${total_on_hand_qty}, NULLIF(${snapshot_day_count}, 0)) ;;
    value_format_name: decimal_0
  }

  measure: avg_inventory_cost {
    label: "Avg Inventory Cost"
    description: "Average cost value of on-hand inventory across the snapshot dates (Total On Hand Cost / Snapshot Days). USD."
    type: number
    sql: SAFE_DIVIDE(${total_on_hand_cost}, NULLIF(${snapshot_day_count}, 0)) ;;
    value_format_name: usd
  }

  measure: avg_inventory_retail {
    label: "Avg Inventory Retail"
    description: "Average retail value of on-hand inventory across the snapshot dates (Total On Hand Retail / Snapshot Days). USD."
    type: number
    sql: SAFE_DIVIDE(${total_on_hand_retail}, NULLIF(${snapshot_day_count}, 0)) ;;
    value_format_name: usd
  }

  measure: inventory_turn_ratio {
    group_label: "Merchandise KPIs"
    label: "Inventory Turn"
    description: "Inventory turnover for the selected period: Total Sold Cost / Avg Inventory Cost. Period turn — multiply by (365 / period days) to annualize. Cost basis is FIFO."
    type: number
    sql: SAFE_DIVIDE(${total_sold_cost}, NULLIF(${avg_inventory_cost}, 0)) ;;
    value_format_name: decimal_2
  }

  measure: gmroi {
    group_label: "Merchandise KPIs"
    label: "GMROI"
    description: "Gross Margin Return on Inventory Investment: Total Sold Margin / Avg Inventory Cost. Higher is better — a value of 2.00 means $2 of margin earned per $1 of inventory carried over the period."
    type: number
    sql: SAFE_DIVIDE(${total_sold_margin}, NULLIF(${avg_inventory_cost}, 0)) ;;
    value_format_name: decimal_2
  }

  measure: weeks_of_supply {
    group_label: "Merchandise KPIs"
    label: "WOS (Weeks of Supply)"
    description: "Weeks of stock at the current sales rate: Avg Inventory Units / (Total Sold Qty / Snapshot Days × 7). Returns NULL when no sales in the period."
    type: number
    sql: SAFE_DIVIDE(${avg_inventory_qty}, NULLIF(SAFE_DIVIDE(${total_sold_qty}, NULLIF(${snapshot_day_count}, 0)) * 7, 0)) ;;
    value_format_name: decimal_1
  }

  measure: days_of_supply {
    group_label: "Merchandise KPIs"
    label: "DOS (Days of Supply)"
    description: "Days of stock at the current sales rate: Avg Inventory Units / (Total Sold Qty / Snapshot Days). Returns NULL when no sales in the period."
    type: number
    sql: SAFE_DIVIDE(${avg_inventory_qty}, NULLIF(SAFE_DIVIDE(${total_sold_qty}, NULLIF(${snapshot_day_count}, 0)), 0)) ;;
    value_format_name: decimal_1
  }

  measure: sell_through_rate {
    group_label: "Merchandise KPIs"
    label: "Sell-Through Rate"
    description: "Share of available units that sold during the period: Total Sold Qty / (Total Sold Qty + Avg Inventory Units). Period-based — pair with a Date_Part filter (e.g. last 4 weeks)."
    type: number
    sql: SAFE_DIVIDE(${total_sold_qty}, NULLIF(${total_sold_qty} + ${avg_inventory_qty}, 0)) ;;
    value_format_name: percent_1
  }

  # ── Out-of-Stock ──

  dimension: is_out_of_stock {
    hidden: yes
    type: yesno
    sql: ${TABLE}.current_qty <= 0 ;;
  }

  measure: out_of_stock_row_count {
    label: "Out-of-Stock Rows"
    description: "Count of (item × location × day) snapshot rows where current_qty ≤ 0."
    type: count
    filters: [is_out_of_stock: "yes"]
  }

  measure: out_of_stock_rate {
    group_label: "Merchandise KPIs"
    label: "Out-of-Stock Rate"
    description: "Share of (item × location × day) rows that were out of stock in the period (Out-of-Stock Rows / SKU-Location-Day Count). Treats each snapshot day equally — apply a Date_Part filter to scope the period."
    type: number
    sql: SAFE_DIVIDE(${out_of_stock_row_count}, NULLIF(${sku_location_count}, 0)) ;;
    value_format_name: percent_1
  }
}