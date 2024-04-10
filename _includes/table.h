{%- comment -%}
Create a table.

Usage: {% include table.h id="slug_something" src="file_path.tbl" caption="caption text" %}

1.  The included file should be a Markdown table (see example below).
2.  There is no way to attach an ID to a <table> element using Jekyll's Markdown parser
    so the table is wrapped in a <div> that has an ID.
3.  The caption is laid out as a paragraph immediately after the table
    because there is no way to add a caption to a Markdown table with Jekyll's Markdown parser.
4.  Tables are numbered sequentially from '1' within each chapter.

Example table (stored in a .tbl file):

| Left Title | Right Title |
| ---------- | ----------- |
| value 1    | value A     |
| value 2    | value B     |
{%- endcomment -%}

{%- unless tbl_counter -%}{%- assign tbl_counter = 1 -%}{%- endunless -%}
{%- capture tbl -%}{% include_relative {{ include.src }} %}{%- endcapture -%}
<div class="table" id="{{ include.id }}">
{{ tbl | markdownify | remove: "<p>" | remove : "</p>" | strip }}
<p>Table {{ tbl_counter }}: {{ include.caption | markdownify | remove: "<p>" | remove : "</p>" | strip }}</p>
</div>
{%- assign tbl_counter = tbl_counter | plus: 1 -%}
