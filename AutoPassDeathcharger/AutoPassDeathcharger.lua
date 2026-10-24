-- AutoPassDeathcharger 1.2.0 (WotLK 3.3.5): passes every loot roll on the items of its list and hides their roll
-- frame - ElvUI's roll bars and Blizzard's GroupLootFrame1-4.
-- RollOnLoot(rollID, 0) is the pass of the roll frame's own button. The frames are hidden again every frame for
-- HIDE_SECONDS: an addon that loads later (ElvUI) handles START_LOOT_ROLL after this one and shows its bar then.
-- 1.2.0: the list is saved per account (AutoPassDeathchargerDB.items) and edited with /autopass add|remove|list or in
-- Interface > AddOns > AutoPassDeathcharger. The two items of 1.1.1 are the starting list and can be removed too.
-- The panel also shows the last RECENT_MAX items rolled for that are not in the list (AutoPassDeathchargerDB.recent),
-- each with an Add button; an item added there shows "in list" until the panel closes, then it leaves "Last rolls".
local DEFAULTS = {
  [23193] = true,   -- Reins of the Naxxramas Deathcharger
  [39152] = true,   -- Manual: Heavy Frostweave Bandage
}
local HIDE_SECONDS = 1
local ROWS, ROW_HEIGHT = 8, 24
local RECENT_MAX = 6
local items = {}    -- the saved list once ADDON_LOADED ran
local recent = {}   -- the last rolled items not in the list, newest first: { id = , link = , icon = }
local justAdded = {} -- ids added with a "Last rolls" Add button while the panel is open

local function size(frame, w, h)
  frame:SetWidth(w)
  frame:SetHeight(h)
end

local function say(text)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AutoPass|r: " .. text)
end

-- An item id from a number or an item link ("|Hitem:23193:..."), else nil
local function toId(text)
  text = text or ""
  return tonumber(text:match("item:(%d+)") or text:match("^%s*(%d+)%s*$"))
end

-- The item's link if the client knows it, else "item <id>" (the client fills its cache when the item is seen)
local function label(id)
  local _, link = GetItemInfo(id)
  return link or ("item " .. id)
end

local function sortedIds()
  local ids = {}
  for id in pairs(items) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

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
local panel, popup  -- the Interface Options panel and the /autopass last window
local function changed()
  if panel and panel:IsShown() then panel.refresh() end
  if popup and popup:IsShown() then popup.refresh() end
end
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("START_LOOT_ROLL")
f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == "AutoPassDeathcharger" then
      if type(AutoPassDeathchargerDB) ~= "table" then AutoPassDeathchargerDB = {} end
      if type(AutoPassDeathchargerDB.items) ~= "table" then
        AutoPassDeathchargerDB.items = {}
        for id in pairs(DEFAULTS) do AutoPassDeathchargerDB.items[id] = true end
      end
      items = AutoPassDeathchargerDB.items
      if type(AutoPassDeathchargerDB.recent) ~= "table" then AutoPassDeathchargerDB.recent = {} end
      recent = AutoPassDeathchargerDB.recent
    end
    return
  end
  local link = GetLootRollItemLink(arg1)
  local id = link and tonumber(link:match("item:(%d+)"))
  if id and not items[id] then
    -- remember the item for the panel's "Last rolls", newest first, each item once (listed items are passed anyway)
    for i = #recent, 1, -1 do
      if recent[i].id == id then table.remove(recent, i) end
    end
    table.insert(recent, 1, { id = id, link = link, icon = (GetLootRollItemInfo(arg1)) })
    while #recent > RECENT_MAX do table.remove(recent) end
    changed()
  end
  if id and items[id] then
    RollOnLoot(arg1, 0)
    hideRollFrames(arg1)
    pending[arg1] = HIDE_SECONDS
    f:SetScript("OnUpdate", f.onUpdate)
    -- no chat line by default; remove the two dashes of the next line to get one
    -- say("passed on " .. link)
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

local function add(id)
  items[id] = true
  say("added " .. label(id))
  changed()
end

local function remove(id)
  if not items[id] then return say(label(id) .. " is not in the list") end
  items[id] = nil
  say("removed " .. label(id))
  changed()
end

SLASH_AUTOPASSDEATHCHARGER1 = "/autopass"
SlashCmdList.AUTOPASSDEATHCHARGER = function(msg)
  local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  cmd = cmd:lower()
  local id = toId(rest)
  if cmd == "add" and id then
    add(id)
  elseif cmd == "remove" and id then
    remove(id)
  elseif cmd == "list" then
    local ids = sortedIds()
    if #ids == 0 then return say("the list is empty") end
    for _, i in ipairs(ids) do say(i .. " " .. label(i)) end
  elseif cmd == "last" then
    if popup:IsShown() then popup:Hide() else popup:Show() end
  else
    say("/autopass add <item id or link>, /autopass remove <item id or link>, /autopass list, /autopass last")
  end
end

-- drop listed items from "Last rolls", except those just added there while a window shows them
local function pruneRecent()
  for i = #recent, 1, -1 do
    if items[recent[i].id] and not justAdded[recent[i].id] then table.remove(recent, i) end
  end
end

-- RECENT_MAX rows for the last rolled items below anchor: icon, link with the item tooltip on mouseover, Add / "in list"
local function makeRecentRows(parent, anchor, x, y)
  local list = {}
  for r = 1, RECENT_MAX do
    local row = CreateFrame("Frame", nil, parent)
    size(row, 360, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y - (r - 1) * ROW_HEIGHT)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
      local itemString = self.link and self.link:match("|H(item:[^|]+)|h")
      if itemString then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(itemString)
        GameTooltip:Show()
      end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    size(row.icon, 20, 20)
    row.icon:SetPoint("LEFT", 0, 0)
    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.add = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    size(row.add, 80, 20)
    row.add:SetPoint("RIGHT", 0, 0)
    row.add:SetText("Add")
    row.add:SetScript("OnClick", function(self)
      justAdded[self.id] = true
      add(self.id)
    end)
    row.inList = row:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    row.inList:SetPoint("RIGHT", -10, 0)
    row.inList:SetText("in list")
    list[r] = row
  end
  return list
end

local function refreshRecent(list)
  pruneRecent()
  for r = 1, RECENT_MAX do
    local e, row = recent[r], list[r]
    if e then
      row.icon:SetTexture(e.icon or select(10, GetItemInfo(e.id)) or "Interface\\Icons\\INV_Misc_QuestionMark")
      row.text:SetText(e.link or label(e.id))
      row.link = e.link
      row.add.id = e.id
      if items[e.id] then
        row.add:Hide()
        row.inList:Show()
      else
        row.inList:Hide()
        row.add:Show()
      end
      row:Show()
    else
      row:Hide()
    end
  end
end

-- /autopass last: a movable window with the last rolled items (ESC or the X closes it)
popup = CreateFrame("Frame", "AutoPassDeathchargerLast", UIParent)
size(popup, 392, 48 + RECENT_MAX * ROW_HEIGHT)
popup:SetPoint("CENTER")
popup:SetFrameStrata("DIALOG")
popup:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 } })
popup:EnableMouse(true)
popup:SetMovable(true)
popup:RegisterForDrag("LeftButton")
popup:SetScript("OnDragStart", popup.StartMoving)
popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
popup:Hide()
tinsert(UISpecialFrames, "AutoPassDeathchargerLast")
local popupTitle = popup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
popupTitle:SetPoint("TOPLEFT", 16, -16)
popupTitle:SetText("AutoPass: last rolls")
local popupClose = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
popupClose:SetPoint("TOPRIGHT", -4, -4)
local popupEmpty = popup:CreateFontString(nil, "ARTWORK", "GameFontDisable")
popupEmpty:SetPoint("TOPLEFT", popupTitle, "BOTTOMLEFT", 0, -10)
popupEmpty:SetText("No rolls yet.")
local popupRows = makeRecentRows(popup, popupTitle, 0, -8)
popup.refresh = function()
  refreshRecent(popupRows)
  if recent[1] then popupEmpty:Hide() else popupEmpty:Show() end
end
popup:SetScript("OnShow", function()
  wipe(justAdded)
  popup.refresh()
end)
popup:SetScript("OnHide", function()
  wipe(justAdded)
  pruneRecent()
end)

-- Interface > AddOns > AutoPassDeathcharger: the list with a Remove button per row, an Add box on top
panel = CreateFrame("Frame", "AutoPassDeathchargerPanel", UIParent)
panel.name = "AutoPassDeathcharger"
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("AutoPassDeathcharger")

local input = CreateFrame("EditBox", "AutoPassDeathchargerInput", panel, "InputBoxTemplate")
size(input, 220, 20)
input:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 6, -16)
input:SetAutoFocus(false)

local addButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
size(addButton, 80, 22)
addButton:SetPoint("LEFT", input, "RIGHT", 8, 0)
addButton:SetText("Add")
local function addFromInput()
  local id = toId(input:GetText())
  if id then
    add(id)
    input:SetText("")
  end
  input:ClearFocus()
end
addButton:SetScript("OnClick", addFromInput)
input:SetScript("OnEnterPressed", addFromInput)
input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local function header(text, anchor, x, y)
  local h = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
  h:SetText(text)
  return h
end

-- the last rolled items, each with an Add button (or "in list")
local recentHeader = header("Last rolls", input, -6, -14)
local recentRows = makeRecentRows(panel, recentHeader, 0, -4)

local listHeader = header("AutoPass list", recentHeader, 0, -8 - RECENT_MAX * ROW_HEIGHT)
local scroll = CreateFrame("ScrollFrame", "AutoPassDeathchargerScroll", panel, "FauxScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -4)
size(scroll, 360, ROWS * ROW_HEIGHT)

local rows = {}
for r = 1, ROWS do
  local row = CreateFrame("Frame", nil, panel)
  size(row, 360, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -(r - 1) * ROW_HEIGHT)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  size(row.icon, 20, 20)
  row.icon:SetPoint("LEFT", 0, 0)
  row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
  row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  size(row.remove, 80, 20)
  row.remove:SetPoint("RIGHT", 0, 0)
  row.remove:SetText("Remove")
  row.remove:SetScript("OnClick", function(self) remove(self.id) end)
  rows[r] = row
end

panel.refresh = function()
  refreshRecent(recentRows)
  local ids = sortedIds()
  FauxScrollFrame_Update(scroll, #ids, ROWS, ROW_HEIGHT)
  local offset = FauxScrollFrame_GetOffset(scroll)
  for r = 1, ROWS do
    local id, row = ids[offset + r], rows[r]
    if id then
      local texture = select(10, GetItemInfo(id))
      row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
      row.text:SetText(id .. "  " .. label(id))
      row.remove.id = id
      row:Show()
    else
      row:Hide()
    end
  end
end
scroll:SetScript("OnVerticalScroll", function(self, offset)
  FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, panel.refresh)
end)
panel:SetScript("OnShow", function()
  wipe(justAdded)
  panel.refresh()
end)
panel:SetScript("OnHide", function()
  wipe(justAdded)
  pruneRecent()
end)
InterfaceOptions_AddCategory(panel)
