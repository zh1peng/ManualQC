# 比较评分者

输入应是多人对**同一份 QC 前数据**的独立记录。回放不能使用某位评分者剔除 epoch 后的文件，否则相同序号可能指向不同试次。

## 复现示例

1. 在 MATLAB 运行 `ratertool`。点击 **Load Rater Files**，从 [rater_files](https://github.com/zh1peng/ManualQC/tree/v1.3.0/rater_files) 同时选中 `rater_czr.xlsx`、`rater_hlz.xlsx` 和 `rater_pcj.csv`。
2. 将数据根目录设为同一文件夹。评分表包含的记录多于仓库附带的两份 EEG；只有能匹配到原始文件的记录才能回放。
3. 点击 **Compute Agreement**，从 **Top Disagreements** 或回放下拉框选择数据集。查看 **Pairwise Details**，找出具体哪两位评分者在哪类决定上不一致。

![示例三份评分表加载后的 RaterTool 结果和回放区域](/figures/raters.png)
<p class="caption"><strong>分三层阅读。</strong> 顶部识别评分者，中部汇总一致性，底部把当前数据集和 epoch 对应到每位评分者的判断。</p>

## 回放一个分歧

选择 `sub-3004_ses-post_task-mid_run-1_eeg_prep` 和要检查的评分者，点击 **Load EEG**。用 **Open Viewer** 查看波形并翻页，以逐评分者表格核对当前 epoch。如果分歧涉及通道或独立成分，使用 **Channel Inspect** 或 **IC Inspect**。示例记录只是供比较，并非裁定后的金标准。

## 使用自己的评分表

保留导出表头：`dataset`、`Rejected trials`、`Interpolated Channels`、`Removed ICs`、`Comments`、`Rating`、`Quality Score Before`、`Quality Score After`。不同评分者须使用一致的数据集名称。比较 IC 时要用**同一套 ICA 分解**，成分数量相同并不够。选定输出目录后用 **Export** 保留比较结果。
