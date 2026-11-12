---
title: Field manual
outline: false
---
<p class="edition">EEGLAB FIELD MANUAL · v1.3.0</p>

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

**Working with a second reviewer?** Review the same input independently, then use [RaterTool](/guide/raters) to locate disagreements and inspect the signal behind them.
