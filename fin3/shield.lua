-- ЭТОТ МОДУЛЬ КОНТРОЛИРУЕТ ЩИТ В СОСТОЯНИИ
-- РЕАКТОРА running / stopping
local shield = {}
local component = require("component")
local shieldreactor = nil
local shieldfluxIn = nil
local myLevel = nil
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
		--if (((reactorInfo("maxFieldStrength") / reactorInfo("fieldStrength")) *100) < 5) then -- ПРИ ТЕСТИРОВАНИИ 13000 ГРАДУСОВ ЩИТ ДЕРЖАЛСЯ В ПРЕДЕЛАХ 8.63%
		if ((reactorInfo("maxFieldStrength") * 0.04) <	reactorInfo("fieldStrength")) then -- ПРИ ТЕСТИРОВАНИИ 13000 ГРАДУСОВ ЩИТ ДЕРЖАЛСЯ В ПРЕДЕЛАХ 8.63%
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") + 300)	 			  -- НУЖНО ДОБАВИТЬ АЛГОРИТМ ПОНИЖЕНИЯ В ТАКОМ СЛУЧАЕ ЩИТА ДО, НУ Я ХЗ... 5%
		else
			shieldfluxIn.setFlowOverride(reactorInfo("fieldDrainRate") + 0) --200
		end
		coroutine.yield() -- Уступает управление							
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