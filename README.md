## Manual QC
<a href="https://imgur.com/XYa5qyJ"><img src="https://i.imgur.com/XYa5qyJ.png" title="source: imgur.com" /></a>

#### Current Version: v1.1.6
#### This GUI was developed using Matlab 2016a.
If you use this tool in your paper, please cite it as follows:

"Additionally, bad epochs, channels, and independent components (ICs) were manually checked and excluded using ManualQC (https://github.com/zh1peng/ManualQC)."

### Brief Introduction
While numerous algorithms have been developed for automatically detecting and removing EEG artifacts, manual intervention remains essential in many cases. In our lab, all EEG datasets undergo rigorous manual quality control (QC). When I began performing QC on EEG data back in 2017, the process involved navigating multiple menus to load datasets, remove bad epochs, interpolate bad channels, remove independent components (ICs), and save datasets. Additionally, I manually recorded this information and added comments as needed. Recognizing the inefficiency of this workflow and the lack of a streamlined solution within EEGLAB, I integrated QC-related functions from EEGLAB into a single graphical user interface (GUI). The in-house version of this GUI, available (here) [https://github.com/zh1peng/EEGQC_GUI], has been utilized in our lab for over a year and has significantly improved the efficiency of our QC process.

Believing this tool could benefit others performing manual QC on EEG data, I reprogrammed the QC GUI with the following improvements:

1. Advanced GUI-building code, consolidating all functionalities into a single file.
2. An improved interface designed to resemble EEGLAB for familiarity and ease of use.
3. Customized EEGLAB functions to streamline the QC process.

### Release Notes:
- **2017-10-09**: ManualQC v1.0 Released.
- **2017-10-10**: 
  - Minor bug fixed.
  - Typo corrected.
- **2017-10-24**: ManualQC v1.1:
  - Added a new button allowing users to remove ICs first.
  - Integrated as an EEGLAB plugin.
  - Fixed the save bug.
  - Added functionality to calculate the number of trials marked as bad.
- **2017-10-28**: ManualQC v1.1.1:
  - Fixed `xlswrite` error on Linux/Mac.
  - Added a button to plot IC activations, providing information on which ICs to remove.
  - Improved the display of search results.
- **2017-11-11**: ManualQC v1.1.2:
  - Added a version check during GUI initiation.
- **2017-11-13**:
  - Added `cell2csv` functionality.
  - Fixed a save error.
- **2017-11-27**: ManualQC v1.1.3:
  - Fixed a minor bug where functions from EEGLAB could not be found.
  - Disabled the 'Load' button after clicking.
  - Disabled the 'Remove IC first' button after saving.
- **2017-12-11**:
  - Fixed a minor bug in GUI launch (version check and EEGLAB path warning).
  - Changed the order of IC removal to remove ICs first when saving datasets.
  - Fixed an error when loading without EEGLAB in the path.
- **2018-01-16**: ManualQC v1.1.4:
  - Changed EEGLAB options to save datasets as a single file instead of two.  
    *(Note: If your lab uses the two-file setting, remove this line: `pop_editoptions('option_savetwofiles', 0);`)*
- **2018-04-20**: ManualQC v1.1.5:
  - Improved dataset handling post-save.
  - Displayed number of ICs changed to a default of 35.
- **2024-02-21**: ManualQC v1.1.6:
  - Added functionality to load the log file if saved with the same name as the dataset.
  - Updated QC information to be dumped into the log file if it exists.
- **2025-01-09**: ManualQC v1.1.7:
  - Make loading log file function more general.
  - Use fixed output path
  - add re-check button on the QC rating
  - automatically add prefix when QC rating is selected
  - give warning if QC rating is not selected
  - proofread documentation using LLM
  - include a Chinese documentation

## Brief Manual

### Step 0:
#### Use it separately from EEGLAB:
1. Add EEGLAB to the MATLAB path.
2. Add ManualQC to the MATLAB path.
3. Run `ManualQC`.

#### Use it as an EEGLAB plugin:
1. Download it from the plugin manager of EEGLAB [if available], or download the `ManualQC1.1` folder into the `plugins` folder in EEGLAB.
2. Load any dataset, and the tool entry will appear in the "Tools" menu.

---

### Step 1: Search datasets using a regular expression
1. Enter a regular expression. An example is shown in the info panel. Type `doc regexp` in MATLAB for more examples.  
   - *(Our lab uses `^Final\w*.set` since 'Final' is added as a prefix to pre-processed data.)*
2. Paste or select the data directory.
3. Click **Search**.

If any file matching the regular expression is found in the data directory:
- The **Load** button will be enabled.
- The index of the file to load will be updated to `1`.
- The total number of files found will be displayed.

---

### Step 2: Load a dataset
**This only works when loading a `.set` file and the dataset index is correct.**

If the dataset is loaded successfully:
- Basic information about the dataset will be displayed.  
  *(Note: Data quality is calculated as the initial scale when using the epoch scrolling function. This is a useful indicator of data quality.)*
- The **Epochs/Channels/ICs** button will be enabled.

---

### Step 3: Check epochs, channels, and ICs
#### Exploring Epochs
Inspect epochs and mark the bad ones:
- **Mark**: Mark selected epochs as bad.  
  Bad epochs will be listed in the information panel and removed upon saving the dataset.

#### Select Channels (Ctrl/Shift for multiple selections)
- **Clear**: Clear previously marked channels.
- **Mark**: Mark selected channels as bad channels.
- **Property**: Plot the properties of selected channels.  
  Bad channels will be listed in the information panel and interpolated upon saving the dataset.

#### Select ICs
- Click the label above the topoplots.
- Mark ICs as **Accept** or **Reject**:  
  - Rejected ICs are labeled in red.
  - Accepted ICs are labeled in green.
- **Selected ICs**: Update the list of selected ICs for testing removal.
- **Test Removal**: Compare data before and after removing selected ICs.
- **Test Averaged Removal**: Compare averaged data before and after removing selected ICs.
- **Clear All Selections**: Clear IC selections and reopen this window.
- **Ok**: Confirm IC selections for removal.  
  Selected ICs will be listed in the information panel and removed upon saving the dataset.

#### Remove ICs First
In cases where removing bad ICs first could retain more trials, use the **Remove Bad ICs First** button before proceeding with the rest of the QC.

---

### Step 4: Add user comments and rate the dataset
Add comments and rate the dataset, such as:
- "A lot of alpha activity."
- "Significant movement or muscle/EMG artifacts."
- "Over 20% of epochs removed -> mark as 'caution' for 'data usable?'"
- "Over 40-50% of epochs removed -> mark as 'bad' for 'data not usable?'"

Click **Add** to update comments.

---

### Step 5: Save the manually QCed dataset
- QC information will be updated in the `QC_log` within the workspace.
- Temporary QC information will be saved as `qc_info_bak_on_HH.MM` in the save path.

---

### Step 6: Save the `QC_log`
Save the final QC log manually by copying it or using `xlswrite` (or similar functions).  
The final QC information will be saved upon completing the last file.

---

## Tips on QC
- Regularly review the QC process to ensure consistency.
- Document any anomalies or deviations from standard procedures.
- Ensure all saved datasets and logs are securely backed up.

