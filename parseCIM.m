
% This script handles the input for the automatic generation of large power
% systems in Simulink.
%
% Author: First Name: Bernhard
%         Last Name:  Krop
%         E-Mail:     b.krop@gmx.de
%
% Last time updated:  09. December 2015

function parseCIM()

    % Use global variables.
    global g_sFilePath;
    
    % Make variables global.
    global g_cObjects;

    % This will contain the whole objects as strings.
    g_cObjects = {'Class' 'ID' 'Attributes'};
    % The file ID for the input file.
    l_iFileID = fopen(g_sFilePath, 'r');
    % The line counter.
    l_iLine = 0;
    
    % Check whether the file is open.
    if(l_iFileID < 0)
        % The file is not open. Clean up and throw an error.
        clearvars -except g_sFilePath g_cObjects;
        error('Error: Could not open file! (Path: %s)', g_sFilePath);
    end
    
    % Read the whole file to get the input.
    while(feof(l_iFileID) ~= 1)
        l_sData = strtrim(fgetl(l_iFileID));
        l_iLine = l_iLine + 1;
        
        % Skip comments.
        l_aCommentStart = strfind(l_sData, '<!--');
        while(size(l_aCommentStart) > 0)
            l_aCommentEnd = strfind(l_sData, '-->');
            while(size(l_aCommentEnd) <= 0)
                l_sData = strcat(l_sData, strtrim(fgetl(l_iFileID)));
                l_iLine = l_iLine + 1;
                l_aCommentEnd = strfind(l_sData, '-->');
            end
            l_sData = l_sData(l_aCommentEnd(1) + 3 : end);
            l_aCommentStart = strfind(l_sData, '<!--');
        end
    
        % Skip empty strings.
        l_cSize = size(l_sData);
        if((l_cSize(1) <= 0) || (l_cSize(2) <= 0))
            continue;
        end
        
        % Read data.
        if(l_sData(1) == '<')
            % A new tag.
            switch(l_sData(2))
                case ('?')
                    % Probably the first xml line. Just ignore it.
                    continue;
                case ('r')
                    % Probably the first rdf line. Just ignore it.
                    continue;
                case ('c')
                    % A new cim tag. Parse it.
                    l_cSeparators = strfind(l_sData, ' ');
                    if(size(l_cSeparators) <= 0)
                        warning('Could not parse line, because could not parse CIM-tag! (Line: %u)', l_iLine);
                        continue;
                    end
                    l_sTag = l_sData(2:l_cSeparators(1, 1) - 1);
                    l_cTagEnd = strfind(l_sData, strcat('</', strcat(l_sTag, '>')));
                    while(size(l_cTagEnd) <= 0)
                        l_sData = strcat(l_sData, strtrim(fgetl(l_iFileID)));
                        l_iLine = l_iLine + 1;
                        l_cTagEnd = strfind(l_sData, strcat('</', strcat(l_sTag, '>')));
                    end
                    % Now, l_sData contains the whole object. Parse it!
                    l_cQuoteChars = strfind(l_sData, '"');
                    if(size(l_cQuoteChars) <= 1)
                        warning('Could not read line, because could not parse RDF-ID! (Line: %u)', l_iLine);
                        continue;
                    end
                    l_sID = l_sData(l_cQuoteChars(1) + 1 : l_cQuoteChars(2) - 1);
                    l_cTagStart = strfind(l_sData, '<');
                    l_cTagEnd = strfind(l_sData, '>');
                    l_cSize = size(l_cTagStart);
                    l_sData = l_sData(l_cTagEnd(1) + 1:l_cTagStart(l_cSize(2)) - 1);
                    g_cObjects = cat(1, g_cObjects, {l_sTag(5:end), l_sID, l_sData});
                case ('/')
                    % A tag ends, which is not a cim-tag (probably an
                    % rdf-tag). Just ignore it.
                otherwise
                    warning('Could not read line, because xml-tag could not be identified! (Line: %u)', l_iLine);
                    continue;
            end % End of switch.
        else
            warning('Could not read line, because it doesn''t start with ''<''! (Line: %u)', l_iLine);
            continue;
        end % End of if.
    end % End of while.
    
    % Clean up everything, that is not needed anymore.
    fclose(l_iFileID);
    clearvars -except g_sFilePath g_cObjects;

end % End of main function.

% End of script.
