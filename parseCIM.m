
% This script handles the input for the automatic generation of large power
% systems in Simulink.
%
% Author: First Name: Bernhard
%         Last Name:  Krop
%         E-Mail:     b.krop@gmx.de
%
% Last time updated:  25. January 2016

% @TODO:
% Consider about pre-allocate 'g_cObjects'.
function parseCIM()

    % Use global variables.
    global g_sFilePath;
    
    % Make variables global.
    global g_iFileID g_iLine g_sData g_cObjects;

    % This will contain the whole objects as strings.
    g_cObjects = cell(0, 3);
    % The file ID for the input file.
    g_iFileID = fopen(g_sFilePath, 'r');
    % The line counter.
    g_iLine = 0;
    % The input buffer.
    g_sData = '';
    
    % Check whether the file is open.
    if(g_iFileID < 0)
        % The file is not open. Clean up and throw an error.
        clearvars -except g_sFilePath;
        error('Error: Could not open file! (Path: %s)', g_sFilePath);
    end
    
    % Read the whole file to get the input.
    while(feof(g_iFileID) ~= 1)
        g_sData = '';
        readLine();
        
        % Skip empty strings.
        l_cSize = size(g_sData);
        if((l_cSize(1) <= 0) || (l_cSize(2) <= 0))
            continue;
        end
        
        % Read data.
        if(g_sData(1) == '<')
            % A new tag.
            switch(g_sData(2))
                case ('?')
                    % Probably the first XML line. Just ignore it.
                    continue;
                case ('r')
                    % Probably the first RDF line. Just ignore it.
                    continue;
                case ('c')
                    % Probably a new CIM tag. Parse it.
                    l_cSpaces = strfind(g_sData, ' ');
                    if(size(l_cSpaces) <= 0)
                        warning('Could not parse CIM-tag! (Line: %u)', g_iLine);
                        continue;
                    end
                    l_sTag = g_sData(2 : l_cSpaces(1) - 1);
                    l_cTagEnd = strfind(g_sData, ['</', l_sTag, '>']);
                    while(size(l_cTagEnd) <= 0)
                        readLine();
                        l_cTagEnd = strfind(g_sData, ['</', l_sTag, '>']);
                    end
                    % Now, g_sData contains the whole object. Parse it!
                    l_cQuoteChars = strfind(g_sData, '"');
                    if(size(l_cQuoteChars) <= 1)
                        warning('Could not parse RDF-ID! (Line: %u)', g_iLine);
                        continue;
                    end
                    l_sID = g_sData(l_cQuoteChars(1) + 1 : l_cQuoteChars(2) - 1);
                    l_cTagStart = strfind(g_sData, '<');
                    l_cTagEnd = strfind(g_sData, '>');
                    l_cSize = size(l_cTagStart);
                    g_sData = g_sData(l_cTagEnd(1) + 1 : l_cTagStart(l_cSize(2)) - 1);
                    g_cObjects = vertcat(g_cObjects, {l_sTag(5 : end), l_sID, g_sData});
                case ('/')
                    % A tag ends, which is not a CIM-tag (probably an
                    % RDF-tag). Just ignore it.
                otherwise
                    warning('XML-tag could not be identified! (Line: %u)', g_iLine);
                    continue;
            end % End of switch.
        else
            warning('Could not read line, because it doesn''t start with ''<''! (Line: %u)', g_iLine);
            continue;
        end % End of if.
    end % End of while.
    
    % Clean up everything, that is not needed anymore.
    fclose(g_iFileID);
    clearvars -global -except g_cObjects;

end % End of main function.

% This function reads a line of a XML-file and removes all comments in that
% line.
% @TODO:
% Consider about pre-allocation of 'g_sData'.
function readLine()

    % Use global variables.
    global g_iFileID g_iLine g_sData;

    g_sData = [g_sData, strtrim(fgetl(g_iFileID))];
    g_iLine = g_iLine + 1;
        
    % Skip comments.
    l_aCommentStart = strfind(g_sData, '<!--');
    l_cSize = size(l_aCommentStart);
    while(l_cSize > 0)
        l_aCommentEnd = strfind(g_sData, '-->');
        while(size(l_aCommentEnd) <= 0)
            g_sData = [g_sData, strtrim(fgetl(g_iFileID))];
            g_iLine = g_iLine + 1;
            l_aCommentEnd = strfind(g_sData, '-->');
        end
        g_sData = [g_sData(1 : l_aCommentStart(l_cSize(2)) - 1), g_sData(l_aCommentEnd(1) + 3 : end)];
        l_aCommentStart = strfind(g_sData, '<!--');
        l_cSize = size(l_aCommentStart);
    end
    
    % Clean up everything, that is not needed anymore.
    clearvars;
    
end % End of function 'readLine'.

% End of script.
