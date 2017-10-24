function eegplugin_manualqc( fig, try_strings, catch_strings)
vers='manualqc1.1';
toolsmenu = findobj(fig, 'tag', 'tools');
uimenu( toolsmenu, 'label', 'ManualQC ', 'callback', 'manualqc;');
