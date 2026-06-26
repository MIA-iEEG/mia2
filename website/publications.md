---
title: "Publications"
subtitle: "Selected publications and presentations connected to MIA and iEEG group analysis."
category: "Citation"
description: "MIA related publications and presentation references."
permalink: /publications/
---

## Cite MIA

If MIA supports your work, please cite the original MIA toolbox paper:

{% assign mia_paper = site.data.publications.featured | where: "year", 2022 | first %}
{% include publication-card.html item=mia_paper featured=true %}

## Selected Publications

<div class="publication-list">
{% for pub in site.data.publications.featured offset:1 %}
{% include publication-card.html item=pub %}
{% endfor %}
</div>

## Presentations

<div class="publication-list">
{% for item in site.data.publications.presentations %}
{% include publication-card.html item=item %}
{% endfor %}
</div>
