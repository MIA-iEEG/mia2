# MIA Website

Source for the MIA GitHub Pages website.

The website is intentionally self-contained in this `website/` directory so the
Matlab toolbox remains clean at the repository root.

## Local Preview

```bash
bundle install
bundle exec jekyll serve
```

Open `http://localhost:4000/mia/`.

## Content

- `_data/site.yml` stores project-wide settings and links.
- `_data/navigation.yml` stores header and footer navigation.
- `_data/content.yml` stores homepage sections.
- `_data/publications.yml` stores selected citation entries.
- `installation.md`, `dataset.md`, `resources.md`, and `publications.md` store page bodies.

## Deployment

The repository root contains `.github/workflows/pages.yml`. It builds this
nested Jekyll site and deploys the generated artifact to GitHub Pages when
changes are pushed to `feature/website_action` or when run manually.
