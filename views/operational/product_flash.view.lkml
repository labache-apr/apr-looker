include: "/views/master/dim_location_franchise.view.lkml"

# ══════════════════════════════════════════════════════════════
# PRODUCT FLASH - Single-product deep dive across locations
# Combines real-time inventory (LocationAvailability) with
# time-bucketed sales aggregates (SalesReceiptJournal) via
# a derived table keyed on Style + LocationId.
# ══════════════════════════════════════════════════════════════

view: product_flash {
  derived_table: {
    # persist_with: inventory_refresh
    sql:
      WITH ref_date AS (
        SELECT COALESCE(DATE({% date_start as_of_date %}), CURRENT_DATE()) AS d
      ),

      availability AS (
        SELECT
          la.item.StyleNo                       AS style,
          la.location.LocationId                AS location_id,
          la.location.LocationCode              AS location_code,
          la.location.LocationName              AS location_name,
          -- Item attributes (take first non-null per style-location)
          MAX(la.item.StoreDescription)          AS description1,
          MAX(la.item.Department)               AS department,
          MAX(la.item.Class)                    AS item_class,
          MAX(la.item.Brand)                    AS brand,
          MAX(la.item.PrimaryVendor)            AS primary_vendor,
          MAX(la.item.PrimaryVendorOrderCost)   AS vendor_cost,
          MAX(la.item.RetailPrice)              AS retail_price,
          MAX(la.item.BasePrice)                AS base_price,
          MAX(CASE WHEN la.item.IsInactive THEN 1 ELSE 0 END) AS is_inactive_flag,
          -- Inventory quantities (sum across SKUs within a style at a location)
          SUM(la.OnHand)                        AS on_hand,
          SUM(la.ATS)                           AS available,
          SUM(la.Committed)                     AS committed,
          SUM(la.Reserved)                      AS reserved,
          SUM(la.Held)                          AS held,
          SUM(la.Damaged)                       AS damaged,
          SUM(la.Incoming)                      AS incoming,
          -- Reorder points - TODO: join to model stock table
          -- (varies by location/modelstockgroup/modelstockperiod/item)
          CAST(NULL AS INT64)                   AS reorder_min,
          CAST(NULL AS INT64)                   AS reorder_max
        FROM `aefc-prod-us-twc-b1bc.external_datamart_1.LocationAvailability_view` la
        WHERE 1=1
          AND {% condition plu %} la.item.PLU {% endcondition %}
        GROUP BY 1, 2, 3, 4
      ),

      sales AS (
        SELECT
          sr.StyleNo                             AS style,
          sr.LocationId                          AS location_id,
          -- Each row = 1 unit; returns count as -1
          -- Time-bucketed sales units (relative to as_of_date)
          SUM(CASE WHEN DATE(sr.ReceiptDateTime) >= DATE_SUB(rd.d, INTERVAL 28 DAY)
                   THEN CASE WHEN sr.ReceiptJournalLineTypeLabel = 'Item (Return)' THEN -1 ELSE 1 END ELSE 0 END) AS l4w_sales_units,
          SUM(CASE WHEN DATE(sr.ReceiptDateTime) >= DATE_SUB(rd.d, INTERVAL 7 DAY)
                   THEN CASE WHEN sr.ReceiptJournalLineTypeLabel = 'Item (Return)' THEN -1 ELSE 1 END ELSE 0 END) AS lw_sales_units,
          SUM(CASE WHEN DATE(sr.ReceiptDateTime) >= DATE_TRUNC(rd.d, YEAR)
                   THEN CASE WHEN sr.ReceiptJournalLineTypeLabel = 'Item (Return)' THEN -1 ELSE 1 END ELSE 0 END) AS ytd_sales_units,
          SUM(CASE WHEN DATE(sr.ReceiptDateTime) >= DATE_TRUNC(DATE_SUB(rd.d, INTERVAL 1 YEAR), YEAR)
                    AND DATE(sr.ReceiptDateTime) < DATE_SUB(rd.d, INTERVAL 1 YEAR)
                   THEN CASE WHEN sr.ReceiptJournalLineTypeLabel = 'Item (Return)' THEN -1 ELSE 1 END ELSE 0 END) AS ly_sales_units,
          -- Time-bucketed sales dollars (relative to as_of_date)
          SUM(CASE WHEN DATE(sr.ReceiptDateTime) >= DATE_SUB(rd.d, INTERVAL 28 DAY)
                   THEN sr.LineAmount ELSE 0 END)  AS l4w_sales_dollars,
          SUM(CASE WHEN DATE(sr.ReceiptDateTime) >= DATE_SUB(rd.d, INTERVAL 7 DAY)
                   THEN sr.LineAmount ELSE 0 END)  AS lw_sales_dollars,
          SUM(CASE WHEN DATE(sr.ReceiptDateTime) >= DATE_TRUNC(rd.d, YEAR)
                   THEN sr.LineAmount ELSE 0 END)  AS ytd_sales_dollars,
          SUM(CASE WHEN DATE(sr.ReceiptDateTime) >= DATE_TRUNC(DATE_SUB(rd.d, INTERVAL 1 YEAR), YEAR)
                    AND DATE(sr.ReceiptDateTime) < DATE_SUB(rd.d, INTERVAL 1 YEAR)
                   THEN sr.LineAmount ELSE 0 END)  AS ly_sales_dollars,
          -- Date milestones
          MIN(DATE(sr.ReceiptDateTime))          AS first_sale_date,
          MAX(DATE(sr.ReceiptDateTime))          AS last_sale_date
        FROM `aefc-prod-us-twc-b1bc.external_datamart_1.SalesReceiptJournal_view` sr
        CROSS JOIN ref_date rd
        WHERE DATE(sr.ReceiptDateTime) <= rd.d
          AND DATE(sr.ReceiptDateTime) >= DATE_TRUNC(DATE_SUB(rd.d, INTERVAL 1 YEAR), YEAR)
          AND sr.ReceiptJournalLineTypeLabel IN ('Item (Sale)', 'Item (Return)')
          AND {% condition plu %} sr.PLU {% endcondition %}
        GROUP BY 1, 2
      )

      SELECT
        a.style,
        a.location_id,
        a.location_code,
        a.location_name,
        a.description1,
        a.department,
        a.item_class,
        a.brand,
        a.primary_vendor,
        a.vendor_cost,
        a.retail_price,
        a.base_price,
        a.is_inactive_flag,
        a.on_hand,
        a.available,
        a.committed,
        a.reserved,
        a.held,
        a.damaged,
        a.incoming,
        a.reorder_min,
        a.reorder_max,
        COALESCE(s.l4w_sales_units, 0)     AS l4w_sales_units,
        COALESCE(s.lw_sales_units, 0)      AS lw_sales_units,
        COALESCE(s.ytd_sales_units, 0)     AS ytd_sales_units,
        COALESCE(s.ly_sales_units, 0)      AS ly_sales_units,
        COALESCE(s.l4w_sales_dollars, 0)   AS l4w_sales_dollars,
        COALESCE(s.lw_sales_dollars, 0)    AS lw_sales_dollars,
        COALESCE(s.ytd_sales_dollars, 0)   AS ytd_sales_dollars,
        COALESCE(s.ly_sales_dollars, 0)    AS ly_sales_dollars,
        s.first_sale_date,
        s.last_sale_date
      FROM availability a
      LEFT JOIN sales s
        ON a.style = s.style
        AND a.location_id = s.location_id
    ;;
  }

  # ══════════════════════════════════════════════════
  # FILTERS
  # ══════════════════════════════════════════════════

  filter: as_of_date {
    label: "As Of Date"
    description: "Reference date for all sales buckets (L4W, LW, YTD, LY). Defaults to today."
    type: date
  }

  filter: plu {
    label: "PLU"
    description: "Price Look-Up code identifying the product to deep-dive on. Filters both inventory and sales sources to the matching style."
    type: number
  }

  # ══════════════════════════════════════════════════
  # PRIMARY KEY
  # ══════════════════════════════════════════════════

  dimension: pk {
    primary_key: yes
    hidden: yes
    type: string
    sql: CONCAT(${TABLE}.style, '|', ${TABLE}.location_id) ;;
  }

  # ══════════════════════════════════════════════════
  # PRODUCT ATTRIBUTES
  # ══════════════════════════════════════════════════

  dimension: style {
    group_label: "Product"
    label: "Style Number"
    description: "Style being analyzed. Use the As Of Date filter to control the reference period for sales buckets."
    type: string
    sql: ${TABLE}.style ;;
  }

  dimension: description1 {
    group_label: "Product"
    label: "Product Name"
    description: "Store description of the style (taken as MAX across SKUs in the style/location)."
    type: string
    sql: ${TABLE}.description1 ;;
  }

  dimension: department {
    group_label: "Product"
    description: "Top-level merchandise department for the style."
    type: string
    sql: ${TABLE}.department ;;
  }

  dimension: item_class {
    group_label: "Product"
    label: "Class"
    description: "Merchandise class (second level beneath Department)."
    type: string
    sql: ${TABLE}.item_class ;;
  }

  dimension: brand {
    group_label: "Product"
    description: "Brand associated with the style."
    type: string
    sql: ${TABLE}.brand ;;
  }

  dimension: primary_vendor {
    group_label: "Product"
    label: "Vendor"
    description: "Primary vendor for the style — used by purchasing for replenishment."
    type: string
    sql: ${TABLE}.primary_vendor ;;
  }

  dimension: vendor_cost {
    group_label: "Pricing"
    description: "Negotiated unit cost from the primary vendor. USD."
    type: number
    sql: ${TABLE}.vendor_cost ;;
    value_format_name: usd
  }

  dimension: retail_price {
    group_label: "Pricing"
    label: "Current Price"
    description: "Current retail price (after permanent markdowns, before promotions). USD."
    type: number
    sql: ${TABLE}.retail_price ;;
    value_format_name: usd
  }

  dimension: base_price {
    group_label: "Pricing"
    hidden: yes
    type: number
    sql: ${TABLE}.base_price ;;
    value_format_name: usd
  }

  dimension: est_margin_pct {
    group_label: "Pricing"
    label: "Est. Margin %"
    description: "Estimated margin: (Retail Price − Vendor Cost) / Retail Price. Approximation — not actual realized margin."
    type: number
    sql: SAFE_DIVIDE(${retail_price} - ${vendor_cost}, ${retail_price}) ;;
    value_format_name: percent_1
  }

  dimension: is_inactive {
    group_label: "Product"
    description: "Yes when the style is flagged inactive. Inactive styles should generally not be reordered."
    type: yesno
    sql: ${TABLE}.is_inactive_flag = 1 ;;
  }

  dimension: status_label {
    group_label: "Product"
    label: "Status"
    description: "Friendly status — 'Active' or 'Inactive' based on Is Inactive flag."
    type: string
    sql: CASE WHEN ${TABLE}.is_inactive_flag = 1 THEN 'Inactive' ELSE 'Active' END ;;
  }

  # ══════════════════════════════════════════════════
  # LOCATION
  # ══════════════════════════════════════════════════

  dimension: location_id {
    group_label: "Location"
    hidden: yes
    type: string
    sql: ${TABLE}.location_id ;;
  }

  dimension: location_code {
    group_label: "Location"
    hidden: yes
    type: string
    sql: ${TABLE}.location_code ;;
  }

  dimension: location_name {
    group_label: "Location"
    description: "Friendly name of the location holding stock."
    type: string
    sql: ${TABLE}.location_name ;;
  }

  dimension: location_label {
    group_label: "Location"
    label: "Location"
    description: "Location code + name"
    type: string
    sql: CONCAT(${location_code}, ' – ', ${location_name}) ;;
  }

  # ══════════════════════════════════════════════════
  # INVENTORY QUANTITIES (per location)
  # ══════════════════════════════════════════════════

  dimension: on_hand {
    group_label: "Inventory"
    label: "On Hand"
    description: "Total physical units in stock at this location for the style."
    type: number
    sql: ${TABLE}.on_hand ;;
  }

  dimension: available {
    group_label: "Inventory"
    label: "Available"
    description: "Available to Sell at this location for the style (OnHand − Committed − Reserved − Held − Damaged)."
    type: number
    sql: ${TABLE}.available ;;
  }

  dimension: committed {
    group_label: "Inventory"
    description: "Units committed to open sales orders at this location for the style."
    type: number
    sql: ${TABLE}.committed ;;
  }

  dimension: incoming {
    group_label: "Inventory"
    description: "Units in transit to this location for the style (open transfers/POs not yet received)."
    type: number
    sql: ${TABLE}.incoming ;;
  }

  dimension: reserved {
    group_label: "Inventory"
    hidden: yes
    type: number
    sql: ${TABLE}.reserved ;;
  }

  dimension: held {
    group_label: "Inventory"
    hidden: yes
    type: number
    sql: ${TABLE}.held ;;
  }

  dimension: damaged {
    group_label: "Inventory"
    hidden: yes
    type: number
    sql: ${TABLE}.damaged ;;
  }

  # ══════════════════════════════════════════════════
  # REORDER POINTS
  # ══════════════════════════════════════════════════

  dimension: reorder_min {
    group_label: "Reorder Points"
    label: "Min"
    description: "Minimum target stock level at this location. Below this, the location should reorder. NOTE: currently NULL — model stock table not yet joined."
    type: number
    sql: ${TABLE}.reorder_min ;;
  }

  dimension: reorder_max {
    group_label: "Reorder Points"
    label: "Max"
    description: "Maximum target stock level at this location. NOTE: currently NULL — model stock table not yet joined."
    type: number
    sql: ${TABLE}.reorder_max ;;
  }

  dimension: stock_status {
    group_label: "Inventory"
    label: "Stock Status"
    description: "OK = above reorder min, Low = below reorder min, Out = zero available"
    type: string
    sql:
      CASE
        WHEN ${available} <= 0 THEN 'Out'
        WHEN ${reorder_min} IS NOT NULL AND ${available} < ${reorder_min} THEN 'Low'
        ELSE 'OK'
      END ;;
    html:
      {% if value == 'Out' %}
        <span style="background:#fee2e2; color:#dc2626; padding:2px 8px; border-radius:4px; font-weight:600;">{{ value }}</span>
      {% elsif value == 'Low' %}
        <span style="background:#fef3c7; color:#d97706; padding:2px 8px; border-radius:4px; font-weight:600;">{{ value }}</span>
      {% else %}
        <span style="background:#d1fae5; color:#059669; padding:2px 8px; border-radius:4px; font-weight:600;">{{ value }}</span>
      {% endif %} ;;
  }

  dimension: needs_reorder {
    group_label: "Reorder Points"
    description: "Yes when available stock is below reorder min. Filter to find locations needing replenishment."
    type: yesno
    sql: ${available} < ${reorder_min} AND ${reorder_min} IS NOT NULL ;;
  }

  # ══════════════════════════════════════════════════
  # SALES QUANTITIES (per location)
  # ══════════════════════════════════════════════════

  dimension: l4w_sales_units {
    group_label: "Sales Units"
    label: "L4W Units"
    description: "Net units sold in the last 4 weeks (28 days) ending at As Of Date. Returns subtract."
    type: number
    sql: ${TABLE}.l4w_sales_units ;;
  }

  dimension: lw_sales_units {
    group_label: "Sales Units"
    label: "LW Units"
    description: "Net units sold in the last 7 days ending at As Of Date. Returns subtract."
    type: number
    sql: ${TABLE}.lw_sales_units ;;
  }

  dimension: ytd_sales_units {
    group_label: "Sales Units"
    label: "YTD Units"
    description: "Net units sold from Jan 1 of the As Of Date's year through As Of Date. Returns subtract."
    type: number
    sql: ${TABLE}.ytd_sales_units ;;
  }

  dimension: ly_sales_units {
    group_label: "Sales Units"
    label: "LY Units"
    description: "Net units sold during the same YTD period in the prior year. Use with YTD Units for YoY comparison."
    type: number
    sql: ${TABLE}.ly_sales_units ;;
  }

  dimension: l4w_sales_dollars {
    group_label: "Sales Amounts"
    label: "L4W Sales $"
    description: "Net sales dollars in the last 4 weeks (28 days) ending at As Of Date. USD."
    type: number
    sql: ${TABLE}.l4w_sales_dollars ;;
    value_format_name: usd
  }

  dimension: lw_sales_dollars {
    group_label: "Sales Amounts"
    label: "LW Sales $"
    description: "Net sales dollars in the last 7 days ending at As Of Date. USD."
    type: number
    sql: ${TABLE}.lw_sales_dollars ;;
    value_format_name: usd
  }

  dimension: ytd_sales_dollars {
    group_label: "Sales Amounts"
    label: "YTD Sales $"
    description: "Net sales dollars from Jan 1 of the As Of Date's year through As Of Date. USD."
    type: number
    sql: ${TABLE}.ytd_sales_dollars ;;
    value_format_name: usd
  }

  dimension: ly_sales_dollars {
    group_label: "Sales Amounts"
    label: "LY Sales $"
    description: "Net sales dollars during the same YTD period in the prior year. Use with YTD Sales $ for YoY comparison. USD."
    type: number
    sql: ${TABLE}.ly_sales_dollars ;;
    value_format_name: usd
  }

  # ══════════════════════════════════════════════════
  # DATE MILESTONES
  # ══════════════════════════════════════════════════

  dimension: first_sale_date {
    group_label: "Dates"
    label: "First Sale"
    description: "Earliest sale of the style at this location within the lookback window."
    type: date
    sql: ${TABLE}.first_sale_date ;;
  }

  dimension: last_sale_date {
    group_label: "Dates"
    label: "Last Sale"
    description: "Most recent sale of the style at this location within the lookback window."
    type: date
    sql: ${TABLE}.last_sale_date ;;
  }

  # ══════════════════════════════════════════════════
  # MEASURES - Inventory Totals
  # ══════════════════════════════════════════════════

  measure: total_on_hand {
    group_label: "Inventory Totals"
    description: "Total on-hand units across selected locations for the style."
    type: sum
    sql: ${on_hand} ;;
    value_format_name: decimal_0
  }

  measure: total_available {
    group_label: "Inventory Totals"
    label: "Total Available"
    description: "Total available-to-sell units across selected locations for the style."
    type: sum
    sql: ${available} ;;
    value_format_name: decimal_0
  }

  measure: total_committed {
    group_label: "Inventory Totals"
    description: "Total committed units across selected locations for the style."
    type: sum
    sql: ${committed} ;;
    value_format_name: decimal_0
  }

  measure: total_incoming {
    group_label: "Inventory Totals"
    description: "Total incoming units across selected locations for the style."
    type: sum
    sql: ${incoming} ;;
    value_format_name: decimal_0
  }

  measure: location_count {
    description: "Count of locations stocking the style."
    type: count
  }

  # ══════════════════════════════════════════════════
  # MEASURES - Sales Totals
  # ══════════════════════════════════════════════════

  measure: total_l4w_sales_units {
    group_label: "Sales Totals"
    label: "L4W Sales Units"
    description: "Total net units sold in the last 4 weeks across selected locations."
    type: sum
    sql: ${l4w_sales_units} ;;
    value_format_name: decimal_0
  }

  measure: total_lw_sales_units {
    group_label: "Sales Totals"
    label: "LW Sales Units"
    description: "Total net units sold in the last week across selected locations."
    type: sum
    sql: ${lw_sales_units} ;;
    value_format_name: decimal_0
  }

  measure: total_ytd_sales_units {
    group_label: "Sales Totals"
    label: "YTD Sales Units"
    description: "Total net units sold YTD across selected locations."
    type: sum
    sql: ${ytd_sales_units} ;;
    value_format_name: decimal_0
  }

  measure: total_ly_sales_units {
    group_label: "Sales Totals"
    label: "LY Sales Units"
    description: "Total net units sold during prior-year YTD across selected locations."
    type: sum
    sql: ${ly_sales_units} ;;
    value_format_name: decimal_0
  }

  measure: total_l4w_sales_dollars {
    group_label: "Sales Totals"
    label: "L4W Sales $"
    description: "Total net sales dollars in the last 4 weeks across selected locations. USD."
    type: sum
    sql: ${l4w_sales_dollars} ;;
    value_format_name: usd
  }

  measure: total_lw_sales_dollars {
    group_label: "Sales Totals"
    label: "LW Sales $"
    description: "Total net sales dollars in the last week across selected locations. USD."
    type: sum
    sql: ${lw_sales_dollars} ;;
    value_format_name: usd
  }

  measure: total_ytd_sales_dollars {
    group_label: "Sales Totals"
    label: "YTD Sales $"
    description: "Total net sales dollars YTD across selected locations. USD."
    type: sum
    sql: ${ytd_sales_dollars} ;;
    value_format_name: usd
  }

  measure: total_ly_sales_dollars {
    group_label: "Sales Totals"
    label: "LY Sales $"
    description: "Total net sales dollars during prior-year YTD across selected locations. USD."
    type: sum
    sql: ${ly_sales_dollars} ;;
    value_format_name: usd
  }

  # ══════════════════════════════════════════════════
  # MEASURES - KPI Calculations
  # ══════════════════════════════════════════════════

  measure: weeks_of_supply {
    group_label: "KPIs"
    description: "On Hand / weekly sales rate (L4W / 4)"
    type: number
    sql: SAFE_DIVIDE(${total_on_hand}, SAFE_DIVIDE(${total_l4w_sales_units}, 4)) ;;
    value_format_name: decimal_1
  }

  measure: sell_through_ytd {
    group_label: "KPIs"
    label: "Sell-Through YTD"
    description: "YTD Units Sold / (YTD Units Sold + Current On Hand)"
    type: number
    sql: SAFE_DIVIDE(${total_ytd_sales_units}, ${total_ytd_sales_units} + ${total_on_hand}) ;;
    value_format_name: percent_1
  }

  measure: ytd_vs_ly_pct {
    group_label: "KPIs"
    label: "YTD vs LY %"
    description: "(YTD Sales $ - LY Sales $) / LY Sales $"
    type: number
    sql: SAFE_DIVIDE(${total_ytd_sales_dollars} - ${total_ly_sales_dollars}, ${total_ly_sales_dollars}) ;;
    value_format_name: percent_1
  }

  measure: stockout_location_count {
    group_label: "KPIs"
    label: "Stock-Out Locations"
    description: "Locations with zero available"
    type: count
    filters: [available: "0"]
  }

  measure: below_reorder_min_count {
    group_label: "KPIs"
    label: "Below Reorder Min"
    description: "Locations below reorder minimum"
    type: sum
    sql: CASE WHEN ${available} > 0 AND ${reorder_min} IS NOT NULL AND ${available} < ${reorder_min} THEN 1 ELSE 0 END ;;
  }
}
