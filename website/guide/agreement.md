# Interpret agreement

Choose the statistic that answers your question. “Did raters flag the same items?” is different from “Did raters agree beyond chance across all possible items?”

| Quantity | Interpretation | Watch for |
| --- | --- | --- |
| Jaccard | Shared rejected items divided by all items rejected by either rater | Two empty sets score 1 by convention. |
| F1 | Twice the overlap divided by the sum of both rejection-set sizes | Symmetric; two empty sets score 1. |
| Precision / recall | Overlap divided by Rater A's / Rater B's rejection count, respectively | Direction matters. Neither rater is a gold standard. |
| Kappa | Agreement relative to expected agreement on the common item universe | Requires metadata; Cohen for two raters, Fleiss for more. |
| ICC(2,1) | Absolute agreement between individual raters' numerical quality scores | Uses datasets with finite scores from every rater. Check the reported sample size. |

For example, A rejecting epochs {1, 3, 5} and B rejecting {3, 5} gives Jaccard **2/3**, F1 **4/5**, precision **2/3**, recall **1**. This calculation alone tells you nothing about the epochs both raters kept.

![Pairwise heatmap generated from the bundled rater logs](/figures/heatmap.png)
<p class="caption"><strong>Compare like with like.</strong> Read the metric named on the plot. Gray means no shared datasets, not zero agreement; the diagonal compares each rater with themself.</p>

## When a number is unavailable

- A dataset with fewer than two raters cannot establish inter-rater agreement.
- For kappa, enable **Use EEG metadata for kappa** and supply the common pre-QC files. Unknown channels or invalid indices are not treated as agreements. When every item receives one category from everyone, expected agreement is 1 and kappa is undefined.
- **Trial identifiers:** v1.3.0 CSV logs record current epoch positions. When `EEG.etc.EEGdojo.TrialID` exists, metadata-based kappa interprets trial entries as mapped IDs. If the mapping is not the identity, reconcile logs with the embedded QC record on a separate analysis copy before interpreting trial kappa.
- For ICC, fewer than two complete datasets or lack of score variation can make the statistic undefined. Report the reason and sample size instead of replacing an unavailable estimate with zero.
