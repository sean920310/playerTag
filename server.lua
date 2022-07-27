local data = {}

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


ESX.RegisterServerCallback("playerTag:getData", function(source,cb)
    local xPlayers = ESX.GetPlayers()
    for i=1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        local _rank = 0
        if xPlayer.get("rank") then
            _rank = tonumber(xPlayer.get("rank"))
        end
        local _guild = xPlayer.get("guild")
        data[xPlayers[i]] = {
            rank = _rank,
            guild = _guild
        }
    end
    cb(data)
 end)

