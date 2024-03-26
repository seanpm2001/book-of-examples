{%- comment -%}
Table of contents.
Creates one ordered list for chapters and another for appendices based on `_data/order.yml`.
{%- endcomment -%}
<ol class="chapters">
  {% for slug in site.data.order.chapters %}{% include toc_entry.h slug=slug %}{% endfor %}
</ol>
<ol class="appendices">
  {% for slug in site.data.order.appendices %}{% include toc_entry.h slug=slug %}{% endfor %}
</ol>
