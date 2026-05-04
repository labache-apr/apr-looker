# ══════════════════════════════════════════════════════════════
# ITEM MASTER - Flat master data table (130 columns, no STRUCTs)
# Used for standalone item exploration and joins from Inventory_view
# ══════════════════════════════════════════════════════════════

view: item_master {
  sql_table_name: `@{schema_name}.external_datamart_1.Item_view` ;;

  # ── Identifiers ──

  dimension: item_id {
    primary_key: yes
    group_label: "Item Identifiers"
    description: "Internal SKU identifier — unique per item. Primary key of this view."
    type: string
    sql: ${TABLE}.ItemId ;;
  }

  dimension: surrogate_item_id {
    group_label: "Item Identifiers"
    type: number
    sql: ${TABLE}.SurrogateItemId ;;
    hidden: yes
    description: "INT64 surrogate key - use for high-performance joins"
  }

  dimension: style {
    group_label: "Item Identifiers"
    description: "Style identifier grouping SKUs that share the same product (e.g. one style with multiple sizes/colors as separate items)."
    type: string
    sql: ${TABLE}.Style ;;
  }

  dimension: style_no {
    group_label: "Item Identifiers"
    label: "Style Number"
    description: "Vendor or merchandiser style number associated with the style."
    type: string
    sql: ${TABLE}.StyleNo ;;
  }

  dimension: plu {
    group_label: "Item Identifiers"
    label: "PLU"
    description: "Price Look-Up code used at the POS for items without a scannable barcode."
    type: number
    sql: ${TABLE}.PLU ;;
  }

  dimension: upc {
    group_label: "Item Identifiers"
    label: "UPC"
    description: "Universal Product Code (barcode) for the item."
    type: string
    sql: ${TABLE}.UPC ;;
  }

  dimension: clu {
    group_label: "Item Identifiers"
    label: "CLU"
    description: "Custom Look-Up code — alternate retailer-defined identifier."
    type: string
    sql: ${TABLE}.CLU ;;
  }

  dimension: eid {
    group_label: "Item Identifiers"
    label: "EID"
    description: "Electronic identifier (e.g. RFID tag id)."
    type: string
    sql: ${TABLE}.EID ;;
  }

  # ── DCSS Hierarchy ──

  dimension: dcss {
    group_label: "DCSS Hierarchy"
    label: "DCSS"
    description: "Concatenated merchandise hierarchy (Department / Class / Subclass1 / Subclass2). Use the individual levels for filtering and pivoting."
    type: string
    sql: ${TABLE}.DCSS ;;
  }

  dimension: department {
    group_label: "DCSS Hierarchy"
    description: "Top level of the merchandise hierarchy."
    type: string
    sql: ${TABLE}.Department ;;
  }

  dimension: class {
    group_label: "DCSS Hierarchy"
    description: "Second level of the merchandise hierarchy, beneath Department."
    type: string
    sql: ${TABLE}.Class ;;
  }

  dimension: subclass1 {
    group_label: "DCSS Hierarchy"
    label: "Subclass 1"
    description: "Third level of the merchandise hierarchy, beneath Class."
    type: string
    sql: ${TABLE}.Subclass1 ;;
  }

  dimension: subclass2 {
    group_label: "DCSS Hierarchy"
    label: "Subclass 2"
    description: "Fourth level of the merchandise hierarchy — most granular DCSS level."
    type: string
    sql: ${TABLE}.Subclass2 ;;
  }

  # ── Attributes ──

  dimension: brand {
    group_label: "Item Attributes"
    description: "Brand name associated with the item."
    type: string
    sql: ${TABLE}.Brand ;;
  }

  dimension: season {
    group_label: "Item Attributes"
    description: "Merchandising season the item is assigned to (e.g. Spring 2026, Holiday)."
    type: string
    sql: ${TABLE}.Season ;;
  }

  dimension: manufacturer {
    group_label: "Item Attributes"
    description: "Manufacturer of the item (may differ from Brand for private-label or licensed goods)."
    type: string
    sql: ${TABLE}.Manufacturer ;;
  }

  dimension: attribute1 { group_label: "Item Attributes" label: "Attribute 1" description: "First custom item attribute (size, color, or other dimension depending on Department conventions)." type: string sql: ${TABLE}.Attribute1 ;; }
  dimension: attribute2 { group_label: "Item Attributes" label: "Attribute 2" description: "Second custom item attribute. Meaning varies by Department." type: string sql: ${TABLE}.Attribute2 ;; }
  dimension: attribute3 { group_label: "Item Attributes" label: "Attribute 3" description: "Third custom item attribute. Meaning varies by Department." type: string sql: ${TABLE}.Attribute3 ;; }

  # ── Descriptions ──

  dimension: description1 { group_label: "Descriptions" label: "Description 1" description: "Primary item description used on receipts, signage, and reports." type: string sql: ${TABLE}.Description1 ;; }
  dimension: description2 { group_label: "Descriptions" label: "Description 2" description: "Secondary item description (long-form or alternate language)." type: string sql: ${TABLE}.Description2 ;; }
  dimension: description3 { group_label: "Descriptions" label: "Description 3" description: "Tertiary item description (purpose varies by retailer convention)." type: string sql: ${TABLE}.Description3 ;; }
  dimension: store_description { group_label: "Descriptions" description: "Description used in-store (signage and printed receipts)." type: string sql: ${TABLE}.StoreDescription ;; }

  # ── Pricing ──

  dimension: base_price  { group_label: "Pricing" description: "List/regular base price before promotions or markdowns. USD." type: number sql: ${TABLE}.BasePrice ;;  value_format_name: usd }
  dimension: retail_price { group_label: "Pricing" description: "Current retail price (after permanent markdowns, before promotions). USD." type: number sql: ${TABLE}.RetailPrice ;; value_format_name: usd }

  # ── Status ──

  dimension: is_non_inventory { group_label: "Status" description: "Yes when the item is not stock-tracked (services, fees, gift cards). Excluded from inventory metrics." type: yesno sql: ${TABLE}.IsNonInventory ;; }
  dimension: is_inactive      { group_label: "Status" description: "Yes when the item has been deactivated and should not be sold or reordered." type: yesno sql: ${TABLE}.IsInactive ;; }

  # ── Vendor ──

  dimension: primary_vendor            { group_label: "Vendor" description: "Primary vendor for the item — used by purchasing for replenishment." type: string sql: ${TABLE}.PrimaryVendor ;; }
  dimension: primary_vendor_order_cost { group_label: "Vendor" description: "Negotiated unit cost from the primary vendor. USD." type: number sql: ${TABLE}.PrimaryVendorOrderCost ;; value_format_name: usd }

  # ── Audit (record-level timestamps for ETL/diagnostics) ──

  dimension_group: dependencies_rec_modified {
    group_label: "Audit"
    label: "Dependencies Modified"
    description: "Latest modification timestamp across joined STRUCT dependencies"
    type: time
    timeframes: [raw, date, time]
    datatype: timestamp
    hidden: yes
    sql: ${TABLE}.DependenciesRecModified ;;
  }

  # ── Counts ──

  measure: item_count {
    description: "Count of item rows. Each row is a SKU — for unique styles use Style Count."
    type: count
    drill_fields: [item_id, style, description1, brand, department, class]
  }

  measure: active_item_count {
    description: "Count of items where Is Inactive = no. Use for current assortment sizing."
    type: count
    filters: [is_inactive: "no"]
  }

  measure: style_count {
    description: "Distinct count of styles — number of unique product styles regardless of how many SKUs each style has."
    type: count_distinct
    sql: ${TABLE}.Style ;;
  }
}