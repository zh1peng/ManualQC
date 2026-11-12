function h = warndlg2(varargin)
%WARNDLG2 Compatibility wrapper for environments without EEGLAB's warndlg2.

h = warndlg(varargin{:});
end
