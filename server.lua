local data = {}

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


ESX.RegisterServerCallback("playerTag:getData", function(source,cb)
    local xPlayers = ESX.GetPlayers()
    for i=1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        data[xPlayers[i]] = {
            rank = tonumber(xPlayer.get("rank")),
        }
    end
    cb(data)
 end)

