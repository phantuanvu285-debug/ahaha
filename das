
--==================================================
-- AUTO PLAYTIME GIFT 1-4 + OPEN PANEL + REJOIN
--==================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

-- CONFIG
local MAX_GIFT = 4
local CHECK_INTERVAL = 3
local CLAIM_TIMEOUT = 15
local REJOIN_DELAY = 5

-- STOP:
-- _G.STOP_AUTO_PLAYTIME = true

_G.STOP_AUTO_PLAYTIME = false

local placeId = game.PlaceId
local jobId = game.JobId

local function stopped()
    return _G.STOP_AUTO_PLAYTIME == true
end

local function getOpenButton()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end

    local topBar = pg:FindFirstChild("TopBar")
    if not topBar then return nil end

    local barRight = topBar:FindFirstChild("BarRight")
    if not barRight then return nil end

    return barRight:FindFirstChild("PlaytimeGifts")
end

local function getGift(index)
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end

    local panel = pg:FindFirstChild("PlaytimeGifts")
    if not panel then return nil end

    local holder = panel:FindFirstChild("Holder")
    if not holder then return nil end

    local root = holder:FindFirstChild("Root")
    if not root then return nil end

    local gifts = root:FindFirstChild("PlaytimeGifts")
    if not gifts then return nil end

    return gifts:FindFirstChild("Gift" .. index)
end

local function openGiftPanel()
    print("[OPEN] Opening Playtime Gifts...")

    local button = getOpenButton()

    if not button then
        warn("[ERROR] Cannot find PlaytimeGifts open button")
        return false
    end

    local success, err = pcall(function()
        firesignal(button.Activated)
    end)

    if not success then
        warn("[OPEN ERROR]", err)
        return false
    end

    for i = 1, 10 do
        if stopped() then return false end

        local gift = getGift(1)
        if gift then
            print("[OPEN] Gift panel ready")
            return true
        end

        task.wait(1)
    end

    warn("[ERROR] Gift panel did not load")
    return false
end

local function waitForGift(index)
    print("[WAIT] Gift" .. index)

    while not stopped() do
        local gift = getGift(index)

        if gift and gift:FindFirstChild("Top")
            and gift:FindFirstChild("Check") then

            if gift.Check.Visible then
                print("[DONE] Gift" .. index .. " already claimed")
                return true
            end

            if gift.Top.Text == "CLAIM!" then
                print("[READY] Gift" .. index)
                return true
            end
        end

        task.wait(CHECK_INTERVAL)
    end

    return false
end

local function claimGift(index)
    local gift = getGift(index)

    if not gift then
        warn("[ERROR] Missing Gift" .. index)
        return false
    end

    if gift.Check.Visible then
        print("[SKIP] Gift" .. index .. " already claimed")
        return true
    end

    if gift.Top.Text ~= "CLAIM!" then
        return false
    end

    print("[CLAIM] Gift" .. index)

    local success, err = pcall(function()
        firesignal(gift.Activated)
    end)

    if not success then
        warn("[CLAIM ERROR]", err)
        return false
    end

    local started = os.clock()

    repeat
        task.wait(1)

        if stopped() then return false end

        if gift.Check.Visible then
            print("[SUCCESS] Gift" .. index)
            return true
        end
    until os.clock() - started >= CLAIM_TIMEOUT

    warn("[TIMEOUT] Gift" .. index)
    return false
end

local function rejoinSameServer()
    if stopped() then return end

    print("[REJOIN] Same server in", REJOIN_DELAY, "seconds")
    task.wait(REJOIN_DELAY)

    if stopped() then return end

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            placeId,
            jobId,
            player
        )
    end)

    if not success then
        warn("[REJOIN ERROR]", err)
    end
end

-- MAIN
print("========== AUTO PLAYTIME START ==========")

if openGiftPanel() then
    local allClaimed = true

    for i = 1, MAX_GIFT do
        if stopped() then
            allClaimed = false
            break
        end

        if not waitForGift(i) then
            allClaimed = false
            break
        end

        if not claimGift(i) then
            allClaimed = false
            break
        end

        task.wait(2)
    end

    if allClaimed and not stopped() then
        print("[COMPLETE] Gift1-4 claimed")
        rejoinSameServer()
    else
        warn("[STOP] Cycle interrupted or claim failed")
    end
end

print("========== AUTO PLAYTIME ENDED ==========")
