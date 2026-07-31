---
title: "Publications"
subtitle: "Selected publications and presentations connected to MIA and iEEG group analysis."
category: "Citation"
description: "MIA related publications and presentation references."
permalink: /publications/
---

## Cite MIA

If MIA supports your work, please cite **both** the version of the software you
actually ran and the paper that introduced the toolbox. Citing the software
itself, and not only the paper, credits every contributor to that release
([Westner et al., 2024](https://arxiv.org/abs/2403.19394)).

**1. The version of MIA you ran.** Run `mia_get_version` in Matlab to obtain it,
then cite:

<div class="callout" markdown="0">
  Dubarry A-S <em>et al.</em> MIA: Multi-patient Intracranial EEG Analysis,
  version X.Y.Z. <a href="{{ site.data.site.github_url }}" target="_blank" rel="noopener">{{ site.data.site.github_url }}</a>
</div>

**2. The paper introducing the toolbox.**

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
