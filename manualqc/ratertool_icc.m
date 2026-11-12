function [value, reason, n] = ratertool_icc(data)
% ICC(2,1): two-way random effects, absolute agreement, complete cases.
value = NaN;
reason = '';
X = data(all(isfinite(data), 2), :);
[n, k] = size(X);
if k < 2 || n < 2
    reason = 'need at least two complete datasets and two raters';
    return
end
% Center and scale without changing ICC, avoiding overflow for large scores.
scale = max(abs(X(:)));
if scale > 0, X = X / scale; end
X = X - mean(X(:));
meanRow = mean(X, 2);
meanCol = mean(X, 1);
MSR = k * sum(meanRow.^2) / (n - 1);
MSC = n * sum(meanCol.^2) / (k - 1);
MSE = sum(sum((X - meanRow - meanCol).^2)) / ((n - 1) * (k - 1));
denom = MSR + (k - 1) * MSE + k * (MSC - MSE) / n;
if denom <= eps(max([MSR, MSC, MSE]))
    reason = 'zero variance; ICC is undefined';
    return
end
value = (MSR - MSE) / denom;
end
