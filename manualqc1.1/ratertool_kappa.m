function [value, reason, observed] = ratertool_kappa(ratings)
% Binary Cohen (two raters) or Fleiss (> two raters) kappa.
value = NaN;
observed = NaN;
reason = '';
[n, k] = size(ratings);
if n == 0 || k < 2
    reason = 'need items and at least two raters';
    return
end
if any(~isfinite(ratings(:))) || any(ratings(:) ~= 0 & ratings(:) ~= 1)
    reason = 'ratings must be finite binary decisions';
    return
end
if k == 2
    observed = mean(ratings(:, 1) == ratings(:, 2));
    positive = mean(ratings, 1);
    expected = prod(positive) + prod(1 - positive);
else
    positive = sum(ratings, 2);
    negative = k - positive;
    observed = mean((positive .* (positive - 1) + negative .* (negative - 1)) / (k * (k - 1)));
    prevalence = mean(ratings(:));
    expected = prevalence^2 + (1 - prevalence)^2;
end
if 1 - expected <= eps(1)
    reason = 'single category; chance agreement is 1';
    return
end
value = (observed - expected) / (1 - expected);
end
