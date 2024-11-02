local reactorHeating = {}

local component = require("component")
local reactorCheck = require("reactorCheck")

local adresses = reactorCheck.reactorSearchAddress()
local reactor = component.proxy(adresses[1]) -- Подключение к реактору и гейтам
local fluxInGate = component.proxy(adresses[2])
local fluxOutGate = component.proxy(adresses[3])

local function rInfoHeating(info) --- на вход параметр реактора в string ..на выход значение 
	local st = reactor.getReactorInfo()
	return st[info]
end

local function charge50field() -- Заряд щита
	print(rInfoHeating("status"))
    reactor.chargeReactor() -- ВКЛ разогрев реактора
	while rInfoHeating("status") ~= "warming_up" do
		print("реактор стартует на разогрев...")
		reactor.stopReactor() -- stopReactor
		reactor.chargeReactor() -- ВКЛ разогрев реактора
		os.sleep(1)
	end	
	print(rInfoHeating("status"))
	fluxInGate.setOverrideEnabled(true) -- Разрешение на управление входящим гейтом программе 
	fluxInGate.setFlowOverride(1)
	os.sleep(0.05)
	local fieldCurrent = rInfoHeating("fieldStrength")
	local field50Max = (rInfoHeating("maxFieldStrength")/2)
	while ((fieldCurrent + 1) <= field50Max) do
		fluxInGate.setFlowOverride(((field50Max - fieldCurrent) / 10) + 10 )
		os.sleep(0.05) -- Ждем 
		fieldCurrent = rInfoHeating("fieldStrength")
	end
	fluxInGate.setFlowOverride(0)
	print("Щит реактора заряжен на 50%")
end

local function charge50saturation() -- Заряд Сатурации
	print("Начало сатурации")
	local saturationCurrent = rInfoHeating("energySaturation")
	local saturation50Max = (rInfoHeating("maxEnergySaturation")/2)
	fluxInGate.setFlowOverride(1)
	os.sleep(0.05)
	while ((saturationCurrent + 1) < saturation50Max) do
		saturationCurrent = rInfoHeating("energySaturation")
		fluxInGate.setFlowOverride(((saturation50Max - saturationCurrent) / 40) + 10 )
		os.sleep(0.05) -- Ждем 
		saturationCurrent = rInfoHeating("energySaturation")
	end
	fluxInGate.setFlowOverride(0)
	print("Насыщение реактора - 50%")
end

local function heating()
	local tCurrent = rInfoHeating("temperature")
	local tDelta = 0
	fluxInGate.setFlowOverride(100)
	local inFlow = fluxInGate.getFlow()
	
	if tCurrent < 2000 then
		while tDelta < 0.1 do
			local tStart = rInfoHeating("temperature")
			os.sleep(0.05) -- Ждем 
			local tEnd = rInfoHeating("temperature")
			fluxInGate.setFlowOverride(inFlow * 1.1)
			inFlow = fluxInGate.getFlow()
			tDelta = tEnd - tStart            
		end
	end	
		
	while tCurrent < 2000 do
		fluxInGate.setFlowOverride((((2000 - tCurrent) / 2) * inFlow) + 1)
		os.sleep(0.05) -- Ждем 
		tCurrent = rInfoHeating("temperature")
	end
fluxInGate.setFlowOverride(0)
print("Ядро разогрето до 2000 градусов и готово к запуску")
end

function reactorHeating.startHeating()    
    if (rInfoHeating("maxFieldStrength")/2) > rInfoHeating("fieldStrength") then
		charge50field() --  вызов функции заряда щита
	end
	if (rInfoHeating("maxEnergySaturation")/2) > rInfoHeating("energySaturation") then
		charge50saturation() --вызов функции сатурации
	end	
    heating() --  вызов функции разогрева реактора
end

-- reactorHeating.startHeating() 

return reactorHeating
