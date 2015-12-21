
% This script handles the generation of a Simulink model for large power
% systems.
%
% Author: First Name: Bernhard
%         Last Name:  Krop
%         E-Mail:     b.krop@gmx.de
%
% Last time updated:  21. December 2015

function createSystem()

    % Use global variables.
    global g_sTitle g_cObjects;

    % Make variables global.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_dSystem g_cBlocks;
    
    % Check whether a Simulink model with the same name is open.
    if bdIsLoaded(g_sTitle)
        % A model with same name is open. Close it without saving and print
        % a warning.
        warning('Another model with the name ''%s'' was open. It got closed without saving!', g_sTitle);
        close_system(g_sTitle, 0);
    end

    % The Simulink model.
    g_dSystem = new_system(g_sTitle);
    % The width of each block.
    g_iWidth = 30;
    % The height of each block.
    g_iHeight = 30;
    % The offset between blocks.
    g_iOffset = 50;
    
    % Check if CIM objects exists.
    l_cSize = size(g_cObjects);
    if(l_cSize(1, 1) <= 1)
        clearvars -except g_dSystem;
        return;
    end
    
    % A cell which contains all information of already created blocks. It
    % contains:
    %
    % The RDF-ID of the object;
    % The name of the block;
    % The name of the parent block;
    % The number of blocks in the (sub)system.
    g_cBlocks = {'', g_sTitle, '', 0};
    
    % Create enums.
    Simulink.defineIntEnumType('Boolean', {'true', 'false'}, [0, 1]);
    Simulink.defineIntEnumType('FuelType', {'coal', 'gas', 'lignite', 'oil'}, [0, 1, 2, 3]);
    Simulink.defineIntEnumType('GeneratorControlSource', {'unavailable', 'offAGC', 'onAGC', 'plantControl'}, [0, 1, 2, 3]);
    Simulink.defineIntEnumType('PhaseCode', {'ABCN', 'ABC', 'ABN', 'ACN', 'BCN', 'AB', 'AC', 'BC', 'AN', 'BN', 'CN', 'A', 'B', 'C', 'N', 's1N', 's2N', 's12N', 's1', 's2', 's12'}, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
    Simulink.defineIntEnumType('RegulatingControlModeKind', {'activePower', 'admittance', 'currentFlow', 'fixed', 'reactivePower', 'voltage'}, [0, 1, 2, 3, 4, 5]);
    Simulink.defineIntEnumType('SynchronousMachineOperatingMode', {'condenser', 'generator'}, [0, 1]);
    Simulink.defineIntEnumType('SynchronousMachineType', {'condenser', 'generator', 'generator_or_condenser'}, [0, 1, 2]);
    Simulink.defineIntEnumType('UnitMultiplier', {'p', 'n', 'micro', 'm', 'c', 'd', 'k', 'M', 'G', 'T', 'none'}, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    Simulink.defineIntEnumType('UnitSymbol', {'VA', 'W', 'VAr', 'VAh', 'Wh', 'VArh', 'V', 'ohm', 'A', 'F', 'H', 'degC', 's', 'min_', 'h', 'deg', 'rad', 'J', 'N', 'S', 'none', 'Hz', 'g', 'Pa', 'm', 'm2', 'm3'}, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]);
    Simulink.defineIntEnumType('WindingConnection', {'D', 'Y', 'Z'}, [0, 1, 2]);
    Simulink.defineIntEnumType('WindingType', {'primary', 'secondary', 'tertiary'}, [0, 1, 2]);
    
    % Create all objects.
    for g_iIterator = 2:l_cSize(1, 1)
        switch(g_cObjects{g_iIterator, 1})
            case ('Analog')
                createAnalog();
            case ('BaseVoltage')
                createBaseVoltage();
            case ('ConnectivityNode')
                createConnectivityNode();
            case ('GeographicalRegion')
                createGeographicalRegion();
            case ('PowerTransformer')
                createPowerTransformer();
            case ('RegulatingControl')
                createRegulatingControl();
            case ('SubGeographicalRegion')
                createSubGeographicalRegion();
            case ('Substation')
                createSubstation();
            case ('SynchronousMachine')
                createSynchronousMachine();
            case ('Terminal')
                createTerminal();
            case ('ThermalGeneratingUnit')
                createThermalGeneratingUnit();
            case ('TransformerWinding')
                createTransformerWinding();
            case ('VoltageLevel')
                createVoltageLevel();
            otherwise
                warning('Could not define class ''%s''!', g_cObjects{g_iIterator, 1});
                continue;
        end % End of switch.
    end % End of for.
    
    % Clean up everything, that is not needed anymore.
    clearvars -except g_dSystem;

end % End of main function.

% This function returns the index of the position, based on the number of
% blocks.
% @param    number  The number of blocks in the current (sub)system.
% @return   index   A 1x2 cell with the index of the position. The left
%                   cell contains the x-position, the right one the
%                   y-position.
function index = getPositionIndex(number)
    
    if(~exist('number', 'var') || ~isnumeric(number))
        index = {0, 0};
        return;
    end

    % The current maximum length.
    l_iLength = 1;
    
    % Determine current dimension.
    while(true)
        if(number < (l_iLength * l_iLength))
            break;
        end
        l_iLength = l_iLength + 1;
    end
    
    % Remove all positions of smaller dimensions.
    number = number - ((l_iLength - 1) * (l_iLength - 1));
    
    % Determine x- and y-position.
    if(number < (l_iLength - 1))
        l_iX = l_iLength - 1;
        l_iY = number;
    else
        l_iX = number - (l_iLength - 1);
        l_iY = l_iLength - 1;
    end
    
    % Clean up everthing, that is not needed anymore.
    index = {l_iX, l_iY};
    clearvars -except index;
    
end % End of function 'getPositionIndex'.

function createAnalog()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Measurement.MemberOf_PowerSystemResource');
        if(size(l_cFind) > 0)
            l_sMemberOf_PowerSystemResource = l_cAttributes{l_iI}(l_cFind(1) + 60:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Measurement.measurementType');
        if(size(l_cFind) > 0)
            l_sMeasurementType = l_cAttributes{l_iI}(l_cFind(1) + 32:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Measurement.phases');
        if(size(l_cFind) > 0)
            l_sPhases = l_cAttributes{l_iI}(l_cFind(1) + 23:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Measurement.Terminal');
        if(size(l_cFind) > 0)
            l_sTerminal = l_cAttributes{l_iI}(l_cFind(1) + 40:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Measurement.unitMultiplier');
        if(size(l_cFind) > 0)
            l_sUnitMultiplier = l_cAttributes{l_iI}(l_cFind(1) + 46:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Measurement.unitSymbol');
        if(size(l_cFind) > 0)
            l_sUnitSymbol = l_cAttributes{l_iI}(l_cFind(1) + 42:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Analog.LimitSets');
        if(size(l_cFind) > 0)
            l_cFind = strfind(l_cAttributes{l_iI}, '"');
            l_cSize = size(l_cFind);
            l_cLimitSets = cell(l_cSize(1, 2) / 2, 1);
            l_iJ = 1;
            while (l_iJ < l_cSize(1, 2))
                l_cLimitSets{(l_iJ + 1) / 2} = l_cAttributes{l_iI}(l_cFind(l_iJ) + 2:l_cFind(l_iJ + 1) - 1);
                l_iJ = l_iJ + 2;
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Analog.maxValue');
        if(size(l_cFind) > 0)
            l_sMaxValue = l_cAttributes{l_iI}(l_cFind(1) + 20:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Analog.minValue');
        if(size(l_cFind) > 0)
            l_sMinValue = l_cAttributes{l_iI}(l_cFind(1) + 20:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Analog.normalValue');
        if(size(l_cFind) > 0)
            l_sNormalValue = l_cAttributes{l_iI}(l_cFind(1) + 23:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Analog.positiveFlowIn');
        if(size(l_cFind) > 0)
            l_sPositiveFlowIn = strcat('Boolean.', l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3));
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Analog.SetPoint');
        if(size(l_cFind) > 0)
            l_sSetPoint = l_cAttributes{l_iI}(l_cFind(1) + 40:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for Analog! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this Analog.
    
    % Every Analog is part of a PowerSystemResource. Therefore,
    % Measurement.MemberOf_PowerSystemResource has to exist. If it doesn't
    % exist, this block cannot be created.
    if(~exist('l_sMemberOf_PowerSystemResource', 'var'))
        warning('Could not create Analog, because PowerSystemResource is missing! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    for l_iI = 1:size(g_cBlocks)
        if(strcmp(g_cBlocks{l_iI, 1}, l_sMemberOf_PowerSystemResource))
            l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
            break;
        end
    end
    if(~exist('l_sParent', 'var'))
        warning('Could not create Analog, because could not find PowerSystemResource, belonging to RDF-Resource! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
        return;
    end
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('Analog', g_iIterator);
    end
    % The type of measurement of this Analog. If
    % Measurement.measurementType exists, it is appended to the name of the
    % block via [ and ].
    if(exist('l_sMeasurementType', 'var'))
        l_sName = strcat(l_sName, ' [', l_sMeasurementType, ']');
    end
    % Now, the block for this Analog can be created. Because it contains
    % some Constants, it is a Subsystem.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    % The kind of phases, this Analog measures. If Measurement.phases
    % doesn't exist, it is assumed to be 'ABCN'.
    l_cPos = getPositionIndex(0);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/phases'), 'Position', l_aPosition);
    if(exist('l_sPhases', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/phases'), 'OutDataTypeStr', 'Enum: PhaseCode', 'Value', l_sPhases);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/phases'), 'OutDataTypeStr', 'Enum: PhaseCode', 'Value', 'PhaseCode.ABCN');
    end
    % The unit multiplier of this Analog. If Measurement.unitMultiplier
    % doesn't exist, it is set to 'none'.
    l_cPos = getPositionIndex(1);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/unitMultiplier'), 'Position', l_aPosition);
    if(exist('l_sUnitMultiplier', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/unitMultiplier'), 'OutDataTypeStr', 'Enum: UnitMultiplier', 'Value', l_sUnitMultiplier);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/unitMultiplier'), 'OutDataTypeStr', 'Enum: UnitMultiplier', 'Value', 'UnitMultiplier.none');
    end
    % The unit symbol of this Analog. If Measurement.unitSymbol doesn't
    % exist, it is set to 'none'.
    l_cPos = getPositionIndex(2);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/unitSymbol'), 'Position', l_aPosition);
    if(exist('l_sUnitSymbol', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/unitSymbol'), 'OutDataTypeStr', 'Enum: UnitSymbol', 'Value', l_sUnitSymbol);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/unitSymbol'), 'OutDataTypeStr', 'Enum: UnitSymbol', 'Value', 'UnitSymbol.none');
    end
    % The Terminal, this Analog is connected with. It is assumed, that the
    % Terminal already exists, if Measurment.Terminal exists.
    if(exist('l_sTerminal', 'var'))
        for l_iJ = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iJ, 1}, l_sTerminal))
                l_sT = strcat(g_cBlocks{l_iJ, 3}, g_cBlocks{l_iJ, 2});
                break;
            end
        end
        if(exist('l_sT', 'var'))
            % TODO: Connect the found Terminal with this Analog.
            warning('Connection from Analogs to Terminals is currently not implemented!');
        else
            warning('Could not find Terminal, belonging to RDF-Resource, for Analog! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
        end
    end
    % The normal measurement value of this Analog (Analog.normalValue) and
    % it's boundaries (Analog.minValue and Analog.maxValue).
    l_cPos = getPositionIndex(3);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/value'), 'Position', l_aPosition);
    if(exist('l_sNormalValue', 'var'))
        if(exist('l_sMinValue', 'var'))
            if(exist('l_sMaxValue', 'var'))
                set_param(strcat(l_sParent, '/', l_sName, '/value'), 'Value', l_sNormalValue, 'OutMin', l_sMinValue, 'OutMax', l_sMaxValue);
            else
                set_param(strcat(l_sParent, '/', l_sName, '/value'), 'Value', l_sNormalValue, 'OutMin', l_sMinValue);
            end
        else
            if(exist('l_sMaxValue', 'var'))
                set_param(strcat(l_sParent, '/', l_sName, '/value'), 'Value', l_sNormalValue, 'OutMax', l_sMaxValue);
            else
                set_param(strcat(l_sParent, '/', l_sName, '/value'), 'Value', l_sNormalValue);
            end
        end
    else
        if(exist('l_sMinValue', 'var'))
            if(exist('l_sMaxValue', 'var'))
                set_param(strcat(l_sParent, '/', l_sName, '/value'), 'Value', l_sMinValue, 'OutMin', l_sMinValue, 'OutMax', l_sMaxValue);
            else
                set_param(strcat(l_sParent, '/', l_sName, '/value'), 'Value', l_sMinValue, 'OutMin', l_sMinValue);
            end
        else
            if(exist('l_sMaxValue', 'var'))
                set_param(strcat(l_sParent, '/', l_sName, '/value'), 'Value', l_sMaxValue, 'OutMax', l_sMaxValue);
            end
        end
    end % End of if.
    % The Analog.positiveFlowIn indicates, whether the measured value flows
    % into the PowerSystemResource. If it doesn't exist, it is assumed to
    % be true.
    l_cPos = getPositionIndex(4);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/positiveFlowIn'), 'Position', l_aPosition);
    if(exist('l_sPositiveFlowIn', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/positiveFlowIn'), 'OutDataTypeStr', 'Enum: Boolean', 'Value', l_sPositiveFlowIn);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/positiveFlowIn'), 'OutDataTypeStr', 'Enum: Boolean', 'Value', 'Boolean.true');
    end
    % The SetPoint, this Analog is connected with. It is assumed, that the
    % SetPoint already exists, if Analog.SetPoint exists.
    if(exist('l_sSetPoint', 'var'))
        for l_iJ = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iJ, 1}, l_sSetPoint))
                l_sSP = strcat(g_cBlocks{l_iJ, 3}, g_cBlocks{l_iJ, 2});
                break;
            end
        end
        if(exist('l_sSP', 'var'))
            % TODO: Connect the found SetPoint with this Analog.
            warning('Connection from Analogs to SetPoints is currently not implemented!');
        else
            warning('Could not find SetPoint, belonging to RDF-Resource, for Analog! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
        end
    end
    % The LimitSets, this Analog is connected with. It is assumed, that the
    % AnalogLimitSets already exists, if Analog.LimitSets exists.
    if(exist('l_cLimitSets', 'var'))
        for l_iJ = 1:size(l_cLimitSets)
            for l_iK = 1:size(g_cBlocks)
                if(strcmp(g_cBlocks{l_iK, 1}, l_cLimitSets{l_iJ}))
                    l_sLS = strcat(g_cBlocks{l_iK, 3}, g_cBlocks{l_iK, 2});
                    break;
                end
            end
            if(exist('l_sLS', 'var'))
                % TODO: Connect the found AnalogLimitSet with this Analog.
                warning('Connection from Analogs to AnalogLimitSets is currently not implemented!');
            else
                warning('Could not find AnalogLimitSet, belonging to RDF-Resource, for Analog! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
            end
            clearvars l_sLS;
        end
    end
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 5});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createAnalog'.

function createBaseVoltage()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_sTitle g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:BaseVoltage.isDC');
        if(size(l_cFind) > 0)
            if(strcmpi(l_cAttributes{l_iI}(l_cFind(1) + 21:l_cFind(2) - 3), 'true'))
                l_bIsDC = true;
            else
                l_bIsDC = false;
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:BaseVoltage.nominalVoltage');
        if(size(l_cFind) > 0)
            l_sNominalVoltage = num2str(str2double(l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3)) * 1000);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for BaseVoltage! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this BaseVoltage.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('BaseVoltage', g_iIterator);
    end
    % BaseVoltage.isDC indicates whether the BaseVoltage is a dc or an ac
    % source. If it doesn't exist, it is assumed to be false.
    if(~exist('l_bIsDC', 'var'))
        l_bIsDC = false;
    end
    % Now, the block for this BaseVoltage can be created, depending on
    % whether it is a dc or an ac source.
    % BaseVoltage.nominalVoltage of this BaseVoltage is set right after the
    % creation.
    l_cPos = getPositionIndex(g_cBlocks{1, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    if(l_bIsDC)
        add_block('fl_lib/Electrical/Electrical Sources/DC Voltage Source', strcat(g_sTitle, '/', l_sName), 'Position', l_aPosition);
        if(exist('l_sNominalVoltage', 'var'))
            set_param(strcat(g_sTitle, '/', l_sName), 'v0', l_sNominalVoltage);
        end
    else
        add_block('fl_lib/Electrical/Electrical Sources/AC Voltage Source', strcat(g_sTitle, '/', l_sName), 'Position', l_aPosition);
        if(exist('l_sNominalVoltage', 'var'))
            set_param(strcat(g_sTitle, '/', l_sName), 'amp', l_sNominalVoltage);
        end
    end
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{1, 4} = g_cBlocks{1, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, g_sTitle, 0});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_sTitle g_cObjects g_cBlocks;

end % End of function 'createBaseVoltage'.

function createConnectivityNode()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:ConnectivityNode.ConnectivityNodeContainer');
        if(size(l_cFind) > 0)
            l_sConnectivityNodeContainer = l_cAttributes{l_iI}(l_cFind(1) + 62:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for ConnectivityNode! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this ConnectivityNode.
    
    % The ConnectivityNodeContainer, which contains this ConnectivityNode.
    % If ConnectivityNode.ConnectivityNodeContainer doesn't exist, this
    % ConnectivityNode cannot be created.
    if(~exist('l_sConnectivityNodeContainer', 'var'))
        warning('Could not create ConnectivityNode, because ConnectivityNodeContainer is missing! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    for l_iI = 1:size(g_cBlocks)
        if(strcmp(g_cBlocks{l_iI, 1}, l_sConnectivityNodeContainer))
            l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
            break;
        end
    end
    if(~exist('l_sParent', 'var'))
        warning('Could not create ConnectivityNode, because could not find ConnectivityNodeContainer, belonging to RDF-Resource! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('ConnectivityNode', g_iIterator);
    end
    % Now, the block for this ConnectivityNode can be created. Because it
    % contains some blocks to connect other blocks, it is a Subsystem.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 0});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createConnectivityNode'.

function createGeographicalRegion()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_sTitle g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for GeographicalRegion! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this GeographicalRegion.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('GeographicalRegion', g_iIterator);
    end
    % Now, the block for this GeographicalRegion can be created. Because it
    % contains some SubGeographicalRegions, it is a Subsystem.
    l_cPos = getPositionIndex(g_cBlocks{1, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(g_sTitle, '/', l_sName), 'Position', l_aPosition);
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{1, 4} = g_cBlocks{1, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, g_sTitle, 0});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_sTitle g_cObjects g_cBlocks;

end % End of function 'createGeographicalRegion'.

function createPowerTransformer()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Equipment.MemberOf_EquipmentContainer');
        if(size(l_cFind) > 0)
            l_sMemberOf_EquipmentContainer = l_cAttributes{l_iI}(l_cFind(1) + 57:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for PowerTransformer! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this PowerTransformer.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('PowerTransformer', g_iIterator);
    end
    % The EquipmentContainer, the PowerTransformer is member of. If it
    if(~exist('l_sMemberOf_EquipmentContainer', 'var'))
        warning('Could not create PowerTransformer, because EquipmentContainer is missing! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    for l_iI = 1:size(g_cBlocks)
        if(strcmp(g_cBlocks{l_iI, 1}, l_sMemberOf_EquipmentContainer))
            l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
            break;
        end
    end
    if(~exist('l_sParent', 'var'))
        warning('Could not create PowerTransformer, because could not find EquipmentContainer, belonging to RDF-Resource! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    % The PowerTransformer itself.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 0});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createPowerTransformer'.

function createRegulatingControl()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        % Currently not used!
        %l_cFind = strfind(l_cAttributes{l_iI}, 'cim:RegulatingControl.discrete');
        %if(size(l_cFind) > 0)
        %    if(strcmpi(l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), 'true'))
        %        l_bDiscrete = true;
        %    else
        %        l_bDiscrete = false;
        %    end
        %    continue;
        %end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:RegulatingControl.Terminal');
        if(size(l_cFind) > 0)
            l_sTerminal = l_cAttributes{l_iI}(l_cFind(1) + 46:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:RegulatingControl.targetRange');
        if(size(l_cFind) > 0)
            l_sTargetRange = l_cAttributes{l_iI}(l_cFind(1) + 33:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:RegulatingControl.targetValue');
        if(size(l_cFind) > 0)
            l_sTargetValue = l_cAttributes{l_iI}(l_cFind(1) + 33:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:RegulatingControl.mode');
        if(size(l_cFind) > 0)
            l_cFind = strfind(l_cAttributes{l_iI}, '#');
            l_sMode = l_cAttributes{l_iI}(l_cFind(1) + 1:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for RegulatingControl! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this RegulatingControl.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('RegulatingControl', g_iIterator);
    end
    % The Terminal, which contains the RegulatingControl.
    if(~exist('l_sTerminal', 'var'))
        warning('Could not create RegulatingControl, because Terminal is missing! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    for l_iI = 1:size(g_cBlocks)
        if(strcmp(g_cBlocks{l_iI, 1}, l_sTerminal))
            l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
            break;
        end
    end
    if(~exist('l_sParent', 'var'))
        warning('Could not create RegulatingControl, because could not find Terminal, belonging to RDF-Resource, for RegulatingControl! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
        return;
    end
    % The RegulatingControl itself.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    % Target range.
    l_cPos = getPositionIndex(0);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/targetRange'), 'Position', l_aPosition);
    if(exist('l_sTargetRange', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/targetRange'), 'Value', l_sTargetRange);
    end
    % Target value.
    l_cPos = getPositionIndex(1);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/targetValue'), 'Position', l_aPosition);
    if(exist('l_sTargetValue', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/targetValue'), 'Value', l_sTargetValue);
    end
    % Mode.
    l_cPos = getPositionIndex(2);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/mode'), 'Position', l_aPosition);
    if(exist('l_sMode', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/mode'), 'OutDataTypeStr', 'Enum: RegulatingControlModeKind', 'Value', l_sMode);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/mode'), 'OutDataTypeStr', 'Enum: RegulatingControlModeKind', 'Value', 'RegulatingControlModeKind.fixed');
    end
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 3});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createRegulatingControl'.

function createSubGeographicalRegion()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SubGeographicalRegion.Region');
        if(size(l_cFind) > 0)
            l_sRegion = l_cAttributes{l_iI}(l_cFind(1) + 48:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for SubGeographicalRegion! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this SubGeographicalRegion.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('SubGeographicalRegion', g_iIterator);
    end
    % The GeographicalRegion, which contains this SubGeographicalRegion.
    if(~exist('l_sRegion', 'var'))
        warning('Could not create SubGeographicalRegion, because Region is missing! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    for l_iI = 1:size(g_cBlocks)
        if(strcmp(g_cBlocks{l_iI, 1}, l_sRegion))
            l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
            break;
        end
    end
    if(~exist('l_sParent', 'var'))
        warning('Could not create SubGeographicalRegion, because could not find GeographicalRegion, belonging to RDF-Resource! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    % The SubGeographicalRegion itself.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 0});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createSubGeographicalRegion'.

function createSubstation()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Substation.Region');
        if(size(l_cFind) > 0)
            l_sRegion = l_cAttributes{l_iI}(l_cFind(1) + 37:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for Substation! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this Substation.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('Substation', g_iIterator);
    end
    % The SubGeographicalRegion, which contains this Substation.
    if(~exist('l_sRegion', 'var'))
        warning('Could not create SubStation, because Region is missing! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    for l_iI = 1:size(g_cBlocks)
        if(strcmp(g_cBlocks{l_iI, 1}, l_sRegion))
            l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
            break;
        end
    end
    if(~exist('l_sParent', 'var'))
        warning('Could not create SubStation, because could not find SubGeographicalRegion, belonging to RDF-Resource! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    % The Substation itself.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 0});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createSubstation'.

function createSynchronousMachine()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        % Currently not used!
        %l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Equipment.equivalent');
        %if(size(l_cFind) > 0)
        %    if(strcmpi(l_cAttributes{l_iI}(l_cFind(1) + 25:l_cFind(2) - 3), 'true'))
        %        l_bEquivalent = true;
        %    else
        %        l_bEquivalent = false;
        %    end
        %    continue;
        %end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Equipment.MemberOf_EquipmentContainer');
        if(size(l_cFind) > 0)
            l_sMemberOf_EquipmentContainer = l_cAttributes{l_iI}(l_cFind(1) + 57:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:ConductingEquipment.BaseVoltage');
        if(size(l_cFind) > 0)
            l_sBaseVoltage = l_cAttributes{l_iI}(l_cFind(1) + 51:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:RegulatingCondEq.RegulatingControl');
        if(size(l_cFind) > 0)
            l_sRegulatingControl = l_cAttributes{l_iI}(l_cFind(1) + 57:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.baseQ');
        if(size(l_cFind) > 0)
            l_sBaseQ = l_cAttributes{l_iI}(l_cFind(1) + 29:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.maxQ');
        if(size(l_cFind) > 0)
            l_sMaxQ = l_cAttributes{l_iI}(l_cFind(1) + 28:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.minQ');
        if(size(l_cFind) > 0)
            l_sMinQ = l_cAttributes{l_iI}(l_cFind(1) + 28:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.operatingMode');
        if(size(l_cFind) > 0)
            l_cFind = strfind(l_cAttributes{l_iI}, '#');
            l_sOperatingMode = l_cAttributes{l_iI}(l_cFind(1) + 1:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.qPercent');
        if(size(l_cFind) > 0)
            l_sQPercent = l_cAttributes{l_iI}(l_cFind(1) + 32:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.referencePriority');
        if(size(l_cFind) > 0)
            l_sReferencePriority = l_cAttributes{l_iI}(l_cFind(1) + 41:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.ratedS');
        if(size(l_cFind) > 0)
            l_sRatedS = l_cAttributes{l_iI}(l_cFind(1) + 30:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.r0');
        if(size(l_cFind) > 0)
            l_sR0 = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.r2');
        if(size(l_cFind) > 0)
            l_sR2 = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.r');
        if(size(l_cFind) > 0)
            l_sR = l_cAttributes{l_iI}(l_cFind(1) + 25:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.type');
        if(size(l_cFind) > 0)
            l_cFind = strfind(l_cAttributes{l_iI}, '#');
            l_sType = l_cAttributes{l_iI}(l_cFind(1) + 1:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.x0');
        if(size(l_cFind) > 0)
            l_sX0 = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.x2');
        if(size(l_cFind) > 0)
            l_sX2 = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.x');
        if(size(l_cFind) > 0)
            l_sX = l_cAttributes{l_iI}(l_cFind(1) + 25:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.InitialReactiveCapabilityCurve');
        if(size(l_cFind) > 0)
            l_sInitialReactiveCapabilityCurve = l_cAttributes{l_iI}(l_cFind(1) + 69:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:SynchronousMachine.MemberOf_GeneratingUnit');
        if(size(l_cFind) > 0)
            l_sMemberOf_GeneratingUnit = l_cAttributes{l_iI}(l_cFind(1) + 62:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for SynchronousMachine! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this SynchronousMachine.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('SynchronousMachine', g_iIterator);
    end
    % The parent (GeneratingUnit or EquipmentContainer), the SynchronousMachine is member of.
    if(exist('l_sMemberOf_GeneratingUnit', 'var'))
        for l_iI = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iI, 1}, l_sMemberOf_GeneratingUnit))
                l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
                break;
            end
        end
        if(~exist('l_sParent', 'var'))
            if(~exist('l_sMemberOf_EquipmentContainer', 'var'))
                warning('Could not create SynchronousMachine, because GeneratingUnit and EquipmentContainer are missing! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
                return;
            end
            for l_iI = 1:size(g_cBlocks)
                if(strcmp(g_cBlocks{l_iI, 1}, l_sMemberOf_EquipmentContainer))
                    l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
                    break;
                end
            end
            warning('GeneratingUnit for SynchronousMachine is missing; Placed it into EquipmentContainer! (RDF-ID: %s)', g_cBlocks{g_iIterator, 2});
        end
    else
        if(~exist('l_sMemberOf_EquipmentContainer', 'var'))
            warning('Could not create SynchronousMachine, because GeneratingUnit and EquipmentContainer are missing! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
            return;
        end
        for l_iI = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iI, 1}, l_sMemberOf_EquipmentContainer))
                l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
                break;
            end
        end
    end % End of if.
    if(~exist('l_sParent', 'var'))
        warning('Could not create SynchronousMachine, because GeneratingUnit and EquipmentContainer are missing! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
        return;
    end
    % The SynchronousMachine itself.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    % BaseVoltage.
    l_cPos = getPositionIndex(0);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    if(exist('l_sBaseVoltage', 'var'))
        for l_iJ = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iJ, 1}, l_sBaseVoltage))
                l_sBV = strcat(g_cBlocks{l_iJ, 3}, '/', g_cBlocks{l_iJ, 2});
                break;
            end
        end
        if(exist('l_sBV', 'var'))
            add_block(l_sBV, strcat(l_sParent, '/', l_sName, '/', g_cBlocks{l_iJ, 2}), 'Position', l_aPosition);
        else
            add_block('fl_lib/Electrical/Electrical Sources/AC Voltage Source', strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'Position', l_aPosition);
            set_param(strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'amp', '0');
            warning('Could not find BaseVoltage, belonging to RDF-Resource, for SynchronousMachine and created AC with 0V! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        end
    else
        add_block('fl_lib/Electrical/Electrical Sources/AC Voltage Source', strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'Position', l_aPosition);
        set_param(strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'amp', '0');
        warning('BaseVoltage for SynchronousMachine is missing; Created AC with 0V! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of if.
    % RegulatingControl.
    l_cPos = getPositionIndex(1);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    if(exist('l_sRegulatingControl', 'var'))
        for l_iJ = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iJ, 1}, l_sRegulatingControl))
                l_sRC = strcat(g_cBlocks{l_iJ, 3}, '/', g_cBlocks{l_iJ, 2});
                break;
            end
        end
        if(exist('l_sRC', 'var'))
            add_block(l_sRC, strcat(l_sParent, '/', l_sName, '/', g_cBlocks{l_iJ, 2}), 'Position', l_aPosition);
        else
            add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName, '/Regulating Control'), 'Position', l_aPosition);
            warning('Could not find RegulatingControl, belonging to RDF-Resource, for SynchronousMachine and created empty Subsystem! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        end
    else
        add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName, '/Regulating Control'), 'Position', l_aPosition);
        warning('RegulatingControl for SynchronousMachine is missing; Created empty Subsystem! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of if.
    % Base reactive power.
    l_cPos = getPositionIndex(2);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/Reactive Power'), 'Position', l_aPosition);
    if(exist('l_sBaseQ', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/Reactive Power'), 'Value', l_sBaseQ);
    end
    % Minimum reactive power.
    if(exist('l_sMinQ', 'var'))
       if(str2double(get_param(strcat(l_sParent, '/', l_sName, '/Reactive Power'), 'Value')) < str2double(l_sMinQ))
           set_param(strcat(l_sParent, '/', l_sName, '/Reactive Power'), 'Value', l_sMinQ, 'OutMin', l_sMinQ);
           warning('Base reactive power for SynchronousMachine is lower than minimal reactive power; It is set to %s! (RDF-ID: %s)', l_sMinQ, g_cObjects{g_iIterator,2});
       else
           set_param(strcat(l_sParent, '/', l_sName, '/Reactive Power'), 'OutMin', l_sMinQ);
       end
    end
    % Maximum reactive power.
    if(exist('l_sMaxQ', 'var'))
       if(str2double(get_param(strcat(l_sParent, '/', l_sName, '/Reactive Power'), 'Value')) > str2double(l_sMaxQ))
           set_param(strcat(l_sParent, '/', l_sName, '/Reactive Power'), 'Value', l_sMaxQ, 'OutMax', l_sMaxQ);
           warning('Base reactive power for SynchronousMachine is higher than maximal reactive power; It is set to %s! (RDF-ID: %s)', l_sMaxQ, g_cObjects{g_iIterator,2});
       else
           set_param(strcat(l_sParent, '/', l_sName, '/Reactive Power'), 'OutMax', l_sMaxQ);
       end
    end
    % Q percent.
    l_cPos = getPositionIndex(3);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/qPercent'), 'Position', l_aPosition);
    if(exist('l_sQPercent', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/qPercent'), 'Value', l_sQPercent);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/qPercent'), 'Value', '0');
        warning('qPercent for SynchronousMachine is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end
    % Power rating.
    l_cPos = getPositionIndex(4);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/ratedS'), 'Position', l_aPosition);
    if(exist('l_sRatedS', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/ratedS'), 'Value', l_sRatedS);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/ratedS'), 'Value', '0');
        warning('ratedS for SynchronousMachine is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Initial reactive capability curve.
    l_cPos = getPositionIndex(5);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    if(exist('l_sInitialReactiveCapabilityCurve', 'var'))
        for l_iJ = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iJ, 1}, l_sInitialReactiveCapabilityCurve))
                l_sIRCC = strcat(g_cBlocks{l_iJ, 3}, '/', g_cBlocks{l_iJ, 2});
                break;
            end
        end
        if(exist('l_sIRCC', 'var'))
            add_block(l_sIRCC, strcat(l_sParent, '/', l_sName, '/', g_cBlocks{l_iJ, 2}), 'Position', l_aPosition);
        else
            add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName, '/Reactive Capability Curve'), 'Position', l_aPosition);
            warning('Could not find InitialReactiveCapabilityCurve, belonging to RDF-Resource, for SynchronousMachine and created empty Subsystem! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        end
    else
        add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName, '/Reactive Capability Curve'), 'Position', l_aPosition);
        warning('InitialReactiveCapabilityCurve for SynchronousMachine is missing; Created empty Subsystem! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of if.
    % Positive resistance.
    l_cPos = getPositionIndex(6);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/r'), 'Position', l_aPosition);
    if(exist('l_sR', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/r'), 'Value', l_sR);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/r'), 'Value', '0');
        warning('Positive resistance for SynchronousMachine is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Zero resistance.
    l_cPos = getPositionIndex(7);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/r0'), 'Position', l_aPosition);
    if(exist('l_sR0', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/r0'), 'Value', l_sR0);
    end
    % Negative resistance.
    l_cPos = getPositionIndex(8);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/r2'), 'Position', l_aPosition);
    if(exist('l_sR2', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/r2'), 'Value', l_sR2);
    end
    % Positive reactance.
    l_cPos = getPositionIndex(9);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/x'), 'Position', l_aPosition);
    if(exist('l_sX', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/x'), 'Value', l_sX);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/x'), 'Value', '0');
        warning('Positive reactance for SynchronousMachine is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Zero reactance.
    l_cPos = getPositionIndex(10);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/x0'), 'Position', l_aPosition);
    if(exist('l_sX0', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/x0'), 'Value', l_sX0);
    end
    % Negative reactance.
    l_cPos = getPositionIndex(11);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/x2'), 'Position', l_aPosition);
    if(exist('l_sX2', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/x2'), 'Value', l_sX2);
    end
    % Reference Priority.
    l_cPos = getPositionIndex(12);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/referencePriority'), 'Position', l_aPosition);
    if(exist('l_sReferencePriority', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/referencePriority'), 'Value', l_sReferencePriority);
    end
    % Synchronous machine type.
    l_cPos = getPositionIndex(13);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/type'), 'Position', l_aPosition);
    if(exist('l_sType', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/type'), 'OutDataTypeStr', 'Enum: SynchronousMachineType', 'Value', l_sType);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/type'), 'OutDataTypeStr', 'Enum: SynchronousMachineType', 'Value', 'SynchronousMachineType.generator_or_condenser');
        warning('Type for SynchronousMachine is missing; It is set to ''generator_or_condenser''! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Synchronous machine operating mode.
    l_cPos = getPositionIndex(14);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/operatingMode'), 'Position', l_aPosition);
    if(exist('l_sType', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/operatingMode'), 'OutDataTypeStr', 'Enum: SynchronousMachineOperatingMode', 'Value', l_sOperatingMode);
    else
        if(strcmp(get_param(strcat(l_sParent, '/', l_sName, 'type'), 'Value'), 'generator'))
            set_param(strcat(l_sParent, '/', l_sName, '/operatingMode'), 'OutDataTypeStr', 'Enum: SynchronousMachineOperatingMode', 'Value', 'SynchronousMachineOperatingMode.generator');
            warning('Operating mode for SynchronousMachine is missing; It is set to ''generator''! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
        else
            set_param(strcat(l_sParent, '/', l_sName, '/operatingMode'), 'OutDataTypeStr', 'Enum: SynchronousMachineOperatingMode', 'Value', 'SynchronousMachineOperatingMode.condenser');
            warning('Operating mode for SynchronousMachine is missing; It is set to ''condenser''! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
        end
    end
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 15});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createSynchronousMachine'.

function createTerminal()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Terminal.connected');
        if(size(l_cFind) > 0)
            if(strcmpi(l_cAttributes{l_iI}(l_cFind(1) + 23:l_cFind(2) - 3), 'true'))
                l_bConnected = true;
            else
                l_bConnected = false;
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Terminal.sequenceNumber');
        if(size(l_cFind) > 0)
            l_sSequenceNumber = l_cAttributes{l_iI}(l_cFind(1) + 28:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Terminal.ConductingEquipment');
        if(size(l_cFind) > 0)
            l_sConductingEquipment = l_cAttributes{l_iI}(l_cFind(1) + 48:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Terminal.TopologicalNode');
        if(size(l_cFind) > 0)
            l_sTopologicalNode = l_cAttributes{l_iI}(l_cFind(1) + 44:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Terminal.ConnectivityNode');
        if(size(l_cFind) > 0)
            l_sConnectivityNode = l_cAttributes{l_iI}(l_cFind(1) + 45:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for Terminal! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this Terminal.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('Terminal', g_iIterator);
    end
    % ConductingEquipment, which contains the Terminal.
    if(~exist('l_sConductingEquipment', 'var'))
        warning('Could not create Terminal, because ConductingEquipment is missing! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    for l_iI = 1:size(g_cBlocks)
        if(strcmp(g_cBlocks{l_iI, 1}, l_sConductingEquipment))
            l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
            break;
        end
    end
    if(~exist('l_sParent', 'var'))
        warning('Could not create Terminal, because could not find ConductingEquipment, belonging to RDF-Resource! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    % The Terminal itself.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    % Sequence number.
    l_cPos = getPositionIndex(0);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/sequenceNumber'), 'Position', l_aPosition);
    if(exist('l_sSequenceNumber', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/sequenceNumber'), 'Value', l_sSequenceNumber);
    end
    % Topolocigal node.
    if(exist('l_sTopologicalNode', 'var'))
        for l_iI = 1:size(g_cBlocks)
            if(strcmp(l_sTopologicalNode, g_cBlocks{l_iI, 1}))
                l_sNode = strcat(g_cBlocks{l_iI, 3}, g_cBlocks{l_iI, 2});
                break;
            end
        end
    end
    % Connectivity node.
    if(exist('l_sConnectivityNode', 'var'))
        for l_iI = 1:size(g_cBlocks)
            if(strcmp(l_sConnectivityNode, g_cBlocks{l_iI, 1}))
                l_sNode = strcat(g_cBlocks{l_iI, 3}, g_cBlocks{l_iI, 2});
                break;
            end
        end
    end
    % Connected.
    if(exist('l_bConnected', 'var') && l_bConnected)
       if(exist('l_sNode', 'var'))
           % TODO: Connect.
       else
           warning('Terminal is connected, but has no node; Could not connect! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
       end
    end
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 1});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createTerminal'.

function createThermalGeneratingUnit()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        % Currently not used!
        %l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Equipment.equivalent');
        %if(size(l_cFind) > 0)
        %    if(strcmpi(l_cAttributes{l_iI}(l_cFind(1) + 25:l_cFind(2) - 3), 'true'))
        %        l_bEquivalent = true;
        %    else
        %        l_bEquivalent = false;
        %    end
        %    continue;
        %end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Equipment.MemberOf_EquipmentContainer');
        if(size(l_cFind) > 0)
            l_sMemberOf_EquipmentContainer = l_cAttributes{l_iI}(l_cFind(1) + 57:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.governorSCD');
        if(size(l_cFind) > 0)
            l_sGovernorSCD = l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.maximumAllowableSpinningReserve');
        if(size(l_cFind) > 0)
            l_sMaximumAllowableSpinningReserve = l_cAttributes{l_iI}(l_cFind(1) + 51:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.maxOperatingP');
        if(size(l_cFind) > 0)
            l_sMaxOperatingP = l_cAttributes{l_iI}(l_cFind(1) + 33:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.minOperatingP');
        if(size(l_cFind) > 0)
            l_sMinOperatingP = l_cAttributes{l_iI}(l_cFind(1) + 33:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.initialP');
        if(size(l_cFind) > 0)
            l_sInitialP = l_cAttributes{l_iI}(l_cFind(1) + 28:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.nominalP');
        if(size(l_cFind) > 0)
            l_sNominalP = l_cAttributes{l_iI}(l_cFind(1) + 28:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.normalPF');
        if(size(l_cFind) > 0)
            l_sNormalPF = l_cAttributes{l_iI}(l_cFind(1) + 28:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.genControlSource');
        if(size(l_cFind) > 0)
            l_cFind = strfind(l_cAttributes{l_iI}, '#');
            l_sGenControlSource = l_cAttributes{l_iI}(l_cFind(1) + 1:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.startupCost');
        if(size(l_cFind) > 0)
            l_sStartupCost = l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:GeneratingUnit.variableCost');
        if(size(l_cFind) > 0)
            l_sVariableCost = l_cAttributes{l_iI}(l_cFind(1) + 32:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:ThermalGeneratingUnit.FossilFuels');
        if(size(l_cFind) > 0)
            l_sFossilFuels = l_cAttributes{l_iI}(l_cFind(1) + 53:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for ThermalGeneratingUnit! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this ThermalGeneratingUnit.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('ThermalGeneratingUnit', g_iIterator);
    end
    % The EquipmentContainer, the ThermalGeneratingUnit is member of.
    if(~exist('l_sMemberOf_EquipmentContainer', 'var'))
        warning('Could not create ThermalGeneratingUnit, because EquipmentContainer is missing! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    for l_iI = 1:size(g_cBlocks)
        if(strcmp(g_cBlocks{l_iI, 1}, l_sMemberOf_EquipmentContainer))
            l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
            break;
        end
    end
    if(~exist('l_sParent', 'var'))
        warning('Could not create ThermalGeneratingUnit, because could not find EquipmentContainer, belonging to RDF-Resource! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    % The ThermalGeneratingUnit itself.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    % Initial operating power.
    l_cPos = getPositionIndex(0);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Position', l_aPosition);
    if(exist('l_sInitialP', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value', l_sInitialP);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value', '0');
        warning('Initial operating power for ThermalGeneratingUnit is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end
    % Minimum operating power.
    if(exist('l_sMinOperatingP', 'var'))
       if(str2double(get_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value')) < str2double(l_sMinOperatingP))
           set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value', l_sMinOperatingP, 'OutMin', l_sMinOperatingP);
           warning('Initial operating power for ThermalGeneratingUnit is lower than minimal operating power; It is set to %s! (RDF-ID: %s)', l_sMinOperatingP, g_cObjects{g_iIterator,2});
       else
           set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'OutMin', l_sMinOperatingP);
       end
    else
       warning('Minimal operating power for ThermalGeneratingUnit is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
       if(str2double(get_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value')) < 0)
           set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value', '0', 'OutMin', '0');
           warning('Initial operating power for ThermalGeneratingUnit is lower than minimal operating power; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
       else
           set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'OutMin', '0');
       end
    end
    % Maximum operating power.
    if(exist('l_sMaxOperatingP', 'var'))
       if(str2double(get_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value')) > str2double(l_sMaxOperatingP))
           set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value', l_sMaxOperatingP, 'OutMax', l_sMaxOperatingP);
           warning('Initial operating power for ThermalGeneratingUnit is higher than maximal operating power; It is set to %s! (RDF-ID: %s)', l_sMaxOperatingP, g_cObjects{g_iIterator,2});
       else
           set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'OutMax', l_sMaxOperatingP);
       end
    else
       warning('Maximal operating power for ThermalGeneratingUnit is missing; It is set to 1! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
       if(str2double(get_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value')) > 1)
           set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'Value', '0', 'OutMax', '1');
           warning('Initial operating power for ThermalGeneratingUnit is higher than maximal operating power; It is set to 1! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
       else
           set_param(strcat(l_sParent, '/', l_sName, '/Operating Power'), 'OutMax', '1');
       end
    end
    % Nominal Power.
    l_cPos = getPositionIndex(1);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/Nominal Power'), 'Position', l_aPosition);
    if(exist('l_sNominalP', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/Nominal Power'), 'Value', l_sNominalP);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/Nominal Power'), 'Value', '0');
        warning('Nominal power for ThermalGeneratingUnit is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end
    % Governor SCD.
    l_cPos = getPositionIndex(2);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/governorSCD'), 'Position', l_aPosition);
    if(exist('l_sGovernorSCD', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/governorSCD'), 'Value', l_sGovernorSCD);
    end
    % Maximum allowable spinning reserve.
    l_cPos = getPositionIndex(3);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/Spinning Reserve'), 'Position', l_aPosition);
    if(exist('l_sMaximumAllowableSpinningReserve', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/Spinning Reserve'), 'OutMax', l_sMaximumAllowableSpinningReserve);
    end
    % Normal participation factor.
    l_cPos = getPositionIndex(4);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/normalPF'), 'Position', l_aPosition);
    if(exist('l_sNormalPF', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/normalPF'), 'Value', l_sNormalPF);
    end
    % Generator control source.
    l_cPos = getPositionIndex(5);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/genControlSource'), 'Position', l_aPosition);
    if(exist('l_sGenControlSource', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/genControlSource'), 'OutDataTypeStr', 'Enum: GeneratorControlSource', 'Value', l_sGenControlSource);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/genControlSource'), 'OutDataTypeStr', 'Enum: GeneratorControlSource', 'Value', 'GeneratorControlSource.unavailable');
    end
    % Startup cost.
    l_cPos = getPositionIndex(6);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/startupCost'), 'Position', l_aPosition);
    if(exist('l_sStartupCost', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/startupCost'), 'Value', l_sStartupCost);
    end
    % Variable cost.
    l_cPos = getPositionIndex(7);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/variableCost'), 'Position', l_aPosition);
    if(exist('l_sVariableCost', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/variableCost'), 'Value', l_sVariableCost);
    end
    % Fossil fuels.
    l_cPos = getPositionIndex(8);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    if(exist('l_sFossilFuels', 'var'))
        for l_iJ = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iJ, 1}, l_sFossilFuels))
                l_sFF = strcat(g_cBlocks{l_iJ, 3}, '/', g_cBlocks{l_iJ, 2});
                break;
            end
        end
        if(exist('l_sFF', 'var'))
            add_block(l_sFF, strcat(l_sParent, '/', l_sName, '/', g_cBlocks{l_iJ, 2}), 'Position', l_aPosition);
        else
            add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/FossilFuels'), 'Position', l_aPosition);
            set_param(strcat(l_sParent, '/', l_sName, '/FossilFuels'), 'OutDataTypeStr', 'Enum: FuelType', 'Value', 'FuelType.coal');
            warning('Could not find FossilFuel, belonging to RDF-Resource, for ThermalGeneratingUnit and created one with FuelType coal! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        end
    else
        add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/FossilFuels'), 'Position', l_aPosition);
        set_param(strcat(l_sParent, '/', l_sName, '/FossilFuels'), 'OutDataTypeStr', 'Enum: FuelType', 'Value', 'FuelType.coal');
        warning('FossilFuel for ThermalGeneratingUnit is missing; Created one with FuelType coal! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of if.
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 9});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createThermalGeneratingUnit'.

function createTransformerWinding()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        % Currently not used!
        %l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Equipment.equivalent');
        %if(size(l_cFind) > 0)
        %    if(strcmpi(l_cAttributes{l_iI}(l_cFind(1) + 25:l_cFind(2) - 3), 'true'))
        %        l_bEquivalent = true;
        %    else
        %        l_bEquivalent = false;
        %    end
        %    continue;
        %end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:Equipment.MemberOf_EquipmentContainer');
        if(size(l_cFind) > 0)
            l_sMemberOf_EquipmentContainer = l_cAttributes{l_iI}(l_cFind(1) + 57:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:ConductingEquipment.BaseVoltage');
        if(size(l_cFind) > 0)
            l_sBaseVoltage = l_cAttributes{l_iI}(l_cFind(1) + 51:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.rground');
        if(size(l_cFind) > 0)
            l_sRground = l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.xground');
        if(size(l_cFind) > 0)
            l_sXground = l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.connectionType');
        if(size(l_cFind) > 0)
            l_cFind = strfind(l_cAttributes{l_iI}, '#');
            l_sConnectionType = l_cAttributes{l_iI}(l_cFind(1) + 1:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.windingType');
        if(size(l_cFind) > 0)
            l_cFind = strfind(l_cAttributes{l_iI}, '#');
            l_sWindingType = l_cAttributes{l_iI}(l_cFind(1) + 1:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.ratedS');
        if(size(l_cFind) > 0)
            l_sRatedS = l_cAttributes{l_iI}(l_cFind(1) + 30:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.ratedU');
        if(size(l_cFind) > 0)
            l_sRatedU = l_cAttributes{l_iI}(l_cFind(1) + 30:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.r0');
        if(size(l_cFind) > 0)
            l_sR0 = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.r');
        if(size(l_cFind) > 0)
            l_sR = l_cAttributes{l_iI}(l_cFind(1) + 25:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.x0');
        if(size(l_cFind) > 0)
            l_sX0 = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.x');
        if(size(l_cFind) > 0)
            l_sX = l_cAttributes{l_iI}(l_cFind(1) + 25:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.b0');
        if(size(l_cFind) > 0)
            l_sB0 = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.b');
        if(size(l_cFind) > 0)
            l_sB = l_cAttributes{l_iI}(l_cFind(1) + 25:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.g0');
        if(size(l_cFind) > 0)
            l_sG0 = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.g');
        if(size(l_cFind) > 0)
            l_sG = l_cAttributes{l_iI}(l_cFind(1) + 25:l_cFind(2) - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:TransformerWinding.MemberOf_PowerTransformer');
        if(size(l_cFind) > 0)
            l_sMemberOf_PowerTransformer = l_cAttributes{l_iI}(l_cFind(1) + 64:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for TransformerWinding! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this TransformerWinding.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('TransformerWinding', g_iIterator);
    end
    % The parent (PowerTransformer or EquipmentContainer), the TransformerWinding is member of.
    if(exist('l_sMemberOf_PowerTransformer', 'var'))
        for l_iI = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iI, 1}, l_sMemberOf_PowerTransformer))
                l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
                break;
            end
        end
        if(~exist('l_sParent', 'var'))
            if(~exist('l_sMemberOf_EquipmentContainer', 'var'))
                warning('Could not create TransformerWinding, because PowerTransformer and EquipmentContainer are missing! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
                return;
            end
            for l_iI = 1:size(g_cBlocks)
                if(strcmp(g_cBlocks{l_iI, 1}, l_sMemberOf_EquipmentContainer))
                    l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
                    break;
                end
            end
            warning('PowerTransformer for TransformerWinding is missing; Placed it into EquipmentContainer! (RDF-ID: %s)', g_cBlocks{g_iIterator, 2});
        end
    else
        if(~exist('l_sMemberOf_EquipmentContainer', 'var'))
            warning('Could not create TransformerWinding, because PowerTransformer and EquipmentContainer are missing! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
            return;
        end
        for l_iI = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iI, 1}, l_sMemberOf_EquipmentContainer))
                l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
                break;
            end
        end
    end % End of if.
    if(~exist('l_sParent', 'var'))
        warning('Could not create TransformerWinding, because PowerTransformer and EquipmentContainer are missing! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
        return;
    end
    % The TransformerWinding itself.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    % BaseVoltage.
    l_cPos = getPositionIndex(0);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    if(exist('l_sBaseVoltage', 'var'))
        for l_iJ = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iJ, 1}, l_sBaseVoltage))
                l_sBV = strcat(g_cBlocks{l_iJ, 3}, '/', g_cBlocks{l_iJ, 2});
                break;
            end
        end
        if(exist('l_sBV', 'var'))
            add_block(l_sBV, strcat(l_sParent, '/', l_sName, '/', g_cBlocks{l_iJ, 2}), 'Position', l_aPosition);
        else
            add_block('fl_lib/Electrical/Electrical Sources/AC Voltage Source', strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'Position', l_aPosition);
            set_param(strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'amp', '0');
            warning('Could not find BaseVoltage, belonging to RDF-Resource, for TransformerWinding and created AC with 0V! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        end
    else
        add_block('fl_lib/Electrical/Electrical Sources/AC Voltage Source', strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'Position', l_aPosition);
        set_param(strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'amp', '0');
        warning('BaseVoltage for TransformerWinding is missing; Created AC with 0V! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of if.
    % R ground.
    l_cPos = getPositionIndex(1);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/rground'), 'Position', l_aPosition);
    if(exist('l_sRground', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/rground'), 'Value', l_sRground);
    end
    % X ground.
    l_cPos = getPositionIndex(2);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/xground'), 'Position', l_aPosition);
    if(exist('l_sXground', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/xground'), 'Value', l_sXground);
    end
    % Power rating.
    l_cPos = getPositionIndex(3);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/ratedS'), 'Position', l_aPosition);
    if(exist('l_sRatedS', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/ratedS'), 'Value', l_sRatedS);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/ratedS'), 'Value', '0');
        warning('ratedS for TransformerWinding is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Voltage rating.
    l_cPos = getPositionIndex(4);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/ratedU'), 'Position', l_aPosition);
    if(exist('l_sRatedU', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/ratedU'), 'Value', l_sRatedU);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/ratedU'), 'Value', '0');
        warning('ratedS for TransformerWinding is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Positive resistance.
    l_cPos = getPositionIndex(5);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/r'), 'Position', l_aPosition);
    if(exist('l_sR', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/r'), 'Value', l_sR);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/r'), 'Value', '0');
        warning('Positive resistance for TransformerWinding is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Zero resistance.
    l_cPos = getPositionIndex(6);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/r0'), 'Position', l_aPosition);
    if(exist('l_sR0', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/r0'), 'Value', l_sR0);
    end
    % Positive reactance.
    l_cPos = getPositionIndex(7);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/x'), 'Position', l_aPosition);
    if(exist('l_sX', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/x'), 'Value', l_sX);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/x'), 'Value', '0');
        warning('Positive reactance for TransformerWinding is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Zero reactance.
    l_cPos = getPositionIndex(8);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/x0'), 'Position', l_aPosition);
    if(exist('l_sX0', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/x0'), 'Value', l_sX0);
    end
    % Positive susceptance.
    l_cPos = getPositionIndex(9);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/b'), 'Position', l_aPosition);
    if(exist('l_sB', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/b'), 'Value', l_sB);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/b'), 'Value', '0');
        warning('Positive susceptance for TransformerWinding is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Zero susceptance.
    l_cPos = getPositionIndex(10);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/b0'), 'Position', l_aPosition);
    if(exist('l_sB0', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/b0'), 'Value', l_sB0);
    end
    % Positive conductance.
    l_cPos = getPositionIndex(11);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/g'), 'Position', l_aPosition);
    if(exist('l_sG', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/g'), 'Value', l_sG);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/g'), 'Value', '0');
        warning('Positive conductance for TransformerWinding is missing; It is set to 0! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Zero conductance.
    l_cPos = getPositionIndex(12);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Constant', strcat(l_sParent, '/', l_sName, '/g0'), 'Position', l_aPosition);
    if(exist('l_sG0', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/g0'), 'Value', l_sG0);
    end
    % Winding type.
    l_cPos = getPositionIndex(13);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/windingType'), 'Position', l_aPosition);
    if(exist('l_sWindingType', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/windingType'), 'OutDataTypeStr', 'Enum: WindingType', 'Value', l_sWindingType);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/windingType'), 'OutDataTypeStr', 'Enum: WindingType', 'Value', 'WindingType.primary');
        warning('Winding type for TransformerWinding is missing; It is set to ''primary''! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    % Winding type.
    l_cPos = getPositionIndex(14);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('simulink/Sources/Enumerated Constant', strcat(l_sParent, '/', l_sName, '/connectionType'), 'Position', l_aPosition);
    if(exist('l_sConnectionType', 'var'))
        set_param(strcat(l_sParent, '/', l_sName, '/connectionType'), 'OutDataTypeStr', 'Enum: WindingConnection', 'Value', l_sConnectionType);
    else
        set_param(strcat(l_sParent, '/', l_sName, '/connectionType'), 'OutDataTypeStr', 'Enum: WindingConnection', 'Value', 'WindingConnection.D');
        warning('Connection type for TransformerWinding is missing; It is set to ''D''! (RDF-ID: %s)', g_cObjects{g_iIterator, 2});
    end
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 15});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createTransformerWinding'.

function createVoltageLevel()

    % Use global variables.
    global g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;
    
    % Parse attributes.
    l_sAttributes = g_cObjects{g_iIterator, 3};
    l_cAttributes = cell(0);
    
    l_cFind = strfind(l_sAttributes, '>');
    while(size(l_cFind) > 0)
        if(strcmp(l_sAttributes(l_cFind(1, 1) - 1), '/'))
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 1)));
            l_sAttributes = l_sAttributes(l_cFind(1, 1) + 1:end);
        else
            l_cAttributes = cat(1, l_cAttributes, l_sAttributes(1:l_cFind(1, 2)));
            l_sAttributes = l_sAttributes(l_cFind(1, 2) + 1:end);
        end
        l_cFind = strfind(l_sAttributes, '>');
    end
    
    % Identify attributes.
    for l_iI = 1:size(l_cAttributes)
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.aliasName');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_sName, ' (', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            else
                l_sName = strcat('(', l_cAttributes{l_iI}(l_cFind(1) + 31:l_cFind(2) - 3), ')');
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:IdentifiedObject.name');
        if(size(l_cFind) > 0)
            if(exist('l_sName', 'var'))
                l_sName = strcat(l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3), ' ', l_sName);
            else
                l_sName = l_cAttributes{l_iI}(l_cFind(1) + 26:l_cFind(2) - 3);
            end
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:VoltageLevel.MemberOf_Substation');
        if(size(l_cFind) > 0)
            l_sSubstation = l_cAttributes{l_iI}(l_cFind(1) + 52:end - 3);
            continue;
        end
        l_cFind = strfind(l_cAttributes{l_iI}, 'cim:VoltageLevel.BaseVoltage');
        if(size(l_cFind) > 0)
            l_sBaseVoltage = l_cAttributes{l_iI}(l_cFind(1) + 44:end - 3);
            continue;
        end
        % Could not identify the attribute.
        warning('Could not identify attribute for VoltageLevel! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of for.
    
    % Create this VoltageLevel.
    
    % The name of the block in following format: IdentifiedObject.name
    % (IdentifiedObject.aliasName). If both variables don't exist, it is
    % the name of the class, followed by the value of 'g_iIterator'.
    if(~exist('l_sName', 'var'))
        l_sName = strcat('VoltageLevel', g_iIterator);
    end
    % EquipmentContainer, which contains the VoltageLevel.
    if(~exist('l_sSubstation', 'var'))
        warning('Could not create VoltageLevel, because Substation is missing! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    for l_iI = 1:size(g_cBlocks)
        if(strcmp(g_cBlocks{l_iI, 1}, l_sSubstation))
            l_sParent = strcat(g_cBlocks{l_iI, 3}, '/', g_cBlocks{l_iI, 2});
            break;
        end
    end
    if(~exist('l_sParent', 'var'))
        warning('Could not create VoltageLevel, because could not find Substation, belonging to RDF-Resource! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        return;
    end
    % The VoltageLevel itself.
    l_cPos = getPositionIndex(g_cBlocks{l_iI, 4});
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    add_block('built-in/Subsystem', strcat(l_sParent, '/', l_sName), 'Position', l_aPosition);
    % BaseVoltage.
    l_cPos = getPositionIndex(0);
    l_iLeft = l_cPos{1, 1} * (g_iOffset + g_iWidth) + g_iOffset;
    l_iTop = l_cPos{1, 2} * (g_iOffset + g_iHeight) + g_iOffset;
    l_aPosition = [l_iLeft, l_iTop, l_iLeft + g_iWidth, l_iTop + g_iHeight];
    if(exist('l_sBaseVoltage', 'var'))
        for l_iJ = 1:size(g_cBlocks)
            if(strcmp(g_cBlocks{l_iJ, 1}, l_sBaseVoltage))
                l_sBV = strcat(g_cBlocks{l_iJ, 3}, '/', g_cBlocks{l_iJ, 2});
                break;
            end
        end
        if(exist('l_sBV', 'var'))
            add_block(l_sBV, strcat(l_sParent, '/', l_sName, '/', g_cBlocks{l_iJ, 2}), 'Position', l_aPosition);
        else
            add_block('fl_lib/Electrical/Electrical Sources/AC Voltage Source', strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'Position', l_aPosition);
            set_param(strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'amp', '0');
            warning('Could not find BaseVoltage, belonging to RDF-Resource, for VoltageLevel and created AC with 0V! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
        end
    else
        add_block('fl_lib/Electrical/Electrical Sources/AC Voltage Source', strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'Position', l_aPosition);
        set_param(strcat(l_sParent, '/', l_sName, '/BaseVoltage'), 'amp', '0');
        warning('BaseVoltage for VoltageLevel is missing; Created AC with 0V! (RDF-ID: %s)', g_cObjects{g_iIterator,2});
    end % End of if.
    
    % Clean up everything, that is not needed anymore.
    g_cBlocks{l_iI, 4} = g_cBlocks{l_iI, 4} + 1;
    g_cBlocks = cat(1, g_cBlocks, {g_cObjects{g_iIterator, 2}, l_sName, l_sParent, 1});
    clearvars -except g_iIterator g_iHeight g_iWidth g_iOffset g_cObjects g_cBlocks;

end % End of function 'createVoltageLevel'.

% End of script.
