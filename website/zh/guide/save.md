# 保存并核对结果

## 记录决定

1. 填写可以复核的观察，例如“某电极在多个 epoch 中持续出现噪声”，点击 **Add**，确认文字已进入信息栏。
2. 选择评分：**Usable** 对应 `qced_`，**Recheck** 对应 `recheck_`，**Not usable** 对应 `bad_`。需要自定义前缀时，先选评分，再修改前缀。
3. 选择已创建的 `qc_output` 输出目录。核对 epoch 数、通道标签、IC 编号和目标路径，再点击 **Save**。

## 从磁盘重新核对

如果示例评级为 **Usable**，可以这样读取结果：

```matlab
out = pop_loadset('filename','qced_sub-165_task-mid_run-01_eeg_prep.set', ...
                  'filepath',fullfile(pwd,'qc_output'));
disp(out.etc.manualqc)
```

输出 epoch 数应等于输入数减去确认移除的数量。插值后通道**仍然存在**，请看波形，而不是仅比较通道数。如果生成了配套的 `.fdt`，请与 `.set` 一起保留。

| 记录 | 如何核对 |
| --- | --- |
| 保存文件中的 `EEG.etc.manualqc` | 区分当前索引 `rejected_epochs_current` 和 `rejected_trials_id`；与行为数据关联前，查看 `rejected_id_space`。 |
| MATLAB 工作区的 `QC_log` | 退出 MATLAB 前检查各文件对应的记录。 |
| `qc_info_bak_on_HH.MM.csv`、`final_qc_info_on_HH.MM.csv` | 前者是过程备份，保存最后一个匹配文件时写出最终日志。每位评分者独立保留一份。 |

::: warning 关于旧版输出
受影响的 v1.2.0 文件可能记录了插值通道，但信号并未改变。安装 v1.3.0 不会修复旧文件；请从原始 QC 前数据重新处理，并验证保存后的通道波形。
:::
