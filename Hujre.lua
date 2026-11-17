-- ==========================================
-- Hujre.lua - KEREN HUB (BOT LOGIC & AUTO FARM)
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local JobEvents = ReplicatedStorage:WaitForChild("JobEvents")
local AssignPrintJob = JobEvents:WaitForChild("AssignPrintJob")
local ComputersFolder = Workspace:WaitForChild("Computers")

local PrinterCoordinates = {
    ["Print_1"] = Vector3.new(-6008.849, 5.956, -210.805),
    ["Print_2"] = Vector3.new(-6008.840, 5.966, -224.522),
    ["Print_3"] = Vector3.new(-6008.839, 5.979, -238.361),
    ["Print_4"] = Vector3.new(-5868.426, 5.982, -213.191),
    ["Print_5"] = Vector3.new(-5868.429, 5.956, -249.965),
}

-- Rute Waypoints Custom menuju ke area Office / Kursi deket Printer 3
local OfficeWaypoints = {
    CFrame.new(-876.491, 2.788, -627.639),
    CFrame.new(-1727.164, 37.488, -575.180),
    CFrame.new(-3162.552, 2.788, -548.694),
    CFrame.new(-4445.568, 2.759, -554.887),
    CFrame.new(-5936.579, 2.759, -553.939),
    CFrame.new(-5988.250, 4.624, -254.500) -- Titik akhir di area printer 3
}

local function autoSelectJob()
    pcall(function()
        local event = JobEvents:FindFirstChild("TeamChangeRequest")
        if event then
            event:FireServer("Office Worker", 11378976, 0, 0, "Detector")
        end
    end)
end

-- Deklarasi awal fungsi printer supaya bisa dipanggil di dalam waypoint
local walkToActivePrinter

-- Fungsi Perjalanan Beruntun dengan Seated Teleport & Anti-Pingsan (Jump Fix)
local function travelToOfficeWaypoints(onComplete)
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end

        local totalPoints = #OfficeWaypoints
        for index, targetCFrame in ipairs(OfficeWaypoints) do
            hrp.CFrame = targetCFrame
            
            -- Jika sudah di titik terakhir kantor (kursi / area printer 3)
            if index == totalPoints then
                task.wait(0.2)
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping) -- Supaya gak pingsan
                task.wait(0.5)
                
                -- Begitu sampai di kantor, langsung jalankan callback (jalan ke printer)
                if onComplete then
                    onComplete()
                end
            else
                -- Waypoint biasa: duduk di angin sebentar, lalu bangunin lagi buat lanjut
                humanoid.Sit = true
                task.wait(1)
                humanoid.Sit = false
                task.wait(0.1)
            end
        end
    end)
end

-- Fungsi Pemicu Awal saat Toggle Auto Farm Dinyalakan di UI (Yobuy.lua)
local function startInitialFarm()
    pcall(function()
        autoSelectJob()
        task.wait(3) -- Jeda 3 detik select job

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end

        -- Duduk dulu di posisi awal sebelum mulai rute
        humanoid.Sit = true
        task.wait(1)

        -- Lempar ke waypoint pertama
        hrp.CFrame = OfficeWaypoints[1] + Vector3.new(0, 2, 0)
        task.wait(1)

        -- Mulai rute, dan begitu sampai di kursi kantor, langsung suruh jalan ke printer aktif
        travelToOfficeWaypoints(function()
            walkToActivePrinter()
        end)
    end)
end

-- Fungsi Selesai Nge-print: Balik ke Kursi Kantor, lalu seated teleport lagi ke area printer
local function returnToSeat(printerName)
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end

        -- Duduk dulu sebentar di area printer sebelum balik ke kursi utama
        humanoid.Sit = true
        task.wait(1)

        -- Teleport balik ke titik awal waypoint (kursi standby)
        hrp.CFrame = OfficeWaypoints[1] + Vector3.new(0, 2, 0)
        task.wait(1)

        -- Lakukan seated teleport lagi untuk kembali ke area printer/kantor secara looping
        travelToOfficeWaypoints(function()
            walkToActivePrinter()
        end)
    end)
end

walkToActivePrinter = function()
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end

        if humanoid.SeatPart then
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(1)
        end

        local targetPrinterName = nil
        local targetPos = nil
        local targetPrompt = nil
        local foundActive = false

        local attempts = 0
        while not foundActive and attempts < 15 do
            attempts = attempts + 1

            for i = 1, 5 do
                local pName = "Print_" .. tostring(i)
                local printerModel = ComputersFolder:FindFirstChild(pName)
                
                if printerModel then
                    local isPromptEnabled = false
                    local foundPrompt = nil

                    for _, descendant in ipairs(printerModel:GetDescendants()) do
                        if descendant:IsA("ProximityPrompt") then
                            foundPrompt = descendant
                            if descendant.Enabled then
                                isPromptEnabled = true
                            end
                            break
                        end
                    end

                    if isPromptEnabled and foundPrompt then
                        targetPrinterName = pName
                        targetPos = PrinterCoordinates[pName]
                        targetPrompt = foundPrompt
                        foundActive = true
                        break
                    end
                end
            end

            if not foundActive then
                task.wait(0.4)
            end
        end

        if targetPos and targetPrinterName then
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true
            })

            path:ComputeAsync(hrp.Position, targetPos + Vector3.new(0, 0, 1.5))
            
            if path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                for _, waypoint in ipairs(waypoints) do
                    humanoid:MoveTo(waypoint.Position)
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                    
                    local reached = false
                    local conn
                    conn = humanoid.MoveToFinished:Connect(function()
                        reached = true
                        if conn then conn:Disconnect() end
                    end)
                    
                    local t = tick()
                    while not reached and (tick() - t) < 0.8 do
                        task.wait(0.05)
                    end
                    if conn then conn:Disconnect() end
                end
            else
                humanoid:MoveTo(targetPos)
                task.wait(1.5)
            end

            task.wait(0.3)
            if targetPrompt and fireproximityprompt then
                fireproximityprompt(targetPrompt)
            end

            task.wait(0.8)
            returnToSeat(targetPrinterName)
        end
    end)
end

-- Daftarkan fungsi ke global environment supaya bisa dipanggil dari Yobuy.lua
getgenv().RunManualPrinter = walkToActivePrinter
getgenv().RunInitialFarm = startInitialFarm

local function solveOfficeTask()
    pcall(function()
        local workGui = PlayerGui:FindFirstChild("WorkGui")
        if not workGui then return end

        local questionLabel = workGui:FindFirstChild("QuestionLabel") or workGui:FindFirstChild("TextLabel")
        if not questionLabel then return end

        local rawText = questionLabel.Text
        if not rawText or rawText == "" then return end

        if not (rawText:find("%+") or rawText:find("%-")) then return end

        local cleanExpr = rawText:gsub("=.*", ""):gsub("[^%d%+%-]", "")
        local mathFunc = loadstring("return " .. cleanExpr)
        if not mathFunc then return end

        local success, result = pcall(mathFunc)
        if not success or not result then return end
        
        local targetAnswer = tostring(result)

        task.wait(math.random(10, 15) / 10)

        local frame = workGui:FindFirstChild("Frame")
        if not frame then return end

        for _, obj in ipairs(frame:GetChildren()) do
            if obj.Name == "AnswerButton" or obj:IsA("TextButton") then
                local btnText = ""
                if obj:IsA("TextButton") then
                    btnText = obj.Text
                else
                    local lbl = obj:FindFirstChildOfClass("TextLabel")
                    if lbl then btnText = lbl.Text end
                end

                local cleanBtnText = btnText:gsub("%D", "")

                if cleanBtnText == targetAnswer or btnText == targetAnswer then
                    if obj:IsA("GuiButton") then
                        if firesignal then
                            firesignal(obj.MouseButton1Click)
                            firesignal(obj.Activated)
                        else
                            obj:Activate()
                        end
                    end
                    
                    task.wait(1.2)
                    break
                end
            end
        end
    end)
end

task.spawn(function()
    while true do
        if getgenv().AutoFarmActive then
            solveOfficeTask()
        end
        task.wait(1)
    end
end)

AssignPrintJob.OnClientEvent:Connect(function()
    if not getgenv().AutoFarmActive then return end
    task.wait(0.5)
    walkToActivePrinter()
end)
