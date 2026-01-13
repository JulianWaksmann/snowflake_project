{% macro cleanup_old_schemas() %}
    {% set sql %}
        DROP SCHEMA IF EXISTS RAW_STAGE;
        DROP SCHEMA IF EXISTS RAW_ANALYTICS;
    {% endset %}

    {% do run_query(sql) %}
    {{ print("✅ Esquemas legacy (RAW_STAGE, RAW_ANALYTICS) eliminados correctamente.") }}
{% endmacro %}
