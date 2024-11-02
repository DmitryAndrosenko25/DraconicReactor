local shield = {}
component = require("component")
local shieldreactor = nil
local shieldfluxIn = nil
local shieldfluxOut = nil
local myLevel = nil
local isRunExtreme = false
local isRun = false

function shield.setReactor(shieldReactor, shieldFluxIn, shieldFluxOut)
	shieldreactor = component.proxy(shieldReactor)
	shieldfluxIn = component.proxy(shieldFluxIn)
	shieldfluxOut = component.proxy(shieldFluxOut)
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
	-- os.sleep(0.05)
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
	-- os.sleep(0.05)
	isRun = false
	isRunExtreme = false
	print("stopShield() выл вызван, все щиты остановлены. Вроде...")
	
end

function shield.runShieldExtreme()
	-- os.sleep(0.05)
	isRun = false
	isRunExtreme = true
	print("Extreme shield has been run")
	while isRunExtreme do
		shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") + 300)	-- ПРИ ТЕСТИРОВАНИИ 13000 ГРАДУСОВ ЩИТ ДЕРЖАЛСЯ В ПРЕДЕЛАХ 8.63% 
		coroutine.yield() -- Уступает управление							-- НУЖНО ДОБАВИТЬ АЛГОРИТМ ПОНИЖЕНИЯ В ТАКОМ СЛУЧАЕ ЩИТА ДО, НУ Я ХЗ... 2%
	end
	print("Я умер! Умер навсегда! З.Ы. Я был Экстримальный щит")
end

return shield -- Возврат модуля управления щита

		--*1 	~ от 0 до ~0.5%  Экстримальный вариант  = rInfo("fieldDrainRate") + 100
		--1.05 	~4 до 9
		--*1.1	~9.00 - 9.30%
		--*1.5 	~33.33
		--*2 	50%
		--*3 	~66.7
		--*4 	~75.11
		--*5	~80