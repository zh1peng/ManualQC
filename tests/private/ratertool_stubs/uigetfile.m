function [files, folder] = uigetfile(varargin)
% Deterministic file selection for RaterTool UI regression tests only.
selection = getappdata(0, 'ratertool_test_selection');
files = selection.files;
folder = selection.folder;
end
