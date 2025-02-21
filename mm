-- Configurations
local baseUrl = "https://raw.githubusercontent.com/robertjojo123/olympus/refs/heads/main/output_"
local totalFiles = 122 -- Number of files to process
local startupFile = "startup.lua" -- The file to copy into each Turtle
local turtleSide = "right" -- The side where Turtles will be placed

local fileCounter = 1 -- Keeps track of the next file to assign

print("Waiting for Turtles to be placed to the right...")

while fileCounter <= totalFiles do
    -- Wait until a Turtle is placed
    while not peripheral.isPresent(turtleSide) or peripheral.getType(turtleSide) ~= "turtle" do
        sleep(1) -- Check every second
    end

    print("Turtle detected! Assigning output_" .. fileCounter .. ".lua")

    -- Define file URL (always saves as output.lua)
    local fileUrl = baseUrl .. fileCounter .. ".lua"

    -- Create a startup script on the Turtle
    local startupScript = [[
shell.run("wget ]] .. fileUrl .. [[ output.lua")
shell.run("reboot") -- Reboot after downloading
]]

    -- Write `startup.lua` inside the Turtle
    local startupPath = turtleSide .. "/startup.lua"
    local file = fs.open(startupPath, "w")
    if file then
        file.write(startupScript)
        file.close()
        print("Created startup.lua inside Turtle")
    else
        print("ERROR: Could not write startup.lua to Turtle!")
        return
    end

    -- Copy the extra `startup_turtle.lua` into the Turtle
    if fs.exists(startupFile) then
        fs.copy(startupFile, turtleSide .. "/startup_turtle.lua")
        print("Copied " .. startupFile .. " to Turtle")
    else
        print("ERROR: " .. startupFile .. " not found!")
        return
    end

    -- Manually reboot the Turtle by "pressing" the power button
    peripheral.call(turtleSide, "turnOn")

    print("Turtle started and will reboot after downloading.")

    -- Move to the next file for the next Turtle
    fileCounter = fileCounter + 1

    -- Wait for the Turtle to be removed before continuing
    while peripheral.isPresent(turtleSide) do
        sleep(1)
    end

    print("Turtle removed. Ready for next one.")
end

print("All files assigned!")
