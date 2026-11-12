-- ==========================================
-- KEREN HUB - OFFICE WORKER (NATIVE UI VERSION)
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Bersihkan UI lama jika ada
if PlayerGui:FindFirstChild("KerenHubOfficeNative") then
    PlayerGui.KerenHubOfficeNative:Destroy()
end
if PlayerGui:FindFirstChild("KHubAutoOfficeOverlay") then
    PlayerGui.KHubAutoOfficeOverlay:Destroy()
end

-- ==========================================
-- MEMBUAT CUSTOM NATIVE UI (FLOATING WINDOW)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KerenHubOfficeNative"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.Position = UDim2.new(0.5, -125, 0.3, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 210)
MainFrame.Active = true
MainFrame.Draggable = true -- Bisa digeser-geser pakai jempol/mouse!

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 80)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

-- Judul UI
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 10)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Font = Enum.Font.GothamBold
Title.Text = "💼 Keren Hub • Office"
Title.TextColor3 = Color3.fromRGB(240, 240, 255)
Title.TextSize = 14

-- Status Text
local StatusText = Instance.new("TextLabel")
StatusText.Parent = MainFrame
StatusText.BackgroundTransparency = 1
StatusText.Position = UDim2.new(0, 0, 0, 38)
StatusText.Size = UDim2.new(1, 0, 0, 20)
StatusText.Font = Enum.Font.GothamMedium
StatusText.Text = "Status: Standby 🔴"
StatusText.TextColor3 = Color3.fromRGB(180, 180, 200)
StatusText.TextSize = 11

-- Tombol Toggle Auto Farm
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(210, 45, 45)
ToggleBtn.Position = UDim2.new(0.1, 0, 0, 68)
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "AUTO FARM: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 12

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

-- Tombol Toggle Black Screen
local BlackScreenBtn = Instance.new("TextButton")
BlackScreenBtn.Parent = MainFrame
BlackScreenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
BlackScreenBtn.Position = UDim2.new(0.1, 0, 0, 115)
BlackScreenBtn.Size = UDim2.new(0.8, 0, 0, 35)
BlackScreenBtn.Font = Enum.Font.GothamBold
BlackScreenBtn.Text = "BLACK SCREEN: OFF"
BlackScreenBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
BlackScreenBtn.TextSize = 11

local BsCorner = Instance.new("UICorner")
BsCorner.CornerRadius = UDim.new(0, 8)
BsCorner.Parent = BlackScreenBtn

-- Tombol Minimize / Hide UI sementara
local HideBtn = Instance.new("TextButton")
HideBtn.Parent = MainFrame
HideBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
HideBtn.Position = UDim2.new(0.1, 0, 0, 158)
HideBtn.Size = UDim2.new(0.8, 0, 0, 32)
HideBtn.Font = Enum.Font.GothamBold
HideBtn.Text = "CLOSE UI (RELOAD SHIFT)"
HideBtn.TextColor3 = Color3.fromRGB(170, 170, 170)
HideBtn.TextSize = 10

local HideCorner = Instance.new("UICorner")
HideCorner.CornerRadius = UDim.new(0, 8)
HideCorner.Parent = HideBtn

-- ==========================================
-- VARIABEL LOGIKA AUTO FARM & SOLVER
-- ==========================================
local AutoOfficeEnabled = false
local BlackScreenEnabled = false
local NoclipEnabled = false
local AntiAfkEnabled = true

local JobEvents = ReplicatedStorage:WaitForChild("JobEvents")
local ComputersFolder = Workspace:WaitForChild("Computers")
local CurrentTargetComputer = nil

local CorrectAnswerEvent = JobEvents:WaitForChild("CorrectAnswer")
local GenerateQuestionEvent = JobEvents:WaitForChild("GenerateQuestion")
local farmThread = nil

-- ==========================================
-- FUNGSI OVERLAY HITAM PEKAT
-- ==========================================
local function showOverlay()
    pcall(function()
        if not BlackScreenEnabled then return end
        if PlayerGui:FindFirstChild("KHubAutoOfficeOverlay") then return end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "KHubAutoOfficeOverlay"
        screenGui.Parent = PlayerGui
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local bgFrame = Instance.new("Frame")
        bgFrame.Size = UDim2.new(1, 0, 1, 0)
        bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bgFrame.BackgroundTransparency = 0
        bgFrame.Parent = screenGui

        local centerContainer = Instance.new("Frame")
        centerContainer.Size = UDim2.new(0, 300, 0, 200)
        centerContainer.Position = UDim2.new(0.5, -150, 0.5, -100)
        centerContainer.BackgroundTransparency = 1
        centerContainer.Parent = bgFrame

        local logoBox = Instance.new("Frame")
        logoBox.Size = UDim2.new(0, 80, 0, 80)
        logoBox.Position = UDim2.new(0.5, -40, 0, 10)
        logoBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        logoBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
        logoBox.BorderSizePixel = 2
        logoBox.Parent = centerContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 12)
        c.Parent = logoBox

        local logoText = Instance.new("TextLabel")
        logoText.Size = UDim2.new(1, 0, 1, 0)
        logoText.BackgroundTransparency = 1
        logoText.Text = "K"
        logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
        logoText.TextSize = 45
        logoText.Font = Enum.Font.GothamBold
        logoText.Parent = logoBox

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 30)
        titleLabel.Position = UDim2.new(0, 0, 0, 100)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Keren Hub"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 22
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Parent = centerContainer

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(1, 0, 0, 20)
        statusLabel.Position = UDim2.new(0, 0, 0, 135)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "Office Worker Auto-Farm Running..."
        statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        statusLabel.TextSize = 12
        statusLabel.Font = Enum.Font.GothamMedium
        statusLabel.Parent = centerContainer
    end)
end

local function hideOverlay()
    pcall(function()
        if PlayerGui:FindFirstChild("KHubAutoOfficeOverlay") then
            PlayerGui.KHubAutoOfficeOverlay:Destroy()
        end
    end)
end

-- ==========================================
-- EVENT LISTENER & MATH SOLVER
-- ==========================================
JobEvents:WaitForChild("AssignPrintJob").OnClientEvent:Connect(function(computerName)
    CurrentTargetComputer = computerName
    if AutoOfficeEnabled then
        StatusText.Text = "Target: " .. tostring(computerName)
    end
end)

JobEvents:WaitForChild("ClearPrintJob").OnClientEvent:Connect(function()
    CurrentTargetComputer = nil
    if AutoOfficeEnabled then
        StatusText.Text = "Status: Selesai 🟢"
    end
end)

-- Auto-Solver Penjumlahan Matematika
GenerateQuestionEvent.OnClientEvent:Connect(function(questionText, options, questionID)
    if not AutoOfficeEnabled then return end
    task.wait(0.3)
    
    pcall(function()
        local cleanExpr = questionText:gsub("=.*", ""):gsub("[^%d%+%-*%/%(%)]", "")
        local mathFunc = loadstring("return " .. cleanExpr)
        if not mathFunc then return end
        local correctAnswerValue = tostring(mathFunc())
        
        for _, opt in ipairs(options) do
            local optClean = tostring(opt.Text):gsub("%D", "")
            if optClean == correctAnswerValue or tostring(opt.Text) == correctAnswerValue then
                CorrectAnswerEvent:FireServer(opt.ID, questionID)
                StatusText.Text = "Soal Terjawab! 🧮"
                break
            end
        end
    end)
end)

-- Noclip & Anti-AFK Loop
RunService.Stepped:Connect(function()
    if NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        if AntiAfkEnabled then
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end
    end)
end)

local function selectOfficeJob()
    pcall(function()
        local TeamChange = JobEvents:FindFirstChild("TeamChangeRequest")
        if TeamChange then
            TeamChange:FireServer("Office Worker", 11378976, 1, 0, "Detector")
            task.wait(2)
        end
    end)
end

local function teleportToPart(targetPart)
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not targetPart then return end
        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.3)
    end)
end

local function interactPrompt(prompt)
    if not prompt then return end
    local holdTime = prompt.HoldDuration or 0
    if holdTime > 0 then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(holdTime + 0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    else
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end
end

-- ==========================================
-- MAIN FARM LOOP
-- ==========================================
local function startFarmLoop()
    if farmThread then task.cancel(farmThread) end
    
    farmThread = task.spawn(function()
        while true do
            task.wait(1)
            if not AutoOfficeEnabled then break end

            pcall(function()
                if not (LocalPlayer.Team and LocalPlayer.Team.Name == "Office Worker") then
                    StatusText.Text = "Masuk Tim Kantor..."
                    selectOfficeJob()
                end

                if CurrentTargetComputer then
                    local targetModel = ComputersFolder:FindFirstChild(CurrentTargetComputer)
                    if targetModel and targetModel:FindFirstChild("Part") then
                        local targetPart = targetModel.Part
                        local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")

                        StatusText.Text = "Teleport ke Printer..."
                        teleportToPart(targetPart)
                        task.wait(0.5)
                        
                        if prompt then
                            interactPrompt(prompt)
                        end
                    end
                else
                    StatusText.Text = "Mencari Tugas..."
                end
            end)
        end
    end)
end

-- ==========================================
-- TOMBOL INTERAKSI UI
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    AutoOfficeEnabled = not AutoOfficeEnabled
    NoclipEnabled = AutoOfficeEnabled
    
    if AutoOfficeEnabled then
        ToggleBtn.Text = "AUTO FARM: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 200, 95)
        StatusText.Text = "Status: Aktif 🟢"
        showOverlay()
        startFarmLoop()
    else
        ToggleBtn.Text = "AUTO FARM: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(210, 45, 45)
        StatusText.Text = "Status: Standby 🔴"
        hideOverlay()
        if farmThread then
            task.cancel(farmThread)
            farmThread = nil
        end
    end
end)

BlackScreenBtn.MouseButton1Click:Connect(function()
    BlackScreenEnabled = not BlackScreenEnabled
    if BlackScreenEnabled then
        BlackScreenBtn.Text = "BLACK SCREEN: ON"
        BlackScreenBtn.BackgroundColor3 = Color3.fromRGB(45, 140, 200)
        if AutoOfficeEnabled then showOverlay() end
    else
        BlackScreenBtn.Text = "BLACK SCREEN: OFF"
        BlackScreenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        hideOverlay()
    end
end)

HideBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    hideOverlay()
end)

print("[Keren Hub] Native Custom UI Loaded Successfully!")
