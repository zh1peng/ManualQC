# Compare raters

Start from **independent logs of the same pre-QC recordings**. Do not point replay at one rater's cleaned file: after epoch removal, epoch 5 can refer to a different trial.

## Reproduce the sample comparison

1. In MATLAB run `ratertool`. Click **Load Rater Files** and select `rater_czr.xlsx`, `rater_hlz.xlsx` and `rater_pcj.csv` from [rater_files](https://github.com/zh1peng/ManualQC/tree/v1.3.0/rater_files).
2. Set the data root to that same folder. The three sheets cover more recordings than the two example EEG files distributed in the repository. Only matching recordings can be replayed.
3. Click **Compute Agreement**. Select a row under **Top Disagreements** or use the replay dataset selector. Inspect **Pairwise Details** to find the raters and decision type behind a low score.

![RaterTool displaying the three example rater files, agreement summary and replay controls](/figures/raters.png)
<p class="caption"><strong>Three levels of inspection.</strong> Inputs identify the raters; Summary compares their decisions; Replay connects a selected dataset and epoch to individual rater decisions.</p>

## Replay a difference

Select `sub-3004_ses-post_task-mid_run-1_eeg_prep`, choose raters, then **Load EEG**. Use **Open Viewer** to view the traces and navigate through epochs. Check the per-rater table for the current epoch. Use **Channel Inspect** or **IC Inspect** when the disagreement concerns a sensor or a component. The example is a comparison, not an adjudicated reference.

## Use your own logs

Keep the exported headers: `dataset`, `Rejected trials`, `Interpolated Channels`, `Removed ICs`, `Comments`, `Rating`, `Quality Score Before`, `Quality Score After`. Keep dataset identifiers consistent between raters. For component comparisons, use the **same ICA decomposition**, not just the same number of components. Use **Export** after selecting an export directory to retain the computed results.
