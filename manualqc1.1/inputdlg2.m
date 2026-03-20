function varargout = inputdlg2(varargin)
%INPUTDLG2 Compatibility wrapper for environments without EEGLAB's inputdlg2.

[varargout{1:nargout}] = inputdlg(varargin{:});
end
