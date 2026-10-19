local addonName, addonTable = ...

local AceAddon = LibStub("AceAddon-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local SPELL_ID = 1280098
local BOON_ICON = "Interface\\Icons\\spell_azerite_essence08"
local defaultFontName = "2002 Bold"

local MIN_FRAME_WIDTH = 240
local MIN_FRAME_HEIGHT = 90
local MAX_FRAME_WIDTH = 900
local FRAME_CHROME_WIDTH = 34
local FRAME_CONTENT_BOTTOM_INSET = 16
local FRAME_CHROME_HEIGHT = 27 + FRAME_CONTENT_BOTTOM_INSET + 4
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

local FALLBACK_FONT_PATH = "Fonts\\FRIZQT__.TTF"

-- Resolve a LibSharedMedia font name to a path that is safe to hand to
-- FontString:SetFont. A missing/legacy font file (e.g. the stock "2002 Bold"
-- -> Fonts\2002B.TTF mapping when ElvUI is not present to supply media) makes
-- SetFont throw, which would kill UpdateDisplay and prevent the viewer from
-- ever showing. Fall back gracefully instead of erroring.
local function SetFontSafe(fontString, fontName, size)
    local path = SharedMedia:Fetch("font", fontName)
        or SharedMedia:Fetch("font", defaultFontName)
        or FALLBACK_FONT_PATH
    if not pcall(fontString.SetFont, fontString, path, size, "") then
        pcall(fontString.SetFont, fontString, FALLBACK_FONT_PATH, size, "")
    end
    return path
end

local addon = AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
    profile = {
        font = defaultFontName,
        fontSize = 12,
        fontColor = {
            r = 1,
            g = 1,
            b = 1,
        },
        frame = {
            width = MIN_FRAME_WIDTH,
            height = MIN_FRAME_HEIGHT,
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

local function GetBoonValues()
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(SPELL_ID)
    if not aura or not aura.auraInstanceID then
        return nil
    end

    local tooltipData = C_TooltipInfo.GetUnitAuraByAuraInstanceID("player", aura.auraInstanceID)
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
                lines[#lines + 1] = text:gsub("%.$", "")
            end
        end
    end

    if #lines > 0 then
        return table.concat(lines, "\n")
    end

    return nil
end

function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BearsBoonViewerDB", defaults, true)
    self.waitingForBoon = false
    self.hasBoonValues = false
    self.lastBoonValues = nil
    self.viewerManuallyClosed = false
    self.boonRefreshRetryID = 0
    local savedFont = self.db.profile.font:lower()
    for fontName, fontPath in pairs(SharedMedia:HashTable("font")) do
        if fontPath:lower() == savedFont then
            self.db.profile.font = fontName
            break
        end
    end

    _G.SLASH_BEARBoonViewer1 = "/boon"
    _G.SlashCmdList.BEARBoonViewer = function()
        self:SlashCommand()
    end
    addonTable.RegisterOptions(self)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnActivityChanged")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnActivityChanged")
    self:RegisterEvent("ZONE_CHANGED", "OnActivityChanged")
    self:RegisterEvent("PLAYER_DIFFICULTY_CHANGED", "OnActivityChanged")
    self:RegisterEvent("ACTIVE_DELVE_DATA_UPDATE", "OnActivityChanged")
    self:RegisterEvent("WALK_IN_DATA_UPDATE", "OnActivityChanged")
    self:RegisterEvent("SPELLS_CHANGED", "RefreshSpellValues")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "RefreshSpellValues")
    self:RegisterEvent("PLAYER_TALENT_UPDATE", "RefreshSpellValues")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "RefreshSpellValues")
    self:RegisterEvent("UNIT_AURA", "OnUnitAura")
    self:Print("Loaded. Type /boon to open options.")
end

function addon:OnEnable()
    self:CreateDisplay()
    self:CreateMinimapButton()
    self:ScheduleDefaultPosition()
    self:OnActivityChanged()
end

function addon:CreateMinimapButton()
    if self.minimapButton or not _G.Minimap then
        return
    end

    local button = CreateFrame("Button", "BearsBoonViewerMinimapButton", _G.Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(_G.Minimap:GetFrameLevel() + 5)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local radius = _G.Minimap:GetWidth() / 2 + 4
    local angle = math.rad(225)
    button:SetPoint("CENTER", _G.Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(50, 50)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetVertexColor(1, 0.82, 0.2)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(24, 24)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("CENTER", button, "CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(BOON_ICON)
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", button, "CENTER")
    button.icon = icon

    button:SetScript("OnEnter", function(buttonFrame)
        GameTooltip:SetOwner(buttonFrame, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Bears Boon Viewer"])
        GameTooltip:AddLine(L["Click to show the boon viewer."])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function()
        if self:UpdateDisplay() then
            self.viewerManuallyClosed = false
            self.displayFrame:Show()
            self.waitingForBoon = false
        end
    end)

    self.minimapButton = button
end

function addon:CreateDisplay()
    if self.displayFrame then
        return
    end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle(L["Bears Boon Viewer"])
    frame:SetLayout("Flow")
    frame:SetStatusTable(self.db.profile.frame)
    frame:EnableResize(false)
    local nativeFrame = rawget(frame, "frame")
    nativeFrame:SetResizeBounds(MIN_FRAME_WIDTH, MIN_FRAME_HEIGHT)

    -- Improve default UI compatibility
    nativeFrame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    nativeFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    nativeFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    local content = rawget(frame, "content")
    content:ClearAllPoints()
    -- Use more universal padding values
    content:SetPoint("TOPLEFT", 16, -28)
    content:SetPoint("BOTTOMRIGHT", -16, 14)

    -- Hide status bar for cleaner look
    local statustext = rawget(frame, "statustext")
    if statustext then
        statustext:GetParent():Hide()
    end

    -- Hide default frame buttons more reliably
    for _, child in ipairs({ nativeFrame:GetChildren() }) do
        if child:GetObjectType() == "Button" then
            local text = child:GetText()
            if text == CLOSE or child:GetHeight() == 24 then
                child:Hide()
            end
        end
    end

    local closeButton = CreateFrame("Button", nil, nativeFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", nativeFrame, "TOPRIGHT", 2, 1)
    closeButton:SetScript("OnClick", function()
        self.viewerManuallyClosed = true
        self.waitingForBoon = false
        frame:Hide()
    end)

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
        return false
    end

    local profile = self.db.profile
    local color = profile.fontColor
    local valuesText = GetBoonValues()
    if not valuesText then
        self.hasBoonValues = false
        self.lastBoonValues = nil
        self.waitingForBoon = true
        self.displayFrame:Hide()
        return false
    end
    local boonValuesBecameAvailable = not self.hasBoonValues
    local boonValuesChanged = self.lastBoonValues ~= nil and self.lastBoonValues ~= valuesText
    self.hasBoonValues = true
    self.lastBoonValues = valuesText

    SetFontSafe(self.valueLabel, profile.font, profile.fontSize)
    self.valueLabel:SetColor(color.r, color.g, color.b)
    self.valueLabel:SetText(valuesText)

    local measureText = self.measureText
    SetFontSafe(measureText, profile.font, profile.fontSize)

    local widestLine = 0
    for line in valuesText:gmatch("[^\n]+") do
        measureText:SetWordWrap(false)
        measureText:SetText(line)
        widestLine = math.max(widestLine, measureText:GetStringWidth())
    end

    local contentWidth = math.min(MAX_FRAME_WIDTH - FRAME_CHROME_WIDTH, widestLine)
    contentWidth = math.max(MIN_FRAME_WIDTH - FRAME_CHROME_WIDTH, contentWidth)
    self.displayFrameWidth = contentWidth + FRAME_CHROME_WIDTH

    self.displayFrame:SetWidth(self.displayFrameWidth)
    self.valueLabel:SetWidth(contentWidth)
    self.displayFrame:DoLayout()
    self.valueLabel:SetWidth(contentWidth)

    measureText:SetWordWrap(true)
    measureText:SetWidth(contentWidth)
    measureText:SetText(valuesText)
    local contentHeight = math.max(profile.fontSize, measureText:GetStringHeight())
    self.displayFrame:SetHeight(contentHeight + FRAME_CHROME_HEIGHT)
    self:PositionFrameByDefault(self.displayFrameWidth)
    return true, boonValuesBecameAvailable, boonValuesChanged
end

-- AceGUI's Frame widget saves drag positions as absolute coordinates
-- (status.left/top) and reapplies them on show. Coordinates saved under one
-- UI scale/layout (e.g. dragged into place while ElvUI was active) land
-- off-screen under another, so the frame is technically shown but invisible.
local function IsSavedFramePositionVisible(position, frameWidth, frameHeight)
    local left = position.left
    local top = position.top
    if not left or not top then
        return false
    end

    local uiWidth, uiHeight = UIParent:GetSize()
    if not uiWidth or uiWidth == 0 then
        return true
    end

    -- status.left/top are applied as offsets from UIParent's bottom-left, so
    -- test the frame's center in that same coordinate space.
    local centerX = left + frameWidth / 2
    local centerY = top - frameHeight / 2
    return centerX >= 0 and centerX <= uiWidth
        and centerY >= 0 and centerY <= uiHeight
end

function addon:PositionFrameByDefault(frameWidth)
    local position = self.db.profile.frame
    if position.left and position.top then
        -- AceGUI's Frame widget has no GetHeight; read the native frame.
        local nativeFrame = self.displayFrame and rawget(self.displayFrame, "frame")
        local frameHeight = nativeFrame and nativeFrame:GetHeight() or MIN_FRAME_HEIGHT
        if IsSavedFramePositionVisible(position, frameWidth or MIN_FRAME_WIDTH, frameHeight) then
            return true
        end
        -- Saved position is off-screen under the current UI scale; discard it
        -- and re-anchor to the default spot beside the minimap.
        position.left = nil
        position.top = nil
    end

    local map = _G.Minimap
    local mapLeft = map and map:GetLeft()
    local mapTop = map and map:GetTop()
    if not mapLeft or not mapTop then
        return false
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
    return true
end

function addon:ScheduleDefaultPosition()
    if self.positionTimer then
        return
    end

    local attempts = 0
    local timer
    timer = C_Timer.NewTicker(0.5, function()
        attempts = attempts + 1
        local frameWidth = self.displayFrameWidth or MIN_FRAME_WIDTH
        if self:PositionFrameByDefault(frameWidth) or attempts >= 40 then
            timer:Cancel()
            self.positionTimer = nil
        end
    end)
    self.positionTimer = timer
end

function addon:RefreshSpellValues()
    if not self.displayFrame then
        return false
    end

    -- The Boons aura is the source of truth for visibility, not the delve
    -- activity APIs. C_DelvesUI.HasActiveDelve is restricted in Midnight
    -- (secret values) and can false-negative right when a boon is picked up,
    -- which previously blocked auto-open while the minimap button (which
    -- never checked activity) kept working. The aura only exists inside a
    -- delve and is removed on leave, so values-present == should-be-shown.
    local hasValues, boonValuesBecameAvailable, boonValuesChanged = self:UpdateDisplay()
    if not hasValues then
        return false
    end

    local shouldShow = (self.waitingForBoon and not self.viewerManuallyClosed)
        or (self.viewerManuallyClosed and boonValuesChanged)
        or boonValuesBecameAvailable
    if shouldShow then
        self.displayFrame:Show()
        self.viewerManuallyClosed = false
        self.waitingForBoon = false
    end
    return true
end

function addon:OnActivityChanged()
    if not self.displayFrame then
        return
    end

    self:ScheduleDefaultPosition()
    local hasValues = self:RefreshSpellValues()
    if hasValues and not self.viewerManuallyClosed then
        self.displayFrame:Show()
        self.waitingForBoon = false
    end
end

function addon:OnUnitAura(_, unit)
    if unit ~= "player" then
        return
    end

    -- No delve/lair activity check here: the Boons aura itself proves a boon
    -- was picked up. Gating on C_DelvesUI broke auto-open (restricted/false-
    -- negative results) while the minimap button kept working.
    local hasValues = self:RefreshSpellValues()
    if hasValues and not self.viewerManuallyClosed then
        self.boonRefreshRetryID = (self.boonRefreshRetryID or 0) + 1
        return
    end

    self.boonRefreshRetryID = (self.boonRefreshRetryID or 0) + 1
    local retryID = self.boonRefreshRetryID
    local attempts = 0
    local function retryRefresh()
        if retryID ~= self.boonRefreshRetryID or self.displayFrame:IsShown() then
            return
        end

        attempts = attempts + 1
        local hasCurrentValues = self:RefreshSpellValues()
        if (not hasCurrentValues or self.viewerManuallyClosed) and attempts < 10 then
            C_Timer.After(0.25, retryRefresh)
        end
    end
    C_Timer.After(0.25, retryRefresh)
end

function addon:SlashCommand()
    rawget(self, "OpenOptionsDialog")()
end
