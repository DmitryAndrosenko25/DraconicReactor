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
		if reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") * 1.5 ) then
			shieldbalance = 1
		elseif reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") * 1.05 ) then
			if shieldbalance > 1 then
				shieldbalance = shieldbalance - 1
			end
			
		elseif reactorInfo("fieldStrength") < (reactorInfo("fieldDrainRate") * 1.03 ) then
			shieldbalance = shieldbalance + 1
		end
		
		if (reactorInfo("fieldStrength") < (reactorInfo("fieldDrainRate") * 1.02 )) then
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") * 1.1)
			shieldbalance = shieldbalance + 5
		else
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate")	* (1 + (0.0001 * shieldbalance))) --0.0001
		end
		
		
		coroutine.yield() -- Уступает управление
	end
	print("Я умер! Умер навсегда! З.Ы. Я был Экстримальный щит")
end

return shield -- Возврат модуля управления щита