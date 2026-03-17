--[[
  TodoWidget Engine
  Supports: sections (dated labels), tasks with descriptions, subitems

  Data format (data.txt):
    Lines starting with "##" are section headers:  ##Section Label
    Task lines:  name|checked|description
    Subitem lines (indented with >):  >name|checked|parent_index
]]

DIVIDER = '|'

function Initialize()
    sDataFile = SELF:GetOption('DataFile')
    sTrashFile = SELF:GetOption('TrashFile')
    sDynamicFile = SELF:GetOption('DynamicMeterFile')

    FONT_FACE = SELF:GetOption('FONT_FACE', 'Segoe UI')
    FONT_SIZE = SELF:GetNumberOption('FONT_SIZE', 13)
    DESC_FONT_SIZE = SELF:GetNumberOption('DESC_FONT_SIZE', 10)
    SUB_FONT_SIZE = SELF:GetNumberOption('SUB_FONT_SIZE', 11)
    SECTION_FONT_SIZE = SELF:GetNumberOption('SECTION_FONT_SIZE', 16)

    ACTIVE_COLOR = SELF:GetOption('ACTIVE_COLOR', '220,225,230,255')
    COMPLETED_COLOR = SELF:GetOption('COMPLETED_COLOR', '140,145,155,120')
    DESC_COLOR = SELF:GetOption('DESC_COLOR', '160,165,175,200')
    SECTION_COLOR = SELF:GetOption('SECTION_COLOR', '130,180,255,255')
    BUTTON_COLOR = SELF:GetOption('BUTTON_COLOR', '180,185,195,220')
    BUTTON_SIZE = SELF:GetNumberOption('BUTTON_SIZE', 14)
    SUB_INDENT = SELF:GetNumberOption('SUB_INDENT', 30)

    SKIN_WIDTH = SKIN:GetW()
end

-- Parse the data file into a structured list
function ParseData()
    local items = {}
    local hFile = io.open(sDataFile, 'r')
    if not hFile then return items end

    for line in hFile:lines() do
        line = Trim(line)
        if line ~= '' then
            if line:sub(1, 2) == '##' then
                -- Section header
                items[#items + 1] = {
                    type = 'section',
                    label = line:sub(3),
                    raw = line
                }
            elseif line:sub(1, 1) == '>' then
                -- Subitem
                local parts = SplitText(line:sub(2))
                items[#items + 1] = {
                    type = 'subitem',
                    name = parts[1] or '',
                    checked = parts[2] or '',
                    description = parts[3] or '',
                    raw = line
                }
            else
                -- Task
                local parts = SplitText(line)
                items[#items + 1] = {
                    type = 'task',
                    name = parts[1] or '',
                    checked = parts[2] or '',
                    description = parts[3] or '',
                    raw = line
                }
            end
        end
    end

    hFile:close()
    return items
end

-- Write items back to data file
function WriteData(items)
    local hFile = io.open(sDataFile, 'w')
    if not hFile then return false end

    for i = 1, #items do
        local item = items[i]
        if item.type == 'section' then
            hFile:write('##' .. item.label .. '\n')
        elseif item.type == 'subitem' then
            hFile:write('>' .. item.name .. DIVIDER .. item.checked .. DIVIDER .. item.description .. '\n')
        else
            hFile:write(item.name .. DIVIDER .. item.checked .. DIVIDER .. item.description .. '\n')
        end
    end

    hFile:close()
    return true
end

function Update()
    local items = ParseData()
    local out = {}
    local meterIndex = 0

    -- Variables section
    out[#out + 1] = '[Variables]'
    out[#out + 1] = '@Include=#@#Icons.inc'

    -- Build meters for each item
    for i = 1, #items do
        local item = items[i]
        meterIndex = meterIndex + 1

        if item.type == 'section' then
            BuildSectionMeter(out, i, meterIndex, item, items)
        elseif item.type == 'task' then
            BuildTaskMeter(out, i, meterIndex, item)
        elseif item.type == 'subitem' then
            BuildSubitemMeter(out, i, meterIndex, item)
        end
    end

    -- Bottom toolbar
    BuildToolbar(out, meterIndex)

    -- Write dynamic file
    local hFile = io.open(sDynamicFile, 'w')
    if not hFile then return false end
    hFile:write(table.concat(out, '\n'))
    hFile:close()

    return true
end

function BuildSectionMeter(out, dataIndex, meterIndex, item, items)
    local isFirst = (meterIndex == 1)

    -- Section label
    out[#out + 1] = '[MeterSection' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. item.label
    out[#out + 1] = 'FontFace=' .. FONT_FACE
    out[#out + 1] = 'FontSize=' .. SECTION_FONT_SIZE
    out[#out + 1] = 'FontColor=' .. SECTION_COLOR
    out[#out + 1] = 'FontWeight=700'
    out[#out + 1] = 'StringStyle=Bold'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'ClipString=1'
    out[#out + 1] = 'X=15'
    if isFirst then
        out[#out + 1] = 'Y=12'
    else
        out[#out + 1] = 'Y=18R'
    end
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - 80)
    out[#out + 1] = 'H=30'
    local sectionLineMeter = 'MeterSectionLine' .. dataIndex
    local sectionMeter = 'MeterSection' .. dataIndex

    -- Find the last item in this section to position the "add task" input there
    local lastInSection = dataIndex
    for j = dataIndex + 1, #items do
        if items[j].type == 'section' then break end
        lastInSection = j
    end
    local addTaskAnchor
    if lastInSection == dataIndex then
        -- Empty section, position below the divider line
        addTaskAnchor = sectionLineMeter
    elseif items[lastInSection].type == 'subitem' then
        if items[lastInSection].description ~= '' then
            addTaskAnchor = 'MeterSubDescEdit' .. lastInSection
        else
            addTaskAnchor = 'MeterSubDesc' .. lastInSection
        end
    else
        if items[lastInSection].description ~= '' then
            addTaskAnchor = 'MeterDescEdit' .. lastInSection
        else
            addTaskAnchor = 'MeterDesc' .. lastInSection
        end
    end

    out[#out + 1] = 'LeftMouseDoubleClickAction=' .. PosAt(sectionMeter) .. '[!SetVariable EditIndex "' .. dataIndex .. '"][!SetVariable EditDefault "' .. EscapeQuotes(item.label) .. '"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 3-4"]'

    -- Add task to this section (+)
    out[#out + 1] = '[MeterSectionAdd' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-add#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. SECTION_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 75)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'ToolTipText=Add task to this section'
    out[#out + 1] = 'LeftMouseUpAction=' .. PosAt(addTaskAnchor, 40) .. '[!SetVariable EditIndex "' .. dataIndex .. '"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 5-6"]'

    -- Section edit icon
    out[#out + 1] = '[MeterSectionEdit' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-edit#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=4R'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'LeftMouseUpAction=' .. PosAt(sectionMeter) .. '[!SetVariable EditIndex "' .. dataIndex .. '"][!SetVariable EditDefault "' .. EscapeQuotes(item.label) .. '"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 3-4"]'

    -- Section delete icon
    out[#out + 1] = '[MeterSectionDel' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-delete#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=4R'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Divider line under section
    out[#out + 1] = '[MeterSectionLine' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=Image'
    out[#out + 1] = 'SolidColor=80,130,220,80'
    out[#out + 1] = 'X=15'
    out[#out + 1] = 'Y=2R'
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - 30)
    out[#out + 1] = 'H=1'
end

function BuildTaskMeter(out, dataIndex, meterIndex, item)
    local isChecked = (item.checked == 'x')
    local nameColor = isChecked and COMPLETED_COLOR or ACTIVE_COLOR
    local checkIcon = isChecked and '#icon-checked#' or '#icon-check#'

    -- Checkbox
    out[#out + 1] = '[MeterCheck' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. checkIcon
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. BUTTON_SIZE
    out[#out + 1] = 'FontColor=' .. nameColor
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=15'
    out[#out + 1] = 'Y=6R'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ToggleCheck(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Task name
    out[#out + 1] = '[MeterName' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. item.name
    out[#out + 1] = 'FontFace=' .. FONT_FACE
    out[#out + 1] = 'FontSize=' .. FONT_SIZE
    out[#out + 1] = 'FontColor=' .. nameColor
    out[#out + 1] = 'FontWeight=600'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'ClipString=1'
    out[#out + 1] = 'X=40'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - 120)
    out[#out + 1] = 'H=24'
    if isChecked then
        out[#out + 1] = 'StringEffect=Strikethrough'
    end

    -- Add subitem button - anchor to last description meter
    local descAnchor
    if item.description ~= '' then
        descAnchor = 'MeterDescEdit' .. dataIndex
    else
        descAnchor = 'MeterDesc' .. dataIndex
    end

    out[#out + 1] = '[MeterTaskAddSub' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-subitem#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 3)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 55)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'ToolTipText=Add subitem'
    out[#out + 1] = 'LeftMouseUpAction=' .. PosAt(descAnchor, 15 + SUB_INDENT) .. '[!SetVariable EditIndex "' .. dataIndex .. '"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 7-8"]'

    -- Delete button
    out[#out + 1] = '[MeterTaskDel' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-delete#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 30)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Description area
    local editDescMeter = (item.description ~= '') and ('MeterDesc' .. dataIndex .. '_1') or ('MeterDesc' .. dataIndex)
    local editAction = PosAt(editDescMeter, 40) .. '[!SetVariable EditIndex "' .. dataIndex .. '"][!SetVariable EditDefault "' .. EscapeQuotes(item.description) .. '"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 9-10"]'

    if item.description == '' then
        -- Empty: show placeholder
        out[#out + 1] = '[MeterDesc' .. dataIndex .. ']'
        out[#out + 1] = 'Meter=String'
        out[#out + 1] = 'Text=add note...'
        out[#out + 1] = 'FontFace=' .. FONT_FACE
        out[#out + 1] = 'FontSize=' .. DESC_FONT_SIZE
        out[#out + 1] = 'FontColor=100,105,115,100'
        out[#out + 1] = 'AntiAlias=1'
        out[#out + 1] = 'ClipString=1'
        out[#out + 1] = 'SolidColor=0,0,0,1'
        out[#out + 1] = 'X=40'
        out[#out + 1] = 'Y=R'
        out[#out + 1] = 'W=' .. (SKIN_WIDTH - 60)
        out[#out + 1] = 'H=20'
        out[#out + 1] = 'LeftMouseUpAction=' .. editAction
    else
        -- Split by ;; for multi-item descriptions
        local descItems = SplitDesc(item.description)
        for di = 1, #descItems do
            local dtext = Trim(descItems[di])
            -- Strip leading "- " bullet marker
            local cleanText = dtext:match('^%-%s*(.+)') or dtext
            local meterName = 'MeterDesc' .. dataIndex .. '_' .. di

            out[#out + 1] = '[' .. meterName .. ']'
            out[#out + 1] = 'Meter=String'
            out[#out + 1] = 'FontFace=' .. FONT_FACE
            out[#out + 1] = 'FontSize=' .. DESC_FONT_SIZE
            out[#out + 1] = 'AntiAlias=1'
            out[#out + 1] = 'ClipString=1'
            out[#out + 1] = 'SolidColor=0,0,0,1'
            out[#out + 1] = 'X=40'
            out[#out + 1] = 'Y=R'
            out[#out + 1] = 'W=' .. (SKIN_WIDTH - 80)
            out[#out + 1] = 'H=20'

            if IsURL(cleanText) then
                local bullet = (#descItems > 1) and '# ' or ''
                out[#out + 1] = 'Text=' .. bullet .. ShortenURL(cleanText)
                out[#out + 1] = 'FontColor=100,160,255,255'
                out[#out + 1] = 'StringStyle=Underline'
                out[#out + 1] = 'LeftMouseUpAction=["' .. cleanText .. '"]'
                out[#out + 1] = 'ToolTipText=' .. cleanText
            else
                local bullet = (#descItems > 1) and '#  ' or ''
                out[#out + 1] = 'Text=' .. bullet .. cleanText
                out[#out + 1] = 'FontColor=' .. DESC_COLOR
                out[#out + 1] = 'LeftMouseUpAction=' .. editAction
            end
        end

        -- Pencil edit icon after the last description line
        out[#out + 1] = '[MeterDescEdit' .. dataIndex .. ']'
        out[#out + 1] = 'Meter=String'
        out[#out + 1] = 'Text=#icon-edit#'
        out[#out + 1] = 'FontFace=Material Icons'
        out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 4)
        out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
        out[#out + 1] = 'SolidColor=0,0,0,1'
        out[#out + 1] = 'AntiAlias=1'
        out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 35)'
        out[#out + 1] = 'Y=r'
        out[#out + 1] = 'H=20'
        out[#out + 1] = 'ToolTipText=Edit description'
        out[#out + 1] = 'LeftMouseUpAction=' .. editAction
    end
end

function BuildSubitemMeter(out, dataIndex, meterIndex, item)
    local isChecked = (item.checked == 'x')
    local nameColor = isChecked and COMPLETED_COLOR or ACTIVE_COLOR
    local checkIcon = isChecked and '#icon-checked#' or '#icon-check#'

    -- Subitem indicator + checkbox
    out[#out + 1] = '[MeterSubCheck' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. checkIcon
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. nameColor
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=' .. (15 + SUB_INDENT)
    out[#out + 1] = 'Y=3R'
    out[#out + 1] = 'H=22'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ToggleCheck(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Subitem name
    out[#out + 1] = '[MeterSubName' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. item.name
    out[#out + 1] = 'FontFace=' .. FONT_FACE
    out[#out + 1] = 'FontSize=' .. SUB_FONT_SIZE
    out[#out + 1] = 'FontColor=' .. nameColor
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'ClipString=1'
    out[#out + 1] = 'X=' .. (15 + SUB_INDENT + 25)
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - SUB_INDENT - 110)
    out[#out + 1] = 'H=22'
    if isChecked then
        out[#out + 1] = 'StringEffect=Strikethrough'
    end

    -- Delete subitem
    out[#out + 1] = '[MeterSubDel' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-delete#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 3)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 30)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=22'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Description for subitem
    local subDescMeter = 'MeterSubDesc' .. dataIndex
    local subXPos = 15 + SUB_INDENT + 25
    local subEditAction = PosAt(subDescMeter, subXPos) .. '[!SetVariable EditIndex "' .. dataIndex .. '"][!SetVariable EditDefault "' .. EscapeQuotes(item.description) .. '"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 9-10"]'

    if item.description == '' then
        out[#out + 1] = '[MeterSubDesc' .. dataIndex .. ']'
        out[#out + 1] = 'Meter=String'
        out[#out + 1] = 'Text=add note...'
        out[#out + 1] = 'FontFace=' .. FONT_FACE
        out[#out + 1] = 'FontSize=' .. (DESC_FONT_SIZE - 1)
        out[#out + 1] = 'FontColor=100,105,115,100'
        out[#out + 1] = 'AntiAlias=1'
        out[#out + 1] = 'ClipString=1'
        out[#out + 1] = 'SolidColor=0,0,0,1'
        out[#out + 1] = 'X=' .. subXPos
        out[#out + 1] = 'Y=R'
        out[#out + 1] = 'W=' .. (SKIN_WIDTH - SUB_INDENT - 80)
        out[#out + 1] = 'H=18'
        out[#out + 1] = 'LeftMouseUpAction=' .. subEditAction
    else
        local descItems = SplitDesc(item.description)
        for di = 1, #descItems do
            local dtext = Trim(descItems[di])
            local cleanText = dtext:match('^%-%s*(.+)') or dtext
            local mName = 'MeterSubDesc' .. dataIndex .. '_' .. di

            out[#out + 1] = '[' .. mName .. ']'
            out[#out + 1] = 'Meter=String'
            out[#out + 1] = 'FontFace=' .. FONT_FACE
            out[#out + 1] = 'FontSize=' .. (DESC_FONT_SIZE - 1)
            out[#out + 1] = 'AntiAlias=1'
            out[#out + 1] = 'ClipString=1'
            out[#out + 1] = 'SolidColor=0,0,0,1'
            out[#out + 1] = 'X=' .. subXPos
            out[#out + 1] = 'Y=R'
            out[#out + 1] = 'W=' .. (SKIN_WIDTH - SUB_INDENT - 100)
            out[#out + 1] = 'H=18'

            if IsURL(cleanText) then
                local bullet = (#descItems > 1) and '# ' or ''
                out[#out + 1] = 'Text=' .. bullet .. ShortenURL(cleanText)
                out[#out + 1] = 'FontColor=100,160,255,255'
                out[#out + 1] = 'StringStyle=Underline'
                out[#out + 1] = 'LeftMouseUpAction=["' .. cleanText .. '"]'
                out[#out + 1] = 'ToolTipText=' .. cleanText
            else
                local bullet = (#descItems > 1) and '#  ' or ''
                out[#out + 1] = 'Text=' .. bullet .. cleanText
                out[#out + 1] = 'FontColor=' .. DESC_COLOR
                out[#out + 1] = 'LeftMouseUpAction=' .. subEditAction
            end
        end

        -- Pencil edit icon
        out[#out + 1] = '[MeterSubDescEdit' .. dataIndex .. ']'
        out[#out + 1] = 'Meter=String'
        out[#out + 1] = 'Text=#icon-edit#'
        out[#out + 1] = 'FontFace=Material Icons'
        out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 4)
        out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
        out[#out + 1] = 'SolidColor=0,0,0,1'
        out[#out + 1] = 'AntiAlias=1'
        out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 35)'
        out[#out + 1] = 'Y=r'
        out[#out + 1] = 'H=18'
        out[#out + 1] = 'ToolTipText=Edit description'
        out[#out + 1] = 'LeftMouseUpAction=' .. subEditAction
    end
end

function BuildToolbar(out, lastMeterIndex)
    -- Add section button
    out[#out + 1] = '[MeterAddSection]'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=+ Section'
    out[#out + 1] = 'FontFace=' .. FONT_FACE
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 4)
    out[#out + 1] = 'FontColor=' .. SECTION_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=15'
    out[#out + 1] = 'Y=15R'
    out[#out + 1] = 'ToolTipText=Add Section'
    out[#out + 1] = 'LeftMouseUpAction=' .. PosAt('MeterAddSection') .. '[!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 1-2"]'

    -- Undo button
    local trashItems = GetTrash()
    if #trashItems > 0 then
        out[#out + 1] = '[MeterUndo]'
        out[#out + 1] = 'Meter=String'
        out[#out + 1] = 'Text=#icon-undo#'
        out[#out + 1] = 'FontFace=Material Icons'
        out[#out + 1] = 'FontSize=' .. BUTTON_SIZE
        out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
        out[#out + 1] = 'SolidColor=0,0,0,1'
        out[#out + 1] = 'AntiAlias=1'
        out[#out + 1] = 'X=6R'
        out[#out + 1] = 'Y=r'
        out[#out + 1] = 'ToolTipText=Undo Delete'
        out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "UndoDelete()"][!Refresh][!Refresh]'
    end

    -- Bottom padding
    out[#out + 1] = '[MeterBottomPad]'
    out[#out + 1] = 'Meter=Image'
    out[#out + 1] = 'SolidColor=0,0,0,0'
    out[#out + 1] = 'X=0'
    out[#out + 1] = 'Y=10R'
    out[#out + 1] = 'W=1'
    out[#out + 1] = 'H=5'
end


-- === Action functions called from skin ===

function ToggleCheck(lineIndex)
    local items = ParseData()
    if lineIndex < 1 or lineIndex > #items then return false end

    local item = items[lineIndex]
    if item.type == 'section' then return false end

    if item.checked == 'x' then
        item.checked = ''
    else
        item.checked = 'x'
    end

    return WriteData(items)
end

function AddTask(name)
    local items = ParseData()
    items[#items + 1] = {
        type = 'task',
        name = name,
        checked = '',
        description = ''
    }
    WriteData(items)
    return true
end

function AddTaskWithDesc(name, desc)
    local items = ParseData()
    items[#items + 1] = {
        type = 'task',
        name = name,
        checked = '',
        description = desc or ''
    }
    WriteData(items)
    return true
end

function AddSubitem(name)
    local items = ParseData()
    items[#items + 1] = {
        type = 'subitem',
        name = name,
        checked = '',
        description = ''
    }
    WriteData(items)
    return true
end

function AddSection(label)
    local items = ParseData()
    items[#items + 1] = {
        type = 'section',
        label = label
    }
    WriteData(items)
    return true
end

function InsertTaskAfterSection(sectionIndex, name)
    local items = ParseData()
    if sectionIndex < 1 or sectionIndex > #items then return false end

    -- Find the end of this section's items (insert before next section or at end)
    local insertAt = sectionIndex + 1
    while insertAt <= #items and items[insertAt].type ~= 'section' do
        insertAt = insertAt + 1
    end

    local newTask = {
        type = 'task',
        name = name,
        checked = '',
        description = ''
    }
    table.insert(items, insertAt, newTask)
    WriteData(items)
    return true
end

function InsertSubitemAfterTask(taskIndex, name)
    local items = ParseData()
    if taskIndex < 1 or taskIndex > #items then return false end

    -- Insert right after the task and any existing subitems
    local insertAt = taskIndex + 1
    while insertAt <= #items and items[insertAt].type == 'subitem' do
        insertAt = insertAt + 1
    end

    local newSub = {
        type = 'subitem',
        name = name,
        checked = '',
        description = ''
    }
    table.insert(items, insertAt, newSub)
    WriteData(items)
    return true
end

function EditSection(lineIndex, newLabel)
    local items = ParseData()
    if lineIndex < 1 or lineIndex > #items then return false end
    if items[lineIndex].type ~= 'section' then return false end

    items[lineIndex].label = newLabel
    return WriteData(items)
end

function EditDescription(lineIndex, newDesc)
    local items = ParseData()
    if lineIndex < 1 or lineIndex > #items then return false end

    items[lineIndex].description = newDesc
    return WriteData(items)
end

function RemoveItem(lineIndex)
    local items = ParseData()
    if lineIndex < 1 or lineIndex > #items then return false end

    local removed = items[lineIndex]

    if removed.type == 'section' then
        -- Delete section header and all its children (tasks + subitems) until next section
        local endIndex = lineIndex + 1
        while endIndex <= #items and items[endIndex].type ~= 'section' do
            endIndex = endIndex + 1
        end
        -- Trash everything from lineIndex to endIndex-1 (in reverse to keep indices valid)
        for i = endIndex - 1, lineIndex, -1 do
            TrashItem(items[i])
            table.remove(items, i)
        end
    elseif removed.type == 'task' then
        -- Delete task and all consecutive subitems that follow it
        local endIndex = lineIndex + 1
        while endIndex <= #items and items[endIndex].type == 'subitem' do
            endIndex = endIndex + 1
        end
        -- Remove in reverse
        for i = endIndex - 1, lineIndex, -1 do
            TrashItem(items[i])
            table.remove(items, i)
        end
    else
        -- Subitem: just remove the single subitem
        TrashItem(removed)
        table.remove(items, lineIndex)
    end

    return WriteData(items)
end

function TrashItem(item)
    if item.type == 'section' then
        AddToTrash('##' .. item.label)
    elseif item.type == 'subitem' then
        AddToTrash('>' .. item.name .. DIVIDER .. item.checked .. DIVIDER .. (item.description or ''))
    else
        AddToTrash(item.name .. DIVIDER .. item.checked .. DIVIDER .. (item.description or ''))
    end
end

function MoveItem(fromIndex, toIndex)
    local items = ParseData()
    if fromIndex < 1 or fromIndex > #items then return false end
    if toIndex < 1 or toIndex > #items then return false end

    local item = table.remove(items, fromIndex)
    table.insert(items, toIndex, item)
    return WriteData(items)
end

-- Trash management
function GetTrash()
    local trashItems = {}
    local hFile = io.open(sTrashFile, 'r')
    if not hFile then return trashItems end

    for line in hFile:lines() do
        if Trim(line) ~= '' then
            trashItems[#trashItems + 1] = line
        end
    end
    hFile:close()
    return trashItems
end

function AddToTrash(line)
    local hFile = io.open(sTrashFile, 'a')
    if not hFile then return false end
    hFile:write(line .. '\n')
    hFile:close()

    -- Trim trash to last 20 items
    local trashItems = GetTrash()
    if #trashItems > 20 then
        hFile = io.open(sTrashFile, 'w')
        for i = #trashItems - 19, #trashItems do
            hFile:write(trashItems[i] .. '\n')
        end
        hFile:close()
    end
    return true
end

function UndoDelete()
    local trashItems = GetTrash()
    if #trashItems == 0 then return false end

    local lastItem = trashItems[#trashItems]

    -- Remove from trash
    table.remove(trashItems, #trashItems)
    local hFile = io.open(sTrashFile, 'w')
    for i = 1, #trashItems do
        hFile:write(trashItems[i] .. '\n')
    end
    hFile:close()

    -- Add back to data
    local hData = io.open(sDataFile, 'a')
    hData:write(lastItem .. '\n')
    hData:close()

    return true
end

-- Utility functions
function SplitText(inputstr)
    local t = {}
    local pos = 1
    local len = string.len(inputstr)
    while pos <= len do
        local delimPos = string.find(inputstr, '|', pos, true)
        if delimPos then
            t[#t + 1] = string.sub(inputstr, pos, delimPos - 1)
            pos = delimPos + 1
        else
            t[#t + 1] = string.sub(inputstr, pos)
            break
        end
    end
    -- If string ends with |, add empty field
    if len > 0 and string.sub(inputstr, len, len) == '|' then
        t[#t + 1] = ''
    end
    -- Ensure at least 3 fields
    while #t < 3 do
        t[#t + 1] = ''
    end
    return t
end

function Trim(s)
    return s:match('^%s*(.-)%s*$') or s
end

function EscapeQuotes(s)
    return s:gsub('"', "'")
end

function IsURL(s)
    return s:sub(1, 7) == 'http://' or s:sub(1, 8) == 'https://'
end

-- Split description by ;; separator for multi-item descriptions
function SplitDesc(desc)
    local items = {}
    local pos = 1
    while true do
        local sepStart, sepEnd = desc:find(';;', pos, true)
        if sepStart then
            items[#items + 1] = desc:sub(pos, sepStart - 1)
            pos = sepEnd + 1
        else
            items[#items + 1] = desc:sub(pos)
            break
        end
    end
    return items
end

-- Shorten a URL for display: show domain + truncate
function ShortenURL(url)
    -- strip protocol
    local display = url:gsub('^https?://', '')
    -- truncate long URLs
    if string.len(display) > 50 then
        display = string.sub(display, 1, 47) .. '...'
    end
    return display
end

-- Generate bangs to position the InputText dialog at a given meter's location
-- anchorMeter: the meter name to position relative to
-- xOffset: X offset from skin left (default 15)
function PosAt(anchorMeter, xOffset)
    xOffset = xOffset or 15
    return '[!SetVariable InputX "' .. xOffset .. '"][!SetVariable InputY "[' .. anchorMeter .. ':Y]"]'
end
