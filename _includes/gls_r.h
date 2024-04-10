{%- comment -%}
Create a link to an entry in the glossary using `{% include gls_r.h key="some_key" text="inline text" %}`.

GitHub's Jekyll doesn't support shortcodes, so we have to use an inclusion.
{%- endcomment -%}
{%- capture url -%}/glossary/#g:{{ include.key }}{%- endcapture -%}
<a class="glossary" href="{{ url | relative_url }}">{{ include.text | markdownify | remove: "<p>" | remove: "</p>" }}</a>
