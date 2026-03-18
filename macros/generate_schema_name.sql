{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set target_schema = target.schema -%}
    {%- if '.' in target_schema -%}
        {%- set target_schema = target_schema.split('.')[-1] -%}
    {%- endif -%}

    {%- if custom_schema_name is none -%}
        {{ target_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
