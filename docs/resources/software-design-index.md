---
layout: post
title: "Software Design 2018-01～2024-11 総目次"
date: 2022-11-23 00:00:00 +0900
update: 2024-10-07 00:00:00 +0900
table: sortable searchable wide
show-on-home: true
---

{% assign num = 0 %}

\#|号|目次順|タイトル|回|サブタイトル|著者
-:|-|-:|-|-|-|-
{% for article in site.data.software-design-index -%}
{%- assign num = num | plus: 1 -%}
{{ num }}|<span>{{ article.volume }}</span>|{{ article.order }}|{{ article.title }}|{{ article.num }}|{{ article.subtitle }}|{{ article.author }}
{% endfor %}
