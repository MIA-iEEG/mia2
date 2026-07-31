---
title: "MIA2 Tutorial"
subtitle: "Run the updated MIA workflow from Brainstorm channel concatenation through condition contrasts."
category: "Learning"
description: "Step-by-step tutorial for the updated MIA2 Brainstorm processes."
permalink: /tutorial/
body_class: tutorial-page
wide_content: true
---

This tutorial describes the updated MIA2 workflow for preparing a shared channel
space, calculating Morlet time-frequency representations, converting Brainstorm
data to MIA ROI data, visualizing averages, and contrasting two conditions.

<nav class="tutorial-toc" aria-label="Tutorial steps" markdown="0">
  <p class="tutorial-toc__title">In this tutorial</p>
  <ol>
    <li><a href="#concatenate-channels"><span>01</span>Concatenate channels</a></li>
    <li><a href="#morlet-time-frequency"><span>02</span>Calculate time-frequency</a></li>
    <li><a href="#convert-to-mia"><span>03</span>Convert to MIA</a></li>
    <li><a href="#visualize-averages"><span>04</span>Visualize averages</a></li>
    <li><a href="#run-statistics"><span>05</span>Run statistics</a></li>
  </ol>
</nav>

## 1. Concatenate channels {#concatenate-channels}

**Process:** `MIA/bst_plugin/process_concatenate_channels.m`

This process creates a new grand subject containing the channels from the
selected subjects in the current Brainstorm protocol. The shared channel space
makes later ROI-based MIA analyses easier to run.

<div class="tutorial-menu-path" markdown="0">
  <span>Brainstorm menu</span>
  <code>Run → Add process icon → Standardize → MIA: Concatenate Channels</code>
</div>

<div class="tutorial-figure-grid tutorial-figure-grid--menu" markdown="0">
  <figure class="tutorial-figure">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/concatenate-channels-menu.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the Concatenate Channels menu screenshot at full size">
      <img src="{{ '/assets/images/tutorial/concatenate-channels-menu.png' | relative_url }}" alt="Brainstorm process menu with MIA Concatenate Channels selected" loading="lazy">
    </a>
    <figcaption>Select MIA: Concatenate Channels from the Standardize process group.</figcaption>
  </figure>
  <figure class="tutorial-figure tutorial-figure--compact">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/concatenate-channels-options.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the Concatenate Channels options screenshot at full size">
      <img src="{{ '/assets/images/tutorial/concatenate-channels-options.png' | relative_url }}" alt="MIA Concatenate Channels process options" loading="lazy">
    </a>
    <figcaption>Configure the grand-subject name and subjects to skip.</figcaption>
  </figure>
</div>

The process has two user-facing inputs:

1. **New subject name:** Name of the grand subject to create. The default is `COREG`.
2. **Subjects to skip:** Comma-separated subjects that should not be included.
   Leave this field empty to include all subjects.

For example:

```text
Subject01, Subject02
```

Click **Run** to create the grand subject.

## 2. Calculate time-frequency representations with Morlet wavelets {#morlet-time-frequency}

**Process:** `MIA/bst_plugin/process_mia_extract_tf.m`

This process calculates a Morlet-wavelet time-frequency representation of the
Brainstorm data dropped into **Process1**. It uses the current Brainstorm
protocol and applies 1/f normalization.

<div class="tutorial-menu-path" markdown="0">
  <span>Brainstorm menu</span>
  <code>Frequency → MIA: Time-frequency (Morlet by band + 1/f norm)</code>
</div>

<div class="tutorial-figure-grid tutorial-figure-grid--menu" markdown="0">
  <figure class="tutorial-figure">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/morlet-time-frequency-menu.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the Morlet time-frequency menu screenshot at full size">
      <img src="{{ '/assets/images/tutorial/morlet-time-frequency-menu.png' | relative_url }}" alt="Brainstorm Frequency menu with the MIA Morlet time-frequency process selected" loading="lazy">
    </a>
    <figcaption>Select the MIA Morlet time-frequency process.</figcaption>
  </figure>
  <figure class="tutorial-figure tutorial-figure--compact">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/morlet-time-frequency-options.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the Morlet time-frequency options screenshot at full size">
      <img src="{{ '/assets/images/tutorial/morlet-time-frequency-options.png' | relative_url }}" alt="MIA Morlet time-frequency process options" loading="lazy">
    </a>
    <figcaption>Set the baseline, frequency bands, and number of cycles.</figcaption>
  </figure>
</div>

The process contains these inputs:

1. **Baseline:** Time window in milliseconds used for 1/f normalization. Enter a
   start and end time, such as `-400.0` to `-1.0` ms, or select **All file** to
   use the entire file.
2. **Frequency bands:** Frequencies and steps to extract, written as a MATLAB
   array expression. For example, `50:10:170` extracts frequencies from 50 Hz
   through 170 Hz in 10 Hz steps.
3. **Number of cycles:** Number of cycles at the Morlet wavelet's central
   frequency. For example, `7` controls the time-frequency resolution trade-off.

Click **Run** to calculate the time-frequency representation.

## 3. Convert Brainstorm data to MIA {#convert-to-mia}

**Process:** `MIA/bst_plugin/process_mia_bst2mia.m`

This process converts Brainstorm data into MIA ROI data. It uses the current
Brainstorm protocol, the condition dropped into **Process1**, the selected
subject's channel file, and a labeling table.

<div class="tutorial-menu-path" markdown="0">
  <span>Brainstorm menu</span>
  <code>Run → Add process icon → Test → MIA: Convert from BST to MIA</code>
</div>

<div class="tutorial-figure-grid tutorial-figure-grid--menu" markdown="0">
  <figure class="tutorial-figure">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/bst-to-mia-menu.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the Convert from BST to MIA menu screenshot at full size">
      <img src="{{ '/assets/images/tutorial/bst-to-mia-menu.png' | relative_url }}" alt="Brainstorm process menu with Convert from BST to MIA selected" loading="lazy">
    </a>
    <figcaption>Select MIA: Convert from BST to MIA.</figcaption>
  </figure>
  <figure class="tutorial-figure tutorial-figure--compact">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/bst-to-mia-options.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the Convert from BST to MIA options screenshot at full size">
      <img src="{{ '/assets/images/tutorial/bst-to-mia-options.png' | relative_url }}" alt="Convert from BST to MIA process options" loading="lazy">
    </a>
    <figcaption>Choose the labeling table, channel subject, and subjects to skip.</figcaption>
  </figure>
</div>

The conversion uses these inputs:

1. **Files in Process1:** Drop one condition from the Brainstorm database. The
   process reads the condition automatically from `sInputs(1).Condition`.
2. **Labeling table (TSV):** Path to the `.tsv` file containing the labeling information.
3. **Channel subject:** Subject from the current Brainstorm protocol whose
   `channel.mat` file should be resolved automatically.
4. **Subjects to skip:** Comma-separated subjects to exclude. Leave the field
   empty to use all eligible subjects.

For example:

```text
Subject01, Subject02
```

Click **Run**. For each converted condition, the process creates:

```text
<brainstorm_protocol_dir>/data/<group_subject>/ROIS/<ConditionName>_rois.mat
```

`<ConditionName>` is the condition dropped into Process1. With the default
grand-subject name, `<group_subject>` is `COREG`.

## 4. Visualize averages {#visualize-averages}

**Process:** `MIA/bst_plugin/process_mia_group_gui.m`

This process opens `mia_group_gui` from ROI files already saved in the current
Brainstorm protocol.

<div class="tutorial-menu-path" markdown="0">
  <span>Brainstorm menu</span>
  <code>Run → Add process icon → Test → MIA: Visualize Averages</code>
</div>

<div class="tutorial-figure-grid tutorial-figure-grid--three" markdown="0">
  <figure class="tutorial-figure">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/visualize-averages-menu.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the Visualize Averages menu screenshot at full size">
      <img src="{{ '/assets/images/tutorial/visualize-averages-menu.png' | relative_url }}" alt="Brainstorm process menu with MIA Visualize Averages selected" loading="lazy">
    </a>
    <figcaption>Select MIA: Visualize Averages.</figcaption>
  </figure>
  <figure class="tutorial-figure tutorial-figure--compact">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/visualize-averages-subject.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the ROI subject selection screenshot at full size">
      <img src="{{ '/assets/images/tutorial/visualize-averages-subject.png' | relative_url }}" alt="ROI subject selection in the Visualize Averages process" loading="lazy">
    </a>
    <figcaption>Choose the subject containing the ROI files.</figcaption>
  </figure>
  <figure class="tutorial-figure tutorial-figure--compact">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/visualize-averages-conditions.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the condition selection screenshot at full size">
      <img src="{{ '/assets/images/tutorial/visualize-averages-conditions.png' | relative_url }}" alt="Condition selection dialog for MIA ROI visualization" loading="lazy">
    </a>
    <figcaption>Select one or more available ROI conditions.</figcaption>
  </figure>
</div>

The process has one user-facing input:

1. **ROI subject:** Subject from the current Brainstorm protocol whose ROI files
   should be read from `data/<SelectedSubject>/ROIS`.

After you click **Run**, the process:

1. Reads the current protocol with `bst_get('ProtocolInfo')`.
2. Reads the selected ROI subject.
3. Scans `data/<SelectedSubject>/ROIS`.
4. Finds and sorts all files matching `*_rois.mat`.
5. Removes `_rois.mat` from each filename to create the displayed condition name.
6. Opens a checkbox dialog for selecting one or more conditions.
7. Loads the `rois` variable from each selected file.
8. Calls `mia_group_gui(...)` with the selected ROI structures.

For example:

```text
Ap_bipolar_2_rois.mat → Ap_bipolar_2
```

### Individual-condition visualization

The interface opens one tab for each selected condition. Each row is an ROI.
The columns report the number of patients (`NPt`), number of contacts (`Nc`),
correlation across patients (`R_p`), and correlation across contacts (`R_c`).

Select one or more ROI rows and then:

- Use **ROI panel** to open the detailed ROI view.
- Use **ROIs Gd Ave** to display average ROI activity.
- Use **Close figs** to close figures opened from this window.

<div class="tutorial-result-with-legend" markdown="0">
  <figure class="tutorial-figure">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/individual-condition-results.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the individual-condition results screenshot at full size">
      <img src="{{ '/assets/images/tutorial/individual-condition-results.png' | relative_url }}" alt="MIA individual-condition ROI results table and plots" loading="lazy">
    </a>
    <figcaption>Individual-condition ROI results.</figcaption>
  </figure>
  <figure class="tutorial-figure tutorial-figure--legend">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/results-table-legend.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the results-table legend at full size">
      <img src="{{ '/assets/images/tutorial/results-table-legend.png' | relative_url }}" alt="Legend explaining the MIA results table columns" loading="lazy">
    </a>
    <figcaption>Results-table column legend.</figcaption>
  </figure>
</div>

<figure class="tutorial-figure tutorial-figure--wide" markdown="0">
  <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/individual-roi-figure.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the detailed individual ROI figure at full size">
    <img src="{{ '/assets/images/tutorial/individual-roi-figure.png' | relative_url }}" alt="Detailed MIA individual ROI time-series and heatmap figure" loading="lazy">
  </a>
  <figcaption>Detailed ROI activity showing z-scored time series and a heatmap.</figcaption>
</figure>

### Group-comparison visualization

When multiple conditions are selected, the interface adds a **Group** tab. It
compares the selected conditions using ROIs present across conditions. Select an
ROI and click **Group ROI Timeseries** to plot the conditions together.

<div class="tutorial-result-with-legend" markdown="0">
  <figure class="tutorial-figure">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/group-comparison-results.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the group-comparison results screenshot at full size">
      <img src="{{ '/assets/images/tutorial/group-comparison-results.png' | relative_url }}" alt="MIA group-comparison ROI results table and plots" loading="lazy">
    </a>
    <figcaption>Group comparison for the selected conditions.</figcaption>
  </figure>
  <figure class="tutorial-figure tutorial-figure--legend">
    <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/results-table-legend.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the results-table legend at full size">
      <img src="{{ '/assets/images/tutorial/results-table-legend.png' | relative_url }}" alt="Legend explaining the MIA results table columns" loading="lazy">
    </a>
    <figcaption>Results-table column legend.</figcaption>
  </figure>
</div>

The generated line plots show z-scored activity over time. The heatmap
summarizes activity across contacts or subjects, and its color bar indicates
z-score values.

<figure class="tutorial-figure tutorial-figure--wide" markdown="0">
  <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/group-roi-timeseries.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the group ROI time-series figure at full size">
    <img src="{{ '/assets/images/tutorial/group-roi-timeseries.png' | relative_url }}" alt="MIA group ROI time-series comparison figure" loading="lazy">
  </a>
  <figcaption>Time-series comparison for a selected ROI across conditions.</figcaption>
</figure>

### Final visualization call

When one condition is selected, the process calls:

```matlab
mia_group_gui(selectedRois{1}, selectedConditionNames{1});
```

Equivalent example:

```matlab
Ap_bipolar_2_file = load('data/COREG/ROIS/Ap_bipolar_2_rois.mat', 'rois');
mia_group_gui(Ap_bipolar_2_file.rois, 'Ap_bipolar_2');
```

When multiple conditions are selected, the process calls:

```matlab
mia_group_gui(selectedRois{:}, strjoin(selectedConditionNames, '-'));
```

Equivalent example:

```matlab
cond_1_file = load('data/COREG/ROIS/cond_1_rois.mat', 'rois');
cond_2_file = load('data/COREG/ROIS/cond_2_rois.mat', 'rois');
mia_group_gui(cond_1_file.rois, cond_2_file.rois, 'cond_1-cond_2');
```

The process uses three helper functions:

- `get_protocol_subject_options()` populates the ROI-subject list from the current protocol.
- `get_subject_roi_files(roiDir)` finds, sorts, and names available `*_rois.mat` files.
- `select_roi_conditions(conditionNames, subjectName)` opens the condition-selection dialog.

## 5. Run statistics {#run-statistics}

This process calculates a statistical contrast between two conditions.

1. Drag and drop exactly two processed conditions into the process pipeline.
2. Select the contrast process as shown below.
3. Run the process to load both conditions, calculate the contrast, and create
   statistical results for visualization and further analysis.

<figure class="tutorial-figure tutorial-figure--menu-only" markdown="0">
  <a class="tutorial-image-link" href="{{ '/assets/images/tutorial/contrast-conditions-menu.png' | relative_url }}" target="_blank" rel="noopener" aria-label="Open the condition-contrast menu screenshot at full size">
    <img src="{{ '/assets/images/tutorial/contrast-conditions-menu.png' | relative_url }}" alt="Brainstorm process menu for contrasting two MIA conditions" loading="lazy">
  </a>
  <figcaption>Select the MIA condition-contrast process after adding two conditions.</figcaption>
</figure>

The output includes statistical measures such as p-values and effect sizes.
