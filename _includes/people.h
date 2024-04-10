{%- comment -%}
Create a list of people's names with links to their GitHub sites.
{%- endcomment -%}

{%- comment -%}
Create an empty array `authors`. (Yes, this is really how it's done in Jekyll.)
{%- endcomment -%}
{%- assign authors = "" | split: "," -%}

{%- comment -%}
Fill the array with hyperlinked authors' names.
{%- endcomment -%}
{%- for ident in include.githubs -%}
  {%- assign temp = site.data.contrib | find: "github", ident -%}
  {%- capture name -%}<a href="https://github.com/{{ temp.github }}">{{ temp.personal }} {{ temp.family }}</a>{%- endcapture -%}
  {%- assign authors = authors | push: name -%}
{%- endfor -%}

{%- comment -%}
Create the final text.
{%- endcomment -%}
{{ authors | array_to_sentence_string: "and" }}
