include: "/views/custom_fields/employee_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# DIM EMPLOYEE - Employee dimension from bi_star.dim_Employee_view
# Contains employee master data including identifiers, contact
# info, commission groups, and client-configurable custom fields.
# ══════════════════════════════════════════════════════════════

view: dim_employee {
  extends: [employee_custom_fields]
  sql_table_name: `aefc-prod-us-twc-b1bc.bi_star.dim_Employee_view` ;;

  # ── Identifiers ──

  dimension: employee_id {
    primary_key: yes
    group_label: "Identifiers"
    type: string
    sql: ${TABLE}.EmployeeId ;;
    hidden: yes
  }

  dimension: label {
    group_label: "Identifiers"
    description: "Display label for the employee, typically combining code and name."
    type: string
    sql: ${TABLE}.Label ;;
  }

  dimension: login_name {
    group_label: "Identifiers"
    description: "System login (username) for the employee."
    type: string
    sql: ${TABLE}.LoginName ;;
  }

  # ── Name ──

  dimension: first_name  { group_label: "Name" description: "Employee's first name. PII — restricted use." type: string sql: ${TABLE}.FirstName ;; }
  dimension: last_name   { group_label: "Name" description: "Employee's last name. PII — restricted use." type: string sql: ${TABLE}.LastName ;; }
  dimension: full_name   { group_label: "Name" description: "Employee's full name. PII — restricted use." type: string sql: ${TABLE}.FullName ;; }
  dimension: nickname    { group_label: "Name" description: "Employee's nickname (often shown on receipts in place of full name)." type: string sql: ${TABLE}.Nickname ;; }

  # ── Status ──

  dimension: is_active {
    group_label: "Status"
    description: "Yes when the employee is an active system user. Source field is named IsActiveUser."
    type: yesno
    sql: ${TABLE}.IsActiveUser ;;
  }

  dimension: is_universal_user {
    group_label: "Status"
    description: "Yes when the employee can access all locations rather than being scoped to one home location."
    type: yesno
    sql: ${TABLE}.IsUniversalUser ;;
  }

  # ── Home Location ──

  dimension: home_location_id {
    group_label: "Home Location"
    type: string
    sql: ${TABLE}.HomeLocationId ;;
    hidden: yes
  }

  dimension: home_location {
    group_label: "Home Location"
    description: "Friendly name of the employee's home location."
    type: string
    sql: ${TABLE}.HomeLocation ;;
  }

  # ── Commission ──

  dimension: commission_group_code {
    group_label: "Commission"
    description: "Code identifying the commission group the employee is assigned to."
    type: string
    sql: ${TABLE}.CommissionGroupCode ;;
  }

  dimension: commission_group_description {
    group_label: "Commission"
    description: "Friendly description of the commission group."
    type: string
    sql: ${TABLE}.CommissionGroupDescription ;;
  }

  # ── Contact ──

  dimension: job_title { group_label: "Contact" description: "Employee's job title." type: string sql: ${TABLE}.JobTitle ;; }
  dimension: phone_no  { group_label: "Contact" description: "Employee's phone number. PII — restricted use." type: string sql: ${TABLE}.PhoneNo ;; }
  dimension: email     { group_label: "Contact" description: "Employee's email address. PII — restricted use." type: string sql: ${TABLE}.Email ;; }

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

  # ── Custom Fields ──
  # Custom Lookups (1-12) and Custom Text (1-6) inherited from
  # employee_custom_fields. Client should rename labels and toggle
  # hidden: yes on unused fields when extending.

  # ── Measures ──

  measure: employee_count {
    description: "Distinct count of employees, including inactive."
    type: count_distinct
    sql: ${employee_id} ;;
    drill_fields: [employee_id, full_name, job_title, home_location, email]
  }

  measure: active_employee_count {
    description: "Distinct count of employees where Is Active = yes."
    type: count_distinct
    sql: ${employee_id} ;;
    filters: [is_active: "yes"]
    drill_fields: [employee_id, full_name, job_title, home_location, email]
  }
}
