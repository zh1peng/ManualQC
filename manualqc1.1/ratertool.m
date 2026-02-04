% RATTERTOOL - Inter-rater agreement tool for ManualQC outputs
%
% Expected input schema (CSV or Excel, one file per rater):
%   - dataset
%   - Rejected trials
%   - Interpolated Channels
%   - Removed ICs
%   - Comments
%   - Rating
%   - Quality Score Before
%   - Quality Score After
%
% Dataset matching for EEG replay:
%   - Uses the dataset column value as the identifier.
%   - If it already ends with ".set", it is matched directly.
%   - Otherwise, ratertool searches data root for "<dataset>.set"
%     (recursive), and falls back to any .set file containing the
%     dataset identifier in the filename.
%
% Metrics:
%   - Jaccard overlap: |A intersect B| / |A union B| (pairwise), and |intersect all|/|union all| (group)
%   - Symmetric precision/recall/F1 (pairwise): precision = |A intersect B|/|A|,
%     recall = |A intersect B|/|B|, F1 = 2|A intersect B|/(|A|+|B|)
%   - Cohen's kappa (2 raters) or Fleiss' kappa (>2) for binary decisions
%     when total item counts are known (from EEG metadata).
%   - ICC (2,1) for scalar scores (Quality Score Before/After) across datasets.
%
% Quick demo workflow (using /rater_test):
%   1) Click "Load Rater Files" and select all files in /rater_test.
%   2) Set Data Root to /rater_test (contains example .set files).
%   3) Click "Compute Agreement" to populate the summary table.
%   4) Click "Plot Distributions" to generate agreement figures.
%   5) Select a dataset and click "Load EEG", then use Replay controls.

function ratertool()
gui_version = 'v0.1';
addpath(fileparts(mfilename('fullpath')));
bgblue = [0.66 0.76 1.00];
btnblue = [0.93 0.96 1];
txtblue = [0 0 0.4];

state = struct();
state.raters = struct('name', {}, 'file', {}, 'map', {});
state.datasets = {};
state.metrics = struct();
state.dataRoot = '';
state.useEegForKappa = false;
state.eeg = [];
state.eegDataset = '';
state.currentEpoch = 1;
state.eegInfoCache = containers.Map('KeyType', 'char', 'ValueType', 'any');

hf = figure('Units', 'Normalized', ...
    'Position', [0.2 0.05 0.6 0.9], ...
    'Menu', 'none', ...
    'Color', bgblue, ...
    'Name', ['RaterTool ', gui_version], ...
    'NumberTitle', 'off');

ui = struct();
ui.title1 = uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.35 0.95 0.2 0.04], ...
    'Style', 'text', ...
    'String', 'RaterTool', ...
    'BackgroundColor', bgblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 16, ...
    'HorizontalAlignment', 'right', ...
    'FontWeight', 'bold');
ui.title2 = uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.55 0.95 0.19 0.04], ...
    'Style', 'text', ...
    'String', gui_version, ...
    'BackgroundColor', bgblue, ...
    'ForegroundColor', txtblue, ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 10);

ui.panelInputs = uipanel('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.02 0.80 0.96 0.14], ...
    'BackgroundColor', bgblue, ...
    'Title', 'Inputs', ...
    'ForegroundColor', txtblue);

ui.loadFiles = uicontrol('Parent', ui.panelInputs, 'Units', 'Normalized', ...
    'Position', [0.60 0.62 0.18 0.30], ...
    'Style', 'pushbutton', ...
    'String', 'Load Rater Files', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 11, ...
    'Callback', @loadFilesCmd);

ui.compute = uicontrol('Parent', ui.panelInputs, 'Units', 'Normalized', ...
    'Position', [0.80 0.62 0.18 0.30], ...
    'Style', 'pushbutton', ...
    'String', 'Compute Agreement', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 11, ...
    'Callback', @computeCmd);

ui.dataRoot = uicontrol('Parent', ui.panelInputs, 'Units', 'Normalized', ...
    'Position', [0.60 0.30 0.30 0.25], ...
    'Style', 'edit', ...
    'String', 'Data root path', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10);

ui.dataRootBrowse = uicontrol('Parent', ui.panelInputs, 'Units', 'Normalized', ...
    'Position', [0.92 0.30 0.06 0.25], ...
    'Style', 'pushbutton', ...
    'String', '...', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 11, ...
    'Callback', @browseDataRootCmd);

ui.useEegKappa = uicontrol('Parent', ui.panelInputs, 'Units', 'Normalized', ...
    'Position', [0.60 0.05 0.38 0.20], ...
    'Style', 'checkbox', ...
    'String', 'Use EEG metadata for kappa (slower)', ...
    'BackgroundColor', bgblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Value', 0, ...
    'Callback', @toggleEegKappaCmd);

ui.raterTable = uitable('Parent', ui.panelInputs, 'Units', 'Normalized', ...
    'Position', [0.02 0.05 0.56 0.90], ...
    'Data', {}, ...
    'ColumnName', {'File', 'Rater Label'}, ...
    'ColumnEditable', [false true], ...
    'ColumnWidth', {260 120}, ...
    'CellEditCallback', @raterTableEditCmd, ...
    'BackgroundColor', [btnblue; btnblue]);

ui.panelSummary = uipanel('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.02 0.44 0.96 0.34], ...
    'BackgroundColor', bgblue, ...
    'Title', 'Summary', ...
    'ForegroundColor', txtblue);

ui.summaryTable = uitable('Parent', ui.panelSummary, 'Units', 'Normalized', ...
    'Position', [0.02 0.10 0.72 0.86], ...
    'Data', {}, ...
    'ColumnName', {}, ...
    'ColumnEditable', false, ...
    'BackgroundColor', [btnblue; btnblue]);

ui.lowAgreementLabel = uicontrol('Parent', ui.panelSummary, 'Units', 'Normalized', ...
    'Position', [0.76 0.86 0.22 0.10], ...
    'Style', 'text', ...
    'String', 'Top Disagreements', ...
    'BackgroundColor', bgblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'FontWeight', 'bold');

ui.lowAgreementList = uicontrol('Parent', ui.panelSummary, 'Units', 'Normalized', ...
    'Position', [0.76 0.34 0.22 0.52], ...
    'Style', 'listbox', ...
    'String', {'(none)'}, ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 9, ...
    'Callback', @lowAgreementSelectCmd);

ui.pairwiseBtn = uicontrol('Parent', ui.panelSummary, 'Units', 'Normalized', ...
    'Position', [0.76 0.16 0.22 0.10], ...
    'Style', 'pushbutton', ...
    'String', 'Pairwise Details', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'Callback', @showPairwiseDetailsCmd);

ui.overallText = uicontrol('Parent', ui.panelSummary, 'Units', 'Normalized', ...
    'Position', [0.76 0.02 0.22 0.16], ...
    'Style', 'text', ...
    'String', 'Overall: NA', ...
    'BackgroundColor', bgblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 9, ...
    'HorizontalAlignment', 'left');
ui.panelPlots = uipanel('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.02 0.34 0.96 0.08], ...
    'BackgroundColor', bgblue, ...
    'Title', 'Figures', ...
    'ForegroundColor', txtblue);

ui.plotDist = uicontrol('Parent', ui.panelPlots, 'Units', 'Normalized', ...
    'Position', [0.02 0.20 0.18 0.60], ...
    'Style', 'pushbutton', ...
    'String', 'Plot Distributions', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Callback', @plotDistributionsCmd);

ui.plotHeatmap = uicontrol('Parent', ui.panelPlots, 'Units', 'Normalized', ...
    'Position', [0.22 0.20 0.18 0.60], ...
    'Style', 'pushbutton', ...
    'String', 'Plot Rater Heatmap', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Callback', @plotHeatmapCmd);

ui.plotDataset = uicontrol('Parent', ui.panelPlots, 'Units', 'Normalized', ...
    'Position', [0.42 0.20 0.18 0.60], ...
    'Style', 'pushbutton', ...
    'String', 'Plot Dataset Bars', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Callback', @plotDatasetBarsCmd);

ui.exportDir = uicontrol('Parent', ui.panelPlots, 'Units', 'Normalized', ...
    'Position', [0.62 0.25 0.26 0.50], ...
    'Style', 'edit', ...
    'String', 'Export dir', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10);

ui.exportFigures = uicontrol('Parent', ui.panelPlots, 'Units', 'Normalized', ...
    'Position', [0.90 0.20 0.08 0.60], ...
    'Style', 'pushbutton', ...
    'String', 'Export', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Callback', @exportFiguresCmd);

ui.panelReplay = uipanel('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.02 0.02 0.96 0.30], ...
    'BackgroundColor', bgblue, ...
    'Title', 'Replay / Inspection', ...
    'ForegroundColor', txtblue);

ui.datasetPopup = uicontrol('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.02 0.85 0.30 0.12], ...
    'Style', 'popupmenu', ...
    'String', {'(no datasets)'}, ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Callback', @datasetSelectCmd);

ui.loadEeg = uicontrol('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.34 0.85 0.12 0.12], ...
    'Style', 'pushbutton', ...
    'String', 'Load EEG', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Callback', @loadEegCmd);

ui.openViewer = uicontrol('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.48 0.85 0.12 0.12], ...
    'Style', 'pushbutton', ...
    'String', 'Open Viewer', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Callback', @openEegViewerCmd);

ui.channelInspect = uicontrol('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.62 0.85 0.16 0.12], ...
    'Style', 'pushbutton', ...
    'String', 'Channel Inspect', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Callback', @channelInspectCmd);

ui.icInspect = uicontrol('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.80 0.85 0.16 0.12], ...
    'Style', 'pushbutton', ...
    'String', 'IC Inspect', ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 10, ...
    'Callback', @icInspectCmd);

ui.raterList = uicontrol('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.02 0.10 0.30 0.70], ...
    'Style', 'listbox', ...
    'String', {'(no raters)'}, ...
    'Max', 2, ...
    'Min', 0, ...
    'Value', [], ...
    'BackgroundColor', btnblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 9, ...
    'Callback', @replaySelectionChangedCmd);

ui.epochText = uicontrol('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.34 0.70 0.28 0.12], ...
    'Style', 'text', ...
    'String', 'Epoch: NA', ...
    'BackgroundColor', bgblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 9, ...
    'HorizontalAlignment', 'left');

ui.rejectionText = uicontrol('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.34 0.58 0.28 0.12], ...
    'Style', 'text', ...
    'String', 'Rejected by: NA', ...
    'BackgroundColor', bgblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 9, ...
    'HorizontalAlignment', 'left');

ui.statusText = uicontrol('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.34 0.46 0.28 0.12], ...
    'Style', 'text', ...
    'String', 'Status: idle', ...
    'BackgroundColor', bgblue, ...
    'ForegroundColor', txtblue, ...
    'FontSize', 9, ...
    'HorizontalAlignment', 'left');

ui.axes = axes('Parent', ui.panelReplay, 'Units', 'Normalized', ...
    'Position', [0.64 0.12 0.34 0.70], ...
    'Color', [1 1 1], ...
    'Visible', 'off');
text(0.5, 0.5, 'Use Open Viewer to inspect epochs', ...
    'Parent', ui.axes, 'HorizontalAlignment', 'center');
    function loadFilesCmd(~, ~)
        [files, path] = uigetfile({'*.csv;*.xlsx;*.xls', 'Rater files (*.csv, *.xlsx, *.xls)'}, ...
            'Select rater files', 'MultiSelect', 'on');
        if isequal(files, 0)
            return
        end
        if ischar(files)
            files = {files};
        end
        updateStatus('Loading rater files...');
        state.raters = struct('name', {}, 'file', {}, 'map', {});
        for i = 1:numel(files)
            filePath = fullfile(path, files{i});
            try
                rater = parseRaterFile(filePath);
                state.raters(end+1) = rater; %#ok<AGROW>
            catch me
                warndlg(['Failed to load ', filePath, ': ', me.message], 'RaterTool');
            end
        end
        updateRaterTable();
        updateStatus('Rater files loaded.');
    end

    function updateRaterTable()
        if isempty(state.raters)
            set(ui.raterTable, 'Data', {});
            set(ui.raterList, 'String', {'(no raters)'}, 'Value', []);
            return
        end
        data = cell(numel(state.raters), 2);
        for i = 1:numel(state.raters)
            data{i, 1} = char(state.raters(i).file);
            data{i, 2} = char(state.raters(i).name);
        end
        set(ui.raterTable, 'Data', data);
        set(ui.raterList, 'String', cellstr(string({state.raters.name})), 'Value', 1:numel(state.raters));
    end

    function raterTableEditCmd(~, event)
        if isempty(state.raters)
            return
        end
        row = event.Indices(1);
        if row <= numel(state.raters)
            state.raters(row).name = string(event.NewData);
            updateRaterTable();
        end
    end

    function browseDataRootCmd(~, ~)
        dataPath = uigetdir(pwd, 'Select EEG data root');
        if isequal(dataPath, 0)
            return
        end
        set(ui.dataRoot, 'String', dataPath);
        state.dataRoot = dataPath;
    end

    function toggleEegKappaCmd(src, ~)
        state.useEegForKappa = logical(get(src, 'Value'));
    end

    function computeCmd(~, ~)
        if isempty(state.raters)
            warndlg('Load rater files first.', 'RaterTool');
            return
        end
        updateStatus('Computing agreement...');
        state.dataRoot = strtrim(get(ui.dataRoot, 'String'));
        state.metrics = computeAgreementMetrics();
        updateSummaryTable();
        updateDatasetPopup();
        updateStatus('Agreement computed.');
    end

    function updateSummaryTable()
        if ~isfield(state.metrics, 'summaryTableData')
            set(ui.summaryTable, 'Data', {}, 'ColumnName', {});
            return
        end
        set(ui.summaryTable, 'Data', state.metrics.summaryTableData, ...
            'ColumnName', state.metrics.summaryTableColumns);
        set(ui.lowAgreementList, 'String', state.metrics.lowAgreementList, 'Value', 1);
        set(ui.overallText, 'String', state.metrics.overallText);
    end

    function updateDatasetPopup()
        if isempty(state.datasets)
            set(ui.datasetPopup, 'String', {'(no datasets)'}, 'Value', 1);
            return
        end
        set(ui.datasetPopup, 'String', state.datasets, 'Value', 1);
    end

    function lowAgreementSelectCmd(~, ~)
        items = get(ui.lowAgreementList, 'String');
        if isempty(items) || strcmp(items{1}, '(none)')
            return
        end
        idx = get(ui.lowAgreementList, 'Value');
        if idx <= numel(items)
            dataset = extractBefore(items{idx}, ' | ');
            selectDatasetInPopup(dataset);
        end
    end

    function showPairwiseDetailsCmd(~, ~)
        dataset = getSelectedDataset();
        if isempty(dataset)
            warndlg('Select a dataset first.', 'RaterTool');
            return
        end
        [activeRaters, decisions] = getDecisionsForDataset(dataset);
        if numel(activeRaters) < 2
            warndlg('Need at least two raters for pairwise details.', 'RaterTool');
            return
        end
        pairs = nchoosek(1:numel(activeRaters), 2);
        rows = size(pairs, 1);
        data = cell(rows, 14);
        for i = 1:rows
            r1 = activeRaters(pairs(i, 1));
            r2 = activeRaters(pairs(i, 2));
            data{i, 1} = char(state.raters(r1).name);
            data{i, 2} = char(state.raters(r2).name);
            [jac, f1, prec, rec] = compareSets(decisions{pairs(i, 1)}.rejectedTrials, decisions{pairs(i, 2)}.rejectedTrials);
            data{i, 3} = round(jac, 4);
            data{i, 4} = round(f1, 4);
            data{i, 5} = round(prec, 4);
            data{i, 6} = round(rec, 4);
            [jac, f1, prec, rec] = compareSets(decisions{pairs(i, 1)}.interpolatedChannels, decisions{pairs(i, 2)}.interpolatedChannels);
            data{i, 7} = round(jac, 4);
            data{i, 8} = round(f1, 4);
            data{i, 9} = round(prec, 4);
            data{i, 10} = round(rec, 4);
            [jac, f1, prec, rec] = compareSets(decisions{pairs(i, 1)}.removedICs, decisions{pairs(i, 2)}.removedICs);
            data{i, 11} = round(jac, 4);
            data{i, 12} = round(f1, 4);
            data{i, 13} = round(prec, 4);
            data{i, 14} = round(rec, 4);
        end
        fig = figure('Color', [1 1 1], 'Name', ['Pairwise: ', dataset]);
        uitable('Parent', fig, 'Units', 'Normalized', ...
            'Position', [0.02 0.02 0.96 0.96], ...
            'Data', data, ...
            'ColumnName', {'Rater A', 'Rater B', ...
                'Trials_J', 'Trials_F1', 'Trials_P', 'Trials_R', ...
                'Chan_J', 'Chan_F1', 'Chan_P', 'Chan_R', ...
                'ICs_J', 'ICs_F1', 'ICs_P', 'ICs_R'}, ...
            'ColumnEditable', false);
    end

    function selectDatasetInPopup(dataset)
        items = get(ui.datasetPopup, 'String');
        if isempty(items)
            return
        end
        idx = find(strcmp(items, dataset), 1);
        if ~isempty(idx)
            set(ui.datasetPopup, 'Value', idx);
            datasetSelectCmd();
        end
    end

    function datasetSelectCmd(~, ~)
        updateReplayPlot(false);
    end

    function replaySelectionChangedCmd(~, ~)
        updateReplayPlot(false);
    end

    function loadEegCmd(~, ~)
        dataset = getSelectedDataset();
        if isempty(dataset)
            warndlg('Select a dataset first.', 'RaterTool');
            return
        end
        if isempty(state.dataRoot) || ~isfolder(state.dataRoot)
            warndlg('Set a valid data root path first.', 'RaterTool');
            return
        end
        updateStatus('Loading EEG (read-only)...');
        [eeg, msg] = loadEegForDataset(dataset, state.dataRoot);
        if isempty(eeg)
            warndlg(msg, 'RaterTool');
            updateStatus('EEG load failed.');
            return
        end
        state.eeg = eeg;
        state.eegDataset = dataset;
        state.currentEpoch = 1;
        updateStatus('EEG loaded.');
        updateReplayPlot(false);
        openEegViewerCmd();
    end

    function openEegViewerCmd(~, ~)
        dataset = getSelectedDataset();
        if isempty(dataset)
            warndlg('Select a dataset first.', 'RaterTool');
            return
        end
        if isempty(state.eeg) || ~strcmp(state.eegDataset, dataset)
            warndlg('Load EEG for this dataset first.', 'RaterTool');
            return
        end
        [activeRaters, decisions] = getActiveRaterDecisions(dataset);
        if isempty(activeRaters)
            warndlg('Select at least one rater.', 'RaterTool');
            return
        end
        launchEegViewer(state.eeg, dataset, activeRaters, decisions);
    end

    function channelInspectCmd(~, ~)
        dataset = getSelectedDataset();
        if isempty(dataset)
            warndlg('Select a dataset first.', 'RaterTool');
            return
        end
        if isempty(state.eeg) || ~strcmp(state.eegDataset, dataset)
            warndlg('Load EEG for this dataset first.', 'RaterTool');
            return
        end
        if ~isfield(state.eeg, 'chanlocs') || isempty(state.eeg.chanlocs)
            warndlg('No channel locations found in EEG.', 'RaterTool');
            return
        end
        labels = {state.eeg.chanlocs.labels};
        if isempty(labels)
            labels = arrayfun(@(x) sprintf('Chan %d', x), 1:state.eeg.nbchan, 'UniformOutput', false);
        end
        list = cell(numel(labels), 1);
        for i = 1:numel(labels)
            list{i} = sprintf('%d - %s', i, labels{i});
        end
        [idx, ok] = listdlg('ListString', list, 'SelectionMode', 'multiple', ...
            'PromptString', 'Select channels to inspect:', 'ListSize', [260 300]);
        if ~ok || isempty(idx)
            return
        end
        if exist('pop_prop', 'file')
            for k = 1:numel(idx)
                try
                    pop_prop(state.eeg, 1, idx(k), NaN, {});
                catch me
                    warndlg(['Failed to open channel properties: ', me.message], 'RaterTool');
                    return
                end
            end
        else
            warndlg('pop_prop not found on path (EEGLAB).', 'RaterTool');
        end
    end

    function icInspectCmd(~, ~)
        dataset = getSelectedDataset();
        if isempty(dataset)
            warndlg('Select a dataset first.', 'RaterTool');
            return
        end
        if isempty(state.eeg) || ~strcmp(state.eegDataset, dataset)
            warndlg('Load EEG for this dataset first.', 'RaterTool');
            return
        end
        if ~isfield(state.eeg, 'icaweights') || isempty(state.eeg.icaweights)
            warndlg('No ICA weights found in EEG.', 'RaterTool');
            return
        end
        if ~exist('pop_selectcomps', 'file')
            warndlg('pop_selectcomps not found on path (EEGLAB).', 'RaterTool');
            return
        end

        raterNames = cellstr(string({state.raters.name}));
        promptList = [raterNames(:); {'Union of selected raters'}; {'All ICs (1:n)'}; {'ICs 1:35'}];
        [idx, ok] = listdlg('ListString', promptList, 'SelectionMode', 'single', ...
            'PromptString', 'Choose IC set to inspect:', 'ListSize', [260 250]);
        if ~ok || isempty(idx)
            return
        end
        nRaters = numel(state.raters);
        comps = [];
        if idx <= nRaters
            comps = getRaterRemovedICs(idx, dataset);
        elseif idx == nRaters + 1
            comps = getUnionRemovedICs(dataset);
        elseif idx == nRaters + 2
            comps = 1:size(state.eeg.icaweights, 1);
        else
            comps = 1:min(35, size(state.eeg.icaweights, 1));
        end
        comps = unique(comps);
        comps = comps(comps >= 1 & comps <= size(state.eeg.icaweights, 1));
        if isempty(comps)
            comps = 1:min(35, size(state.eeg.icaweights, 1));
        end
        try
            ensureEEGInBase(state.eeg);
            pop_selectcomps(state.eeg, comps);
        catch me
            warndlg(['Failed to open IC inspector: ', me.message], 'RaterTool');
        end
    end

    function comps = getRaterRemovedICs(raterIdx, dataset)
        comps = [];
        if raterIdx < 1 || raterIdx > numel(state.raters)
            return
        end
        if isKey(state.raters(raterIdx).map, dataset)
            entry = state.raters(raterIdx).map(dataset);
            if isfield(entry, 'removedICs') && ~isempty(entry.removedICs)
                comps = entry.removedICs(:)';
            end
        end
    end

    function comps = getUnionRemovedICs(dataset)
        comps = [];
        for r = 1:numel(state.raters)
            if isKey(state.raters(r).map, dataset)
                entry = state.raters(r).map(dataset);
                if isfield(entry, 'removedICs') && ~isempty(entry.removedICs)
                    comps = [comps, entry.removedICs(:)']; %#ok<AGROW>
                end
            end
        end
        comps = unique(comps);
    end

    function ensureEEGInBase(eeg)
        try
            assignin('base', 'EEG', eeg);
        catch
        end
        try
            evalin('base', 'global EEG;');
        catch
        end
        try
            global EEG; %#ok<TLEV>
            EEG = eeg;
        catch
        end
    end

    function dataset = getSelectedDataset()
        items = get(ui.datasetPopup, 'String');
        if isempty(items) || strcmp(items{1}, '(no datasets)')
            dataset = '';
            return
        end
        idx = get(ui.datasetPopup, 'Value');
        dataset = items{idx};
    end

    function updateReplayPlot(forceLoad)
        dataset = getSelectedDataset();
        if isempty(dataset)
            cla(ui.axes);
            title(ui.axes, 'EEG Viewer');
            return
        end
        if isempty(state.eeg) || ~strcmp(state.eegDataset, dataset)
            if forceLoad
                return
            end
            cla(ui.axes);
            title(ui.axes, 'EEG Viewer');
            set(ui.epochText, 'String', 'Epoch: NA');
            set(ui.rejectionText, 'String', 'Rejected by: NA');
            return
        end
        if state.eeg.trials < 1
            return
        end
        if state.currentEpoch < 1 || state.currentEpoch > state.eeg.trials
            state.currentEpoch = 1;
        end
        [activeRaters, decisions] = getActiveRaterDecisions(dataset);
        [rejNames, keepNames, missingNames] = getEpochStatus(activeRaters, decisions, state.currentEpoch);
        epochStr = sprintf('Epoch: %d / %d', state.currentEpoch, state.eeg.trials);
        set(ui.epochText, 'String', epochStr);
        rejText = sprintf('Rejected by: %s', joinNames(rejNames));
        keepText = sprintf(' Kept by: %s', joinNames(keepNames));
        missingText = '';
        if ~isempty(missingNames)
            missingText = [' No data: ', joinNames(missingNames)];
        end
        set(ui.rejectionText, 'String', [rejText, ';', keepText, ';', missingText]);

        cla(ui.axes);
        title(ui.axes, 'EEG Viewer');
    end
    function [activeRaters, decisions] = getActiveRaterDecisions(dataset)
        if isempty(state.raters)
            activeRaters = [];
            decisions = {};
            return
        end
        selected = get(ui.raterList, 'Value');
        if isempty(selected)
            selected = 1:numel(state.raters);
        end
        activeRaters = selected;
        decisions = cell(1, numel(activeRaters));
        for i = 1:numel(activeRaters)
            r = activeRaters(i);
            if isKey(state.raters(r).map, dataset)
                decisions{i} = state.raters(r).map(dataset);
            else
                decisions{i} = struct('rejectedTrials', [], 'interpolatedChannels', {}, 'removedICs', []);
            end
        end
    end

    function [rejNames, keepNames, missingNames] = getEpochStatus(activeRaters, decisions, epochIdx)
        rejNames = {};
        keepNames = {};
        missingNames = {};
        for i = 1:numel(activeRaters)
            rIdx = activeRaters(i);
            name = char(state.raters(rIdx).name);
            if ~isfield(decisions{i}, 'rejectedTrials')
                missingNames{end+1} = name; %#ok<AGROW>
                continue
            end
            if isempty(decisions{i}.rejectedTrials) && ~isKey(state.raters(rIdx).map, getSelectedDataset())
                missingNames{end+1} = name; %#ok<AGROW>
                continue
            end
            if ismember(epochIdx, decisions{i}.rejectedTrials)
                rejNames{end+1} = name; %#ok<AGROW>
            else
                keepNames{end+1} = name; %#ok<AGROW>
            end
        end
    end

    function launchEegViewer(eeg, dataset, activeRaters, decisions)
        if isempty(eeg) || ~isfield(eeg, 'pnts')
            warndlg('EEG data is missing epoch information.', 'RaterTool');
            return
        end
        totalEpochs = eeg.trials;
        if isempty(totalEpochs) || totalEpochs < 1
            warndlg('EEG has no epochs.', 'RaterTool');
            return
        end
        nbchan = [];
        if isfield(eeg, 'nbchan') && ~isempty(eeg.nbchan)
            nbchan = eeg.nbchan;
        else
            nbchan = size(eeg.data, 1);
        end
        winrej = buildWinrejForRaters(decisions, totalEpochs, eeg.pnts, nbchan);
        eloc = buildElocForLabels(eeg);
        raterBadChans = buildRaterBadChans(decisions, eeg);
        raterColors = getRaterColors(numel(decisions));
        titleStr = ['RaterTool: ', dataset];
        if exist('ratertool_eegplot', 'file')
            try
                ratertool_eegplot(eeg.data, 'srate', eeg.srate, 'title', titleStr, ...
                    'winrej', winrej, 'limits', [eeg.xmin eeg.xmax]*1000, ...
                    'spacing', 72, 'trialstag', eeg.pnts, 'eloc_file', eloc, ...
                    'raterbadchans', raterBadChans, 'ratercolors', raterColors);
                fig = gcf;
                addRaterLegend(fig, activeRaters);
            catch me
                warndlg(['Failed to open viewer: ', me.message], 'RaterTool');
            end
        elseif exist('pop_eegplot', 'file')
            try
                pop_eegplot(eeg, 1, 1, 0);
                warning('ratertool_eegplot not found. Opened pop_eegplot without rater overlays.');
            catch me
                warndlg(['Failed to open pop_eegplot: ', me.message], 'RaterTool');
            end
        else
            warndlg('EEGLAB eegplot not found on path.', 'RaterTool');
        end
    end

    function winrej = buildWinrejForRaters(decisions, totalEpochs, pntsPerEpoch, nbchan)
        nRaters = numel(decisions);
        if nRaters == 0
            winrej = [];
            return
        end
        if nargin < 4 || isempty(nbchan) || isnan(nbchan)
            nbchan = 0;
        end
        colors = getRaterColors(nRaters);
        winrej = [];
        for r = 1:nRaters
            epochs = decisions{r}.rejectedTrials;
            if isempty(epochs)
                continue
            end
            epochs = epochs(epochs >= 1 & epochs <= totalEpochs);
            if isempty(epochs)
                continue
            end
            for e = 1:numel(epochs)
                startP = (epochs(e) - 1) * pntsPerEpoch + 1;
                endP = epochs(e) * pntsPerEpoch;
                winrej = [winrej; startP endP colors(r, :) zeros(1, nbchan)]; %#ok<AGROW>
            end
        end
    end

    function eloc = buildElocForLabels(eeg)
        eloc = [];
        if ~isfield(eeg, 'chanlocs') || isempty(eeg.chanlocs)
            return
        end
        eloc = eeg.chanlocs;
        if isfield(eloc, 'badchan')
            for i = 1:numel(eloc)
                eloc(i).badchan = 0;
            end
        end
    end

    function raterBad = buildRaterBadChans(decisions, eeg)
        raterBad = cell(numel(decisions), 1);
        if ~isfield(eeg, 'chanlocs') || isempty(eeg.chanlocs)
            return
        end
        labels = strings(numel(eeg.chanlocs), 1);
        for i = 1:numel(eeg.chanlocs)
            labels(i) = upper(string(eeg.chanlocs(i).labels));
        end
        for r = 1:numel(decisions)
            if ~isfield(decisions{r}, 'interpolatedChannels') || isempty(decisions{r}.interpolatedChannels)
                raterBad{r} = [];
                continue
            end
            ch = decisions{r}.interpolatedChannels;
            if iscell(ch) || isstring(ch)
                tokens = string(ch(:));
            elseif isnumeric(ch)
                tokens = string(ch(:));
            else
                tokens = strings(0, 1);
            end
            tokens = upper(strtrim(tokens));
            tokens = tokens(tokens ~= "");
            idx = mapChannelsToIndex(tokens, labels);
            raterBad{r} = unique(idx(idx >= 1 & idx <= numel(labels)));
        end
    end

    function colors = getRaterColors(n)
        base = [0.85 0.2 0.2;
            0.2 0.6 0.2;
            0.2 0.2 0.85;
            0.85 0.6 0.2;
            0.6 0.2 0.85;
            0.2 0.7 0.7;
            0.5 0.5 0.5;
            0.85 0.4 0.4];
        if n <= size(base, 1)
            colors = base(1:n, :);
        else
            colors = hsv(n);
        end
    end


    function addRaterLegend(fig, activeRaters)
        if isempty(activeRaters)
            return
        end
        colors = getRaterColors(numel(activeRaters));
        panel = uipanel('Parent', fig, 'Units', 'normalized', ...
            'Position', [0.82 0.02 0.16 0.18], ...
            'Title', 'Raters', ...
            'BackgroundColor', [1 1 1]);
        for i = 1:numel(activeRaters)
            rIdx = activeRaters(i);
            name = char(state.raters(rIdx).name);
            ypos = 1 - i * (1 / max(numel(activeRaters), 1));
            uicontrol('Parent', panel, 'Style', 'text', ...
                'Units', 'normalized', ...
                'Position', [0.05 ypos 0.90 0.20], ...
                'String', name, ...
                'BackgroundColor', colors(i, :), ...
                'ForegroundColor', [1 1 1]);
        end
    end

    function plotDistributionsCmd(~, ~)
        if ~isfield(state.metrics, 'datasetMetrics')
            warndlg('Compute agreement first.', 'RaterTool');
            return
        end
        metrics = state.metrics.datasetMetrics;
        figure('Color', [1 1 1], 'Name', 'Agreement Distributions');
        data = [metrics.trialsJaccardMean, metrics.channelsJaccardMean, metrics.icsJaccardMean];
        boxplot(data, 'Labels', {'Trials', 'Channels', 'ICs'});
        ylabel('Jaccard (mean pairwise)');
        title('Agreement Distributions');
    end

    function plotHeatmapCmd(~, ~)
        if ~isfield(state.metrics, 'pairwise')
            warndlg('Compute agreement first.', 'RaterTool');
            return
        end
        labels = {state.raters.name};
        figure('Color', [1 1 1], 'Name', 'Pairwise Rater Agreement');
        subplot(1, 3, 1);
        imagesc(state.metrics.pairwise.trialsJaccardMean);
        axis square;
        colorbar;
        title('Trials Jaccard');
        set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels, ...
            'YTick', 1:numel(labels), 'YTickLabel', labels);
        subplot(1, 3, 2);
        imagesc(state.metrics.pairwise.channelsJaccardMean);
        axis square;
        colorbar;
        title('Channels Jaccard');
        set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels, ...
            'YTick', 1:numel(labels), 'YTickLabel', labels);
        subplot(1, 3, 3);
        imagesc(state.metrics.pairwise.icsJaccardMean);
        axis square;
        colorbar;
        title('ICs Jaccard');
        set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels, ...
            'YTick', 1:numel(labels), 'YTickLabel', labels);
    end

    function plotDatasetBarsCmd(~, ~)
        if ~isfield(state.metrics, 'datasetMetrics')
            warndlg('Compute agreement first.', 'RaterTool');
            return
        end
        dataset = getSelectedDataset();
        if isempty(dataset)
            warndlg('Select a dataset first.', 'RaterTool');
            return
        end
        idx = find(strcmp(state.metrics.datasetMetrics.dataset, dataset), 1);
        if isempty(idx)
            return
        end
        vals = [state.metrics.datasetMetrics.trialsGroupJaccard(idx), ...
                state.metrics.datasetMetrics.channelsGroupJaccard(idx), ...
                state.metrics.datasetMetrics.icsGroupJaccard(idx)];
        figure('Color', [1 1 1], 'Name', ['Dataset Agreement: ', dataset]);
        bar(vals);
        ylim([0 1]);
        set(gca, 'XTickLabel', {'Trials', 'Channels', 'ICs'});
        ylabel('Group Jaccard');
        title(['Agreement (', dataset, ')']);
    end

    function exportFiguresCmd(~, ~)
        exportDir = strtrim(get(ui.exportDir, 'String'));
        if isempty(exportDir) || strcmpi(exportDir, 'Export dir')
            exportDir = pwd;
        end
        if ~isfolder(exportDir)
            warndlg('Export directory not found.', 'RaterTool');
            return
        end
        figs = findall(0, 'Type', 'figure');
        figs = figs(figs ~= hf);
        if isempty(figs)
            warndlg('No figures to export.', 'RaterTool');
            return
        end
        for i = 1:numel(figs)
            f = figs(i);
            name = get(f, 'Name');
            if isempty(name)
                name = ['Figure_', num2str(i)];
            end
            safeName = regexprep(name, '[^a-zA-Z0-9_-]', '_');
            pngPath = fullfile(exportDir, [safeName, '.png']);
            figPath = fullfile(exportDir, [safeName, '.fig']);
            try
                saveas(f, pngPath);
                saveas(f, figPath);
            catch
                warning('Failed to export figure: %s', name);
            end
        end
        updateStatus(['Exported ', num2str(numel(figs)), ' figure(s).']);
    end

    function updateStatus(msg)
        set(ui.statusText, 'String', ['Status: ', msg]);
        drawnow;
    end

    function rater = parseRaterFile(filePath)
        [~, name, ext] = fileparts(filePath);
        rater = struct();
        rater.name = string(name);
        rater.file = filePath;
        rater.map = containers.Map('KeyType', 'char', 'ValueType', 'any');
        ext = lower(ext);
        if strcmp(ext, '.csv')
            T = readtable(filePath, 'TextType', 'string', 'VariableNamingRule', 'preserve');
        else
            T = readtable(filePath, 'FileType', 'spreadsheet', 'TextType', 'string', 'VariableNamingRule', 'preserve');
        end
        col = struct();
        col.dataset = getTableColumn(T, {'dataset'});
        col.rejected = getTableColumn(T, {'Rejected trials', 'Rejected_trials', 'RejectedTrials'});
        col.channels = getTableColumn(T, {'Interpolated Channels', 'Interpolated_Channels', 'InterpolatedChannels'});
        col.ics = getTableColumn(T, {'Removed ICs', 'Removed_ICs', 'RemovedICs'});
        col.comments = getTableColumn(T, {'Comments', 'Comment'});
        col.rating = getTableColumn(T, {'Rating'});
        col.qBefore = getTableColumn(T, {'Quality Score Before', 'Quality_Score_Before', 'QualityScoreBefore'});
        col.qAfter = getTableColumn(T, {'Quality Score After', 'Quality_Score_After', 'QualityScoreAfter'});
        for i = 1:height(T)
            datasetId = strtrim(string(col.dataset(i)));
            if datasetId == "" || ismissing(datasetId)
                continue
            end
            entry = struct();
            entry.dataset = char(datasetId);
            entry.rejectedTrials = parseIndexSet(col.rejected(i));
            entry.interpolatedChannels = parseChannelSet(col.channels(i));
            entry.removedICs = parseIndexSet(col.ics(i));
            entry.comments = string(col.comments(i));
            entry.rating = string(col.rating(i));
            entry.qualityBefore = parseScalar(col.qBefore(i));
            entry.qualityAfter = parseScalar(col.qAfter(i));
            rater.map(entry.dataset) = entry;
        end
    end

    function column = getTableColumn(T, candidates)
        vnames = T.Properties.VariableNames;
        vnamesNorm = sanitizeNames(vnames);
        column = [];
        for i = 1:numel(candidates)
            target = sanitizeNames(candidates{i});
            idx = find(strcmp(vnamesNorm, target), 1);
            if ~isempty(idx)
                column = T.(vnames{idx});
                return
            end
        end
        if isempty(column)
            column = strings(height(T), 1);
        end
    end

    function names = sanitizeNames(namesIn)
        if ischar(namesIn)
            namesIn = {namesIn};
        end
        names = cell(size(namesIn));
        for i = 1:numel(namesIn)
            names{i} = lower(regexprep(namesIn{i}, '[^a-z0-9]', ''));
        end
        if iscell(namesIn)
            names = string(names);
        end
    end

    function idx = parseIndexSet(value)
        idx = [];
        if isempty(value)
            return
        end
        if isnumeric(value)
            value = value(~isnan(value));
            idx = unique(value(:))';
            return
        end
        str = strtrim(string(value));
        if str == "" || ismissing(str)
            return
        end
        if any(strcmpi(str, ["na", "nan", "none", "null"]))
            return
        end
        str = regexprep(char(str), '[\[\]\(\)\{\},;]', ' ');
        tokens = regexp(str, '\d+[\:\-]\d+|\d+', 'match');
        for i = 1:numel(tokens)
            tok = tokens{i};
            if contains(tok, ':') || contains(tok, '-')
                parts = regexp(tok, '\d+', 'match');
                if numel(parts) >= 2
                    a = str2double(parts{1});
                    b = str2double(parts{2});
                    if ~isnan(a) && ~isnan(b)
                        if a <= b
                            idx = [idx, a:b]; %#ok<AGROW>
                        else
                            idx = [idx, b:a]; %#ok<AGROW>
                        end
                    end
                end
            else
                val = str2double(tok);
                if ~isnan(val)
                    idx = [idx, val]; %#ok<AGROW>
                end
            end
        end
        idx = unique(idx);
    end

    function labels = parseChannelSet(value)
        labels = {};
        if isempty(value)
            return
        end
        if isnumeric(value)
            value = value(~isnan(value));
            labels = arrayfun(@(x) num2str(x), value(:)', 'UniformOutput', false);
            labels = unique(labels, 'stable');
            return
        end
        str = strtrim(string(value));
        if str == "" || ismissing(str)
            return
        end
        if any(strcmpi(str, ["na", "nan", "none", "null"]))
            return
        end
        str = regexprep(char(str), '[\[\]\(\)\{\},;]', ' ');
        tokens = regexp(str, '[A-Za-z]+[A-Za-z0-9]*|\d+[\:\-]\d+|\d+', 'match');
        out = {};
        for i = 1:numel(tokens)
            tok = tokens{i};
            if contains(tok, ':') || contains(tok, '-')
                parts = regexp(tok, '\d+', 'match');
                if numel(parts) >= 2
                    a = str2double(parts{1});
                    b = str2double(parts{2});
                    if ~isnan(a) && ~isnan(b)
                        if a <= b
                            vals = a:b;
                        else
                            vals = b:a;
                        end
                        out = [out, arrayfun(@(x) num2str(x), vals, 'UniformOutput', false)]; %#ok<AGROW>
                    end
                end
            else
                out{end+1} = upper(tok); %#ok<AGROW>
            end
        end
        labels = unique(out, 'stable');
    end

    function val = parseScalar(value)
        if isnumeric(value)
            if isempty(value) || all(isnan(value))
                val = NaN;
            else
                val = value(1);
            end
            return
        end
        str = strtrim(string(value));
        if str == "" || ismissing(str)
            val = NaN;
            return
        end
        val = str2double(str);
        if isnan(val)
            val = NaN;
        end
    end
    function metrics = computeAgreementMetrics()
        nRaters = numel(state.raters);
        datasetList = {};
        for r = 1:nRaters
            datasetList = [datasetList; keys(state.raters(r).map)']; %#ok<AGROW>
        end
        datasetList = unique(datasetList);
        state.datasets = datasetList;

        pairwise = initPairwise(nRaters);
        datasetMetrics = initDatasetMetrics(datasetList);
        qualityBefore = nan(numel(datasetList), nRaters);
        qualityAfter = nan(numel(datasetList), nRaters);

        for d = 1:numel(datasetList)
            dataset = datasetList{d};
            for r = 1:nRaters
                if isKey(state.raters(r).map, dataset)
                    entry = state.raters(r).map(dataset);
                    if isfield(entry, 'qualityBefore')
                        qualityBefore(d, r) = entry.qualityBefore;
                    end
                    if isfield(entry, 'qualityAfter')
                        qualityAfter(d, r) = entry.qualityAfter;
                    end
                end
            end
            datasetMetrics.qualityBeforeMean(d) = mean(qualityBefore(d, :), 'omitnan');
            datasetMetrics.qualityAfterMean(d) = mean(qualityAfter(d, :), 'omitnan');
            [activeRaters, decisions] = getDecisionsForDataset(dataset);
            datasetMetrics.nRaters(d) = numel(activeRaters);

            [pairStats, groupStats] = computeSetAgreement(decisions, 'rejectedTrials', dataset);
            datasetMetrics.trialsJaccardMean(d) = pairStats.jaccardMean;
            datasetMetrics.trialsF1Mean(d) = pairStats.f1Mean;
            datasetMetrics.trialsPrecisionMean(d) = pairStats.precisionMean;
            datasetMetrics.trialsRecallMean(d) = pairStats.recallMean;
            datasetMetrics.trialsKappa(d) = pairStats.kappa;
            datasetMetrics.trialsGroupJaccard(d) = groupStats.groupJaccard;
            pairwise = accumulatePairwise(pairwise, pairStats, activeRaters, 'trials');

            [pairStats, groupStats] = computeSetAgreement(decisions, 'interpolatedChannels', dataset);
            datasetMetrics.channelsJaccardMean(d) = pairStats.jaccardMean;
            datasetMetrics.channelsF1Mean(d) = pairStats.f1Mean;
            datasetMetrics.channelsPrecisionMean(d) = pairStats.precisionMean;
            datasetMetrics.channelsRecallMean(d) = pairStats.recallMean;
            datasetMetrics.channelsKappa(d) = pairStats.kappa;
            datasetMetrics.channelsGroupJaccard(d) = groupStats.groupJaccard;
            pairwise = accumulatePairwise(pairwise, pairStats, activeRaters, 'channels');

            [pairStats, groupStats] = computeSetAgreement(decisions, 'removedICs', dataset);
            datasetMetrics.icsJaccardMean(d) = pairStats.jaccardMean;
            datasetMetrics.icsF1Mean(d) = pairStats.f1Mean;
            datasetMetrics.icsPrecisionMean(d) = pairStats.precisionMean;
            datasetMetrics.icsRecallMean(d) = pairStats.recallMean;
            datasetMetrics.icsKappa(d) = pairStats.kappa;
            datasetMetrics.icsGroupJaccard(d) = groupStats.groupJaccard;
            pairwise = accumulatePairwise(pairwise, pairStats, activeRaters, 'ics');
        end

        pairwise = finalizePairwise(pairwise);
        metrics.datasetMetrics = datasetMetrics;
        metrics.pairwise = pairwise;
        metrics.iccBefore = computeICC2_1(qualityBefore);
        metrics.iccAfter = computeICC2_1(qualityAfter);
        [metrics.summaryTableData, metrics.summaryTableColumns] = buildSummaryTable(datasetMetrics);
        metrics.lowAgreementList = buildLowAgreementList(datasetMetrics);
        metrics.overallText = buildOverallText(datasetMetrics, metrics.iccBefore, metrics.iccAfter);
    end

    function [activeRaters, decisions] = getDecisionsForDataset(dataset)
        activeRaters = [];
        decisions = {};
        for r = 1:numel(state.raters)
            if isKey(state.raters(r).map, dataset)
                activeRaters(end+1) = r; %#ok<AGROW>
                decisions{end+1} = state.raters(r).map(dataset); %#ok<AGROW>
            end
        end
    end

    function pairwise = initPairwise(nRaters)
        pairwise = struct();
        pairwise.trialsSum = zeros(nRaters);
        pairwise.trialsCount = zeros(nRaters);
        pairwise.channelsSum = zeros(nRaters);
        pairwise.channelsCount = zeros(nRaters);
        pairwise.icsSum = zeros(nRaters);
        pairwise.icsCount = zeros(nRaters);
    end

    function datasetMetrics = initDatasetMetrics(datasetList)
        n = numel(datasetList);
        datasetMetrics = struct();
        datasetMetrics.dataset = datasetList;
        datasetMetrics.nRaters = zeros(n, 1);
        datasetMetrics.trialsJaccardMean = nan(n, 1);
        datasetMetrics.trialsF1Mean = nan(n, 1);
        datasetMetrics.trialsPrecisionMean = nan(n, 1);
        datasetMetrics.trialsRecallMean = nan(n, 1);
        datasetMetrics.trialsKappa = nan(n, 1);
        datasetMetrics.trialsGroupJaccard = nan(n, 1);
        datasetMetrics.channelsJaccardMean = nan(n, 1);
        datasetMetrics.channelsF1Mean = nan(n, 1);
        datasetMetrics.channelsPrecisionMean = nan(n, 1);
        datasetMetrics.channelsRecallMean = nan(n, 1);
        datasetMetrics.channelsKappa = nan(n, 1);
        datasetMetrics.channelsGroupJaccard = nan(n, 1);
        datasetMetrics.icsJaccardMean = nan(n, 1);
        datasetMetrics.icsF1Mean = nan(n, 1);
        datasetMetrics.icsPrecisionMean = nan(n, 1);
        datasetMetrics.icsRecallMean = nan(n, 1);
        datasetMetrics.icsKappa = nan(n, 1);
        datasetMetrics.icsGroupJaccard = nan(n, 1);
        datasetMetrics.qualityBeforeMean = nan(n, 1);
        datasetMetrics.qualityAfterMean = nan(n, 1);
    end

    function [pairStats, groupStats] = computeSetAgreement(decisions, fieldName, dataset)
        pairStats = struct('jaccardMean', NaN, 'f1Mean', NaN, ...
            'precisionMean', NaN, 'recallMean', NaN, ...
            'kappa', NaN, 'pairwise', []);
        groupStats = struct('groupJaccard', NaN);
        n = numel(decisions);
        if n < 2
            return
        end
        sets = cell(1, n);
        for i = 1:n
            if isfield(decisions{i}, fieldName)
                sets{i} = decisions{i}.(fieldName);
            else
                sets{i} = [];
            end
        end
        [jaccards, f1s, precisions, recalls, pairIdx] = pairwiseSetMetrics(sets);
        pairStats.jaccardMean = mean(jaccards, 'omitnan');
        pairStats.f1Mean = mean(f1s, 'omitnan');
        pairStats.precisionMean = mean(precisions, 'omitnan');
        pairStats.recallMean = mean(recalls, 'omitnan');
        pairStats.pairwise = struct('pairs', pairIdx, 'jaccard', jaccards, ...
            'precision', precisions, 'recall', recalls);
        groupStats.groupJaccard = groupJaccard(sets);
        if state.useEegForKappa
            kappa = computeKappaForDataset(sets, fieldName, dataset);
            pairStats.kappa = kappa;
        end
    end

    function pairwise = accumulatePairwise(pairwise, pairStats, activeRaters, domain)
        if isempty(pairStats.pairwise)
            return
        end
        pairs = pairStats.pairwise.pairs;
        values = pairStats.pairwise.jaccard;
        for k = 1:size(pairs, 1)
            i = activeRaters(pairs(k, 1));
            j = activeRaters(pairs(k, 2));
            switch domain
                case 'trials'
                    pairwise.trialsSum(i, j) = pairwise.trialsSum(i, j) + values(k);
                    pairwise.trialsSum(j, i) = pairwise.trialsSum(j, i) + values(k);
                    pairwise.trialsCount(i, j) = pairwise.trialsCount(i, j) + 1;
                    pairwise.trialsCount(j, i) = pairwise.trialsCount(j, i) + 1;
                case 'channels'
                    pairwise.channelsSum(i, j) = pairwise.channelsSum(i, j) + values(k);
                    pairwise.channelsSum(j, i) = pairwise.channelsSum(j, i) + values(k);
                    pairwise.channelsCount(i, j) = pairwise.channelsCount(i, j) + 1;
                    pairwise.channelsCount(j, i) = pairwise.channelsCount(j, i) + 1;
                case 'ics'
                    pairwise.icsSum(i, j) = pairwise.icsSum(i, j) + values(k);
                    pairwise.icsSum(j, i) = pairwise.icsSum(j, i) + values(k);
                    pairwise.icsCount(i, j) = pairwise.icsCount(i, j) + 1;
                    pairwise.icsCount(j, i) = pairwise.icsCount(j, i) + 1;
            end
        end
    end

    function pairwise = finalizePairwise(pairwise)
        pairwise.trialsJaccardMean = pairwise.trialsSum ./ max(pairwise.trialsCount, 1);
        pairwise.channelsJaccardMean = pairwise.channelsSum ./ max(pairwise.channelsCount, 1);
        pairwise.icsJaccardMean = pairwise.icsSum ./ max(pairwise.icsCount, 1);
        pairwise.trialsJaccardMean(pairwise.trialsCount == 0) = NaN;
        pairwise.channelsJaccardMean(pairwise.channelsCount == 0) = NaN;
        pairwise.icsJaccardMean(pairwise.icsCount == 0) = NaN;
    end

    function [jaccards, f1s, precisions, recalls, pairs] = pairwiseSetMetrics(sets)
        n = numel(sets);
        pairs = [];
        jaccards = [];
        f1s = [];
        precisions = [];
        recalls = [];
        idx = 0;
        for i = 1:n-1
            for j = i+1:n
                idx = idx + 1;
                pairs(idx, :) = [i j]; %#ok<AGROW>
                [jac, f1, prec, rec] = compareSets(sets{i}, sets{j});
                jaccards(idx, 1) = jac; %#ok<AGROW>
                f1s(idx, 1) = f1; %#ok<AGROW>
                precisions(idx, 1) = prec; %#ok<AGROW>
                recalls(idx, 1) = rec; %#ok<AGROW>
            end
        end
    end
    function [jac, f1, precision, recall] = compareSets(a, b)
        if isempty(a) && isempty(b)
            jac = 1;
            precision = 1;
            recall = 1;
            f1 = 1;
            return
        end
        if iscell(a)
            a = string(a);
        end
        if iscell(b)
            b = string(b);
        end
        if isstring(a) || isstring(b)
            a = string(a);
            b = string(b);
            inter = intersect(a, b);
            uni = union(a, b);
            jac = numel(inter) / max(numel(uni), 1);
            [precision, recall, f1] = computePRF(numel(inter), numel(a), numel(b));
        else
            inter = intersect(a, b);
            uni = union(a, b);
            jac = numel(inter) / max(numel(uni), 1);
            [precision, recall, f1] = computePRF(numel(inter), numel(a), numel(b));
        end
    end

    function [precision, recall, f1] = computePRF(interCount, countA, countB)
        if countA == 0
            precision = double(countB == 0);
        else
            precision = interCount / countA;
        end
        if countB == 0
            recall = double(countA == 0);
        else
            recall = interCount / countB;
        end
        if precision + recall == 0
            f1 = 0;
        else
            f1 = 2 * precision * recall / (precision + recall);
        end
    end

    function g = groupJaccard(sets)
        if isempty(sets)
            g = NaN;
            return
        end
        current = sets{1};
        if iscell(current)
            current = string(current);
        end
        interAll = current;
        unionAll = current;
        for i = 2:numel(sets)
            s = sets{i};
            if iscell(s)
                s = string(s);
            end
            interAll = intersect(interAll, s);
            unionAll = union(unionAll, s);
        end
        if isempty(unionAll) && isempty(interAll)
            g = 1;
        else
            g = numel(interAll) / max(numel(unionAll), 1);
        end
    end

    function kappa = computeKappaForDataset(sets, fieldName, dataset)
        kappa = NaN;
        info = getEegInfo(dataset);
        if isempty(info)
            return
        end
        total = NaN;
        if strcmp(fieldName, 'rejectedTrials')
            total = info.trials;
        elseif strcmp(fieldName, 'interpolatedChannels')
            total = info.channels;
        elseif strcmp(fieldName, 'removedICs')
            total = info.ics;
        end
        if isempty(total) || isnan(total) || total < 1
            return
        end
        bin = buildBinaryMatrix(sets, fieldName, total, info);
        if isempty(bin)
            return
        end
        if size(bin, 2) == 2
            kappa = cohensKappa(bin(:, 1), bin(:, 2));
        elseif size(bin, 2) > 2
            kappa = fleissKappa(bin);
        end
    end

    function bin = buildBinaryMatrix(sets, fieldName, total, info)
        nR = numel(sets);
        bin = zeros(total, nR);
        for i = 1:nR
            if isempty(sets{i})
                continue
            end
            if strcmp(fieldName, 'interpolatedChannels')
                idx = mapChannelsToIndex(sets{i}, info.channelLabels);
            else
                idx = sets{i};
            end
            idx = idx(idx >= 1 & idx <= total);
            bin(idx, i) = 1;
        end
    end

    function idx = mapChannelsToIndex(labels, channelLabels)
        idx = [];
        if isempty(channelLabels)
            return
        end
        if iscell(labels)
            labels = string(labels);
        end
        labels = upper(string(labels));
        for i = 1:numel(labels)
            tok = labels(i);
            val = str2double(tok);
            if ~isnan(val)
                idx(end+1) = val; %#ok<AGROW>
            else
                match = find(strcmpi(channelLabels, tok), 1);
                if ~isempty(match)
                    idx(end+1) = match; %#ok<AGROW>
                end
            end
        end
        idx = unique(idx);
    end

    function info = getEegInfo(dataset)
        if isempty(state.dataRoot) || ~isfolder(state.dataRoot)
            info = [];
            return
        end
        if isKey(state.eegInfoCache, dataset)
            info = state.eegInfoCache(dataset);
            return
        end
        [eeg, msg] = loadEegForDataset(dataset, state.dataRoot, true);
        if isempty(eeg)
            warning('EEG info not found: %s', msg);
            info = [];
            state.eegInfoCache(dataset) = info;
            return
        end
        info = struct();
        if isfield(eeg, 'trials')
            info.trials = eeg.trials;
        else
            info.trials = NaN;
        end
        if isfield(eeg, 'nbchan')
            info.channels = eeg.nbchan;
        else
            info.channels = NaN;
        end
        if isfield(eeg, 'icaweights') && ~isempty(eeg.icaweights)
            info.ics = size(eeg.icaweights, 1);
        else
            info.ics = NaN;
        end
        info.channelLabels = [];
        if isfield(eeg, 'chanlocs') && ~isempty(eeg.chanlocs)
            info.channelLabels = arrayfun(@(c) upper(string(c.labels)), eeg.chanlocs, 'UniformOutput', false);
        end
        state.eegInfoCache(dataset) = info;
    end

    function [eeg, msg] = loadEegForDataset(dataset, dataRoot, infoOnly)
        if nargin < 3
            infoOnly = false;
        end
        eeg = [];
        msg = '';
        filePath = findDatasetFile(dataRoot, dataset);
        if isempty(filePath)
            msg = 'EEG file not found for dataset.';
            return
        end
        [fileDir, fileName, fileExt] = fileparts(filePath);
        if ~strcmpi(fileExt, '.set')
            msg = 'EEG file is not a .set file.';
            return
        end
        try
            if exist('pop_loadset', 'file')
                if infoOnly
                    eeg = pop_loadset('filename', [fileName, fileExt], 'filepath', fileDir, 'loadmode', 'info');
                else
                    eeg = pop_loadset('filename', [fileName, fileExt], 'filepath', fileDir);
                end
            else
                tmp = load(filePath, '-mat');
                if isfield(tmp, 'EEG')
                    eeg = tmp.EEG;
                else
                    eeg = tmp;
                end
            end
        catch me
            eeg = [];
            msg = me.message;
        end
    end

    function filePath = findDatasetFile(dataRoot, dataset)
        dataset = char(dataset);
        if endsWith(dataset, '.set')
            candidate = fullfile(dataRoot, dataset);
            if exist(candidate, 'file')
                filePath = candidate;
                return
            end
            [~, datasetName, ~] = fileparts(dataset);
        else
            datasetName = dataset;
        end
        candidate = fullfile(dataRoot, [datasetName, '.set']);
        if exist(candidate, 'file')
            filePath = candidate;
            return
        end
        matches = dir(fullfile(dataRoot, '**', [datasetName, '.set']));
        if ~isempty(matches)
            filePath = fullfile(matches(1).folder, matches(1).name);
            return
        end
        allSets = dir(fullfile(dataRoot, '**', '*.set'));
        filePath = '';
        for i = 1:numel(allSets)
            if contains(allSets(i).name, datasetName)
                filePath = fullfile(allSets(i).folder, allSets(i).name);
                return
            end
        end
    end

    function [idx, label] = parseChannelSelection(inputStr, eeg)
        idx = [];
        label = '';
        if isempty(eeg) || ~isfield(eeg, 'nbchan')
            return
        end
        inputStr = strtrim(string(inputStr));
        if inputStr == ""
            return
        end
        tokens = regexp(char(inputStr), '[A-Za-z]+[A-Za-z0-9]*|\d+', 'match');
        if isempty(tokens)
            return
        end
        indices = [];
        labels = {};
        for i = 1:numel(tokens)
            tok = tokens{i};
            val = str2double(tok);
            if ~isnan(val)
                indices(end+1) = val; %#ok<AGROW>
                labels{end+1} = num2str(val); %#ok<AGROW>
            elseif isfield(eeg, 'chanlocs') && ~isempty(eeg.chanlocs)
                match = find(strcmpi({eeg.chanlocs.labels}, tok), 1);
                if ~isempty(match)
                    indices(end+1) = match; %#ok<AGROW>
                    labels{end+1} = eeg.chanlocs(match).labels; %#ok<AGROW>
                end
            end
        end
        if isempty(indices)
            return
        end
        indices = unique(indices);
        indices = indices(indices >= 1 & indices <= eeg.nbchan);
        if isempty(indices)
            return
        end
        idx = indices;
        label = strjoin(unique(labels, 'stable'), ',');
    end
    function [tableData, columns] = buildSummaryTable(datasetMetrics)
        columns = {'Dataset', 'Raters', 'QC_Before', 'QC_After', ...
            'Trials_Jaccard', 'Trials_F1', 'Trials_Prec', 'Trials_Rec', 'Trials_Kappa', 'Trials_GroupJ', ...
            'Chan_Jaccard', 'Chan_F1', 'Chan_Prec', 'Chan_Rec', 'Chan_Kappa', 'Chan_GroupJ', ...
            'ICs_Jaccard', 'ICs_F1', 'ICs_Prec', 'ICs_Rec', 'ICs_Kappa', 'ICs_GroupJ'};
        n = numel(datasetMetrics.dataset);
        tableData = cell(n, numel(columns));
        for i = 1:n
            tableData{i, 1} = char(datasetMetrics.dataset{i});
            tableData{i, 2} = datasetMetrics.nRaters(i);
            tableData{i, 3} = round(datasetMetrics.qualityBeforeMean(i), 4);
            tableData{i, 4} = round(datasetMetrics.qualityAfterMean(i), 4);
            tableData{i, 5} = round(datasetMetrics.trialsJaccardMean(i), 4);
            tableData{i, 6} = round(datasetMetrics.trialsF1Mean(i), 4);
            tableData{i, 7} = round(datasetMetrics.trialsPrecisionMean(i), 4);
            tableData{i, 8} = round(datasetMetrics.trialsRecallMean(i), 4);
            tableData{i, 9} = round(datasetMetrics.trialsKappa(i), 4);
            tableData{i, 10} = round(datasetMetrics.trialsGroupJaccard(i), 4);
            tableData{i, 11} = round(datasetMetrics.channelsJaccardMean(i), 4);
            tableData{i, 12} = round(datasetMetrics.channelsF1Mean(i), 4);
            tableData{i, 13} = round(datasetMetrics.channelsPrecisionMean(i), 4);
            tableData{i, 14} = round(datasetMetrics.channelsRecallMean(i), 4);
            tableData{i, 15} = round(datasetMetrics.channelsKappa(i), 4);
            tableData{i, 16} = round(datasetMetrics.channelsGroupJaccard(i), 4);
            tableData{i, 17} = round(datasetMetrics.icsJaccardMean(i), 4);
            tableData{i, 18} = round(datasetMetrics.icsF1Mean(i), 4);
            tableData{i, 19} = round(datasetMetrics.icsPrecisionMean(i), 4);
            tableData{i, 20} = round(datasetMetrics.icsRecallMean(i), 4);
            tableData{i, 21} = round(datasetMetrics.icsKappa(i), 4);
            tableData{i, 22} = round(datasetMetrics.icsGroupJaccard(i), 4);
        end
    end

    function list = buildLowAgreementList(datasetMetrics)
        n = numel(datasetMetrics.dataset);
        avg = nan(n, 1);
        for i = 1:n
            vals = [datasetMetrics.trialsJaccardMean(i), ...
                datasetMetrics.channelsJaccardMean(i), ...
                datasetMetrics.icsJaccardMean(i)];
            avg(i) = mean(vals, 'omitnan');
        end
        avgForSort = avg;
        avgForSort(isnan(avgForSort)) = inf;
        [~, order] = sort(avgForSort, 'ascend');
        topN = min(10, n);
        list = cell(topN, 1);
        for i = 1:topN
            idx = order(i);
            list{i} = sprintf('%s | avg Jaccard = %.3f', datasetMetrics.dataset{idx}, avg(idx));
        end
        if isempty(list)
            list = {'(none)'};
        end
    end

    function text = buildOverallText(datasetMetrics, iccBefore, iccAfter)
        meanTrials = mean(datasetMetrics.trialsJaccardMean, 'omitnan');
        meanCh = mean(datasetMetrics.channelsJaccardMean, 'omitnan');
        meanIcs = mean(datasetMetrics.icsJaccardMean, 'omitnan');
        medTrials = median(datasetMetrics.trialsJaccardMean, 'omitnan');
        medCh = median(datasetMetrics.channelsJaccardMean, 'omitnan');
        medIcs = median(datasetMetrics.icsJaccardMean, 'omitnan');
        stdTrials = std(datasetMetrics.trialsJaccardMean, 'omitnan');
        stdCh = std(datasetMetrics.channelsJaccardMean, 'omitnan');
        stdIcs = std(datasetMetrics.icsJaccardMean, 'omitnan');
        if nargin < 2
            iccBefore = NaN;
            iccAfter = NaN;
        end
        text = sprintf(['Jaccard mean/median/std:\n', ...
            'Trials %.3f / %.3f / %.3f\n', ...
            'Channels %.3f / %.3f / %.3f\n', ...
            'ICs %.3f / %.3f / %.3f\n', ...
            'ICC(Quality Before) %.3f\n', ...
            'ICC(Quality After) %.3f'], ...
            meanTrials, medTrials, stdTrials, ...
            meanCh, medCh, stdCh, ...
            meanIcs, medIcs, stdIcs, ...
            iccBefore, iccAfter);
    end

    function icc = computeICC2_1(data)
        icc = NaN;
        if isempty(data) || size(data, 2) < 2
            return
        end
        validRows = all(~isnan(data), 2);
        X = data(validRows, :);
        if size(X, 1) < 2
            return
        end
        n = size(X, 1);
        k = size(X, 2);
        meanRow = mean(X, 2);
        meanCol = mean(X, 1);
        grand = mean(X(:));
        SSR = k * sum((meanRow - grand).^2);
        SSC = n * sum((meanCol - grand).^2);
        SSE = sum(sum((X - meanRow - meanCol + grand).^2));
        MSR = SSR / (n - 1);
        MSC = SSC / (k - 1);
        MSE = SSE / ((n - 1) * (k - 1));
        denom = MSR + (k - 1) * MSE + (k * (MSC - MSE) / n);
        if denom == 0
            icc = NaN;
        else
            icc = (MSR - MSE) / denom;
        end
    end

    function kappa = cohensKappa(a, b)
        a = a(:);
        b = b(:);
        if numel(a) ~= numel(b) || isempty(a)
            kappa = NaN;
            return
        end
        p0 = mean(a == b);
        pyes1 = mean(a == 1);
        pyes2 = mean(b == 1);
        pno1 = 1 - pyes1;
        pno2 = 1 - pyes2;
        pe = pyes1 * pyes2 + pno1 * pno2;
        if (1 - pe) == 0
            kappa = NaN;
        else
            kappa = (p0 - pe) / (1 - pe);
        end
    end

    function kappa = fleissKappa(mat)
        [n, k] = size(mat);
        if n == 0 || k < 2
            kappa = NaN;
            return
        end
        n1 = sum(mat == 1, 2);
        n0 = k - n1;
        P = (n1 .* (n1 - 1) + n0 .* (n0 - 1)) / (k * (k - 1));
        Pbar = mean(P);
        p1 = sum(n1) / (n * k);
        p0 = sum(n0) / (n * k);
        Pe = p1^2 + p0^2;
        if (1 - Pe) == 0
            kappa = NaN;
        else
            kappa = (Pbar - Pe) / (1 - Pe);
        end
    end

    function out = joinNames(names)
        if isempty(names)
            out = 'none';
        else
            out = strjoin(names, ', ');
        end
    end

end
