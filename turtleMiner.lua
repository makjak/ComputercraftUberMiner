-- Autominer turtle script thing
-- Written by Liam Svanåsbakken Crouch
-- Start with the arguments: <depth> <digDepth> <digWidth> <minimumCoal>

local currentPosX = 0
local currentPosY = 0
local currentPosZ = 0
local rotation = 0
local ROTATION_FORWARD = 0
local ROTATION_RIGHT = 1
local ROTATION_BACKWARDS = 2
local ROTATION_LEFT = 3
local SAFETY_MARGIN = 30
local ZLENGTH = 20
local SAVEFILE_NAME = "miner.save"

function distanceFromHome()
	return math.abs(currentPosX)+math.abs(currentPosY)+math.abs(currentPosZ)
end

function shouldGoHome()
	if turtle.getFuelLevel() ~= "unlimited" then
		local minimumDistance = turtle.getFuelLevel() - SAFETY_MARGIN
		if distanceFromHome() > minimumDistance then
			return true;
		end
	end

	for i = 1, 16, 1 do
		if turtle.getItemSpace(i) == 0 then
			return true;
		end
	end

	return false
end

function forward()
	local success = turtle.forward()
	if success then
		if rotation == ROTATION_FORWARD then
			currentPosZ = currentPosZ + 1
		elseif rotation == ROTATION_RIGHT then
			currentPosX = currentPosX + 1
		elseif rotation == ROTATION_BACKWARDS then
			currentPosZ = currentPosZ - 1
		elseif rotation == ROTATION_LEFT then
			currentPosX = currentPosX - 1
		else
			print "Unhandled rotation!"
		end
	end
	return success
end
function back()
	local success = turtle.back()
	if success then
		if rotation == ROTATION_FORWARD then
			currentPosZ = currentPosZ - 1
		elseif rotation == ROTATION_RIGHT then
			currentPosX = currentPosX - 1
		elseif rotation == ROTATION_BACKWARDS then
			currentPosZ = currentPosZ + 1
		elseif rotation == ROTATION_LEFT then
			currentPosX = currentPosX + 1
		else
			print "Unhandled rotation!"
		end
	end
	return success
end
function up()
	local success = turtle.up()

	if success then
		currentPosY = currentPosY + 1
	else
		print("Failed digging up!")
	end

	return success
end
function down()
	local success = turtle.down()

	if success then
		currentPosY = currentPosY - 1
	else
		print("Failed digging down!")
	end

	return success
end

function turnLeft()
	local success = turtle.turnLeft()
	if success then
		if rotation == ROTATION_FORWARD then
			rotation = ROTATION_LEFT
		else
			rotation = rotation - 1
		end
	end
	return success
end

function turnRight()
	local success = turtle.turnRight()
	if success then
		if rotation == ROTATION_LEFT then
			rotation = ROTATION_FORWARD
		else
			rotation = rotation + 1
		end
	end
	return success
end

--Expects turtle to be facing "out"
function refuel(wantedLevel)
	turnLeft()
	print("Refueling. Waiting for " .. tostring(wantedLevel) .. " fuel")
	turtle.select(1)
	while turtle.getFuelLevel() < wantedLevel do
		turtle.suck(1)
		turtle.refuel(1)
	end
	turnRight()
end

--Expects turtle to be facing "out"
function unloadPayload()
	turnRight()
	print "Unloading payload..."
	for i = 1, 16, 1 do
		turtle.select(i)
		turtle.drop()
	end
	turnLeft()
end

function digForward()
	if turtle.detect() then
		turtle.dig()
	end
	return forward()
end
function digUp()
	if turtle.detectUp() then
		turtle.digUp()
	end
	return up()
end
function digDown()
	if turtle.detectDown() then
		turtle.digDown()
	end
	return down()
end

function safeDigForward()
	local digged = false
	while digged == false do
		digged = digForward()
		turtle.attack()
	end
end
function safeDigUp()
	local digged = false
	while digged == false do
		digged = digUp()
		turtle.attackUp()
	end
end
function safeDigDown()
	local digged = false
	while digged == false do
		digged = digDown()
		turtle.attackDown()
	end
end

function removeBloat()
	for i = 1, 16, 1 do
		turtle.select(i)
		local slotData = turtle.getItemDetail(i)
		if slotData then
			if slotData["name"] == "minecraft:cobblestone" or slotData["name"] == "minecraft:gravel" or slotData["name"] == "minecraft:dirt" then
				turtle.drop()
			end
		end
	end
end

function goHome()
	print("Going home!")
	travelToPoint(0,0)

	print("Aligning Y")
	--Y position
	if currentPosY < 0 then
		while currentPosY ~= 0 do
			digUp()
		end
	else
		while currentPosY ~= 0 do
			digDown()
		end
	end
	--Turning correct way
	while rotation ~= ROTATION_FORWARD do
		turnLeft()
	end
end

function travelToPoint(xTarget, zTarget)
	print "Aligning X"
	if currentPosX < xTarget then
		while rotation ~= ROTATION_RIGHT do
			turnLeft()
		end
	else
		while rotation ~= ROTATION_LEFT do
			turnLeft()
		end
	end

	while currentPosX ~= xTarget do
		safeDigForward()
	end
	removeBloat()

	--Z position
	print("Aligning Z")
	if currentPosZ < zTarget then
		while rotation ~= ROTATION_FORWARD do
			turnLeft()
		end
	else
		while rotation ~= ROTATION_BACKWARDS do
			turnLeft()
		end
	end

	while currentPosZ ~= zTarget do
		safeDigForward()
	end
	removeBloat()
end

function saveProgress(digged, direction, turn)
	local saveData = tostring(currentPosX) .. "," .. tostring(currentPosZ) .. "," .. tostring(digged) .. "," .. tostring(direction) .. "," .. tostring(turn)

	h = fs.open(SAVEFILE_NAME, "w")
	h.write(saveData)
	h.close()
end

function loadProgress()
	if fs.exists(SAVEFILE_NAME) == true then
	        h = fs.open(SAVEFILE_NAME, "r")
	        text = h.readAll()
	        h.close()
	        --Create table
	        local returnDataTable = {}
	        local index = 1
	        for i in string.gmatch(text, '([^,]+)') do
	        	returnDataTable[index] = i
	        	index = index + 1
	        end

	        return tonumber(returnDataTable[1]), tonumber(returnDataTable[2]), tonumber(returnDataTable[3]), tonumber(returnDataTable[4]), tonumber(returnDataTable[5])
	else
	        return 0,0,0,0,0
	end
end

--Main program loop

print "Welcome to petterroeas mining bot!"

local args = {...}

if #args == 4 then
	local startHeight = tonumber(args[1])
	local digDownHeight = tonumber(args[2])
	local digLength = tonumber(args[3])
	local wantedFuelLevel = tonumber(args[4])

	if digDownHeight >= SAFETY_MARGIN-10 then
		print "Please enter a smaller dig down height."
	else
		while true do

			local xTarget, zTarget, digged, direction, turn = loadProgress()

			unloadPayload()

			if turtle.getFuelLevel() ~= "unlimited" then
				refuel(wantedFuelLevel)
			end
			--Get down to required depth
			for i = 0, startHeight, 1 do
				digDown()
			end
			removeBloat()

			--Travel to last saved position
			print("Traveling to last saved position")
			travelToPoint(xTarget, zTarget)

			--Make sure we have the correct heading
			if direction == 0 then
				while rotation ~= ROTATION_FORWARD do
					turnLeft()
				end
			else
				while rotation ~= ROTATION_BACKWARDS do
					turnLeft()
				end
			end

			--turn = 0
			
			--Dig stuff
			print("Started digging")
			while shouldGoHome() ~= true do
				if turn == 0 then
					for i = 0, digDownHeight, 1 do
						safeDigDown()
					end
					turn = 1

				else
					for i = 0, digDownHeight, 1 do
						safeDigUp()
					end
					turn = 0
				end

				if digged >= digLength then
					if direction == 0 then
						turnLeft()
						safeDigForward()
						turnLeft()
						direction = 1
					else
						turnRight()
						safeDigForward()
						turnRight()
						direction = 0
					end
					digged = 0
				else
					safeDigForward()
				end

				removeBloat()
				digged = digged + 1
				-- print(tostring(shouldGoHome()) .. ", " .. distanceFromHome())
				print(distanceFromHome() .. " blocks from home. " .. turtle.getFuelLevel() .. " fuel left.")
			end
			saveProgress(digged, direction, turn)
			goHome()
		end
	end
else
	print "Missing arguments"
end
