project_name: "apr_looker"

constant: schema_name {
  value: "default_schema" # A fallback value
  export: override_required # This forces the Spoke to provide a value
}

constant: model_name {
  value: "default_model"
  export: override_required # This is the key!
}
