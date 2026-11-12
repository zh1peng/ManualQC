# Load your first dataset

Use the small `sub-165` example for a first session. The aim here is to load exactly one recording without changing the original.

## Prepare MATLAB

1. Download and extract [ManualQC v1.3.0](https://github.com/zh1peng/ManualQC/archive/refs/tags/v1.3.0.zip). Keep the included `rater_files` directory.
2. Start [EEGLAB](https://eeglab.org/) in MATLAB so its functions are on the path. Change MATLAB's current folder to the extracted repository.
3. Run the commands below. Add the toolbox folder itself, not the repository and all its test subfolders.

```matlab
addpath(fullfile(pwd,'manualqc1.1'))
mkdir('qc_output')
manualqc
```

Choose **Continue** in the startup dialog. Alternatively, install the `manualqc1.1` folder under EEGLAB's `plugins` directory, restart EEGLAB, load a dataset and open **Tools → ManualQC**.

## Find one recording

Set the search directory to `rater_files`. In the regular-expression field enter:

```text
^sub-165_task-mid_run-01_eeg_prep\.set$
```

Click **Search**. Compare the filename in the results window with the expression above. Leave the file index at **1** and click **Load**. For a larger batch use a broader expression, such as `\.set$`, and review the match list first. Keep the output folder outside the search tree so later searches do not include processed copies.

![ManualQC workbench after loading the bundled sub-165 dataset](/figures/workbench.png)
<p class="caption"><strong>Read the workbench from top to bottom.</strong> Search and load at the top; inspect epochs, channels and ICs in the middle; check the dataset and your recorded decisions in the information panel.</p>

**Checkpoint:** the window title identifies the dataset. For this sample, the information panel reports **327 trials, 59 channels and 52 ICs**. The initial quality score is a signal-scale summary, not a pass/fail threshold.
