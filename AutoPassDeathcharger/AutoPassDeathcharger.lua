-- AutoPassDeathcharger 1.0.1 (WotLK 3.3.5): passes every loot roll on item 23193, Reins of the Naxxramas Deathcharger,
-- and hides its roll frame (ElvUI's roll bars and Blizzard's GroupLootFrame1-4). Nothing else, no settings.
-- RollOnLoot(rollID, 0) is the pass of the roll frame's own button.
local ITEM_ID = 23193

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
f:RegisterEvent("START_LOOT_ROLL")
f:SetScript("OnEvent", function(_, _, rollID)
  local link = GetLootRollItemLink(rollID)
  local id = link and tonumber(link:match("item:(%d+)"))
  if id == ITEM_ID then
    RollOnLoot(rollID, 0)
    hideRollFrames(rollID)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AutoPassDeathcharger|r: passed on " .. link)
  end
end)
