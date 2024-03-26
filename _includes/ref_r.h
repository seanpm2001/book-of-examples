{%- comment -%}
Create a link to an entry in the references using `{% include ref_r.h key="some_key" %}`.

GitHub's Jekyll doesn't support shortcodes, so we have to use an inclusion.
{%- endcomment -%}
{%- capture url -%}/references/#b:{{ include.key }}{%- endcapture -%}
{%- assign entry = site.data.references | find: "key", include.key -%}
{%- assign title = entry["title"] | markdownify | remove: "<p>" | remove: "</p>" -%}
<a class="references" href="{{ url | relative_url }}">{{ title }}</a>
