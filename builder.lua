local json = require("json") -- JSON library for saving/loading progress

-- ✅ Define block data URL
local blockDataURL = "https://example.com/blockdata.lua"  -- Replace with actual URL

-- ✅ Download block data as output.lua (Only if it doesn't exist)
if not fs.exists("output.lua") then
    print("📥 Downloading block data...")
    shell.run("wget " .. blockDataURL .. " output.lua")

    -- Check if the file was downloaded
    if fs.exists("output.lua") then
        print("✅ Block data saved as output.lua. Ready for building.")
    else
        print("❌ Error: Failed to download block data.")
        return
    end
else
    print("⚡ Block data already exists. Skipping download.")
end

-- ✅ Position Tracking
local pos = {x = 0, y = 0, z = 0, dir = 0} -- Turtle's absolute position
local lastPlacedIndex = 1 -- Tracks last placed block
local referencePoint = nil -- Build start reference (absolute coords)

-- ✅ Calculates Storage Positions
local function calculateStoragePositions()
    if referencePoint then
        return {
            fuelChest = {x = referencePoint.x, y = referencePoint.y - 1, z = referencePoint.z - 4, dir = 2},
            materialChests = {
                ["minecraft:wool"]  = {x = referencePoint.x - 4, y = referencePoint.y, z = referencePoint.z - 4, dir = 2},
                ["minecraft:clay"]  = {x = referencePoint.x - 4, y = referencePoint.y + 1, z = referencePoint.z - 4, dir = 2},
                ["minecraft:dirt"]  = {x = referencePoint.x - 4, y = referencePoint.y + 2, z = referencePoint.z - 4, dir = 2},
                ["minecraft:grass"] = {x = referencePoint.x - 4, y = referencePoint.y + 3, z = referencePoint.z - 4, dir = 2},
                ["minecraft:stone"] = {x = referencePoint.x - 4, y = referencePoint.y + 4, z = referencePoint.z - 4, dir = 2},
                ["minecraft:log"]   = {x = referencePoint.x - 4, y = referencePoint.y + 5, z = referencePoint.z - 4, dir = 2}
            }
        }
    end
    return nil
end

-- ✅ GPS Movement Functions
local function moveTo(target)
    while pos.x ~= target.x do
        if pos.x < target.x then while pos.dir ~= 1 do turtle.turnRight() end
        else while pos.dir ~= 3 do turtle.turnRight() end
        end
        turtle.forward()
    end
    while pos.z ~= target.z do
        if pos.z < target.z then while pos.dir ~= 0 do turtle.turnRight() end
        else while pos.dir ~= 2 do turtle.turnRight() end
        end
        turtle.forward()
    end
    while pos.y < target.y do turtle.up() end
    while pos.y > target.y do turtle.down() end
end

-- ✅ Save/Load Functions
local function saveData(filename, data)
    local file = fs.open(filename, "w")
    file.write(json.encode(data))
    file.close()
end

local function loadData(filename)
    if fs.exists(filename) then
        local file = fs.open(filename, "r")
        local data = json.decode(file.readAll())
        file.close()
        return data
    end
    return nil
end

-- ✅ Resume Build Progress
local function saveProgress() saveData("progress.json", {lastPlacedIndex = lastPlacedIndex}) end
local function loadProgress() lastPlacedIndex = loadData("progress.json") and loadData("progress.json").lastPlacedIndex or 1 end
local function savePosition() saveData("position.json", pos) end
local function loadPosition() pos = loadData("position.json") or pos end
local function saveReferencePoint() saveData("reference.json", pos) end
local function loadReferencePoint() referencePoint = loadData("reference.json") end

-- ✅ Wait for `output.lua`
local function waitForFile(fileName)
    print("📂 Waiting for file:", fileName)
    while not fs.exists(fileName) do sleep(1) end
    print("✅ File detected:", fileName)
end

-- ✅ Load Block Data
local function loadBlocksFromFile(fileName)
    local chunk = loadfile(fileName)
    if chunk then
        local success, data = pcall(chunk)
        if success then
            for _, block in ipairs(data) do
                if block.block and not block.block:match("^minecraft:") then
                    block.block = "minecraft:" .. block.block
                end
            end
            return data
        end
    end
    return {}
end

-- ✅ Restock Function (Finds Material in Storage)
local function isPathClear()
    return not turtle.detect()
end

local function findChestAccess(chestPos)
    local possiblePositions = {
        {x = chestPos.x, y = chestPos.y, z = chestPos.z + 1, dir = 2},
        {x = chestPos.x, y = chestPos.y, z = chestPos.z - 1, dir = 0},
        {x = chestPos.x + 1, y = chestPos.y, z = chestPos.z, dir = 3},
        {x = chestPos.x - 1, y = chestPos.y, z = chestPos.z, dir = 1}
    }

    for _, pos in ipairs(possiblePositions) do
        moveTo(pos)
        while pos.dir ~= chestPos.dir do turtle.turnRight() end
        if isPathClear() then return true end
    end

    return false
end

local function restock(block)
    local storage = calculateStoragePositions()
    if not storage then return false end

    local chestPos = storage.materialChests[block]
    if not chestPos then return false end

    if findChestAccess(chestPos) then
        local restocked = 0
        for _ = 1, 2 do
            if turtle.suck(64) then restocked = restocked + 1 else break end
        end

        returnToLastPosition()
        return restocked > 0
    end

    return false
end

-- ✅ Refuel Turtle (Uses Fuel Chest)
local function refuelTurtle()
    if turtle.getFuelLevel() >= 1000 then return true end

    local storage = calculateStoragePositions()
    if not storage then return false end

    savePosition()
    moveTo(storage.fuelChest)

    local refueled = 0
    for _ = 1, 2 do
        if turtle.suck(1) then turtle.refuel() refueled = refueled + 1 end
    end

    returnToLastPosition()
    return refueled > 0
end

-- ✅ Start Build Process
local function start()
    loadReferencePoint()
    waitForFile("output.lua")

    if not referencePoint then
        moveTo({x = pos.x, y = pos.y, z = pos.z + 3})
        saveReferencePoint()
    end

    buildSchematic("output.lua")
end

start()
