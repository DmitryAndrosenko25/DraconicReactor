-- ПЕРЕРАБОТАННЫЙ МОДУЛЬ reactorToWorkTemperature.lua
-- Управляет разогревом и стабилизацией температуры реактора с помощью ПИД-регулятора
-- Добавлено логирование в файл pid_log.csv

local reactorToWorkTemperature = {}

local component = require("component")
local shield = require("shield")
local reactor = nil
local fluxInGate = nil
local fluxOutGate = nil

----------------------------------------------------------
-- PID параметры (подбираются вручную)
----------------------------------------------------------
local Kp = 0.8     -- Пропорциональный коэффициент
local Ki = 0.02    -- Интегральный коэффициент
local Kd = 0.5     -- Дифференциальный коэффициент

----------------------------------------------------------
-- Прочие настройки
----------------------------------------------------------
local dt = 0.1               -- Интервал обновления (сек)
local integralLimit = 20000  -- ограничение интеграла (anti-windup)
local logFileName = "pid_log.csv"
----------------------------------------------------------

-- Вспомогательная функция
local function rInfo(info)
	local st = reactor.getReactorInfo()
	return st[info]
end

-- Запуск реактора, если он не активен
local function starter()
	fluxOutGate.setOverrideEnabled(true)
	fluxOutGate.setFlowOverride(0)

	if rInfo("status") ~= "running" then
		print("Попытка запуска реактора...")
		if reactor.activateReactor() then
			print("Реактор успешно запущен (из PID-модуля)")
		else
			local temp = fluxInGate.getFlow()
			while not reactor.activateReactor() do
				temp = temp + 1
				fluxInGate.setFlowOverride(temp)
				os.sleep(0.05)
			end
			print("Реактор успешно запущен (из PID-модуля)")
		end
	else
		print("Реактор уже работает")
	end
end

----------------------------------------------------------
-- Функция записи строки в CSV лог
----------------------------------------------------------
local function writeLog(file, t, temp, error, flow, Kp, Ki, Kd)
	file:write(string.format("%d,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n", t, temp, error, flow, Kp, Ki, Kd))
end

----------------------------------------------------------
-- Основная функция разогрева и стабилизации температуры
----------------------------------------------------------
function reactorToWorkTemperature.startHeating(reactorAddress, fluxInAddress, fluxOutAddress, tempMax)

	reactor = component.proxy(reactorAddress)
	fluxInGate = component.proxy(fluxInAddress)
	fluxOutGate = component.proxy(fluxOutAddress)

	-- Настройка щитов
	print("→ Устанавливается экстремальный щит")
	local coroutineShieldExtreme = coroutine.create(shield.runShieldExtreme)

	print("→ Устанавливается безопасный щит")
	shield.setReactor(reactorAddress, fluxInAddress)
	shield.setLevel(1.4)
	local coroutineShield = coroutine.create(shield.runShield)
	coroutine.resume(coroutineShield)
	print("✓ Безопасный щит активен")

	-- Запуск реактора
	if rInfo("status") ~= "running" then
		starter()
	end

	----------------------------------------------------------
	-- PID-переменные
	----------------------------------------------------------
	local setpoint = tempMax
	local integral = 0
	local prev_error = 0
	local timeStep = 0

	print(string.format("→ Начинается ПИД-контроль температуры до %.0f°C", tempMax))
	fluxOutGate.setOverrideEnabled(true)
	fluxOutGate.setFlowOverride(rInfo("generationRate"))  -- стартовое значение

	----------------------------------------------------------
	-- Подготовка файла лога
	----------------------------------------------------------
	local file = io.open(logFileName, "w")
	if file then
		file:write("time,temp,error,flow,Kp,Ki,Kd\n")
	else
		print("⚠️  Ошибка: не удалось открыть файл лога pid_log.csv для записи.")
		return
	end

	local shieldCount = 0
	local isRunning = true

	while isRunning do
		local temp = rInfo("temperature")
		local error = setpoint - temp
		integral = integral + error * dt

		-- Anti-windup
		if integral > integralLimit then integral = integralLimit end
		if integral < -integralLimit then integral = -integralLimit end

		local derivative = (error - prev_error) / dt

		-- PID формула
		local output = (Kp * error) + (Ki * integral) + (Kd * derivative)

		-- Ограничим поток (flow)
		local baseFlow = rInfo("generationRate")
		local newFlow = baseFlow + output
		if newFlow < 0 then newFlow = 0 end
		if newFlow > baseFlow * 1.5 then newFlow = baseFlow * 1.5 end

		fluxOutGate.setFlowOverride(newFlow)

		-- Контроль щита
		if math.abs(error) <= 0.2 then
			shieldCount = shieldCount + 1
		else
			shieldCount = 0
		end
		if shieldCount >= 150 then
			coroutine.resume(coroutineShieldExtreme)
		else
			coroutine.resume(coroutineShield)
		end

		-- Логирование
		writeLog(file, timeStep, temp, error, newFlow, Kp, Ki, Kd)

		-- Условия остановки по топливу
		if ((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100) >= 80 then
			print("⚠️  Топливо израсходовано на 80%, реактор останавливается.")
			reactor.stopReactor()
			isRunning = false
		end

		prev_error = error
		timeStep = timeStep + dt
		os.sleep(dt)
	end

	file:close()
	print("✓ PID-логирование завершено. Файл: pid_log.csv")
	print(string.format("Реактор стабилизирован при температуре %.2f°C", rInfo("temperature")))
end

return reactorToWorkTemperature
