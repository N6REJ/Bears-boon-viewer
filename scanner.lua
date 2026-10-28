local addonName, addonTable = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local addon = addonTable.addon

local scanner = addon:NewModule("Scanner")
local DELVE_DIFFICULTY_ID = 208
local LABYRINTH_MAP_ID = 2647
local CURIOSITY_VIGNETTE_ID = 5482
local DEFAULT_SCAN_INTERVAL = 2.0
local BOON_PIN_SIZE = 25
local BOON_PIN_MIN_SIZE = 16
local BOON_PIN_MAX_SIZE = 32
local REFERENCE_MINIMAP_VIEW_RADIUS = 300
local EDGE_ALPHA = 0.6
local FALLBACK_MINIMAP_SPAN = 0.18
local LOOT_DISTANCE = 0.018

local INSTANCE_EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "UPDATE_INSTANCE_INFO",
    "PLAYER_DIFFICULTY_CHANGED",
    "ACTIVE_DELVE_DATA_UPDATE",
    "WALK_IN_DATA_UPDATE",
    "VIGNETTES_UPDATED",
    "VIGNETTE_MINIMAP_UPDATED",
    "MINIMAP_UPDATE_ZOOM",
    "ADDON_LOADED",
    "WORLD_MAP_OPEN",
}

local RELATED_MAPS = {
    [2547] = { 2577, 2578 },
    [2577] = { 2547, 2578 },
    [2578] = { 2547, 2577 },
}

local FLOOR_MAP_TRANSFORMS = {
    [2577] = { a = 2.87286886, b = -0.03981183, c = 0.03981183, d = 2.87286886, tx = -1.31567616, ty = -0.50125193 },
    [2578] = { a = 2.63157150, b = -0.25947460, c = 0.25947460, d = 2.63157150, tx = -1.09713713, ty = -0.53560123 },
}

local function ProjectToMinimap(east, north, viewRadius, facing, squareMinimap)
    east, north = east / viewRadius, north / viewRadius
    if facing then
        local cosFacing, sinFacing = math.cos(facing), math.sin(facing)
        east, north = east * cosFacing - north * sinFacing, north * cosFacing + east * sinFacing
    end

    local distance = squareMinimap and math.max(math.abs(east), math.abs(north)) or math.sqrt(east * east + north * north)
    if distance > 1 then
        return east / distance, north / distance, true
    end
    return east, north, false
end

local function IsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

local function ReadVector2(value)
    if not value or IsSecret(value) then
        return nil
    end

    local ok, x, y = pcall(function()
        return value:GetXY()
    end)
    if not ok or IsSecret(x) or IsSecret(y) or type(x) ~= "number" or type(y) ~= "number" then
        return nil
    end
    return { x = x, y = y }
end

local function GetCuriosityVignetteID(vignetteGUID, vignetteInfo)
    if vignetteInfo and not IsSecret(vignetteInfo) then
        local ok, id = pcall(function()
            return vignetteInfo.vignetteID
        end)
        if ok and not IsSecret(id) and type(id) == "number" then
            return id
        end
    end
    if type(vignetteGUID) ~= "string" then
        return nil
    end

    local parts = { strsplit("-", vignetteGUID) }
    return tonumber(parts[6])
end

local function AddMapAndParents(mapIDs, seen, mapID)
    local visited = {}
    while mapID and mapID ~= 0 and not seen[mapID] and not visited[mapID] do
        visited[mapID] = true
        seen[mapID] = true
        mapIDs[#mapIDs + 1] = mapID

        local mapInfo = C_Map.GetMapInfo(mapID)
        mapID = mapInfo and mapInfo.parentMapID
    end
end

local function IsMapOrChild(mapID, ancestorMapID)
    local visited = {}
    while mapID and mapID ~= 0 and not visited[mapID] do
        if mapID == ancestorMapID then
            return true
        end
        visited[mapID] = true
        local mapInfo = C_Map.GetMapInfo(mapID)
        mapID = mapInfo and mapInfo.parentMapID
    end
    return false
end

local function GetRelatedMapIDs(uiMapID)
    local mapIDs = {}
    local seen = {}
    AddMapAndParents(mapIDs, seen, uiMapID)

    if C_Map.GetMapGroupID and C_Map.GetMapGroupMembersInfo then
        local ok, mapGroupID = pcall(C_Map.GetMapGroupID, uiMapID)
        if ok and mapGroupID then
            local membersOK, members = pcall(C_Map.GetMapGroupMembersInfo, mapGroupID)
            if membersOK and type(members) == "table" then
                for _, member in ipairs(members) do
                    if member and member.mapID then
                        AddMapAndParents(mapIDs, seen, member.mapID)
                    end
                end
            end
        end
    end

    for _, relatedMapID in ipairs(RELATED_MAPS[uiMapID] or {}) do
        AddMapAndParents(mapIDs, seen, relatedMapID)
    end

    return mapIDs
end

local function GetVignetteMapPositions(vignetteGUID, mapIDs)
    local positions = {}
    for _, mapID in ipairs(mapIDs) do
        local ok, position = pcall(C_VignetteInfo.GetVignettePosition, vignetteGUID, mapID)
        local coordinates = ok and ReadVector2(position)
        if coordinates then
            positions[mapID] = coordinates
        end
    end
    return positions
end

local function ConvertMapPosition(sourceMapID, position, mapID)
    if sourceMapID == mapID then
        return position
    end

    if C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos then
        local worldOK, continentID, worldPosition = pcall(C_Map.GetWorldPosFromMapPos, sourceMapID, position)
        local worldCoordinates = worldOK and ReadVector2(worldPosition)
        if worldCoordinates then
            local mappedOK, mappedMapID, mappedPosition = pcall(
                C_Map.GetMapPosFromWorldPos,
                continentID,
                worldPosition,
                mapID
            )
            local mappedCoordinates = mappedOK and ReadVector2(mappedPosition)
            if mappedMapID == mapID and mappedCoordinates then
                return mappedCoordinates
            end
        end
    end

    if C_Map.GetMapRectOnMap then
        local ok, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, mapID, sourceMapID)
        if ok and minX and maxX and minY and maxY and maxX > minX and maxY > minY then
            local x = (position.x - minX) / (maxX - minX)
            local y = (position.y - minY) / (maxY - minY)
            if x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                return { x = x, y = y }
            end
        end
    end
end

local function GetPositionOnMap(locations, mapID)
    local position = locations[mapID]
    if position then
        return position
    end

    local transform = FLOOR_MAP_TRANSFORMS[mapID]
    local basePosition = transform and locations[2547]
    if basePosition then
        local x = transform.a * basePosition.x + transform.b * basePosition.y + transform.tx
        local y = transform.c * basePosition.x + transform.d * basePosition.y + transform.ty
        if x >= 0 and x <= 1 and y >= 0 and y <= 1 then
            return { x = x, y = y }
        end
    end

    for sourceMapID, sourcePosition in pairs(locations) do
        position = ConvertMapPosition(sourceMapID, sourcePosition, mapID)
        if position then
            return position
        end
    end
end

local function GetPlayerMapPosition(mapID)
    if not mapID or not C_Map.GetPlayerMapPosition then
        return nil
    end

    local ok, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    return ok and ReadVector2(position) or nil
end

local function GetMinimapMapScale(mapID)
    if C_Map.GetMapWorldSize then
        local ok, width, height = pcall(C_Map.GetMapWorldSize, mapID)
        if ok and type(width) == "number" and type(height) == "number" and not IsSecret(width) and not IsSecret(height) and width > 0 and height > 0 then
            return width, height
        end
    end
end

local function GetInstanceKey()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    return tostring(instanceID or "?") .. ":" .. tostring(difficultyID or "?")
end

function scanner:OnEnable()
    self.pins = {}
    self.sparePins = {}
    self.locations = {}
    self.scanning = false
    self.inDelve = false
    self.scanned = false
    self.sinceLastScan = addon.db.profile.scanInterval or DEFAULT_SCAN_INTERVAL
    self.instanceKey = nil
    self.currentMapID = nil
    self.lastScanDetails = {
        mapLabel = L["Unknown Delve map"],
        curiosityCount = 0,
        hiddenCount = 0,
        positionCount = 0,
        mappedCount = 0,
        minimapPinCount = 0,
        mapIDsChecked = 0,
    }

    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...)
        self:OnEvent(event, ...)
    end)
    for _, event in ipairs(INSTANCE_EVENTS) do
        self.eventFrame:RegisterEvent(event)
    end
    self:UpdateActivity()
end

function scanner:OnDisable()
    self.scanning = false
    self.inDelve = false
    wipe(self.locations)
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame:SetScript("OnUpdate", nil)
    end
    self:ReleaseAllPins()
    self:RefreshMapPins()
end

function scanner:OnEvent(event, addonName)
    if event == "ADDON_LOADED" then
        if addonName == "Blizzard_WorldMap" then
            self:EnsureMapDataProvider()
            self:RefreshMapPins()
        end
        return
    elseif event == "WORLD_MAP_OPEN" then
        self:EnsureMapDataProvider()
        self:RefreshMapPins()
        return
    end

    if event == "VIGNETTES_UPDATED" or event == "VIGNETTE_MINIMAP_UPDATED" then
        if self.scanning then
            self:ScanVignettes()
            self:DrawPins()
        end
        return
    elseif event == "MINIMAP_UPDATE_ZOOM" then
        if self.scanning then
            self:DrawPins()
        end
        return
    end

    self:UpdateActivity()
end

function scanner:UpdateActivity()
    local _, instanceType, difficultyID = GetInstanceInfo()
    local uiMapID = C_Map.GetBestMapForUnit("player")
    local isDelve = difficultyID == DELVE_DIFFICULTY_ID
    local isLabyrinth = uiMapID and IsMapOrChild(uiMapID, LABYRINTH_MAP_ID)
    self.inDelve = instanceType == "scenario" and (isDelve or isLabyrinth)

    local shouldScan = self.inDelve and addon.db.profile.showBoonPins
    if shouldScan ~= self.scanning then
        self.scanning = shouldScan
        if shouldScan then
            self.sinceLastScan = addon.db.profile.scanInterval or DEFAULT_SCAN_INTERVAL
            self.eventFrame:SetScript("OnUpdate", function(_, elapsed)
                self:OnUpdate(elapsed)
            end)
        else
            self.eventFrame:SetScript("OnUpdate", nil)
            self.scanned = false
            self.instanceKey = nil
            self.currentMapID = nil
            wipe(self.locations)
            self:ReleaseAllPins()
            self:RefreshMapPins()
        end
    end
end

function scanner:OnUpdate(elapsed)
    if not self.scanning then
        return
    end

    self.sinceLastScan = self.sinceLastScan + elapsed
    local scanInterval = addon.db.profile.scanInterval or DEFAULT_SCAN_INTERVAL
    if self.sinceLastScan >= scanInterval then
        self.sinceLastScan = 0
        self:ScanVignettes()
    end

    if next(self.pins) and _G.Minimap and _G.Minimap:IsVisible() then
        self:DrawPins()
    end
end

function scanner:CreateBoonPin(vignetteGUID)
    local pin = table.remove(self.sparePins)
    if not pin then
        pin = CreateFrame("Frame", nil, _G.Minimap)
        pin:SetSize(BOON_PIN_SIZE, BOON_PIN_SIZE)
        local strata = _G.Minimap:GetFrameStrata()
        pin:SetFrameStrata(strata)
        pin:SetFrameLevel(_G.Minimap:GetFrameLevel() + 3)
        pin:SetFixedFrameLevel(true)
        pin:EnableMouse(true)
        pin:SetMouseClickEnabled(false)
        pin:SetScript("OnEnter", function(frame)
            GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Potential Mislaid Curiosity"], 1, 1, 1)
            GameTooltip:AddLine(L["Detected from a Mislaid Curiosity vignette."], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        pin:SetScript("OnLeave", GameTooltip_Hide)

        local texture = pin:CreateTexture(nil, "OVERLAY")
        texture:SetAllPoints()
        texture:SetAtlas("VignetteLoot")
        texture:SetVertexColor(1.0, 0.1, 0.1, 1.0)
        texture:SetSnapToPixelGrid(true)
        texture:SetTexelSnappingBias(0)
    end

    pin.vignetteGUID = vignetteGUID
    self.pins[vignetteGUID] = pin
    return pin
end

function scanner:ReleasePin(vignetteGUID)
    local pin = self.pins[vignetteGUID]
    if not pin then
        return
    end

    pin:Hide()
    pin:ClearAllPoints()
    self.pins[vignetteGUID] = nil
    table.insert(self.sparePins, pin)
end

function scanner:ReleaseAllPins()
    if not self.pins then
        return
    end
    for vignetteGUID in pairs(self.pins) do
        self:ReleasePin(vignetteGUID)
    end
end

function scanner:EnsureMapDataProvider()
    if self.mapDataProvider or not _G.WorldMapFrame or not MapCanvasDataProviderMixin then
        return
    end

    local provider = CreateFromMixins(MapCanvasDataProviderMixin)
    function provider:RemoveAllData()
        if _G.WorldMapFrame then
            _G.WorldMapFrame:RemoveAllPinsByTemplate("BearsBoonFinderMapPinTemplate")
        end
    end
    function provider:RefreshAllData()
        self:RemoveAllData()
        if not scanner.inDelve or not addon.db.profile.showBoonPins then
            return
        end

        local mapID = _G.WorldMapFrame:GetMapID()
        if not mapID then
            return
        end

        for _, location in pairs(scanner.locations) do
            local position = GetPositionOnMap(location.maps, mapID)
            if position then
                local pin = _G.WorldMapFrame:AcquirePin("BearsBoonFinderMapPinTemplate", location)
                pin:SetPosition(position.x, position.y)
                pin:SetScript("OnEnter", function(frame)
                    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                    GameTooltip:SetText(L["Potential Mislaid Curiosity"], 1, 1, 1)
                    GameTooltip:AddLine(L["Detected from a Mislaid Curiosity vignette."], 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                pin:SetScript("OnLeave", GameTooltip_Hide)
            end
        end
    end

    self.mapDataProvider = provider
    _G.WorldMapFrame:AddDataProvider(provider)
end

function scanner:RefreshMapPins()
    self:EnsureMapDataProvider()
    if self.mapDataProvider then
        self.mapDataProvider:RefreshAllData()
    end
end

function scanner:ScanVignettes()
    local uiMapID = C_Map.GetBestMapForUnit("player")
    local mapInfo = uiMapID and C_Map.GetMapInfo(uiMapID)
    local mapLabel = mapInfo and mapInfo.name or L["Unknown Delve map"]
    if uiMapID then
        mapLabel = string.format("%s (%s)", mapLabel, tostring(uiMapID))
    end

    local instanceKey = GetInstanceKey()
    if self.instanceKey and self.instanceKey ~= instanceKey then
        wipe(self.locations)
        self:ReleaseAllPins()
    end
    self.instanceKey = instanceKey
    self.currentMapID = uiMapID

    local mapIDs = uiMapID and GetRelatedMapIDs(uiMapID) or {}
    local curiosityCount = 0
    local hiddenCount = 0
    local positionCount = 0
    local mappedCount = 0
    local vignettes = C_VignetteInfo.GetVignettes() or {}
    local live = {}

    for _, vignetteGUID in ipairs(vignettes) do
        local ok, vignetteInfo = pcall(C_VignetteInfo.GetVignetteInfo, vignetteGUID)
        if not ok then
            vignetteInfo = nil
        end
        if GetCuriosityVignetteID(vignetteGUID, vignetteInfo) == CURIOSITY_VIGNETTE_ID then
            curiosityCount = curiosityCount + 1
            if not vignetteInfo then
                hiddenCount = hiddenCount + 1
            end

            live[vignetteGUID] = true
            local location = self.locations[vignetteGUID] or { maps = {} }
            local positions = GetVignetteMapPositions(vignetteGUID, mapIDs)
            local hasPosition = next(positions) ~= nil
            for mapID, position in pairs(positions) do
                location.maps[mapID] = position
            end
            if hasPosition then
                positionCount = positionCount + 1
            end
            self.locations[vignetteGUID] = location
        end
    end

    local playerPosition = GetPlayerMapPosition(uiMapID)
    if playerPosition then
        for vignetteGUID, location in pairs(self.locations) do
            if not live[vignetteGUID] then
                local targetPosition = GetPositionOnMap(location.maps, uiMapID)
                if targetPosition then
                    local dx = targetPosition.x - playerPosition.x
                    local dy = targetPosition.y - playerPosition.y
                    if math.sqrt(dx * dx + dy * dy) <= LOOT_DISTANCE then
                        self.locations[vignetteGUID] = nil
                        self:ReleasePin(vignetteGUID)
                    end
                end
            end
        end
    end

    for _, location in pairs(self.locations) do
        if uiMapID and GetPositionOnMap(location.maps, uiMapID) then
            mappedCount = mappedCount + 1
        end
    end

    self.lastScanDetails.mapLabel = mapLabel
    self.lastScanDetails.curiosityCount = curiosityCount
    self.lastScanDetails.hiddenCount = hiddenCount
    self.lastScanDetails.positionCount = positionCount
    self.lastScanDetails.mappedCount = mappedCount
    self.lastScanDetails.mapIDsChecked = #mapIDs
    self.scanned = true
    self:DrawPins()
    self:RefreshMapPins()
end

function scanner:DrawPins()
    local minimap = _G.Minimap
    local mapID = self.currentMapID
    local playerPosition = GetPlayerMapPosition(mapID)
    if not minimap or not playerPosition then
        for _, pin in pairs(self.pins) do
            pin:Hide()
        end
        self.lastScanDetails.minimapPinCount = 0
        return
    end

    local rotateMinimap = GetCVarBool("rotateMinimap")
    local facing
    if rotateMinimap and type(GetPlayerFacing) == "function" then
        local ok, value = pcall(GetPlayerFacing)
        if ok and not IsSecret(value) and type(value) == "number" then
            facing = value
        end
    end
    local squareMinimap = _G.GetMinimapShape and _G.GetMinimapShape() == "SQUARE"
    local minimapWidth, minimapHeight = minimap:GetWidth(), minimap:GetHeight()
    local halfWidth, halfHeight = minimapWidth / 2, minimapHeight / 2
    local mapWorldWidth, mapWorldHeight = GetMinimapMapScale(mapID)
    if mapWorldWidth and IsSecret(mapWorldWidth) then mapWorldWidth = nil end
    if mapWorldHeight and IsSecret(mapWorldHeight) then mapWorldHeight = nil end
    local viewRadius = C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()
    if viewRadius and IsSecret(viewRadius) then viewRadius = nil end
    local minimapZoom = (minimap.GetZoom and minimap:GetZoom()) or 0
    if type(minimapZoom) ~= "number" or IsSecret(minimapZoom) then minimapZoom = 0 end
    local useWorldScale = mapWorldWidth and mapWorldHeight and type(viewRadius) == "number" and viewRadius > 0
    local iconSize = 20
    local projectionScale
    if useWorldScale then
        projectionScale = viewRadius
    else
        -- Keep the fallback span responsive to minimap zoom so pins still
        -- move with zoom when world scale data is unavailable.
        projectionScale = FALLBACK_MINIMAP_SPAN / (1 + minimapZoom * 0.35)
        if projectionScale <= 0 then
            projectionScale = FALLBACK_MINIMAP_SPAN
        end
    end
    local activePins = {}
    local mappedCount = 0
    local minimapPinCount = 0
    local pinHalfWidth = math.max(0, halfWidth - iconSize / 2)
    local pinHalfHeight = math.max(0, halfHeight - iconSize / 2)
    for vignetteGUID, location in pairs(self.locations) do
        local targetPosition = GetPositionOnMap(location.maps, mapID)
        if targetPosition then
            mappedCount = mappedCount + 1
            local east = targetPosition.x - playerPosition.x
            local north = playerPosition.y - targetPosition.y
            if useWorldScale then
                east, north = east * mapWorldWidth, north * mapWorldHeight
            end
            local relativeDistance
            if squareMinimap then
                relativeDistance = math.max(math.abs(east), math.abs(north)) / projectionScale
            else
                relativeDistance = math.sqrt(east * east + north * north) / projectionScale
            end
            if relativeDistance <= 1.15 then
                local pin = self.pins[vignetteGUID] or self:CreateBoonPin(vignetteGUID)
                pin:SetSize(iconSize, iconSize)
                local x, y, onEdge = ProjectToMinimap(east, north, projectionScale, facing, squareMinimap)
                pin:ClearAllPoints()
                pin:SetPoint("CENTER", minimap, "CENTER", x * pinHalfWidth, y * pinHalfHeight)
                pin:SetAlpha(onEdge and EDGE_ALPHA or 1)
                pin:Show()
                activePins[vignetteGUID] = true
                minimapPinCount = minimapPinCount + 1
            end
        end
    end

    for vignetteGUID, pin in pairs(self.pins) do
        if not activePins[vignetteGUID] then
            pin:Hide()
        end
    end
    self.lastScanDetails.mappedCount = mappedCount
    self.lastScanDetails.minimapPinCount = minimapPinCount
end

function scanner:GetStatus()
    if not self.inDelve then
        return L["Enter a Delve or Labyrinth to look for Mislaid Curiosities."]
    end
    if not addon.db.profile.showBoonPins then
        return L["Mislaid Curiosity pins are disabled."]
    end
    return L["Scanning this Delve or Labyrinth for Mislaid Curiosities."]
end

function scanner:GetSummary()
    if not self.inDelve then
        return L["Mislaid Curiosity pins are only shown inside a Delve or Labyrinth."]
    end
    if not addon.db.profile.showBoonPins then
        return L["Enable minimap pins to show potential locations."]
    end
    if not self.scanned then
        return L["Waiting for the first location scan."]
    end

    if self.lastScanDetails.mappedCount > 0 then
        return string.format(
            L["Mapped Mislaid Curiosities: %d; treasure chest pins nearby: %d."],
            self.lastScanDetails.mappedCount,
            self.lastScanDetails.minimapPinCount
        )
    end

    local details = self.lastScanDetails
    return string.format(
        L["No mapped Mislaid Curiosities found on %s. Curiosity vignettes: %d; hidden: %d; positions: %d; mapped: %d; maps checked: %d."],
        details.mapLabel,
        details.curiosityCount,
        details.hiddenCount,
        details.positionCount,
        details.mappedCount,
        details.mapIDsChecked
    )
end

function scanner:Scan()
    if not self.inDelve then
        return false, L["Enter a Delve or Labyrinth to look for Mislaid Curiosities."]
    end
    if not addon.db.profile.showBoonPins then
        return false, L["Enable minimap pins to show potential locations."]
    end

    self:ScanVignettes()
    return true, self:GetSummary()
end