-- search for ==IMPLEMENT== for places with incomplete code
--
--
-- This is the name of the file with the legacy events
-- If you want to parse the legacy events at the time the 
-- scenario is run, use "getLegacyEvents"
-- note: ignore the .lua part of the file name
local legacyEventTableName = "getLegacyEvents"

local eventsPath = string.gsub(debug.getinfo(1).source, "@", "")
local scenarioFolderPath = string.gsub(eventsPath, "legacyEventEngine.lua", "?.lua")
if string.find(package.path, scenarioFolderPath, 1, true) == nil then
   package.path = package.path .. ";" .. scenarioFolderPath
end
--print(debug.getinfo(1).source)
--print(eventsPath)
--print(scenarioFolderPath)
--print(package.path)

local eventTable = require(legacyEventTableName)
local civlua = require("civlua")
local func = require("functions")

-- legacyEventEngine accesses the state table through the global variable 
-- g_LegacyState
-- This is now a local variable, which can be linked using a linkState function
-- I haven't yet removed the g_ from the variable name, but I will do so at some point
-- (it can be automated, but I don't want to test)
local g_LegacyState = nil
local function linkState(table)
    if type(table)=="table" then
        g_LegacyState = table
    else
        error("legacy.linkState: linkState requires a table as the argument.")
    end
end




-- string to object converters (none are case dependant)
--
-- If true, Lua will produce an error if a string
-- search doesn't find anything
local failSearchWithError=false
-- stringToTribe(string)
local function stringToTribe(inputString,triggerAttackerName,triggerDefenderName,triggerReceiverName)
    if civ.isTribe(inputString) then
        return inputString
    end
    if string.lower(inputString) == "triggerattacker" then
        inputString = triggerAttackerName
    elseif string.lower(inputString) == "triggerdefender" then
        inputString = triggerDefenderName
    elseif string.lower(inputString) == "triggerreceiver" then
        inputString = triggerReceiverName
    end
    if inputString ~= nil then
        for i=0,7 do
            if civ.getTribe(i) and string.lower(civ.getTribe(i).name) == string.lower(inputString) then
                return civ.getTribe(i)
            end
        end
        if failSearchWithError then
            error(inputString.." does not match the name of a tribe in the game.")
        end
    end
    return nil
end


local function stringToCity(inputString)
    if string.lower(inputString) == "none" then
        return nil
    end
    for city in civ.iterateCities() do
        if string.lower(city.name) == string.lower(inputString) then
            return city
        end
    end
    if failSearchWithError then
        error(inputString.." does not match the name of a city in the game.")
    end
    return nil
end

local function inMapRect(tile,coordTable,map)
    local zVal = map or 0
    local xMin = coordTable[1][1]
    local xMax = coordTable[2][1]
    local yMin = coordTable[2][2]
    local yMax = coordTable[3][2]
    return tile.z == zVal and tile.x >= xMin and tile.x <=xMax and tile.y >= yMin and tile.y <= yMax
end

local function moveUnitQualified(unit,unitTypeName,tribeName,mapRectTable,map)
    if string.lower(unit.type.name) ~= string.lower(unitTypeName) and string.lower(unitTypeName) ~= "anyunit" then
        -- wrong unit type
        return false
    end
    if string.lower(unit.owner.name) ~= string.lower(tribeName) and string.lower(tribeName) ~= "anybody" then
        -- wrong owner
        return false
    end
    if unit.owner.isHuman then
        -- human owner, so move unit doesn't apply
        return false
    end
    if unit.order == 2 then
        -- unit fortified, so move unit doesn't apply
        return false
    end
    if unit.order == 3 then
        -- unit on sentry duty, move unit doesn't apply
        return false
    end
    if unit.gotoTile then
        -- unit has a goto order already, so move unit doesn't apply
        return false
    end
    if unit.order == 1 or unit.order == 4 then
        -- unit is building fortifications, or settler is building a fortress, so no move unit
        return false
    end
    if unit.type.attack == 99 then
        -- unit is a nuclear weapon, so move unit does not apply
        return false
    end
    return inMapRect(unit.location,mapRectTable,map)
end

local function applyWildCard(value,triggerAttackerString,triggerDefenderString,triggerReceiverString)
    if string.lower(value) == "triggerattacker" then
        return triggerAttackerString
    elseif string.lower(value) == "triggerdefender" then
        return triggerDefenderString
    elseif string.lower(value) == "triggerreceiver" then
        return triggerReceiverString
    else
        return value
    end
end

local function changeTerrainQualified(tile,mapRectTable,map,exceptionMask)
    if not inMapRect(tile,mapRectTable, map) then
        return false
    end
    local terrainNum = tile.terrainType % 16
    if exceptionMask and type(exceptionMask) == "number" 
        and exceptionMask & 1<<(terrainNum) == 1<<(terrainNum) then
        -- exception mask has the bit corresponding to the tile's terrain type set to 1 
            return false
    end
    if exceptionMask and type(exceptionMask) == "string" and exceptionMask:sub(1,2) == "0b" then
        -- string of expected form
        -- remove "0b" just in case event doesn't take into account extra terrain types
        local mString = exceptionMask:sub(3)
        if mString:sub(-(terrainNum+1),-(terrainNum+1)) == "1" then
            -- exception maks has bit corresponding to tile terrain type set to 1, so don't change
            return false
        end
    end
    return true
end



local function stringToUnitType(inputString)
    for i=0,civ.cosmic.numberOfUnitTypes-1 do
        if civ.getUnitType(i) and string.lower(civ.getUnitType(i).name) == string.lower(inputString) then
            return civ.getUnitType(i)
        end
    end
    if failSearchWithError then
        error(inputString.." does not match the name of a unit type in the game.")
    end
    return nil
end

local function canTalkByTriggers(talkerLeaderID,listenerLeaderID)
    for i=1,#eventTable do
        -- this global variable is for error reporting
        -- it can also be accessed from the console in the event of an error
        g_EventNumber = i
        local ANDIFTable=eventTable[i]["IF"]
        if ANDIFTable["negotiation"] then
            if ANDIFTable["talkermask"] and 
                ANDIFTable["talkermask"]:sub(-(talkerLeaderID+1),-(talkerLeaderID+1))=="1"
                and ANDIFTable["listenermask"] and
                ANDIFTable["listenermask"]:sub(-(listenerLeaderID+1),-(listenerLeaderID+1))=="1" then
                -- talker and listener both in the negotiaion event mask, so they can't negotiatie
                return false
            end
            -- if no talker/listener mask, then use the "tribe colour" of the leader to 
            -- get a tribe for comparisons
            local talkerCorrect = false
            local talkerTribe = civ.getTribe(1+(talkerLeaderID%7))
            if ANDIFTable["talker"] and ANDIFTable["talker"]==string.lower(talkerTribe.name)
                then talkerCorrect=true
            end
            if ANDIFTable["talkertype"] then
                if ANDIFTable["talkertype"] == "humanorcomputer" then
                    talkerCorrect = true
                elseif ANDIFTable["talkertype"] == "human" and talkerTribe.isHuman then
                    talkerCorrect = true
                elseif ANDIFTable["talkertype"] == "computer" and not talkerTribe.isHuman then
                    talkerCorrect = true
                end
            end
            local listenerCorrect = false
            local listenerTribe =civ.getTribe(1+(listenerLeaderID%7)) 
            if ANDIFTable["listener"] and ANDIFTable["listener"]==string.lower(listenerTribe.name)
                then listenerCorrect = true
            end
            if ANDIFTable["listenertype"] then
                if ANDIFTable["listenertype"] == "humanorcomputer" then
                    listenerCorrect = true
                elseif ANDIFTable["listenertype"] == "human" and listenerTribe.isHuman then
                    listenerCorrect = true
                elseif ANDIFTable["listenertype"] == "computer" and not listenerTribe.isHuman then
                    listenerCorrect = true
                end
            end
            if talkerCorrect and listenerCorrect then 
                return false
            end
        end
        local ANDIFTable=eventTable[i]["AND"]
        if ANDIFTable and ANDIFTable["negotiation"] then
            if ANDIFTable["talkermask"] and 
                ANDIFTable["talkermask"]:sub(-(talkerLeaderID+1),-(talkerLeaderID+1))=="1"
                and ANDIFTable["listenermask"] and
                ANDIFTable["listenermask"]:sub(-(listenerLeaderID+1),-(listenerLeaderID+1))=="1" then
                -- talker and listener both in the negotiaion event mask, so they can't negotiatie
                return false
            end
            -- if no talker/listener mask, then use the "tribe colour" of the leader to 
            -- get a tribe for comparisons
            local talkerCorrect = false
            local talkerTribe = civ.getTribe(1+(talkerLeaderID%7))
            if ANDIFTable["talker"] and ANDIFTable["talker"]==string.lower(talkerTribe.name)
                then talkerCorrect=true
            end
            if ANDIFTable["talkertype"] then
                if ANDIFTable["talkertype"] == "humanorcomputer" then
                    talkerCorrect = true
                elseif ANDIFTable["talkertype"] == "human" and talkerTribe.isHuman then
                    talkerCorrect = true
                elseif ANDIFTable["talkertype"] == "computer" and not talkerTribe.isHuman then
                    talkerCorrect = true
                end
            end
            local listenerCorrect = false
            local listenerTribe =civ.getTribe(1+(listenerLeaderID%7)) 
            if ANDIFTable["listener"] and ANDIFTable["listener"]==string.lower(listenerTribe.name)
                then listenerCorrect = true
            end
            if ANDIFTable["listenertype"] then
                if ANDIFTable["listenertype"] == "humanorcomputer" then
                    listenerCorrect = true
                elseif ANDIFTable["listenertype"] == "human" and listenerTribe.isHuman then
                    listenerCorrect = true
                elseif ANDIFTable["listenertype"] == "computer" and not listenerTribe.isHuman then
                    listenerCorrect = true
                end
            end
            if talkerCorrect and listenerCorrect then 
                return false
            end
        end
    end
    return true
end

local function initializeCanTalk()
    if g_LegacyState.canTalk then
        return
    end
    g_LegacyState.canTalk = {}
    for talker = 0,20 do
        g_LegacyState.canTalk[talker]={}
        for listener=0,20 do
            g_LegacyState.canTalk[talker][listener]=canTalkByTriggers(talker,listener)
        end
    end
end

local function canNegotiate(talkerTribe,listenerTribe)
    initializeCanTalk()
    return g_LegacyState.canTalk[talkerTribe.leader.id][listenerTribe.leader.id]
end




-- eventInformationTable
--
-- g_LegacyState.eventStatusTable
-- Indexed by the Event Number (i.e. the table index for the event)
-- g_LegacyState.eventStatusTable[n] =
-- { ifConditionSatisfied=bool or nil, ifConditionContinuous=bool or nil,
--  andConditionSatisfied=bool or nil, andConditionContinuous=bool or nil,
--  justOnceCompleted=bool or nil,
--  delayedEvents = table of delayedEventInfo or nil}
--
--  delayedEventInfo = {
--  performOnTurn=integer,
--  triggerAttacker=tribeName or nil,
--  triggerDefender=tribeName or nil,
--  triggerReceiver=tribeName or nil,}
--
local function eventIfConditionSatisfied(eventIndex)
    g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
    g_LegacyState.eventStatusTable[eventIndex] = g_LegacyState.eventStatusTable[eventIndex] or {}
    g_LegacyState.eventStatusTable[eventIndex].ifConditionSatisfied=true 
    g_LegacyState.eventStatusTable[eventIndex].ifConditionContinuous=eventTable[eventIndex]["IF"]["continuous"] 
end

local function eventAndConditionSatisfied(eventIndex)
    g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
    g_LegacyState.eventStatusTable[eventIndex] = g_LegacyState.eventStatusTable[eventIndex] or {}
    g_LegacyState.eventStatusTable[eventIndex].andConditionSatisfied=true 
    g_LegacyState.eventStatusTable[eventIndex].andConditionContinuous=eventTable[eventIndex]["AND"]["continuous"] 
end

local function eventDelayed(eventIndex,performEventOnTurn,triggerAttacker,triggerDefender,triggerReceiver)
    g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
    g_LegacyState.eventStatusTable[eventIndex] = g_LegacyState.eventStatusTable[eventIndex] or {}
    g_LegacyState.eventStatusTable[eventIndex].delayedEvents = g_LegacyState.eventStatusTable[eventIndex].delayedEvents or {}
    g_LegacyState.eventStatusTable[eventIndex].delayedEvents[#g_LegacyState.eventStatusTable[eventIndex].delayedEvents+1] = {performOnTurn=perfromEventOnTurn, triggerAttacker=triggerAttacker, triggerDefender=triggerDefender, triggerReceiver = triggerReceiver,}
end

local function eventJustOnceExecuted(eventIndex)
    g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
    g_LegacyState.eventStatusTable[eventIndex] = g_LegacyState.eventStatusTable[eventIndex] or {}
    g_LegacyState.eventStatusTable[eventIndex].justOnceCompleted = true
end

-- Sets the events satisfied to nil (equivalent to false for these purposes) unless it has the continuous modifier
local function clearSatisfiedEventConditions(eventIndex)
    g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
    if g_LegacyState.eventStatusTable[eventIndex] then
        local eStatus = g_LegacyState.eventStatusTable[eventIndex]
        eStatus.ifContidionSatisifed = (eStatus.ifConditionSatisfied and eStatus.ifConditionContinuous) or nil
        eStatus.andContidionSatisifed =(eStatus.andConditionSatisfied and eStatus.andConditionContinuous) or nil
    end
end

-- clears active event conditions, unless they are continuous
local function resetEventConditions()
    g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
    for eventIndex, eventStatus in pairs(g_LegacyState.eventStatusTable) do
        clearSatisfiedEventConditions(eventIndex)
    end
end

-- returns true if the @IF condition of a trigger is currently satisfied, false/nil if not
local function isEventIfConditionAlreadySatisfied(eventIndex)
    g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
    g_LegacyState.eventStatusTable[eventIndex] = g_LegacyState.eventStatusTable[eventIndex] or {}
    return g_LegacyState.eventStatusTable[eventIndex].ifConditionSatisfied
end

-- returns true if the @AND condition of a trigger is currently satisfied or if there is no @AND for the event
-- returns false/nil otherwise
local function isEventAndConditionAlreadySatisfied(eventIndex)
    if eventTable[eventIndex]["AND"] == nil then
        return true
    else
        g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
        g_LegacyState.eventStatusTable[eventIndex] = g_LegacyState.eventStatusTable[eventIndex] or {}
        return g_LegacyState.eventStatusTable[eventIndex].andConditionSatisfied
    end
end

-- returns true if this event has already happened and it had a justOnce action, false/nil otherwise
local function justOnceCompleted(eventIndex)
    g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
    g_LegacyState.eventStatusTable[eventIndex] = g_LegacyState.eventStatusTable[eventIndex] or {}
    return g_LegacyState.eventStatusTable[eventIndex].justOnceCompleted
end
    

        
-- legacy Flag Functions
local function showFlags()
    local text = "_off,*off Cont, Xon,Con Cont\n"
    for tribeID = 1,7 do
        text = text.."^ Tribe "..tostring(tribeID).." "
        for flagID = 31,1,-1 do
            local fpair = g_LegacyState.legacyFlags[tribeID][flagID]
            if fpair.status and fpair.continuous then
                text = text.."C"
            elseif fpair.status and not fpair.continuous then
                text = text.."X"
            elseif not fpair.status and fpair.continuous then
                text = text.."*"
            elseif not fpair.status and not fpair.continuous then
                text = text.."-"
            else
                text = text.."#"
            end
        end
        text = text.."\n"
    end
    civ.ui.text(func.splitlines(text))
end

local function initializeLegacyFlags()
    if g_LegacyState.legacyFlags then
        return
    end
    g_LegacyState.legacyFlags = {[0]={},[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},}
    for tribeID=0,7 do
        for flagID=0,31 do
            g_LegacyState.legacyFlags[tribeID][flagID]={status = false, continuous = false}
        end
    end
end

local function setFlagOn(flagNumber, tribe, continuous)
    if not g_LegacyState.legacyFlags then
        initializeLegacyFlags()
    end
    if tribe and type(tribe) == "string" then
        tribe = stringToTribe(tribe)
    end
    if tribe and civ.isTribe(tribe) then
        g_LegacyState.legacyFlags[tribe.id][flagNumber]={status=true, continuous=continuous}
    else
        for i=0,7 do
            g_LegacyState.legacyFlags[i][flagNumber]={status=true, continuous=continuous}
        end
    end
end

local function clearFlagOff(flagNumber, tribe, continuous)
    if not g_LegacyState.legacyFlags then
        initializeLegacyFlags()
    end
    if tribe and type(tribe) == "string" then
        tribe = stringToTribe(tribe)
    end
    if tribe and civ.isTribe(tribe) then
        g_LegacyState.legacyFlags[tribe.id][flagNumber]={status=false, continuous=continuous}
    else
        for i=0,7 do
            g_LegacyState.legacyFlags[i][flagNumber]={status=false, continuous=continuous}
        end
    end
end

local function doMask(maskStringOrNum,tribeID,makeState,continuous)
    local maskNum = nil
    if type(maskStringOrNum) == "number" then
        maskNum = maskStringOrNum
    elseif type(maskStringOrNum) == "string" then
        -- If given in decimal or hexidecimal, this will work
        -- otherwise it will return nil
        maskNum = tonumber(maskStringOrNum)
    end
    if maskNum then
        for i=0,31 do
            if maskNum & 1<<i == 1<<i then
                g_LegacyState.legacyFlags[tribeID][i] = {status=makeState,continuous=continuous}
            end
        end
    elseif string.lower(maskStringOrNum:sub(1,2))=="0b" then
        local maskString=maskStringOrNum
        for i=0,31 do
            if maskString:sub(-(i+1),-(i+1)) == "1" then
                g_LegacyState.legacyFlags[tribeID][i] = {status=makeState,continuous=continuous}
            end
        end
    else
        error(tostring(maskStringOrNum).." not a valid flag mask.")
    end
end

local function setMaskOn(maskStringOrNum, tribeName, continuous)
    if not g_LegacyState.legacyFlags then
        initializeLegacyFlags()
    end
    if tribeName and stringToTribe(tribeName) then
        doMask(maskStringOrNum,stringToTribe(tribeName).id,true,continuous)
    else
        for i=0,7 do
            doMask(maskStringOrNum,i,true,continuous)
        end
    end
end

local function clearMaskOff(maskStringOrNum, tribeName, continuous)
    if not g_LegacyState.legacyFlags then
        initializeLegacyFlags()
    end
    if tribeName and stringToTribe(tribeName) then
        doMask(maskStringOrNum,stringToTribe(tribeName).id,false,continuous)
    else
        for i=0,7 do
            doMask(maskStringOrNum,i,false,continuous)
        end
    end
end

-- clears flags unless they have the continuous aspect set and are already true
local function resetFlags()
    initializeLegacyFlags()
    for tribeID=0,7 do
        for flagID=0,31 do
            local currentStatus = g_LegacyState.legacyFlags[tribeID][flagID].status
            local isContinuous = g_LegacyState.legacyFlags[tribeID][flagID].continuous
            g_LegacyState.legacyFlags[tribeID][flagID].status = currentStatus and isContinuous
        end
    end
end
        
local function getFlagValue(tribe,flagNumber)
    initializeLegacyFlags()
    local tribeID = nil
    if civ.isTribe(tribe) then
        tribeID = tribe.id
    elseif type(tribe) == "number" then
        tribeID = tribe
    elseif type(tribe) == "string" then
        tribeID = stringToTribe(tribe) and stringToTribe(tribe).id
    end
    if not tribeID then
        error("getFlagValue: "..tostring(tribe).." not the name of a tribe in play.")
    end
    return g_LegacyState.legacyFlags[tribeID][flagNumber].status
end


local function getDelayPerFlag(mask,perFlagDelay)
    initializeLegacyFlags()
    local validFlags = 0
    if type(mask) == "number" then
        for flagNum = 0,31 do
            if mask & 1<<flagNum ==1<<flagNum then
                for tribeID = 1,7 do
                    if g_LegacyState.legacyFlags[tribeID][flagNum].status then
                        validFlags=validFlags+1
                    end
                end
            end
        end
    else
        for flagNum = 0,31 do
            if mask:sub(-(flagNum+1),-(flagNum+1))=="1" then
                for tribeID = 1,7 do
                    if g_LegacyState.legacyFlags[tribeID][flagNum].status then
                        validFlags=validFlags+1
                    end
                end
            end
        end
    end
    return perFlagDelay*validFlags
end

 
-- Makes a rating for whether a city should get an improvement
-- foreign cities get rating of -1
-- cities with the improvement get rating of 0
local function cityRating(city,tribe,improvementID,capitalBonus,wondersBonus)
    if city.owner ~= tribe then 
        return -1
    end
    if improvementID < 40 and city:hasImprovement(civ.getImprovement(improvementID)) then
        return 0
    end
    local wondersInCity=0
    for i=0,27 do
        if civ.getWonder(i).city == city then
            wondersInCity=wondersInCity+1
        end
    end
    local capitalValue = 0
    if city:hasImprovement(civ.getImprovement(1)) then
        capitalValue=capitalBonus
    end
    return city.size+wondersInCity*wondersBonus+capitalValue
end

                                                                  
                                                                  
                                                                  
                                                                  
                                                                  

-- Legacy Actions

-- The main function for performing legacy trigger actions.
--
-- performingDelayedAction is true if the action was delayed from the original trigger time
--      this means it ignores the "justonce", "delay", "delay per flag" keywords
local function performLegacyEventActions(eventIndex, triggerAttackerString,triggerDefenderString,triggerReceiverString, performingDelayedAction)
    local thenTable = eventTable[eventIndex]["THEN"]
    if not(performingDelayedAction) then
        if thenTable["justonce"] and justOnceCompleted(eventIndex) then
            -- this event should not happen
            return
        elseif thenTable["delay"] then
            local delay = thenTable["delay"]["delay"]
            if thenTable["delay"]["randomize"] then
                delay = math.random(0,delay)
            end
            if delay == 0 then
                -- if the delay is 0, then perform the action now
                -- but perform it as a delayed action
                performLegacyEventActions(eventIndex,triggerAttackerString,triggerDefenderString,triggerReceiverString, true)
                return
            else
                -- if the delay is not 0, delay the event until the appropriate turn
                eventDelayed(eventIndex,civ.getTurn()+delay,triggerAttackerString,
                    triggerDefenderString,triggerReceiverString)
            end
            if thenTable["justonce"] then
                -- JustOnce so that the delay isn't executed again
                eventJustOnceExecuted(eventIndex)
            end
            return -- this is everything that should be done until the action is executed
        elseif thenTable["delayperflag"] then
            local delay = thenTable["delayperflag"]["basedelay"]
            delay = delay+getDelayPerFlag(thenTable["delayperflag"]["mask"],thenTable["delayperflag"]["perflagdelay"])
            if thenTable["delayperflag"]["randomize"] then
                delay = math.random(0,delay)
            end
            if delay == 0 then
                -- if the delay is 0, then perform the action now
                -- but perform it as a delayed action
                performLegacyEventActions(eventIndex,triggerAttackerString,triggerDefenderString,triggerReceiverString, true)
                return
            else
                -- if the delay is not 0, delay the event until the appropriate turn
                eventDelayed(eventIndex,civ.getTurn()+delay,triggerAttackerString,
                    triggerDefenderString,triggerReceiverString)
            end
            if thenTable["justonce"] then
                -- JustOnce so that the delay isn't executed again
                eventJustOnceExecuted(eventIndex)
            end
            return -- this is everything that should be done until the action is executed
        end
    end
    --either performing a delayed action, or performing an action without a delay component
    if thenTable["justonce"] then
        eventJustOnceExecuted(eventIndex)
    end
    if thenTable["playwavefile"] then
        civ.playSound(thenTable["playwavefile"])
    end
    if thenTable["playavifile"] then
        civ.playVideo(thenTable["playavifile"])
    end
    if thenTable["playcdtrack"] then
        civ.playMusic(thenTable["playcdtrack"])
    end
    if thenTable["createunit"] then
        local optionsTable = {}
        local unitType = stringToUnitType(thenTable["createunit"]["unit"])
        local ownerTribe = stringToTribe(thenTable["createunit"]["owner"],triggerAttackerString,triggerDefenderString,triggerReceiverString)
        optionsTable.count = thenTable["createunit"]["count"] or 1
        if thenTable["createunit"]["veteran"] == "yes" or thenTable["createunit"]["veteran"] == "true" then
            optionsTable.veteran = true
        else
            optionsTable.veteran = false
        end
        optionsTable.homeCity = stringToCity(thenTable["createunit"]["homecity"])
        optionsTable.inCapital = thenTable["createunit"]["incapital"]
        createLocations = thenTable["createunit"]["locations"]
        -- just in case there are only 2 coordinates, make third coordinate 0
        for index,value in pairs(createLocations) do
            if not value[3] then
                value[3] = 0
            end
        end
        optionsTable.randomize = thenTable["createunit"]["randomize"]
        if unitType and ownerTribe and createLocations then
            civlua.createUnit(unitType,ownerTribe,createLocations, optionsTable)
        end
    end
    if thenTable["moveunit"] then
        local numberToMove = nil
        local ownerString = applyWildCard(thenTable["moveunit"]["owner"])
        local destinationTile = civ.getTile(thenTable["moveunit"]["moveto"][1],thenTable["moveunit"]["moveto"][2],
                thenTable["moveunit"]["moveto"][3] or thenTable["moveunit"]["map"] or 0)
        if ownerString and destinationTile then
            if thenTable["moveunit"]["numbertomove"] == "all" then
                numberToMove = 1000000
            elseif type(thenTable["moveunit"]["numbertomove"]) == "number" then
                numberToMove = thenTable["moveunit"]["numbertomove"]
            else
                numberToMove = -1
            end
            for unit in civ.iterateUnits() do 
                if moveUnitQualified(unit,thenTable["moveunit"]["unit"],ownerString,
                    thenTable["moveunit"]["maprect"],thenTable["moveunit"]["map"]) then
                    unit.gotoTile = destinationTile
                    numberToMove = numberToMove-1
                    if numberToMove <=0 then
                        break
                    end
                end
            end
        end
    end
    if thenTable["transport"] then
        local unitType = stringToUnitType(thenTable["transport"]["unit"])
        local tMode = thenTable["transport"]["mode"]
        -- set the bit for the type of transport to 1 
        local transBit = 1<<(thenTable["transport"]["type"])
        if unitType then
            if thenTable["transport"]["state"] == "on" or thenTable["transport"]["state"] == "set" then
                unitType[mode.."Transport"]= unitType[mode.."Transport"] | transBit
            elseif thenTable["transport"]["state"] == "on" or thenTable["transport"]["state"] == "set" then
                unitType[mode.."Transport"]= unitType[mode.."Transport"] & ~transBit
            end
        end
    end
    if thenTable["changeterrain"] then
        for tile in civlua.iterateTiles() do
            if changeTerrainQualified(tile,thenTable["changeterrain"]["maprect"],
                thenTable["changeterrain"]["map"],thenTable["changeterrain"]["exceptionmask"]) then
                tile.terrainType = thenTable["changeterrain"]["terraintype"]
                -- a bug/feature of the legacy macro language is that the top unit on the tile is
                -- deleted when the terrain is changed
                civ.deleteUnit(tile.units())
            end
        end
    end
    if thenTable["makeaggression"] then
        local aggressor = stringToTribe(thenTable["makeaggression"]["who"],triggerAttackerString,
            triggerDefenderString, triggerReceiverString)
        local victim = stringToTribe(thenTable["makeaggression"]["whom"],triggerAttackerString,
            triggerDefenderString, triggerReceiverString)
        if aggressor and victim then
            civ.makeAggression(aggressor,victim)
        end
    end
    if thenTable["changemoney"] then
        local receivingTribe = stringToTribe(thenTable["changemoney"]["receiver"],triggerAttackerString,
            triggerDefenderString, triggerReceiverString)
        if receivingTribe then
            receivingTribe.money = math.max(0,receivingTribe.money+thenTable["changemoney"]["amount"])
        end
    end
    if thenTable["destroyacivilization"] then
        local victim = stringToTribe(thenTable["destroyacivilization"]["whom"],triggerAttackerString,
            triggerDefenderString, triggerReceiverString)
        if victim then
            civ.killTribe(victim)
        end
    end
    if thenTable["givetechnology"] then
        local receivingTribe = stringToTribe(thenTable["givetechnology"]["receiver"],triggerAttackerString,
            triggerDefenderString, triggerReceiverString)
        if receivingTribe then
            receivingTribe:giveTech(civ.getTech(thenTable["givetechnology"]["technology"]))
        end
    end
    if thenTable["taketechnology"] then
        local losingTribe = stringToTribe(thenTable["taketechnology"]["whom"],triggerAttackerString,
            triggerDefenderString, triggerReceiverString)
        if losingTribe then
            civ.takeTech(losingTribe,civ.getTech(thenTable["taketechnology"]["technology"]),
                thenTable["taketechnology"]["collapse"])
        end
    end
    if thenTable["enabletechnology"] then
        local enabledTribe = stringToTribe(thenTable["enabletechnology"]["whom"],triggerAttackerString,
            triggerDefenderString, triggerReceiverString)
        if enabledTribe then
            civ.enableTechGroup(enabledTribe,civ.getTech(thenTable["enabletechnology"]["technology"]).group,
                thenTable["enabletechnology"]["value"])
        end
    end
    if thenTable["text"] then
        local textToDisplay = ""
        for i=0,15 do -- documentation says at most 10 lines of text, will do 15 just in case
            if thenTable["text"]["text"] and thenTable["text"]["text"][i] then
                textToDisplay = textToDisplay..thenTable["text"]["text"][i].."\n"
            end
        end
        if thenTable["text"]["no broadcast"] and not civ.getCurrentTribe().isHuman then
            -- don't show the message, since the receipiant is an ai and there is no-broadcast
        else
            civ.ui.text(func.splitlines(textToDisplay))
        end
    end
    if thenTable["modifyreputation"] then
        local modifiedTribe = stringToTribe(thenTable["modifyreputation"]["who"],triggerAttackerString,
            triggerDefenderString, triggerReceiverString)
        if modifiedTribe and thenTable["modifyreputation"]["betray"] then
            modifiedTribe.betrayals=thenTable["modifyreputation"]["betray"]
        end
        if modifiedTribe and thenTable["modifyreputation"]["whom"] and thenTable["modifyreputation"]["modifier"] then
            local opiningTribe = stringToTribe(thenTable["modifyreputation"]["whom"])
            if opiningTribe then
                opiningTribe.attitude[modifiedTribe] = math.min(100,math.max(0,thenTable["modifyreputation"]["modifier"]))
            end
        end
    end
    if thenTable["bestowimprovement"] then
        -- capital counts as this many citizens for the city rating
        local capitalValue = 0
        if thenTable["bestowimprovement"]["capital"] =="yes" or
            thenTable["bestowimprovement"]["capital"] =="on" or 
            thenTable["bestowimprovement"]["capital"] =="true" then 
            capitalValue = 3
        end
        local wondersValue = 0
        if thenTable["bestowimprovement"]["wonders"] =="yes" or
            thenTable["bestowimprovement"]["wonders"] =="on" or 
            thenTable["bestowimprovement"]["wonders"] =="true" then 
            wondersValue = 2
        end
        local eligibleCitiesList = {}
        local improvementID = thenTable["bestowimprovement"]["improvement"]
        local receivingTribe = stringToTribe(thenTable["bestowimprovement"]["race"],triggerAttackerString,
            triggerDefenderString, triggerReceiverString)
        if receivingTribe then
            for city in civ.iterateCities() do
                local value = cityRating(city,receivingTribe,improvementID,capitalValue,wondersValue)
                if value > 0 then
                    eligibleCitiesList[#eligibleCitiesList+1]={city=city,rating=value}
                end
            end
            local eligibleCitiesListSize = #eligibleCitiesList
            if eligibleCitiesListSize > 0 then
                eligibleCitiesList=table.sort(eligibleCitiesList,function(a,b) return a.rating > b.rating end)
                local giveCity = nil
                if thenTable["bestowimprovement"]["randomize"] then
                    giveCity = eligibleCitiesList[math.random(1,math.min(eligibleCitiesListSize,10))].city
                else
                    giveCity = eligibleCitiesList[1].city
                end
                if improvementID < 40 then
                    giveCity:addImprovement(civ.getImprovement(improvementID))
                end
                local wonderToGive = civ.getWonder(improvementID-40)
                if wonderToGive and not (wonderToGive.city or wonderToGive.destroyed) then
                    wonderToGive.city=giveCity
                end
            end
        end
    end
    if thenTable["endgameoverride"] then
        g_LegacyState.endGameOverride=true
    end
    if thenTable["endgame"] then
        local endscreens = nil
        if thenTable["endgame"]["endscreens"] == "yes" or thenTable["endgame"]["endscreens"] == "on" or thenTable["endgame"]["endscreens"] == "true" or thenTable["endgame"]["endscreens"] == true then
            endscreens = true
        else
            endscreens = false
        end
        civ.endGame(endscreens)
    end
    if thenTable["flag"] then
        local flagTribe = nil
        if thenTable["flag"]["who"] then
            flagTribe = stringToTribe(thenTable["flag"]["who"],triggerAttackerString,
                triggerDefenderString, triggerReceiverString)
        end
        if thenTable["flag"]["state"] == "on" or thenTable["flag"]["state"] =="set" then
            if thenTable["flag"]["flag"] then
                setFlagOn(thenTable["flag"]["flag"],flagTribe, thenTable["flag"]["continuous"])
            elseif thenTable["flag"]["mask"] then
                setMaskOn(thenTable["flag"]["mask"],flagTribe,thenTable["flag"]["continuous"])
            end
        elseif thenTable["flag"]["state"] == "off" or thenTable["flag"]["state"] == "clear" then
            if thenTable["flag"]["flag"] then
                clearFlagOff(thenTable["flag"]["flag"],flagTribe, thenTable["flag"]["continuous"])
            elseif thenTable["flag"]["mask"] then
                clearMaskOff(thenTable["flag"]["mask"],flagTribe,thenTable["flag"]["continuous"])
            end
        end
    end
    if thenTable["negotiator"] then
        initializeCanTalk()
        local leaderID = nil
        if type(thenTable["negotiator"]["who"]) == "number" then
            -- according to the documentation, if who=number, the list of leaders starts at 1
            -- however, the list of leaders given by tribe.leader.id starts at 0, so correct this
            leaderID= thenTable["negotiator"]["who"]+1
        elseif type(thenTable["negotiator"]["who"]) == "string" then
            leaderID = stringToTribe(inputString,triggerAttackerString,triggerDefenderString,triggerReceiverString) and stringToTribe(inputString,triggerAttackerString,triggerDefenderString,triggerReceiverString).leader.id
        end
        if leaderID then
            if thenTable["negotiator"]["type"]=="talker" then
                local negotiationAllowed = nil
                if thenTable["negotiator"]["state"] == "set" then
                    negotiationAllowed=false
                else
                    negotiationAllowed=true
                end
                for listener=0,20 do
                    g_LegacyState.canTalk[leaderID][listener] = negotiationAllowed
                end
            elseif thenTable["negotiator"]["type"]=="listener" then
                local negotiationAllowed = nil
                if thenTable["negotiator"]["state"] == "set" then
                    negotiationAllowed=false
                else
                    negotiationAllowed=true
                end
                for talker=0,20 do
                    g_LegacyState.canTalk[talker][leaderID]=negotiationAllowed
                end
            end
        end
    end
end


-- Trigger Checks
local function doTriggerEventsFunction(conditionMetFunction,conditionMetArg1,conditionMetArg2,
            triggerAttackerString,triggerDefenderString,triggerReceiverString)
    for i=1,#eventTable do
        -- this global variable is for error reporting
        -- it can also be accessed from the console in the event of an error
        g_EventNumber = i
        -- make sure the action is only performed once
        local eventIActionNotDone = true
        if eventTable[i]["AND"] then
            -- event i has two conditions
            if conditionMetFunction(eventTable[i]["IF"],conditionMetArg1,conditionMetArg2) then
                eventIfConditionSatisfied(i)
                if isEventAndConditionAlreadySatisfied(i) and eventIActionNotDone then
                    performLegacyEventActions(i, triggerAttackerString, triggerDefenderString,
                        triggerReceiverString, false)
                    eventIActionNotDone=false
                end
            end
            if conditionMetFunction(eventTable[i]["AND"],conditionMetArg1,conditionMetArg2) then
                eventAndConditionSatisfied(i)
                if isEventIfConditionAlreadySatisfied(i) and eventIActionNotDone then
                    performLegacyEventActions(i, triggerAttackerString, triggerDefenderString,
                        triggerReceiverString, false)
                    eventIActionNotDone=false
                end
            end
        else
            -- Event i has only an if condition
            -- So, if this condition is true, do it
            if conditionMetFunction(eventTable[i]["IF"],conditionMetArg1,conditionMetArg2) then
                performLegacyEventActions(i,triggerAttackerString,triggerDefenderString,
                    triggerReceiverString,false)
                eventIActionNotDone=false
            end
        end
    end
end


--onTurn
--civ.scen.onTurn(function (turn) -> void)
--
-- ON TURN Triggers and Maintenance

-- performDelayedActions
local function performDelayedActions(turn)
    g_LegacyState.eventStatusTable=g_LegacyState.eventStatusTable or {}
    for i=1,#eventTable do
        -- this global variable is for error reporting
        -- it can also be accessed from the console in the event of an error
        g_EventNumber = i
        if g_LegacyState.eventStatusTable[i] and g_LegacyState.eventStatusTable[i].delayedEvents then
            for index,delayedEventInfo in pairs(g_LegacyState.eventStatusTable[i].delayedEvents) do
                if turn == delayedEventInfo.performOnTurn then
                    performDelayedActions(i,delayedEventInfo.triggerAttacker,
                        delayedEventInfo.triggerDefender,delayedEventInfo.triggerReceiver,true)
                    g_LegacyState.eventStatusTable[i].delayedEvents[index]=nil
                end
            end
        end
    end
end

-- checkTurnTriggers 
local function turnConditionMet(ANDIFTable,turn,spareArg)
    -- note: The turn parameter overwrites the turn triggertype in the parser
    -- this doesn't matter since no other trigger type has a turn= parameter
    return ANDIFTable["turn"] and ANDIFTable["turn"]==turn
end

local function doTurnEvents(turn)
    doTriggerEventsFunction(turnConditionMet,turn,nil,nil,nil,nil)
end
--
-- checkTurnIntervalTriggers
--
local function turnIntervalConditionMet(ANDIFTable,turn,spareArg)
    if not ANDIFTable["turninterval"] then
        -- not a turn interval trigger
        return false
    end
    if turn % ANDIFTable["interval"]==0 then
        -- this will happen every x turns, for interval=x, beginning on turn x
        return true
    else
        return false
    end
end

local function doTurnIntervalEvents(turn)
    doTriggerEventsFunction(turnIntervalConditionMet,turn,nil,nil,nil,nil)
end
-- checkRandomTurnTriggers
local function randomTurnConditionMet(ANDIFTable, spareArg1,spareArg2)
    if not ANDIFTable["randomturn"] then
        -- not a randomTurn trigger
        return false
    end
    -- this has a one in x chance of being true for denominator=x
    return math.random(1,ANDIFTable["denominator"])==1
end

local function doRandomTurnEvents()
    doTriggerEventsFunction(randomTurnConditionMet,nil,nil,nil,nil,nil)
end

-- checkReceivedTechnologyTriggers
--
local function doReceivedTechnologyEvents()
    local function satisfiesTechCondition(tribeID,ANDIFTable)
        -- checks if tribe with id tribeID satisfies the 
        -- ReceivedTechnology conditions, except for the 
        -- receivedtechnology trigger keyword itself
        local tribe = civ.getTribe(tribeID)
        if not tribe then
            return false
        end
        if ANDIFTable["receiver"] ~= string.lower(tribe.name) and ANDIFTable["receiver"]~="anybody" then
            -- not the correct tribe
            return false
        end
        if ANDIFTable["futuretech"] and tribe.futureTechs < ANDIFTable["futuretech"] then
            return false
        end
        return civ.hasTech(tribe, civ.getTech(ANDIFTable["technology"]))
    end
    for i=1,#eventTable do
        -- this global variable is for error reporting
        -- it can also be accessed from the console in the event of an error
        g_EventNumber = i
        if eventTable[i]["AND"] then
            -- event i has two conditions
            if eventTable[i]["IF"]["receivedtechnology"] then
                -- this is a received technology trigger
                -- must test against every tribe
                for tribeID=1,7 do
                    if satisfiesTechCondition(tribeID,eventTable[i]["IF"]) then
                        eventIfConditionSatisfied(i)
                        if isEventAndConditionAlreadySatisfied(i) then
                            performLegacyEventActions(i, nil,nil,string.lower(civ.getTribe(tribeID).name),false)
                        end
                    end
                end
            end
            if eventTable[i]["AND"]["receivedtechnology"] then
                -- this is a received technology trigger
                -- must test against every tribe
                for tribeID=1,7 do
                    if satisfiesTechCondition(tribeID,eventTable[i]["AND"]) then
                        eventAndConditionSatisfied(i)
                        if isEventIfConditionAlreadySatisfied(i) then
                            performLegacyEventActions(i, nil,nil,string.lower(civ.getTribe(tribeID).name),false)
                        end
                    end
                end
            end
        else
            --event i has only one condition
            if eventTable[i]["IF"]["receivedtechnology"] then
                -- this is a received technology trigger
                -- must test against every tribe
                for tribeID = 1,7 do
                    if satisfiesTechCondition(tribeID,eventTable[i]["IF"]) then
                        performLegacyEventActions(i,nil,nil,string.lower(civ.getTribe(tribeID).name),false)
                    end
                end
            end
        end
    end
end
 



-- checkCheckFlagTriggers
-- triggerattacker is the key if "somebody" satisfies the flag
-- handles the specific civilization and somebody case
-- note that barbarian flags don't appear to be checked
local function isIndividualCivFlagConditionTrue(ANDIFTable,tribeID)
    if not ANDIFTable["checkflag"] then
        -- not a check flag event
        return false
    end
    local tribe = civ.getTribe(tribeID)
    if ANDIFTable["who"]~="somebody" and not (tribe and string.lower(tribe.name) == ANDIFTable["who"]) then
        -- not the correct tribe
        return false
    end
    if ANDIFTable["technology"] and not (tribe and civ.hasTech(tribe, civ.getTech(ANDIFTable["technology"]))) then
        -- technology requirement and tribe does not meet it
        return false
    end
    --local isDesiredFlagSetting = nil
    desiredFlagSetting = nil
    if ANDIFTable["state"]=="on" or ANDIFTable["state"]=="set" then
        -- desired flag setting is true
       -- isDesiredFlagSetting = function (bool) return bool end
       desiredFlagSetting = true
    elseif ANDIFTable["state"]=="off" or ANDIFTable["state"]=="clear" then
        --isDesiredFlagSetting = function (bool) return not bool end
        desiredFlagSetting = false
    else
        error("Check Flag error. state="..ANDIFTable["state"].." is not appropriate")
    end
    if ANDIFTable["flag"] then
        -- a single flag number is specified
        -- return isDesiredFlagSetting(getFlagValue(tribeID,ANDIFTable["flag"]))
        if desiredFlagSetting then
            return getFlagValue(tribeID,ANDIFTable["flag"])
        else
            return not getFlagValue(tribeID,ANDIFTable["flag"])
        end
    end
    -- If we're here, a mask is used.
    local numberOfCorrectFlags = 0
    if type(ANDIFTable["mask"]) == "string" then
        local maskString = ANDIFTable["mask"]
        for flagNum = 0,31 do
            if maskString:sub(-(flagNum+1),-(flagNum+1)) == "1" then
                if desiredFlagSetting and getFlagValue(tribeID,flagNum) then
                    numberOfCorrectFlags = numberOfCorrectFlags+1
                elseif not desiredFlagSetting and not getFlagValue(tribeID,flagNum) then
                    numberOfCorrectFlags = numberOfCorrectFlags+1
                end
            end
        end
    else
        -- the mask was converted to a number (probably because it was specified in
        -- hexidecimal, which lua can use in tonumber, which was done in the parser
        local maskNum = ANDIFTable["mask"]
        for flagNum=0,31 do
            if maskNum & 1<<flagNum == 1<<flagNum then
                if desiredFlagSetting and getFlagValue(tribeID,flagNum) then
                    numberOfCorrectFlags = numberOfCorrectFlags+1
                elseif not desiredFlagSetting and not getFlagValue(tribeID,flagNum) then
                    numberOfCorrectFlags = numberOfCorrectFlags+1
                end
            end
        end
    end
    if ANDIFTable["threshold"] then
        return numberOfCorrectFlags >= ANDIFTable["threshold"]
    end
    if ANDIFTable["count"] then
        return numberOfCorrectFlags == ANDIFTable["count"]
    end
    -- we shoulnd't get here, but just in case
    return false
end

local function isEverybodyFlagConditionTrue(ANDIFTable)
    if not ANDIFTable["checkflag"] then
        -- not a flag trigger
        return false
    end
    if ANDIFTable["who"]~="everybody" then
        -- not an everybody flag trigger
        return false
    end
    local isDesiredFlagSetting = nil
    if ANDIFTable["state"]=="on" or ANDIFTable["state"]=="set" then
        -- desired flag setting is true
        isDesiredFlagSetting = function (bool) return bool end
    else
        isDesiredFlagSetting = function (bool) return not bool end
    end
    local function everybodyFlag(flagNumber)
        for civNum=1,7 do
            if isDesiredFlagSetting(getFlagValue(civNum,flagNumber)) then
                return true
            end
        end
        return false
    end
    if ANDIFTable["flag"] then
        return everybodyFlag(ANDIFTable["flag"])
    end
    -- If we're here, a mask is used.
    local numberOfCorrectFlags = 0
    if type(ANDIFTable["mask"]) == "string" then
        local maskString = ANDIFTable["mask"]
        for flagNum = 0,31 do
            if maskString:sub(-(flagNum+1),-(flagNum+1)) == "1" then
                if everybodyFlag(flagNum) then
                    numberOfCorrectFlags = numberOfCorrectFlags+1
                end
            end
        end
    else
        -- the mask was converted to a number (probably because it was specified in
        -- hexidecimal, which lua can use in tonumber, which was done in the parser
        local maskNum = ANDIFTable["mask"]
        for flagNum=0,31 do
            if maskNum & 1<<flagNum == 1<<flagNum then
                if everybodyFlag(flagNum) then
                    numberOfCorrectFlags = numberOfCorrectFlags+1
                end
            end
        end
    end
    if ANDIFTable["threshold"] then
        return numberOfCorrectFlags >= ANDIFTable["threshold"]
    end
    if ANDIFTable["count"] then
        return numberOfCorrectFlags == ANDIFTable["count"]
    end
    -- we shoulnd't get here, but just in case
    return false
end

local function doCheckFlagEvents()
    for i=1,#eventTable do
        -- this global variable is for error reporting
        -- it can also be accessed from the console in the event of an error
        g_EventNumber = i
        if eventTable[i]["AND"] then
            -- event i has two conditions
            for tribeID = 1,7 do
                if isIndividualCivFlagConditionTrue(eventTable[i]["IF"],tribeID) then
                    eventIfConditionSatisfied(i)
                    if isEventAndConditionAlreadySatisfied(i) then
                        local triggerAttackerString = civ.getTribe(tribeID) and string.lower(civ.getTribe(tribeID).name)
                        performLegacyEventActions(i,triggerAttackerString,nil,nil,false)
                    end
                end
            end
            if isEverybodyFlagConditionTrue(eventTable[i]["IF"]) then
                eventIfConditionSatisfied(i)
                if isEventAndConditionAlreadySatisfied(i) then
                    performLegacyEventActions(i,nil,nil,nil,false)
                end
            end
            for tribeID = 1,7 do
                if isIndividualCivFlagConditionTrue(eventTable[i]["AND"],tribeID) then
                    eventAndConditionSatisfied(i)
                    if isEventIfConditionAlreadySatisfied(i) then
                        local triggerAttackerString = civ.getTribe(tribeID) and string.lower(civ.getTribe(tribeID).name)
                        performLegacyEventActions(i,triggerAttackerString,nil,nil,false)
                    end
                end
            end
            if isEverybodyFlagConditionTrue(eventTable[i]["AND"]) then
                eventAndConditionSatisfied(i)
                if isEventIfConditionAlreadySatisfied(i) then
                    performLegacyEventActions(i,nil,nil,nil,false)
                end
            end
        else
            -- event i has only one condition
            -- must test against every tribe
            for tribeID = 1,7 do
                if isIndividualCivFlagConditionTrue(eventTable[i]["IF"],tribeID) then
                    local triggerAttackerString = civ.getTribe(tribeID) and string.lower(civ.getTribe(tribeID).name)
                    performLegacyEventActions(i,triggerAttackerString,nil,nil,false)
                end
            end
            if isEverybodyFlagConditionTrue(eventTable[i]["IF"]) then
                performLegacyEventActions(i,nil,nil,nil,false) 
            end
        end
    end
end
-- resetFlags
--
--
local function onTurnEventsAndMaintenance(turnNumber)
    resetEventConditions()
    performDelayedActions(turnNumber)
    doTurnEvents(turnNumber)
    doTurnIntervalEvents(turnNumber)
    doRandomTurnEvents()
    doReceivedTechnologyEvents()
    doCheckFlagEvents()
    resetFlags()
end
--
--onUnitKilled
--civ.scen.onUnitKilled(function (loser, winner) -> void)

local function unitKilledConditionMet(ANDIFTable, loser, winner)
    if not ANDIFTable["unitkilled"] then
        return false
    end
    if ANDIFTable["defender only"] and loser.owner == civ.getCurrentTribe() then
        -- if the loser is owned by the active tribe, then it was not
        -- the defender, so the trigger isn't satisfied
        return false
    end
    local combatMap = winner.location.z
    -- case where the map parameter is defined, but combat is not on one of those maps.
    if ANDIFTable["map"] and not ANDIFTable["map"][combatMap] then
        return false
    end
    if string.lower(loser.type.name) ~= ANDIFTable["unit"] and "anyunit"~=ANDIFTable["unit"] then
        -- unit killed doesn't match trigger unit
        return false
    elseif string.lower(loser.owner.name)~=ANDIFTable["defender"] and "anybody"~=ANDIFTable["defender"] then
        -- defender doesn't match trigger defender
        return false
    elseif string.lower(winner.owner.name)~=ANDIFTable["attacker"] and "anybody"~=ANDIFTable["attacker"] then
        -- attacker doesn't match trigger attacker
        return false
    end
    -- if we get here, everything is a match
    return true
end

local function doUnitKilledEvents(loser,winner)
    doTriggerEventsFunction(unitKilledConditionMet,loser,winner,string.lower(winner.owner.name),
        string.lower(loser.owner.name), nil)
end

-- checkUnitKilledTriggers
--
--onScenarioLoaded
--civ.scen.onScenarioLoaded(function () -> void)
local function scenarioLoadedConditionMet(ANDIFTable,spareArg1,spareArg2)
    -- no parameters for this trigger, so just return whether the
    -- trigger word is there
    return ANDIFTable["scenarioloaded"]
end

local function doScenarioLoadedEvents()
    doTriggerEventsFunction(scenarioLoadedConditionMet,nil,nil,nil,nil,nil)
end
--
-- checkScenarioLoadedTriggers
--
--onNegotiation
--civ.scen.onNegotiation(function (talker, listener) -> boolean)
local function negotiationConditionMet(ANDIFTable,talker,listener)
    local talkerLeaderID = talker.leader.id
    local listenerLeaderID = listener.leader.id
    if ANDIFTable["negotiation"] then
        if ANDIFTable["talkermask"] and 
            ANDIFTable["talkermask"]:sub(-(talkerLeaderID+1),-(talkerLeaderID+1))=="1"
            and ANDIFTable["listenermask"] and
            ANDIFTable["listenermask"]:sub(-(listenerLeaderID+1),-(listenerLeaderID+1))=="1" then
            -- talker and listener both in the negotiaion event mask, so they can't negotiatie
            return true
        end
        -- if no talker/listener mask, then use the "tribe colour" of the leader to 
        -- get a tribe for comparisons
        local talkerCorrect = false
        local talkerTribe = talker
        if ANDIFTable["talker"] and ANDIFTable["talker"]==string.lower(talkerTribe.name)
            then talkerCorrect=true
        end
        if ANDIFTable["talkertype"] then
            if ANDIFTable["talkertype"] == "humanorcomputer" then
                talkerCorrect = true
            elseif ANDIFTable["talkertype"] == "human" and talkerTribe.isHuman then
                talkerCorrect = true
            elseif ANDIFTable["talkertype"] == "computer" and not talkerTribe.isHuman then
                talkerCorrect = true
            end
        end
        local listenerCorrect = false
        local listenerTribe =listener 
        if ANDIFTable["listener"] and ANDIFTable["listener"]==string.lower(listenerTribe.name)
            then listenerCorrect = true
        end
        if ANDIFTable["listenertype"] then
            if ANDIFTable["listenertype"] == "humanorcomputer" then
                listenerCorrect = true
            elseif ANDIFTable["listenertype"] == "human" and listenerTribe.isHuman then
                listenerCorrect = true
            elseif ANDIFTable["listenertype"] == "computer" and not listenerTribe.isHuman then
                listenerCorrect = true
            end
        end
        if talkerCorrect and listenerCorrect then 
            return true
        end
    end
    return false
end

local function doNegotiationEvents(talker,listener)
    doTriggerEventsFunction(negotiationConditionMet,talker,listener)
end


-- checkNegotiationTriggers


--onSchism
--civ.scen.onSchism(function (tribe) -> boolean)
--
local allowSchism = true
local function noSchismConditionMet(ANDIFTable,tribe,extraArg)
    if not ANDIFTable["noschism"] then
        -- not a noSchism event
        return false
    end
    if ANDIFTable["defender"]~=string.lower(tribe.name) and ANDIFTable["defender"]~="anybody" then
        -- incorrect tribe
        return false
    end
    -- set allowSchism to false, since a noSchism event was found
    allowSchism=false
    return true
end

local function doNoSchismEvents(tribe)
    -- make sure to allow schism if nothing is found
    -- if a noSchism event is found for this tribe, this value will
    -- be set to false
    allowSchism = true
    doTriggerEventsFunction(noSchismConditionMet,tribe,nil,nil,nil,nil)
    return allowSchism
end

-- checkNoSchismTriggers
--
--onCityTaken
--civ.scen.onCityTaken(function (city, defender) -> void)
--
-- checkCityTakenTriggers

local function cityTakenConditionMet(ANDIFTable,city,defender)
    if not ANDIFTable["citytaken"] then
        return false
    end
    if ANDIFTable["city"]~= string.lower(city.name) and ANDIFTable["city"] ~= "anycity" then
        -- city doesn't have correct name
        return false
    end
    if ANDIFTable["unittype"] and ANDIFTable["citytaken"] then
        civ.ui.text("CityTaken unittype=spy parameter not implemented in legacy Event Engine, and doesn't seem to work in original events either.  (Based on very small amount of testing.)")
    end
    if ANDIFTable["attacker"] ~= string.lower(city.owner.name) and ANDIFTable["attacker"]~="anybody" then
        -- city not captured by the correct tribe
        return false
    end
    if ANDIFTable["defender"] ~= string.lower(defender.name) and ANDIFTable["defender"]~="anybody" then
        -- city not previously owned by correct tribe
        return false
    end
    -- if we get here, everything is a match
    return true
end

local function doCityTakenEvents(city,defender)
    doTriggerEventsFunction(cityTakenConditionMet,city,defender,string.lower(city.owner.name),
        string.lower(defender.name), nil)
end

--onCityProduction
--civ.scen.onCityProduction(function (city, prod) -> void)
local function cityProductionConditionMet(ANDIFTable,city,prod)
    if not ANDIFTable["cityproduction"] then
        -- not a city production trigger
        return false
    end
    if ANDIFTable["builder"]~=string.lower(city.owner.name) and ANDIFTable["builder"]~="anybody" then
        -- builder is not the correct tribe
        return false
    end
    if ANDIFTable["improvement"] then
        -- This is the case where an improvement/wonder is supposed to be built
        -- add 40 to the wonder id number to bring in line with the 0-67 improvment id
        -- number of macro
        -- The parser should have made a number for the value of .improvement
        if civ.isImprovement(prod) then
            return ANDIFTable["improvement"] == prod.id
        elseif civ.isWonder(prod) then
            return ANDIFTable["improvement"] == 40+prod.id
        else
            -- production was not an improvement or wonder, so return false
            return false
        end
    end
    if ANDIFTable["unit"] then
        -- note that anyunit doesn't seem to make the trigger happen (based on very limited test)
        -- if not a unit, return false, if a unit, return true if the name matches the parameter
        return civ.isUnit(prod) and string.lower(prod.type.name) == ANDIFTable["unit"]
    end
end

local function doCityProductionEvents(city,prod)
    doTriggerEventsFunction(cityProductionConditionMet, city,prod, nil,
        string.lower(city.owner.name),string.lower(city.owner.name))
        -- note that triggerattacker in cityproduction event actions doesn't
        -- seem to do anything, but triggerdefender and triggerreceiver both seem to work
end
    
-- checkCityProductionTriggers
--
--onCentauriArrival
--civ.scen.onCentauriArrival(function (tribe) -> void)
--
local function alphaCentauriArrivalConditionMet(ANDIFTable,tribe,extraArg)
    if not ANDIFTable["alphacentauriarrival"] then
        -- not an alphaCentauriArrival trigger
        return false
    end
    if string.lower(tribe.name)~=ANDIFTable["race"] and ANDIFTable["race"]~="anybody" then
        -- not the correct tribe to reach alpha centauri
        return false
    end
    if ANDIFTable["size"] == "anysize" then
        return true
    end
    -- trigger depends on exact size of the spaceship
    local shipSize = math.min(tribe.spaceship.habitation, tribe.spaceship.lifesupport, tribe.spaceship.solar)
    return shipSize == ANDIFTable["size"] 
end

local function doAlphaCentauriArrivalEvents(tribe)
    doTriggerEventsFunction(alphaCentauriArrivalConditionMet,tribe,nil,string.lower(tribe.name),nil,nil)
    --A quick test suggests that triggerAttacker is the valid "wildcard" associated with the alpha centauri event
end
-- checkAlphaCentauriArrivalTriggers
--
--onCityDestroyed
--civ.scen.onCityDestroyed(function (city) -> void)
--
local function cityDestroyedConditionMet(ANDIFTable,city,extraArg)
    if not ANDIFTable["citydestroyed"] then
        -- not a citydestroyed trigger
        return false
    end
    if string.lower(city.name) ~= ANDIFTable["city"] then
        -- not the correct city
        -- anycity doesn't seem to work for the city destroyed event
        return false
    end
    if string.lower(city.owner.name) ~= ANDIFTable["owner"] and ANDIFTable["owner"]~="anybody" then
        -- the owner of the city is not of the correct tribe
        return false
    end
    -- all conditions are met
    return true
end

local function doCityDestroyedEvents(city)
    doTriggerEventsFunction(cityDestroyedConditionMet,city,nil,nil,string.lower(city.owner.name),nil)
    -- note that testing suggests that triggerattacker is not a valid keyword 
    -- for this event in the macro language, hence it is set to nil
end
        
-- checkCityDestroyedTriggers
--
--onBribeUnit
--civ.scen.onBribeUnit(function (unit, previousOwner) -> void)
local function bribeUnitConditionMet(ANDIFTable,unit,previousOwner)
    if not ANDIFTable["bribeunit"] then
        -- not a bribe unit trigger
        return false
    end
    if ANDIFTable["who"] ~= string.lower(unit.owner.name) and ANDIFTable["who"] ~= "anybody" then
        -- not correct tribe for briber
        return false
    end
    if ANDIFTable["whom"] ~= string.lower(previousOwner.name) and ANDIFTable["whom"]~="anybody" then
        -- not correct previous owner
        return false
    end
    if unit.type.id ~= ANDIFTable["unittype"] then
        -- not correct unit type
        -- anyunit doesn't seem to work for this based on very limited test
        return false
    end
    -- if we get here, everything is correct
    return true
end

local function doBribeUnitEvents(unit,previousOwner)
    doTriggerEventsFunction(bribeUnitConditionMet,unit,previousOwner,string.lower(unit.owner.name),
        string.lower(previousOwner.name),string.lower(previousOwner.name))
end

--
-- checkBribeUnitTriggers
--
--onGameEnds
--civ.scen.onGameEnds(function (reason) -> boolean)
--
local function endTheGame(reason)
    if reason <= 2 and g_LegacyState.endGameOverride then
        return false
    else 
        return true
    end
end
-- NO ON GAME ENDS TRIGGERS
--
--onKeyPress
--civ.scen.onKeyPress(function (keyCode) -> void)
--
-- NO KEY PRESS TRIGGERS
--
--onActivateUnit
--civ.scen.onActivateUnit(function (unit, source) -> void)
--
-- NO ACTIVATE UNIT TRIGGERS
--
--onCityFounded
--civ.scen.onCityFounded(function (city) -> void)
--
-- NO CITY FOUNDED TRIGGERS
--
--onResolveCombat
--civ.scen.onResolveCombat(function (defaultResolutionFunction, attacker, defender) -> boolean)
--
-- NO RESOLVE COMBAT TRIGGERS
--
--onCanBuild
--civ.scen.onCanBuild(function (defaultBuildFunction, city, item) -> boolean)
--
-- NO CAN BUILD TRIGGERS
--
--
return {setFlagOn=setFlagOn,
clearFlagOff = clearFlagOff,
setMaskOn = setMaskOn,
clearMaskOff = clearMaskOff,
getFlagValue = getFlagValue,
doUnitKilledEvents=doUnitKilledEvents,
doCityTakenEvents=doCityTakenEvents,
onTurnEventsAndMaintenance=onTurnEventsAndMaintenance,
doCityProductionEvents = doCityProductionEvents,
doCityDestroyedEvents = doCityDestroyedEvents,
doScenarioLoadedEvents = doScenarioLoadedEvents,
doAlphaCentauriArrivalEvents=doAlphaCentauriArrivalEvents,
doBribeUnitEvents = doBribeUnitEvents,
doNoSchismEvents = doNoSchismEvents,
canNegotiate = canNegotiate,
doNegotiationEvents = doNegotiationEvents,
endTheGame = endTheGame,
linkState = linkState,
}