{%- comment -%}
Create a figure.

Usage: {% include figure.h id="slug_something" src="file_path.ext" alt="alt text" caption="caption text" %}

Figures are numbered sequentially from '1' within each chapter.
{%- endcomment -%}

{%- unless fig_counter -%}{%- assign fig_counter = 1 -%}{%- endunless -%}
<figure id="{{ include.id }}">
  <img src="./{{ include.img }}" alt="{{ include.alt }}">
  <figcaption>Figure {{ fig_counter }}: {{ include.caption | markdownify | remove: "<p>" | remove : "</p>" | strip }}</figcaption>
</figure>
{%- assign fig_counter = fig_counter | plus: 1 -%}
