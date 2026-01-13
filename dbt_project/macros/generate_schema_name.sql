{#
    This macro overrides the default dbt behavior for generating schema names.
    By default, dbt concatenates the target schema (e.g., 'RAW') with the custom schema (e.g., 'STAGE') -> 'RAW_STAGE'.
    
    This override forces dbt to use the custom schema name EXACTLY as defined.
    If 'custom_schema_name' is provided (e.g., 'STAGE'), it uses 'STAGE'.
    If not provided, it falls back to the default target schema.
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
