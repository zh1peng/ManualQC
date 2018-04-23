## Manual QC
<a href="https://imgur.com/XYa5qyJ"><img src="https://i.imgur.com/XYa5qyJ.png" title="source: imgur.com" /></a>

#### Current version: v1.1.5
#### This GUI is developed using Matlab2016a.
Please cite this tools if you use it for your paper


### Breif Introduction
Currently, more algorithms have been developed to automatically detect and remove EEG artefacts, but manual inventions are still needed. At least, in our lab, all EEG datasets have been QCed manually. When I started running QC on EEG data two years ago, I had to click the menu multiple times to load dataset, remove bad epoches, interpolate bad channels, remove ICs and save dataset. Then recorded those info manually and added comments if necessary. I couldn’t find an efficient way to do that from eeglab, so I incorporated QC related functions from eeglab and assembled them into one GUI. (in-house version) [https://github.com/zh1peng/EEGQC_GUI]. This GUI have been used in [our lab](http://www.whelanlabtcd.org/) for one year and it worked well.

Realized that this could be useful by others who need to do manual QC on eegdata. I re-programmed it QC GUI with

1.Advanced GUI-building codes [all stuffs in one file].

2.Better interface that is similar to eeglab.

3.Customised eeglab functions to facilitate QC process.

4.A tiny bug appears in in-house version fixed


### Release notes:
2017-10-09 ManualQC v1.0 Released

2017-10-10 Tiny bug fixed/Typo corrected

2017-10-24 ManualQC v1.1:
* mainly added in a new button which allows users to do ICs removal first
* added as eegplugin
* fixed the save bug
* calculate how many trials are marked as bad trials

2017-10-28 ManualQC v1.1.1:
*  fixed xlswrite on linux/mac error
*  added button to plot ICs activition giving info on the ICs should be removed or not.
 *  display search results.


2017-11-11 ManualQC v1.1.2:

* check version when initiate the gui

2017-11-13
* add cell2csv  11.13
* fix save error (Orz)

2017-11-27 ManualQC v1.1.3:
 * tiny bug fixed; couldn't find functions from eeglab
 * disable 'Load' button after click
 * disable 'remove IC first' button after click save button

2017-12-11
* tiny bug when launching the GUI (version check and eeglab path warning)
* change the order of IC remove. remove IC first if any when saving the datasets
* fix error with load without eeglab in path.

2018-01-16 ManualQC v1.1.4:
* changing eeglab options to save as 1 file instead of two.
If your lab is using 2 files setting, just remove this:
` pop_editoptions( 'option_savetwofiles', 0);`

2018-04-20 ManualQC v.1.1.5 

* improve a few things after saving dateset
* change ICs number to show as 35

## Breif Manual
### Step0.
Use it seperately from eeglab:

1. Add eeglab in Matlab path
2. Add manualqc in Matlab path
3. Run manualqc

Use it as eeglab plugin:
1. download it from plugin manager of eeglab [if available]. or downlaod the manualqc1.1 folder to the plugins folder in eeglab
2. load any dataset and the tool entry will be appeared in tools menu.

### Step1. Search datasets using a regular expression.
1. Enter a regular expression. One example is shown in the info panel. Type doc regexp to see more examples.
  [Our lab is using `^Final\w*.set` as 'Final' is added as prefix on pre-processed data]
2. Paste or select data directory.
3. Click search.

If there is any file matching the regular expression in the data directory:
* Load button will be enabled
* Index of file to load will be updated to 1.
* File number will be displayed.

### Step2. Load a dataset.
**This only works when you are trying to load set file and the index of dataset is correct.**

If the dataset is loaded correctly:
* Some basic information of the dataset will be display.
  (Note: Data quality is calculated as the initial scale when epoch scrolling function. To some extent, this is a good index for data quality.)
* Epochs/Channels/ICs button will be enabled.



### Step3. Check epochs, channels and ICs.
#### Exploring epochs
Inspect epochs and select bad ones in a normal way.
Mark: Mark selected epocehs as bad epochs.
The Bad epochs will be displayed in the information panel and removed when you save the dataset.
#### Select channels (ctrl/shift for multiple selections)
* Clear: clear previously marked channels.
* Mark: Mark the selected channels as bad channels.
* Property: Plot selected channels properties.

The Bad channels will be displayed in the information panel and interpolated by default way when you save the dataset.

#### Select ICs.
* Click the label above the topoplots.
* Mark the IC as Accept or Reject.
    Then the label of rejected ICs will be in red and accepted ICs will be in green.
* Selected ICs: update selected ICs. This is for testing IC removal.
* Test removal: Compare data before and after the removal of selected ICs.
* Test removal: Compare averaged data before and after the removal of selected ICs.
* Clear all selections: will clear ICs and reopen this window.
* Ok: Confirm selection of ICs to be removed.

The selected ICs will be displayed in the information panel and removed when you save the dataset.

#### Remove ICs first
Some trials marked as bad could be kept if you have removed some bad ICs. The idea for the button Remove Bad ICs First is designed for the situation that you want to remove some bad ICs first and do the rest QC.

### Step4. Add user’s comments and rate the dataset.
Make comments and rate dataset like:
* a lot of alpha
* a lot of movement or muscle/EMG artefacts
* over 20% of epochs removed -> mark as 'caution' for 'data usable?'
* over 40-50% of epochs removed -> mark as 'bad' for 'data usable?'

Click add to update comments

### Step5. Save manually QCed dataset.
* QC info will be updated in QC_log in workspace
* Temporary QC info will be saved as qc_info_bak_on_HH.MM in the save path.

### Step6.  Save the QC_log by copying or xlswrite etc
Final QC info will be saved, when you finish the last file.

## Tips on QC
