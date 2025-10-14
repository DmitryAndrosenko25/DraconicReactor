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
	while isRunExtreme do
	
	
		-- если сила щита реактора БОЛЬШЕ 0.1% от МАКСИМУМА и сила щита больще ПОТРЕБЛЕНИЯ + 1200 ТО ПОТРЕБЛЯЙ
		if ((reactorInfo("maxFieldStrength") * 0.001) <	reactorInfo("fieldStrength")) and (reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") + 1200))then
			-- если сила щита достаточна И потребление избыточно ТО
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate"))
			-- выставляем входящий инпут на значения потребления щита
		elseif ((reactorInfo("maxFieldStrength") * 0.0009) < reactorInfo("fieldStrength")) and (reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") + 1200)) then
			-- если сила щита НЕ достаточна И потребление избыточно ТО
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") + 600)		
		else
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") + 2000)
		end
		coroutine.yield() -- Уступает управление
	
	
	
	
	
	
	
		--[[ ЭТО РАБОЧИЙ АЛГОРИТМ
		-- если сила щита реактора БОЛЬШЕ 0.1% от МАКСИМУМА и сила щита больще ПОТРЕБЛЕНИЯ + 1200 ТО ПОТРЕБЛЯЙ
		if ((reactorInfo("maxFieldStrength") * 0.001) <	reactorInfo("fieldStrength")) and (reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") + 1200))then
			-- если сила щита достаточна И потребление избыточно ТО
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate"))
			-- выставляем входящий инпут на значения потребления щита
		elseif ((reactorInfo("maxFieldStrength") * 0.0009) < reactorInfo("fieldStrength")) and (reactorInfo("fieldStrength") > (reactorInfo("fieldDrainRate") + 1200)) then
			-- если сила щита НЕ достаточна И потребление избыточно ТО
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") + 600)		
		else
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") + 2000)
		end
		coroutine.yield() -- Уступает управление
		]]
		
		
	end
	print("Я умер! Умер навсегда! З.Ы. Я был Экстримальный щит")
end

return shield -- Возврат модуля управления щита