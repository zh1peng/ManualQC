function tests = test_ratertool
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.oldPath = path;
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.root = root;
addpath(fullfile(root, 'manualqc'));
addpath(fullfile(root, 'tests', 'private', 'ratertool_stubs'));
testCase.TestData.output = tempname;
mkdir(testCase.TestData.output);
end

function setup(testCase)
testCase.TestData.figures = findall(0, 'Type', 'figure');
end

function teardown(testCase)
delete(setdiff(findall(0, 'Type', 'figure'), testCase.TestData.figures));
if isappdata(0, 'ratertool_test_selection'), rmappdata(0, 'ratertool_test_selection'); end
clear global in_callback
end

function teardownOnce(testCase)
path(testCase.TestData.oldPath);
rmdir(testCase.TestData.output, 's');
end

function testCohenKappa(testCase)
[value, reason, observed] = ratertool_kappa([1 1; 1 0; 0 1; 0 0]);
verifyEqual(testCase, value, 0, 'AbsTol', 1e-12);
verifyEqual(testCase, observed, 0.5);
verifyEmpty(testCase, reason);
verifyEqual(testCase, ratertool_kappa([1 1; 0 0]), 1);
verifyEqual(testCase, ratertool_kappa([1 0; 0 1]), -1);
end

function testFleissKappa(testCase)
[value, reason, observed] = ratertool_kappa([1 1 1; 0 0 0; 1 1 0; 0 0 1]);
verifyEqual(testCase, observed, 2/3, 'AbsTol', 1e-12);
verifyEqual(testCase, value, 1/3, 'AbsTol', 1e-12);
verifyEmpty(testCase, reason);
end

function testUndefinedKappa(testCase)
for k = [2 3]
    for category = [0 1]
        [value, reason, observed] = ratertool_kappa(repmat(category, 10, k));
        verifyTrue(testCase, isnan(value));
        verifyEqual(testCase, observed, 1);
        verifySubstring(testCase, reason, 'single category');
    end
end
[value, reason] = ratertool_kappa([0 NaN; 1 1]);
verifyTrue(testCase, isnan(value));
verifySubstring(testCase, reason, 'finite binary');
end

function testICC(testCase)
% Published Shrout/Fleiss example, ICC(2,1) = 0.2898.
scores = [9 2 5 8; 6 1 3 2; 8 4 6 8; 7 1 2 6; 10 5 6 9; 6 2 4 7];
[value, reason, n] = ratertool_icc(scores);
verifyEqual(testCase, value, 0.289763779527559, 'AbsTol', 1e-12);
verifyEqual(testCase, n, 6);
verifyEmpty(testCase, reason);
verifyEqual(testCase, ratertool_icc([1 1; 2 2; 3 3]), 1, 'AbsTol', 1e-12);
[value, reason, n] = ratertool_icc([scores; NaN 1 2 3; Inf 2 3 4]);
verifyEqual(testCase, value, ratertool_icc(scores), 'AbsTol', 1e-12);
verifyEqual(testCase, n, 6);
verifyEmpty(testCase, reason);
[value, reason] = ratertool_icc(ones(4, 3));
verifyTrue(testCase, isnan(value));
verifySubstring(testCase, reason, 'zero variance');
[value, reason] = ratertool_icc([1 2; NaN 3]);
verifyTrue(testCase, isnan(value));
verifySubstring(testCase, reason, 'two complete datasets');
end

function testBinaryMapping(testCase)
info = struct('channelLabels', {{'Fz', 'Cz', 'Pz'}}, 'trialIds', [101 103 107]);
[ratings, reason] = ratertool_binary_decisions({[101 107], 103}, 'rejectedTrials', 3, info);
verifyEqual(testCase, ratings, [1 0; 0 1; 1 0]);
verifyEmpty(testCase, reason);
[ratings, reason] = ratertool_binary_decisions({{'fz', 'PZ'}, {'2'}}, 'interpolatedChannels', 3, info);
verifyEqual(testCase, ratings, [1 0; 0 1; 1 0]);
verifyEmpty(testCase, reason);
for invalid = {104, -1, 1.5, Inf}
    [ratings, reason] = ratertool_binary_decisions({invalid{1}, []}, 'rejectedTrials', 3, info);
    verifyEmpty(testCase, ratings);
    verifySubstring(testCase, reason, 'unknown or out-of-range');
end
[ratings, reason] = ratertool_binary_decisions({{'unknown'}, {}}, 'interpolatedChannels', 3, info);
verifyEmpty(testCase, ratings);
verifySubstring(testCase, reason, 'unknown or out-of-range');
[ratings, reason] = ratertool_binary_decisions({4, []}, 'removedICs', 3, info);
verifyEmpty(testCase, ratings);
verifySubstring(testCase, reason, 'unknown or out-of-range');
end

function testViewerNavigation(testCase)
verifyEqual(testCase, exist('ratertool_eegplot', 'file'), 2);
data = reshape(1:8*64*30, 8, 64, 30);
ratertool_eegplot(data, 'srate', 64, 'trialstag', 64, 'winlength', 5, ...
    'raterbadchans', {[2], [4]}, 'ratercolors', [1 0 0; 0 0 1]);
fig = gcf;
verifyEqual(testCase, get(fig, 'UserData').time, 0);
runControl(findobj(fig, 'String', '>>'));
verifyEqual(testCase, get(fig, 'UserData').time, 5);
runControl(findobj(fig, 'String', '>'));
verifyEqual(testCase, get(fig, 'UserData').time, 6);
runControl(findobj(fig, 'String', '<'));
verifyEqual(testCase, get(fig, 'UserData').time, 5);
runControl(findobj(fig, 'String', '<<'));
verifyEqual(testCase, get(fig, 'UserData').time, 0);
position = findobj(fig, 'Tag', 'EPosition');
set(position, 'String', '21');
runControl(position);
verifyEqual(testCase, get(fig, 'UserData').time, 20);
spacing = findobj(fig, 'Tag', 'ESpacing');
set(spacing, 'String', '50');
runControl(spacing);
verifyEqual(testCase, get(fig, 'UserData').spacing, 50);
key = get(fig, 'WindowKeyPressFcn');
other = figure('Visible', 'off');
key(fig, struct('Key', 'rightarrow', 'Character', ''));
verifyEqual(testCase, get(fig, 'UserData').time, 25);
key(fig, struct('Key', 'leftarrow', 'Character', ''));
verifyEqual(testCase, get(fig, 'UserData').time, 20);
delete(other);
verifyNotEmpty(testCase, findobj(fig, 'Tag', 'raterbadtri'));
end

function testSummaryMissingData(testCase)
folder = testCase.TestData.output;
writeRater(fullfile(folder, 'a.csv'), ["shared"; "onlyA"], ["None"; "1"], [1; NaN]);
writeRater(fullfile(folder, 'b.csv'), ["shared"; "onlyB"], ["None"; "2"], [1; NaN]);
fig = loadRaters(folder, {'a.csv', 'b.csv'});
runControl(findobj(fig, 'String', 'Compute Agreement'));
table = findobj(fig, 'Type', 'uitable', 'ColumnName', {'Dataset', 'Raters', 'QC_Before', 'QC_After', ...
    'Trials_Jaccard', 'Trials_F1', 'Trials_Prec', 'Trials_Rec', 'Trials_Kappa', 'Trials_GroupJ', ...
    'Chan_Jaccard', 'Chan_F1', 'Chan_Prec', 'Chan_Rec', 'Chan_Kappa', 'Chan_GroupJ', ...
    'ICs_Jaccard', 'ICs_F1', 'ICs_Prec', 'ICs_Rec', 'ICs_Kappa', 'ICs_GroupJ'});
verifyNumElements(testCase, table, 1);
rows = get(table, 'Data');
shared = find(strcmp(rows(:, 1), 'shared'));
verifyEqual(testCase, rows{shared, 5}, 1);
verifySubstring(testCase, rows{shared, 9}, 'disabled');
single = find(strcmp(rows(:, 1), 'onlyA'));
verifySubstring(testCase, rows{single, 5}, 'fewer than two raters');
verifyFalse(testCase, any(cellfun(@(v) isnumeric(v) && any(~isfinite(v(:))), rows(:))));
end

function testLiteralPlotLabels(testCase)
folder = testCase.TestData.output;
names = {'reviewer_one', 'reviewer_two'};
files = strcat(names, '.csv');
for i = 1:2
    writeRater(fullfile(folder, files{i}), "sub_test", "1", 18.75);
end
fig = loadRaters(folder, files);
runControl(findobj(fig, 'String', 'Compute Agreement'));
tables = findobj(fig, 'Type', 'uitable');
summary = tables(arrayfun(@(t) any(strcmp(t.ColumnName,'QC_Before')), tables));
verifyEqual(testCase, summary.Data(1,3:4), {'19', '19'});
runControl(findobj(fig, 'String', 'Plot Rater Heatmap'));
ax = findobj(gcf, 'Type', 'axes');
verifyNumElements(testCase, ax, 3);
for i = 1:3
    verifyEqual(testCase, ax(i).TickLabelInterpreter, 'none');
    verifyEqual(testCase, string(ax(i).XTickLabel(:)), string(names(:)));
end
runControl(findobj(fig, 'String', 'Plot Dataset Bars'));
verifyEqual(testCase, get(gca().Title, 'Interpreter'), 'none');
end

function testMetadataAgreement(testCase)
folder = testCase.TestData.output;
writeRater(fullfile(folder, 'c.csv'), "mapped", "101", 1);
writeRater(fullfile(folder, 'd.csv'), "mapped", "103", 2);
EEG = eeg_emptyset;
EEG.data = zeros(3, 64, 3, 'single');
EEG.nbchan = 3;
EEG.pnts = 64;
EEG.trials = 3;
EEG.srate = 64;
EEG.xmin = 0;
EEG.xmax = 63/64;
EEG.chanlocs = struct('labels', {'Fz', 'Cz', 'Pz'});
EEG.etc.EEGdojo.TrialID = [101 103 107];
save(fullfile(folder, 'mapped.set'), 'EEG', '-mat');
fig = loadRaters(folder, {'c.csv', 'd.csv'});
set(findobj(fig, 'String', 'Data root path'), 'String', folder);
toggle = findobj(fig, 'Style', 'checkbox');
set(toggle, 'Value', 1);
runControl(toggle);
runControl(findobj(fig, 'String', 'Compute Agreement'));
tables = findobj(fig, 'Type', 'uitable');
summary = tables(arrayfun(@(h) numel(get(h, 'ColumnName')) == 22, tables));
rows = get(summary, 'Data');
verifyEqual(testCase, rows{1, 9}, -0.5, 'AbsTol', 1e-12);
verifySubstring(testCase, rows{1, 15}, 'single category');
verifySubstring(testCase, rows{1, 21}, 'no valid item count');
% Recomputing must not reuse metadata from an earlier root/file state.
EEG.etc.EEGdojo.TrialID = [201 203 207];
save(fullfile(folder, 'mapped.set'), 'EEG', '-mat');
runControl(findobj(fig, 'String', 'Compute Agreement'));
rows = get(summary, 'Data');
verifySubstring(testCase, rows{1, 9}, 'unknown or out-of-range');
end

function testNoSharedDatasets(testCase)
folder = testCase.TestData.output;
writeRater(fullfile(folder, 'e.csv'), "A", "None", NaN);
writeRater(fullfile(folder, 'f.csv'), "B", "None", NaN);
fig = loadRaters(folder, {'e.csv', 'f.csv'});
runControl(findobj(fig, 'String', 'Compute Agreement'));
verifyNotEmpty(testCase, findobj(fig, 'Style', 'listbox', 'String', {'(none)'}));
runControl(findobj(fig, 'String', 'Plot Rater Heatmap'));
images = findobj(gcf, 'Type', 'image');
verifyNumElements(testCase, images, 3);
for h = images'
    values = get(h, 'CData');
    verifyEqual(testCase, diag(values), [1; 1]);
    verifyTrue(testCase, isnan(values(1, 2)));
    verifyEqual(testCase, get(h, 'AlphaData'), logical(eye(2)));
end
end

function testReplayDecisionLayout(testCase)
folder = testCase.TestData.output;
dataset = "sub-165_task-mid_run-01_eeg_prep";
names = {'first_reviewer_with_a_long_display_name', 'second_reviewer', 'third_reviewer'};
files = strcat(names, '.csv');
writeRater(fullfile(folder, files{1}), dataset, "1", 1);
writeRater(fullfile(folder, files{2}), dataset, "None", 1);
writeRater(fullfile(folder, files{3}), "z_other_dataset", "None", 1);
fig = loadRaters(folder, files);
set(findobj(fig, 'String', 'Data root path'), 'String', fullfile(testCase.TestData.root, 'rater_files'));
runControl(findobj(fig, 'String', 'Compute Agreement'));
runControl(findobj(fig, 'String', 'Load EEG'));
panel = findobj(fig, 'Type', 'uipanel', 'Title', 'Replay / Inspection');
t = findobj(panel, 'Type', 'uitable');
verifyEqual(testCase, t.Data, [names(:), {'Rejected'; 'Kept'; 'No data'}]);
labels = findobj(panel, 'Style', 'text');
epoch = labels(arrayfun(@(h) startsWith(h.String, 'Epoch: 1 /'), labels));
assertNumElements(testCase, epoch, 1);
status = findobj(panel, 'String', 'Status: EEG loaded.');
for width = [820 1200]
    set(fig, 'Units', 'pixels', 'Position', [40 80 width 570]);
    drawnow;
    e = getpixelposition(epoch);
    s = getpixelposition(status);
    p = getpixelposition(t);
    verifyLessThanOrEqual(testCase, e(1)+e(3), s(1)+1);
    verifyLessThanOrEqual(testCase, p(2)+p(4), min(e(2), s(2))+1);
end
list = findobj(panel, 'Style', 'listbox');
set(list, 'Value', [2 3]);
runControl(list);
verifyEqual(testCase, t.Data, [names(2:3)', {'Kept'; 'No data'}]);
popup = findobj(panel, 'Style', 'popupmenu');
set(popup, 'Value', 2);
runControl(popup);
verifyEmpty(testCase, t.Data);
verifyEqual(testCase, epoch.String, 'Epoch: N/A');
end

function writeRater(file, datasets, trials, quality)
n = numel(datasets);
T = table(datasets, trials, repmat("None", n, 1), repmat("None", n, 1), ...
    repmat("", n, 1), repmat("Usable", n, 1), quality, quality, ...
    'VariableNames', {'dataset', 'Rejected trials', 'Interpolated Channels', ...
    'Removed ICs', 'Comments', 'Rating', 'Quality Score Before', 'Quality Score After'});
writetable(T, file);
end

function fig = loadRaters(folder, files)
setappdata(0, 'ratertool_test_selection', struct('folder', folder, 'files', {files}));
ratertool;
fig = gcf;
runControl(findobj(fig, 'String', 'Load Rater Files'));
end

function runControl(control)
assert(isscalar(control));
callback = get(control, 'Callback');
if isa(callback, 'function_handle')
    callback(control, []);
else
    callbackFigure = ancestor(control, 'figure');
    set(0, 'CurrentFigure', callbackFigure);
    callback = strrep(callback, 'gcbf', 'callbackFigure');
    callback = strrep(callback, 'gcbo', 'control');
    eval(callback);
end
end
