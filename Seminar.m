
% This script handles the input for large Simulink models.
%
% Author: Bernhard Krop
%
% The input file should have the following syntax:
% 
% # Nodes:
% # Syntax of a node: [X-Position,Y-Position]
% # Nodes are separated by ; or a new line.
% 
% [19,6];[17,2];[13,5];[6,3]
% [10,7];[12,14];[16,9]
% 
% # Edges:
% # Edges are stored as adjacence matrix of the nodes.
% 
% {
% {0,1,0,0,0,0,1}
% {1,0,1,0,0,0,0}
% {0,1,0,0,1,1,0}
% {0,0,0,0,0,1,0}
% {0,0,1,0,0,0,1}
% {0,0,1,1,0,0,1}
% {1,0,0,0,1,1,0}
% }

% The path for the input file.
g_sInputPath = 'Input.txt';
% This contains the name of the Simulink model.
g_sTitle = 'untitled';
% This is the width of each block in Simulink.
g_iWidth = 30;
% This is the height of each block in Simulink.
g_iHeight = 50;
% This table holds all nodes and it's properties.
g_tNodes = table(cell(0), cell(0), 'VariableNames', {'X_Position' 'Y_Position'});
% This cell holds the adjacence matrix of the nodes.
g_cEdges = cell(0);
% This is used to count the actual line in the file.
g_iLine = 0;
% This holds the file ID.
g_iFileID = fopen(g_sInputPath, 'r');

% Check whether the input file is open.
if(g_iFileID < 0)
    % Could not open the input file. Clean up and throw an error.
    clear g_iLine g_iWidth g_iHeight g_iFileID g_sTitle g_cEdges g_tNodes;
    error('Error: Could not open file! (Path: %s)', g_sInputPath);
end

% Read the whole file to get the input.
while(feof(g_iFileID) ~= 1)
    l_sData = fgetl(g_iFileID);
    g_iLine = g_iLine + 1;
    
    % Skip empty strings.
    if(size(l_sData) <= 0)
        continue;
    end
    
    switch(l_sData(1))
        case('#')
            % Skip comments.
        case('}')
            % The adjacence matrix ends. This should be the end of the
            % file, too. Just do nothing.
        case('{')
            if(strcmp(l_sData, '{'))
                % The adjacence matrix begins. Just skip the line.
                continue;
            end
            % A new line of the adjacence matrix.
            l_iSize = size(l_sData);
            l_sData = l_sData(2:l_iSize(2) - 1);
            l_cEdges = strsplit(l_sData, ',');
            g_cEdges = cat(1, g_cEdges, l_cEdges);
        case('[')
            % There are some (minimum one) nodes.
            l_sData = strsplit(l_sData, ';');
            l_iSize = size(l_sData);
            for l_iIteratorA = 1:l_iSize(2)
                l_aPosition = textscan(char(l_sData(1,l_iIteratorA)),'[%f,%f]');
                g_tNodes = cat(1, g_tNodes, l_aPosition);
            end
        otherwise
            % Something bad has happened. Clean up and throw error.
            fclose(g_iFileID);
            clear l_iIteratorA l_iSize l_aPosition l_cEdges l_sEdges g_iWidth g_iHeight g_iFileID g_dSystem g_sInputPath g_sTitle g_cEdges g_tNodes;
            error('Error: Invalid structure in input-file! (line %u: Data = %s)', g_iLine, l_sData);
    end
end

% Clean up everything, that is not needed anymore.
fclose(g_iFileID);
clear l_sData l_cEdges g_iLine g_iFileID g_sInputPath;

% Check whether a Simulink model with the same name is open.
if bdIsLoaded(g_sTitle)
    % A model with same name is open. Close it without saving and print a
    % warning.
    warning('Another model with the name ''%s'' was open. It got closed without saving!', g_sTitle);
    close_system(g_sTitle, 0);
end

% This holds the new Simulink system.
g_dSystem = new_system(g_sTitle);

% Start creating the blocks.
l_iSize = size(g_tNodes);
for l_iIteratorA = 1:l_iSize(1, 1)
    l_aPosition = [g_tNodes{l_iIteratorA, 1}{1, 1}, g_tNodes{l_iIteratorA, 2}{1, 1}, (g_tNodes{l_iIteratorA, 1}{1, 1}) + g_iWidth, g_tNodes{l_iIteratorA, 2}{1, 1} + g_iHeight];
    add_block('built-in/Gain', strcat(g_sTitle, '/Node', (l_iIteratorA + '0')), 'Position', l_aPosition);
end

% Start connecting the blocks.
l_iCount = 2;
for l_iIteratorA = 1:(l_iSize(1, 1) - 1)
    for l_iIteratorB = l_iCount:l_iSize(1, 1)
        if(g_cEdges{l_iIteratorA, l_iIteratorB} == '1')
            %add_line(g_sTitle, strcat('Node', (l_iIteratorA + '0'), '/1'), strcat('Node', (l_iIteratorB + '0'), '/1'), 'autorouting', 'on');
        end
    end
    l_iCount = l_iCount + 1;
end

% Open the created system.
open_system(g_dSystem);

% Clean up.
clear l_iSize l_iIteratorA l_iIteratorB l_iCount l_aPosition g_iHeight g_iWidth g_dSystem g_sTitle g_cEdges g_tNodes;

% End of script
