-- AutoPassDeathcharger 1.1.1 (WotLK 3.3.5): passes every loot roll on the items below and hides their roll frame
-- ElvUI's roll bars and Blizzard's GroupLootFrame1-4
-- RollOnLoot(rollID, 0) is the pass of the roll frame's own button. The frames are hidden again every frame for
-- HIDE_SECONDS: an addon that loads later (ElvUI) handles START_LOOT_ROLL after this one and shows its bar then.
local ITEMS = {
  [23193] = true,   -- Reins of the Naxxramas Deathcharger
  [39152] = true,   -- Manual: Heavy Frostweave Bandage
}
local HIDE_SECONDS = 1

local function hideRollFrames(rollID)
  for i = 1, 4 do
    local g = _G["GroupLootFrame" .. i]
    if g and g.rollID == rollID then g:Hide() end
  end
  local M = ElvUI and ElvUI[1] and ElvUI[1].GetModule and ElvUI[1]:GetModule("Misc", true)
  for _, bar in ipairs(M and M.RollBars or {}) do
    if bar.rollID == rollID then bar:Hide() end
  end
end

local f = CreateFrame("Frame")
local pending = {}
f:RegisterEvent("START_LOOT_ROLL")
f:SetScript("OnEvent", function(_, _, rollID)
  local link = GetLootRollItemLink(rollID)
  local id = link and tonumber(link:match("item:(%d+)"))
  if id and ITEMS[id] then
    RollOnLoot(rollID, 0)
    hideRollFrames(rollID)
    pending[rollID] = HIDE_SECONDS
    f:SetScript("OnUpdate", f.onUpdate)
    -- no chat line by default; remove the two dashes of the next line to get one
    -- DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AutoPassDeathcharger|r: passed on " .. link)
  end
end)
f.onUpdate = function(self, elapsed)
  local any = false
  for rollID, left in pairs(pending) do
    hideRollFrames(rollID)
    left = left - elapsed
    if left <= 0 then pending[rollID] = nil else pending[rollID] = left; any = true end
  end
  if not any then self:SetScript("OnUpdate", nil) end
end
