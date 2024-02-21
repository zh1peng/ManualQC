## Manual QC
<a href="https://imgur.com/XYa5qyJ"><img src="https://i.imgur.com/XYa5qyJ.png" title="source: imgur.com" /></a>

#### Current Version: v1.1.6
#### This GUI was developed using Matlab 2016a.
Please cite this tool if you use it in your paper.

### Brief Introduction
While more algorithms have been developed to automatically detect and remove EEG artifacts, manual intervention is often still necessary. In our lab, all EEG datasets undergo manual QC. When I began performing QC on EEG data two years ago, I had to navigate through multiple menus to load datasets, remove bad epochs, interpolate bad channels, remove ICs, and save datasets. Then, I manually recorded this information and added comments where necessary. Finding no efficient solution in EEGLAB, I incorporated QC-related functions from EEGLAB into a single GUI (in-house version) [https://github.com/zh1peng/EEGQC_GUI]. This GUI has been used in our lab for a year and has proven effective.

Believing this could benefit others needing to perform manual QC on EEG data, I re-programmed the QC GUI with:

1. Advanced GUI-building codes [all functionalities in one file].
2. A better interface that is similar to EEGLAB.
3. Customized EEGLAB functions to facilitate the QC process.
4. A fix for a minor bug present in the in-house version.

### Release Notes:
- **2017-10-09**: ManualQC v1.0 Released.
- **2017-10-10**: Minor bug fixed/typo corrected.
- **2017-10-24**: ManualQC v1.1:
  - Added a new button allowing users to remove ICs first.
  - Added as an eegplugin.
  - Fixed the save bug.
  - Now calculates the number of trials marked as bad.
- **2017-10-28**: ManualQC v1.1.1:
  - Fixed `xlswrite` error on Linux/Mac.
  - Added a button to plot IC activations, giving info on which ICs should be removed.
  - Improved display of search results.
- **2017-11-11**: ManualQC v1.1.2:
  - Added version check at GUI initiation.
- **2017-11-13**:
  - Added `cell2csv`.
  - Fixed a save error.
- **2017-11-27**: ManualQC v1.1.3:
  - Fixed a minor bug; couldn't find functions from EEGLAB.
  - Disabled 'Load' button after clicking.
  - Disabled 'Remove IC first' button after clicking the save button.
- **2017-12-11**:
  - Fixed a minor bug when launching the GUI (version check and EEGLAB path warning).
  - Changed the order of IC removal. Now removes IC first if any when saving the datasets.
  - Fixed error with load without EEGLAB in path.
- **2018-01-16**: ManualQC v1.1.4:
  - Changed EEGLAB options to save as one file instead of two. If your lab uses the 2 files setting, remove this: `pop_editoptions('option_savetwofiles', 0);`
- **2018-04-20**: ManualQC v1.1.5:
  - Improved a few things after saving the dataset.
  - Changed the displayed number of ICs to show as 35.
- **2024-02-21**: ManualQC v1.1.6:
  - Loads the log file if it is saved using the same name as the dataset.
  - Dumps QC information to the log file if it exists.

## Brief Manual
### Step 0:
Use it separately from EEGLAB:
1. Add EEGLAB to the Matlab path.
2. Add ManualQC to the Matlab path.
3. Run ManualQC.

Use it as an EEGLAB plugin:
1. Download it from the plugin manager of EEGLAB [if available], or download the ManualQC1.1 folder to the plugins folder in EEGLAB.
2. Load any dataset, and the tool entry will appear in the tools menu.

### Step 1: Search datasets using a regular expression.
1. Enter a regular expression. An example is shown in the info panel. Type `doc regexp` to see more examples. [Our lab uses `^Final\w*.set` since 'Final' is added as a prefix to pre-processed data.]
2. Paste or select the data directory.
3. Click search.

If any file matching the regular expression is found in the data directory:
- The Load button will be enabled.
- The index of the file to load will be updated to 1.
- The file number will be displayed.

### Step 2: Load a dataset.
**This only works when you are trying to load a .set file, and the dataset index is correct.**

If the dataset is loaded correctly:
- Basic information about the dataset will be displayed. (Note: Data quality is calculated as the initial scale when using the epoch scrolling function. To some extent, this is a good index for data quality.)
- The Epochs/Channels/ICs button will be enabled.

### Step 3: Check epochs, channels, and ICs.
#### Exploring Epochs
Inspect epochs and select the bad ones in the usual way.
- Mark: Mark selected epochs as bad epochs. The bad epochs will be displayed in the information panel and removed when you save the dataset.

#### Select Channels (ctrl/shift for multiple selections)
- Clear: Clear previously marked channels.
- Mark: Mark the selected channels as bad channels.
- Property: Plot selected channels' properties. The bad channels will be displayed in the information panel and interpolated by default when you save the dataset.

#### Select ICs
- Click the label above the topoplots.
- Mark the IC as Accept or Reject. Then the label of rejected ICs will be in red, and accepted ICs will be in green.
- Selected ICs: Update selected ICs. This is for testing IC removal.
- Test Removal: Compare data before and after the removal of selected ICs.
- Test Averaged Removal: Compare averaged data before and after the removal of selected ICs.
- Clear All Selections: This will clear ICs and reopen this window.
- Ok: Confirm the selection of ICs to be removed. The selected ICs will be displayed in the information panel and removed when you save the dataset.

#### Remove ICs First
Some trials marked as bad could be kept if some bad ICs are removed first. The "Remove Bad ICs First" button is designed for situations where you want to remove some bad ICs first and then perform the rest of the QC.

### Step 4: Add user’s comments and rate the dataset.
Make comments and rate the dataset, such as:
- A lot of alpha activity.
- A lot of movement or muscle/EMG artifacts.
- Over 20% of epochs removed -> mark as 'caution' for 'data usable?'
- Over 40-50% of epochs removed -> mark as 'bad' for 'data usable?'

Click "Add" to update comments.

### Step 5: Save the manually QCed dataset.
- QC info will be updated in the QC_log in the workspace.
- Temporary QC info will be saved as qc_info_bak_on_HH.MM in the save path.

### Step 6: Save the QC_log by copying or using xlswrite, etc.
The final QC info will be saved when you finish the last file.

## Tips on QC
