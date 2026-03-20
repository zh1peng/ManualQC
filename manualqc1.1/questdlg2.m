function varargout = questdlg2(varargin)
%QUESTDLG2 Compatibility wrapper for environments without EEGLAB's questdlg2.

[varargout{1:nargout}] = questdlg(varargin{:});
end
