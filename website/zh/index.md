---
title: ManualQC 使用手册
titleTemplate: false
outline: false
---
<p class="edition">ManualQC · EEGLAB 插件 · v1.3.0</p>

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

## 为什么要记录脑电人工质控的判断？

自动预处理之后，有些伪迹仍需要人工判断。例如，ICLabel 会估计一个独立成分来自脑活动、眼动或其他来源的概率。遇到分类不确定的成分，评分者可以结合头皮地形图、时间序列和功率谱，再决定是否移除。[Pion-Tonachini 等，2019](https://doi.org/10.1016/j.neuroimage.2019.05.026)

撰写研究报告时，一个基本问题是：最终有多少个试次进入了分析？一项涵盖 132 项视觉 N400 研究的综述发现，40.2% 的研究没有报告因伪迹或行为错误剔除试次后还剩多少个试次。ManualQC 将剔除的 epoch、插值的通道、移除的独立成分和评分者备注随处理后的数据一起保存，也可通过[质控日志](/zh/guide/save)逐份核对这些决定。[Šoškić 等，2022](https://doi.org/10.1007/s11065-021-09513-4)

两位评分者剔除的 epoch 数量相同，选中的却可能是不同的片段。培训时，可以先独立审查同一份记录，再用 [RaterTool](/zh/guide/raters) 将两人的标记叠加在质控前的波形上。选一个意见不同的 epoch 一起看，讨论这段信号是否符合实验室的剔除标准。[Shirk 等，2017](https://doi.org/10.3389/fnins.2017.00322) · [Boudewyn 等，2023](https://doi.org/10.1111/psyp.14365)
