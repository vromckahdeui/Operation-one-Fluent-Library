local Fluent = loadstring(game:HttpGet(
    "https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentLite"
))()

local Window = Fluent:CreateWindow({
    Title       = "Spectre",
    SubTitle    = "",
    TabWidth    = 139,
    Size        = UDim2.fromOffset(480, 460),
    Acrylic     = true,
    Theme       = "AMOLED",
    MinimizeKey = Enum.KeyCode.RightControl,
    Search      = true,
})

local MainTab     = Window:AddTab({ Title = "Main",     Icon = "solar/home-bold" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "solar/settings-bold" })

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer      = Players.LocalPlayer
local camera           = workspace.CurrentCamera
local viewmodels       = workspace:FindFirstChild("Viewmodels")

local espEnabled    = false
local fovEnabled    = false
local fovRadius     = 80
local selfColor     = Color3.fromRGB(255, 105, 130)
local enemyColor    = Color3.fromRGB(255, 105, 130)
local teammateColor = Color3.fromRGB(80, 255, 80)

local fovCircle = Drawing.new("Circle")
fovCircle.Radius       = fovRadius
fovCircle.Color        = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness    = 1
fovCircle.Transparency = 1
fovCircle.Filled       = false
fovCircle.Visible      = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovCircle.Visible  = fovEnabled
end)

local function applyHighlight(model, fillColor, outlineColor)
    local existing = model:FindFirstChild("ESPHighlight")
    if existing then existing:Destroy() end
    local h = Instance.new("Highlight")
    h.Name                = "ESPHighlight"
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillTransparency    = 0.3
    h.OutlineTransparency = 0.5
    h.FillColor           = fillColor
    h.OutlineColor        = outlineColor
    h.Adornee             = model
    h.Parent              = model
end

local function removeHighlight(model)
    local h = model:FindFirstChild("ESPHighlight")
    if h then h:Destroy() end
end

local function isTeammate(model)
    for _, v in ipairs(model:GetChildren()) do
        if v:IsA("Highlight") and v.Name ~= "ESPHighlight" then
            return true
        end
    end
    return false
end

local function highlightPlayer(model)
    if model.Name == "LocalViewmodel" then return end
    if model.Name ~= "Viewmodel" then return end
    local torso = model:FindFirstChild("torso")
    if not torso then return end
    if isTeammate(model) then
        applyHighlight(model, teammateColor, teammateColor)
    else
        applyHighlight(model, enemyColor, enemyColor)
    end
end

local function enableESP()
    local localVM = viewmodels and viewmodels:FindFirstChild("LocalViewmodel")
    if localVM then
        applyHighlight(localVM, selfColor, selfColor)
    end
    if viewmodels then
        for _, model in ipairs(viewmodels:GetChildren()) do
            highlightPlayer(model)
        end
    end
end

local function disableESP()
    if viewmodels then
        for _, model in ipairs(viewmodels:GetChildren()) do
            removeHighlight(model)
        end
    end
end

local vmConn
local function startESPListener()
    if vmConn then vmConn:Disconnect() end
    if viewmodels then
        vmConn = viewmodels.ChildAdded:Connect(function(model)
            if espEnabled and model:IsA("Model") then
                task.wait(0.2)
                highlightPlayer(model)
            end
        end)
    end
end

startESPListener()

local ESPSection = MainTab:AddSection("ESP")

ESPSection:AddToggle("ESP", {
    Title    = "ESP Highlight",
    Icon     = "solar/eye-bold",
    Default  = false,
    Callback = function(val)
        espEnabled = val
        if val then enableESP() else disableESP() end
    end,
})

ESPSection:AddColorpicker("SelfColor", {
    Title    = "Self Color",
    Icon     = "solar/user-bold",
    Default  = selfColor,
    Callback = function(col)
        selfColor = col
        local localVM = viewmodels and viewmodels:FindFirstChild("LocalViewmodel")
        if localVM then
            local h = localVM:FindFirstChild("ESPHighlight")
            if h then h.FillColor = col h.OutlineColor = col end
        end
    end,
})

ESPSection:AddColorpicker("EnemyColor", {
    Title    = "Enemy Color",
    Icon     = "solar/danger-bold",
    Default  = enemyColor,
    Callback = function(col)
        enemyColor = col
        if viewmodels then
            for _, model in ipairs(viewmodels:GetChildren()) do
                if model.Name == "Viewmodel" and not isTeammate(model) then
                    local h = model:FindFirstChild("ESPHighlight")
                    if h then h.FillColor = col h.OutlineColor = col end
                end
            end
        end
    end,
})

ESPSection:AddColorpicker("TeamColor", {
    Title    = "Teammate Color",
    Icon     = "solar/users-group-bold",
    Default  = teammateColor,
    Callback = function(col)
        teammateColor = col
        if viewmodels then
            for _, model in ipairs(viewmodels:GetChildren()) do
                if model.Name == "Viewmodel" and isTeammate(model) then
                    local h = model:FindFirstChild("ESPHighlight")
                    if h then h.FillColor = col h.OutlineColor = col end
                end
            end
        end
    end,
})

local FOVSection = MainTab:AddSection("FOV")

FOVSection:AddToggle("FOVToggle", {
    Title    = "FOV Circle",
    Icon     = "solar/target-bold",
    Default  = false,
    Callback = function(val) fovEnabled = val end,
})

FOVSection:AddSlider("FOVSize", {
    Title    = "FOV Size",
    Icon     = "solar/scale-bold",
    Default  = 80,
    Min      = 0,
    Max      = 300,
    Rounding = 0,
    Callback = function(val)
        fovRadius        = val
        fovCircle.Radius = val
    end,
})

local WeaponSection = MainTab:AddSection("Weapon")

WeaponSection:AddToggle("NoRecoil", {
    Title    = "No Recoil",
    Icon     = "solar/gun-bold",
    Default  = false,
    Callback = function(val)
        if val then
            run_on_actor(getactors()[1], [==[
                local recoil_x = 0
                local recoil_y = 0
                local old_tweenInfo_new = clonefunction(TweenInfo.new)
                hookfunction(TweenInfo.new, newcclosure(function(...)
                    if debug.info(3, "n") == "recoil_function" then
                        setstack(3, 5, getstack(3, 5) * recoil_x)
                        setstack(3, 6, getstack(3, 6) * recoil_y)
                    end
                    return old_tweenInfo_new(...)
                end))
            ]==])
        end
    end,
})

WeaponSection:AddToggle("AutoFire", {
    Title    = "Auto Fire",
    Icon     = "solar/bolt-bold",
    Default  = false,
    Callback = function(val)
        if val then
            run_on_actor(getactors()[1], [==[
                local rs = game:GetService("ReplicatedStorage")
                local gnm = require(rs.Modules.Items.Item.Gun)
                rawset(gnm, "automatic", true)
                print("Auto set:", gnm.automatic)
            ]==])
        end
    end,
})

local SaveManager           = Fluent.SaveManager
local InterfaceManager      = Fluent.InterfaceManager
local FloatingButtonManager = Fluent.FloatingButtonManager

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
FloatingButtonManager:SetLibrary(Fluent)

InterfaceManager:SetFolder("Spectre")
SaveManager:SetFolder("Spectre/Config")
FloatingButtonManager:SetFolder("Spectre/Floating")

InterfaceManager:BuildInterfaceSection(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)
FloatingButtonManager:BuildConfigSection(SettingsTab)

SaveManager:LoadAutoloadConfig()
FloatingButtonManager:LoadAutoloadConfig()

Window:SelectTab(1)

local toggleGui = Instance.new("ScreenGui")
toggleGui.Name           = "SpectreUI"
toggleGui.Parent         = localPlayer:WaitForChild("PlayerGui")
toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toggleGui.ResetOnSpawn   = false

local mainBtn = Instance.new("TextButton")
mainBtn.Name                   = "OpenButton"
mainBtn.Parent                 = toggleGui
mainBtn.BackgroundTransparency = 1
mainBtn.Position               = UDim2.new(0.05, 0, 0.1, 0)
mainBtn.Size                   = UDim2.new(0, 64, 0, 64)
mainBtn.Text                   = ""
Instance.new("UICorner", mainBtn)

local frontImage = Instance.new("ImageLabel")
frontImage.Parent                 = mainBtn
frontImage.Size                   = UDim2.fromOffset(56, 56)
frontImage.Position               = UDim2.new(0.5, 0, 0.5, 0)
frontImage.AnchorPoint            = Vector2.new(0.5, 0.5)
frontImage.BackgroundTransparency = 1
frontImage.Image                  = "rbxassetid://126113649238951"
frontImage.ZIndex                 = 1
Instance.new("UICorner", frontImage).CornerRadius = UDim.new(0.2, 0)

local dragging, dragStart, startPos = false, nil, nil
mainBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = mainBtn.Position
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        mainBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local windowOpen = true
mainBtn.MouseButton1Click:Connect(function()
    windowOpen = not windowOpen
    if windowOpen then
        Window:Unminimize()
    else
        Window:Minimize()
    end
end)

FloatingButtonManager:AddButton("OpenBtn", mainBtn, false, false)

Fluent:Notify({
    Title    = "Spectre",
    Content  = "Loaded!",
    Duration = 3,
})