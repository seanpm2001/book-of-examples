{%- comment -%}
Create a link to an appendix by slug.

Usage: {% include app_r.h slug="slug" %}

And yes, we have to loop over the array to get the index…
{%- endcomment -%}
{%- assign num = 0 -%}
{%- assign slug = nil -%}
{%- for entry in site.data.order.appendices -%}
  {%- if entry == include.slug -%}
    {%- assign num = forloop.index0 -%}
    {%- assign slug = "/" | append: entry | append: "/" -%}
    {%- break -%}
  {%- endif -%}
{%- endfor -%}
{%- assign letter = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" | slice: num -%}
<a href="{{ slug | relative_url }}">Appendix&nbsp;{{ letter }}</a>
