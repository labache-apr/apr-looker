# ══════════════════════════════════════════════════════════════
# CUSTOMER MASTER - Flat master data table (97 columns + 2 ARRAYs)
# ══════════════════════════════════════════════════════════════

view: customer_master {
  sql_table_name: `@{schema_name}.external_datamart_1.Customer_view` ;;

  # ── Identifiers ──

  dimension: customer_id {
    primary_key: yes
    group_label: "Customer Identifiers"
    description: "Internal identifier for the customer (lowercased for case-insensitive joins). Primary key of this view."
    type: string
    sql: LOWER(${TABLE}.CustomerId) ;;
  }

  dimension: customer_no {
    group_label: "Customer Identifiers"
    label: "Customer Number"
    description: "Customer-facing number used by associates and on receipts."
    type: string
    sql: ${TABLE}.CustomerNo ;;
  }

  dimension: eid {
    group_label: "Customer Identifiers"
    label: "EID"
    description: "External identifier (e.g. loyalty card number or third-party CRM id)."
    type: string
    sql: ${TABLE}.EID ;;
  }

  # ── Location ──

  dimension: location_code {
    type: string
    description: "Home location code for the customer"
    sql: ${TABLE}.LocationCode ;;
  }

  dimension: location {
    group_label: "Customer Identifiers"
    type: string
    description: "Home location name for the customer"
    sql: ${TABLE}.Location ;;
  }

  # ── Name ──

  dimension: first_name  { group_label: "Customer Name" description: "Customer's first name. PII — restricted use." type: string sql: ${TABLE}.FirstName ;; }
  dimension: last_name   { group_label: "Customer Name" description: "Customer's last name. PII — restricted use." type: string sql: ${TABLE}.LastName ;; }
  dimension: full_name {
    group_label: "Customer Name"
    description: "Concatenated first + last name. PII — restricted use."
    type: string
    sql: CONCAT(${TABLE}.FirstName, ' ', ${TABLE}.LastName) ;;
  }
  dimension: organization { group_label: "Customer Name" description: "Organization name when the customer is a business account." type: string sql: ${TABLE}.Organization ;; }

  # ── Contact ──

  dimension: email { group_label: "Customer Contact" description: "Primary email address. PII — restricted use." type: string sql: ${TABLE}.Email1 ;; }
  dimension: email2 { group_label: "Customer Contact" label: "Email 2" description: "Secondary email address. PII — restricted use." type: string sql: ${TABLE}.Email2 ;; }
  dimension: phone { group_label: "Customer Contact" description: "Primary phone number. PII — restricted use." type: string sql: ${TABLE}.PhoneNo1 ;; }
  dimension: phone2 { group_label: "Customer Contact" label: "Phone 2" description: "Secondary phone number. PII — restricted use." type: string sql: ${TABLE}.PhoneNo2 ;; }

  # ── Address ──

  dimension: address1    { group_label: "Customer Address" description: "Primary street address line. PII — restricted use." type: string sql: ${TABLE}.Address1 ;; }
  dimension: address2    { group_label: "Customer Address" description: "Secondary street address line (apt, suite). PII — restricted use." type: string sql: ${TABLE}.Address2 ;; }
  dimension: city        { group_label: "Customer Address" description: "Customer's city." type: string sql: ${TABLE}.City ;; }
  dimension: state       { group_label: "Customer Address" description: "Customer's state or province." type: string sql: ${TABLE}.State ;; }
  dimension: postal_code { group_label: "Customer Address" description: "Customer's postal/ZIP code. Use for trade-area analysis." type: string sql: ${TABLE}.PostalCode ;; }
  dimension: country     { group_label: "Customer Address" description: "Customer's country." type: string sql: ${TABLE}.Country ;; }

  # ── Classification ──

  dimension: price_level_code { group_label: "Classification" label: "Price Level" description: "Pricing tier the customer is assigned to (e.g. wholesale, employee, VIP)." type: string sql: ${TABLE}.PriceLevelCode ;; }

  # ── Status ──

  dimension: is_active     { group_label: "Status" description: "Yes when the customer record is active. Source field is named Active in the warehouse." type: yesno sql: ${TABLE}.Active ;; }
  dimension: is_inactive   { group_label: "Status" description: "Yes when the customer has been marked inactive. Note: Is Active and Is Inactive can be independent flags — check both for filtering." type: yesno sql: ${TABLE}.IsInactive ;; }

  # ── Title ──

  dimension: title { group_label: "Customer Name" description: "Title or salutation (Mr., Ms., Dr., etc.)." type: string sql: ${TABLE}.Title ;; }

  # ── Dates ──

  dimension_group: created {
    description: "Timestamp the customer record was created in the source system."
    type: time
    timeframes: [raw, date, month, quarter, year]
    sql: ${TABLE}.CreateDateTime ;;
  }

  dimension_group: last_modified {
    description: "Timestamp the customer record was last modified in the source system."
    type: time
    timeframes: [raw, date, month, year]
    sql: ${TABLE}.EditDateTime ;;
  }

  # ── Demographics ──

  dimension: gender       { group_label: "Demographics" description: "Customer's stated gender. May be NULL or unspecified." type: string sql: ${TABLE}.Gender ;; }
  dimension: middle_name  { group_label: "Customer Name" description: "Customer's middle name or initial. PII — restricted use." type: string sql: ${TABLE}.MiddleName ;; }
  dimension: is_employee  { group_label: "Demographics" description: "Yes when the customer is also an employee. Often excluded from comp-sales analysis." type: yesno  sql: ${TABLE}.IsEmployee ;; }
  dimension: is_company   { group_label: "Demographics" description: "Yes when the customer record represents a business/organization rather than an individual." type: yesno  sql: ${TABLE}.IsCompany ;; }
  dimension: is_anonymous { group_label: "Demographics" description: "Yes when the customer is an anonymous/walk-in placeholder rather than an identified individual." type: yesno  sql: ${TABLE}.IsAnonymous ;; }

  # ── Birthday / Anniversary ──

  dimension_group: birthdate {
    group_label: "Birthday"
    description: "Customer's date of birth. PII — restricted use."
    type: time
    timeframes: [raw, date, month, year]
    sql: ${TABLE}.Birthdate ;;
  }

  dimension_group: anniversary {
    group_label: "Anniversary"
    description: "Customer's anniversary date (use varies — wedding, membership, etc.)."
    type: time
    timeframes: [raw, date, month, year]
    sql: ${TABLE}.AnniversaryDate ;;
  }

  # ── Marketing Consent ──

  dimension: accept_marketing_1              { group_label: "Marketing Consent" label: "Accept Marketing 1"              description: "Consent flag for marketing channel 1. Honor before including the customer in promotional sends." type: yesno sql: ${TABLE}.AcceptMarketing1 ;; }
  dimension: accept_marketing_2              { group_label: "Marketing Consent" label: "Accept Marketing 2"              description: "Consent flag for marketing channel 2. Honor before including the customer in promotional sends." type: yesno sql: ${TABLE}.AcceptMarketing2 ;; }
  dimension: accept_transactional_emails_1   { group_label: "Marketing Consent" label: "Accept Transactional Emails 1"   description: "Consent flag for transactional email channel 1 (receipts, order confirmations)." type: yesno sql: ${TABLE}.AcceptTransactionalEmails1 ;; }
  dimension: accept_transactional_emails_2   { group_label: "Marketing Consent" label: "Accept Transactional Emails 2"   description: "Consent flag for transactional email channel 2." type: yesno sql: ${TABLE}.AcceptTransactionalEmails2 ;; }

  # ── Financial ──

  dimension: store_credit_balance { group_label: "Financial" description: "Current store credit balance available to the customer. USD." type: number sql: ${TABLE}.StoreCreditBalance ;; value_format_name: usd }

  # ── Membership ──

  dimension: membership_code        { group_label: "Membership" description: "Code identifying the membership program the customer is enrolled in." type: string sql: ${TABLE}.MembershipCode ;; }
  dimension: membership_level_label { group_label: "Membership" description: "Friendly label for the membership tier (e.g. Gold, Platinum)." type: string sql: ${TABLE}.MembershipLevelLabel ;; }
  dimension: membership_days        { group_label: "Membership" description: "Number of days remaining on the customer's current membership." type: number sql: ${TABLE}.MembershipDays ;; }
  dimension: membership_end_date    { group_label: "Membership" description: "Date the customer's current membership expires." type: string sql: CAST(${TABLE}.MembershipEndDate AS DATE) ;; }

  # ── Record Audit ──

  dimension: customer_status      { group_label: "Record Audit" description: "Numeric status code from the source system. See source documentation for code meanings." type: number sql: ${TABLE}.CustomerStatus ;; }
  dimension: create_employee_code { group_label: "Record Audit" description: "Code of the employee who created the customer record." type: string sql: ${TABLE}.CreateEmployeeCode ;; }
  dimension: edit_employee_code   { group_label: "Record Audit" description: "Code of the employee who last edited the customer record." type: string sql: ${TABLE}.EditEmployeeCode ;; }

  # ── Registration ──

  dimension_group: registration {
    group_label: "Registration"
    description: "Date the customer registered for an account or loyalty program."
    type: time
    timeframes: [raw, date, month, quarter, year]
    sql: ${TABLE}.RegistrationDate ;;
  }

  # ── Measures ──

  measure: customer_count {
    description: "Total count of customer records, including inactive and anonymous."
    type: count
    drill_fields: [customer_id, full_name, email, city, state]
  }

  measure: active_customer_count {
    description: "Count of customers where Is Active = yes. Note this only checks Is Active — also consider Is Inactive when filtering for true active set."
    type: count
    filters: [is_active: "yes"]
  }

  measure: employee_customer_count {
    description: "Count of customer records flagged as employees. Use to size or exclude employee-customer overlap."
    type: count
    filters: [is_employee: "yes"]
  }
}

# ══════════════════════════════════════════════════════════════
# CUSTOMER CONTACTS - Unnested ARRAY
# ══════════════════════════════════════════════════════════════

view: customer_contacts {
  derived_table: {
    sql:
      SELECT
        LOWER(c.CustomerId) AS customer_id,
        ct.FirstName AS contact_first_name,
        ct.LastName  AS contact_last_name,
        ct.EMail     AS contact_email,
        ct.Phone     AS contact_phone,
        ct.Title     AS contact_title
      FROM `@{schema_name}.external_datamart_1.Customer_view` c,
           UNNEST(c.contacts) AS ct
    ;;
  }

  dimension: customer_id        { type: string sql: ${TABLE}.customer_id ;; hidden: yes }
  dimension: contact_first_name { description: "First name of an associated contact (typically for business customers). PII." type: string sql: ${TABLE}.contact_first_name ;; }
  dimension: contact_last_name  { description: "Last name of an associated contact. PII." type: string sql: ${TABLE}.contact_last_name ;; }
  dimension: contact_email      { description: "Email of an associated contact. PII." type: string sql: ${TABLE}.contact_email ;; }
  dimension: contact_phone      { description: "Phone of an associated contact. PII." type: string sql: ${TABLE}.contact_phone ;; }
  dimension: contact_title      { description: "Job title of the contact at the customer organization." type: string sql: ${TABLE}.contact_title ;; }

  measure: contact_count { description: "Count of contact records (one per contact per customer; customers can have multiple)." type: count }
}

# ══════════════════════════════════════════════════════════════
# CUSTOMER ADDRESSES - Unnested ARRAY
# ══════════════════════════════════════════════════════════════

view: customer_addresses {
  derived_table: {
    sql:
      SELECT
        LOWER(c.CustomerId) AS customer_id,
        a.AddressType AS address_type,
        a.Address1    AS address1,
        a.Address2    AS address2,
        a.City        AS city,
        a.State       AS state,
        a.PostalCode  AS postal_code,
        a.Country     AS country
      FROM `@{schema_name}.external_datamart_1.Customer_view` c,
           UNNEST(c.addresses) AS a
    ;;
  }

  dimension: customer_id  { type: string sql: ${TABLE}.customer_id ;; hidden: yes }
  dimension: address_type { description: "Type of address (e.g. shipping, billing, home)." type: string sql: ${TABLE}.address_type ;; }
  dimension: address1     { description: "Street address line. PII — restricted use." type: string sql: ${TABLE}.address1 ;; }
  dimension: city         { description: "City of this address." type: string sql: ${TABLE}.city ;; }
  dimension: state        { description: "State or province of this address." type: string sql: ${TABLE}.state ;; }
  dimension: postal_code  { description: "Postal/ZIP code of this address." type: string sql: ${TABLE}.postal_code ;; }
  dimension: country      { description: "Country of this address." type: string sql: ${TABLE}.country ;; }

  measure: address_count { description: "Count of address records (one per address per customer; customers can have multiple)." type: count }
}