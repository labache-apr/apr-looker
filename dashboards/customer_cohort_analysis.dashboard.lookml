---
- dashboard: customer_cohort_analysis
  title: "Customer Cohort Analysis"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Analyze customer behavior and value by acquisition cohort based on first purchase date."

  filters:
    - name: customer_type
      title: "Customer Type"
      type: field_filter
      explore: customer_performance
      field: customer_attributes.type
      default_value: ""
      allow_multiple_values: true

    - name: location
      title: "Home Location"
      type: field_filter
      explore: customer_performance
      field: customer_performance.location
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── New Customers by Cohort ──

    - title: "New Customers by Acquisition Quarter"
      name: cohort_count
      model: "@{model_name}"
      explore: customer_performance
      type: looker_column
      fields: [customer_metrics.first_purchase_quarter, customer_metrics.customer_count]
      fill_fields: [customer_metrics.first_purchase_quarter]
      sorts: [customer_metrics.first_purchase_quarter]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 0
      col: 0
      width: 24
      height: 7

    # ── Cohort Spend Analysis ──

    - title: "Avg Lifetime Spend by Acquisition Quarter"
      name: cohort_spend
      model: "@{model_name}"
      explore: customer_performance
      type: looker_grid
      fields: [customer_metrics.first_purchase_quarter, customer_metrics.customer_count,
               customer_metrics.avg_customer_spend, customer_metrics.avg_customer_transactions,
               customer_metrics.avg_transaction_value, customer_metrics.avg_margin_percent]
      fill_fields: [customer_metrics.first_purchase_quarter]
      sorts: [customer_metrics.first_purchase_quarter desc]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 7
      col: 0
      width: 24
      height: 8

    # ── Cohort Value Comparison ──

    - title: "Total Revenue by Acquisition Quarter"
      name: cohort_revenue
      model: "@{model_name}"
      explore: customer_performance
      type: looker_column
      fields: [customer_metrics.first_purchase_quarter, customer_metrics.total_lifetime_spend]
      fill_fields: [customer_metrics.first_purchase_quarter]
      sorts: [customer_metrics.first_purchase_quarter]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 15
      col: 0
      width: 12
      height: 7

    - title: "Avg Transactions by Acquisition Quarter"
      name: cohort_frequency
      model: "@{model_name}"
      explore: customer_performance
      type: looker_column
      fields: [customer_metrics.first_purchase_quarter, customer_metrics.avg_customer_transactions]
      fill_fields: [customer_metrics.first_purchase_quarter]
      sorts: [customer_metrics.first_purchase_quarter]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 15
      col: 12
      width: 12
      height: 7

    # ── Cohort by Year Detail ──

    - title: "Cohort Detail by Acquisition Year"
      name: cohort_year_detail
      model: "@{model_name}"
      explore: customer_performance
      type: looker_grid
      fields: [customer_metrics.first_purchase_year, customer_metrics.customer_count,
               customer_metrics.total_lifetime_spend, customer_metrics.avg_customer_spend,
               customer_metrics.total_transactions, customer_metrics.avg_customer_transactions,
               customer_metrics.avg_days_since_last_purchase, customer_metrics.return_rate]
      sorts: [customer_metrics.first_purchase_year desc]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 22
      col: 0
      width: 24
      height: 7
