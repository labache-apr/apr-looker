---
- dashboard: action_tracking
  title: "Action Tracking - Audit & Loss Prevention"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "POS and back-office action audit trail for loss prevention. Surfaces voids, item removals, price changes, manager overrides, failed logins, and cash-drawer events by employee, workstation, and location."
  preferred_slug: action-tracking

  filters:
    - name: date_range
      title: "Date Range"
      type: field_filter
      explore: action_tracking
      field: action_tracking.action_at_date
      default_value: "7 days"
      allow_multiple_values: true

    - name: location
      title: "Location"
      type: field_filter
      explore: action_tracking
      field: dim_location_franchise.location_name
      default_value: ""
      allow_multiple_values: true

    - name: action
      title: "Action"
      type: field_filter
      explore: action_tracking
      field: action_tracking.action
      default_value: "-ApplicationDidBecomeActive,-ApplicationWillResignActive,-ApplicationDidEnterBackground,-ApplicationWillEnterForeground,-ApplicationRun,-ApplicationWillTerminate,-DocumentStarted"
      allow_multiple_values: true

    - name: application
      title: "Application"
      type: field_filter
      explore: action_tracking
      field: action_tracking.application
      default_value: ""
      allow_multiple_values: true

    - name: employee
      title: "Employee"
      type: field_filter
      explore: action_tracking
      field: dim_employee.full_name
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── KPI Row ──

    - title: "Total Actions"
      name: total_actions
      model: twc_aefc
      explore: action_tracking
      type: single_value
      fields: [action_tracking.action_count]
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        action: action_tracking.action
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 0
      col: 0
      width: 6
      height: 3

    - title: "Distinct Employees"
      name: distinct_employees
      model: twc_aefc
      explore: action_tracking
      type: single_value
      fields: [action_tracking.distinct_employees]
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        action: action_tracking.action
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 0
      col: 6
      width: 6
      height: 3

    - title: "Distinct Workstations"
      name: distinct_workstations
      model: twc_aefc
      explore: action_tracking
      type: single_value
      fields: [action_tracking.distinct_workstations]
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        action: action_tracking.action
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 0
      col: 12
      width: 6
      height: 3

    - title: "Failed Logins"
      name: failed_logins
      model: twc_aefc
      explore: action_tracking
      type: single_value
      fields: [action_tracking.action_count]
      filters:
        action_tracking.action: "LoginFailed,TransactionLoginFailed,InitLoginFailed,ManageTCLoginFailed,ManagerOverrideLoginFailed"
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 0
      col: 18
      width: 6
      height: 3

    # ── Voided / Discarded Transaction Value (loss-prevention dollar exposure) ──

    - title: "Voided & Discarded Receipt Value"
      name: voided_value
      model: twc_aefc
      explore: action_tracking
      type: single_value
      fields: [action_tracking.total_receipt_value_with_tax]
      filters:
        action_tracking.action: "DiscountVoided,LineDiscountVoided,DocumentDiscarded"
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 3
      col: 0
      width: 8
      height: 3

    - title: "Discount Applied — Receipt Value"
      name: discount_value
      model: twc_aefc
      explore: action_tracking
      type: single_value
      fields: [action_tracking.total_receipt_value_with_tax]
      filters:
        action_tracking.action: "DiscountApplied,LineDiscountApplied"
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 3
      col: 8
      width: 8
      height: 3

    - title: "Manual 'No Sale' Drawer Opens"
      name: no_sale_opens
      model: twc_aefc
      explore: action_tracking
      type: single_value
      fields: [action_tracking.action_count]
      filters:
        action_tracking.action: "CashDrawerOpened"
        action_tracking.drawer_open_type: "-Change Due,-NULL"
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 3
      col: 16
      width: 8
      height: 3

    # ── Action Trend ──

    - title: "Actions Over Time"
      name: actions_trend
      model: twc_aefc
      explore: action_tracking
      type: looker_line
      fields: [action_tracking.action_at_date, action_tracking.action, action_tracking.action_count]
      pivots: [action_tracking.action]
      fill_fields: [action_tracking.action_at_date]
      sorts: [action_tracking.action_at_date, action_tracking.action_count desc]
      limit: 5000
      column_limit: 12
      x_axis_gridlines: false
      y_axis_gridlines: true
      legend_position: center
      point_style: none
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        action: action_tracking.action
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 6
      col: 0
      width: 24
      height: 7

    # ── Actions by Type ──

    - title: "Actions by Type"
      name: actions_by_type
      model: twc_aefc
      explore: action_tracking
      type: looker_bar
      fields: [action_tracking.action, action_tracking.action_count]
      sorts: [action_tracking.action_count desc]
      limit: 25
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        action: action_tracking.action
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 13
      col: 0
      width: 12
      height: 7

    # ── Actions by Location ──

    - title: "Actions by Location"
      name: actions_by_location
      model: twc_aefc
      explore: action_tracking
      type: looker_bar
      fields: [dim_location_franchise.location_name, action_tracking.action_count]
      sorts: [action_tracking.action_count desc]
      limit: 25
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        action: action_tracking.action
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 13
      col: 12
      width: 12
      height: 7

    # ── Hour-of-Day Heatmap (off-hours signal for loss prevention) ──

    - title: "Action Volume by Day of Week and Hour"
      name: actions_heatmap
      model: twc_aefc
      explore: action_tracking
      type: looker_grid
      fields: [action_tracking.action_at_day_of_week, action_tracking.action_at_hour_of_day,
               action_tracking.action_count]
      pivots: [action_tracking.action_at_hour_of_day]
      sorts: [action_tracking.action_at_day_of_week, action_tracking.action_at_hour_of_day]
      limit: 500
      enable_conditional_formatting: true
      conditional_formatting_include_totals: false
      conditional_formatting_include_nulls: false
      conditional_formatting:
        - type: along a scale...
          value:
          background_color:
          font_color:
          color_application:
            collection_id: legacy
            palette_id: legacy_diverging0
            options:
              steps: 5
              constraints:
                min:
                  type: minimum
                mid:
                  type: middle
                max:
                  type: maximum
              mirror: true
              reverse: false
              stepped: false
          bold: false
          italic: false
          strikethrough: false
          fields: [action_tracking.action_count]
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        action: action_tracking.action
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 20
      col: 0
      width: 24
      height: 7

    # ── High-Risk Sales Actions by Employee ──
    # Voids, item removals, price changes, document discards, manager overrides — the audit-of-record events for loss prevention

    - title: "High-Risk Sales Actions by Employee"
      name: high_risk_by_employee
      model: twc_aefc
      explore: action_tracking
      type: looker_grid
      fields: [dim_employee.full_name, dim_employee.home_location, action_tracking.action,
               action_tracking.action_count, action_tracking.total_receipt_value_with_tax,
               action_tracking.distinct_workstations]
      pivots: [action_tracking.action]
      filters:
        action_tracking.action: "DiscountVoided,LineDiscountVoided,DrawerMemoPaidInOutVoided,ItemRemoved,ItemPriceChanged,DocumentDiscarded,ManagerOverrideLogin,ManagerOverrideLoginFailed,Reprint"
      sorts: [action_tracking.action_count desc 0]
      limit: 50
      column_limit: 50
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 27
      col: 0
      width: 24
      height: 8

    # ── High-Risk Sales Actions by Location ──

    - title: "High-Risk Sales Actions by Location"
      name: high_risk_by_location
      model: twc_aefc
      explore: action_tracking
      type: looker_grid
      fields: [dim_location_franchise.location_name, action_tracking.action,
               action_tracking.action_count, action_tracking.total_receipt_value_with_tax,
               action_tracking.distinct_employees]
      pivots: [action_tracking.action]
      filters:
        action_tracking.action: "DiscountVoided,LineDiscountVoided,DrawerMemoPaidInOutVoided,ItemRemoved,ItemPriceChanged,DocumentDiscarded,ManagerOverrideLogin,ManagerOverrideLoginFailed,Reprint"
      sorts: [action_tracking.action_count desc 0]
      limit: 50
      column_limit: 50
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 35
      col: 0
      width: 24
      height: 7

    # ── Failed Login Attempts (credential probing) ──

    - title: "Failed Login Attempts"
      name: failed_logins_by_employee
      model: twc_aefc
      explore: action_tracking
      type: looker_grid
      fields: [dim_employee.full_name, dim_location_franchise.location_name,
               action_tracking.action, action_tracking.workstation_id,
               action_tracking.action_count]
      filters:
        action_tracking.action: "LoginFailed,TransactionLoginFailed,InitLoginFailed,ManageTCLoginFailed,ManagerOverrideLoginFailed"
      sorts: [action_tracking.action_count desc]
      limit: 50
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 42
      col: 0
      width: 12
      height: 7

    # ── Cash Drawer Activity (paid-in/out and non-sale opens) ──
    # CashDrawerOpened reason often = "Sales Receipt - Change". Paid-in/out events are the manual cash movements worth auditing.

    - title: "Cash Movement Activity by Employee"
      name: cash_movement
      model: twc_aefc
      explore: action_tracking
      type: looker_grid
      fields: [dim_employee.full_name, dim_location_franchise.location_name,
               action_tracking.action, action_tracking.action_count]
      pivots: [action_tracking.action]
      filters:
        action_tracking.action: "DrawerMemoPaidInOutAdded,DrawerMemoPaidInOutEdited,DrawerMemoPaidInOutVoided,DrawerMemoTakenOffline"
      sorts: [action_tracking.action_count desc 0]
      limit: 50
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 42
      col: 12
      width: 12
      height: 7

    # ── Detailed Audit Trail ──
    # Surfaces parsed DetailedInfo fields. Raw XML payload is intentionally omitted — drill on Action ID for the full record.

    - title: "Audit Trail (Detail)"
      name: audit_trail
      model: twc_aefc
      explore: action_tracking
      type: looker_grid
      fields: [action_tracking.action_at_time, dim_location_franchise.location_name,
               dim_employee.full_name, action_tracking.action, action_tracking.reason,
               action_tracking.receipt_num, action_tracking.receipt_total_with_tax,
               action_tracking.receipt_total_qty, action_tracking.global_discount_percent,
               action_tracking.drawer_open_type, action_tracking.customer_last_name,
               action_tracking.customer_first_name, action_tracking.membership_code,
               action_tracking.workstation_id, action_tracking.application]
      sorts: [action_tracking.action_at_time desc]
      limit: 500
      listen:
        date_range: action_tracking.action_at_date
        location: dim_location_franchise.location_name
        action: action_tracking.action
        application: action_tracking.application
        employee: dim_employee.full_name
      row: 49
      col: 0
      width: 24
      height: 10
