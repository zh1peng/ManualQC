function run_manualqc_regression(eeglabRoot)
% Run in a fresh MATLAB session with an EEGLAB checkout/install:
% addpath('tests'); run_manualqc_regression('/path/to/eeglab');
% Real EEGLAB functions handle plotting, interpolation, rejection and saving.
testDir = fileparts(mfilename('fullpath'));
oldPath = path;
oldVisibility = get(0, 'DefaultFigureVisible');
oldFigures = findall(0, 'Type', 'figure');
outputDir = tempname;
mkdir(outputDir);
cleanup = onCleanup(@restoreEnvironment);
addpath(eeglabRoot);
addpath(genpath(fullfile(eeglabRoot, 'functions')));
addpath(fullfile(fileparts(testDir), 'manualqc1.1'));
set(0, 'DefaultFigureVisible', 'off');
startupPath = fullfile(testDir, 'private', 'startup_stubs');
addpath(startupPath);
manualqc;
rmpath(startupPath);

global EEG tmprej ui chanlisttmp chanliststr ic2remove just_ic filenames n
locations = readlocs(fullfile(eeglabRoot, 'sample_locs', 'Standard-10-20-Cap81.ced'));
rng(17);
EEG = makeDataset(8, 0);
tmprej = [];

% Reopen, add, unmark, clear/confirm, and cancel are separate transitions.
plotFigure = openEpochs;
setEpochs(plotFigure, [1 3 5]);
runButton(findobj(plotFigure, 'Tag', 'Accept'));
assert(isequal(find(tmprej), [1 3 5]));
plotFigure = openEpochs;
assert(isequal(markedEpochs(plotFigure), [1 3 5]));
setEpochs(plotFigure, [1 2 3 4 5 6]);
runButton(findobj(plotFigure, 'Tag', 'Accept'));
assert(isequal(find(tmprej), 1:6));
plotFigure = openEpochs;
assert(isequal(markedEpochs(plotFigure), 1:6));
setEpochs(plotFigure, [1 2 4 5 6]);
runButton(findobj(plotFigure, 'Tag', 'Accept'));
assert(isequal(find(tmprej), [1 2 4 5 6]));
plotFigure = openEpochs;
runButton(findobj(plotFigure, 'Tag', 'ClearEpochs'));
assert(isempty(markedEpochs(plotFigure)));
assert(isequal(find(tmprej), [1 2 4 5 6]));
runButton(findobj(plotFigure, 'String', 'CANCEL'));
assert(isequal(find(tmprej), [1 2 4 5 6]));
plotFigure = openEpochs;
assert(isequal(markedEpochs(plotFigure), [1 2 4 5 6]));
setEpochs(plotFigure, [2 7]);
runButton(findobj(plotFigure, 'String', 'CANCEL'));
assert(isequal(find(tmprej), [1 2 4 5 6]));
plotFigure = openEpochs;
setEpochs(plotFigure, []);
runButton(findobj(plotFigure, 'Tag', 'Accept'));
assert(isempty(tmprej));
plotFigure = openEpochs;
setEpochs(plotFigure, [1 3 5]);
runButton(findobj(plotFigure, 'Tag', 'Accept'));
plotFigure = openEpochs;
runButton(findobj(plotFigure, 'Tag', 'ClearEpochs'));
runButton(findobj(plotFigure, 'Tag', 'Accept'));
assert(isempty(tmprej));
assert(contains(get(ui.info3, 'String'), '[Sum: 0]'));
plotFigure = openEpochs;
assert(isempty(markedEpochs(plotFigure)));
runButton(findobj(plotFigure, 'Tag', 'Accept'));
assert(isempty(tmprej));
fprintf('PASS: epoch reopen/add/unmark/Clear/Mark/Cancel transitions\n');

% Save must change bad-channel samples and preserve the TrialID mapping.
original = makeDataset(8, 0);
original.data(2,:,:) = original.data(2,:,:) + 1000;
original.data(4,:,:) = original.data(4,:,:) - 2000;
original.etc.EEGdojo.TrialID = (101:108)';
EEG = original;
tmprej = [1 0 1 0 0 0 0 0];
chanlisttmp = [2 4];
chanliststr = strjoin({EEG.chanlocs(chanlisttmp).labels}, ' ');
expectedLabels = chanliststr;
expected = pop_rejepoch(original, tmprej, 0);
expected = pop_interp(expected, chanlisttmp, 'spherical');
prepareSave('interpolated.set');
runButton(ui.save);
saved = pop_loadset('filename', 'qc_interpolated.set', 'filepath', outputDir);
assert(max(abs(double(saved.data(:))-double(expected.data(:)))) < 1e-4);
assert(isequal(saved.etc.EEGdojo.TrialID, [102; 104; 105; 106; 107; 108]));
assert(isequal(saved.etc.manualqc.rejected_trials_id, [101 103]));
assert(strcmp(saved.etc.manualqc.interpolated_channels, expectedLabels));
assert(max(abs(double(reshape(saved.data(2,:,:), [], 1)))) < 1000);
fprintf('PASS: saved samples match joint interpolation; TrialIDs survive rejection\n');

EEG = original;
tmprej = [];
chanlisttmp = [];
chanliststr = [];
prepareSave('unchanged.set');
runButton(ui.save);
saved = pop_loadset('filename', 'qc_unchanged.set', 'filepath', outputDir);
assert(isequal(saved.data, original.data));
assert(isequal(saved.etc.EEGdojo.TrialID, original.etc.EEGdojo.TrialID));
assert(strcmp(saved.etc.manualqc.interpolated_channels, 'None'));
fprintf('PASS: no selections leave saved samples and TrialIDs unchanged\n');

% Include rank-reduced ICA, a single IC, and multiple pages.
for count = [1 20 40]
    EEG = makeDataset(max(8, count+2), count);
    runButton(ui.ica);
    figures = findall(0, 'Type', 'figure', '-regexp', 'Tag', '^selcomp');
    assert(numel(figures) == ceil(count/35));
    buttons = findall(figures, 'Type', 'uicontrol', '-regexp', 'Tag', '^comp[0-9]+$');
    indices = arrayfun(@(h) str2double(get(h, 'String')), buttons);
    assert(isequal(sort(indices(:))', 1:count));
    assert(isequal(size(EEG.reject.gcompreject), [1 count]));
    delete(figures);
end
EEG = makeDataset(8, 0);
runButton(ui.ica);
assert(isempty(findall(0, 'Type', 'figure', '-regexp', 'Tag', '^selcomp')));
fprintf('PASS: 0/1/20/40 ICs, including rank-reduced ICA and pagination\n');
fprintf('All ManualQC regression checks passed.\n');

    function dataset = makeDataset(channels, components)
        dataset = eeg_emptyset;
        dataset.setname = 'ManualQC regression';
        dataset.data = single(randn(channels, 64, 8));
        dataset.nbchan = channels;
        dataset.pnts = 64;
        dataset.trials = 8;
        dataset.srate = 64;
        dataset.xmin = 0;
        dataset.xmax = 63/64;
        dataset.chanlocs = locations(1:channels);
        if components > 0
            dataset.icaweights = eye(components, channels);
            dataset.icasphere = eye(channels);
            dataset.icawinv = pinv(dataset.icaweights);
            dataset.icachansind = 1:channels;
        end
        dataset = eeg_checkset(dataset);
    end

    function plotFigure = openEpochs
        runButton(ui.scroll);
        plotFigure = findall(0, 'Type', 'figure', 'Tag', 'EEGPLOT');
        assert(isscalar(plotFigure));
    end

    function setEpochs(plotFigure, indices)
        state = get(plotFigure, 'UserData');
        mask = false(1, EEG.trials);
        mask(indices) = true;
        state.winrej = trial2eegplot(mask, zeros(EEG.nbchan, EEG.trials), EEG.pnts, [1 1 0.783]);
        set(plotFigure, 'UserData', state);
    end

    function indices = markedEpochs(plotFigure)
        state = get(plotFigure, 'UserData');
        if isempty(state.winrej)
            indices = [];
        else
            indices = find(eegplot2trial(state.winrej, EEG.pnts, EEG.trials));
        end
    end

    function prepareSave(name)
        ic2remove = [];
        just_ic = [];
        filenames = {name, 'next.set'};
        n = 1;
        set(ui.savedir, 'String', outputDir);
        set(ui.prefix, 'String', 'qc_');
        ratings = findobj(ui.rating, 'Style', 'radiobutton');
        ui.rating.SelectedObject = ratings(1);
    end

    function restoreEnvironment
        delete(setdiff(findall(0, 'Type', 'figure'), oldFigures));
        set(0, 'DefaultFigureVisible', oldVisibility);
        path(oldPath);
        rmdir(outputDir, 's');
    end
end

function runButton(button)
assert(isscalar(button));
callback = get(button, 'Callback');
if isa(callback, 'function_handle')
    callback(button, []);
else
    % Supply the figure/button context normally supplied by a mouse event.
    callbackFigure = ancestor(button, 'figure');
    set(0, 'CurrentFigure', callbackFigure);
    callback = strrep(callback, 'gcbf', 'callbackFigure');
    callback = strrep(callback, 'gcbo', 'button');
    eval(callback);
end
end
