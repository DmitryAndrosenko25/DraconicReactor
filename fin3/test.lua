local component = require("component")
local reactorInit = require("reactorInit")
-- local reactorHeating = require("reactorHeating")
-- local reactorShield = require("shield")

local a = reactorInit.getGatesAddresses() -- Получаем адреса по порядку: 1 реактор, 2 гейт вход, 3 гейт выход
local reactorAddress = a[1]
print("reactor ="..reactorAddress)
local fluxInAddress = a[2]
print("fluxInAddress ="..fluxInAddress)
local fluxOutAddress = a[3]
print("fluxOutAddress ="..fluxOutAddress) --temporary///////////////////

-- local reactor = component.proxy(reactorAddress)
-- local fluxIn = component.proxy(fluxInAddress)
-- local fluxOut = component.proxy(fluxOutAddress)

