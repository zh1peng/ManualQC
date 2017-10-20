## Manual QC
<a href="https://imgur.com/4izPvsv"><img src="https://i.imgur.com/4izPvsv.png" title="source: imgur.com" /></a>

#### Current version: v1.0



### Breif Introduction
Currently, more algorithms have been developed to automatically detect and remove EEG artefacts, but manual inventions are still needed. At least, in our lab, all EEG datasets have been QCed manually. When I started running QC on EEG data two years ago, I had to click the menu multiple times to load dataset, remove bad epoches, interpolate bad channels, remove ICs and save dataset. Then recorded those info manually and added comments if necessary. I couldn’t find an efficient way to do that from eeglab, so I incorporated QC related functions from eeglab and assembled them into one GUI. (in-house version) [https://github.com/zh1peng/EEGQC_GUI]. This GUI have been used in our lab for one year and it worked well.

Realized that this could be useful by others who need to do manual QC on eegdata. I re-programmed it QC GUI with

1.Advanced GUI-building codes [all stuffs in one file].

2.Better interface that is similar to eeglab.

3.Customised eeglab functions to facilitate QC process.

4.A tiny bug appears in in-house version fixed


### Release notes:
2017-10-09 ManualQC v1.0 Released

2017-10-10 Tiny bug fixed/Typo corrected

#### To do in new release :microscope: 
** 2017-10-11 Feature request for saving ICs removed dataset temporarily for the cases that a dataset needs remove QC first and inspect bad trials.**
** 2017-10-17 add that as EEGLAB plugin. **

### Breif Manual
#### Step0.
Add eeglab in Matlab path
Add manualqc in Matlab path
Run manualqc

#### Step1. Search datasets using a regular expression.
1. Enter a regular expression. One example is shown in the info panel. Type doc regexp to see more examples.
  [Our lab is using `^Final\w*.set` as ‘Final’ is added as prefix on pre-processed data]
2. Paste or select data directory.
3. Click search.

If there is any file matching the regular expression in the data directory:
* Load button will be enabled
* Index of file to load will be updated to 1.
* File number will be displayed.

#### Step2. Load a dataset.
**This only works when you are trying to load set file and the index of dataset is correct.**

If the dataset is loaded correctly:
* Some basic information of the dataset will be display.
  (Note: Data quality is calculated as the initial scale when epoch scrolling function. To some extent, this is a good index for data quality.)
* Epochs/Channels/ICs button will be enabled.



#### Step3. Check epochs, channels and ICs.
###### Exploring epochs
Inspect epochs and select bad ones in a normal way.
Mark: Mark selected epocehs as bad epochs.
The Bad epochs will be displayed in the information panel and removed when you save the dataset.
###### Select channels (ctrl/shift for multiple selections)
* Clear: clear previously marked channels.
* Mark: Mark the selected channels as bad channels.
* Property: Plot selected channels properties.

The Bad channels will be displayed in the information panel and interpolated by default way when you save the dataset.

###### Select ICs.
* Click the label above the topoplots.
* Mark the IC as Accept or Reject.
    Then the label of rejected ICs will be in red and accepted ICs will be in green.
* Selected ICs: update selected ICs. This is for testing IC removal.
* Test removal: Compare data before and after the removal of selected ICs.
* Test removal: Compare averaged data before and after the removal of selected ICs.
* Clear all selections: will clear ICs and reopen this window.
* Ok: Confirm selection of ICs to be removed.

The selected ICs will be displayed in the information panel and removed when you save the dataset.

#### Step4. Add user’s comments and rate the dataset.
Make comments and rate dataset like:
* a lot of alpha
* a lot of movement or muscle/EMG artefacts
* over 20% of epochs removed _> mark as 'caution' for 'data usable?'
* over 40-50% of epochs removed -> mark as 'bad' for 'data usable?'

Click add to update comments

#### Step5. Save manually QCed dataset.
* QC info will be updated in QC_log in workspace
* Temporary QC info will be saved as qc_info_bak_on_HH.MM in the save path.

#### Step6.  Save the QC_log by copying or xlswrite etc

### Tips on artfacts  ​
