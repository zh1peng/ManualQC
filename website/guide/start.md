# Load your first dataset

Use the small `sub-165` example for a first session. The aim here is to load exactly one recording without changing the original.

## Prepare MATLAB

1. Download and extract [current ManualQC source](https://github.com/zh1peng/ManualQC/archive/refs/heads/master.zip). Keep the included `rater_files` directory.
2. Start [EEGLAB](https://eeglab.org/) in MATLAB so its functions are on the path. Change MATLAB's current folder to the extracted repository.
3. Run the commands below. Add the toolbox folder itself, not the repository and all its test subfolders.

```matlab
addpath(fullfile(pwd,'manualqc'))
mkdir('qc_output')
manualqc
```

Choose **Continue** in the startup dialog. Alternatively, install the `manualqc` folder under EEGLAB's `plugins` directory, restart EEGLAB, load a dataset and open **Tools → ManualQC**.

On an existing installation, remove the old toolbox directory from your MATLAB path or EEGLAB plugins before adding the new one. Run `which manualqc -all` to confirm MATLAB resolves the intended copy.

## Find one recording

Set the search directory to `rater_files`. In the regular-expression field enter:

```text
^sub-165_task-mid_run-01_eeg_prep\.set$
```

Click **Search**. Compare the filename in the results window with the expression above. Leave the file index at **1** and click **Load**. For a larger batch use a broader expression, such as `\.set$`, and review the match list first. Keep the output folder outside the search tree so later searches do not include processed copies.

![ManualQC workbench after loading the bundled sub-165 dataset](/figures/workbench.png)
<p class="caption"><strong>Read the workbench from top to bottom.</strong> Search and load at the top; inspect epochs, channels and ICs in the middle; check the dataset and your recorded decisions in the information panel.</p>

**Checkpoint:** the window title identifies the dataset. For this sample, the information panel reports **327 trials, 59 channels and 52 ICs**. The workbench displays **Data Quality: 33 (Low quality, >=29)**.

## Filename patterns

Search checks **filenames**, not folder paths, including files in subfolders. Type a pattern without quotes. ManualQC uses MATLAB's case-insensitive [`regexpi`](https://www.mathworks.com/help/matlab/ref/regexpi.html), not shell wildcards: use `\.set$`, not `*.set`.

| To find | Enter | Matches in the bundled folder |
| --- | --- | --- |
| Every EEGLAB dataset | `\.set$` | Both recordings |
| Only participant 165 | `^sub-165_.*\.set$` | One; not participant 1650 |
| Post-session recordings | `_ses-post_.*\.set$` | The sub-3004 recording |
| Run 1, written as 1 or 01 | `_run-0?1_eeg_prep\.set$` | Both recordings, not run 11 |

Read `^sub-165_.*\.set$` from left to right: `^` anchors the start; `sub-165_` is literal; `.*` allows any intervening text; `\.` matches a literal dot; `$` anchors the end. In the run pattern, `0?` means an optional zero. Always check the results before loading a batch.

## Data Quality

The score measures typical amplitude variation. For recordings with the same units, reference and preprocessing, lower values generally indicate better quality. The current calculation is **not** limited to the first 5,000 points and does **not** process every point of a long recording:

1. Concatenate epochs in time order. Sample up to 5,000 equally spaced positions from first to last, using the same positions for all channels.
2. Split the sampled sequence into five equal-length windows; omit any trailing remainder. Compute each channel's sample standard deviation per window, then take its median across windows. With fewer than five positions, use one standard deviation per channel.
3. Take a 5% trimmed mean across channels and multiply by three. The result has the same units as the input amplitudes; it is not a percentage.

| Displayed integer | Quality band |
| --- | --- |
| 18 or less | High quality |
| 19 to 28 | Moderate quality |
| 29 or more | Low quality |

Round first, then read the band: 28.4 displays as **28 (Moderate quality)**; 28.6 as **29 (Low quality)**. Logs retain decimal scores for before/after comparison and ICC. A brief artifact can be missed by sampling or suppressed by the median; a flat signal can score low. Inspect the traces before choosing **Usable**, **Recheck** or **Not usable**.
