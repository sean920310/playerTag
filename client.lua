local PlayerTag = {}
PlayerTag.data = {}
PlayerTag.hasInit = false
PlayerTag.showTag = true
PlayerTag.showSelfTag = false

local mpGamerTags = {}
local playerId = PlayerId() -- you can use any local player ID here

-------------------------------------------------------------------------------

ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent("esx:getSharedObject", function(obj)
            ESX = obj
        end)
        Citizen.Wait(0)
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    Citizen.Wait(1000)
    PlayerTag:init()
end)

-------------------------------------------------------------------------------

--頭上顯示樣式
function PlayerTag:formatTag(i)
    return ('[%d] %s Lv.%d'):format(GetPlayerServerId(i), GetPlayerName(i),PlayerTag.data[GetPlayerServerId(i)].rank)
end

function PlayerTag:init()
    ESX.TriggerServerCallback("playerTag:getData", function(data)
        PlayerTag.data = data
        PlayerTag.hasInit = true
    end)
end

function PlayerTag:update()
    -- get local coordinates to compare to
    local localCoords = GetEntityCoords(PlayerPedId())

    for i = 0, 255 do
        if NetworkIsPlayerActive(i) and (i ~= playerId or (i == playerId and self.showSelfTag)) then
            -- get their ped
            local ped = GetPlayerPed(i)
            local pedCoords = GetEntityCoords(ped)

            -- make a new settings list if needed
            -- if not mpGamerTagSettings[i] then
            --     mpGamerTagSettings[i] = makeSettings()
            -- end

            -- check the ped, because changing player models may recreate the ped
            -- also check gamer tag activity in case the game deleted the gamer tag
            if not mpGamerTags[i] or mpGamerTags[i].ped ~= ped or not IsMpGamerTagActive(mpGamerTags[i].tag) then
                local nameTag = PlayerTag:formatTag(i)

                -- remove any existing tag
                if mpGamerTags[i] then
                    RemoveMpGamerTag(mpGamerTags[i].tag)
                end

                -- store the new tag
                mpGamerTags[i] = {
                    tag = CreateFakeMpGamerTag(GetPlayerPed(i), nameTag, false, false, '', 0),
                    ped = ped
                }
            end

            -- store the tag in a local
            local tag = mpGamerTags[i].tag

            -- update tag
            
            SetMpGamerTagName(tag, PlayerTag:formatTag(i))
            

            -- check distance
            local distance = #(pedCoords - localCoords)

            -- show/hide based on nearbyness/line-of-sight
            -- nearby checks are primarily to prevent a lot of LOS checks
            if distance < Config.dist and HasEntityClearLosToEntity(PlayerPedId(), ped, 17) then
                SetMpGamerTagVisibility(tag, 0, self.showTag) -- GAMER_NAME
                SetMpGamerTagVisibility(tag, 4, NetworkIsPlayerTalking(i) and self.showTag) -- AUDIO_ICON

            else
                SetMpGamerTagVisibility(tag, 0, false) -- GAMER_NAME
                SetMpGamerTagVisibility(tag, 4, false) -- AUDIO_ICON
            end

        elseif mpGamerTags[i] then
            RemoveMpGamerTag(mpGamerTags[i].tag)

            mpGamerTags[i] = nil
        end

    end
end

function PlayerTag:dataRefresh()
    ESX.TriggerServerCallback("playerTag:getData", function(data)
        PlayerTag.data = data

        for i = 0, 255 do
            if NetworkIsPlayerActive(i) and (i ~= playerId or (i == playerId and PlayerTag.showSelfTag)) then
                -- store the tag in a local
                local tag = mpGamerTags[i].tag

                -- update tag
                if tag ~= nil then
                    SetMpGamerTagName(tag, PlayerTag:formatTag(i))
                end

            elseif mpGamerTags[i] then
                RemoveMpGamerTag(mpGamerTags[i].tag)

                mpGamerTags[i] = nil
            end
        end
    end)
end

function PlayerTag:showToggle()
    PlayerTag.showTag = not PlayerTag.showTag
    if PlayerTag.showTag then
        chat("顯示名字標籤", {0, 255, 0})
    else
        chat("隱藏名字標籤", {255, 0, 0})
    end
end

function PlayerTag:selfTag()
    PlayerTag.showSelfTag = not PlayerTag.showSelfTag
    if PlayerTag.showSelfTag then
        chat("顯示自身名字標籤", {0, 255, 0})
    else
        chat("隱藏自身名字標籤", {255, 0, 0})
    end
end

function chat(str, color)
    TriggerEvent('chat:addMessage', {
        color = color,
        multiline = true,
        args = {str}
    })
end
-------------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        if PlayerTag.hasInit then
            PlayerTag:update()
        else
            Citizen.Wait(1000)
            PlayerTag.init()
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if PlayerTag.hasInit then
            PlayerTag:dataRefresh()
        end
    end
end)


RegisterCommand("tag", function(source, args)
    if args[1] then
        if args[1] == "self" then
            PlayerTag:selfTag()

        elseif args[1] == "refresh" then
            PlayerTag:dataRefresh()
        end
    else
        PlayerTag:showToggle()
    end
end)

-------------------------------------------------------------------------------

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        for i = 0, 255 do
            if mpGamerTags[i] then
                RemoveMpGamerTag(mpGamerTags[i].tag)
                mpGamerTags[i] = nil
            end
        end
    end
  end)