# Save and verify

## Record the decision

1. Enter a short observation, for example “Persistent noise at one electrode across epochs”, and click **Add**. Check that the comment appears in the information panel.
2. Choose a dataset rating. **Usable** sets the prefix to `qced_`, **Recheck** to `recheck_`, and **Not usable** to `bad_`. Edit the prefix *after* selecting the rating if your study uses another convention.
3. Set the output directory to the existing `qc_output` folder. Verify the epoch count, channel labels, IC numbers and destination. Click **Save**.

## Check the files, not just the screen

For the sample rated **Usable**, open the result from the output directory:

```matlab
out = pop_loadset('filename','qced_sub-165_task-mid_run-01_eeg_prep.set', ...
                  'filepath',fullfile(pwd,'qc_output'));
disp(out.etc.manualqc)
```

Compare the number of saved epochs with the input count minus your confirmed rejections. Interpolated channels **remain** in the montage. Inspect their waveforms, not just the channel count. Keep any companion `.fdt` alongside its `.set`.

| Record | What it is for |
| --- | --- |
| `EEG.etc.manualqc` in the saved dataset | Inspect the decisions that apply to this file. Distinguish `rejected_epochs_current` from `rejected_trials_id`; check `rejected_id_space` before joining to behavioral data. |
| `QC_log` in the MATLAB base workspace | Review the session's rows before closing MATLAB. |
| `qc_info_bak_on_HH.MM.csv` / `final_qc_info_on_HH.MM.csv` | Backup during review / final log when the last matched file is saved. Keep one independent log per rater. |

::: warning Previously saved datasets
Affected v1.2.0 outputs could list channels as interpolated without changing the samples. Installing v1.3.0 does not repair those files. Reprocess from the original pre-QC dataset and verify the saved channel signals.
:::
