local component = require("component")
local reactorInit = require("reactorInit")
local reactorUpTo2000 = require("reactorUpTo2000")
local reactorToWorkTemperature = require("reactorToWorkTemperature")
-- local shield = require("shield")

local a = reactorInit.getGatesAddresses() -- Получаем адреса по порядку: 1 реактор, 2 гейт вход, 3 гейт выход
local reactorAddress = a[1]
print("reactor ="..reactorAddress)
local fluxInAddress = a[2]
print("fluxInAddress ="..fluxInAddress)
local fluxOutAddress = a[3]
print("fluxOutAddress ="..fluxOutAddress) --temporary///////////////////

-- reactorInit = nil			-- Эти две строки нужны 
-- collectgarbage("collect")	-- чтобы избавится от модуля и освободить память  НЕ РАБОТАЕТ

local reactor = component.proxy(reactorAddress)
local fluxIn = component.proxy(fluxInAddress)
local fluxOut = component.proxy(fluxOutAddress)

local function rInfo(info) --- на вход параметр реактора в string ..на выход значение 
	local st = reactor.getReactorInfo()
	return st[info]
end

--[[=======================================================================
		ЭТОТ БЛОК НУЖЕН ИСКЛЮЧИТЕЛЬНО ДЛЯ ТЕСТИРОВАНИЯ ПРОГРАММЫ]]--

-- local tempMAX = 13000
local tempMAX = 8000
 -- tempMAX = 13000


--=======================================================================


if (rInfo("temperature") < 2000) then
	print("В потоке тест стартую поднятие температуры до 2000")
	reactorUpTo2000.to2000(reactorAddress, fluxInAddress, fluxOutAddress)
end


reactorToWorkTemperature.startHeating(reactorAddress, fluxInAddress, fluxOutAddress, tempMAX)
