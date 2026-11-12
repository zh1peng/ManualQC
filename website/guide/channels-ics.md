# Inspect channels and ICs

A bad channel and a bad independent component are different decisions. Interpolating a channel reconstructs its signal from neighboring sensors; removing an IC subtracts a component's contribution across sensors.

## Inspect a channel

1. Open **Channels**. Select a channel label; use Ctrl or Shift for a multiple selection.
2. Use **Property** to examine the selected channel. Compare it with neighboring channels and check whether the problem persists across epochs.
3. Choose **Mark** and confirm the labels in **Bad Channels**. To remove the selection, use **Clear**. At save time ManualQC interpolates the selected channels together using spherical interpolation. This requires usable electrode coordinates.

## Inspect the decomposition

Open **ICs** on a dataset with ICA weights. There are at most **35 components per window**: a rank-20 decomposition should show 20 components even on a larger montage.

![Numbered component scalp maps in the ManualQC inspection window](/figures/components.png)
<p class="caption"><strong>Start with the numbered button above a map.</strong> It opens the component properties. A scalp map alone is not evidence that an IC should be removed.</p>

Review the properties, set **Accept** or **Reject**, then update **Selected ICs**. Use **Test Removal** or **Test Averaged Removal** to compare the signal before and after the proposed subtraction. Click **Ok** and check the IC list in the workbench. Without an ICA decomposition, skip this step.

::: warning Order matters
**Remove Bad ICs First** changes the in-memory data immediately and clears current epoch and channel marks. Use it before those reviews, then inspect the changed signal again. For ordinary deferred removal, keep the confirmed IC list and proceed to Save.
:::
