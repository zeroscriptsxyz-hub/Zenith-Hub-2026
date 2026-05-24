-- [[ Wraith | Basketball Stars 3 ]] --
-- [[ stacktrace45 | Rayfield port by NW HUB ]] --

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// Services \\--
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))

--// Window \\--
local Window = Rayfield:CreateWindow({
    Name = "Wraith | Basketball Stars 3",
    LoadingTitle = "Wraith",
    LoadingSubtitle = "By stacktrace45",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
})

--// Tabs \\--
local ShootingTab   = Window:CreateTab("Shooting",   4483362458)
local DefenseTab    = Window:CreateTab("Defense",    4483362458)
local MovementTab   = Window:CreateTab("Movement",   4483362458)
local VisualsTab    = Window:CreateTab("Visuals",    4483362458)
local MiscTab       = Window:CreateTab("Misc",       4483362458)
local InfoTab       = Window:CreateTab("Info",       4483362458)
local UISettingsTab = Window:CreateTab("UI Settings",4483362458)

--// State \\--
local autoTimeMethod      = "Legit"
local autoTimeEnabled     = false
local dunkChangerEnabled  = false
local dunkAnimation       = "Behind"
local autoStealEnabled    = false
local teamCheck           = true
local showIndicator       = true
local stealRange          = 1.5
local stealAnimation      = false
local walkspeedEnabled    = false
local walkspeedValue      = 8.25
local autoStealIndicator  = nil
local antiKnockback       = false
local antiKnockConnection = nil
local oldKnockNamecall    = nil
local staminaConnection   = nil
local autoSwitchConnection= nil
local handlesSpeedValue   = 16.25
local layupSpeedValue     = 12.5
local colorLoopEnabled    = false
local ballMagConnection   = nil
local lastPickupTime      = 0
local currtween           = nil

--// Auto time internals \\--
local namecallHook         = nil
local tweenConnections     = {}
local autoTimeNamecallActive = false
local visualConnection     = nil

--// Helpers \\--
local function disconnectTween()
    for _, conn in pairs(tweenConnections) do conn:Disconnect() end
    tweenConnections = {}
end

local function disconnectNamecall()
    if namecallHook then
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__namecall = namecallHook
        setreadonly(mt, true)
        namecallHook = nil
        autoTimeNamecallActive = false
    end
end

local function disconnectVisual()
    if visualConnection then visualConnection:Disconnect(); visualConnection = nil end
end

--// Legit auto time \\--
local function setupTween()
    disconnectNamecall()
    disconnectVisual()
    local vals  = getgenv().scriptValues  or require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("BallValues"))
    local funcs = getgenv().scriptFunctions or require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("BallFunctions"))
    local function bind(t)
        table.insert(tweenConnections, t.Completed:Connect(function()
            if autoTimeEnabled and vals.holding then funcs.shoot() end
        end))
    end
    bind(vals.jumpshotTween)
    bind(vals.layupTween)
    bind(vals.movingTween)
    bind(vals.dunkTween)
end

--// No bar \\--
local function setupNamecall()
    disconnectTween()
    disconnectVisual()
    if autoTimeNamecallActive then return end
    autoTimeNamecallActive = true
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    if not namecallHook then namecallHook = mt.__namecall end
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        if autoTimeEnabled and getnamecallmethod() == "FireServer" and tostring(self) == "BallEvent"
            and (args[2] == "shoot" or args[2] == "dunk") then
            args[3] = 1
            return namecallHook(self, unpack(args))
        end
        return namecallHook(self, ...)
    end)
    setreadonly(mt, true)
end

--// Auto bar \\--
local function setupVisual()
    disconnectTween()
    disconnectNamecall()
    local scriptValues
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "shootingGui") and rawget(v, "move") then
            scriptValues = v; break
        end
    end
    visualConnection = RunService.RenderStepped:Connect(function()
        if autoTimeEnabled and scriptValues and scriptValues.shootingGui
            and scriptValues.shootingGui.Enabled and scriptValues.move then
            scriptValues.move.Size = UDim2.new(0.8, 0, 0.975, 0)
        end
    end)
end

-- ==========================================
--               SHOOTING TAB
-- ==========================================
ShootingTab:CreateSection("Auto Time")

ShootingTab:CreateDropdown({
    Name = "Auto Time Method",
    Options = {"Legit", "No Bar", "Auto Bar"},
    CurrentOption = {"Legit"},
    Flag = "AutoTimeMethod",
    Callback = function(v)
        autoTimeMethod = v
        if autoTimeEnabled then
            if v == "Legit" then setupTween()
            elseif v == "No Bar" then setupNamecall()
            else setupVisual() end
        end
    end,
})

ShootingTab:CreateToggle({
    Name = "Auto Time",
    CurrentValue = false,
    Flag = "AutoTime",
    Callback = function(v)
        autoTimeEnabled = v
        if v then
            if autoTimeMethod == "Legit" then setupTween()
            elseif autoTimeMethod == "No Bar" then setupNamecall()
            else setupVisual() end
        else
            disconnectTween(); disconnectNamecall(); disconnectVisual()
        end
    end,
})

ShootingTab:CreateSection("Shot Modifiers")

ShootingTab:CreateButton({
    Name = "No Shot Meter",
    Callback = function()
        local sg = Players.LocalPlayer.Character.HumanoidRootPart:WaitForChild("ShootingGui")
        sg.Enabled = false
        sg:GetPropertyChangedSignal("Enabled"):Connect(function()
            if sg.Enabled then sg.Enabled = false end
        end)
    end,
})

ShootingTab:CreateButton({
    Name = "Easier Moving Shots",
    Callback = function()
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            if getnamecallmethod() == "FireServer" and self.Name == "BallEvent" and args[2] == "shoot" then
                if type(args[6]) == "table" then args[5] = 0; args[6] = 1 end
                return old(self, unpack(args))
            end
            return old(self, ...)
        end)
    end,
})

ShootingTab:CreateButton({
    Name = "High Shot Arc",
    Callback = function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local nc = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local a = {...}
            if getnamecallmethod() == "FireServer" and tostring(self) == "BallEvent"
                and typeof(a[6]) == "table" and typeof(a[6][2]) == "Vector3" then
                a[6][2] = Vector3.new(a[6][2].X, 35, a[6][2].Z)
            end
            return nc(self, unpack(a))
        end)
        setreadonly(mt, true)
    end,
})

ShootingTab:CreateSection("Dunk Settings")

ShootingTab:CreateToggle({
    Name = "Dunk Changer",
    CurrentValue = false,
    Flag = "DunkChanger",
    Callback = function(v) dunkChangerEnabled = v end,
})

ShootingTab:CreateDropdown({
    Name = "Dunk Animation",
    Options = {"2 Hand", "Tomahawk", "1 Hand", "Windmill", "Between", "Behind", "180", "Under", "360"},
    CurrentOption = {"Behind"},
    Flag = "DunkAnimation",
    Callback = function(v) dunkAnimation = v end,
})

ShootingTab:CreateToggle({
    Name = "Unlimited Dunk Range",
    CurrentValue = false,
    Flag = "UnlimitedDunkRange",
    Callback = function(v)
        local f = require(ReplicatedStorage.Modules.Functions).magXZ
        local c = debug.getconstants(f)
        for i, val in c do
            if val == "X" or val == "Z" or val == "Y" then
                debug.setconstant(f, i, v and "Y" or (val == "Y" and (i % 2 == 0 and "Z" or "X") or val))
            end
        end
    end,
})

--// Dunk anim swap loop \\--
local chr = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local hum = chr:WaitForChild("Humanoid")

local ids = {
    ["2 Hand"]   = "rbxassetid://16792383527",
    ["Tomahawk"] = "rbxassetid://115440095914436",
    ["1 Hand"]   = "rbxassetid://18998519353",
    ["Windmill"] = "rbxassetid://106278649589240",
    ["Between"]  = "rbxassetid://74345936965111",
    ["Behind"]   = "rbxassetid://120055472811741",
    ["180"]      = "rbxassetid://95017863158093",
    ["Under"]    = "rbxassetid://108988611725506",
    ["360"]      = "rbxassetid://72310933284051",
}

RunService.Heartbeat:Connect(function()
    if not dunkChangerEnabled then return end
    for _, v in ipairs(hum:GetPlayingAnimationTracks()) do
        for _, id in pairs(ids) do
            if v.Animation.AnimationId == id and id ~= ids[dunkAnimation] then
                v:Stop(); v:Destroy()
                local a = Instance.new("Animation")
                a.AnimationId = ids[dunkAnimation]
                local track = hum:LoadAnimation(a)
                track:Play(); track:AdjustSpeed(1.2)
                return
            end
        end
    end
end)

-- ==========================================
--               DEFENSE TAB
-- ==========================================
local p = Players.LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
local h = c:WaitForChild("HumanoidRootPart")
local lastStealTime = 0

DefenseTab:CreateSection("Auto Steal")

DefenseTab:CreateToggle({
    Name = "Auto Steal",
    CurrentValue = false,
    Flag = "AutoSteal",
    Callback = function(v)
        autoStealEnabled = v
        if not v and autoStealIndicator then
            autoStealIndicator:Destroy(); autoStealIndicator = nil
        end
    end,
})

DefenseTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(v) teamCheck = v end,
})

DefenseTab:CreateToggle({
    Name = "Show Indicator",
    CurrentValue = true,
    Flag = "ShowIndicator",
    Callback = function(v)
        showIndicator = v
        if not v and autoStealIndicator then
            autoStealIndicator:Destroy(); autoStealIndicator = nil
        end
    end,
})

DefenseTab:CreateToggle({
    Name = "Steal Animation",
    CurrentValue = false,
    Flag = "StealAnimation",
    Callback = function(v) stealAnimation = v end,
})

DefenseTab:CreateSlider({
    Name = "Steal Range",
    Range = {0.5, 10},
    Increment = 0.1,
    CurrentValue = 1.5,
    Flag = "StealRange",
    Callback = function(v) stealRange = v end,
})

RunService.RenderStepped:Connect(function()
    if not autoStealEnabled then
        if autoStealIndicator then autoStealIndicator:Destroy(); autoStealIndicator = nil end
        return
    end
    local targetBall  = nil
    local currentTime = tick()
    local ball = workspace:FindFirstChild("Balls") and workspace.Balls:FindFirstChild("Ball")

    if ball and (ball.Position - h.Position).Magnitude <= stealRange and currentTime - lastStealTime >= 0.5 then
        local ballOwner = ball:FindFirstChild("Player") and ball.Player.Value
        local shouldStealBall = true
        if teamCheck and ballOwner then shouldStealBall = ballOwner.Team ~= p.Team end
        if shouldStealBall then
            ReplicatedStorage:WaitForChild("BallEvent"):FireServer(ball, "steal")
            lastStealTime = currentTime
            if showIndicator then targetBall = ball end
        end
    end

    for _, b in pairs(workspace.Balls:GetChildren()) do
        if b:IsA("BasePart") and b:FindFirstChild("Player") then
            local plr = b.Player.Value
            if plr then
                local inRange    = (b.Position - h.Position).Magnitude <= stealRange
                local shouldSteal = true
                if teamCheck then shouldSteal = plr.TeamColor ~= p.TeamColor end
                if shouldSteal and inRange and currentTime - lastStealTime >= 0.5 then
                    ReplicatedStorage:WaitForChild("BallEvent"):FireServer(b, "steal")
                    lastStealTime = currentTime
                end
                if stealAnimation and shouldSteal and inRange then
                    local humChar = c:FindFirstChildOfClass("Humanoid")
                    if humChar then
                        local animId = b.Position.X > h.Position.X
                            and "rbxassetid://16190100758" or "rbxassetid://16190106253"
                        local anim = Instance.new("Animation")
                        anim.AnimationId = animId
                        humChar:LoadAnimation(anim):Play()
                    end
                end
                if showIndicator and inRange and shouldSteal then targetBall = b end
            end
        end
    end

    if showIndicator then
        if targetBall then
            if not autoStealIndicator then
                local part = Instance.new("Part")
                part.Size = Vector3.new(1,1,1); part.Anchored = true
                part.CanCollide = false; part.Transparency = 0.7
                part.Color = Color3.new(0,1,0); part.Shape = Enum.PartType.Ball
                autoStealIndicator = part
            end
            autoStealIndicator.Position = targetBall.Position
            autoStealIndicator.Parent   = workspace
        elseif autoStealIndicator then
            autoStealIndicator:Destroy(); autoStealIndicator = nil
        end
    end
end)

DefenseTab:CreateSection("Contest & Block")

DefenseTab:CreateToggle({
    Name = "Auto Contest",
    CurrentValue = false,
    Flag = "AutoContest",
    Callback = function(Value)
        if Value then
            if UserInputService.TouchEnabled then
                local rm  = ReplicatedStorage:WaitForChild("Modules")
                local fm  = require(rm:WaitForChild("Functions"))
                local be  = ReplicatedStorage:WaitForChild("BallEvent")
                local dunkIds = {
                    ["16792383527"]=true,["115440095914436"]=true,["18998519353"]=true,
                    ["106278649589240"]=true,["74345936965111"]=true,["120055472811741"]=true,
                    ["95017863158093"]=true,["108988611725506"]=true,["72310933284051"]=true,
                }
                task.spawn(function()
                    while task.wait() do
                        local char = p.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local ball = fm.findNearestBall(char.HumanoidRootPart.Position)
                            if ball and ball:FindFirstChild("Player") and ball:FindFirstChild("State") then
                                local bp = ball.Player.Value
                                if bp and bp ~= p and not fm.sameTeam(bp, p) then
                                    local dist = (ball.Position - char.HumanoidRootPart.Position).Magnitude
                                    local isDunking = false
                                    if bp.Character and bp.Character:FindFirstChildOfClass("Humanoid") then
                                        for _, track in pairs(bp.Character:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
                                            if dunkIds[track.Animation.AnimationId:match("%d+$")] then isDunking = true; break end
                                        end
                                    end
                                    if dist <= 9 and (ball.State.Value == "Shooting" or isDunking) then
                                        be:FireServer(nil, "guarding", true)
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                local contestIds = {["15625460755"]=true,["15640551795"]=true,["15640621238"]=true,["15933297660"]=true,["15933244201"]=true,["16792383527"]=true}
                local pressing = false
                RunService.Heartbeat:Connect(function()
                    if not c or not c:FindFirstChild("HumanoidRootPart") then return end
                    local shouldPress = false
                    for _, v in pairs(Players:GetPlayers()) do
                        if v ~= p and v.Character and v.Character:FindFirstChild("HumanoidRootPart")
                            and v.Character:FindFirstChildOfClass("Humanoid") and v.Team ~= p.Team then
                            local d = (c.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                            if d <= 8 then
                                local elv = v.Character.HumanoidRootPart.CFrame.LookVector
                                local dtp = (c.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Unit
                                if elv:Dot(dtp) > -0.3 then
                                    for _, t in pairs(v.Character:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
                                        if contestIds[t.Animation.AnimationId:match("%d+$")] then shouldPress = true; break end
                                    end
                                end
                            end
                        end
                    end
                    if shouldPress and not pressing then keypress(0x47); pressing = true
                    elseif not shouldPress and pressing then keyrelease(0x47); pressing = false end
                end)
            end
        end
    end,
})

DefenseTab:CreateToggle({
    Name = "Auto Block",
    CurrentValue = false,
    Flag = "AutoBlock",
    Callback = function(v)
        if v then
            local blockIds = {["15625460755"]=true,["15640551795"]=true,["15640621238"]=true,["15933297660"]=true,["15933244201"]=true,["16792383527"]=true}
            RunService.Heartbeat:Connect(function()
                if not c or not c:FindFirstChild("HumanoidRootPart") then return end
                local hm = c:FindFirstChildOfClass("Humanoid")
                if not hm then return end
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= p and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Team ~= p.Team then
                        if (c.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude <= 6.5 then
                            for _, t in pairs(plr.Character:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
                                if blockIds[t.Animation.AnimationId:match("%d+$")] then
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game); break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end,
})

DefenseTab:CreateSection("Defensive Utilities")

DefenseTab:CreateButton({
    Name = "No Steal Cooldown",
    Callback = function()
        local vals = require(Players.LocalPlayer.PlayerScripts.BallValues)
        spawn(function()
            while wait() do
                if vals.currentAnim == "Steal" then vals.defensiveCooldown = false end
            end
        end)
    end,
})

-- ==========================================
--               MOVEMENT TAB
-- ==========================================
MovementTab:CreateSection("Speed")

MovementTab:CreateToggle({
    Name = "Walkspeed",
    CurrentValue = false,
    Flag = "Walkspeed",
    Callback = function(v)
        walkspeedEnabled = v
        if v then
            RunService.Heartbeat:Connect(function()
                if not walkspeedEnabled then return end
                local char = Players.LocalPlayer.Character
                if not char then return end
                local hroot   = char:FindFirstChild("HumanoidRootPart")
                local humWalk = char:FindFirstChild("Humanoid")
                if not hroot or not humWalk then return end
                local mv = humWalk.MoveDirection
                if mv.Magnitude > 0 then
                    if currtween then currtween:Cancel() end
                    local tpos = hroot.CFrame.Position + mv * walkspeedValue
                    currtween = TweenService:Create(hroot, TweenInfo.new(0.2, Enum.EasingStyle.Linear),
                        {CFrame = CFrame.new(tpos, tpos + hroot.CFrame.LookVector)})
                    currtween:Play()
                else
                    if currtween then currtween:Cancel(); currtween = nil end
                end
            end)
        else
            if currtween then currtween:Cancel(); currtween = nil end
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Walkspeed Value",
    Range = {1, 20},
    Increment = 0.01,
    CurrentValue = 8.25,
    Flag = "WalkspeedValue",
    Callback = function(v) walkspeedValue = v end,
})

MovementTab:CreateSection("Handles")

MovementTab:CreateToggle({
    Name = "Handles Speed Changer",
    CurrentValue = false,
    Flag = "HandlesSpeed",
    Callback = function(v)
        require(ReplicatedStorage.Modules.Values).baseSliders.handlesSpeed = v and handlesSpeedValue or 16.25
    end,
})

MovementTab:CreateSlider({
    Name = "Handles Speed",
    Range = {10, 25},
    Increment = 0.01,
    CurrentValue = 16.25,
    Flag = "HandlesSpeedValue",
    Callback = function(v)
        handlesSpeedValue = v
        require(ReplicatedStorage.Modules.Values).baseSliders.handlesSpeed = v
    end,
})

MovementTab:CreateToggle({
    Name = "Layup Glide Changer",
    CurrentValue = false,
    Flag = "LayupGlide",
    Callback = function(v)
        local a = require(ReplicatedStorage.Modules.Values)
        a.baseSliders.layupSpeed = v and layupSpeedValue or 12.5
        a.sliders.layupSpeed     = v and layupSpeedValue or 12.5
    end,
})

MovementTab:CreateSlider({
    Name = "Layup Glide Speed",
    Range = {1, 25},
    Increment = 0.01,
    CurrentValue = 12.5,
    Flag = "LayupGlideSpeed",
    Callback = function(v)
        layupSpeedValue = v
        local a = require(ReplicatedStorage.Modules.Values)
        a.baseSliders.layupSpeed = v; a.sliders.layupSpeed = v
    end,
})

MovementTab:CreateToggle({
    Name = "Auto Switch Hands",
    CurrentValue = false,
    Flag = "AutoSwitchHands",
    Callback = function(v)
        if v then
            local scriptValues  = require(p:WaitForChild("PlayerScripts"):WaitForChild("BallValues"))
            local functionModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Functions"))
            autoSwitchConnection = RunService.Heartbeat:Connect(function()
                if not scriptValues.ball or not scriptValues.root then return end
                for _, defender in Players:GetPlayers() do
                    if defender ~= p and not functionModule.sameTeam(defender, p) and defender.Character then
                        local defRoot = defender.Character:FindFirstChild("HumanoidRootPart")
                        if defRoot and (defRoot.Position - scriptValues.root.Position).Magnitude <= 8 then
                            local rel = scriptValues.root.CFrame:PointToObjectSpace(defRoot.Position)
                            if rel.X > 0 and scriptValues.hand == "L" then scriptValues.hand = "R"; break
                            elseif rel.X <= 0 and scriptValues.hand == "R" then scriptValues.hand = "L"; break end
                        end
                    end
                end
            end)
        else
            if autoSwitchConnection then autoSwitchConnection:Disconnect(); autoSwitchConnection = nil end
        end
    end,
})

MovementTab:CreateSection("Stamina")

MovementTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Flag = "InfiniteStamina",
    Callback = function(v)
        if v then
            local PS = Players.LocalPlayer:FindFirstChild("PlayerScripts")
            local BF = require(PS:FindFirstChild("BallFunctions"))
            local BV = require(PS:FindFirstChild("BallValues"))
            BF.useStamina = function(...)
                BV.stamina = 100
                BV.staminaMove.Size  = UDim2.new(1,0,0.8,0)
                BV.staminaMove2.Size = BV.staminaMove.Size
            end
            staminaConnection = RunService.Heartbeat:Connect(function()
                BV.stamina = 100
                BV.staminaMove.Size  = UDim2.new(1,0,0.8,0)
                BV.staminaMove2.Size = BV.staminaMove.Size
            end)
        else
            if staminaConnection then staminaConnection:Disconnect(); staminaConnection = nil end
        end
    end,
})

-- ==========================================
--               VISUALS TAB
-- ==========================================
local replicatedModules = ReplicatedStorage:WaitForChild("Modules")
local clothingList = require(replicatedModules:WaitForChild("ClothingList"))

local function getColor(colorName)
    if clothingList.Colors[colorName] then return clothingList.Colors[colorName][2]
    elseif type(colorName) == "string" and #colorName == 6 then return Color3.fromHex(colorName) end
    return clothingList.Colors["Institutional white"][2]
end

local function multColor3(color, mult)
    return Color3.new(math.clamp(color.R*mult,0,1), math.clamp(color.G*mult,0,1), math.clamp(color.B*mult,0,1))
end

local function applyColor(char, colorName)
    local color   = multColor3(getColor(colorName), 1.2)
    local shirt   = char:FindFirstChildOfClass("Shirt")
    local pants   = char:FindFirstChildOfClass("Pants")
    local headband = char:FindFirstChild("Headband")
    if shirt and (shirt.ShirtTemplate == "rbxassetid://15973302914" or shirt.ShirtTemplate == "rbxassetid://15973417823") then
        shirt.Color3 = color
    end
    if pants then pants.Color3 = color end
    if headband and headband.Handle.Mesh.TextureId == "rbxassetid://15973764217" then
        headband.Handle.Mesh.VertexColor = Vector3.new(color.R, color.G, color.B)
    end
end

VisualsTab:CreateSection("Cosmetics")

VisualsTab:CreateToggle({
    Name = "Rainbow Jersey",
    CurrentValue = false,
    Flag = "RainbowJersey",
    Callback = function(v)
        colorLoopEnabled = v
        if v then
            local colorNames = {}
            for name in pairs(clothingList.Colors) do table.insert(colorNames, name) end
            spawn(function()
                while colorLoopEnabled do
                    if p.Character then applyColor(p.Character, colorNames[math.random(1,#colorNames)]) end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

local colorList = {}
for name in pairs(clothingList.Colors) do table.insert(colorList, name) end

VisualsTab:CreateDropdown({
    Name = "Jersey Color",
    Options = colorList,
    CurrentOption = {colorList[1]},
    Flag = "ColorPicker",
    Callback = function(v)
        if p.Character then applyColor(p.Character, v) end
    end,
})

VisualsTab:CreateInput({
    Name = "Custom Hex Color",
    CurrentValue = "FF0000",
    PlaceholderText = "FF0000",
    RemoveTextAfterFocusLost = false,
    Flag = "HexColor",
    Callback = function(v)
        if p.Character and #v == 6 then applyColor(p.Character, v) end
    end,
})

-- ==========================================
--               MISC TAB
-- ==========================================
MiscTab:CreateSection("Ball Utilities")

MiscTab:CreateToggle({
    Name = "Ball Mag",
    CurrentValue = false,
    Flag = "BallMag",
    Callback = function(v)
        if v then
            ballMagConnection = RunService.Heartbeat:Connect(function()
                local char = Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local ct = tick()
                    if ct - lastPickupTime >= 0.1 then
                        for _, ball in pairs(workspace.Balls:GetChildren()) do
                            if ball.Name == "Ball" and (ball.Position - char.HumanoidRootPart.Position).Magnitude <= 8 then
                                ReplicatedStorage.BallEvent:FireServer(ball, "pickup")
                                lastPickupTime = ct; break
                            end
                        end
                    end
                end
            end)
        else
            if ballMagConnection then ballMagConnection:Disconnect(); ballMagConnection = nil end
        end
    end,
})

MiscTab:CreateSection("Misc Utilities")

MiscTab:CreateToggle({
    Name = "Anti Knockback/Pushed",
    CurrentValue = false,
    Flag = "AntiKnockback",
    Callback = function(v)
        if v then
            local sv = require(Players.LocalPlayer.PlayerScripts.BallValues)
            local sf = require(Players.LocalPlayer.PlayerScripts.BallFunctions)
            local vm = require(ReplicatedStorage.Modules.Values)
            antiKnockback = true
            oldKnockNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local args = {...}
                if antiKnockback and getnamecallmethod() == "FireClient" and self.Name == "ballEvent" then
                    if args[2] == "pushed" or args[2] == "knock" then return end
                end
                return oldKnockNamecall(self, ...)
            end))
            antiKnockConnection = RunService.Heartbeat:Connect(function()
                if antiKnockback and sv.knocked then
                    sv.knocked = false; sv.linearVelocity.Enabled = false
                    sv.alignOrientation.Enabled = false; sv.humanoid.AutoRotate = true; sv.facePart = nil
                    for _, track in pairs(sv.humanoid:GetPlayingAnimationTracks()) do
                        local id = tonumber(track.Animation.AnimationId:match("%d+"))
                        if id ~= 507767714 and id ~= 6861835527 then track:Stop() end
                    end
                    sf.changeSpeed(vm.sliders.startingSpeed, false)
                end
                if antiKnockback and sv.linearVelocity.Enabled and not sv.shootBounce and not sv.passRec and not sv.holdingBall then
                    sv.linearVelocity.Enabled = false; sv.alignOrientation.Enabled = false; sv.humanoid.AutoRotate = true
                    if sv.picking == 0 then sf.changeSpeed(vm.sliders.startingSpeed, false) end
                end
            end)
        else
            antiKnockback = false
            if antiKnockConnection then antiKnockConnection:Disconnect(); antiKnockConnection = nil end
        end
    end,
})

MiscTab:CreateButton({
    Name = "Stamina Drain (push on touch)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local chr = plr.Character or plr.CharacterAdded:Wait()
        local hit = chr:WaitForChild("hit")
        local ev  = ReplicatedStorage:WaitForChild("BallEvent")
        local old
        old = hookfunction(ev.FireServer, function(self, ...)
            local a = {...}
            if a[2] == "push" and a[3] and a[3] ~= plr then
                for i = 1, 5 do task.spawn(function() old(self, nil, "push", a[3]) end) end
            end
            return old(self, ...)
        end)
        hit.Touched:Connect(function(part)
            if part.Parent and part.Parent:FindFirstChild("Humanoid") then
                local t = game.Players:GetPlayerFromCharacter(part.Parent)
                if t and t ~= plr and t.Team ~= plr.Team then
                    for i = 1, 3 do task.wait(0.1); ev:FireServer(nil, "push", t) end
                end
            end
        end)
    end,
})

MiscTab:CreateToggle({
    Name = "Anti-Ankle Breaker",
    CurrentValue = false,
    Flag = "AntiAnkleBreaker",
    Callback = function(v)
        local bf = require(Players.LocalPlayer.PlayerScripts.BallFunctions)
        bf.ankles = v and newcclosure(function() end) or (bf.originalAnkles or bf.ankles)
    end,
})

MiscTab:CreateButton({
    Name = "Remove Dunk Poster Stun",
    Callback = function()
        local hitBox = Players.LocalPlayer.Character:WaitForChild("hit")
        for _, conn in pairs(getconnections(hitBox.Touched)) do conn:Disable() end
    end,
})

MiscTab:CreateSection("Badges")

MiscTab:CreateButton({
    Name = "Infinite Badge Levels",
    Callback = function()
        local rm = ReplicatedStorage:WaitForChild("Modules")
        local fm = require(rm:WaitForChild("Functions"))
        fm.getBadgeMaxLevel = function() return 8 end
        fm.getBadgeLevel    = function() return 8, 8 end
        local vm = require(rm:WaitForChild("Values"))
        if vm.badgeUpgrades then
            for k in pairs(vm.badgeUpgrades) do vm.badgeUpgrades[k] = 0 end
        end
    end,
})

MiscTab:CreateSection("Teleports")

local tp = {
    {id="18638157143",  name="Beginner"},
    {id="113454014057557", name="Intermediate"},
    {id="117737879114585", name="Advanced"},
    {id="18668109315",  name="Private"},
    {id="15583100726",  name="Lobby"},
    {id="138786645426705",name="Afk Zone"},
    {id="131054006918765",name="Park"},
    {id="111682393431323",name="Rec Center"},
}

for _, v in pairs(tp) do
    MiscTab:CreateButton({
        Name = "TP: " .. v.name,
        Callback = function()
            TeleportService:Teleport(tonumber(v.id), Players.LocalPlayer)
        end,
    })
end

-- ==========================================
--               INFO TAB
-- ==========================================
InfoTab:CreateSection("System Info")
InfoTab:CreateLabel("Device: "   .. (UserInputService.TouchEnabled and "Mobile" or "PC"))
InfoTab:CreateLabel("Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))
InfoTab:CreateLabel("Script by stacktrace45 | discord.gg/NxbdayKh")

-- ==========================================
--             UI SETTINGS TAB
-- ==========================================
UISettingsTab:CreateSection("Menu")

UISettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function() Rayfield:Destroy() end,
})

-- ==========================================
--               NOTIFY
-- ==========================================
Rayfield:Notify({
    Title   = "Wraith Loaded",
    Content = "Basketball Stars 3 | By stacktrace45",
    Duration = 10,
    Image   = 4483362458,
})
