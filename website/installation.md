---
title: "Installation"
subtitle: "Install MIA through Brainstorm or as a standalone Matlab toolbox."
category: "Getting Started"
description: "Installation instructions for MIA."
permalink: /installation/
---

<div class="content-logo">
  <img src="{{ '/assets/images/logo/mia_newlogo3.png' | relative_url }}" alt="MIA logo">
</div>

## MIA Installation With Brainstorm

- Install the latest version of [Brainstorm](https://neuroimage.usc.edu/brainstorm/Introduction).
- In the Brainstorm window, open `Plugins → sEEG → mia → Install`.
- See the [Brainstorm plugin tutorial](https://neuroimage.usc.edu/brainstorm/Tutorials/Plugins) for the plugin workflow.

<figure class="figure-large" markdown="0">
  <img src="{{ '/assets/images/installation/brainstorm-plugin-menu.webp' | relative_url }}" alt="Brainstorm Plugins menu opened on sEEG then mia, showing the Install entry for the github-master version" loading="lazy">
  <figcaption>Install MIA from the Brainstorm plugin menu. Once installed, the same menu offers Update, Uninstall, Load and Start MIA.</figcaption>
</figure>

## Standalone Matlab Installation

Use this route if you do not run Brainstorm, or if you want to read and modify
the MIA source.

**1. Get the code.** Either download the latest archive from the
[MIA GitHub repository]({{ site.data.site.github_url }}) and unzip it, or clone
the repository:

```
git clone {{ site.data.site.github_url }}.git mia
```

Cloning is worth preferring if you expect to update, since later versions are
then a `git pull` away.

**2. Put the program folder somewhere you can write to** without administrator
rights:

- Windows: `Documents\mia`
- macOS: `~/Documents/mia`
- Linux: `~/mia`

**3. Create a separate, empty folder for the MIA database**, next to the program
folder rather than inside it:

- Windows: `Documents\mia_db`
- macOS: `~/Documents/mia_db`
- Linux: `~/mia_db`

<div class="callout callout--warning">
  <strong>Important:</strong> never create the database folder inside the program
  folder. It may be deleted when updating MIA, taking your analyses with it.
  Back up <code>mia_db</code> regularly.
</div>

## Add MIA To Matlab

- Start Matlab.
- Add the MIA folder **and its subfolders** to the Matlab path
  (`Home → Set Path → Add with Subfolders`), then save the path so MIA is still
  available the next time you start Matlab.

<figure class="figure-large" markdown="0">
  <img src="{{ '/assets/images/installation/matlab-add-path.png' | relative_url }}" alt="Matlab dialog showing how to add the MIA folder and subfolders to the path" loading="lazy">
  <figcaption>Add the MIA folder and all subfolders to the Matlab path.</figcaption>
</figure>

- Type `mia` in the Matlab command window.
- On the first run only, MIA asks for a database directory. Choose the empty
  `mia_db` folder you created — it must be empty, and it is remembered from then
  on.
- Continue with the [tutorial]({{ '/tutorial/' | relative_url }}), or browse the
  [Resources]({{ '/resources/' | relative_url }}) page.

## Requirements

The original MIA development notes mention Matlab 2017a as the main development
version. MIA aims to preserve backward compatibility where possible. If you hit
an installation error, open an issue and include your Matlab version.
