---
title: ManualQC Documentation
titleTemplate: false
outline: false
---
<p class="edition">ManualQC for EEGLAB · v1.3.0</p>

# ManualQC

<p class="lead">Review an EEG recording one decision at a time. Follow a sample dataset from the first epoch plot to a saved, auditable QC record.</p>

**[Start with the sample dataset →](/guide/start)** · [Compare existing rater logs](/guide/raters)

![EEGLAB channel traces with a single epoch highlighted in the ManualQC viewer](/figures/epochs.png)
<p class="caption"><strong>Fig. 01 · An epoch under review.</strong> Each row is a channel. The shaded interval is a reviewer's selection, not an automatic artifact prediction.</p>

## A session in four steps

| Step | Decision | What you should see |
| --- | --- | --- |
| [01 · Load](/guide/start) | Which input file am I reviewing? | Filename in the title; dimensions in the information panel |
| [02 · Mark epochs](/guide/epochs) | Which time segments should be excluded? | The same highlights when you reopen the plot |
| [03 · Channels and ICs](/guide/channels-ics) | Does the problem follow a sensor or a component? | Separate lists for interpolation and removal |
| [04 · Save](/guide/save) | Can another person reconstruct the decision? | A new dataset, embedded QC record and log |

## Why record manual EEG quality control decisions?

After automated preprocessing, some artifacts still require judgment. For example, ICLabel estimates how likely an independent component is to reflect brain activity, eye movements or another source. When the classification is uncertain, a reviewer can inspect the component’s scalp map, time course and spectrum before deciding whether to remove it. [Pion-Tonachini et al., 2019](https://doi.org/10.1016/j.neuroimage.2019.05.026)

Those decisions matter when someone asks how many trials entered an analysis. In a review of 132 visual N400 studies, 40.2% did not report how many trials remained after exclusions for artifacts or behavioral errors. ManualQC saves the rejected epochs, interpolated channels, removed components and reviewer comments with each processed dataset. The [QC log](/guide/save) brings those decisions together across recordings. [Šoškić et al., 2022](https://doi.org/10.1007/s11065-021-09513-4)

Two reviewers can reject the same number of epochs and still disagree about which ones to discard. For rater training, review the same recording independently, then use [RaterTool](/guide/raters) to display both sets of markings on the pre-QC waveforms. A disputed epoch gives the team a concrete example to discuss when applying its artifact criteria. [Shirk et al., 2017](https://doi.org/10.3389/fnins.2017.00322) · [Boudewyn et al., 2023](https://doi.org/10.1111/psyp.14365)
