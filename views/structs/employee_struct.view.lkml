view: employee_struct {
  extension: required  # Cannot be used standalone - must be extended

  # ══════════════════════════════════════════════════
  # IDENTIFIERS
  # ══════════════════════════════════════════════════

  dimension: employee_id {
    group_label: "Employee"
    description: "Internal identifier of the employee (associate) on the transaction. Snapshot from time of transaction — for current employee state, join to Employee dimension."
    type: string
    sql: ${TABLE}.employee.EmployeeId ;;
  }

  dimension: employee_label {
    group_label: "Employee"
    label: "Employee Label"
    description: "Display label for the employee (typically combining code and name)."
    type: string
    sql: ${TABLE}.employee.Label ;;
  }

  dimension: employee_name {
    group_label: "Employee"
    description: "Employee's full name as recorded on the transaction. PII — restricted use."
    type: string
    sql: ${TABLE}.employee.FullName ;;
  }

  dimension: employee_first_name {
    group_label: "Employee"
    description: "Employee's first name. PII — restricted use."
    type: string
    sql: ${TABLE}.employee.FirstName ;;
  }

  dimension: employee_last_name {
    group_label: "Employee"
    description: "Employee's last name. PII — restricted use."
    type: string
    sql: ${TABLE}.employee.LastName ;;
  }

  # ══════════════════════════════════════════════════
  # ROLE
  # ══════════════════════════════════════════════════

  dimension: employee_job_title {
    group_label: "Employee"
    label: "Job Title"
    description: "Employee's job title at time of transaction."
    type: string
    sql: ${TABLE}.employee.JobTitle ;;
  }

  dimension: is_active {
    group_label: "Employee"
    label: "Employee Is Active"
    description: "Yes when the employee was an active system user at time of transaction."
    type: yesno
    sql: ${TABLE}.employee.IsActiveUser ;;
  }
}
