# 加载第一份数据

用体积较小的 `sub-165` 示例完成第一次操作。目标是只加载一个文件，并保留原始输入。

## 准备 MATLAB

1. 下载并解压 [ManualQC v1.3.0](https://github.com/zh1peng/ManualQC/archive/refs/tags/v1.3.0.zip)，保留其中的 `rater_files` 文件夹。
2. 在 MATLAB 中先启动 [EEGLAB](https://eeglab.org/)，再把当前目录切换到解压后的仓库根目录。
3. 运行以下命令。只添加工具目录，不要将测试目录递归加入路径。

```matlab
addpath(fullfile(pwd,'manualqc1.1'))
mkdir('qc_output')
manualqc
```

启动提示选择 **Continue**。作为插件使用时，把 `manualqc1.1` 放进 EEGLAB 的 `plugins` 目录，重新启动 EEGLAB，载入数据后从 **Tools → ManualQC** 打开。

## 精确匹配一个文件

搜索目录填写 `rater_files`，正则表达式填写：

```text
^sub-165_task-mid_run-01_eeg_prep\.set$
```

点击 **Search**，核对结果窗口中的文件名。保留文件索引 **1**，点击 **Load**。批量处理可用 `\.set$` 匹配多个文件，但要先核对搜索结果。输出目录放在搜索树之外，以免下次把已处理文件当成输入。

![加载 sub-165 后的 ManualQC 工作台](/figures/workbench.png)
<p class="caption"><strong>自上而下看工作台。</strong> 上方搜索和加载，中间打开各类检查窗口，信息区显示当前数据和已确认的决定。</p>

**核对：** 窗口标题显示预期的数据集，信息区应显示 **327 个试次、59 个通道、52 个 IC**。初始质量分数反映信号尺度，不是数据合格线。
