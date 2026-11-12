# 查看通道与独立成分

坏道插值用周围电极重建该传感器的信号，移除 IC 则从多个通道中减去一个独立成分的贡献。两者不是同一种操作。

## 检查电极

打开 **Channels**，用 Ctrl 或 Shift 多选标签。点击 **Property** 检查通道，与附近电极对比，判断问题是否跨多个 epoch 持续存在。点击 **Mark**，核对工作台的 **Bad Channels** 列表；使用 **Clear** 可清除选择。保存时会对所选通道一起执行球面插值，前提是电极坐标有效。

## 检查 ICA 分解

打开 **ICs**。每个窗口最多显示 **35 个成分**，数量取决于实际分解结果。即使通道多于 20 个，秩为 20 的分解也只应显示 20 个 IC。

![ManualQC 的编号 IC 地形图窗口](/figures/components.png)
<p class="caption"><strong>点击地形图上方的编号。</strong> 编号会打开成分属性。不要仅凭一张地形图决定移除成分。</p>

查看属性，选择 **Accept** 或 **Reject**，用 **Selected ICs** 更新清单。用 **Test Removal** 或 **Test Averaged Removal** 比较移除前后的信号。最后点 **Ok** 并核对工作台的 IC 清单。如果数据没有 ICA 权重，跳过这一步。

::: warning 注意操作顺序
**Remove Bad ICs First** 会立即改变内存中的数据，并清空当前的 epoch 和通道选择。如果要先移除 IC，请在检查 epoch 和通道之前执行，然后重新检查改变后的信号。普通流程只需确认 IC 清单，留待保存时统一处理。
:::
