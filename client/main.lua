-- Variables
local KGCore = exports['kg-core']:GetCoreObject()
local PlayerData = KGCore.Functions.GetPlayerData()
local CurrentWeaponData, CanShoot, MultiplierAmount, currentWeapon = {}, true, 0, nil

-- Handlers

AddEventHandler('KGCore:Client:OnPlayerLoaded', function()
    PlayerData = KGCore.Functions.GetPlayerData()
    KGCore.Functions.TriggerCallback('kg-weapons:server:GetConfig', function(RepairPoints)
        for k, data in pairs(RepairPoints) do
            Config.WeaponRepairPoints[k].IsRepairing = data.IsRepairing
            Config.WeaponRepairPoints[k].RepairingData = data.RepairingData
        end
    end)
end)

RegisterNetEvent('KGCore:Client:OnPlayerUnload', function()
    for k in pairs(Config.WeaponRepairPoints) do
        Config.WeaponRepairPoints[k].IsRepairing = false
        Config.WeaponRepairPoints[k].RepairingData = {}
    end
end)

-- Functions

local function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Events

RegisterNetEvent('kg-weapons:client:SyncRepairShops', function(NewData, key)
    Config.WeaponRepairPoints[key].IsRepairing = NewData.IsRepairing
    Config.WeaponRepairPoints[key].RepairingData = NewData.RepairingData
end)

RegisterNetEvent('kg-weapons:client:EquipTint', function(weapon, tint)
    local player = PlayerPedId()
    SetPedWeaponTintIndex(player, weapon, tint)
end)

RegisterNetEvent('kg-weapons:client:SetCurrentWeapon', function(data, bool)
    if data ~= false then
        CurrentWeaponData = data
    else
        CurrentWeaponData = {}
    end
    CanShoot = bool
end)

RegisterNetEvent('kg-weapons:client:SetWeaponQuality', function(amount)
    if CurrentWeaponData and next(CurrentWeaponData) then
        TriggerServerEvent('kg-weapons:server:SetWeaponQuality', CurrentWeaponData, amount)
    end
end)

RegisterNetEvent('kg-weapons:client:AddAmmo', function(type, amount, itemData)
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)

    if not CurrentWeaponData then
        KGCore.Functions.Notify(Lang:t('error.no_weapon'), 'error')
        return
    end

    if KGCore.Shared.Weapons[weapon]['name'] == 'weapon_unarmed' or KGCore.Shared.Weapons[weapon]['ammotype'] ~= type:upper() then
        KGCore.Functions.Notify(Lang:t('error.no_weapon'), 'error')
        return
    end

    local total = GetAmmoInPedWeapon(ped, weapon)
    local _, maxAmmo = GetMaxAmmo(ped, weapon)

    if total >= maxAmmo then
        KGCore.Functions.Notify(Lang:t('error.max_ammo'), 'error')
        return
    end

    KGCore.Functions.Progressbar('taking_bullets', Lang:t('info.loading_bullets'), Config.ReloadTime, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        if KGCore.Shared.Weapons[weapon] then
            AddAmmoToPed(ped, weapon, amount)
            TaskReloadWeapon(ped, false)
            TriggerServerEvent('kg-weapons:server:UpdateWeaponAmmo', CurrentWeaponData, total + amount)
            TriggerServerEvent('kg-weapons:server:removeWeaponAmmoItem', itemData)
            TriggerEvent('kg-inventory:client:ItemBox', KGCore.Shared.Items[itemData.name], 'remove')
            TriggerEvent('KGCore:Notify', Lang:t('success.reloaded'), 'success')
        end
    end, function()
        KGCore.Functions.Notify(Lang:t('error.canceled'), 'error')
    end)
end)

RegisterNetEvent('kg-weapons:client:UseWeapon', function(weaponData, shootbool)
    local ped = PlayerPedId()
    local weaponName = tostring(weaponData.name)
    local weaponHash = joaat(weaponData.name)
    if currentWeapon == weaponName then
        TriggerEvent('kg-weapons:client:DrawWeapon', nil)
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        RemoveAllPedWeapons(ped, true)
        TriggerEvent('kg-weapons:client:SetCurrentWeapon', nil, shootbool)
        currentWeapon = nil
    elseif weaponName == 'weapon_stickybomb' or weaponName == 'weapon_pipebomb' or weaponName == 'weapon_smokegrenade' or weaponName == 'weapon_flare' or weaponName == 'weapon_proxmine' or weaponName == 'weapon_ball' or weaponName == 'weapon_molotov' or weaponName == 'weapon_grenade' or weaponName == 'weapon_bzgas' then
        TriggerEvent('kg-weapons:client:DrawWeapon', weaponName)
        GiveWeaponToPed(ped, weaponHash, 1, false, false)
        SetPedAmmo(ped, weaponHash, 1)
        SetCurrentPedWeapon(ped, weaponHash, true)
        TriggerEvent('kg-weapons:client:SetCurrentWeapon', weaponData, shootbool)
        currentWeapon = weaponName
    elseif weaponName == 'weapon_snowball' then
        TriggerEvent('kg-weapons:client:DrawWeapon', weaponName)
        GiveWeaponToPed(ped, weaponHash, 10, false, false)
        SetPedAmmo(ped, weaponHash, 10)
        SetCurrentPedWeapon(ped, weaponHash, true)
        TriggerServerEvent('kg-inventory:server:snowball', 'remove')
        TriggerEvent('kg-weapons:client:SetCurrentWeapon', weaponData, shootbool)
        currentWeapon = weaponName
    else
        TriggerEvent('kg-weapons:client:DrawWeapon', weaponName)
        TriggerEvent('kg-weapons:client:SetCurrentWeapon', weaponData, shootbool)
        local ammo = tonumber(weaponData.info.ammo) or 0

        if weaponName == 'weapon_petrolcan' or weaponName == 'weapon_fireextinguisher' then
            ammo = 4000
        end

        GiveWeaponToPed(ped, weaponHash, ammo, false, false)
        SetPedAmmo(ped, weaponHash, ammo)
        SetCurrentPedWeapon(ped, weaponHash, true)

        if weaponData.info.attachments then
            for _, attachment in pairs(weaponData.info.attachments) do
                GiveWeaponComponentToPed(ped, weaponHash, joaat(attachment.component))
            end
        end

        if weaponData.info.tint then
            SetPedWeaponTintIndex(ped, weaponHash, weaponData.info.tint)
        end

        currentWeapon = weaponName
    end
end)

RegisterNetEvent('kg-weapons:client:CheckWeapon', function(weaponName)
    if currentWeapon ~= weaponName:lower() then return end
    local ped = PlayerPedId()
    TriggerEvent('kg-weapons:ResetHolster')
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    RemoveAllPedWeapons(ped, true)
    currentWeapon = nil
end)

-- Threads

CreateThread(function()
    SetWeaponsNoAutoswap(true)
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedArmed(ped, 7) == 1 and (IsControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 24)) then
            local weapon = GetSelectedPedWeapon(ped)
            local ammo = GetAmmoInPedWeapon(ped, weapon)
            TriggerServerEvent('kg-weapons:server:UpdateWeaponAmmo', CurrentWeaponData, tonumber(ammo))
            if MultiplierAmount > 0 then
                TriggerServerEvent('kg-weapons:server:UpdateWeaponQuality', CurrentWeaponData, MultiplierAmount)
                MultiplierAmount = 0
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if CurrentWeaponData and next(CurrentWeaponData) then
                if IsPedShooting(ped) or IsControlJustPressed(0, 24) then
                    local weapon = GetSelectedPedWeapon(ped)
                    if CanShoot then
                        if weapon and weapon ~= 0 and KGCore.Shared.Weapons[weapon] then
                            KGCore.Functions.TriggerCallback('prison:server:checkThrowable', function(result)
                                if result or GetAmmoInPedWeapon(ped, weapon) <= 0 then return end
                                MultiplierAmount += 1
                            end, weapon)
                            Wait(200)
                        end
                    else
                        if weapon ~= `WEAPON_UNARMED` then
                            TriggerEvent('kg-weapons:client:CheckWeapon', KGCore.Shared.Weapons[weapon]['name'])
                            KGCore.Functions.Notify(Lang:t('error.weapon_broken'), 'error')
                            MultiplierAmount = 0
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local inRange = false
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            for k, data in pairs(Config.WeaponRepairPoints) do
                local distance = #(pos - data.coords)
                if distance < 10 then
                    inRange = true
                    if distance < 1 then
                        if data.IsRepairing then
                            if data.RepairingData.CitizenId ~= PlayerData.citizenid then
                                DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.repairshop_not_usable'))
                            else
                                if not data.RepairingData.Ready then
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.weapon_will_repair'))
                                else
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.take_weapon_back'))
                                end
                            end
                        else
                            if CurrentWeaponData and next(CurrentWeaponData) then
                                if not data.RepairingData.Ready then
                                    local WeaponData = KGCore.Shared.Weapons[GetHashKey(CurrentWeaponData.name)]
                                    local WeaponClass = (KGCore.Shared.SplitStr(WeaponData.ammotype, '_')[2]):lower()
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.repair_weapon_price', { value = Config.WeaponRepairCosts[WeaponClass] }))
                                    if IsControlJustPressed(0, 38) then
                                        KGCore.Functions.TriggerCallback('kg-weapons:server:RepairWeapon', function(HasMoney)
                                            if HasMoney then
                                                CurrentWeaponData = {}
                                            end
                                        end, k, CurrentWeaponData)
                                    end
                                else
                                    if data.RepairingData.CitizenId ~= PlayerData.citizenid then
                                        DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.repairshop_not_usable'))
                                    else
                                        DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.take_weapon_back'))
                                        if IsControlJustPressed(0, 38) then
                                            TriggerServerEvent('kg-weapons:server:TakeBackWeapon', k, data)
                                        end
                                    end
                                end
                            else
                                if data.RepairingData.CitizenId == nil then
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('error.no_weapon_in_hand'))
                                elseif data.RepairingData.CitizenId == PlayerData.citizenid then
                                    DrawText3Ds(data.coords.x, data.coords.y, data.coords.z, Lang:t('info.take_weapon_back'))
                                    if IsControlJustPressed(0, 38) then
                                        TriggerServerEvent('kg-weapons:server:TakeBackWeapon', k, data)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if not inRange then
                Wait(1000)
            end
        end
        Wait(0)
    end
end)
