function [ratings, reason] = ratertool_binary_decisions(sets, fieldName, total, info)
% Map every rejection into the common pre-QC item universe, or reject it.
ratings = [];
reason = '';
if ~isscalar(total) || ~isfinite(total) || total < 1 || total ~= fix(total)
    reason = 'no valid item count in EEG metadata';
    return
end
trialIds = [];
if strcmp(fieldName, 'rejectedTrials') && isfield(info, 'trialIds') && ~isempty(info.trialIds)
    trialIds = info.trialIds(:);
    if ~isnumeric(trialIds) || numel(trialIds) ~= total || ...
            any(~isfinite(trialIds) | trialIds < 1 | trialIds ~= fix(trialIds)) || numel(unique(trialIds)) ~= total
        reason = 'invalid EEG TrialID mapping';
        return
    end
end
ratings = zeros(total, numel(sets));
for r = 1:numel(sets)
    if isempty(sets{r}), continue; end
    if strcmp(fieldName, 'interpolatedChannels')
        labels = upper(strtrim(string(sets{r})));
        known = upper(strtrim(string(info.channelLabels)));
        idx = zeros(size(labels));
        for j = 1:numel(labels)
            match = find(known == labels(j));
            if isscalar(match)
                idx(j) = match;
            elseif isempty(match)
                idx(j) = str2double(labels(j));
            else
                idx(j) = NaN;
            end
        end
    elseif ~isempty(trialIds)
        [found, idx] = ismember(sets{r}, trialIds);
        idx(~found) = NaN;
    else
        idx = sets{r};
    end
    if ~isnumeric(idx) || any(~isfinite(idx(:)) | idx(:) < 1 | idx(:) > total | idx(:) ~= fix(idx(:)))
        ratings = [];
        reason = sprintf('rater %d: unknown or out-of-range item; check pre-QC EEG/TrialIDs', r);
        return
    end
    ratings(unique(idx), r) = 1;
end
end
