local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local tool = Instance.new("Tool")
tool.Name = "BlackHole V2" -- Set the tool's name to "blackhole"
tool.RequiresHandle = false -- No handle needed
tool.Parent = player.Backpack -- Parent the tool to the player's backpack

local frozenParts = {}
local Forces = {}
local redBall = nil -- Variable to store the red ball
local nocolide = {} -- Table to store parts that should not collide with the player

-- Function to create an unanchored part that doesn't collide with the player
function createNoCollidePart(position)
    local part = Instance.new("Part")
    part.Size = Vector3.new(5, 5, 5) -- Size of the part
    part.Position = position
    part.Anchored = false -- Unanchor the part
    part.CanCollide = true -- Initially set to collide with everything
    part.Material = Enum.Material.SmoothPlastic
    part.Color = Color3.fromRGB(255, 0, 0) -- Red color to distinguish
    part.Parent = workspace

    -- Add part to the no-collide list
    table.insert(nocolide, part)

    -- Create a collision group to ignore collisions with the player
    local collisionGroupName = "NoPlayerCollision"
    local PhysicsService = game:GetService("PhysicsService")
    
    -- Check if the collision group exists, if not, create it
    if not pcall(function() PhysicsService:GetCollisionGroupId(collisionGroupName) end) then
        PhysicsService:CreateCollisionGroup(collisionGroupName)
    end

    -- Set the part's collision group to the one we created
    PhysicsService:SetPartCollisionGroup(part, collisionGroupName)

    -- Set up the collision group to not collide with the player
    PhysicsService:CollisionGroupSetCollidable(collisionGroupName, "Player", false)

    return part
end

-- Function to check if a part is valid for teleportation
local function CheckPart(part, localPlayer)
    return part:IsA("BasePart") 
        and not part.Anchored 
        and not part:IsDescendantOf(localPlayer.Character) 
        and part.Name ~= "Sphere"
end

-- When tool is activated (when player clicks with the tool equipped)
tool.Activated:Connect(function()
    -- If the red ball already exists, don't generate a new one
    if redBall then
        return
    end

    -- Get the origin (camera position) and direction (mouse hit position)
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = (mouse.Hit.Position - origin).Unit * 500 -- Extend ray 500 studs

    -- Raycast parameters
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character} -- Ignore player character
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    -- Perform raycast
    local result = workspace:Raycast(origin, direction, raycastParams)

    if result then
        -- Create a red ball at the hit position
        local hitPosition = result.Position
        redBall = Instance.new("Part")
        redBall.Shape = Enum.PartType.Ball
        redBall.Size = Vector3.new(1, 1, 1) -- Size of the ball
        redBall.Position = hitPosition
        redBall.Anchored = true
        redBall.CanCollide = false
        redBall.Material = Enum.Material.Neon
        redBall.BrickColor = BrickColor.new("Bright red")
        redBall.Parent = workspace

        -- Update raycast parameters to ignore this new red ball
        raycastParams.FilterDescendantsInstances = {player.Character, redBall}

        -- Apply forces to all frozen parts
        for _, part in pairs(workspace:GetDescendants()) do
            if CheckPart(part, player) then
                -- Remove existing forces
                for _, c in pairs(part:GetChildren()) do
                    if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
                        c:Destroy()
                    end
                end

                -- Apply a force to move the part to the red ball's position
                local forceInstance = Instance.new("BodyPosition")
                forceInstance.Parent = part
                forceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                forceInstance.Position = redBall.Position
                table.insert(Forces, forceInstance)

                -- Track frozen parts to avoid duplicates
                if not table.find(frozenParts, part) then
                    table.insert(frozenParts, part)
                end
            end
        end

        -- Remove the red ball after 1 second
        task.delay(1, function()
            if redBall then
                redBall:Destroy()
                redBall = nil -- Reset the redBall variable
            end
        end)
    end

    -- Create a no-collide part where the ray hits
    if result then
        createNoCollidePart(result.Position)
    end
end)

-- When the tool is unequipped, remove the red ball and no-collide parts
tool.Unequipped:Connect(function()
    if redBall then
        redBall:Destroy()
        redBall = nil -- Reset the redBall variable
    end

    -- Destroy all no-collide parts
    for _, part in pairs(nocolide) do
        part:Destroy()
    end
    nocolide = {} -- Clear the list of no-collide parts
end)