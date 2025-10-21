-- КОНСТАНТЫ И КОЭФФИЦИЕНТЫ
local DT = 0.05             -- Интервал времени (равный вашему os.sleep)
local Kp = -0.1             -- НАЧАЛЬНЫЕ ОТРИЦАТЕЛЬНЫЕ ЗНАЧЕНИЯ!
local Ki = -0.0001
local Kd = -1.0
local INTEGRAL_LIMIT = 100000.0 -- Защита от насыщения интеграла (Anti-Windup)
local FLOW_LIMIT_MAX = 5000000.0 -- Максимальный физический поток гейта

-- ПЕРЕМЕННЫЕ СОСТОЯНИЯ (хранят историю)
local integral = 0.0        -- Накопленная ошибка
local last_error = 0.0      -- Ошибка из предыдущего цикла




-- Внутри цикла while true do:

-- 1. Считывание текущего значения
local tCurrent = rInfo(reactor, "temperature")

-- 2. Вычисление ошибки
local error = tCurrent - targetTemp -- Положительна, если слишком горячо

-- 3. Пропорциональный член (P)
local P = Kp * error

-- 4. Интегральный член (I)
integral = integral + (error * DT) 
-- Защита от насыщения интеграла (Anti-Windup)
integral = math.min(math.max(integral, -INTEGRAL_LIMIT), INTEGRAL_LIMIT) 
local I = Ki * integral

-- 5. Дифференциальный член (D)
local derivative = (error - last_error) / DT
local D = Kd * derivative

-- 6. Общее управляющее воздействие (Новый поток)
local output_flow = P + I + D

-- 7. Ограничение физическим лимитом
local newFlow = math.max(FLOW_LIMIT_MIN, math.min(FLOW_LIMIT_MAX, output_flow))

-- 8. Установка потока и обновление состояния
fluxOut.setFlowOverride(newFlow)
last_error = error -- Сохраняем ошибку для следующего цикла

-- 9. Пауза
os.sleep(DT)

