# Review epochs

A mark identifies a **whole epoch**, not just the channel or the point you clicked. Open **Epochs** and use the viewer's arrows to move through the recording. Click inside an epoch to toggle its highlight.

![Channel traces with the third epoch highlighted for demonstration](/figures/epochs.png)
<p class="caption"><strong>Read across channels.</strong> The shaded vertical band shows the selected interval across the montage. Epoch 3 was selected to demonstrate the control, not to label the sample as bad.</p>

## Try a reversible edit

Walk through this example on the sample file before adopting a lab rejection protocol:

| Starting selection | In the epoch viewer | Confirmed selection when reopened |
| --- | --- | --- |
| Empty | Click 1, 3, 5; **Mark** | 1, 3, 5 |
| 1, 3, 5 | Click 2, 4, 6; **Mark** | 1, 2, 3, 4, 5, 6 |
| 1 through 6 | Click 3 again; **Mark** | 1, 2, 4, 5, 6 |
| 1, 2, 4, 5, 6 | **Clear**, then **Cancel** | 1, 2, 4, 5, 6 |
| 1, 2, 4, 5, 6 | **Clear**, then **Mark** | Empty |

**Mark** replaces the confirmed list with the complete highlighted selection. **Cancel** discards only edits made since opening the viewer. Neither writes a dataset. Check the **Bad epochs** count in the workbench before continuing; marked epochs are removed on [Save](/guide/save).
