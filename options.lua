local addonName, addonTable = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local SharedMedia = LibStub("LibSharedMedia-3.0")
local MIN_FONT_SIZE = 8
local MAX_FONT_SIZE = 48

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
            fontSize = {
                type = "range",
                order = 3,
                width = "full",
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
            decreaseFontSize = {
                type = "execute",
                order = 4,
                width = 0.48,
                name = L["Smaller"],
                desc = L["Decrease the display text size by one pixel."],
                func = function()
                    addon.db.profile.fontSize = math.max(MIN_FONT_SIZE, addon.db.profile.fontSize - 1)
                    addon:UpdateDisplay()
                end,
            },
            increaseFontSize = {
                type = "execute",
                order = 5,
                width = 0.48,
                name = L["Larger"],
                desc = L["Increase the display text size by one pixel."],
                func = function()
                    addon.db.profile.fontSize = math.min(MAX_FONT_SIZE, addon.db.profile.fontSize + 1)
                    addon:UpdateDisplay()
                end,
            },
            fontColorSpacing = {
                type = "description",
                order = 6,
                width = "full",
                name = " ",
                fontSize = "small",
            },
            fontColor = {
                type = "color",
                order = 7,
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
        },
    }

    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    AceConfigRegistry:RegisterOptionsTable(addonName, options)
    AceConfigDialog:AddToBlizOptions(addonName, L["Bears Boon Viewer"])
    addon.OpenOptionsDialog = function()
        AceConfigDialog:Open(addonName)
    end
end
