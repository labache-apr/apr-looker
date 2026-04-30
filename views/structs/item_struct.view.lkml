view: item_struct {
  extension: required  # Cannot be used standalone - must be extended

  # ══════════════════════════════════════════════════
  # IDENTIFIERS
  # ══════════════════════════════════════════════════

  dimension: item_id {
    group_label: "Item Identifiers"
    description: "Internal SKU identifier captured on the transaction line. Snapshot from time of transaction — for current item state, join to Item Master."
    type: string
    sql: ${TABLE}.item.ItemId ;;
  }

  dimension: style {
    group_label: "Item Identifiers"
    description: "Style identifier grouping SKUs that share the same product. Snapshot from time of transaction."
    type: string
    sql: ${TABLE}.item.Style ;;
  }

  dimension: style_no {
    group_label: "Item Identifiers"
    label: "Style Number"
    description: "Vendor or merchandiser style number associated with the style."
    type: string
    sql: ${TABLE}.item.StyleNo ;;
  }

  dimension: plu {
    group_label: "Item Identifiers"
    label: "PLU"
    description: "Price Look-Up code used at the POS for items without a scannable barcode."
    type: number
    sql: ${TABLE}.item.PLU ;;
  }

  dimension: upc {
    group_label: "Item Identifiers"
    label: "UPC"
    description: "Universal Product Code (barcode) for the item."
    type: string
    sql: ${TABLE}.item.UPC ;;
  }

  dimension: clu {
    group_label: "Item Identifiers"
    label: "CLU"
    description: "Custom Look-Up code — alternate retailer-defined identifier."
    type: string
    sql: ${TABLE}.item.CLU ;;
  }

  dimension: eid {
    group_label: "Item Identifiers"
    label: "EID"
    description: "Electronic identifier (e.g. RFID tag id)."
    type: string
    sql: ${TABLE}.item.EID ;;
  }

  # ══════════════════════════════════════════════════
  # DCSS HIERARCHY
  # ══════════════════════════════════════════════════

  dimension: dcss {
    group_label: "DCSS Hierarchy"
    label: "DCSS"
    description: "Concatenated merchandise hierarchy (Department / Class / Subclass1 / Subclass2). Snapshot from time of transaction."
    type: string
    sql: ${TABLE}.item.DCSS ;;
  }

  dimension: department {
    group_label: "DCSS Hierarchy"
    description: "Top level of the merchandise hierarchy at time of transaction."
    type: string
    sql: ${TABLE}.item.Department ;;
  }

  dimension: class {
    group_label: "DCSS Hierarchy"
    description: "Second level of the merchandise hierarchy, beneath Department. Snapshot from time of transaction."
    type: string
    sql: ${TABLE}.item.Class ;;
  }

  dimension: subclass1 {
    group_label: "DCSS Hierarchy"
    label: "Subclass 1"
    description: "Third level of the merchandise hierarchy, beneath Class."
    type: string
    sql: ${TABLE}.item.Subclass1 ;;
  }

  dimension: subclass2 {
    group_label: "DCSS Hierarchy"
    label: "Subclass 2"
    description: "Fourth level of the merchandise hierarchy — most granular DCSS level."
    type: string
    sql: ${TABLE}.item.Subclass2 ;;
  }

  # ══════════════════════════════════════════════════
  # ATTRIBUTES
  # ══════════════════════════════════════════════════

  dimension: brand {
    group_label: "Item Attributes"
    description: "Brand name associated with the item at time of transaction."
    type: string
    sql: ${TABLE}.item.Brand ;;
  }

  dimension: season {
    group_label: "Item Attributes"
    description: "Merchandising season the item was assigned to at time of transaction."
    type: string
    sql: ${TABLE}.item.Season ;;
  }

  dimension: manufacturer {
    group_label: "Item Attributes"
    description: "Manufacturer of the item (may differ from Brand for private-label or licensed goods)."
    type: string
    sql: ${TABLE}.item.Manufacturer ;;
  }

  dimension: attribute1 {
    group_label: "Item Attributes"
    label: "Attribute 1"
    description: "First custom item attribute (size, color, or other dimension depending on Department conventions)."
    type: string
    sql: ${TABLE}.item.Attribute1 ;;
  }

  dimension: attribute1_set {
    group_label: "Item Attributes"
    label: "Attribute 1 Set"
    description: "Name of the attribute set Attribute 1 belongs to (e.g. 'Color', 'Size')."
    type: string
    sql: ${TABLE}.item.Attribute1Set ;;
  }

  dimension: attribute2 {
    group_label: "Item Attributes"
    label: "Attribute 2"
    description: "Second custom item attribute. Meaning varies by Department."
    type: string
    sql: ${TABLE}.item.Attribute2 ;;
  }

  dimension: attribute2_set {
    group_label: "Item Attributes"
    label: "Attribute 2 Set"
    description: "Name of the attribute set Attribute 2 belongs to."
    type: string
    sql: ${TABLE}.item.Attribute2Set ;;
  }

  dimension: attribute3 {
    group_label: "Item Attributes"
    label: "Attribute 3"
    description: "Third custom item attribute. Meaning varies by Department."
    type: string
    sql: ${TABLE}.item.Attribute3 ;;
  }

  dimension: attribute3_set {
    group_label: "Item Attributes"
    label: "Attribute 3 Set"
    description: "Name of the attribute set Attribute 3 belongs to."
    type: string
    sql: ${TABLE}.item.Attribute3Set ;;
  }

  # ══════════════════════════════════════════════════
  # DESCRIPTIONS
  # ══════════════════════════════════════════════════

  dimension: description1 {
    group_label: "Item Descriptions"
    label: "Description 1"
    description: "Primary item description used on receipts, signage, and reports."
    type: string
    sql: ${TABLE}.item.Description1 ;;
  }

  dimension: description2 {
    group_label: "Item Descriptions"
    label: "Description 2"
    description: "Secondary item description (long-form or alternate language)."
    type: string
    sql: ${TABLE}.item.Description2 ;;
  }

  dimension: description3 {
    group_label: "Item Descriptions"
    label: "Description 3"
    description: "Tertiary item description (purpose varies by retailer convention)."
    type: string
    sql: ${TABLE}.item.Description3 ;;
  }

  dimension: store_description {
    group_label: "Item Descriptions"
    description: "Description used in-store (signage and printed receipts)."
    type: string
    sql: ${TABLE}.item.StoreDescription ;;
  }

  # ══════════════════════════════════════════════════
  # PRICING
  # ══════════════════════════════════════════════════

  dimension: base_price {
    group_label: "Item Pricing"
    description: "List/regular base price at time of transaction. USD."
    type: number
    sql: ${TABLE}.item.BasePrice ;;
    value_format_name: usd
  }

  dimension: retail_price {
    group_label: "Item Pricing"
    description: "Retail price at time of transaction (after permanent markdowns, before promotions). USD."
    type: number
    sql: ${TABLE}.item.RetailPrice ;;
    value_format_name: usd
  }

  # ══════════════════════════════════════════════════
  # VENDOR
  # ══════════════════════════════════════════════════

  dimension: primary_vendor {
    group_label: "Item Vendor"
    description: "Primary vendor for the item at time of transaction."
    type: string
    sql: ${TABLE}.item.PrimaryVendor ;;
  }

  dimension: primary_vendor_order_cost {
    group_label: "Item Vendor"
    description: "Negotiated unit cost from the primary vendor at time of transaction. USD."
    type: number
    sql: ${TABLE}.item.PrimaryVendorOrderCost ;;
    value_format_name: usd
  }

  dimension: primary_vendor_min_order_qty {
    group_label: "Item Vendor"
    description: "Minimum order quantity from the primary vendor."
    type: number
    sql: ${TABLE}.item.PrimaryVendorMinOrderQty ;;
  }

  # ══════════════════════════════════════════════════
  # STATUS
  # ══════════════════════════════════════════════════

  dimension: is_non_inventory {
    group_label: "Item Status"
    description: "Yes when the item is not stock-tracked (services, fees, gift cards). Excluded from inventory metrics."
    type: yesno
    sql: ${TABLE}.item.IsNonInventory ;;
  }

  dimension: is_inactive {
    group_label: "Item Status"
    description: "Yes when the item was inactive at time of transaction."
    type: yesno
    sql: ${TABLE}.item.IsInactive ;;
  }

  dimension: sort_order {
    group_label: "Item Status"
    type: number
    sql: ${TABLE}.item.SortOrder ;;
    hidden: yes
  }
}
