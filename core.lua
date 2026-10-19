local addonName, addonTable = ...

local AceAddon = LibStub("AceAddon-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local SPELL_ID = 1280098
local MIN_FRAME_WIDTH = 240
local MAX_FRAME_WIDTH = 900
local FRAME_CHROME_WIDTH = 34
local FRAME_CHROME_HEIGHT = 80
local DEFAULT_POSITION_GAP = 12
local BOON_VALUE_TERMS = {
    "maximum health",
    "primary stat",
    "haste",
    "critical strike",
    "mastery",
    "versatility",
    "movement speed",
    "incoming damage",
    "damage reduction",
}

local addon = AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
    profile = {
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 13,
        fontColor = {
            r = 1,
            g = 1,
            b = 1,
        },
        frame = {
        },
    },
}

local function StripTooltipColors(text)
    return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", "\n")
end

local function IsBoonValueLine(text)
    if not text:find("%%") then
        return false
    end

    local lowerText = text:lower()
    for _, term in ipairs(BOON_VALUE_TERMS) do
        if lowerText:find(term, 1, true) then
            return true
        end
    end

    return false
end

local function GetSpellValues()
    local tooltipData = C_TooltipInfo.GetSpellByID(SPELL_ID)
    local lines = {}

    if tooltipData and tooltipData.lines then
        for _, line in ipairs(tooltipData.lines) do
            local leftText = line.leftText and StripTooltipColors(line.leftText):match("^%s*(.-)%s*$")
            local rightText = line.rightText and StripTooltipColors(line.rightText):match("^%s*(.-)%s*$")
            local text

            if leftText and leftText ~= "" then
                if rightText and rightText ~= "" then
                    text = leftText .. "  " .. rightText
                else
                    text = leftText
                end
            elseif rightText and rightText ~= "" then
                text = rightText
            end

            if text and IsBoonValueLine(text) then
                lines[#lines + 1] = text
            end
        end
    end

    if #lines > 0 then
        return table.concat(lines, "\n")
    end

    if C_Spell and C_Spell.GetSpellDescription then
        local description = C_Spell.GetSpellDescription(SPELL_ID)
        if description and description ~= "" then
            for line in StripTooltipColors(description):gmatch("[^\n]+") do
                if IsBoonValueLine(line) then
                    lines[#lines + 1] = line
                end
            end

            if #lines > 0 then
                return table.concat(lines, "\n")
            end
        end
    end

    return L["Spell values are not available yet."]
end

function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BearsBoonViewerDB", defaults, true)
    addonTable.RegisterOptions(self)
    self:RegisterChatCommand("bbv", "SlashCommand")
    self:RegisterChatCommand("boonviewer", "SlashCommand")

    self:RegisterEvent("PLAYER_ENTERING_WORLD", "RefreshSpellValues")
    self:RegisterEvent("SPELLS_CHANGED", "RefreshSpellValues")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "RefreshSpellValues")
    self:RegisterEvent("PLAYER_STATS_CHANGED", "RefreshSpellValues")
    self:RegisterEvent("PLAYER_TALENT_UPDATE", "RefreshSpellValues")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "RefreshSpellValues")
    self:RegisterEvent("SPELL_DATA_LOAD_RESULT", "OnSpellDataLoadResult")
    self:RegisterEvent("UNIT_AURA", "OnUnitAura")
end

function addon:OnEnable()
    if C_Spell and C_Spell.RequestLoadSpellData then
        C_Spell.RequestLoadSpellData(SPELL_ID)
    end

    self:CreateDisplay()
    self:RefreshSpellValues()
    self.displayFrame:Show()
end

function addon:CreateDisplay()
    if self.displayFrame then
        return
    end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle(L["Bears Boon Viewer"])
    frame:SetStatusText(L["Drag this window to move it."])
    frame:SetLayout("Flow")
    frame:SetStatusTable(self.db.profile.frame)
    frame:EnableResize(false)

    local valueLabel = AceGUI:Create("Label")
    valueLabel:SetFullWidth(true)
    frame:AddChild(valueLabel)

    self.displayFrame = frame
    self.valueLabel = valueLabel
    self.measureText = UIParent:CreateFontString(nil, "ARTWORK")
    self.measureText:Hide()
end

function addon:UpdateDisplay()
    if not self.valueLabel then
        return
    end

    local profile = self.db.profile
    local color = profile.fontColor
    local valuesText = GetSpellValues()

    self.valueLabel:SetFont(profile.font, profile.fontSize)
    self.valueLabel:SetColor(color.r, color.g, color.b)
    self.valueLabel:SetText(valuesText)

    local measureText = self.measureText
    measureText:SetFont(profile.font, profile.fontSize)

    local widestLine = 0
    for line in valuesText:gmatch("[^\n]+") do
        measureText:SetWordWrap(false)
        measureText:SetText(line)
        widestLine = math.max(widestLine, measureText:GetStringWidth())
    end

    local contentWidth = math.min(MAX_FRAME_WIDTH - FRAME_CHROME_WIDTH, widestLine)
    contentWidth = math.max(MIN_FRAME_WIDTH - FRAME_CHROME_WIDTH, contentWidth)

    self.displayFrame:SetWidth(contentWidth + FRAME_CHROME_WIDTH)
    self.valueLabel:SetWidth(contentWidth)
    self.displayFrame:DoLayout()
    self.valueLabel:SetWidth(contentWidth)

    measureText:SetWordWrap(true)
    measureText:SetWidth(contentWidth)
    measureText:SetText(valuesText)
    local contentHeight = math.max(profile.fontSize, measureText:GetStringHeight())
    self.displayFrame:SetHeight(contentHeight + FRAME_CHROME_HEIGHT)
    self:PositionFrameByDefault(contentWidth + FRAME_CHROME_WIDTH)
end

function addon:PositionFrameByDefault(frameWidth)
    local position = self.db.profile.frame
    if position.left and position.top then
        return
    end

    local map = _G.Minimap
    local mapLeft = map and map:GetLeft()
    local mapTop = map and map:GetTop()
    if not mapLeft or not mapTop then
        return
    end

    local top = mapTop
    local buffBar = _G.BuffFrame
    local buffBottom = buffBar and buffBar:GetBottom()
    if buffBottom then
        top = math.min(top, buffBottom)
    end

    position.left = mapLeft - frameWidth - DEFAULT_POSITION_GAP
    position.top = top - DEFAULT_POSITION_GAP
    self.displayFrame:ApplyStatus()
end

function addon:RefreshSpellValues()
    if not self.displayFrame then
        return
    end

    self:UpdateDisplay()
end

function addon:OnSpellDataLoadResult(_, spellID, success)
    if spellID == SPELL_ID and success then
        self:RefreshSpellValues()
    end
end

function addon:OnUnitAura(_, unit)
    if unit == "player" then
        self:RefreshSpellValues()
    end
end

function addon:SlashCommand(input)
    if input and input:lower() == "options" then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
        return
    end

    if not self.displayFrame then
        self:CreateDisplay()
    end

    if self.displayFrame:IsShown() then
        self.displayFrame:Hide()
    else
        self.displayFrame:Show()
    end
end
