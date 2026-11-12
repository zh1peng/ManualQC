function label = manualqc_score_label(score)
% Display bands use the same integer the reviewer sees; logs retain decimals.
score = round(score);
if ~isfinite(score)
    label = 'N/A';
    return
elseif score <= 18
    band = 'Low, <=18';
elseif score <= 28
    band = 'Mid, 19-28';
else
    band = 'High, >=29';
end
label = sprintf('%d (%s)', score, band);
end
