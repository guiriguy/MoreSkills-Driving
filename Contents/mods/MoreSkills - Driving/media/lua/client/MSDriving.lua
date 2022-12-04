local MSDriving = {}

MSDriving.InVehicle = false
MSDriving.VehicleSquare = nil
MSDriving.VehicleTotalDistance = 0
MSDriving.VehicleState = nil
MSDriving.Damaged = false
MSDriving.FuelAmount = 0
MSDriving.PerkDriving = Perks.MSDriving
MSDriving.getTotalMass = 0
MSDriving.minMul = 3 --Option
MSDriving.maxMul = 16 --Option
MSDriving.minFuelConsumption = 0
MSDriving.maxFuelConsumption = 20

MSDriving.GiveBackFuel =  function(vehicle, perkLevel)
    local actualFuel = vehicle:getPartById("GasTank"):getContainerContentAmount()
    local fuelLost = MSDriving.FuelAmount - actualFuel
    local mathsFuel = (MSDriving.minFuelConsumption + ((MSDriving.maxFuelConsumption-MSDriving.minFuelConsumption)*(perkLevel/10)))*0.01
    vehicle:getPartById("GasTank"):setContainerContentAmount(vehicle:getPartById("GasTank"):getContainerContentAmount()+(fuelLost*mathsFuel))
    MSDriving.FuelAmount = vehicle:getPartById("GasTank"):getContainerContentAmount()
end

MSDriving.CheckIfLoseLevel = function(player, perkLevel)
    if MSDriving.PerkDriving:getTotalXpForLevel(perkLevel) > player:getXp():getXP(MSDriving.PerkDriving) then
        player:LoseLevel(MSDriving.PerkDriving)
    end
end

MSDriving.MathsUp00 = function(x)
    x = math.ceil(x*100)/100
    return x
end

MSDriving.getVCondition = function (vehicle)
    local parts = {}
    for i = 1, vehicle:getPartCount() do
        local part = vehicle:getPartByIndex(i-1)
        parts[part] = part:getCondition()
    end
    return parts
end

MSDriving.compareVCondition = function (old, actual)
    local totalDamage = 0
    for part, condition in pairs(old) do
        if actual[part] ~= nil then
            if (condition - actual[part]) > 2 then
                totalDamage = totalDamage + (condition - actual[part])
            end
        end
    end
    if totalDamage > 0 then
        MSDriving.Damaged = true
        return totalDamage
    else
        return 0
    end
end

MSDriving.OnEnterVehicle = function(player)
    if player then
        print("Entered vehicle by: ",player, " Vehicle is: ",player)
        local vehicle = player:getVehicle()
        MSDriving.InVehicle = true
        MSDriving.VehicleSquare = vehicle:getSquare()
        MSDriving.VehicleState = MSDriving.getVCondition(vehicle)
        MSDriving.FuelAmount = vehicle:getPartById("GasTank"):getContainerContentAmount()
    end
end
MSDriving.OnExitVehicle = function(player)
    if player then
        print("Exited vehicle by: ",player)
        MSDriving.InVehicle = false
        MSDriving.VehicleSquare = nil
        MSDriving.VehicleState = nil
        MSDriving.Damaged = false
        MSDriving.VehicleTotalDistance = 0
        MSDriving.getTotalMass = 0
    end
end
MSDriving.CheckXP = function()
    for i=0, getNumActivePlayers()-1 do
        local player = getSpecificPlayer(i)
        if MSDriving.InVehicle and player:getVehicle():isDriver(player) and not player:isNPC() and not player:isDead() then
            local getVehicle = player:getVehicle()
            local getTrailer = getVehicle:getVehicleTowing()
            local getSpeed = getVehicle:getCurrentSpeedKmHour()
            local getDistance = MSDriving.VehicleSquare:DistToProper(getVehicle:getSquare()) * 0.001
            local condition = MSDriving.getVCondition(getVehicle)
            local perkDrivingLevel = player:getPerkLevel(MSDriving.PerkDriving)
            --test zone
            --
            if getTrailer then
                MSDriving.getTotalMass = getTrailer:getMass() + getVehicle:getMass()
            else
                MSDriving.getTotalMass = getVehicle:getMass()
            end
            if getDistance ~= 0 then
                if MSDriving.VehicleState and condition then
                    local Damage = MSDriving.compareVCondition(MSDriving.VehicleState, condition)
                    if MSDriving.Damaged then
                        player:getXp():AddXP(MSDriving.PerkDriving, (Damage*-1), true, false, false)
                        player:getXp():addXpMultiplier(MSDriving.PerkDriving,0,perkDrivingLevel,10)
                        MSDriving.VehicleTotalDistance = 0
                        MSDriving.Damaged = false
                        MSDriving.CheckIfLoseLevel(player, perkDrivingLevel)
                    else
                        local XPToGive = (getDistance * ((getSpeed * 0.1) + (MSDriving.getTotalMass*0.001))) * 4
                        if getSpeed < 0 then
                            if getTrailer then
                                XPToGive = XPToGive * 2
                            else
                                XPToGive = XPToGive / 2
                            end
                        end
                        player:getXp():AddXP(MSDriving.PerkDriving, XPToGive)
                    end
                end
                MSDriving.VehicleState = condition
                MSDriving.VehicleTotalDistance = (MSDriving.VehicleTotalDistance + (getDistance))
                MSDriving.GiveBackFuel(getVehicle, perkDrivingLevel)
                local mathsMul = ((MSDriving.minMul-1) + ((MSDriving.maxMul-MSDriving.minMul)*(perkDrivingLevel/10))) + 1
                if MSDriving.VehicleTotalDistance < mathsMul and MSDriving.VehicleTotalDistance ~= 0 then
                    player:getXp():addXpMultiplier(MSDriving.PerkDriving,((mathsMul-1)*((MSDriving.VehicleTotalDistance)/3))+1,perkDrivingLevel,10)
                elseif MSDriving.VehicleTotalDistance ~= 0 then
                    player:getXp():addXpMultiplier(MSDriving.PerkDriving,mathsMul,perkDrivingLevel,10)
                else
                    player:getXp():addXpMultiplier(MSDriving.PerkDriving,0,perkDrivingLevel,10)
                end
                MSDriving.VehicleSquare = getVehicle:getSquare()
                --print("Total distance: ",MSDriving.MathsUp00(MSDriving.VehicleTotalDistance),"m")
            end
        end
    end
end
Events.OnEnterVehicle.Add(MSDriving.OnEnterVehicle)
Events.OnExitVehicle.Add(MSDriving.OnExitVehicle)
Events.EveryOneMinute.Add(MSDriving.CheckXP)