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
- Use the Brainstorm plugin menu to install MIA.
- See the [Brainstorm plugin tutorial](https://neuroimage.usc.edu/brainstorm/Tutorials/Plugins) for the plugin workflow.

## Standalone Matlab Installation

1. Go to the [MIA GitHub repository]({{ site.data.site.github_url }}).
2. Download one of the latest archives.
3. Unzip it somewhere on your computer, for example:
   - Windows: `Documents\mia`
   - Linux: `/usr/local/mia` or `~/mia`
   - macOS: `Applications/mia`
4. Create a separate `mia_db` folder for the MIA database, for example:
   - Windows: `Documents\mia_db`
   - Linux: `/home/username/mia_db`
   - macOS: `Documents/mia_db`

<div class="callout callout--warning">
  <strong>Important:</strong> never create the database folder inside the program
  folder. It may be deleted when updating MIA.
</div>

Set up regular backups for your `mia_db` folder so analysis work is not lost.

## Add MIA To Matlab

- Start Matlab.
- Add the MIA folder and subfolders to the Matlab path.

<figure class="figure-large">
  <img src="{{ '/assets/images/installation/matlab-add-path.png' | relative_url }}" alt="Matlab dialog showing how to add the MIA folder and subfolders to the path" loading="lazy">
  <figcaption>Add the MIA folder and all subfolders to the Matlab path.</figcaption>
</figure>

- Type `mia` in the Matlab command window.
- When asked for the MIA database folder, choose the `mia_db` folder you created.
- Continue with the tutorial material linked from the [Resources]({{ '/resources/' | relative_url }}) page.

## Requirements

The original MIA development notes mention Matlab 2017a as the main development
version. MIA aims to preserve backward compatibility where possible. If you hit
an installation error, open an issue and include your Matlab version.
