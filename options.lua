local addonName, addonTable = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local SharedMedia = LibStub("LibSharedMedia-3.0")
local MIN_FONT_SIZE = 8
local MAX_FONT_SIZE = 48

local function FormatExclusionList(list)
    if not list or #list == 0 then
        return L["None"]
    end

    local parts = {}
    for _, spot in ipairs(list) do
        parts[#parts + 1] = string.format("[%.2f, %.2f]", spot.x, spot.y)
    end
    return table.concat(parts, " ")
end

local function GetFontOptions()
    local fonts = {}
    for _, fontName in ipairs(SharedMedia:List("font")) do
        fonts[fontName] = fontName
    end

    return fonts
end

function addonTable.RegisterOptions(addon)
    local options = {
        type = "group",
        name = L["Bears Boon Viewer"],
        args = {
            showBoonPins = {
                type = "toggle",
                order = 0,
                width = "full",
                name = L["Show Mislaid Curiosity treasure chest pins"],
                desc = L["Enable minimap pins to show potential locations."],
                get = function()
                    return addon.db.profile.showBoonPins
                end,
                set = function(_, value)
                    addon.db.profile.showBoonPins = value
                    addon:GetModule("Scanner"):UpdateActivity()
                end,
            },
            useExclusions = {
                type = "toggle",
                order = 0.5,
                width = "full",
                name = L["Use exclusions"],
                desc = L["Hide hidden chests near the excluded locations on the Labyrinth map."],
                get = function()
                    return addon.db.profile.useExclusions ~= false
                end,
                set = function(_, value)
                    addon.db.profile.useExclusions = value
                    local scanner = addon:GetModule("Scanner")
                    if scanner.scanning then
                        scanner:ScanVignettes()
                    end
                end,
            },
            scanInterval = {
                type = "range",
                order = 1,
                width = "full",
                name = L["Scan interval (seconds)"],
                desc = L["How often to scan for Mislaid Curiosities."],
                min = 0.5,
                max = 10,
                step = 0.5,
                get = function()
                    return addon.db.profile.scanInterval or 2.0
                end,
                set = function(_, value)
                    addon.db.profile.scanInterval = value
                end,
            },
            font = {
                type = "select",
                order = 1,
                width = "full",
                name = L["Font"],
                desc = L["Choose a font registered with LibSharedMedia."],
                values = GetFontOptions,
                get = function()
                    return addon.db.profile.font
                end,
                set = function(_, value)
                    addon.db.profile.font = value
                    addon:UpdateDisplay()
                end,
            },
            fontSpacing = {
                type = "description",
                order = 2,
                width = "full",
                name = " ",
                fontSize = "small",
            },
            decreaseFontSize = {
                type = "execute",
                order = 3,
                width = "relative",
                relWidth = 0.11,
                name = L["Smaller"],
                desc = L["Decrease the display text size by one pixel."],
                func = function()
                    addon.db.profile.fontSize = math.max(MIN_FONT_SIZE, addon.db.profile.fontSize - 1)
                    addon:UpdateDisplay()
                end,
            },
            -- Flow layout stacks children with no spacing, so empty fixed-
            -- fraction descriptions act as gaps. All widths in this row are
            -- relative fractions that sum to 0.99 so the row can never wrap,
            -- and the slider (0.73) absorbs everything the buttons/gaps leave.
            fontSizeGapLeft = {
                type = "description",
                order = 4,
                width = "relative",
                relWidth = 0.02,
                name = "",
            },
            fontSize = {
                type = "range",
                order = 5,
                width = "relative",
                relWidth = 0.73,
                name = L["Font size"],
                desc = L["Set the display text size in pixels."],
                min = MIN_FONT_SIZE,
                max = MAX_FONT_SIZE,
                step = 1,
                get = function()
                    return addon.db.profile.fontSize
                end,
                set = function(_, value)
                    addon.db.profile.fontSize = value
                    addon:UpdateDisplay()
                end,
            },
            fontSizeGapRight = {
                type = "description",
                order = 6,
                width = "relative",
                relWidth = 0.02,
                name = "",
            },
            increaseFontSize = {
                type = "execute",
                order = 7,
                width = "relative",
                relWidth = 0.11,
                name = L["Larger"],
                desc = L["Increase the display text size by one pixel."],
                func = function()
                    addon.db.profile.fontSize = math.min(MAX_FONT_SIZE, addon.db.profile.fontSize + 1)
                    addon:UpdateDisplay()
                end,
            },
            fontColorSpacing = {
                type = "description",
                order = 8,
                width = "full",
                name = " ",
                fontSize = "small",
            },
            fontColor = {
                type = "color",
                order = 9,
                width = "full",
                name = L["Font color"],
                desc = L["Choose the display text color."],
                hasAlpha = false,
                get = function()
                    local color = addon.db.profile.fontColor
                    return color.r, color.g, color.b
                end,
                set = function(_, red, green, blue)
                    local color = addon.db.profile.fontColor
                    color.r = red
                    color.g = green
                    color.b = blue
                    addon:UpdateDisplay()
                end,
            },
            pinColor = {
                type = "color",
                order = 100,
                width = "full",
                name = L["Pin color"],
                desc = L["Choose the color of Mislaid Curiosity pins."],
                hasAlpha = false,
                get = function()
                    local color = addon.db.profile.pinColor
                    if type(color) ~= "table" then
                        color = { r = 0, g = 1, b = 0 }
                    end
                    return color.r, color.g, color.b
                end,
                set = function(_, red, green, blue)
                    local color = addon.db.profile.pinColor
                    if type(color) ~= "table" then
                        color = { r = 0, g = 1, b = 0 }
                        addon.db.profile.pinColor = color
                    end
                    color.r = red
                    color.g = green
                    color.b = blue
                    local scanner = addon:GetModule("Scanner")
                    scanner:RefreshMapPins()
                    if scanner.scanning then
                        scanner:DrawPins()
                    end
                end,
            },
            exclusionHeader = {
                type = "header",
                order = 200,
                name = L["Excluded hidden chest locations"],
            },
            exclusionList = {
                type = "description",
                order = 201,
                width = "full",
                fontSize = "medium",
                name = function()
                    return FormatExclusionList(addon.db.profile.hexmaskExclusions)
                end,
            },
            excludeCurrentLocation = {
                type = "execute",
                order = 203,
                width = "relative",
                relWidth = 0.48,
                name = L["Exclude Current Location"],
                desc = L["Add your current map position to the exclusion list."],
                func = function()
                    addon:AddCurrentLocationExclusion()
                end,
            },
            buttonSpacer = {
                type = "description",
                order = 204,
                width = "relative",
                relWidth = 0.02,
                name = "",
            },
            includeCurrentLocation = {
                type = "execute",
                order = 205,
                width = "relative",
                relWidth = 0.48,
                name = L["Include Current Location"],
                desc = L["Remove exclusions near your current map position."],
                func = function()
                    addon:RemoveCurrentLocationExclusions()
                end,
            },
            exportExclusions = {
                type = "execute",
                order = 210,
                width = "full",
                name = L["Export Exclusions"],
                desc = L["Show the exclusion list as text you can copy."],
                func = function()
                    local parts = {}
                    for _, spot in ipairs(addon.db.profile.hexmaskExclusions) do
                        parts[#parts + 1] = string.format("[%.2f, %.2f]", spot.x, spot.y)
                    end
                    addon:ShowExportWindow(L["Exclusion Export"], table.concat(parts, " "))
                end,
            },
            clearExclusions = {
                type = "execute",
                order = 207,
                width = "relative",
                relWidth = 0.48,
                name = L["Clear Exclusions"],
                desc = L["Remove all excluded chest locations."],
                func = function()
                    wipe(addon.db.profile.hexmaskExclusions)
                    addon:Print(L["Exclusion list cleared."])
                    local scanner = addon:GetModule("Scanner")
                    if scanner.scanning then
                        scanner:ScanVignettes()
                    end
                    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
                end,
            },
            loadDefaultsSpacer = {
                type = "description",
                order = 208,
                width = "relative",
                relWidth = 0.02,
                name = "",
            },
            loadDefaultExclusions = {
                type = "execute",
                order = 209,
                width = "relative",
                relWidth = 0.48,
                name = L["Load Default Exclusions"],
                desc = L["Replace the exclusion list with the built-in defaults."],
                func = function()
                    addon:LoadDefaultExclusions()
                    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
                end,
            },
        },
    }

    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    AceConfigRegistry:RegisterOptionsTable(addonName, options)
    AceConfigDialog:AddToBlizOptions(addonName, L["Bears Boon Viewer"])

    local previewButton

    local function TogglePreview()
        if not addon.displayFrame then
            addon:CreateDisplay()
        end
        addon:UpdateDisplay()
        if addon.displayFrame and addon.displayFrame:IsShown() then
            addon.viewerManuallyClosed = true
            addon.waitingForBoon = false
            addon.displayFrame:Hide()
        elseif addon.displayFrame then
            addon.viewerManuallyClosed = false
            addon.waitingForBoon = false
            addon.displayFrame:Show()
        end
    end

    local function CreatePreviewButton()
        if not AceConfigDialog.OpenFrames then
            return
        end
        local frame = AceConfigDialog.OpenFrames[addonName]
        if not frame then
            return
        end
        local parent = frame.frame or frame
        if not parent then
            return
        end
        if previewButton and previewButton:GetParent() == parent then
            return
        end
        if previewButton then
            previewButton:Hide()
            previewButton:SetParent(nil)
            previewButton = nil
        end
        previewButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        previewButton:SetSize(90, 22)
        previewButton:SetText(L["Live Preview"])
        previewButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -8)
        previewButton:SetScript("OnClick", TogglePreview)
        previewButton:Show()
    end

    local origOpen = AceConfigDialog.Open
    AceConfigDialog.Open = function(self, appName, ...)
        local ret = origOpen(self, appName, ...)
        if appName == addonName then
            if C_Timer and C_Timer.After then
                C_Timer.After(0, CreatePreviewButton)
            else
                CreatePreviewButton()
            end
        end
        return ret
    end

    addon.OpenOptionsDialog = function()
        AceConfigDialog:Open(addonName)
        if C_Timer and C_Timer.After then
            C_Timer.After(0, CreatePreviewButton)
        else
            CreatePreviewButton()
        end
    end
end
