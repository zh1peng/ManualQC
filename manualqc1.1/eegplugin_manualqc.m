function eegplugin_manualqc( fig, try_strings, catch_strings)
toolsmenu = findobj(fig, 'tag', 'tools');
uimenu( toolsmenu, 'label', 'ManualQC ', 'callback', 'manualqc;');
