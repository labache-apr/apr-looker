view: customer_struct {
  extension: required  # Cannot be used standalone - must be extended

  # ══════════════════════════════════════════════════
  # IDENTIFIERS
  # ══════════════════════════════════════════════════

  dimension: customer_id {
    group_label: "Customer Identifiers"
    description: "Internal identifier of the customer on the transaction (lowercased for case-insensitive joins). Snapshot from time of transaction — for current customer state, join to Customer Master."
    type: string
    sql: LOWER(${TABLE}.customer.CustomerId) ;;
  }

  dimension: customer_no {
    group_label: "Customer Identifiers"
    label: "Customer Number"
    description: "Customer-facing number used by associates and on receipts."
    type: string
    sql: ${TABLE}.customer.CustomerNo ;;
  }

  dimension: customer_label {
    group_label: "Customer Identifiers"
    description: "Display label for the customer (typically combining number and name)."
    type: string
    sql: ${TABLE}.customer.Label ;;
  }

  # ══════════════════════════════════════════════════
  # NAME
  # ══════════════════════════════════════════════════

  dimension: first_name {
    group_label: "Customer Name"
    description: "Customer's first name. PII — restricted use."
    type: string
    sql: ${TABLE}.customer.FirstName ;;
  }

  dimension: last_name {
    group_label: "Customer Name"
    description: "Customer's last name. PII — restricted use."
    type: string
    sql: ${TABLE}.customer.LastName ;;
  }

  dimension: full_name {
    group_label: "Customer Name"
    description: "Concatenated first + last name. PII — restricted use."
    type: string
    sql: CONCAT(${TABLE}.customer.FirstName, ' ', ${TABLE}.customer.LastName) ;;
  }

  dimension: organization {
    group_label: "Customer Name"
    description: "Organization name when the customer is a business account."
    type: string
    sql: ${TABLE}.customer.Organization ;;
  }

  # ══════════════════════════════════════════════════
  # CONTACT
  # ══════════════════════════════════════════════════

  dimension: email {
    group_label: "Customer Contact"
    description: "Customer's primary email at time of transaction. PII — restricted use."
    type: string
    sql: ${TABLE}.customer.Email1 ;;
  }

  dimension: phone {
    group_label: "Customer Contact"
    description: "Customer's primary phone number at time of transaction. PII — restricted use."
    type: string
    sql: ${TABLE}.customer.PhoneNo1 ;;
  }

  # ══════════════════════════════════════════════════
  # ADDRESS
  # ══════════════════════════════════════════════════

  dimension: city {
    group_label: "Customer Address"
    description: "Customer's city at time of transaction."
    type: string
    sql: ${TABLE}.customer.City ;;
  }

  dimension: state {
    group_label: "Customer Address"
    description: "Customer's state or province at time of transaction."
    type: string
    sql: ${TABLE}.customer.State ;;
  }

  dimension: country {
    group_label: "Customer Address"
    description: "Customer's country at time of transaction."
    type: string
    sql: ${TABLE}.customer.Country ;;
  }

  dimension: postal_code {
    group_label: "Customer Address"
    description: "Customer's postal/ZIP code at time of transaction. Use for trade-area analysis."
    type: string
    sql: ${TABLE}.customer.PostalCode ;;
  }

  # ══════════════════════════════════════════════════
  # CLASSIFICATION
  # ══════════════════════════════════════════════════

  dimension: wholesale_customer {
    group_label: "Customer Classification"
    description: "Yes when the customer was classified as wholesale at time of transaction. Often excluded from retail comp-sales reporting."
    type: yesno
    sql: ${TABLE}.customer.WholesaleCustomer ;;
  }

  # ══════════════════════════════════════════════════
  # STATUS
  # ══════════════════════════════════════════════════

  dimension: is_active {
    group_label: "Customer Status"
    description: "Yes when the customer was active at time of transaction (computed as NOT IsInactive)."
    type: yesno
    sql: NOT ${TABLE}.customer.IsInactive ;;
  }

  dimension: is_inactive {
    group_label: "Customer Status"
    description: "Yes when the customer was inactive at time of transaction."
    type: yesno
    sql: ${TABLE}.customer.IsInactive ;;
  }

  # ══════════════════════════════════════════════════
  # LOYALTY
  # ══════════════════════════════════════════════════

  dimension: opt_in_loyalty {
    group_label: "Customer Loyalty"
    label: "Opt In Loyalty Program"
    description: "Numeric flag indicating loyalty program enrollment status. See source documentation for code meanings."
    type: number
    sql: ${TABLE}.customer.OptInLoyaltyProgram ;;
  }
}
