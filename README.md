# ManualQC
* ## Manual QC
  <a href="https://imgur.com/4izPvsv"><img src="https://i.imgur.com/4izPvsv.png" title="source: imgur.com" /></a>

  ### Current version: v1.0
  ### Breif Introduction
  Currently, more algorithms have been developed to automatically detect and remove EEG artefacts, but manual inventions are still needed. At least, in our lab, all EEG datasets have been QCed manually. When I started running QC on EEG data two years ago, I had to click the menu multiple times to load dataset, remove bad epoches, interpolate bad channels, remove ICs and save dataset. Then recorded those info manually and added comments if necessary. I couldn’t find an efficient way to do that from eeglab, so I incorporated QC related functions from eeglab and assembled them into one GUI. (in-house version) [https://github.com/zh1peng/EEGQC_GUI]. This GUI have been used in our lab for one year and it worked well.

  Realized that this could be useful by others who need to do manual QC on eegdata. I re-programmed the QC GUI with

  1.Advanced GUI-building codes [all stuffs in one file].

  2.Better interface that is similar to eeglab.

  3.Customised eeglab functions to facilitate QC process.

  4.A tiny bug appears in in-house version fixed


  ### Release notes:
  2017-10-09 ManualQC v1.0 Released

  ### Breif Manual

  ### Tips on artfacts  ​
