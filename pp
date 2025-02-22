-- ✅ Placer Turtle Settings
local blockDataBaseUrl = "https://raw.githubusercontent.com/robertjojo123/olympus2/refs/heads/main/output_"
local totalFiles = 122
local startIndex = 1
local diskSide = "left" -- The Worker Turtle will have the Disk Drive on this side

-- ✅ Function: Wait for Previous Worker Turtle to be Removed
local function waitForTurtleRemoval()
    while turtle.detect() do
        print("⏳ Waiting for previous Worker Turtle to be removed...")
        sleep(2)
    end
end

-- ✅ Function: Place and Setup New Worker Turtle
local function deployWorker(turtleIndex)
    print("📦 Placing Worker Turtle for `output_" .. turtleIndex .. ".lua`")
    
    -- Wait until there's space
    waitForTurtleRemoval()
    
    -- Place the Worker Turtle
    if not turtle.place() then
        print("❌ ERROR: Failed to place Worker Turtle!")
        return
    end

    -- Wrap the Worker Turtle as a peripheral
    local worker = peripheral.wrap("front")
    if not worker then
        print("❌ ERROR: Could not detect placed Worker Turtle!")
        return
    end

    -- Send the Worker Turtle its assigned block data index
    print("🔢 Assigning Block Data Index:", turtleIndex)
    local file = fs.open("block_data_index.txt", "w")
    file.write(tostring(turtleIndex))
    file.close()
    worker.run("cp block_data_index.txt /block_data_index.txt")

    -- Tell the Worker Turtle to copy `startup.lua` from the Disk Drive next to it
    print("📂 Instructing Worker Turtle to copy `startup.lua` from Disk Drive...")
    worker.run("cp /disk/startup.lua /startup")

    -- Reboot the Worker Turtle so it automatically starts building
    print("🔄 Rebooting Worker Turtle!")
    worker.run("reboot")
end

-- ✅ Main Loop: Deploy Worker Turtles Sequentially
for i = startIndex, totalFiles do
    deployWorker(i)
    print("✅ Worker Turtle #" .. i .. " is now running! Waiting for removal before placing the next one...")
    waitForTurtleRemoval() -- Wait before placing the next Turtle
end

print("🎉 All Worker Turtles deployed!")
