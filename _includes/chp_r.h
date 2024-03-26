{%- comment -%}
Create a link to a chapter by slug.

Usage: {% include chp_r.h slug="slug" %}

And yes, we have to loop over the array to get the index…
{%- endcomment -%}
{%- assign num = 0 -%}
{%- assign slug = nil -%}
{%- for entry in site.data.order.chapters -%}
  {%- if entry == include.slug -%}
    {%- assign num = forloop.index -%}
    {%- assign slug = "/" | append: entry | append: "/" -%}
    {%- break -%}
  {%- endif -%}
{%- endfor -%}
<a href="{{ slug | relative_url }}">Chapter&nbsp;{{ num }}</a>
