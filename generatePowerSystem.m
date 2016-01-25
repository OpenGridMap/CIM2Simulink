
% This script handles the automatic generation of large power systems ins
% Simulink.
%
% Author: First Name: Bernhard
%         Last Name:  Krop
%         E-Mail:     b.krop@gmx.de
%
% Last time updated:  25. December 2015

% @param    path    The path of the input file. This is an optional
%                   argument. If it does not exist or is not a string,
%                   'Input.txt' will be set as standard path.
% @param    title   The title for the Simulink model. This is an optional
%                   argument. If it does not exist or is not a string,
%                   'untitled' will be set as standard title.
% @return   system  The Simulink model, created by this script.
function system = generatePowerSystem(path, title)

    % Use global variables.
    global g_dSystem;

    % Make variables global.
    global g_sFilePath g_sTitle;

    % The path for the input file.
    if(exist('path', 'var') && ischar(path))
        g_sFilePath = path;
    else
        g_sFilePath = 'Input.txt';
    end
    
    % The CIM objects, defined in the input file.
    if(~exist('parseCIM.m', 'file'))
        clearvars -global;
        error('Cannot find ''parseCIM.m''!');
    end
    
    parseCIM();
    
    % The title for the Simulink model.
    if(exist('title', 'var') && ischar(title))
        g_sTitle = title;
    else
        g_sTitle = 'untitled';
    end
    
    % The Simulink model.
    if(~exist('createSystem.m', 'file'))
        clearvars -global;
        error('Cannot find ''createSystem.m''!');
    end
    
    createSystem();

    % Open the created system.
    open_system(g_dSystem);

    % Clean up everything, that is not needed anymore.
    system = g_dSystem;
    clearvars -global -except system;

end % End of main function.

% End of script
