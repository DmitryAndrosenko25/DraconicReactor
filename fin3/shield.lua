-- ЭТОТ МОДУЛЬ КОНТРОЛИРУЕТ ЩИТ В СОСТОЯНИИ
-- РЕАКТОРА running / stopping
local shield = {}
local component = require("component")
local shieldreactor = nil
local shieldfluxIn = nil
local myLevel = 1.3
local isRunExtreme = false
local isRun = false

function shield.setReactor(adressReactor, ardessFluxIn)
	shieldreactor = component.proxy(adressReactor)
	shieldfluxIn = component.proxy(ardessFluxIn)
	shieldfluxIn.setOverrideEnabled(true)
	print("reactor shield is set!")
end

function shield.setLevel(tempValue) -- замена множителя щита
	myLevel = tempValue
end

local function reactorInfo(info) --- на вход параметр реактора в string ..на выход значение 
    local st = shieldreactor.getReactorInfo()
    return st[info]
end

function shield.runShield()
	isRun = true
	isRunExtreme = false
	print("Shield has been run")
	while isRun do
		shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") * myLevel)	
		coroutine.yield() -- Уступает управление
	end
	print("Я умер! Умер навсегда! З.Ы. Я был обычный щит")
end

function shield.stopShield()
	shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") * 1.5)
	isRun = false
	isRunExtreme = false
	print("stopShield() выл вызван, все щиты остановлены. Вроде...")	
end

function shield.runShieldExtreme()
	isRun = false
	isRunExtreme = true
	print("Extreme shield has been run")
	local shieldbalance = 1
	
	while isRunExtreme do
	
		-- shiledForceIn = shieldfluxIn.getFlow()
		-- ЕСЛИ ЗАРЯД ЩИТА БОЛЬШЕ 0.1% ОТ МАКСИМУМА И БОЛЬШЕ 101% ОТ ПОТРЕБЛЕНИЯ
		-- if (reactorInfo("fieldStrength") > (reactorInfo("maxFieldStrength") * 0.001)) and (reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") * 1.01 )) then
		if (reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") * 1.01 )) then
			if reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") * 1.1 ) then
				shieldbalance = 1 --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			elseif reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") * 1.03 ) then
				if shieldbalance > 0 then
					shieldbalance = shieldbalance - 1
				end 
				
				-- 101 ЭТО ВИДИМО ОЧЕНЬ МАЛО!!!!!!!!!!
				
				
			elseif reactorInfo("fieldStrength") < (reactorInfo("fieldDrainRate") * 1.01 ) then
				shieldbalance = shieldbalance + 1
			end
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate")	* (1 + (0.0001 * shieldbalance))) --?????????????????????????
		end
		coroutine.yield() -- Уступает управление
	end
	print("Я умер! Умер навсегда! З.Ы. Я был Экстримальный щит")
end

return shield -- Возврат модуля управления щита