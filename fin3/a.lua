local a = {}

local text = "local text"
globalText = "globalText"

print(text)
print("in module a")
print(variableB)

local function isA ()
	print ("in  function isA in module a")
	print (text)
	local result = "@@"
	if text == "local text" then
		result = globalText
	end
	
	return result
end

function a.visibleC()
	isA()

end



return a