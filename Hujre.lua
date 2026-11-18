-- ==========================================
-- CLEAN TEST SCRIPT: NUNGGU DIPANGGIL -> JALAN -> AUTO SOLVE -> SOAL BERES -> LOMPAT -> JALAN KE KURSI
-- ==========================================
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ComputersFolder = Workspace:WaitForChild("Computers")

local PrinterCoordinates = {
    ["Print_1"] = Vector3.new(-6008.849, 5.956, -210.805),
    ["Print_2"] = Vector3.new(-6008.840, 5.966, -224.522),
    ["Print_3"] = Vector3.new(-6008.839, 5.979, -238.361),
    ["Print_4"] = Vector3.new(-5868.426, 5.982, -213.191),
    ["Print_5"] = Vector3.new(-5868.429, 5.956, -249.965),
}

local PrinterSeats = {
    ["Print_1"] = Vector3.new(-5968.743, 4.643, -228.440),
    ["Print_2"] = Vector3.new(-5968.743, 4.643, -228.440),
    ["Print_3"] = Vector3.new(-5967.168, 4.643, -260.844),
    ["Print_4"] = Vector3.new(-5878.439, 4.643, -228.620),
    ["Print_5"] = Vector3.new(-5880.500, 4.643, -261.013),
}

local function walkToPosition(targetPos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })

    path:ComputeAsync(hrp.Position, targetPos)
    
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
end

local function solveOfficeTask()
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
    task.wait(math.random(5, 10) / 10)

    local frame = workGui:FindFirstChild("Frame")
    if not frame then return end

    for _, obj in ipairs(frame:GetChildren()) do
        if obj.Name == "AnswerButton" or obj:IsA("TextButton") then
            local btnText = obj:IsA("TextButton") and obj.Text or (obj:FindFirstChildOfClass("TextLabel") and obj:FindFirstChildOfClass("TextLabel").Text or "")
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
                task.wait(1.0)
                break
            end
        end
    end
end

local function runTestCycle(testPrinterName)
    print("[TEST] Memulai siklus untuk: " .. testPrinterName)
    local targetPos = PrinterCoordinates[testPrinterName]
    local targetSeat = PrinterSeats[testPrinterName]

    if not targetPos or not targetSeat then 
        print("[TEST] Nama printer tidak valid! Gunakan Print_1 sampai Print_5")
        return 
    end

    -- 1. Jalan kaki ke printer target
    print("[TEST] Berjalan kaki menuju " .. testPrinterName)
    walkToPosition(targetPos + Vector3.new(0, 0, 1.5))
    task.wait(0.3)

    -- 2. Klik proximity prompt printer
    local printerModel = ComputersFolder:FindFirstChild(testPrinterName)
    if printerModel then
        for _, desc in ipairs(printerModel:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and fireproximityprompt then
                fireproximityprompt(desc)
                break
            end
        end
    end

    -- 3. Tunggu WorkGui muncul lalu auto-solve semua soal math
    print("[TEST] Menunggu dan mengerjakan semua soal math...")
    local startTime = tick()
    local guiFound = false
    
    while tick() - startTime < 4 do
        if PlayerGui:FindFirstChild("WorkGui") then
            guiFound = true
            break
        end
        task.wait(0.1)
    end

    if guiFound then
        while PlayerGui:FindFirstChild("WorkGui") do
            solveOfficeTask()
            task.wait(0.5)
        end
        print("[TEST] Semua soal math selesai dikerjakan!")
    else
        print("[TEST] WorkGui tidak muncul, lanjut...")
    end

    task.wait(0.5)

    -- 4. JUMP FIX: Lompat sekali pas semua soal beres sebelum jalan balik
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Sit = false
        humanoid.PlatformStand = false
        task.wait(0.1)
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        humanoid.Jump = true
        print("[TEST] Soal selesai -> Karakter melompat!")
        task.wait(0.8)
    end

    -- 5. Jalan kaki balik ke kursi printer terdekat
    print("[TEST] Berjalan kaki kembali ke kursi " .. testPrinterName)
    walkToPosition(targetSeat)

    task.wait(0.3)
    if humanoid then
        humanoid.Sit = true
    end
    print("[TEST] Selesai! Berhasil duduk manis di kursi " .. testPrinterName)
end

-- Daftarkan ke global environment supaya bisa dipanggil manual via console executor:
-- Contoh ketik di console: RunTest("Print_1") atau RunTest("Print_5")
getgenv().RunTest = runTestCycle

print("[TEST SCRIPT LOADED] Ketik RunTest('Print_1') sampai RunTest('Print_5') di console executor untuk mulai.")
