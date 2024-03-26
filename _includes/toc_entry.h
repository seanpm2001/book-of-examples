{%- comment -%}
Single entry in table of contents.
This is a standalone 'include' so that it can be used for both chapters and appendices.
{%- endcomment -%}
{%- assign temp = site.data.topic | find: "slug", include.slug -%}
<li><a href="./{{ temp.slug }}/">{{ temp.title }}</a></li>
