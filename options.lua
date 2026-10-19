local addonName, addonTable = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local SharedMedia = LibStub("LibSharedMedia-3.0")

function addonTable.RegisterOptions(addon)
    local options = {
        type = "group",
        name = L["Bears Boon Viewer"],
        args = {
            font = {
                type = "select",
                order = 1,
                name = L["Font"],
                desc = L["Choose a font registered with LibSharedMedia."],
                values = function()
                    return SharedMedia:HashTable("font")
                end,
                get = function()
                    return addon.db.profile.font
                end,
                set = function(_, value)
                    addon.db.profile.font = value
                    addon:UpdateDisplay()
                end,
            },
            fontSize = {
                type = "range",
                order = 2,
                name = L["Font size"],
                desc = L["Set the display text size in pixels."],
                min = 8,
                max = 72,
                step = 1,
                get = function()
                    return addon.db.profile.fontSize
                end,
                set = function(_, value)
                    addon.db.profile.fontSize = value
                    addon:UpdateDisplay()
                end,
            },
            fontColor = {
                type = "color",
                order = 3,
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

    local AceConfig = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    AceConfig:RegisterOptionsTable(addonName, options)
    AceConfigDialog:AddToBlizOptions(addonName, L["Bears Boon Viewer"])
end
