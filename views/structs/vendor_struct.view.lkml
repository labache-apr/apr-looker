view: vendor_struct {
  extension: required  # Cannot be used standalone - must be extended

  # ══════════════════════════════════════════════════
  # IDENTIFIERS
  # ══════════════════════════════════════════════════

  dimension: vendor_id {
    group_label: "Vendor"
    description: "Internal identifier of the vendor on the transaction. Snapshot from time of transaction."
    type: string
    sql: ${TABLE}.vendor.VendorId ;;
  }

  dimension: vendor_no {
    group_label: "Vendor"
    label: "Vendor Number"
    description: "Vendor-facing number used in purchasing documents."
    type: string
    sql: ${TABLE}.vendor.VendorNo ;;
  }

  dimension: vendor_name {
    group_label: "Vendor"
    description: "Friendly name of the vendor."
    type: string
    sql: ${TABLE}.vendor.VendorName ;;
  }

  # ══════════════════════════════════════════════════
  # ATTRIBUTES
  # ══════════════════════════════════════════════════

  dimension: is_manufacturer {
    group_label: "Vendor"
    description: "Yes when the vendor is the manufacturer of the goods (rather than a distributor or wholesaler)."
    type: yesno
    sql: ${TABLE}.vendor.IsManufacturer ;;
  }

  dimension: lead_time_days {
    group_label: "Vendor"
    description: "Expected lead time in days from purchase order to receipt."
    type: number
    sql: ${TABLE}.vendor.LeadTimeDays ;;
  }

  # ══════════════════════════════════════════════════
  # ADDRESS
  # ══════════════════════════════════════════════════

  dimension: vendor_city {
    group_label: "Vendor Address"
    label: "City"
    description: "Vendor's city."
    type: string
    sql: ${TABLE}.vendor.City ;;
  }

  dimension: vendor_state {
    group_label: "Vendor Address"
    label: "State"
    description: "Vendor's state or province."
    type: string
    sql: ${TABLE}.vendor.State ;;
  }

  dimension: vendor_country {
    group_label: "Vendor Address"
    label: "Country"
    description: "Vendor's country."
    type: string
    sql: ${TABLE}.vendor.Country ;;
  }
}
