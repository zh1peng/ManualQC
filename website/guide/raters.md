# Compare raters

Start from **independent logs of the same pre-QC recordings**. Do not point replay at one rater's cleaned file: after epoch removal, epoch 5 can refer to a different trial.

## Reproduce the sample comparison

1. In MATLAB run `ratertool`. Click **Load Rater Files** and select `rater_czr.xlsx`, `rater_hlz.xlsx` and `rater_pcj.csv` from [rater_files](https://github.com/zh1peng/ManualQC/tree/v1.3.0/rater_files).
2. Set the data root to that same folder. The three sheets cover more recordings than the two example EEG files distributed in the repository. Only matching recordings can be replayed.
3. Click **Compute Agreement**. Select a row under **Top Disagreements** or use the replay dataset selector. Inspect **Pairwise Details** to find the raters and decision type behind a low score.

![RaterTool displaying the three example rater files, agreement summary and replay controls](/figures/raters.png)
<p class="caption"><strong>Three levels of inspection.</strong> Inputs identify the raters; Summary compares their decisions; Replay connects a selected dataset and epoch to individual rater decisions.</p>

## Replay agreement and disagreement

Select `sub-165_task-mid_run-01_eeg_prep`, keep all three raters selected, and click **Load EEG**. **Open Viewer** opens the traces. In the position box between the arrows, type **175** and press Enter. The screen now shows epochs 175 to 179. Read the epoch numbers along the top, not the millisecond ticks below the traces.

![Replay of epochs 175–179 with all three rater bands on epochs 177 and 178](/figures/replay.png)
<p class="caption"><strong>Compare the five epochs.</strong> All three raters kept epoch 175 and rejected 177 and 178. Only <code>rater_czr</code> (red) and <code>rater_pcj</code> (blue) rejected 176. Only <code>rater_pcj</code> rejected 179. Green identifies <code>rater_hlz</code>.</p>

Use **Channel Inspect** or **IC Inspect** if the difference concerns a sensor or component. The overlay shows where judgments differ; it does not decide which rater is correct.

## Use your own logs

Keep the exported headers: `dataset`, `Rejected trials`, `Interpolated Channels`, `Removed ICs`, `Comments`, `Rating`, `Quality Score Before`, `Quality Score After`. Keep dataset identifiers consistent between raters. For component comparisons, use the **same ICA decomposition**, not just the same number of components. Use **Export** after selecting an export directory to retain the computed results.
