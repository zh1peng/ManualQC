## Manual QC
<a href="https://imgur.com/XYa5qyJ"><img src="https://i.imgur.com/XYa5qyJ.png" title="source: imgur.com" /></a>

#### Current Version: v1.1.7
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
  - remove logFile stuff
  - improve warning dialogus
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



## 简要手册

### 第0步：
#### 独立使用 ManualQC（不作为 EEGLAB 插件）：
1. 将 EEGLAB 添加到 MATLAB 路径中。
2. 将 ManualQC 添加到 MATLAB 路径中。
3. 运行 `ManualQC`。

#### 作为 EEGLAB 插件使用：
1. 从 EEGLAB 的插件管理器中下载（如果可用），或者将 `ManualQC1.1` 文件夹下载到 EEGLAB 的 `plugins` 文件夹中。
2. 加载任意数据集，工具条目将出现在 "Tools" 菜单中。

---

### 第1步：使用正则表达式搜索数据集
1. 输入一个正则表达式。信息面板中显示了一个示例。可以在 MATLAB 中键入 `doc regexp` 查看更多示例。  
   - *（我们实验室使用 `^Final\w*.set`，因为 'Final' 是添加到预处理数据的前缀。）*
2. 粘贴或选择数据目录。
3. 点击 **Search**。

如果在数据目录中找到匹配正则表达式的文件：
- **Load** 按钮将被启用。
- 要加载的文件索引将更新为 `1`。
- 将显示找到的文件总数。

---

### 第2步：加载数据集
**仅在加载 `.set` 文件且数据集索引正确时可用。**

如果数据集成功加载：
- 数据集的基本信息将显示出来。  
  *(注意：数据质量在使用 epoch 滚动功能时作为初始指标计算。这是一个有用的数据质量指标。)*
- **Epochs/Channels/ICs** 按钮将被启用。

---

### 第3步：检查 epochs、通道和 ICs
#### 查看 Epochs
检查 epochs 并标记坏的：
- **Mark**：将选定的 epochs 标记为坏的。  
  坏的 epochs 将显示在信息面板中，并在保存数据集时移除。

#### 选择通道（按住 Ctrl/Shift 可多选）
- **Clear**：清除先前标记的通道。
- **Mark**：将选定的通道标记为坏通道。
- **Property**：绘制选定通道的属性图。  
  坏通道将显示在信息面板中，并在保存数据集时进行插值。

#### 选择 ICs
- 点击 topoplots 上方的标签。
- 将 IC 标记为 **Accept** 或 **Reject**：  
  - 被拒绝的 IC 用红色标记。
  - 被接受的 IC 用绿色标记。
- **Selected ICs**：更新选定的 IC 列表以测试移除。
- **Test Removal**：比较移除选定 IC 前后的数据。
- **Test Averaged Removal**：比较移除选定 IC 前后的平均数据。
- **Clear All Selections**：清除所有 IC 选择并重新打开此窗口。
- **Ok**：确认移除的 IC 选择。  
  选定的 IC 将显示在信息面板中，并在保存数据集时移除。

#### 优先移除 ICs
如果优先移除坏 IC 可以保留更多的试验，请在继续执行其余 QC 之前使用 **Remove Bad ICs First** 按钮。

---

### 第4步：添加用户评论并对数据集进行评分
添加评论并对数据集评分，例如：
- "大量 alpha 活动。"
- "显著的运动或肌肉/EMG 伪影。"
- "移除了超过 20% 的 epochs -> 标记为 'caution'（数据可用？）"
- "移除了超过 40-50% 的 epochs -> 标记为 'bad'（数据不可用？）"

点击 **Add** 更新评论。

---

### 第5步：保存手动 QC 的数据集
- QC 信息将更新到工作区中的 `QC_log`。
- 临时 QC 信息将保存为 `qc_info_bak_on_HH.MM`，位于保存路径中。

---

### 第6步：保存 `QC_log`
手动复制或使用 `xlswrite`（或类似功能）保存最终的 QC 日志。  
在完成最后一个文件后，将保存最终的 QC 信息。

---

## 关于 QC 的提示
- 定期审查 QC 流程以确保一致性。
- 记录任何异常或偏离标准流程的情况。
- 确保所有保存的数据集和日志已安全备份。
