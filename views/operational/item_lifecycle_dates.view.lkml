# ══════════════════════════════════════════════════════════════
# ITEM LIFECYCLE DATES - First/last activity dates per item
# One row per item with first/last dates across:
#   - Sales (customer purchase)
#   - Purchase (vendor receipt)
#   - Purchase Order
#   - Transfer
# ══════════════════════════════════════════════════════════════

view: item_lifecycle_dates {
  derived_table: {
    sql:
      WITH sales AS (
        SELECT
          item.ItemId    AS item_id,
          MIN(Date_Part) AS first_date,
          MAX(Date_Part) AS last_date
        FROM `@{schema_name}.external_datamart_1.SalesReceipt_view`
        WHERE item.ItemId IS NOT NULL
        GROUP BY item.ItemId
      ),
      received AS (
        SELECT
          item.ItemId    AS item_id,
          MIN(Date_Part) AS first_date,
          MAX(Date_Part) AS last_date
        FROM `@{schema_name}.external_datamart_1.Purchase_view`
        WHERE item.ItemId IS NOT NULL
        GROUP BY item.ItemId
      ),
      ordered AS (
        SELECT
          item.ItemId    AS item_id,
          MIN(Date_Part) AS first_date,
          MAX(Date_Part) AS last_date
        FROM `@{schema_name}.external_datamart_1.PurchaseOrder_view`
        WHERE item.ItemId IS NOT NULL
        GROUP BY item.ItemId
      ),
      transferred AS (
        SELECT
          item.ItemId    AS item_id,
          MIN(Date_Part) AS first_date,
          MAX(Date_Part) AS last_date
        FROM `@{schema_name}.external_datamart_1.Transfer_view`
        WHERE item.ItemId IS NOT NULL
        GROUP BY item.ItemId
      ),
      all_items AS (
        SELECT item_id FROM sales        UNION DISTINCT
        SELECT item_id FROM received     UNION DISTINCT
        SELECT item_id FROM ordered      UNION DISTINCT
        SELECT item_id FROM transferred
      )
      SELECT
        a.item_id                AS item_id,
        s.first_date             AS first_purchase_date,
        s.last_date              AS last_purchase_date,
        r.first_date             AS first_received_date,
        r.last_date              AS last_received_date,
        o.first_date             AS first_order_date,
        o.last_date              AS last_order_date,
        t.first_date             AS first_transfer_date,
        t.last_date              AS last_transfer_date
      FROM all_items   a
      LEFT JOIN sales       s USING (item_id)
      LEFT JOIN received    r USING (item_id)
      LEFT JOIN ordered     o USING (item_id)
      LEFT JOIN transferred t USING (item_id)
    ;;
  }

  # ── Identifier ──

  dimension: item_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.item_id ;;
  }

  # ── Sales (Customer Purchase) ──

  dimension_group: first_purchase {
    group_label: "Item Lifecycle Dates"
    label: "First Purchase"
    description: "Earliest date this item was sold across all sales receipts"
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    datatype: date
    sql: ${TABLE}.first_purchase_date ;;
  }

  dimension_group: last_purchase {
    group_label: "Item Lifecycle Dates"
    label: "Last Purchase"
    description: "Most recent date this item was sold across all sales receipts"
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    datatype: date
    sql: ${TABLE}.last_purchase_date ;;
  }

  # ── Vendor Receipt ──

  dimension_group: first_received {
    group_label: "Item Lifecycle Dates"
    label: "First Received"
    description: "Earliest date this item was received from a vendor"
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    datatype: date
    sql: ${TABLE}.first_received_date ;;
  }

  dimension_group: last_received {
    group_label: "Item Lifecycle Dates"
    label: "Last Received"
    description: "Most recent date this item was received from a vendor"
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    datatype: date
    sql: ${TABLE}.last_received_date ;;
  }

  # ── Purchase Order ──

  dimension_group: first_order {
    group_label: "Item Lifecycle Dates"
    label: "First Order"
    description: "Earliest date this item appeared on a purchase order"
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    datatype: date
    sql: ${TABLE}.first_order_date ;;
  }

  dimension_group: last_order {
    group_label: "Item Lifecycle Dates"
    label: "Last Order"
    description: "Most recent date this item appeared on a purchase order"
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    datatype: date
    sql: ${TABLE}.last_order_date ;;
  }

  # ── Transfer ──

  dimension_group: first_transfer {
    group_label: "Item Lifecycle Dates"
    label: "First Transfer"
    description: "Earliest date this item was transferred between locations"
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    datatype: date
    sql: ${TABLE}.first_transfer_date ;;
  }

  dimension_group: last_transfer {
    group_label: "Item Lifecycle Dates"
    label: "Last Transfer"
    description: "Most recent date this item was transferred between locations"
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    datatype: date
    sql: ${TABLE}.last_transfer_date ;;
  }
}