--[[
  TodoWidget Engine
  Supports: sections (dated labels), tasks with descriptions, subitems, archive

  Data format (data.txt):
    Lines starting with "##" are section headers:  ##Section Label
    Task lines:  name|checked|description
    Subitem lines (indented with >):  >name|checked|description
    Archive marker:  ###ARCHIVE|collapsed  or  ###ARCHIVE|expanded
    Items after the marker are archived
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

    ARCHIVE_COLOR = '100,110,130,180'
    ARCHIVE_DIMMED = '90,95,105,120'

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
            if line:sub(1, 10) == '###ARCHIVE' then
                local state = 'collapsed'
                local pipePos = line:find('|', 1, true)
                if pipePos then
                    state = line:sub(pipePos + 1)
                end
                items[#items + 1] = {
                    type = 'archive_marker',
                    collapsed = (state ~= 'expanded')
                }
            elseif line:sub(1, 2) == '##' then
                items[#items + 1] = {
                    type = 'section',
                    label = line:sub(3),
                    raw = line
                }
            elseif line:sub(1, 1) == '>' then
                local parts = SplitText(line:sub(2))
                items[#items + 1] = {
                    type = 'subitem',
                    name = parts[1] or '',
                    checked = parts[2] or '',
                    description = parts[3] or '',
                    raw = line
                }
            else
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
    -- Safety: refuse to write empty data if the file already has content
    if #items == 0 then
        SKIN:Bang('!Log', 'TodoEngine: WriteData refused to write empty items list', 'Warning')
        return false
    end

    -- Backup current file before overwriting
    local src = io.open(sDataFile, 'r')
    if src then
        local content = src:read('*a')
        src:close()
        if content and #content > 0 then
            local bak = io.open(sDataFile .. '.bak', 'w')
            if bak then
                bak:write(content)
                bak:close()
            end
        end
    end

    local hFile = io.open(sDataFile, 'w')
    if not hFile then return false end

    for i = 1, #items do
        local item = items[i]
        if item.type == 'archive_marker' then
            local state = item.collapsed and 'collapsed' or 'expanded'
            hFile:write('###ARCHIVE|' .. state .. '\n')
        elseif item.type == 'section' then
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

    -- Find archive marker
    local archivePos = FindArchiveMarker(items)
    local activeEnd = archivePos and (archivePos - 1) or #items

    -- Build meters for active items
    for i = 1, activeEnd do
        local item = items[i]
        meterIndex = meterIndex + 1

        if item.type == 'section' then
            BuildSectionMeter(out, i, meterIndex, item, items, activeEnd)
        elseif item.type == 'task' then
            BuildTaskMeter(out, i, meterIndex, item)
        elseif item.type == 'subitem' then
            BuildSubitemMeter(out, i, meterIndex, item)
        end
    end

    -- Bottom toolbar
    BuildToolbar(out, meterIndex)

    -- Archive section
    if archivePos then
        local archiveItem = items[archivePos]
        BuildArchiveHeader(out, archiveItem)

        if not archiveItem.collapsed then
            for i = archivePos + 1, #items do
                local item = items[i]
                meterIndex = meterIndex + 1

                if item.type == 'section' then
                    BuildArchivedSectionMeter(out, i, meterIndex, item)
                elseif item.type == 'task' then
                    BuildArchivedTaskMeter(out, i, meterIndex, item)
                elseif item.type == 'subitem' then
                    BuildArchivedSubitemMeter(out, i, meterIndex, item)
                end
            end
        end
    end

    -- Bottom padding
    out[#out + 1] = '[MeterBottomPad]'
    out[#out + 1] = 'Meter=Image'
    out[#out + 1] = 'SolidColor=0,0,0,0'
    out[#out + 1] = 'X=0'
    out[#out + 1] = 'Y=10R'
    out[#out + 1] = 'W=1'
    out[#out + 1] = 'H=5'

    -- Write dynamic file
    local hFile = io.open(sDynamicFile, 'w')
    if not hFile then return false end
    hFile:write(table.concat(out, '\n'))
    hFile:close()

    return true
end

function BuildSectionMeter(out, dataIndex, meterIndex, item, items, activeEnd)
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
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - 140)
    out[#out + 1] = 'H=30'
    local sectionLineMeter = 'MeterSectionLine' .. dataIndex
    local sectionMeter = 'MeterSection' .. dataIndex

    -- Find the last item in this section to position the "add task" input there
    local lastInSection = dataIndex
    for j = dataIndex + 1, activeEnd do
        if items[j].type == 'section' or items[j].type == 'archive_marker' then break end
        lastInSection = j
    end
    local addTaskAnchor
    if lastInSection == dataIndex then
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

    -- Move section up
    out[#out + 1] = '[MeterSectionUp' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-up#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 3)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 130)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'ToolTipText=Move section up'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "MoveSectionUp(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Move section down
    out[#out + 1] = '[MeterSectionDown' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-down#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 3)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=1R'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'ToolTipText=Move section down'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "MoveSectionDown(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Add task to this section (+)
    out[#out + 1] = '[MeterSectionAdd' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-add#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. SECTION_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=4R'
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

    -- Archive section icon
    out[#out + 1] = '[MeterSectionArchive' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-archive#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=4R'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'ToolTipText=Archive section'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ArchiveSection(' .. dataIndex .. ')"][!Refresh][!Refresh]'

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
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - 170)
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

    -- Move task up
    out[#out + 1] = '[MeterTaskUp' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-up#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 4)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 120)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'ToolTipText=Move up'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "MoveTaskUp(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Move task down
    out[#out + 1] = '[MeterTaskDown' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-down#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 4)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=1R'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'ToolTipText=Move down'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "MoveTaskDown(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Add subitem
    out[#out + 1] = '[MeterTaskAddSub' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-subitem#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 3)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=4R'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'ToolTipText=Add subitem'
    out[#out + 1] = 'LeftMouseUpAction=' .. PosAt(descAnchor, 15 + SUB_INDENT) .. '[!SetVariable EditIndex "' .. dataIndex .. '"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 7-8"]'

    -- Archive button
    out[#out + 1] = '[MeterTaskArchive' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-archive#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 3)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=4R'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'ToolTipText=Archive task'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ArchiveTask(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Delete button
    out[#out + 1] = '[MeterTaskDel' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-delete#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=4R'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Description area
    local editDescMeter = (item.description ~= '') and ('MeterDesc' .. dataIndex .. '_1') or ('MeterDesc' .. dataIndex)
    local editAction = PosAt(editDescMeter, 40) .. '[!SetVariable EditIndex "' .. dataIndex .. '"][!SetVariable EditDefault "' .. EscapeQuotes(item.description) .. '"][!UpdateMeasure MeasureInput][!CommandMeasure MeasureInput "ExecuteBatch 9-10"]'

    if item.description == '' then
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
        local descItems = SplitDesc(item.description)
        for di = 1, #descItems do
            local dtext = Trim(descItems[di])
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

    -- Backup button (right side of toolbar)
    out[#out + 1] = '[MeterBackup]'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-save#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. BUTTON_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 30)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'ToolTipText=Backup data'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "BackupData()"][!SetOption MeterBackup Text "#icon-checked#"][!SetOption MeterBackup FontColor "80,200,120,255"][!UpdateMeter MeterBackup][!Redraw]'
end

-- === Archive rendering ===

function BuildArchiveHeader(out, archiveItem)
    local toggleIcon = archiveItem.collapsed and '#icon-expand#' or '#icon-collapse#'

    -- Divider line above archive
    out[#out + 1] = '[MeterArchiveLine]'
    out[#out + 1] = 'Meter=Image'
    out[#out + 1] = 'SolidColor=60,70,90,120'
    out[#out + 1] = 'X=15'
    out[#out + 1] = 'Y=15R'
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - 30)
    out[#out + 1] = 'H=1'

    -- Archive toggle icon
    out[#out + 1] = '[MeterArchiveHeader]'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. toggleIcon
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_COLOR
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=15'
    out[#out + 1] = 'Y=6R'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ToggleArchive()"][!Refresh][!Refresh]'

    -- Archive label
    out[#out + 1] = '[MeterArchiveLabel]'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=ARCHIVE'
    out[#out + 1] = 'FontFace=' .. FONT_FACE
    out[#out + 1] = 'FontSize=' .. (FONT_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_COLOR
    out[#out + 1] = 'FontWeight=700'
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=4R'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=24'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "ToggleArchive()"][!Refresh][!Refresh]'
end

function BuildArchivedSectionMeter(out, dataIndex, meterIndex, item)
    out[#out + 1] = '[MeterSection' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. item.label
    out[#out + 1] = 'FontFace=' .. FONT_FACE
    out[#out + 1] = 'FontSize=' .. (SECTION_FONT_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_COLOR
    out[#out + 1] = 'FontWeight=700'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'ClipString=1'
    out[#out + 1] = 'X=15'
    out[#out + 1] = 'Y=12R'
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - 60)
    out[#out + 1] = 'H=26'

    -- Delete archived section
    out[#out + 1] = '[MeterSectionDel' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-delete#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_DIMMED
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 30)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Thin divider
    out[#out + 1] = '[MeterSectionLine' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=Image'
    out[#out + 1] = 'SolidColor=60,70,90,60'
    out[#out + 1] = 'X=15'
    out[#out + 1] = 'Y=1R'
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - 30)
    out[#out + 1] = 'H=1'
end

function BuildArchivedTaskMeter(out, dataIndex, meterIndex, item)
    local isChecked = (item.checked == 'x')
    local checkIcon = isChecked and '#icon-checked#' or '#icon-check#'

    out[#out + 1] = '[MeterCheck' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. checkIcon
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 2)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_DIMMED
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=15'
    out[#out + 1] = 'Y=4R'
    out[#out + 1] = 'H=22'

    out[#out + 1] = '[MeterName' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. item.name
    out[#out + 1] = 'FontFace=' .. FONT_FACE
    out[#out + 1] = 'FontSize=' .. (FONT_SIZE - 1)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_DIMMED
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'ClipString=1'
    out[#out + 1] = 'X=38'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - 80)
    out[#out + 1] = 'H=22'
    if isChecked then
        out[#out + 1] = 'StringEffect=Strikethrough'
    end

    -- Delete archived task
    out[#out + 1] = '[MeterTaskDel' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-delete#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 3)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_DIMMED
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 30)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=22'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(' .. dataIndex .. ')"][!Refresh][!Refresh]'

    -- Show description if present (dimmed, non-interactive)
    if item.description ~= '' then
        local descItems = SplitDesc(item.description)
        for di = 1, #descItems do
            local dtext = Trim(descItems[di])
            local cleanText = dtext:match('^%-%s*(.+)') or dtext

            out[#out + 1] = '[MeterDesc' .. dataIndex .. '_' .. di .. ']'
            out[#out + 1] = 'Meter=String'
            out[#out + 1] = 'FontFace=' .. FONT_FACE
            out[#out + 1] = 'FontSize=' .. (DESC_FONT_SIZE - 1)
            out[#out + 1] = 'AntiAlias=1'
            out[#out + 1] = 'ClipString=1'
            out[#out + 1] = 'X=38'
            out[#out + 1] = 'Y=R'
            out[#out + 1] = 'W=' .. (SKIN_WIDTH - 60)
            out[#out + 1] = 'H=18'

            if IsURL(cleanText) then
                local bullet = (#descItems > 1) and '# ' or ''
                out[#out + 1] = 'Text=' .. bullet .. ShortenURL(cleanText)
                out[#out + 1] = 'FontColor=70,110,180,150'
                out[#out + 1] = 'ToolTipText=' .. cleanText
            else
                local bullet = (#descItems > 1) and '#  ' or ''
                out[#out + 1] = 'Text=' .. bullet .. cleanText
                out[#out + 1] = 'FontColor=80,85,95,100'
            end
        end
    end
end

function BuildArchivedSubitemMeter(out, dataIndex, meterIndex, item)
    local isChecked = (item.checked == 'x')
    local checkIcon = isChecked and '#icon-checked#' or '#icon-check#'

    out[#out + 1] = '[MeterSubCheck' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. checkIcon
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 3)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_DIMMED
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=' .. (15 + SUB_INDENT)
    out[#out + 1] = 'Y=2R'
    out[#out + 1] = 'H=20'

    out[#out + 1] = '[MeterSubName' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=' .. item.name
    out[#out + 1] = 'FontFace=' .. FONT_FACE
    out[#out + 1] = 'FontSize=' .. (SUB_FONT_SIZE - 1)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_DIMMED
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'ClipString=1'
    out[#out + 1] = 'X=' .. (15 + SUB_INDENT + 22)
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'W=' .. (SKIN_WIDTH - SUB_INDENT - 80)
    out[#out + 1] = 'H=20'
    if isChecked then
        out[#out + 1] = 'StringEffect=Strikethrough'
    end

    -- Delete archived subitem
    out[#out + 1] = '[MeterSubDel' .. dataIndex .. ']'
    out[#out + 1] = 'Meter=String'
    out[#out + 1] = 'Text=#icon-delete#'
    out[#out + 1] = 'FontFace=Material Icons'
    out[#out + 1] = 'FontSize=' .. (BUTTON_SIZE - 3)
    out[#out + 1] = 'FontColor=' .. ARCHIVE_DIMMED
    out[#out + 1] = 'SolidColor=0,0,0,1'
    out[#out + 1] = 'AntiAlias=1'
    out[#out + 1] = 'X=(' .. SKIN_WIDTH .. ' - 30)'
    out[#out + 1] = 'Y=r'
    out[#out + 1] = 'H=20'
    out[#out + 1] = 'LeftMouseUpAction=[!CommandMeasure "MeasureTodoEngine" "RemoveItem(' .. dataIndex .. ')"][!Refresh][!Refresh]'
end


-- === Action functions called from skin ===

function ToggleCheck(lineIndex)
    local items = ParseData()
    if lineIndex < 1 or lineIndex > #items then return false end

    local item = items[lineIndex]
    if item.type == 'section' or item.type == 'archive_marker' then return false end

    if item.checked == 'x' then
        item.checked = ''
    else
        item.checked = 'x'
    end

    return WriteData(items)
end

function AddTask(name)
    local items = ParseData()
    local insertAt = FindArchiveMarker(items) or (#items + 1)
    table.insert(items, insertAt, {
        type = 'task',
        name = name,
        checked = '',
        description = ''
    })
    WriteData(items)
    return true
end

function AddTaskWithDesc(name, desc)
    local items = ParseData()
    local insertAt = FindArchiveMarker(items) or (#items + 1)
    table.insert(items, insertAt, {
        type = 'task',
        name = name,
        checked = '',
        description = desc or ''
    })
    WriteData(items)
    return true
end

function AddSubitem(name)
    local items = ParseData()
    local insertAt = FindArchiveMarker(items) or (#items + 1)
    table.insert(items, insertAt, {
        type = 'subitem',
        name = name,
        checked = '',
        description = ''
    })
    WriteData(items)
    return true
end

function AddSection(label)
    local items = ParseData()
    local insertAt = FindArchiveMarker(items) or (#items + 1)
    table.insert(items, insertAt, {
        type = 'section',
        label = label
    })
    WriteData(items)
    return true
end

function InsertTaskAfterSection(sectionIndex, name)
    local items = ParseData()
    if sectionIndex < 1 or sectionIndex > #items then return false end

    local insertAt = sectionIndex + 1
    while insertAt <= #items and items[insertAt].type ~= 'section' and items[insertAt].type ~= 'archive_marker' do
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
        local endIndex = lineIndex + 1
        while endIndex <= #items and items[endIndex].type ~= 'section' and items[endIndex].type ~= 'archive_marker' do
            endIndex = endIndex + 1
        end
        for i = endIndex - 1, lineIndex, -1 do
            TrashItem(items[i])
            table.remove(items, i)
        end
    elseif removed.type == 'task' then
        local endIndex = lineIndex + 1
        while endIndex <= #items and items[endIndex].type == 'subitem' do
            endIndex = endIndex + 1
        end
        for i = endIndex - 1, lineIndex, -1 do
            TrashItem(items[i])
            table.remove(items, i)
        end
    elseif removed.type == 'subitem' then
        TrashItem(removed)
        table.remove(items, lineIndex)
    end

    return WriteData(items)
end

-- === Archive functions ===

function ArchiveSection(sectionIndex)
    local items = ParseData()
    if sectionIndex < 1 or sectionIndex > #items then return false end
    if items[sectionIndex].type ~= 'section' then return false end

    local sectionName = items[sectionIndex].label

    -- Collect section + children
    local endIndex = sectionIndex + 1
    while endIndex <= #items and items[endIndex].type ~= 'section' and items[endIndex].type ~= 'archive_marker' do
        endIndex = endIndex + 1
    end

    -- Extract items to archive
    local toArchive = {}
    for i = sectionIndex, endIndex - 1 do
        toArchive[#toArchive + 1] = items[i]
    end

    -- Remove from active area (reverse order)
    for i = endIndex - 1, sectionIndex, -1 do
        table.remove(items, i)
    end

    -- Find or create archive marker
    local archivePos = FindArchiveMarker(items)
    if not archivePos then
        items[#items + 1] = { type = 'archive_marker', collapsed = false }
        archivePos = #items
    else
        -- Auto-expand when archiving
        items[archivePos].collapsed = false
    end

    -- Find matching section in archive
    local existingSection = nil
    for i = archivePos + 1, #items do
        if items[i].type == 'section' and items[i].label == sectionName then
            existingSection = i
            break
        end
    end

    if existingSection then
        -- Find end of existing archive section to merge
        local insertAt = existingSection + 1
        while insertAt <= #items and items[insertAt].type ~= 'section' do
            insertAt = insertAt + 1
        end
        -- Insert tasks only (skip the duplicate section header)
        for j = 2, #toArchive do
            table.insert(items, insertAt, toArchive[j])
            insertAt = insertAt + 1
        end
    else
        -- Append entire section to end
        for j = 1, #toArchive do
            items[#items + 1] = toArchive[j]
        end
    end

    return WriteData(items)
end

function ArchiveTask(taskIndex)
    local items = ParseData()
    if taskIndex < 1 or taskIndex > #items then return false end
    if items[taskIndex].type ~= 'task' then return false end

    -- Find parent section name
    local parentName = FindParentSectionName(items, taskIndex)

    -- Collect task + subitems
    local endIndex = taskIndex + 1
    while endIndex <= #items and items[endIndex].type == 'subitem' do
        endIndex = endIndex + 1
    end

    local toArchive = {}
    for i = taskIndex, endIndex - 1 do
        toArchive[#toArchive + 1] = items[i]
    end

    -- Remove from active area
    for i = endIndex - 1, taskIndex, -1 do
        table.remove(items, i)
    end

    -- Find or create archive marker
    local archivePos = FindArchiveMarker(items)
    if not archivePos then
        items[#items + 1] = { type = 'archive_marker', collapsed = false }
        archivePos = #items
    else
        items[archivePos].collapsed = false
    end

    -- Find matching section in archive
    local existingSection = nil
    for i = archivePos + 1, #items do
        if items[i].type == 'section' and items[i].label == parentName then
            existingSection = i
            break
        end
    end

    local insertAt
    if existingSection then
        -- Find end of this section in archive
        insertAt = existingSection + 1
        while insertAt <= #items and items[insertAt].type ~= 'section' do
            insertAt = insertAt + 1
        end
    else
        -- Create section at end of archive
        items[#items + 1] = { type = 'section', label = parentName }
        insertAt = #items + 1
    end

    -- Insert archived items
    for j = 1, #toArchive do
        table.insert(items, insertAt, toArchive[j])
        insertAt = insertAt + 1
    end

    return WriteData(items)
end

function BackupData()
    local timestamp = os.date('%Y%m%d_%H%M%S')
    local backupFile = sDataFile:gsub('%.txt$', '') .. '_' .. timestamp .. '.txt'

    local hIn = io.open(sDataFile, 'r')
    if not hIn then return false end
    local content = hIn:read('*a')
    hIn:close()

    local hOut = io.open(backupFile, 'w')
    if not hOut then return false end
    hOut:write(content)
    hOut:close()

    return true
end

function ToggleArchive()
    local items = ParseData()
    local archivePos = FindArchiveMarker(items)
    if not archivePos then return false end

    items[archivePos].collapsed = not items[archivePos].collapsed
    return WriteData(items)
end

function MoveSectionUp(sectionIndex)
    local items = ParseData()
    if sectionIndex < 1 or sectionIndex > #items then return false end
    if items[sectionIndex].type ~= 'section' then return false end

    -- Find previous section
    local prevSection = nil
    for i = sectionIndex - 1, 1, -1 do
        if items[i].type == 'section' then
            prevSection = i
            break
        end
    end
    if not prevSection then return false end

    local archivePos = FindArchiveMarker(items)
    local activeEnd = archivePos and (archivePos - 1) or #items

    -- Collect current section block
    local endIndex = sectionIndex + 1
    while endIndex <= activeEnd and items[endIndex].type ~= 'section' do
        endIndex = endIndex + 1
    end

    -- Extract block
    local block = {}
    for i = sectionIndex, endIndex - 1 do
        block[#block + 1] = items[i]
    end

    -- Remove block
    for i = endIndex - 1, sectionIndex, -1 do
        table.remove(items, i)
    end

    -- Insert at previous section's position
    for j = 1, #block do
        table.insert(items, prevSection + j - 1, block[j])
    end

    return WriteData(items)
end

function MoveSectionDown(sectionIndex)
    local items = ParseData()
    if sectionIndex < 1 or sectionIndex > #items then return false end
    if items[sectionIndex].type ~= 'section' then return false end

    local archivePos = FindArchiveMarker(items)
    local activeEnd = archivePos and (archivePos - 1) or #items

    -- Find end of current section
    local endIndex = sectionIndex + 1
    while endIndex <= activeEnd and items[endIndex].type ~= 'section' do
        endIndex = endIndex + 1
    end

    -- Next section must exist
    if endIndex > activeEnd then return false end
    if items[endIndex].type ~= 'section' then return false end

    -- MoveSectionUp on the next section achieves the same result
    local nextSection = endIndex

    -- Collect next section block
    local nextEnd = nextSection + 1
    while nextEnd <= activeEnd and items[nextEnd].type ~= 'section' do
        nextEnd = nextEnd + 1
    end

    local block = {}
    for i = nextSection, nextEnd - 1 do
        block[#block + 1] = items[i]
    end

    for i = nextEnd - 1, nextSection, -1 do
        table.remove(items, i)
    end

    for j = 1, #block do
        table.insert(items, sectionIndex + j - 1, block[j])
    end

    return WriteData(items)
end

function MoveTaskUp(taskIndex)
    local items = ParseData()
    if taskIndex < 1 or taskIndex > #items then return false end
    if items[taskIndex].type ~= 'task' then return false end

    -- Find previous task (stop at section boundary)
    local prevTask = nil
    for i = taskIndex - 1, 1, -1 do
        if items[i].type == 'section' or items[i].type == 'archive_marker' then break end
        if items[i].type == 'task' then
            prevTask = i
            break
        end
    end
    if not prevTask then return false end

    -- Collect current task block (task + subitems)
    local endIndex = taskIndex + 1
    while endIndex <= #items and items[endIndex].type == 'subitem' do
        endIndex = endIndex + 1
    end

    local block = {}
    for i = taskIndex, endIndex - 1 do
        block[#block + 1] = items[i]
    end

    for i = endIndex - 1, taskIndex, -1 do
        table.remove(items, i)
    end

    -- Insert before previous task
    for j = 1, #block do
        table.insert(items, prevTask + j - 1, block[j])
    end

    return WriteData(items)
end

function MoveTaskDown(taskIndex)
    local items = ParseData()
    if taskIndex < 1 or taskIndex > #items then return false end
    if items[taskIndex].type ~= 'task' then return false end

    -- Collect current task block
    local endIndex = taskIndex + 1
    while endIndex <= #items and items[endIndex].type == 'subitem' do
        endIndex = endIndex + 1
    end

    -- Next item must be a task (not section/archive boundary)
    if endIndex > #items or items[endIndex].type ~= 'task' then return false end

    local nextTask = endIndex

    -- Collect next task block
    local nextEnd = nextTask + 1
    while nextEnd <= #items and items[nextEnd].type == 'subitem' do
        nextEnd = nextEnd + 1
    end

    -- Extract next block, insert before current
    local block = {}
    for i = nextTask, nextEnd - 1 do
        block[#block + 1] = items[i]
    end

    for i = nextEnd - 1, nextTask, -1 do
        table.remove(items, i)
    end

    for j = 1, #block do
        table.insert(items, taskIndex + j - 1, block[j])
    end

    return WriteData(items)
end

-- === Helper functions ===

function FindArchiveMarker(items)
    for i = 1, #items do
        if items[i].type == 'archive_marker' then return i end
    end
    return nil
end

function FindParentSectionName(items, index)
    for i = index - 1, 1, -1 do
        if items[i].type == 'section' then return items[i].label end
    end
    return 'Unsorted'
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

    table.remove(trashItems, #trashItems)
    local hFile = io.open(sTrashFile, 'w')
    for i = 1, #trashItems do
        hFile:write(trashItems[i] .. '\n')
    end
    hFile:close()

    -- Add back to data (before archive marker)
    local items = ParseData()
    local insertAt = FindArchiveMarker(items) or (#items + 1)

    -- Parse the trash line into an item
    if lastItem:sub(1, 2) == '##' then
        table.insert(items, insertAt, { type = 'section', label = lastItem:sub(3) })
    elseif lastItem:sub(1, 1) == '>' then
        local parts = SplitText(lastItem:sub(2))
        table.insert(items, insertAt, { type = 'subitem', name = parts[1], checked = parts[2], description = parts[3] })
    else
        local parts = SplitText(lastItem)
        table.insert(items, insertAt, { type = 'task', name = parts[1], checked = parts[2], description = parts[3] })
    end

    return WriteData(items)
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
    if len > 0 and string.sub(inputstr, len, len) == '|' then
        t[#t + 1] = ''
    end
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

function ShortenURL(url)
    local display = url:gsub('^https?://', '')
    if string.len(display) > 50 then
        display = string.sub(display, 1, 47) .. '...'
    end
    return display
end

function PosAt(anchorMeter, xOffset)
    xOffset = xOffset or 15
    return '[!SetVariable InputX "' .. xOffset .. '"][!SetVariable InputY "[' .. anchorMeter .. ':Y]"]'
end
