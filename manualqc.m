function manualqc()
evalin('base','clear')
evalin('base','QC_log={};')
%% Define call back functions
global filepath filenames n EEG tmprej ui chanlisttmp ic2remove chanliststr qc_log;
qc_log=eval('{''dataset'',''Rejected trials'',''Interpolated Channels'',''Removed ICs'',''Comments'',''Rating'',''Quality Score Before'',''Quality Score After''};'); %don't want remove ' by hand.
% 0 datadir_cmd
    function datadir_select_cmd(hObject,eventdata)
        data_path=uigetdir(pwd,'Select a search dir');
        set(ui.datadir,'String',data_path);
    end
% 1 search_cmd
%dataset starting with 'Final': '^Final.*.set'
% word ending with m: '\w*m$'
    function search_cmd(hObject,eventdata)
        data_path=get(ui.datadir,'String');
        regexp=get(ui.regexp,'String');
        [filepath, filenames]=filesearch_regexp(data_path,regexp);
        if length(filenames)==0
            set(ui.idxbox, 'String','NA');
            set(ui.info2,'String','Cannot find any file with the regexp, try it again')
        else
            set(ui.idxbox, 'String','1');
            set(ui.info2,'String',sprintf('Find %d in the path',length(filenames)));
            set(ui.load,'enable','on')
        end
    end
% 2 load_cmd
    function load_cmd(hObject,eventdata)
        n=str2num(get(ui.idxbox,'String'));
        %if n>length(filenames)
        set(ui.info2,'String','Loading dataset');
        set(ui.info7,'String','User Rating: Usable')
        set(ui.info6,'String','User Comments: ')
        
        set(ui.info3,'String','Bad Epoches: ')
        set(ui.info4,'String','Bad Channels: ')
        set(ui.info5,'String','ICs to remove: ')
        try
        EEG = pop_loadset('filename',filenames{n},'filepath',filepath{n});
        EEG = eeg_checkset( EEG );
        set(hf,'Name',['You are working on: No.',num2str(n),' ',filenames{n}(1:end-4)]);
        %set(ui.info2,'String',['You are working on: No.',num2str(n),' ',filenames{n}(1:end-4)])
        % Initial scale in scroll. Very rough estimation of data quality
        %   From my experience, normally (for 70% data), small figure indicates good quality
        quality=data_quality(EEG);
        if quality<=18;
            meanning='Good';
        elseif quality<=28;
            meanning='Fair';
        else
            meanning='Seems bad';
        end
        % set enable on
        nbtrials=EEG.trials ;
        nbchan=EEG.nbchan ;
        nbics=size(EEG.icaweights,1);
        datainfo=sprintf('Trial number: %d;   Channel number: %d;   ICs number: %d;   Data Quality: %d (%s)',nbtrials,nbchan,nbics,quality,meanning);
        set(ui.info2,'String',datainfo)
        set(ui.scroll,'enable','on');
        set(ui.badchan,'enable','on');
        set(ui.ica,'enable','on')
%         set(ui.update,'enable','on')
        set(ui.save,'enable','on')
        catch
            try error_info=[fullfile(filepath{n},filenames{n}),' cannot be loaded'];
                set(ui.info2,'String',error_info)
            catch
                warndlg('Index > files you have','Manual QC')
                set(ui.info2,'String','Index > files you have')
            end
        end
    end
% 3 scroll_cmd
    function scroll_cmd(hObject,eventdata)
        cmd='global EEG tmprej ui; if isempty(TMPREJ), warndlg(''no epoch is selected'',''Manual QC''); clear TMPREJ; else [tmprej, tmprejE] = eegplot2trial(TMPREJ,EEG.pnts, EEG.trials, [1 1 0.783], []); set(ui.info3,''String'',[''Bad Epoches: '', num2str(find(tmprej==1))]); clear tmprejE TMPREJ;end';
        %          cmd=' if isempty(TMPREJ), warndlg(''no epoch is selected''); else [tmprej, tmprejE] = eegplot2trial(TMPREJ,EEG.pnts, EEG.trials, [1 1 0.783], []); end';
        
        modified_eegplot( EEG.data, 'srate', EEG.srate, 'title', 'eegplot()', ...
            'limits', [EEG.xmin EEG.xmax]*1000,'eloc_file',EEG.chanlocs,'events',EEG.event,'wincolor' ,[1 1 0.783],'command',cmd,'butlabel','Mark')
        %             bad_trials=
        %             set(ui.info3,'String',['Bad epoches: ', num2str(find(tmprej==1))]);
    end
% 4 badchan_cmd ---to do modify the function
    function badchan_cmd(hObject,eventdata)
%         chanlisttmp=[];
%         chanliststr=[];
        tmpchaninfo = EEG.chanlocs;
        [chanlisttmp chanliststr] = modified_pop_chansel( EEG, { tmpchaninfo.labels } ,'withindex','on');
        if ~isempty(chanlisttmp)
        set(ui.info4,'String',['Bad Channels: [',chanliststr,' ] (Index: ' num2str(chanlisttmp),' )']);
        else
        set(ui.info4,'String','Bad Channels: No bad channels selected');    
        end
    end
% 5 ica_cmd ---to do modify the function
    function ica_cmd(hObject,eventdata)
        [EEG]=modified_pop_selectcomps( EEG, [1:28]);
        EEG = eeg_checkset( EEG );
        %test set(ui.info3,'String',['Bad epoches: ', num2str(1:200)])
        % set(ui.info2,'String',['Bad epoches: ', num2str(find(tmprej==1))])
    end
% 6 add_cmd
    function add_cmd(hObject,eventdata)
        set(ui.info6, 'String', ['User Comments: ', get(ui.comments,'String')])
        % frozen bottuns and edit box.
    end
% 7 savedir_select_cmd
    function savedir_select_cmd(hObject,eventdata)
        data_path=get(ui.datadir,'String');
        output_path=uigetdir(data_path,'Select output folder');
        set(ui.savedir,'String',output_path);
    end
% 8 save_cmd
    function save_cmd(hObject,eventdata)
        output_path=get(ui.savedir,'String');
        prefix=get(ui.prefix,'String');
        savename=strcat(prefix,filenames(n));
        stars=['*****************************************************'];
        
        EEG = eeg_checkset( EEG );
        quality_score_before=data_quality(EEG);
% reject epoches
        if ~isempty(tmprej)
            EEG = pop_rejepoch(EEG,tmprej,0);
            EEG = eeg_checkset( EEG );
            disp(stars);
            disp([num2str(find(tmprej==1)),' trails were removed']);
            disp(stars);
            set(ui.info3,'String',[num2str(find(tmprej==1)),' trails were removed']);
        else
            disp(stars);
            disp(['No epoch was rejected']);
            disp(stars);
            set(ui.info3,'String','No trail was removed');
        end
 % interpolated channels    
        if ~isempty(chanlisttmp)
            for badi=1:length(chanlisttmp)
                EEG = pop_interp(EEG,chanlisttmp(badi), 'spherical');
                EEG = eeg_checkset( EEG );
            end
            badi=[];
            disp(stars)
            disp(['Interpolated channels (spherical): ',num2str(chanlisttmp)]);
            disp(stars)
            set(ui.info4,'String',['Interpolated channels (spherical): ',chanliststr]);
        else
            disp(stars);
            disp('No bandchannel');
            disp(stars);
            set(ui.info4,'String','No bandchannel');
        end
        
        if  ~isempty(ic2remove)
            EEG=pop_subcomp(EEG,ic2remove,0);
            EEG = eeg_checkset( EEG );
            disp(stars);
            disp(['Removed components: ',num2str(ic2remove)]);
            disp(stars);
            set(ui.info5,'String',['Removed components: ',num2str(ic2remove)]);
        else
            disp(stars);
            disp('No component was selected');
            disp(stars);
            set(ui.info5,'String','No component was selected');
        end
        
        %calculate data quality after QC
        quality_score_after=data_quality(EEG);
        % wrap QC info
        tmp_name=filenames{n};
        tmp_comments=get(ui.info6,'String');
        tmp_rating=get(ui.info7,'String');
        tmp_info={tmp_name(1:end-4),num2str(find(tmprej==1)),chanliststr,num2str(ic2remove),tmp_comments(16:end),tmp_rating(14:end),num2str(quality_score_before),num2str(quality_score_after)};
        %save info in EEG structure
        EEG.comments = pop_comments(EEG.comments,'','QC info:',1);
        EEG.comments = pop_comments(EEG.comments,'','Trials removed:',1);
        EEG.comments = pop_comments(EEG.comments,'',tmp_info{2},1);
        EEG.comments = pop_comments(EEG.comments,'','Bad Channel interpolated:',1);
        EEG.comments = pop_comments(EEG.comments,'',tmp_info{3},1);
        EEG.comments = pop_comments(EEG.comments,'','ICs removed:',1);
        EEG.comments = pop_comments(EEG.comments,'',tmp_info{4},1);
        EEG.comments = pop_comments(EEG.comments,'',tmp_info{5},1);
        EEG.comments = pop_comments(EEG.comments,'',tmp_info{6},1);
        EEG.comments = pop_comments(EEG.comments,'','quality before QC:',1);
        EEG.comments = pop_comments(EEG.comments,'',tmp_info{7},1);
        EEG.comments = pop_comments(EEG.comments,'','quality after QC:',1);
        EEG.comments = pop_comments(EEG.comments,'',tmp_info{8},1);

        qc_log(n+1,1:8)=deal(tmp_info);
        if exist(output_path)
        EEG = pop_saveset( EEG, 'filename',savename{n},'filepath',output_path);
        %save tmp results- 
        qc_info_temp_bak=['qc_info_bak_on_',datestr(now,'HH.MM'),'.xls'];
         xlswrite(fullfile(output_path,qc_info_temp_bak),qc_log);
            
        
        
        assignin('base','QC_log',qc_log);
        set(ui.info2, 'String','file saved');
        set(ui.scroll,'enable','off');
        set(ui.badchan,'enable','off');
        set(ui.ica,'enable','off')
        set(ui.save,'enable','off')
%         set(ui.update,'enable','off')
%         set(ui.info7,'String','User Rating: Usable')
%         set(ui.info6,'String','User Comments: ')
%         set(ui.info2,'String','Dataset: ')
%         set(ui.info3,'String','Bad Epoches: ')
%         set(ui.info4,'String','Bad Channels: ')
%         set(ui.info5,'String','ICs to remove: ')
        EEG=[];
        ic2remove=[];
        tmprej=[];
        chanlisttmp=[];
        tmp_info={};
        if n+1<=length(filenames)
            set(ui.idxbox, 'String',num2str(n+1));
        else
            set(ui.idxbox, 'String','end');
           
            set(ui.info7,'String','')
            set(ui.info6,'String','')
            set(ui.info3,'String','')
            set(ui.info4,'String','')
            set(ui.info5,'String','')
            warndlg('No more files.','Manual QC')
            set(ui.info2, 'String','No more files.');

        end
        else
            set(ui.info2,'String','The save dir doesn''t exist.');
             warndlg('The save dir doesn''t exist.','Manual QC')
        end        
end
% 9 data_quality Initial scale in scroll. Very rough estimation of data quality
%   From my experience, normally (for 70% data), small figure indicates good quality
    function quality_index=data_quality(EEG)
        maxindex = min(1000, EEG.pnts*EEG.trials);
        stds = std(EEG.data(:,1:maxindex),[],2);
        datastd = stds;
        stds = sort(stds);
        if length(stds) > 2
            stds = mean(stds(2:end-1));
        else
            stds = mean(stds);
        end;
        spacing = stds*3;
        if spacing > 10
            spacing = round(spacing);
        end
        quality_index=spacing;
    end
    function bselection(source,event)
       set(ui.info7,'String',['User Rating: ', event.NewValue.String]);
    end
%% GUI settings
bgblue=[0.66    0.76   1.00];
btnblue=[0.93 0.96 1];
txtblue=[0 0 0.4];
hf = figure('Units', 'Normalized', ...
    'Position', [0.32,0.17,0.4,0.7], ...
    'Menu', 'none', ...
    'Color',bgblue,...
    'Name','ManualQC v.1',...
    'NumberTitle', 'off',...
    'CloseRequestFcn', 'delete(gcf);disp(''Thank you for using Manual QC.'')');
%Line1-Title
ui.tittle1=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.35 0.9 0.2 0.07], ...
    'Style', 'text', ...
    'String', 'ManualQC', ...
    'BackgroundColor',bgblue,...
    'ForegroundColor',txtblue,...
    'FontSize',18,...
    'HorizontalAlignment','right',...
    'FontWeight', 'bold');
ui.tittle2=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.55 0.9 0.19 0.07], ...
    'Style', 'text', ...
    'String', 'v1.0', ...
    'BackgroundColor',bgblue,...
    'ForegroundColor',txtblue,...
    'HorizontalAlignment','left',...
    'FontSize',12);
%Line2-Search files
ui.regexp=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.05 0.86 0.2 0.06], ...
    'Style', 'edit', ...
    'String', 'regular expression', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12);
ui.datadir=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.27 0.86 0.33 0.06], ...
    'Style', 'edit', ...
    'String', 'paste or select datadir', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12);
ui.datadir_select=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.62 0.86 0.15 0.06], ...
    'Style', 'pushbutton', ...
    'String', 'Browse', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12,...
    'Callback',@datadir_select_cmd);
ui.search=uicontrol('Parent', hf,  'Units', 'Normalized', ...
    'Position', [0.79 0.86 0.15 0.06], ...
    'Style', 'pushbutton', ...
    'String', 'Search', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'HorizontalAlignment','left',...
    'FontSize',14,...
    'Callback',@search_cmd);

% Line3 Load data
ui.idxbox=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.05 0.78 0.2 0.06], ...
    'Style', 'edit', ...
    'String', 'set number to load', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12);
ui.load=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.27 0.78 0.16 0.06], ...
    'Style', 'pushbutton', ...
    'String', 'Load', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',14,...
    'Callback',@load_cmd);
ui.scroll=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.45 0.78 0.15 0.06], ...
    'Style', 'pushbutton', ...
    'String', 'Epoches', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',14,...
    'FontWeight', 'bold',...
    'Callback',@scroll_cmd);
ui.badchan=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.62 0.78 0.15 0.06], ...
    'Style', 'pushbutton', ...
    'String', 'Channels', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',14,...
    'FontWeight', 'bold',...
    'Callback',@badchan_cmd);
ui.ica=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.79 0.78 0.15 0.06], ...
    'Style', 'pushbutton', ...
    'String', 'ICs', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',14,...
    'FontWeight', 'bold',...
    'Callback',@ica_cmd);

% Line4 Rating and comments
ui.rating=uibuttongroup('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.05 0.70 0.38 0.06],'BackgroundColor',bgblue, 'SelectionChangedFcn',@bselection);
ui.r1 = uicontrol(ui.rating,'Style',...
    'radiobutton','Units', 'Normalized',...
    'String','Usable',...
    'Position',[0.03 0.2 0.25 0.5],...
    'HandleVisibility','off','BackgroundColor',bgblue, 'FontSize',12);
ui.r2 = uicontrol(ui.rating,'Style','radiobutton','Units', 'Normalized',...
    'String','Caution',...
    'Position',[0.31 0.2 0.3 0.5],...
    'HandleVisibility','off','BackgroundColor',bgblue,'FontSize',12);
ui.r3 = uicontrol(ui.rating,'Style','radiobutton','Units', 'Normalized',...
    'String','Not usable',...
    'Position',[0.63 0.2 0.34 0.5],...
    'HandleVisibility','off','BackgroundColor',bgblue,'FontSize',12);
ui.rating.Visible = 'on';

ui.comments=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.45 0.70 0.32 0.06], ...
    'Style', 'edit', ...
    'String', 'User''s Comments', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12);
ui.add=uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [0.79 0.70 0.15 0.06], ...
    'Style', 'pushbutton', ...
    'String', 'Add', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12,...
    'callback',@add_cmd);

% Line5 Information pannel
ui.info1=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.05 0.61 0.9 0.06], ...
    'Style', 'text', ...
    'String', 'Information Pannel', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',18);
ui.info2=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.05 0.55 0.9 0.06], ...
    'Style', 'text', ...
    'String', 'Enter ^Final\w*.set to search set files starting with word ''Final''.|  See regexp for more.', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12,...
    'HorizontalAlignment','left');
ui.info3=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.05 0.405 0.9 0.15], ...
    'Style', 'text', ...
    'String', 'Bad Epoches: ', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12,...
    'HorizontalAlignment','left');
ui.info4=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.05 0.355 0.9 0.06], ...
    'Style', 'text', ...
    'String', 'Bad Channels:', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12,...
    'HorizontalAlignment','left');
ui.info5=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.05 0.30 0.9 0.06], ...
    'Style', 'text', ...
    'String', 'ICs to remove: ', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12,...
    'HorizontalAlignment','left');
ui.info6=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.05 0.245 0.65 0.06], ...
    'Style', 'text', ...
    'String', 'User Comments: ', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12,...
    'HorizontalAlignment','left');
ui.info7=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.70 0.245 0.25 0.06], ...
    'Style', 'text', ...
    'String', 'User Rating: Usable', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12,...
    'HorizontalAlignment','left');
% Line6 Update and Save
ui.prefix=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.05 0.17 0.2 0.06], ...
    'Style', 'edit', ...
    'String', 'prefix', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12);
ui.savedir=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.27 0.17 0.5 0.06], ...
    'Style', 'edit', ...
    'String', 'paste or select savedir', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12);
ui.savedir_select=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.79 0.17 0.16 0.06], ...
    'Style', 'pushbutton', ...
    'String', 'Browse', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',12,...
    'Callback',@savedir_select_cmd);
ui.save=uicontrol('Parent', hf,'Units', 'Normalized', ...
    'Position', [0.05 0.03 0.9 0.12], ...
    'Style', 'pushbutton', ...
    'String', 'Save', ...
    'BackgroundColor',btnblue,...
    'ForegroundColor',txtblue,...
    'FontSize',20,...
    'FontWeight', 'bold',...
    'callback',@save_cmd);
% ui.update=uicontrol('Parent', hf,'Units', 'Normalized', ...
%     'Position', [0.05 0.03 0.45 0.12], ...
%     'Style', 'pushbutton', ...
%     'String', 'Update QC info', ...
%     'BackgroundColor',btnblue,...
%     'ForegroundColor',txtblue,...
%     'FontSize',20,...
%     'FontWeight', 'bold');

% Create and display the text label
% 1.how to set color
% 2.how to set relative position
url = 'zh1peng.github.io/ManualQC';
labelStr = ['<html><body style=background-color:#A8C2FF>More info: <a href=>', url, '</a></body></html>'];
jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
bgcolor = get(gcf, 'Color');
jLabel.setBackground(java.awt.Color(bgcolor(1),bgcolor(2),bgcolor(3)));
[hjLabel,hContainer] = javacomponent(jLabel);
set(hContainer,'parent',gcf,'units','normalized','position',[0.62,0.01,0.4,0.02])
% Modify the mouse cursor when hovering on the label
hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
% Set the label's tooltip
hjLabel.setToolTipText(['Visit the ' url ' website']);
% Set the mouse-click callback
set(hjLabel, 'MouseClickedCallback', @(h,e)web(['http://' url], '-browser'))

set(ui.scroll,'enable','off');
set(ui.badchan,'enable','off');
set(ui.ica,'enable','off')
set(ui.save,'enable','off')
% set(ui.update,'enable','off')
set(ui.load,'enable','off')
end
%% ====================================================================================
%               Functions (some are customized functions from eeglab)
%% ====================modified_eegplot=================================
% This is a modified eegplot function. see eegplot()
% 1.removed 2 buttons [Norm; Stack]
% 2.removed ['Accept and close'] in 'Figure' menu
% 3.changed size of the window. [DEFAULT_AXES_POSITION]
% 4.set g.spacing as 72 [This is used in our lab]
% 5.removed ['Help'] menu
% Note: eegplot ect functions from eeglab are needed in path.
% eeglab14_0_0b/functions/*
% same usage as eegplot()
function [outvar1] = modified_eegplot(data, varargin); % p1,p2,p3,p4,p5,p6,p7,p8,p9)
% Defaults (can be re-defined):
g.spacing=72; %change this if you are using different display spacing
DEFAULT_PLOT_COLOR = { [0 0 1], [0.7 0.7 0.7]};         % EEG line color
try, icadefs;
    DEFAULT_FIG_COLOR = BACKCOLOR;
    BUTTON_COLOR = GUIBUTTONCOLOR;
catch
    DEFAULT_FIG_COLOR = [1 1 1];
    BUTTON_COLOR =[0.8 0.8 0.8];
end;
DEFAULT_AXIS_COLOR = 'k';         % X-axis, Y-axis Color, text Color
DEFAULT_GRID_SPACING = 1;         % Grid lines every n seconds
DEFAULT_GRID_STYLE = '-';         % Grid line style
YAXIS_NEG = 'off';                % 'off' = positive up
DEFAULT_NOUI_PLOT_COLOR = 'k';    % EEG line color for noui option
%   0 - 1st color in AxesColorOrder
SPACING_EYE = 'on';               % g.spacingI on/off
SPACING_UNITS_STRING = '';        % '\muV' for microvolt optional units for g.spacingI Ex. uV
%MAXEVENTSTRING = 10;
%DEFAULT_AXES_POSITION = [0.0964286 0.15 0.842 0.75-(MAXEVENTSTRING-5)/100];
% dimensions of main EEG axes
ORIGINAL_POSITION = [50 50 800 500];

if nargin < 1
    help eegplot
    return
end

% %%%%%%%%%%%%%%%%%%%%%%%%
% Setup inputs
% %%%%%%%%%%%%%%%%%%%%%%%%

if ~isstr(data) % If NOT a 'noui' call or a callback from uicontrols
    
    try
        options = varargin;
        if ~isempty( varargin ),
            for i = 1:2:numel(options)
                g.(options{i}) = options{i+1};
            end
        else g= []; end;
    catch
        disp('eegplot() error: calling convention {''key'', value, ... } error'); return;
    end;
    
    % Selection of data range If spectrum plot
    if isfield(g,'freqlimits') || isfield(g,'freqs')
        %        % Check  consistency of freqlimits
        %        % Check  consistency of freqs
        
        % Selecting data and freqs
        [temp, fBeg] = min(abs(g.freqs-g.freqlimits(1)));
        [temp, fEnd] = min(abs(g.freqs-g.freqlimits(2)));
        data = data(:,fBeg:fEnd,:);
        g.freqs     = g.freqs(fBeg:fEnd);
        
        % Updating settings
        if ndims(data) == 2, g.winlength = g.freqs(end) - g.freqs(1); end
        g.srate     = length(g.freqs)/(g.freqs(end)-g.freqs(1));
        g.isfreq    = 1;
    end
    
    % push button: create/remove window
    % ---------------------------------
    defdowncom   = 'eegplot(''defdowncom'',   gcbf);'; % push button: create/remove window
    defmotioncom = 'eegplot(''defmotioncom'', gcbf);'; % motion button: move windows or display current position
    defupcom     = 'eegplot(''defupcom'',     gcbf);';
    defctrldowncom = 'eegplot(''topoplot'',   gcbf);'; % CTRL press and motion -> do nothing by default
    defctrlmotioncom = ''; % CTRL press and motion -> do nothing by default
    defctrlupcom = ''; % CTRL press and up -> do nothing by default
    
    try, g.srate; 		    catch, g.srate		= 256; 	end;
    %    try, g.spacing; 			catch, g.spacing	= 0; 	end;
    try, g.eloc_file; 		catch, g.eloc_file	= 0; 	end; % 0 mean numbered
    try, g.winlength; 		catch, g.winlength	= 5; 	end; % Number of seconds of EEG displayed
    try, g.position; 	    catch, g.position	= ORIGINAL_POSITION; 	end;
    try, g.title; 		    catch, g.title		= ['Scroll activity -- eegplot()']; 	end;
    try, g.plottitle; 		catch, g.plottitle	= ''; 	end;
    try, g.trialstag; 		catch, g.trialstag	= -1; 	end;
    try, g.winrej; 			catch, g.winrej		= []; 	end;
    try, g.command; 			catch, g.command	= ''; 	end;
    try, g.tag; 				catch, g.tag		= 'EEGPLOT'; end;
    try, g.xgrid;		    catch, g.xgrid		= 'off'; end;
    try, g.ygrid;		    catch, g.ygrid		= 'off'; end;
    try, g.color;		    catch, g.color		= 'off'; end;
    try, g.submean;			catch, g.submean	= 'off'; end;
    try, g.children;			catch, g.children	= 0; end;
    try, g.limits;		    catch, g.limits	    = [0 1000*(size(data,2)-1)/g.srate]; end;
    try, g.freqs;            catch, g.freqs	    = []; end;  % Ramon
    try, g.freqlimits;	    catch, g.freqlimits	= []; end;
    try, g.dispchans; 		catch, g.dispchans  = size(data,1); end;
    try, g.wincolor; 		catch, g.wincolor   = [ 0.7 1 0.9]; end;
    try, g.butlabel; 		catch, g.butlabel   = 'REJECT'; end;
    try, g.colmodif; 		catch, g.colmodif   = { g.wincolor }; end;
    try, g.scale; 		    catch, g.scale      = 'on'; end;
    try, g.events; 		    catch, g.events      = []; end;
    try, g.ploteventdur;     catch, g.ploteventdur = 'off'; end;
    try, g.data2;            catch, g.data2      = []; end;
    try, g.plotdata2;        catch, g.plotdata2 = 'off'; end;
    try, g.mocap;		    catch, g.mocap		= 'off'; end; % nima
    try, g.selectcommand;     catch, g.selectcommand     = { defdowncom defmotioncom defupcom }; end;
    try, g.ctrlselectcommand; catch, g.ctrlselectcommand = { defctrldowncom defctrlmotioncom defctrlupcom }; end;
    try, g.datastd;          catch, g.datastd = []; end; %ozgur
    try, g.normed;            catch, g.normed = 0; end; %ozgur
    try, g.envelope;          catch, g.envelope = 0; end;%ozgur
    try, g.maxeventstring;    catch, g.maxeventstring = 10; end; % JavierLC
    try, g.isfreq;            catch, g.isfreq = 0;    end; % Ramon
    
    if strcmpi(g.ploteventdur, 'on'), g.ploteventdur = 1; else g.ploteventdur = 0; end;
    if ndims(data) > 2
        g.trialstag = size(	data, 2);
    end;
    
    gfields = fieldnames(g);
    for index=1:length(gfields)
        switch gfields{index}
            case {'spacing', 'srate' 'eloc_file' 'winlength' 'position' 'title' 'plottitle' ...
                    'trialstag'  'winrej' 'command' 'tag' 'xgrid' 'ygrid' 'color' 'colmodif'...
                    'freqs' 'freqlimits' 'submean' 'children' 'limits' 'dispchans' 'wincolor' ...
                    'maxeventstring' 'ploteventdur' 'butlabel' 'scale' 'events' 'data2' 'plotdata2' 'mocap' 'selectcommand' 'ctrlselectcommand' 'datastd' 'normed' 'envelope' 'isfreq'},;
            otherwise, error(['eegplot: unrecognized option: ''' gfields{index} '''' ]);
        end;
    end;
    
    % g.data=data; % never used and slows down display dramatically - Ozgur 2010
    
    if length(g.srate) > 1
        disp('Error: srate must be a single number'); return;
    end;
    if length(g.spacing) > 1
        disp('Error: ''spacing'' must be a single number'); return;
    end;
    if length(g.winlength) > 1
        disp('Error: winlength must be a single number'); return;
    end;
    if isstr(g.title) > 1
        disp('Error: title must be is a string'); return;
    end;
    if isstr(g.command) > 1
        disp('Error: command must be is a string'); return;
    end;
    if isstr(g.tag) > 1
        disp('Error: tag must be is a string'); return;
    end;
    if length(g.position) ~= 4
        disp('Error: position must be is a 4 elements array'); return;
    end;
    switch lower(g.xgrid)
        case { 'on', 'off' },;
        otherwise disp('Error: xgrid must be either ''on'' or ''off'''); return;
    end;
    switch lower(g.ygrid)
        case { 'on', 'off' },;
        otherwise disp('Error: ygrid must be either ''on'' or ''off'''); return;
    end;
    switch lower(g.submean)
        case { 'on' 'off' };
        otherwise disp('Error: submean must be either ''on'' or ''off'''); return;
    end;
    switch lower(g.scale)
        case { 'on' 'off' };
        otherwise disp('Error: scale must be either ''on'' or ''off'''); return;
    end;
    
    if ~iscell(g.color)
        switch lower(g.color)
            case 'on', g.color = { 'k', 'm', 'c', 'b', 'g' };
            case 'off', g.color = { [ 0 0 0.4] };
            otherwise
                disp('Error: color must be either ''on'' or ''off'' or a cell array');
                return;
        end;
    end;
    if length(g.dispchans) > size(data,1)
        g.dispchans = size(data,1);
    end;
    if ~iscell(g.colmodif)
        g.colmodif = { g.colmodif };
    end;
    if g.maxeventstring>20 % JavierLC
        disp('Error: maxeventstring must be equal or lesser than 20'); return;
    end;
    
    % max event string;  JavierLC
    % ---------------------------------
    MAXEVENTSTRING = g.maxeventstring;
    DEFAULT_AXES_POSITION =[0.08 0.15 0.88 0.85-(MAXEVENTSTRING-5)/100];
    
    % convert color to modify into array of float
    % -------------------------------------------
    for index = 1:length(g.colmodif)
        if iscell(g.colmodif{index})
            tmpcolmodif{index} = g.colmodif{index}{1} ...
                + g.colmodif{index}{2}*10 ...
                + g.colmodif{index}{3}*100;
        else
            tmpcolmodif{index} = g.colmodif{index}(1) ...
                + g.colmodif{index}(2)*10 ...
                + g.colmodif{index}(3)*100;
        end;
    end;
    g.colmodif = tmpcolmodif;
    
    [g.chans,g.frames, tmpnb] = size(data);
    g.frames = g.frames*tmpnb;
    
    %   if g.spacing == 0
    %     maxindex = min(1000, g.frames);
    % 	stds = std(data(:,1:maxindex),[],2);
    %     g.datastd = stds;
    % 	stds = sort(stds);
    % 	if length(stds) > 2
    % 		stds = mean(stds(2:end-1));
    % 	else
    % 		stds = mean(stds);
    % 	end;
    %     g.spacing = stds*3;
    %     if g.spacing > 10
    %       g.spacing = round(g.spacing);
    %     end
    %     if g.spacing  == 0 | isnan(g.spacing)
    %         g.spacing = 1; % default
    %     end;
    %   end
    
    % set defaults
    % ------------
    g.incallback = 0;
    g.winstatus = 1;
    g.setelectrode  = 0;
    [g.chans,g.frames,tmpnb] = size(data);
    g.frames = g.frames*tmpnb;
    g.nbdat = 1; % deprecated
    g.time  = 0;
    g.elecoffset = 0;
    
    % %%%%%%%%%%%%%%%%%%%%%%%%
    % Prepare figure and axes
    % %%%%%%%%%%%%%%%%%%%%%%%%
    
    figh = figure('UserData', g,... % store the settings here
        'Color',DEFAULT_FIG_COLOR, 'name', g.title,...
        'MenuBar','none','tag', g.tag ,'Position',g.position, ...
        'numbertitle', 'off', 'visible', 'off', 'Units', 'Normalized');
    
    pos = get(figh,'position'); % plot relative to current axes
    q = [pos(1) pos(2) 0 0];
    s = [pos(3) pos(4) pos(3) pos(4)]./100;
    clf;
    
    % Plot title if provided
    if ~isempty(g.plottitle)
        h = findobj('tag', 'eegplottitle');
        if ~isempty(h)
            set(h, 'string',g.plottitle);
        else
            h = textsc(g.plottitle, 'title');
            set(h, 'tag', 'eegplottitle');
        end;
    end
    
    % Background axis
    % ---------------
    ax0 = axes('tag','backeeg','parent',figh,...
        'Position',DEFAULT_AXES_POSITION,...
        'Box','off','xgrid','off', 'xaxislocation', 'top', 'Units', 'Normalized');
    
    % Drawing axis
    % ---------------
    YLabels = num2str((1:g.chans)');  % Use numbers as default
    YLabels = flipud(str2mat(YLabels,' '));
    ax1 = axes('Position',DEFAULT_AXES_POSITION,...
        'userdata', data, ...% store the data here
        'tag','eegaxis','parent',figh,...%(when in g, slow down display)
        'Box','on','xgrid', g.xgrid,'ygrid', g.ygrid,...
        'gridlinestyle',DEFAULT_GRID_STYLE,...
        'Xlim',[0 g.winlength*g.srate],...
        'xtick',[0:g.srate*DEFAULT_GRID_SPACING:g.winlength*g.srate],...
        'Ylim',[0 (g.chans+1)*g.spacing],...
        'YTick',[0:g.spacing:g.chans*g.spacing],...
        'YTickLabel', YLabels,...
        'XTickLabel',num2str((0:DEFAULT_GRID_SPACING:g.winlength)'),...
        'TickLength',[.005 .005],...
        'Color','none',...
        'XColor',DEFAULT_AXIS_COLOR,...
        'YColor',DEFAULT_AXIS_COLOR);
    
    if isstr(g.eloc_file) | isstruct(g.eloc_file)  % Read in electrode names
        if isstruct(g.eloc_file) & length(g.eloc_file) > size(data,1)
            g.eloc_file(end) = []; % common reference channel location
        end;
        eegplot('setelect', g.eloc_file, ax1);
    end;
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%
    % Set up uicontrols
    % %%%%%%%%%%%%%%%%%%%%%%%%%
    
    % positions of buttons
    posbut(1,:) = [ 0.0464    0.0254    0.0385    0.0339 ]; % <<
    posbut(2,:) = [ 0.0924    0.0254    0.0288    0.0339 ]; % <
    posbut(3,:) = [ 0.1924    0.0254    0.0299    0.0339 ]; % >
    posbut(4,:) = [ 0.2297    0.0254    0.0385    0.0339 ]; % >>
    posbut(5,:) = [ 0.1287    0.0203    0.0561    0.0390 ]; % Eposition
    posbut(6,:) = [ 0.4744    0.0236    0.0582    0.0390 ]; % Espacing
    posbut(7,:) = [ 0.2762    0.01    0.0582    0.0390 ]; % elec
    posbut(8,:) = [ 0.3256    0.01    0.0707    0.0390 ]; % g.time
    posbut(9,:) = [ 0.4006    0.01    0.0582    0.0390 ]; % value
    posbut(14,:) = [ 0.2762    0.05    0.0582    0.0390 ]; % elec tag
    posbut(15,:) = [ 0.3256    0.05    0.0707    0.0390 ]; % g.time tag
    posbut(16,:) = [ 0.4006    0.05    0.0582    0.0390 ]; % value tag
    posbut(10,:) = [ 0.5437    0.0458    0.0275    0.0270 ]; % +
    posbut(11,:) = [ 0.5437    0.0134    0.0275    0.0270 ]; % -
    posbut(12,:) = [ 0.6    0.02    0.14    0.05 ]; % cancel
    posbut(13,:) = [-0.15   0.02    0.07    0.05 ]; % cancel
    posbut(17,:) = [-0.06    0.02    0.09    0.05 ]; % events types
    posbut(20,:) = [-0.17   0.15     0.015    0.8 ]; % slider
    %posbut(21,:) = [0.738    0.87    0.06      0.048];%normalize
    %posbut(22,:) = [0.738    0.93    0.06      0.048];%stack channels(same offset)
    posbut(:,1) = posbut(:,1)+0.2;
    
    % Five move buttons: << < text > >>
    
    u(1) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'Position', posbut(1,:), ...
        'Tag','Pushbutton1',...
        'string','<<',...
        'Callback',['global in_callback;', ...
        'if isempty(in_callback);in_callback=1;', ...
        '    try eegplot(''drawp'',1);', ...
        '        clear global in_callback;', ...
        '    catch error_struct;', ...
        '        clear global in_callback;', ...
        '        throw(error_struct);', ...
        '    end;', ...
        'else;return;end;']);%James Desjardins 2013/Jan/22
    u(2) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'Position', posbut(2,:), ...
        'Tag','Pushbutton2',...
        'string','<',...
        'Callback',['global in_callback;', ...
        'if isempty(in_callback);in_callback=1;', ...
        '    try eegplot(''drawp'',2);', ...
        '        clear global in_callback;', ...
        '    catch error_struct;', ...
        '        clear global in_callback;', ...
        '        throw(error_struct);', ...
        '    end;', ...
        'else;return;end;']);%James Desjardins 2013/Jan/22
    u(5) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'BackgroundColor',[1 1 1], ...
        'Position', posbut(5,:), ...
        'Style','edit', ...
        'Tag','EPosition',...
        'string', fastif(g.trialstag(1) == -1, '0', '1'),...
        'Callback', 'eegplot(''drawp'',0);' );
    u(3) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'Position',posbut(3,:), ...
        'Tag','Pushbutton3',...
        'string','>',...
        'Callback',['global in_callback;', ...
        'if isempty(in_callback);in_callback=1;', ...
        '    try eegplot(''drawp'',3);', ...
        '        clear global in_callback;', ...
        '    catch error_struct;', ...
        '        clear global in_callback;', ...
        '        throw(error_struct);', ...
        '    end;', ...
        'else;return;end;']);%James Desjardins 2013/Jan/22
    u(4) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'Position',posbut(4,:), ...
        'Tag','Pushbutton4',...
        'string','>>',...
        'Callback',['global in_callback;', ...
        'if isempty(in_callback);in_callback=1;', ...
        '    try eegplot(''drawp'',4);', ...
        '        clear global in_callback;', ...
        '    catch error_struct;', ...
        '        clear global in_callback;', ...
        '        error(error_struct);', ...
        '    end;', ...
        'else;return;end;']);%James Desjardins 2013/Jan/22
    
    % Text edit fields: ESpacing
    
    u(6) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'BackgroundColor',[1 1 1], ...
        'Position', posbut(6,:), ...
        'Style','edit', ...
        'Tag','ESpacing',...
        'string',num2str(g.spacing),...
        'Callback', 'eegplot(''draws'',0);' );
    
    % Slider for vertical motion
    u(20) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'Position', posbut(20,:), ...
        'Style','slider', ...
        'visible', 'off', ...
        'sliderstep', [0.9 1], ...
        'Tag','eegslider', ...
        'callback', [ 'tmpg = get(gcbf, ''userdata'');' ...
        'tmpg.elecoffset = get(gcbo, ''value'')*(tmpg.chans-tmpg.dispchans);' ...
        'set(gcbf, ''userdata'', tmpg);' ...
        'eegplot(''drawp'',0);' ...
        'clear tmpg;' ], ...
        'value', 0);
    
    % Channels, position, value and tag
    
    u(9) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'BackgroundColor',DEFAULT_FIG_COLOR, ...
        'Position', posbut(7,:), ...
        'Style','text', ...
        'Tag','Eelec',...
        'string',' ');
    u(10) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'BackgroundColor',DEFAULT_FIG_COLOR, ...
        'Position', posbut(8,:), ...
        'Style','text', ...
        'Tag','Etime',...
        'string','0.00');
    u(11) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'BackgroundColor',DEFAULT_FIG_COLOR, ...
        'Position',posbut(9,:), ...
        'Style','text', ...
        'Tag','Evalue',...
        'string','0.00');
    
    u(14)= uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'BackgroundColor',DEFAULT_FIG_COLOR, ...
        'Position', posbut(14,:), ...
        'Style','text', ...
        'Tag','Eelecname',...
        'string','Chan.');
    
    % Values of time/value and freq/power in GUI
    if g.isfreq
        u15_string =  'Freq';
        u16_string  = 'Power';
    else
        u15_string =  'Time';
        u16_string  = 'Value';
    end
    
    u(15) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'BackgroundColor',DEFAULT_FIG_COLOR, ...
        'Position', posbut(15,:), ...
        'Style','text', ...
        'Tag','Etimename',...
        'string',u15_string);
    
    u(16) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'BackgroundColor',DEFAULT_FIG_COLOR, ...
        'Position',posbut(16,:), ...
        'Style','text', ...
        'Tag','Evaluename',...
        'string',u16_string);
    
    % ESpacing buttons: + -
    u(7) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'Position',posbut(10,:), ...
        'Tag','Pushbutton5',...
        'string','+',...
        'FontSize',8,...
        'Callback','eegplot(''draws'',1)');
    u(8) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'Position',posbut(11,:), ...
        'Tag','Pushbutton6',...
        'string','-',...
        'FontSize',8,...
        'Callback','eegplot(''draws'',2)');
    
    cb_normalize = ['g = get(gcbf,''userdata'');if g.normed, disp(''Denormalizing...''); else, disp(''Normalizing...''); end;'...
        'hmenu = findobj(gcf, ''Tag'', ''Normalize_menu'');' ...
        'ax1 = findobj(''tag'',''eegaxis'',''parent'',gcbf);' ...
        'data = get(ax1,''UserData'');' ...
        'if isempty(g.datastd), g.datastd = std(data(:,1:min(1000,g.frames),[],2)); end;'...
        'if g.normed, '...
        'for i = 1:size(data,1), '...
        'data(i,:,:) = data(i,:,:)*g.datastd(i);'...
        'if ~isempty(g.data2), g.data2(i,:,:) = g.data2(i,:,:)*g.datastd(i);end;'...
        'end;'...
        'set(gcbo,''string'', ''Norm'');set(findobj(''tag'',''ESpacing'',''parent'',gcbf),''string'',num2str(g.oldspacing));' ...
        'else, for i = 1:size(data,1),'...
        'data(i,:,:) = data(i,:,:)/g.datastd(i);'...
        'if ~isempty(g.data2), g.data2(i,:,:) = g.data2(i,:,:)/g.datastd(i);end;'...
        'end;'...
        'set(gcbo,''string'', ''Denorm'');g.oldspacing = g.spacing;set(findobj(''tag'',''ESpacing'',''parent'',gcbf),''string'',''5'');end;' ...
        'g.normed = 1 - g.normed;' ...
        'eegplot(''draws'',0);'...
        'set(hmenu, ''Label'', fastif(g.normed,''Denormalize channels'',''Normalize channels''));' ...
        'set(gcbf,''userdata'',g);set(ax1,''UserData'',data);clear ax1 g data;' ...
        'eegplot(''drawp'',0);' ...
        'disp(''Done.'')'];
    % Button for Normalizing data
    % u(21) = uicontrol('Parent',figh, ...
    %     'Units', 'normalized', ...
    %     'Position',posbut(21,:), ...
    %     'Tag','Norm',...
    %     'string','Norm', 'callback', cb_normalize);
    
    cb_envelope = ['g = get(gcbf,''userdata'');'...
        'hmenu = findobj(gcf, ''Tag'', ''Envelope_menu'');' ...
        'g.envelope = ~g.envelope;' ...
        'set(gcbf,''userdata'',g);'...
        'set(gcbo,''string'',fastif(g.envelope,''Spread'',''Stack''));' ...
        'set(hmenu, ''Label'', fastif(g.envelope,''Spread channels'',''Stack channels''));' ...
        'eegplot(''drawp'',0);clear g;'];
    
    % Button to plot envelope of data
    % u(22) = uicontrol('Parent',figh, ...
    %     'Units', 'normalized', ...
    %     'Position',posbut(22,:), ...
    %     'Tag','Envelope',...
    %     'string','Stack', 'callback', cb_envelope);
    
    
    if isempty(g.command) tmpcom = 'fprintf(''Rejections saved in variable TMPREJ\n'');';
    else tmpcom = g.command;
    end;
    acceptcommand = [ 'g = get(gcbf, ''userdata'');' ...
        'TMPREJ = g.winrej;' ...
        'if g.children, delete(g.children); end;' ...
        'delete(gcbf);' ...
        tmpcom ...
        '; clear g;']; % quitting expression
    if ~isempty(g.command)
        u(12) = uicontrol('Parent',figh, ...
            'Units', 'normalized', ...
            'Position',posbut(12,:), ...
            'Tag','Accept',...
            'string',g.butlabel, 'callback', acceptcommand);
    end;
    u(13) = uicontrol('Parent',figh, ...
        'Units', 'normalized', ...
        'Position',posbut(13,:), ...
        'string',fastif(isempty(g.command),'CLOSE', 'CANCEL'), 'callback', ...
        [	'g = get(gcbf, ''userdata'');' ...
        'if g.children, delete(g.children); end;' ...
        'close(gcbf);'] );
    
    if ~isempty(g.events)
        u(17) = uicontrol('Parent',figh, ...
            'Units', 'normalized', ...
            'Position',posbut(17,:), ...
            'string', 'Event types', 'callback', 'eegplot(''drawlegend'', gcbf)');
    end;
    
    for i = 1: length(u) % Matlab 2014b compatibility
        if isprop(eval(['u(' num2str(i) ')']),'Style')
            set(u(i),'Units','Normalized');
        end
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set up uimenus
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Figure Menu %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    m(7) = uimenu('Parent',figh,'Label','Figure');
    m(8) = uimenu('Parent',m(7),'Label','Print');
    uimenu('Parent',m(7),'Label','Edit figure', 'Callback', 'eegplot(''noui'');');
    %   uimenu('Parent',m(7),'Label','Accept and close', 'Callback', acceptcommand );
    uimenu('Parent',m(7),'Label','Cancel and close', 'Callback','delete(gcbf)')
    
    % Portrait %%%%%%%%
    
    timestring = ['[OBJ1,FIG1] = gcbo;',...
        'PANT1 = get(OBJ1,''parent'');',...
        'OBJ2 = findobj(''tag'',''orient'',''parent'',PANT1);',...
        'set(OBJ2,''checked'',''off'');',...
        'set(OBJ1,''checked'',''on'');',...
        'set(FIG1,''PaperOrientation'',''portrait'');',...
        'clear OBJ1 FIG1 OBJ2 PANT1;'];
    
    uimenu('Parent',m(8),'Label','Portrait','checked',...
        'on','tag','orient','callback',timestring)
    
    % Landscape %%%%%%%
    timestring = ['[OBJ1,FIG1] = gcbo;',...
        'PANT1 = get(OBJ1,''parent'');',...
        'OBJ2 = findobj(''tag'',''orient'',''parent'',PANT1);',...
        'set(OBJ2,''checked'',''off'');',...
        'set(OBJ1,''checked'',''on'');',...
        'set(FIG1,''PaperOrientation'',''landscape'');',...
        'clear OBJ1 FIG1 OBJ2 PANT1;'];
    
    uimenu('Parent',m(8),'Label','Landscape','checked',...
        'off','tag','orient','callback',timestring)
    
    % Print command %%%%%%%
    uimenu('Parent',m(8),'Label','Print','tag','printcommand','callback',...
        ['RESULT = inputdlg2( { ''Command:'' }, ''Print'', 1,  { ''print -r72'' });' ...
        'if size( RESULT,1 ) ~= 0' ...
        '  eval ( RESULT{1} );' ...
        'end;' ...
        'clear RESULT;' ]);
    
    % Display Menu %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    m(1) = uimenu('Parent',figh,...
        'Label','Display', 'tag', 'displaymenu');
    
    % window grid %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % userdata = 4 cells : display yes/no, color, electrode yes/no,
    %                      trial boundary adapt yes/no (1/0)
    m(11) = uimenu('Parent',m(1),'Label','Data select/mark', 'tag', 'displaywin', ...
        'userdata', { 1, [0.8 1 0.8], 0, fastif( g.trialstag(1) == -1, 0, 1)});
    
    uimenu('Parent',m(11),'Label','Hide marks','Callback', ...
        ['g = get(gcbf, ''userdata'');' ...
        'if ~g.winstatus' ...
        '  set(gcbo, ''label'', ''Hide marks'');' ...
        'else' ...
        '  set(gcbo, ''label'', ''Show marks'');' ...
        'end;' ...
        'g.winstatus = ~g.winstatus;' ...
        'set(gcbf, ''userdata'', g);' ...
        'eegplot(''drawb''); clear g;'] )
    
    % color %%%%%%%%%%%%%%%%%%%%%%%%%%
    if isunix % for some reasons, does not work under Windows
        uimenu('Parent',m(11),'Label','Choose color', 'Callback', ...
            [ 'g = get(gcbf, ''userdata'');' ...
            'g.wincolor = uisetcolor(g.wincolor);' ...
            'set(gcbf, ''userdata'', g ); ' ...
            'clear g;'] )
    end;
    
    % set channels
    %uimenu('Parent',m(11),'Label','Mark channels', 'enable', 'off', ...
    %'checked', 'off', 'Callback', ...
    %['g = get(gcbf, ''userdata'');' ...
    % 'g.setelectrode = ~g.setelectrode;' ...
    % 'set(gcbf, ''userdata'', g); ' ...
    % 'if ~g.setelectrode setgcbo, ''checked'', ''on''); ...
    % else set(gcbo, ''checked'', ''off''); end;'...
    % ' clear g;'] )
    
    % trials boundaries
    %uimenu('Parent',m(11),'Label','Trial boundaries', 'checked', fastif( g.trialstag(1) == -1, 'off', 'on'), 'Callback', ...
    %['hh = findobj(''tag'',''displaywin'',''parent'', findobj(''tag'',''displaymenu'',''parent'', gcbf ));' ...
    % 'hhdat = get(hh, ''userdata'');' ...
    % 'set(hh, ''userdata'', { hhdat{1},  hhdat{2}, hhdat{3}, ~hhdat{4}} ); ' ...
    %'if ~hhdat{4} set(gcbo, ''checked'', ''on''); else set(gcbo, ''checked'', ''off''); end;' ...
    %' clear hh hhdat;'] )
    
    % plot durations
    % --------------
    if g.ploteventdur & isfield(g.events, 'duration')
        disp(['Use menu "Display > Hide event duration" to hide colored regions ' ...
            'representing event duration']);
    end;
    if isfield(g.events, 'duration')
        uimenu('Parent',m(1),'Label',fastif(g.ploteventdur, 'Hide event duration', 'Plot event duration'),'Callback', ...
            ['g = get(gcbf, ''userdata'');' ...
            'if ~g.ploteventdur' ...
            '  set(gcbo, ''label'', ''Hide event duration'');' ...
            'else' ...
            '  set(gcbo, ''label'', ''Show event duration'');' ...
            'end;' ...
            'g.ploteventdur = ~g.ploteventdur;' ...
            'set(gcbf, ''userdata'', g);' ...
            'eegplot(''drawb''); clear g;'] )
    end;
    
    % X grid %%%%%%%%%%%%
    m(3) = uimenu('Parent',m(1),'Label','Grid');
    timestring = ['FIGH = gcbf;',...
        'AXESH = findobj(''tag'',''eegaxis'',''parent'',FIGH);',...
        'if size(get(AXESH,''xgrid''),2) == 2' ... %on
        '  set(AXESH,''xgrid'',''off'');',...
        '  set(gcbo,''label'',''X grid on'');',...
        'else' ...
        '  set(AXESH,''xgrid'',''on'');',...
        '  set(gcbo,''label'',''X grid off'');',...
        'end;' ...
        'clear FIGH AXESH;' ];
    uimenu('Parent',m(3),'Label',fastif(strcmp(g.xgrid, 'off'), ...
        'X grid on','X grid off'), 'Callback',timestring)
    
    % Y grid %%%%%%%%%%%%%
    timestring = ['FIGH = gcbf;',...
        'AXESH = findobj(''tag'',''eegaxis'',''parent'',FIGH);',...
        'if size(get(AXESH,''ygrid''),2) == 2' ... %on
        '  set(AXESH,''ygrid'',''off'');',...
        '  set(gcbo,''label'',''Y grid on'');',...
        'else' ...
        '  set(AXESH,''ygrid'',''on'');',...
        '  set(gcbo,''label'',''Y grid off'');',...
        'end;' ...
        'clear FIGH AXESH;' ];
    uimenu('Parent',m(3),'Label',fastif(strcmp(g.ygrid, 'off'), ...
        'Y grid on','Y grid off'), 'Callback',timestring)
    
    % Grid Style %%%%%%%%%
    m(5) = uimenu('Parent',m(3),'Label','Grid Style');
    timestring = ['FIGH = gcbf;',...
        'AXESH = findobj(''tag'',''eegaxis'',''parent'',FIGH);',...
        'set(AXESH,''gridlinestyle'',''--'');',...
        'clear FIGH AXESH;'];
    uimenu('Parent',m(5),'Label','- -','Callback',timestring)
    timestring = ['FIGH = gcbf;',...
        'AXESH = findobj(''tag'',''eegaxis'',''parent'',FIGH);',...
        'set(AXESH,''gridlinestyle'',''-.'');',...
        'clear FIGH AXESH;'];
    uimenu('Parent',m(5),'Label','_ .','Callback',timestring)
    timestring = ['FIGH = gcbf;',...
        'AXESH = findobj(''tag'',''eegaxis'',''parent'',FIGH);',...
        'set(AXESH,''gridlinestyle'','':'');',...
        'clear FIGH AXESH;'];
    uimenu('Parent',m(5),'Label','. .','Callback',timestring)
    timestring = ['FIGH = gcbf;',...
        'AXESH = findobj(''tag'',''eegaxis'',''parent'',FIGH);',...
        'set(AXESH,''gridlinestyle'',''-'');',...
        'clear FIGH AXESH;'];
    uimenu('Parent',m(5),'Label','__','Callback',timestring)
    
    % Submean menu %%%%%%%%%%%%%
    cb =       ['g = get(gcbf, ''userdata'');' ...
        'if strcmpi(g.submean, ''on''),' ...
        '  set(gcbo, ''label'', ''Remove DC offset'');' ...
        '  g.submean =''off'';' ...
        'else' ...
        '  set(gcbo, ''label'', ''Do not remove DC offset'');' ...
        '  g.submean =''on'';' ...
        'end;' ...
        'set(gcbf, ''userdata'', g);' ...
        'eegplot(''drawp'', 0); clear g;'];
    uimenu('Parent',m(1),'Label',fastif(strcmp(g.submean, 'on'), ...
        'Do not remove DC offset','Remove DC offset'), 'Callback',cb)
    
    % Scale Eye %%%%%%%%%
    timestring = ['[OBJ1,FIG1] = gcbo;',...
        'eegplot(''scaleeye'',OBJ1,FIG1);',...
        'clear OBJ1 FIG1;'];
    m(7) = uimenu('Parent',m(1),'Label','Show scale','Callback',timestring);
    
    % Title %%%%%%%%%%%%
    uimenu('Parent',m(1),'Label','Title','Callback','eegplot(''title'')')
    
    % Stack/Spread %%%%%%%%%%%%%%%
    cb =       ['g = get(gcbf, ''userdata'');' ...
        'hbutton = findobj(gcf, ''Tag'', ''Envelope'');' ...  % find button
        'if g.envelope == 0,' ...
        '  set(gcbo, ''label'', ''Spread channels'');' ...
        '  g.envelope = 1;' ...
        '  set(hbutton, ''String'', ''Spread'');' ...
        'else' ...
        '  set(gcbo, ''label'', ''Stack channels'');' ...
        '  g.envelope = 0;' ...
        '  set(hbutton, ''String'', ''Stack'');' ...
        'end;' ...
        'set(gcbf, ''userdata'', g);' ...
        'eegplot(''drawp'', 0); clear g;'];
    uimenu('Parent',m(1),'Label',fastif(g.envelope == 0, ...
        'Stack channels','Spread channels'), 'Callback',cb, 'Tag', 'Envelope_menu')
    
    % Normalize/denormalize %%%%%%%%%%%%%%%
    cb_normalize = ['g = get(gcbf,''userdata'');if g.normed, disp(''Denormalizing...''); else, disp(''Normalizing...''); end;'...
        'hbutton = findobj(gcf, ''Tag'', ''Norm'');' ...  % find button
        'ax1 = findobj(''tag'',''eegaxis'',''parent'',gcbf);' ...
        'data = get(ax1,''UserData'');' ...
        'if isempty(g.datastd), g.datastd = std(data(:,1:min(1000,g.frames),[],2)); end;'...
        'if g.normed, '...
        '  for i = 1:size(data,1), '...
        '    data(i,:,:) = data(i,:,:)*g.datastd(i);'...
        '    if ~isempty(g.data2), g.data2(i,:,:) = g.data2(i,:,:)*g.datastd(i);end;'...
        '  end;'...
        '  set(hbutton,''string'', ''Norm'');set(findobj(''tag'',''ESpacing'',''parent'',gcbf),''string'',num2str(g.oldspacing));' ...
        '  set(gcbo, ''label'', ''Normalize channels'');' ...
        'else, for i = 1:size(data,1),'...
        '    data(i,:,:) = data(i,:,:)/g.datastd(i);'...
        '    if ~isempty(g.data2), g.data2(i,:,:) = g.data2(i,:,:)/g.datastd(i);end;'...
        '  end;'...
        '  set(hbutton,''string'', ''Denorm'');'...
        '  set(gcbo, ''label'', ''Denormalize channels'');' ...
        '  g.oldspacing = g.spacing;set(findobj(''tag'',''ESpacing'',''parent'',gcbf),''string'',''5'');end;' ...
        'g.normed = 1 - g.normed;' ...
        'eegplot(''draws'',0);'...
        'set(gcbf,''userdata'',g);set(ax1,''UserData'',data);clear ax1 g data;' ...
        'eegplot(''drawp'',0);' ...
        'disp(''Done.'')'];
    uimenu('Parent',m(1),'Label',fastif(g.envelope == 0, ...
        'Normalize channels','Denormalize channels'), 'Callback',cb_normalize, 'Tag', 'Normalize_menu')
    
    
    % Settings Menu %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    m(2) = uimenu('Parent',figh,...
        'Label','Settings');
    
    % Window %%%%%%%%%%%%
    uimenu('Parent',m(2),'Label','Time range to display',...
        'Callback','eegplot(''window'')')
    
    % Electrode window %%%%%%%%
    uimenu('Parent',m(2),'Label','Number of channels to display',...
        'Callback','eegplot(''winelec'')')
    
    % Electrodes %%%%%%%%
    m(6) = uimenu('Parent',m(2),'Label','Channel labels');
    
    timestring = ['FIGH = gcbf;',...
        'AXESH = findobj(''tag'',''eegaxis'',''parent'',FIGH);',...
        'YTICK = get(AXESH,''YTick'');',...
        'YTICK = length(YTICK);',...
        'set(AXESH,''YTickLabel'',flipud(str2mat(num2str((1:YTICK-1)''),'' '')));',...
        'clear FIGH AXESH YTICK;'];
    uimenu('Parent',m(6),'Label','Show number','Callback',timestring)
    uimenu('Parent',m(6),'Label','Load .loc(s) file',...
        'Callback','eegplot(''loadelect'');')
    
    % Zooms %%%%%%%%
    zm = uimenu('Parent',m(2),'Label','Zoom off/on');
    if verLessThan('matlab','8.4.0')
        commandzoom = [ 'set(gcbf, ''WindowButtonDownFcn'', [ ''zoom(gcbf,''''down''''); eegplot(''''zoom'''', gcbf, 1);'' ]);' ...
            'tmpg = get(gcbf, ''userdata'');' ...
            'clear tmpg tmpstr;'];
    else
        % Temporary fix to avoid warning when setting a callback and the  mode is active
        % This is failing for us http://undocumentedmatlab.com/blog/enabling-user-callbacks-during-zoom-pan
        commandzoom = [ 'wtemp = warning; warning off;set(gcbf, ''WindowButtonDownFcn'', [ ''zoom(gcbf); eegplot(''''zoom'''', gcbf, 1);'' ]);' ...
            'tmpg = get(gcbf, ''userdata'');' ...
            'warning(wtemp);'...
            'clear wtemp tmpg tmpstr; '];
    end
    
    %uimenu('Parent',zm,'Label','Zoom time', 'callback', ...
    %             [ 'zoom(gcbf, ''xon'');' commandzoom ]);
    %uimenu('Parent',zm,'Label','Zoom channels', 'callback', ...
    %             [ 'zoom(gcbf, ''yon'');' commandzoom ]);
    uimenu('Parent',zm,'Label','Zoom on', 'callback', commandzoom);
    uimenu('Parent',zm,'Label','Zoom off', 'separator', 'on', 'callback', ...
        ['zoom(gcbf, ''off''); tmpg = get(gcbf, ''userdata'');' ...
        'set(gcbf, ''windowbuttondownfcn'', tmpg.commandselect{1});' ...
        'set(gcbf, ''windowbuttonupfcn'', tmpg.commandselect{3});' ...
        'clear tmpg;' ]);
    
    %   uimenu('Parent',figh,'Label', 'Help', 'callback', 'pophelp(''eegplot'');');
    
    % Events %%%%%%%%
    zm = uimenu('Parent',m(2),'Label','Events');
    complotevent = [ 'tmpg = get(gcbf, ''userdata'');' ...
        'tmpg.plotevent = ''on'';' ...
        'set(gcbf, ''userdata'', tmpg); clear tmpg; eegplot(''drawp'', 0);'];
    comnoevent   = [ 'tmpg = get(gcbf, ''userdata'');' ...
        'tmpg.plotevent = ''off'';' ...
        'set(gcbf, ''userdata'', tmpg); clear tmpg; eegplot(''drawp'', 0);'];
    comeventmaxstring   = [ 'tmpg = get(gcbf, ''userdata'');' ...
        'tmpg.plotevent = ''on'';' ...
        'set(gcbf, ''userdata'', tmpg); clear tmpg; eegplot(''emaxstring'');']; % JavierLC
    comeventleg  = [ 'eegplot(''drawlegend'', gcbf);'];
    
    uimenu('Parent',zm,'Label','Events on'    , 'callback', complotevent, 'enable', fastif(isempty(g.events), 'off', 'on'));
    uimenu('Parent',zm,'Label','Events off'   , 'callback', comnoevent  , 'enable', fastif(isempty(g.events), 'off', 'on'));
    uimenu('Parent',zm,'Label','Events'' string length'   , 'callback', comeventmaxstring, 'enable', fastif(isempty(g.events), 'off', 'on')); % JavierLC
    uimenu('Parent',zm,'Label','Events'' legend', 'callback', comeventleg , 'enable', fastif(isempty(g.events), 'off', 'on'));
    
    
    % %%%%%%%%%%%%%%%%%
    % Set up autoselect
    % NOTE: commandselect{2} option has been moved to a
    %       subfunction to improve speed
    %%%%%%%%%%%%%%%%%%%
    g.commandselect{1} = [ 'if strcmp(get(gcbf, ''SelectionType''),''alt''),' g.ctrlselectcommand{1} ...
        'else '                                            g.selectcommand{1} 'end;' ];
    g.commandselect{3} = [ 'if strcmp(get(gcbf, ''SelectionType''),''alt''),' g.ctrlselectcommand{3} ...
        'else '                                            g.selectcommand{3} 'end;' ];
    
    set(figh, 'windowbuttondownfcn',   g.commandselect{1});
    set(figh, 'windowbuttonmotionfcn', {@defmotion,figh,ax0,ax1,u(10),u(11),u(9)});
    set(figh, 'windowbuttonupfcn',     g.commandselect{3});
    set(figh, 'WindowKeyPressFcn',     @eegplot_readkey);
    set(figh, 'interruptible', 'off');
    set(figh, 'busyaction', 'cancel');
    %  set(figh, 'windowbuttondownfcn', commandpush);
    %  set(figh, 'windowbuttonmotionfcn', commandmove);
    %  set(figh, 'windowbuttonupfcn', commandrelease);
    %  set(figh, 'interruptible', 'off');
    %  set(figh, 'busyaction', 'cancel');
    
    % prepare event array if any
    % --------------------------
    if ~isempty(g.events)
        if ~isfield(g.events, 'type') | ~isfield(g.events, 'latency'), g.events = []; end;
    end;
    
    if ~isempty(g.events)
        if isstr(g.events(1).type)
            [g.eventtypes tmpind indexcolor] = unique_bc({g.events.type}); % indexcolor countinas the event type
        else [g.eventtypes tmpind indexcolor] = unique_bc([ g.events.type ]);
        end;
        g.eventcolors     = { 'r', [0 0.8 0], 'm', 'c', 'k', 'b', [0 0.8 0] };
        g.eventstyle      = { '-' '-' '-'  '-'  '-' '-' '-' '--' '--' '--'  '--' '--' '--' '--'};
        g.eventwidths     = [ 2.5 1 ];
        g.eventtypecolors = g.eventcolors(mod([1:length(g.eventtypes)]-1 ,length(g.eventcolors))+1);
        g.eventcolors     = g.eventcolors(mod(indexcolor-1               ,length(g.eventcolors))+1);
        g.eventtypestyle  = g.eventstyle (mod([1:length(g.eventtypes)]-1 ,length(g.eventstyle))+1);
        g.eventstyle      = g.eventstyle (mod(indexcolor-1               ,length(g.eventstyle))+1);
        
        % for width, only boundary events have width 2 (for the line)
        % -----------------------------------------------------------
        indexwidth = ones(1,length(g.eventtypes))*2;
        if iscell(g.eventtypes)
            for index = 1:length(g.eventtypes)
                if strcmpi(g.eventtypes{index}, 'boundary'), indexwidth(index) = 1; end;
            end;
        end;
        g.eventtypewidths = g.eventwidths (mod(indexwidth([1:length(g.eventtypes)])-1 ,length(g.eventwidths))+1);
        g.eventwidths     = g.eventwidths (mod(indexwidth(indexcolor)-1               ,length(g.eventwidths))+1);
        
        % latency and duration of events
        % ------------------------------
        g.eventlatencies  = [ g.events.latency ]+1;
        if isfield(g.events, 'duration')
            durations = { g.events.duration };
            durations(cellfun(@isempty, durations)) = { NaN };
            g.eventlatencyend   = g.eventlatencies + [durations{:}]+1;
        else g.eventlatencyend   = [];
        end;
        g.plotevent       = 'on';
    end;
    if isempty(g.events)
        g.plotevent      = 'off';
    end;
    
    set(figh, 'userdata', g);
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot EEG Data
    % %%%%%%%%%%%%%%%%%%%%%%%%%%
    axes(ax1)
    hold on
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot Spacing I
    % %%%%%%%%%%%%%%%%%%%%%%%%%%
    YLim = get(ax1,'Ylim');
    A = DEFAULT_AXES_POSITION;
    axes('Position',[A(1)+A(3) A(2) 1-A(1)-A(3) A(4)],'Visible','off','Ylim',YLim,'tag','eyeaxes')
    axis manual
    if strcmp(SPACING_EYE,'on'),  set(m(7),'checked','on')
    else set(m(7),'checked','off');
    end
    eegplot('scaleeye', [], gcf);
    if strcmp(lower(g.scale), 'off')
        eegplot('scaleeye', 'off', gcf);
    end;
    
    eegplot('drawp', 0);
    eegplot('drawp', 0);
    if g.dispchans ~= g.chans
        eegplot('zoom', gcf);
    end;
    eegplot('scaleeye', [], gcf);
    
    h = findobj(gcf, 'style', 'pushbutton');
    set(h, 'backgroundcolor', BUTTON_COLOR);
    h = findobj(gcf, 'tag', 'eegslider');
    set(h, 'backgroundcolor', BUTTON_COLOR);
    set(figh, 'visible', 'on');
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % End Main Function
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
else
    try, p1 = varargin{1}; p2 = varargin{2}; p3 = varargin{3}; catch, end;
    switch data
        case 'drawp' % Redraw EEG and change position
            
            % this test help to couple eegplot windows
            if exist('p3', 'var')
                figh = p3;
                figure(p3);
            else
                figh = gcf;                          % figure handle
            end;
            
            if strcmp(get(figh,'tag'),'dialog')
                figh = get(figh,'UserData');
            end
            ax0 = findobj('tag','backeeg','parent',figh); % axes handle
            ax1 = findobj('tag','eegaxis','parent',figh); % axes handle
            g = get(figh,'UserData');
            data = get(ax1,'UserData');
            ESpacing = findobj('tag','ESpacing','parent',figh);   % ui handle
            EPosition = findobj('tag','EPosition','parent',figh); % ui handle
            if ~isempty(EPosition) && ~isempty(ESpacing)
                if g.trialstag(1) == -1
                    g.time    = str2num(get(EPosition,'string'));
                else
                    g.time    = str2num(get(EPosition,'string'));
                    g.time    = g.time - 1;
                end;
                g.spacing = str2num(get(ESpacing,'string'));
            end;
            
            if p1 == 1
                g.time = g.time-g.winlength;     % << subtract one window length
            elseif p1 == 2
                g.time = g.time-fastif(g.winlength>=1, 1, g.winlength/5);             % < subtract one second
            elseif p1 == 3
                g.time = g.time+fastif(g.winlength>=1, 1, g.winlength/5);             % > add one second
            elseif p1 == 4
                g.time = g.time+g.winlength;     % >> add one window length
            end
            
            if g.trialstag ~= -1 % time in second or in trials
                multiplier = g.trialstag;
            else
                multiplier = g.srate;
            end;
            
            % Update edit box
            % ---------------
            g.time = max(0,min(g.time,ceil((g.frames-1)/multiplier)-g.winlength));
            if g.trialstag(1) == -1
                set(EPosition,'string',num2str(g.time));
            else
                set(EPosition,'string',num2str(g.time+1));
            end;
            set(figh, 'userdata', g);
            
            lowlim = round(g.time*multiplier+1);
            highlim = round(min((g.time+g.winlength)*multiplier+2,g.frames));
            
            % Plot data and update axes
            % -------------------------
            if ~isempty(g.data2)
                switch lower(g.submean) % subtract the mean ?
                    case 'on',
                        meandata = mean(g.data2(:,lowlim:highlim)');
                        if any(isnan(meandata))
                            meandata = nan_mean(g.data2(:,lowlim:highlim)');
                        end;
                    otherwise, meandata = zeros(1,g.chans);
                end;
            else
                switch lower(g.submean) % subtract the mean ?
                    case 'on',
                        meandata = mean(data(:,lowlim:highlim)');
                        if any(isnan(meandata))
                            meandata = nan_mean(data(:,lowlim:highlim)');
                        end;
                    otherwise, meandata = zeros(1,g.chans);
                end;
            end;
            if strcmpi(g.plotdata2, 'off')
                axes(ax1)
                cla
            end;
            
            oldspacing = g.spacing;
            if g.envelope
                g.spacing = 0;
            end
            % plot data
            % ---------
            axes(ax1)
            hold on
            
            % plot channels whose "badchan" field is set to 1.
            % Bad channels are plotted first so that they appear behind the good
            % channels in the eegplot figure window.
            for i = 1:g.chans
                if strcmpi(g.plotdata2, 'on')
                    tmpcolor = [ 1 0 0 ];
                else tmpcolor = g.color{mod(i-1,length(g.color))+1};
                end;
                
                if isfield(g, 'eloc_file') & ...
                        isfield(g.eloc_file, 'badchan') & ...
                        g.eloc_file(g.chans-i+1).badchan;
                    tmpcolor = [ .85 .85 .85 ];
                    plot(data(g.chans-i+1,lowlim:highlim) -meandata(g.chans-i+1)+i*g.spacing + (g.dispchans+1)*(oldspacing-g.spacing)/2 +g.elecoffset*(oldspacing-g.spacing), ...
                        'color', tmpcolor, 'clipping','on')
                    plot(1,mean(data(g.chans-i+1,lowlim:highlim) -meandata(g.chans-i+1)+i*g.spacing + (g.dispchans+1)*(oldspacing-g.spacing)/2 +g.elecoffset*(oldspacing-g.spacing),2),'<r','MarkerFaceColor','r','MarkerSize',6);
                end
                
            end
            
            % plot good channels on top of bad channels (if g.eloc_file(i).badchan = 0... or there is no bad channel information)
            for i = 1:g.chans
                if strcmpi(g.plotdata2, 'on')
                    tmpcolor = [ 1 0 0 ];
                else tmpcolor = g.color{mod(g.chans-i,length(g.color))+1};
                end;
                
                %        keyboard;
                if (isfield(g, 'eloc_file') & ...
                        isfield(g.eloc_file, 'badchan') & ...
                        ~g.eloc_file(g.chans-i+1).badchan) | ...
                        (~isfield(g, 'eloc_file')) | ...
                        (~isfield(g.eloc_file, 'badchan'));
                    plot(data(g.chans-i+1,lowlim:highlim) -meandata(g.chans-i+1)+i*g.spacing + (g.dispchans+1)*(oldspacing-g.spacing)/2 +g.elecoffset*(oldspacing-g.spacing), ...
                        'color', tmpcolor, 'clipping','on')
                end
                
            end
            
            % draw selected channels
            % ------------------------
            if ~isempty(g.winrej) & size(g.winrej,2) > 2
                for tpmi = 1:size(g.winrej,1) % scan rows
                    if (g.winrej(tpmi,1) >= lowlim & g.winrej(tpmi,1) <= highlim) | ...
                            (g.winrej(tpmi,2) >= lowlim & g.winrej(tpmi,2) <= highlim)
                        abscmin = max(1,round(g.winrej(tpmi,1)-lowlim));
                        abscmax = round(g.winrej(tpmi,2)-lowlim);
                        maxXlim = get(gca, 'xlim');
                        abscmax = min(abscmax, round(maxXlim(2)-1));
                        for i = 1:g.chans
                            if g.winrej(tpmi,g.chans-i+1+5)
                                plot(abscmin+1:abscmax+1,data(g.chans-i+1,abscmin+lowlim:abscmax+lowlim) ...
                                    -meandata(g.chans-i+1)+i*g.spacing + (g.dispchans+1)*(oldspacing-g.spacing)/2 +g.elecoffset*(oldspacing-g.spacing), 'color','r','clipping','on')
                            end;
                        end
                    end;
                end;
            end;
            g.spacing = oldspacing;
            set(ax1, 'Xlim',[1 g.winlength*multiplier+1],...
                'XTick',[1:multiplier*DEFAULT_GRID_SPACING:g.winlength*multiplier+1]);
            %          if g.isfreq % Ramon
            %              set(ax1, 'XTickLabel', num2str((g.freqs(1):DEFAULT_GRID_SPACING:g.freqs(end))'));
            %          else
            set(ax1, 'XTickLabel', num2str((g.time:DEFAULT_GRID_SPACING:g.time+g.winlength)'));
            %          end
            
            % ordinates: even if all elec are plotted, some may be hidden
            set(ax1, 'ylim',[g.elecoffset*g.spacing (g.elecoffset+g.dispchans+1)*g.spacing] );
            
            if g.children ~= 0
                if ~exist('p2', 'var')
                    p2 =[];
                end;
                eegplot( 'drawp', p1, p2, g.children);
                figure(figh);
            end;
            
            % draw second data if necessary
            if ~isempty(g.data2)
                tmpdata = data;
                set(ax1, 'userdata', g.data2);
                g.data2 = [];
                g.plotdata2 = 'on';
                set(figh, 'userdata', g);
                eegplot('drawp', 0);
                g.plotdata2 = 'off';
                g.data2 = get(ax1, 'userdata');
                set(ax1, 'userdata', tmpdata);
                set(figh, 'userdata', g);
            else
                eegplot('drawb');
            end;
            
        case 'drawb' % Draw background ******************************************************
            % Redraw EEG and change position
            
            ax0 = findobj('tag','backeeg','parent',gcf); % axes handle
            ax1 = findobj('tag','eegaxis','parent',gcf); % axes handle
            
            g = get(gcf,'UserData');  % Data (Note: this could also be global)
            
            % Plot data and update axes
            axes(ax0);
            cla;
            hold on;
            % plot rejected windows
            if g.trialstag ~= -1
                multiplier = g.trialstag;
            else
                multiplier = g.srate;
            end;
            
            % draw rejection windows
            % ----------------------
            lowlim = round(g.time*multiplier+1);
            highlim = round(min((g.time+g.winlength)*multiplier+1));
            displaymenu = findobj('tag','displaymenu','parent',gcf);
            if ~isempty(g.winrej) & g.winstatus
                if g.trialstag ~= -1 % epoched data
                    indices = find((g.winrej(:,1)' >= lowlim & g.winrej(:,1)' <= highlim) | ...
                        (g.winrej(:,2)' >= lowlim & g.winrej(:,2)' <= highlim));
                    if ~isempty(indices)
                        tmpwins1 = g.winrej(indices,1)';
                        tmpwins2 = g.winrej(indices,2)';
                        if size(g.winrej,2) > 2
                            tmpcols  = g.winrej(indices,3:5);
                        else tmpcols  = g.wincolor;
                        end;
                        try, eval('[cumul indicescount] = histc(tmpwins1, (min(tmpwins1)-1):g.trialstag:max(tmpwins2));');
                        catch, [cumul indicescount] = myhistc(tmpwins1, (min(tmpwins1)-1):g.trialstag:max(tmpwins2));
                        end;
                        count = zeros(size(cumul));
                        %if ~isempty(find(cumul > 1)), find(cumul > 1), end;
                        for tmpi = 1:length(tmpwins1)
                            poscumul = indicescount(tmpi);
                            heightbeg = count(poscumul)/cumul(poscumul);
                            heightend = heightbeg + 1/cumul(poscumul);
                            count(poscumul) = count(poscumul)+1;
                            h = patch([tmpwins1(tmpi)-lowlim tmpwins2(tmpi)-lowlim ...
                                tmpwins2(tmpi)-lowlim tmpwins1(tmpi)-lowlim], ...
                                [heightbeg heightbeg heightend heightend], ...
                                tmpcols(tmpi,:));  % this argument is color
                            set(h, 'EdgeColor', get(h, 'facecolor'))
                        end;
                    end;
                else
                    event2plot1 = find ( g.winrej(:,1) >= lowlim & g.winrej(:,1) <= highlim );
                    event2plot2 = find ( g.winrej(:,2) >= lowlim & g.winrej(:,2) <= highlim );
                    event2plot3 = find ( g.winrej(:,1) <  lowlim & g.winrej(:,2) >  highlim );
                    event2plot  = union_bc(union(event2plot1, event2plot2), event2plot3);
                    
                    for tpmi = event2plot(:)'
                        if size(g.winrej,2) > 2
                            tmpcols  = g.winrej(tpmi,3:5);
                        else tmpcols  = g.wincolor;
                        end;
                        h = patch([g.winrej(tpmi,1)-lowlim g.winrej(tpmi,2)-lowlim ...
                            g.winrej(tpmi,2)-lowlim g.winrej(tpmi,1)-lowlim], ...
                            [0 0 1 1], tmpcols);
                        set(h, 'EdgeColor', get(h, 'facecolor'))
                    end;
                end;
            end;
            
            % plot tags
            % ---------
            %if trialtag(1) ~= -1 & displaystatus % put tags at arbitrary places
            % 	for tmptag = trialtag
            %		if tmptag >= lowlim & tmptag <= highlim
            %			plot([tmptag-lowlim tmptag-lowlim], [0 1], 'b--');
            %		end;
            %	end;
            %end;
            
            % draw events if any
            % ------------------
            if strcmpi(g.plotevent, 'on')
                
                % JavierLC ###############################
                MAXEVENTSTRING = g.maxeventstring;
                if MAXEVENTSTRING<0
                    MAXEVENTSTRING = 0;
                elseif MAXEVENTSTRING>75
                    MAXEVENTSTRING=75;
                end
                AXES_POSITION = [0.0964286 0.15 0.842 0.75-(MAXEVENTSTRING-5)/100];
                % JavierLC ###############################
                
                % find event to plot
                % ------------------
                event2plot    = find ( g.eventlatencies >=lowlim & g.eventlatencies <= highlim );
                if ~isempty(g.eventlatencyend)
                    event2plot2 = find ( g.eventlatencyend >= lowlim & g.eventlatencyend <= highlim );
                    event2plot3 = find ( g.eventlatencies  <  lowlim & g.eventlatencyend >  highlim );
                    event2plot  = union_bc(union(event2plot, event2plot2), event2plot3);
                end;
                for index = 1:length(event2plot)
                    %Just repeat for the first one
                    if index == 1
                        EVENTFONT = ' \fontsize{10} ';
                        ylims=ylim;
                    end
                    
                    % draw latency line
                    % -----------------
                    tmplat = g.eventlatencies(event2plot(index))-lowlim-1;
                    tmph   = plot([ tmplat tmplat ], ylims, 'color', g.eventcolors{ event2plot(index) }, ...
                        'linestyle', g.eventstyle { event2plot(index) }, ...
                        'linewidth', g.eventwidths( event2plot(index) ) );
                    
                    % schtefan: add Event types text above event latency line
                    % -------------------------------------------------------
                    %             EVENTFONT = ' \fontsize{10} ';
                    %             ylims=ylim;
                    evntxt = strrep(num2str(g.events(event2plot(index)).type),'_','-');
                    if length(evntxt)>MAXEVENTSTRING, evntxt = [ evntxt(1:MAXEVENTSTRING-1) '...' ]; end; % truncate
                    try,
                        tmph2 = text([tmplat], ylims(2)-0.005, [EVENTFONT evntxt], ...
                            'color', g.eventcolors{ event2plot(index) }, ...
                            'horizontalalignment', 'left',...
                            'rotation',90);
                    catch, end;
                    
                    % draw duration is not 0
                    % ----------------------
                    if g.ploteventdur & ~isempty(g.eventlatencyend) ...
                            & g.eventwidths( event2plot(index) ) ~= 2.5 % do not plot length of boundary events
                        tmplatend = g.eventlatencyend(event2plot(index))-lowlim-1;
                        if tmplatend ~= 0,
                            tmplim = ylims;
                            tmpcol = g.eventcolors{ event2plot(index) };
                            h = patch([ tmplat tmplatend tmplatend tmplat ], ...
                                [ tmplim(1) tmplim(1) tmplim(2) tmplim(2) ], ...
                                tmpcol );  % this argument is color
                            set(h, 'EdgeColor', 'none')
                        end;
                    end;
                end;
            else % JavierLC
                MAXEVENTSTRING = 10; % default
                AXES_POSITION = [0.0964286 0.15 0.842 0.75-(MAXEVENTSTRING-5)/100];
            end;
            
            if g.trialstag(1) ~= -1
                
                % plot trial limits
                % -----------------
                tmptag = [lowlim:highlim];
                tmpind = find(mod(tmptag-1, g.trialstag) == 0);
                for index = tmpind
                    plot([tmptag(index)-lowlim-1 tmptag(index)-lowlim-1], [0 1], 'b--');
                end;
                alltag = tmptag(tmpind);
                
                % compute Xticks
                % --------------
                tagnum = (alltag-1)/g.trialstag+1;
                set(ax0,'XTickLabel', tagnum,'YTickLabel', [],...
                    'Xlim',[0 g.winlength*multiplier],...
                    'XTick',alltag-lowlim+g.trialstag/2, 'YTick',[], 'tag','backeeg');
                
                axes(ax1);
                tagpos  = [];
                tagtext = [];
                if ~isempty(alltag)
                    alltag = [alltag(1)-g.trialstag alltag alltag(end)+g.trialstag]; % add border trial limits
                else
                    alltag = [ floor(lowlim/g.trialstag)*g.trialstag ceil(highlim/g.trialstag)*g.trialstag ]+1;
                end;
                
                nbdiv = 20/g.winlength; % approximative number of divisions
                divpossible = [ 100000./[1 2 4 5] 10000./[1 2 4 5] 1000./[1 2 4 5] 100./[1 2 4 5 10 20]]; % possible increments
                [tmp indexdiv] = min(abs(nbdiv*divpossible-(g.limits(2)-g.limits(1)))); % closest possible increment
                incrementpoint = divpossible(indexdiv)/1000*g.srate;
                
                % tag zero below is an offset used to be sure that 0 is included
                % in the absicia of the data epochs
                if g.limits(2) < 0, tagzerooffset  = (g.limits(2)-g.limits(1))/1000*g.srate+1;
                else                tagzerooffset  = -g.limits(1)/1000*g.srate;
                end;
                if tagzerooffset < 0, tagzerooffset = 0; end;
                
                for i=1:length(alltag)-1
                    if ~isempty(tagpos) & tagpos(end)-alltag(i)<2*incrementpoint/3
                        tagpos  = tagpos(1:end-1);
                    end;
                    if ~isempty(g.freqlimits)
                        tagpos  = [ tagpos linspace(alltag(i),alltag(i+1)-1, nbdiv) ];
                    else
                        if tagzerooffset ~= 0
                            tmptagpos = [alltag(i)+tagzerooffset:-incrementpoint:alltag(i)];
                        else
                            tmptagpos = [];
                        end;
                        tagpos  = [ tagpos [tmptagpos(end:-1:2) alltag(i)+tagzerooffset:incrementpoint:(alltag(i+1)-1)]];
                    end;
                end;
                
                % find corresponding epochs
                % -------------------------
                if ~g.isfreq
                    tmplimit = g.limits;
                    tpmorder = 1E-3;
                else
                    tmplimit = g.freqlimits;
                    tpmorder = 1;
                end
                tagtext = eeg_point2lat(tagpos, floor((tagpos)/g.trialstag)+1, g.srate, tmplimit,tpmorder);
                set(ax1,'XTickLabel', tagtext,'XTick', tagpos-lowlim);
            else
                set(ax0,'XTickLabel', [],'YTickLabel', [],...
                    'Xlim',[0 g.winlength*multiplier],...
                    'XTick',[], 'YTick',[], 'tag','backeeg');
                
                axes(ax1);
                if g.isfreq
                    set(ax1, 'XTickLabel', num2str((g.freqs(1):DEFAULT_GRID_SPACING:g.freqs(end))'),...
                        'XTick',[1:multiplier*DEFAULT_GRID_SPACING:g.winlength*multiplier+1]);
                else
                    set(ax1,'XTickLabel', num2str((g.time:DEFAULT_GRID_SPACING:g.time+g.winlength)'),...
                        'XTick',[1:multiplier*DEFAULT_GRID_SPACING:g.winlength*multiplier+1]);
                end
                
                set(ax1, 'Position', AXES_POSITION) % JavierLC
                set(ax0, 'Position', AXES_POSITION) % JavierLC
            end;
            
            % ordinates: even if all elec are plotted, some may be hidden
            set(ax1, 'ylim',[g.elecoffset*g.spacing (g.elecoffset+g.dispchans+1)*g.spacing] );
            
            axes(ax1)
            
        case 'draws'
            % Redraw EEG and change scale
            
            ax1 = findobj('tag','eegaxis','parent',gcf);         % axes handle
            g = get(gcf,'UserData');
            data = get(ax1, 'userdata');
            ESpacing = findobj('tag','ESpacing','parent',gcf);   % ui handle
            EPosition = findobj('tag','EPosition','parent',gcf); % ui handle
            if g.trialstag(1) == -1
                g.time    = str2num(get(EPosition,'string'));
            else
                g.time    = str2num(get(EPosition,'string'))-1;
            end;
            g.spacing = str2num(get(ESpacing,'string'));
            
            orgspacing= g.spacing;
            if p1 == 1
                g.spacing= g.spacing+ 0.1*orgspacing; % increase g.spacing(5%)
            elseif p1 == 2
                g.spacing= max(0,g.spacing-0.1*orgspacing); % decrease g.spacing(5%)
            end
            if round(g.spacing*100) == 0
                maxindex = min(10000, g.frames);
                g.spacing = 0.01*max(max(data(:,1:maxindex),[],2),[],1)-min(min(data(:,1:maxindex),[],2),[],1);  % Set g.spacingto max/min data
            end;
            
            % update edit box
            % ---------------
            set(ESpacing,'string',num2str(g.spacing,4))
            set(gcf, 'userdata', g);
            eegplot('drawp', 0);
            set(ax1,'YLim',[0 (g.chans+1)*g.spacing],'YTick',[0:g.spacing:g.chans*g.spacing])
            set(ax1, 'ylim',[g.elecoffset*g.spacing (g.elecoffset+g.dispchans+1)*g.spacing] );
            
            % update scaling eye (I) if it exists
            % -----------------------------------
            eyeaxes = findobj('tag','eyeaxes','parent',gcf);
            if ~isempty(eyeaxes)
                eyetext = findobj('type','text','parent',eyeaxes,'tag','thescalenum');
                set(eyetext,'string',num2str(g.spacing,4))
            end
            
            return;
            
        case 'window'  % change window size
            % get new window length with dialog box
            % -------------------------------------
            g = get(gcf,'UserData');
            result       = inputdlg2( { fastif(g.trialstag==-1,'New window length (s):', 'Number of epoch(s):') }, 'Change window length', 1,  { num2str(g.winlength) });
            if size(result,1) == 0 return; end;
            
            g.winlength = eval(result{1});
            set(gcf, 'UserData', g);
            eegplot('drawp',0);
            return;
            
        case 'winelec'  % change channel window size
            % get new window length with dialog box
            % -------------------------------------
            fig = gcf;
            g = get(gcf,'UserData');
            result = inputdlg2( ...
                { 'Number of channels to display:' } , 'Change number of channels to display', 1,  { num2str(g.dispchans) });
            if size(result,1) == 0 return; end;
            
            g.dispchans = eval(result{1});
            if g.dispchans<0 | g.dispchans>g.chans
                g.dispchans =g.chans;
            end;
            set(gcf, 'UserData', g);
            eegplot('updateslider', fig);
            eegplot('drawp',0);
            eegplot('scaleeye', [], fig);
            return;
            
        case 'emaxstring'  % change events' string length  ;  JavierLC
            % get dialog box
            % -------------------------------------
            g = get(gcf,'UserData');
            result = inputdlg2({ 'Max events'' string length:' } , 'Change events'' string length to display', 1,  { num2str(g.maxeventstring) });
            if size(result,1) == 0 return; end;
            g.maxeventstring = eval(result{1});
            set(gcf, 'UserData', g);
            eegplot('drawb');
            return;
            
        case 'loadelect' % load channels
            [inputname,inputpath] = uigetfile('*','Channel locations file');
            if inputname == 0 return; end;
            if ~exist([ inputpath inputname ])
                error('no such file');
            end;
            
            AXH0 = findobj('tag','eegaxis','parent',gcf);
            eegplot('setelect',[ inputpath inputname ],AXH0);
            return;
            
        case 'setelect'
            % Set channels
            eloc_file = p1;
            axeshand = p2;
            outvar1 = 1;
            if isempty(eloc_file)
                outvar1 = 0;
                return
            end
            
            tmplocs = readlocs(eloc_file);
            YLabels = { tmplocs.labels };
            YLabels = strvcat(YLabels);
            
            YLabels = flipud(str2mat(YLabels,' '));
            set(axeshand,'YTickLabel',YLabels)
            
        case 'title'
            % Get new title
            h = findobj('tag', 'eegplottitle');
            
            if ~isempty(h)
                result       = inputdlg2( { 'New title:' }, 'Change title', 1,  { get(h(1), 'string') });
                if ~isempty(result), set(h, 'string', result{1}); end;
            else
                result       = inputdlg2( { 'New title:' }, 'Change title', 1,  { '' });
                if ~isempty(result), h = textsc(result{1}, 'title'); set(h, 'tag', 'eegplottitle');end;
            end;
            
            return;
            
        case 'scaleeye'
            % Turn scale I on/off
            obj = p1;
            figh = p2;
            g = get(figh,'UserData');
            % figh = get(obj,'Parent');
            
            if ~isempty(obj)
                eyeaxes = findobj('tag','eyeaxes','parent',figh);
                children = get(eyeaxes,'children');
                if isstr(obj)
                    if strcmp(obj, 'off')
                        set(children, 'visible', 'off');
                        set(eyeaxes, 'visible', 'off');
                        return;
                    else
                        set(children, 'visible', 'on');
                        set(eyeaxes, 'visible', 'on');
                    end;
                else
                    toggle = get(obj,'checked');
                    if strcmp(toggle,'on')
                        set(children, 'visible', 'off');
                        set(eyeaxes, 'visible', 'off');
                        set(obj,'checked','off');
                        return;
                    else
                        set(children, 'visible', 'on');
                        set(eyeaxes, 'visible', 'on');
                        set(obj,'checked','on');
                    end;
                end;
            end;
            
            eyeaxes = findobj('tag','eyeaxes','parent',figh);
            ax1 = findobj('tag','eegaxis','parent',gcf); % axes handle
            YLim = double(get(ax1, 'ylim'));
            
            ESpacing = findobj('tag','ESpacing','parent',figh);
            g.spacing= str2num(get(ESpacing,'string'));
            
            axes(eyeaxes); cla; axis off;
            set(eyeaxes, 'ylim', YLim);
            
            Xl = double([.35 .65; .5 .5; .35 .65]);
            Yl = double([ g.spacing g.spacing; g.spacing 0; 0 0] + YLim(1));
            plot(Xl(1,:),Yl(1,:),'color',DEFAULT_AXIS_COLOR,'clipping','off', 'tag','eyeline'); hold on;
            plot(Xl(2,:),Yl(2,:),'color',DEFAULT_AXIS_COLOR,'clipping','off', 'tag','eyeline');
            plot(Xl(3,:),Yl(3,:),'color',DEFAULT_AXIS_COLOR,'clipping','off', 'tag','eyeline');
            text(.5,(YLim(2)-YLim(1))/23+Yl(1),num2str(g.spacing,4),...
                'HorizontalAlignment','center','FontSize',10,...
                'tag','thescalenum')
            text(Xl(2)+.1,Yl(1),'+','HorizontalAlignment','left',...
                'verticalalignment','middle', 'tag', 'thescale')
            text(Xl(2)+.1,Yl(4),'-','HorizontalAlignment','left',...
                'verticalalignment','middle', 'tag', 'thescale')
            if ~isempty(SPACING_UNITS_STRING)
                text(.5,-YLim(2)/23+Yl(4),SPACING_UNITS_STRING,...
                    'HorizontalAlignment','center','FontSize',10, 'tag', 'thescale')
            end
            text(.5,(YLim(2)-YLim(1))/10+Yl(1),'Scale',...
                'HorizontalAlignment','center','FontSize',10, 'tag', 'thescale')
            set(eyeaxes, 'tag', 'eyeaxes');
            
        case 'noui'
            if ~isempty(varargin)
                eegplot( varargin{:} ); fig = gcf;
            else
                fig = findobj('tag', 'EEGPLOT');
            end;
            set(fig, 'menubar', 'figure');
            
            % find button and text
            obj = findobj(fig, 'style', 'pushbutton'); delete(obj);
            obj = findobj(fig, 'style', 'edit'); delete(obj);
            obj = findobj(fig, 'style', 'text');
            %objscale = findobj(obj, 'tag', 'thescale');
            %delete(setdiff(obj, objscale));
            obj = findobj(fig, 'tag', 'Eelec');delete(obj);
            obj = findobj(fig, 'tag', 'Etime');delete(obj);
            obj = findobj(fig, 'tag', 'Evalue');delete(obj);
            obj = findobj(fig, 'tag', 'Eelecname');delete(obj);
            obj = findobj(fig, 'tag', 'Etimename');delete(obj);
            obj = findobj(fig, 'tag', 'Evaluename');delete(obj);
            obj = findobj(fig, 'type', 'uimenu');delete(obj);
            
        case 'zoom' % if zoom
            fig = varargin{1};
            ax1 = findobj('tag','eegaxis','parent',fig);
            ax2 = findobj('tag','backeeg','parent',fig);
            tmpxlim  = get(ax1, 'xlim');
            tmpylim  = get(ax1, 'ylim');
            tmpxlim2 = get(ax2, 'xlim');
            set(ax2, 'xlim', get(ax1, 'xlim'));
            g = get(fig,'UserData');
            
            % deal with abscissa
            % ------------------
            if g.trialstag ~= -1
                Eposition = str2num(get(findobj('tag','EPosition','parent',fig), 'string'));
                g.winlength = (tmpxlim(2) - tmpxlim(1))/g.trialstag;
                Eposition = Eposition + (tmpxlim(1) - tmpxlim2(1)-1)/g.trialstag;
                Eposition = round(Eposition*1000)/1000;
                set(findobj('tag','EPosition','parent',fig), 'string', num2str(Eposition));
            else
                Eposition = str2num(get(findobj('tag','EPosition','parent',fig), 'string'))-1;
                g.winlength = (tmpxlim(2) - tmpxlim(1))/g.srate;
                Eposition = Eposition + (tmpxlim(1) - tmpxlim2(1)-1)/g.srate;
                Eposition = round(Eposition*1000)/1000;
                set(findobj('tag','EPosition','parent',fig), 'string', num2str(Eposition+1));
            end;
            
            % deal with ordinate
            % ------------------
            g.elecoffset = tmpylim(1)/g.spacing;
            g.dispchans  = round(1000*(tmpylim(2)-tmpylim(1))/g.spacing)/1000;
            
            set(fig,'UserData', g);
            eegplot('updateslider', fig);
            eegplot('drawp', 0);
            eegplot('scaleeye', [], fig);
            
            % reactivate zoom if 3 arguments
            % ------------------------------
            if exist('p2', 'var') == 1
                if verLessThan('matlab','8.4.0')
                    set(gcbf, 'windowbuttondownfcn', [ 'zoom(gcbf,''down''); eegplot(''zoom'', gcbf, 1);' ]);
                else
                    % This is failing for us: http://undocumentedmatlab.com/blog/enabling-user-callbacks-during-zoom-pan
                    %               hManager = uigetmodemanager(gcbf);
                    %               [hManager.WindowListenerHandles.Enabled] = deal(false);
                    
                    % Temporary fix
                    wtemp = warning; warning off;
                    set(gcbf, 'WindowButtonDownFcn', [ 'zoom(gcbf); eegplot(''zoom'', gcbf, 1);' ]);
                    warning(wtemp);
                end
            end;
            
        case 'updateslider' % if zoom
            fig = varargin{1};
            g = get(fig,'UserData');
            sliider = findobj('tag','eegslider','parent',fig);
            if g.elecoffset < 0
                g.elecoffset = 0;
            end;
            if g.dispchans >= g.chans
                g.dispchans = g.chans;
                g.elecoffset = 0;
                set(sliider, 'visible', 'off');
            else
                set(sliider, 'visible', 'on');
                set(sliider, 'value', g.elecoffset/g.chans, ...
                    'sliderstep', [1/(g.chans-g.dispchans) g.dispchans/(g.chans-g.dispchans)]);
                %'sliderstep', [1/(g.chans-1) g.dispchans/(g.chans-1)]);
            end;
            if g.elecoffset < 0
                g.elecoffset = 0;
            end;
            if g.elecoffset > g.chans-g.dispchans
                g.elecoffset = g.chans-g.dispchans;
            end;
            set(fig,'UserData', g);
            eegplot('scaleeye', [], fig);
            
        case 'drawlegend'
            fig = varargin{1};
            g = get(fig,'UserData');
            
            if ~isempty(g.events) % draw vertical colored lines for events, add event name text above
                nleg = length(g.eventtypes);
                fig2 = figure('numbertitle', 'off', 'name', '', 'visible', 'off', 'menubar', 'none', 'color', DEFAULT_FIG_COLOR);
                pos = get(fig2, 'position');
                set(fig2, 'position', [ pos(1) pos(2) 130 14*nleg+20]);
                
                for index = 1:nleg
                    plot([10 30], [(index-0.5) * 10 (index-0.5) * 10], 'color', g.eventtypecolors{index}, 'linestyle', ...
                        g.eventtypestyle{ index }, 'linewidth', g.eventtypewidths( index )); hold on;
                    if iscell(g.eventtypes)
                        th=text(35, (index-0.5)*10, g.eventtypes{index}, ...
                            'color', g.eventtypecolors{index});
                    else
                        th=text(35, (index-0.5)*10, num2str(g.eventtypes(index)), ...
                            'color', g.eventtypecolors{index});
                    end;
                end;
                xlim([0 130]);
                ylim([0 nleg*10]);
                axis off;
                set(fig2, 'visible', 'on');
            end;
            
            
            % motion button: move windows or display current position (channel, g.time and activation)
            % ----------------------------------------------------------------------------------------
            % case moved as subfunction
            % add topoplot
            % ------------
        case 'topoplot'
            fig = varargin{1};
            g = get(fig,'UserData');
            if ~isstruct(g.eloc_file) || ~isfield(g.eloc_file, 'theta') || isempty( [ g.eloc_file.theta ])
                return;
            end;
            ax1 = findobj('tag','backeeg','parent',fig);
            tmppos = get(ax1, 'currentpoint');
            ax1 = findobj('tag','eegaxis','parent',fig); % axes handle
            % plot vertical line
            yl = ylim;
            plot([ tmppos tmppos ], yl, 'color', [0.8 0.8 0.8]);
            
            if g.trialstag ~= -1,
                lowlim = round(g.time*g.trialstag+1);
            else, lowlim = round(g.time*g.srate+1);
            end;
            data = get(ax1,'UserData');
            datapos = max(1, round(tmppos(1)+lowlim));
            datapos = min(datapos, g.frames);
            
            figure; topoplot(data(:,datapos), g.eloc_file);
            if g.trialstag == -1,
                latsec = (datapos-1)/g.srate;
                title(sprintf('Latency of %d seconds and %d milliseconds', floor(latsec), round(1000*(latsec-floor(latsec)))));
            else
                trial = ceil((datapos-1)/g.trialstag);
                
                latintrial = eeg_point2lat(datapos, trial, g.srate, g.limits, 0.001);
                title(sprintf('Latency of %d ms in trial %d', round(latintrial), trial));
            end;
            return;
            
            % release button: check window consistency, add to trial boundaries
            % -------------------------------------------------------------------
        case 'defupcom'
            fig = varargin{1};
            g = get(fig,'UserData');
            ax1 = findobj('tag','backeeg','parent',fig);
            g.incallback = 0;
            set(fig,'UserData', g);  % early save in case of bug in the following
            if strcmp(g.mocap,'on'), g.winrej = g.winrej(end,:);end; % nima
            if ~isempty(g.winrej)', ...
                    if g.winrej(end,1) == g.winrej(end,2) % remove unitary windows
                    g.winrej = g.winrej(1:end-1,:);
                    else
                        if g.winrej(end,1) > g.winrej(end,2) % reverse values if necessary
                            g.winrej(end, 1:2) = [g.winrej(end,2) g.winrej(end,1)];
                        end;
                        g.winrej(end,1) = max(1, g.winrej(end,1));
                        g.winrej(end,2) = min(g.frames, g.winrej(end,2));
                        if g.trialstag == -1 % find nearest trials boundaries if necessary
                            I1 = find((g.winrej(end,1) >= g.winrej(1:end-1,1)) & (g.winrej(end,1) <= g.winrej(1:end-1,2)) );
                            if ~isempty(I1)
                                g.winrej(I1,2) = max(g.winrej(I1,2), g.winrej(end,2)); % extend epoch
                                g.winrej = g.winrej(1:end-1,:); % remove if empty match
                            else,
                                I2 = find((g.winrej(end,2) >= g.winrej(1:end-1,1)) & (g.winrej(end,2) <= g.winrej(1:end-1,2)) );
                                if ~isempty(I2)
                                    g.winrej(I2,1) = min(g.winrej(I2,1), g.winrej(end,1)); % extend epoch
                                    g.winrej = g.winrej(1:end-1,:); % remove if empty match
                                else,
                                    I2 = find((g.winrej(end,1) <= g.winrej(1:end-1,1)) & (g.winrej(end,2) >= g.winrej(1:end-1,1)) );
                                    if ~isempty(I2)
                                        g.winrej(I2,:) = []; % remove if empty match
                                    end;
                                end;
                            end;
                        end;
                    end;
            end;
            set(fig,'UserData', g);
            eegplot('drawp', 0);
            if strcmp(g.mocap,'on'), show_mocap_for_eegplot(g.winrej); g.winrej = g.winrej(end,:); end; % nima
            
            % push button: create/remove window
            % ---------------------------------
        case 'defdowncom'
            show_mocap_timer = timerfind('tag','mocapDisplayTimer'); if ~isempty(show_mocap_timer),  end; % nima
            fig = varargin{1};
            g = get(fig,'UserData');
            
            ax1 = findobj('tag','backeeg','parent',fig);
            tmppos = get(ax1, 'currentpoint');
            if strcmp(get(fig, 'SelectionType'),'normal');
                
                fig = varargin{1};
                g = get(fig,'UserData');
                ax1 = findobj('tag','backeeg','parent',fig);
                tmppos = get(ax1, 'currentpoint');
                g = get(fig,'UserData'); % get data of backgroung image {g.trialstag g.winrej incallback}
                if g.incallback ~= 1 % interception of nestest calls
                    if g.trialstag ~= -1,
                        lowlim = round(g.time*g.trialstag+1);
                        highlim = round(g.winlength*g.trialstag);
                    else,
                        lowlim  = round(g.time*g.srate+1);
                        highlim = round(g.winlength*g.srate);
                    end;
                    if (tmppos(1) >= 0) & (tmppos(1) <= highlim),
                        if isempty(g.winrej) Allwin=0;
                        else Allwin = (g.winrej(:,1) < lowlim+tmppos(1)) & (g.winrej(:,2) > lowlim+tmppos(1));
                        end;
                        if any(Allwin) % remove the mark or select electrode if necessary
                            lowlim = find(Allwin==1);
                            if g.setelectrode  % select electrode
                                ax2 = findobj('tag','eegaxis','parent',fig);
                                tmppos = get(ax2, 'currentpoint');
                                tmpelec = g.chans + 1 - round(tmppos(1,2) / g.spacing);
                                tmpelec = min(max(tmpelec, 1), g.chans);
                                g.winrej(lowlim,tmpelec+5) = ~g.winrej(lowlim,tmpelec+5); % set the electrode
                            else  % remove mark
                                g.winrej(lowlim,:) = [];
                            end;
                        else
                            if g.trialstag ~= -1 % find nearest trials boundaries if epoched data
                                alltrialtag = [0:g.trialstag:g.frames];
                                I1 = find(alltrialtag < (tmppos(1)+lowlim) );
                                if ~isempty(I1) & I1(end) ~= length(alltrialtag),
                                    g.winrej = [g.winrej' [alltrialtag(I1(end)) alltrialtag(I1(end)+1) g.wincolor zeros(1,g.chans)]']';
                                end;
                            else,
                                g.incallback = 1;  % set this variable for callback for continuous data
                                if size(g.winrej,2) < 5
                                    g.winrej(:,3:5) = repmat(g.wincolor, [size(g.winrej,1) 1]);
                                end;
                                if size(g.winrej,2) < 5+g.chans
                                    g.winrej(:,6:(5+g.chans)) = zeros(size(g.winrej,1),g.chans);
                                end;
                                g.winrej = [g.winrej' [tmppos(1)+lowlim tmppos(1)+lowlim g.wincolor zeros(1,g.chans)]']';
                            end;
                        end;
                        set(fig,'UserData', g);
                        eegplot('drawp', 0);  % redraw background
                    end;
                end;
            elseif strcmp(get(fig, 'SelectionType'),'normal');
                
                
            end;
        otherwise
            error(['Error - invalid eegplot() parameter: ',data])
    end
end

% Function to show the value and electrode at mouse position
    function defmotion(varargin)
        fig = varargin{3};
        ax1 = varargin{4};
        tmppos = get(ax1, 'currentpoint');
        
        if  all([tmppos(1,1) >= 0,tmppos(1,2)>= 0])
            g = get(fig,'UserData');
            if g.trialstag ~= -1,
                lowlim = round(g.time*g.trialstag+1);
            else, lowlim = round(g.time*g.srate+1);
            end;
            if g.incallback
                g.winrej = [g.winrej(1:end-1,:)' [g.winrej(end,1) tmppos(1)+lowlim g.winrej(end,3:end)]']';
                set(fig,'UserData', g);
                eegplot('drawb');
            else
                hh = varargin{6}; % h = findobj('tag','Etime','parent',fig);
                if g.trialstag ~= -1,
                    tmpval = mod(tmppos(1)+lowlim-1,g.trialstag)/g.trialstag*(g.limits(2)-g.limits(1)) + g.limits(1);
                    if g.isfreq, tmpval = tmpval/1000 + g.freqs(1); end
                    set(hh, 'string', num2str(tmpval));
                else
                    tmpval = (tmppos(1)+lowlim-1)/g.srate;
                    if g.isfreq, tmpval = tmpval+g.freqs(1); end
                    set(hh, 'string', num2str(tmpval)); % put g.time in the box
                end;
                ax1 = varargin{5};% ax1 = findobj('tag','eegaxis','parent',fig);
                tmppos = get(ax1, 'currentpoint');
                tmpelec = round(tmppos(1,2) / g.spacing);
                tmpelec = min(max(double(tmpelec), 1),g.chans);
                labls = get(ax1, 'YtickLabel');
                hh = varargin{8}; % hh = findobj('tag','Eelec','parent',fig);  % put electrode in the box
                if ~g.envelope
                    set(hh, 'string', labls(tmpelec+1,:));
                else
                    set(hh, 'string', ' ');
                end
                hh = varargin{7}; % hh = findobj('tag','Evalue','parent',fig);
                if ~g.envelope
                    eegplotdata = get(ax1, 'userdata');
                    set(hh, 'string', num2str(eegplotdata(g.chans+1-tmpelec, min(g.frames,max(1,double(round(tmppos(1)+lowlim)))))));  % put value in the box
                else
                    set(hh,'string',' ');
                end
            end;
        end
        % function not supported under Mac
        function [reshist, allbin] = myhistc(vals, intervals);
            
            reshist = zeros(1, length(intervals));
            allbin = zeros(1, length(vals));
            
            for index=1:length(vals)
                minvals = vals(index)-intervals;
                bintmp  = find(minvals >= 0);
                [mintmp indextmp] = min(minvals(bintmp));
                bintmp = bintmp(indextmp);
                
                allbin(index) = bintmp;
                reshist(bintmp) = reshist(bintmp)+1;
            end;
            
        end
    end
end

%%   =====================modified_listdlg2===================================
% modified_listdlg2
% modified_listdlg2 add a button to show selected channel properties.
% original function listdlg2
function [vals, okornot, strval] = modified_listdlg2(EEG,varargin);

if nargin < 2
    help listdlg2;
    return;
end;
for index = 1:length(varargin)
    if iscell(varargin{index}), varargin{index} = { varargin{index} }; end;
    if isstr(varargin{index}), varargin{index} = lower(varargin{index}); end;
end;
g = struct(varargin{:});

try,  g.promptstring;  catch, g.promptstring = ''; end;
try,  g.liststring;    catch, error('''liststring'' must be defined'); end;
try,  g.selectionmode; catch, g.selectionmode = 'multiple'; end;
try,  g.listsize;      catch, g.listsize = []; end;
try,  g.initialvalue;  catch, g.initialvalue = []; end;
try,  g.name;          catch, g.name = ''; end;

fig = figure('visible', 'off');
set(gcf, 'name', g.name);
if isstr(g.liststring)
    allstr =  g.liststring;
else
    allstr = '';
    for index = 1:length(g.liststring)
        allstr = [ allstr '|' g.liststring{index} ];
    end;
    allstr = allstr(2:end);
end;

geometry = {[1] [1 1 1]};
geomvert = [min(length(g.liststring), 10) 1];
if ~strcmpi(g.selectionmode, 'multiple') | ...
        (iscell(g.liststring) & length(g.liststring) == 1) | ...
        (isstr (g.liststring) & size  (g.liststring,1) == 1 & isempty(find(g.liststring == '|')))
    if isempty(g.initialvalue), g.initialvalue = 1; end;
    minval = 1;
    maxval = 1;
else
    minval = 0;
    maxval = 2;
end;
listui = {{ 'Style', 'listbox', 'tag', 'listboxvals', 'string', allstr, 'max', maxval, 'min', minval } ...
    { 'Style', 'pushbutton', 'string', 'Clear', 'callback', ['set(gcbf, ''userdata'', ''clear'');'] }  ...
    { 'Style', 'pushbutton', 'string', 'Mark'    , 'callback', ['set(gcbf, ''userdata'', ''ok'');'] } ...
    { 'Style', 'pushbutton', 'string', 'Property'    , 'callback', ['drawnow;set(gcbf, ''userdata'', ''property'');'] }};

if ~isempty(g.promptstring)
    geometry = {[1] geometry{:}};
    geomvert = [1 geomvert];
    listui = { { 'Style', 'text', 'string', g.promptstring } listui{:}};
end;
[tmp tmp2 allobj] = supergui( fig, geometry, geomvert, listui{:} );

% assign value to listbox
% must be done after creating it
% ------------------------------
lstbox = findobj(fig, 'tag', 'listboxvals');
set(lstbox, 'value', g.initialvalue);

if ~isempty(g.listsize)
    pos = get(gcf, 'position');
    set(gcf, 'position', [ pos(1:2) g.listsize]);
end;
h = findobj( 'parent', fig, 'tag', 'listboxvals');

okornot = 0;
strval = '';
vals = [];
figure(fig);
drawnow;

% run the following code until fig get the 'userdata' --zhipeng notes
waitfor( fig, 'userdata');
if strcmp(get(fig, 'userdata'), 'clear') | strcmp(get(fig, 'userdata'), 'ok')
    try,
        vals = get(h, 'value');
        strval = '';
        if iscell(g.liststring)
            for index = vals
                strval = [ strval ' ' g.liststring{index} ];
            end;
        else
            for index = vals
                strval = [ strval ' ' g.liststring(index,:) ];
            end;
        end;
        strval = strval(2:end);
        if strcmp(get(fig, 'userdata'), 'clear')
            okornot = 0;
        else
            okornot = 1;
        end;
        close(fig);
        drawnow;
    end;
else
    
    refresh(fig)
    h = findobj( 'parent', fig, 'tag', 'listboxvals');
    try,
        vals = get(h, 'value');
        for idx=1:length(vals)
            pop_prop(EEG,1,vals(idx),NaN,{})
        end
        close(fig); %No idea how to allow it to click pushbutton multiple times.
        drawnow;
        
    end;
end
end

%% =====================modified_pop_chansel===============================
%This is a modified pop_chansel function to select bad channel that need to
%be interpolated.
%Add plot chanel property button to plot selected channel property, which
%is helpful when you select bad channel.
%similiar usage as pop_chansel. see pop_chansel
function [chanlist,chanliststr, allchanstr] = modified_pop_chansel(EEG,chans, varargin);

if nargin < 1
    help pop_chansel;
    return;
end;
if isempty(chans), disp('Empty input'); return; end;
if isnumeric(chans),
    for c = 1:length(chans)
        newchans{c} = num2str(chans(c));
    end;
    chans = newchans;
end;
chanlist    = [];
chanliststr = {};
allchanstr  = '';

g = finputcheck(varargin, { 'withindex'     {  'integer';'string' } { [] {'on' 'off'} }   'off';
    'select'        { 'cell';'string';'integer' } [] [];
    'selectionmode' 'string' { 'single';'multiple' } 'multiple'});
if isstr(g), error(g); end;
if ~isstr(g.withindex), chan_indices = g.withindex; g.withindex = 'on';
else                    chan_indices = 1:length(chans);
end;

% convert selection to integer
% ----------------------------
if isstr(g.select) & ~isempty(g.select)
    g.select = parsetxt(g.select);
end;
if iscell(g.select) & ~isempty(g.select)
    if isstr(g.select{1})
        tmplower = lower( chans );
        for index = 1:length(g.select)
            matchind = strmatch(lower(g.select{index}), tmplower, 'exact');
            if ~isempty(matchind), g.select{index} = matchind;
            else error( [ 'Cannot find ''' g.select{index} '''' ] );
            end;
        end;
    end;
    g.select = [ g.select{:} ];
end;
if ~isnumeric( g.select ), g.select = []; end;

% add index to channel name
% -------------------------
tmpstr = {chans};
if isnumeric(chans{1})
    tmpstr = [ chans{:} ];
    tmpfieldnames = cell(1, length(tmpstr));
    for index=1:length(tmpstr),
        if strcmpi(g.withindex, 'on')
            tmpfieldnames{index} = [ num2str(chan_indices(index)) '  -  ' num2str(tmpstr(index)) ];
        else
            tmpfieldnames{index} = num2str(tmpstr(index));
        end;
    end;
else
    tmpfieldnames = chans;
    if strcmpi(g.withindex, 'on')
        for index=1:length(tmpfieldnames),
            tmpfieldnames{index} = [ num2str(chan_indices(index)) '  -  ' tmpfieldnames{index} ];
        end;
    end;
end;
[chanlist,tmp,chanliststr] = modified_listdlg2(EEG, 'PromptString',strvcat('Select channel(s)', '(ctrl/shift for mul)'), ...
    'ListString', tmpfieldnames, 'initialvalue', g.select, 'selectionmode', g.selectionmode,'Name','Channel Selection');
if tmp == 0
    chanlist = [];
    chanliststr = '';
    return;
else
    allchanstr = chans(chanlist);
end;

% test for spaces
% ---------------
spacepresent = 0;
if ~isnumeric(chans{1})
    tmpstrs = [ allchanstr{:} ];
    if ~isempty( find(tmpstrs == ' ')) | ~isempty( find(tmpstrs == 9))
        spacepresent = 1;
    end;
end;

% get concatenated string (if index)
% -----------------------
if strcmpi(g.withindex, 'on') | spacepresent
    if isnumeric(chans{1})
        chanliststr = num2str(celltomat(allchanstr));
    else
        chanliststr = '';
        for index = 1:length(allchanstr)
            if spacepresent
                chanliststr = [ chanliststr '''' allchanstr{index} ''' ' ];
            else
                chanliststr = [ chanliststr allchanstr{index} ' ' ];
            end;
        end;
        chanliststr = chanliststr(1:end-1);
    end;
end;

return;
end

%%  ======================modified_pop_selectcomps===============================
%This is a modified pop_selectcomps function
% Add buttons comparing single trials as well as ERPs after and before
% rejecting the selected ICs
function [EEG] = modified_pop_selectcomps( EEG, compnum, fig );
COLREJ = '[1 0.6 0.6]';
COLACC = '[0.75 1 0.75]';
PLOTPERFIG = 35;

if nargin < 1
    help pop_selectcomps;
    return;
end;

if nargin < 2
    promptstr = { 'Components to plot:' };
    initstr   = { [ '1:' int2str(size(EEG.icaweights,1)) ] };
    
    result = inputdlg2(promptstr, 'Reject comp. by map -- pop_selectcomps',1, initstr);
    if isempty(result), return; end;
    compnum = eval( [ '[' result{1} ']' ]);
    
    if length(compnum) > PLOTPERFIG
        ButtonName=questdlg2(strvcat(['More than ' int2str(PLOTPERFIG) ' components so'],'this function will pop-up several windows'), ...
            'Confirmation', 'Cancel', 'OK','OK');
        if ~isempty( strmatch(lower(ButtonName), 'cancel')), return; end;
    end;
    
end;
fprintf('Drawing figure...\n');
currentfigtag = ['selcomp' num2str(rand)]; % generate a random figure tag

if length(compnum) > PLOTPERFIG
    for index = 1:PLOTPERFIG:length(compnum)
        modified_pop_selectcomps(EEG, compnum([index:min(length(compnum),index+PLOTPERFIG-1)]));
    end;
    
    com = [ 'pop_selectcomps(' inputname(1) ', ' vararg2str(compnum) ');' ];
    return;
end;

if isempty(EEG.reject.gcompreject)
    EEG.reject.gcompreject = zeros( size(EEG.icawinv,2));
end;
try, icadefs;
catch,
    BACKCOLOR = [0.8 0.8 0.8];
    GUIBUTTONCOLOR   = [0.8 0.8 0.8];
end;

% set up the figure
% -----------------
column =ceil(sqrt( length(compnum) ))+1;
rows = ceil(length(compnum)/column);
if ~exist('fig','var')
    figure('name', [ 'Reject components by map - pop_selectcomps() (dataset: ' EEG.setname ')'], 'tag', currentfigtag, ...
        'numbertitle', 'off', 'color', BACKCOLOR);
    set(gcf,'MenuBar', 'none');
    pos = get(gcf,'Position');
    set(gcf,'Position', [pos(1) 20 800/7*column 600/5*rows]);
    incx = 120;
    incy = 110;
    sizewx = 100/column;
    if rows > 2
        sizewy = 90/rows;
    else
        sizewy = 80/rows;
    end;
    pos = get(gca,'position'); % plot relative to current axes
    hh = gca;
    q = [pos(1) pos(2) 0 0];
    s = [pos(3) pos(4) pos(3) pos(4)]./100;
    axis off;
end;

% figure rows and columns
% -----------------------
if EEG.nbchan > 64
    disp('More than 64 electrodes: electrode locations not shown');
    plotelec = 0;
else
    plotelec = 1;
end;
count = 1;
for ri = compnum
    if exist('fig','var')
        button = findobj('parent', fig, 'tag', ['comp' num2str(ri)]);
        if isempty(button)
            error( 'pop_selectcomps(): figure does not contain the component button');
        end;
    else
        button = [];
    end;
    
    if isempty( button )
        % compute coordinates
        % -------------------
        X = mod(count-1, column)/column * incx-10;
        Y = (rows-floor((count-1)/column))/rows * incy - sizewy*1.3;
        
        % plot the head
        % -------------
        if ~strcmp(get(gcf, 'tag'), currentfigtag);
            figure(findobj('tag', currentfigtag));
        end;
        ha = axes('Units','Normalized', 'Position',[X Y sizewx sizewy].*s+q);
        if plotelec
            topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                'off', 'style' , 'fill', 'chaninfo', EEG.chaninfo, 'numcontour', 8);
        else
            topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                'off', 'style' , 'fill','electrodes','off', 'chaninfo', EEG.chaninfo, 'numcontour', 8);
        end;
        axis square;
        
        % plot the button
        % ---------------
        if ~strcmp(get(gcf, 'tag'), currentfigtag);
            figure(findobj('tag', currentfigtag));
        end
        button = uicontrol(gcf, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
            [X Y+sizewy sizewx sizewy*0.25].*s+q, 'tag', ['comp' num2str(ri)]);
        command = sprintf('global EEG; pop_prop( %s, 0, %d, gcbo, { ''freqrange'', [1 50] });', inputname(1), ri); %RMC command = sprintf('pop_prop( %s, 0, %d, %3.15f, { ''freqrange'', [1 50] });', inputname(1), ri, button);
        set( button, 'callback', command );
    end;
    %tmp info is stored in EEG.reject.gcompreject
    set( button, 'backgroundcolor', eval(fastif(EEG.reject.gcompreject(ri), COLREJ,COLACC)), 'string', int2str(ri));
    drawnow;
    count = count +1;
end;

% draw the bottom button
% ----------------------
if ~exist('fig','var')
    if ~strcmp(get(gcf, 'tag'), currentfigtag);
        figure(findobj('tag', currentfigtag));
    end
    select_cmd1= 'global EEG; h_tmp1=findobj(gcf,''tag'',''ics'');set(h_tmp1,''string'',num2str(find(EEG.reject.gcompreject==1))); ';
    select_cmd2='h_tmp2=findobj(gcf,''tag'',''test_btn1'');set(h_tmp2,''enable'',''on''); ';
    select_cmd3='h_tmp3=findobj(gcf,''tag'',''test_btn2'');set(h_tmp3,''enable'',''on''); ';
    select_cmd4='clear h_tmp3 h_tmp2 h_tmp1';
    select_cmd=[select_cmd1,select_cmd2,select_cmd3,select_cmd4];
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'Selected ICs:', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[-10 -10 15 sizewy*0.25].*s+q,'Fontsize',14,'HorizontalAlignment','left','callback',select_cmd);
    h_ics = uicontrol(gcf, 'Style', 'text', 'string', '<---click to update', 'Units','Normalized', 'backgroundcolor', BACKCOLOR, ...
        'Position',[5 -10  20 sizewy*0.25].*s+q, 'Fontsize',16,'tag','ics' );
    %Test btns
    cmd1='h_ics=findobj(gcf,''tag'',''ics'');components=get(h_ics,''string'');';
    cmd2='component_keep = setdiff_bc(1:size(EEG.icaweights,1), components);';
    cmd3='compproj = EEG.icawinv(:, component_keep)*eeg_getdatact(EEG, ''component'', component_keep, ''reshape'', ''2d'');';
    cmd4='compproj = reshape(compproj, size(compproj,1), EEG.pnts, EEG.trials);';
    cmd5='eegplot( EEG.data(EEG.icachansind,:,:), ''srate'', EEG.srate, ''title'', ''Black = channel before rejection; red = after rejection -- eegplot()'',''limits'', [EEG.xmin EEG.xmax]*1000, ''data2'', compproj);';
    cmd_off1='h_tmp2=findobj(gcf,''tag'',''test_btn1'');set(h_tmp2,''enable'',''off'');';
    cmd5_1='clear component_keep compproj h_tmp2 components h_ics';
    cmp_single_cmd=[cmd_off1,cmd1,cmd2,cmd3,cmd4,cmd5,cmd5_1];
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'Test removal', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[30 -10  15 sizewy*0.25].*s+q,'callback',cmp_single_cmd,'tag','test_btn1','enable','off');
    
    cmd6=' tracing  = [ squeeze(mean(EEG.data(EEG.icachansind,:,:),3)) squeeze(mean(compproj,3))];';
    cmd7='figure;plotdata(tracing, EEG.pnts, [EEG.xmin*1000 EEG.xmax*1000 0 0],''Trial ERPs (red) with and (blue) without these components'');';
    cmd_off2='h_tmp3=findobj(gcf,''tag'',''test_btn2'');set(h_tmp3,''enable'',''off''); clear h_tmp3;';
    cmd8='clear component_keep compproj h_tmp3 tracing components h_ics';
    cmp_average_cmd=[cmd_off2, cmd1,cmd2,cmd3,cmd4,cmd6,cmd7,cmd8];
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'Test removal (averaged ERPs)', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[50 -10  15 sizewy*0.25].*s+q, 'callback', cmp_average_cmd,'tag','test_btn2','enable','off');
    
    clear_cmd1=' global EEG ui; ic2remove=find(EEG.reject.gcompreject==1);EEG.reject.gcompreject(ic2remove)=0;set(ui.info5,''String'',''ICs to remove : all selected ICs were cleared.'');close(gcf);';
    clear_cmd2='cb = get(ui.ica, ''callback'');cb(ui.ica,[])';
    clear_cmd=[clear_cmd1,clear_cmd2];
    
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'Clear all selections', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[70 -10  15 sizewy*0.25].*s+q, 'callback',clear_cmd);
    
    
    ok_cmd = 'global EEG ui ic2remove;ic2remove=find(EEG.reject.gcompreject==1); set(ui.info5,''String'',[''ICs to remove : '', num2str(find(EEG.reject.gcompreject==1))]);close(gcf);';
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'OK', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[90 -10  15 sizewy*0.25].*s+q, 'callback',  ok_cmd);
    % sprintf(['eeg_global; if %d pop_rejepoch(%d, %d, find(EEG.reject.sigreject > 0), EEG.reject.elecreject, 0, 1);' ...
    %		' end; pop_compproj(%d,%d,1); close(gcf); eeg_retrieve(%d); eeg_updatemenu; '], rejtrials, set_in, set_out, fastif(rejtrials, set_out, set_in), set_out, set_in));

end;
end

%% ==========================search using regexp======================================
function [paths, names] = filesearch_regexp(startDir,expression,norecurse)
    if (~exist('norecurse','var') || isempty(norecurse))
        norecurse=0;
    end
    [paths names] = dir_search(startDir,expression,norecurse);
    
    function [paths names] = dir_search(currDir,expression,norecurse)
        if nargin < 2
            fprintf('Usage: [paths names] = dirsearch(currDir, searchstring)\n');
            paths = '';
            names = '';
            return;
        elseif (exist('norecurse','var')~=1)
            norecurse=0;
        end
        paths = {};
        names = {};
        list_currDir = dir(currDir);

        for u = 1:length(list_currDir)
            if (list_currDir(u).isdir==1 && strcmp(list_currDir(u).name,'.')~=1 && strcmp(list_currDir(u).name,'..')~=1 && norecurse==0)
                [temppaths tempnames] = dir_search(sprintf('%s%s%s',currDir,filesep,list_currDir(u).name),expression);
                paths = {paths{:} temppaths{:}};
                names = {names{:} tempnames{:}};
            elseif (length(list_currDir(u).name) > 4)
                    if isempty(regexpi(list_currDir(u).name, expression))==0
                        paths = {paths{:} currDir};
                        names = {names{:} list_currDir(u).name};
                    end
            end
        end

	end
end