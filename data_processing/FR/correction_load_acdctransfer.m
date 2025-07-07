function [acdctransfer] = correction_load_acdctransfer(file)
% Loader of the acdctransfer correction file.
% It will always return all acdctransfer parameters even if they are not found.
% In that case it will load 'neutral' defaults (unity AC/DC transfer).
%
% Inputs:
%   file - absolute file path to the acdctransfer header INFO file.
%          Set '' or not assigned to load default 'blank' correction.
%
% Outputs:
%   acdctransfer.type - string defining acdctransfer type 'acdctransfer'
%   acdctransfer.name - string with acdctransfer's name
%   acdctransfer.sn - string with acdctransfer's serial
%   acdctransfer.acdc_diff - 2D table of AC/DC difference values

    % load default values only?
    is_default = ~exist('file','var') || isempty(file);

    if ~is_default
        % root folder of the correction
        root_fld = [fileparts(file) filesep()];
        % try to load the correction file
        inf = infoload(file);
        % parse info file (speedup):
        inf = infoparse(inf);
        % get correction type id
        t_type = infogettext(inf, 'type');
        % try to identify correction type
        id = find(strcmpi(t_type, 'acdctransfer'),1);
        if ~numel(id)
            error(sprintf('acdctransfer correction loader: Correction type ''%s'' not recognized!'), t_type);
        end
    else
        % defaults:
        warning('correction_load_acdctransfer: Loading correction for blank AC/DC transfer standard!');
        t_type = 'acdctransfer';
    end

    % store acdctransfer type
    acdctransfer.type = t_type;

    if ~is_default
        % acdctransfer correction name
        tran.name = infogettext(inf, 'name');
        % acdctransfer serial number
        acdctransfer.sn = infogettext(inf, 'serial number');
        % load AC/DC differences:
        fdep_file = fullfile(root_fld, correction_load_acdctransfer_get_file_key(inf, 'AC/DC difference path'));
    else
        % defaults:
        acdctransfer.name = 'blank AC/DC transfer standard';
        acdctransfer.sn = 'n/a';
        % default (gain, unc.)
        fdep_file = {[], [], 0.0, 0.01e-6};
    end

    acdctransfer.acdc_diff = correction_load_table(fdep_file, 'rms', {'f', 'acdc_diff', 'u_acdc_diff'});
    acdctransfer.acdc_diff.qwtb = qwtb_gen_naming('acdctransfer_acdc_diff', 'f', 'rms', {'acdc_diff'}, {'u_acdc_diff'}, {''});

    % this is a list of the correction that will be passed to the QWTB algorithm
    % note: any correction added to this list will be passed to the QWTB
    %       but it must contain the 'qwtb' record in the table (see eg. above)  
    acdctransfer.qwtb_list = {};
    % autobuild of the list of loaded correction:
    fnm = fieldnames(acdctransfer);
    for k = 1:numel(fnm)
        item = getfield(acdctransfer,fnm{k});
        if isfield(item, 'qwtb')
            acdctransfer.qwtb_list{end+1} = fnm{k};
        end
    end

end % function correction_load_acdctransfer

% get info text, if found and empty generate error
function [file_name] = correction_load_acdctransfer_get_file_key(inf,key)
    file_name = infogettext(inf,key);
    if isempty(file_name)
        error('File name empty!');
    end
    % convert filepaths for linux or for windows if needed. dos notation ('\') is kept because of
    % labview:
    file_name = path_dos2unix(file_name);
end % function correction_load_acdctransfer_get_file_key

 
function [qw] = qwtb_gen_naming(c_name,ax_prim,ax_sec,v_list,u_list,v_names)
% Correction table structure cannot be directly passed into the QWTB.
% So this will prepare names of the QWTB variables that will be used
% for passing the table to the QWTB algorithm.
%
% Parameters:
%   c_name  - core name of the correction data
%   ax_prim - name of the primary axis suffix (optional)
%   ax_sec  - name of the secondary axis suffix (optional)
%   v_list  - cell array of the table's quantities to store
%   u_list  - cell array of the table's uncertainties to store
%   v_names - names of the suffixes for each item in the 'v_list'
%
% Example 1:
%   qw = qwtb_gen_naming('adc_gain','f','a',{'gain'},{'u_gain'},{''}):
%   qw.c_name = 'adc_gain'
%   qw.v_names = 'adc_gain'
%   qw.ax_prim = 'adc_gain_f'
%   qw.ax_sec = 'adc_gain_a'
%   qw.v_list = {'gain'}
%   qw.u_list = {'u_gain'}
%   this will be passed to the QWTB list:
%     di.adc_gain.v - the table quantity 'gain' 
%     di.adc_gain.u - the table quantity 'u_gain' (uncertainty)
%     di.adc_gain_f.v - primary axis of the table
%     di.adc_gain_a.v - secondary axis of the table
%
% Example 2:
%   qw = qwtb_gen_naming('Yin','f','',{'Rp','Cp'},{'u_Rp','u_Cp'},{'rp','cp'}):
%   qw.c_name = 'Yin'
%   qw.v_names = {'Yin_Rp','Yin_Cp'}
%   qw.ax_prim = 'Yin_f'
%   qw.ax_sec = ''
%   qw.v_list = {'Rp','Cp'}
%   qw.u_list = {'u_Rp','u_Cp'}
%   this will be passed to the QWTB list:
%     di.Yin_rp.v - the table quantity 'Rp' 
%     di.Yin_rp.u - the table quantity 'u_Rp' (uncertainty)
%     di.Yin_cp.v - the table quantity 'Cp' 
%     di.Yin_cp.u - the table quantity 'u_Cp' (uncertainty)
%     di.adc_gain_f.v - primary axis of the table

    
    V = numel(v_names);
    if V > 1
        % create variable names: 'c_name'_'v_names{:}':
        qw.v_names = {};
        for k = 1:V
            qw.v_names{k} = [c_name '_' v_names{k}];
        end
    else
        % variable name: 'c_name':
        qw.v_names = {c_name}; 
    end
    
    if ~isempty(ax_prim)
        qw.ax_prim = [c_name '_' ax_prim];
    else
        qw.ax_prim = '';         
    end
    if ~isempty(ax_sec)
        qw.ax_sec = [c_name '_' ax_sec];
    else
        qw.ax_sec = '';
    end
    qw.c_name = c_name;
    qw.v_list = v_list;
    qw.u_list = u_list;
    
end % function qwtb_gen_naming
