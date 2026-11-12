---
title: 使用手册
outline: false
---
<p class="edition">EEGLAB 使用手册 · v1.3.0</p>

# ManualQC

<p class="lead">从一份真实的 EEG 记录开始，逐项检查 epoch、通道和独立成分，最后保存一份可以复核的质量控制记录。</p>

**[加载示例，开始第一次 QC →](/zh/guide/start)** · [已有评分表，直接比较](/zh/guide/raters)

![ManualQC 查看器中的多通道波形和已选 epoch](/figures/epochs.png)
<p class="caption"><strong>图 01 · 正在审查的 epoch。</strong> 每行代表一个通道。阴影是评分者当前的选择，并不是算法预测的伪迹。</p>

## 一次 QC 的四个步骤

| 步骤 | 要回答的问题 | 核对结果 |
| --- | --- | --- |
| [01 · 加载](/zh/guide/start) | 我打开的是哪份输入？ | 信息栏中的文件名和数据维度 |
| [02 · 标记 epoch](/zh/guide/epochs) | 哪些时间段整段不可用？ | 重开后高亮仍在 |
| [03 · 通道与 IC](/zh/guide/channels-ics) | 问题来自电极还是独立成分？ | 分别列出插值和移除清单 |
| [04 · 保存](/zh/guide/save) | 其他人能否复核我的决定？ | 新的数据集、内嵌记录和日志 |

多人研究先独立审查**同一份输入**，再用 [RaterTool](/zh/guide/raters) 找到分歧，回到波形核对。
