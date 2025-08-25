-- TotemBar.lua — Vanilla/Turtle 1.12 macro builder (clean)

-- ==== Globals & SavedVariables bootstrapping ====
local _G = getfenv(0)
_G.TotemBarDB = _G.TotemBarDB or {}     -- SavedVariables (per character if set in .toc)
_G.TotemBar   = _G.TotemBar   or {}     -- namespace

local function EnsureDB()
  local db = _G.TotemBarDB
  db.chosen     = db.chosen     or { EARTH=nil, FIRE=nil, WATER=nil, AIR=nil }
  db.pos        = db.pos        or {}                      -- we persist absolute left/top only
  db.macroName  = db.macroName  or "TotemDrop"
  db.debug      = (db.debug == true)                       -- default OFF
  -- Safety: if Fire Nova Totem was previously saved, clear it (now unsupported)
  if db.chosen.FIRE == "Fire Nova Totem" then db.chosen.FIRE = nil end
end

local TOTEMS = {
  EARTH = { "Strength of Earth Totem","Stoneclaw Totem","Stoneskin Totem","Tremor Totem","Earthbind Totem" },
  -- Removed "Fire Nova Totem" from the FIRE list
  FIRE  = { "Searing Totem","Magma Totem","Flametongue Totem","Fire Resistance Totem" },
  WATER = { "Healing Stream Totem","Mana Spring Totem","Poison Cleansing Totem","Disease Cleansing Totem","Frost Resistance Totem" },
  AIR   = { "Windfury Totem","Grace of Air Totem","Windwall Totem","Grounding Totem","Nature Resistance Totem","Sentry Totem","Tranquil Air Totem" },
}

-- ==== Logging (toggleable) ====
local function TB_DebugOn() return _G.TotemBarDB and _G.TotemBarDB.debug end
local function Log(msg) if TB_DebugOn() then DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffTotemBar:|r "..tostring(msg)) end end
local function Info(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffTotemBar:|r "..tostring(msg)) end

-- ==== Tiny deferral helper (Vanilla-safe) ====
local function After(delay, fn)
  local f = CreateFrame("Frame")
  local runAt = GetTime() + (delay or 0)
  f:SetScript("OnUpdate", function()
    if GetTime() >= runAt then
      f:SetScript("OnUpdate", nil)
      local ok, err = pcall(fn)
      if not ok then Log("Deferred call failed: "..tostring(err)) end
    end
  end)
end

-- ==== Layout ====
local TB_BTN, TB_GAP, TB_PAD = 36, 10, 10
function TotemBar.SizeToFit()
  local w = TB_PAD + (TB_BTN*4) + (TB_GAP*3) + TB_PAD
  local h = TB_PAD + TB_BTN + TB_PAD
  TotemBarFrame:SetWidth(w); TotemBarFrame:SetHeight(h)
end

local BTNNAME = { EARTH="Earth", FIRE="Fire", WATER="Water", AIR="Air" }

-- ==== Spell helpers ====
local function NormalizeBaseName(s)
  if not s then return "" end
  s = string.gsub(s, "%s*%(%s*Rank%s+%d+%s*%)%s*$", "")
  s = string.gsub(s, "%s+Rank%s+%d+%s*$", "")
  return string.lower(s)
end

function GetSpellNameSafe(i)  -- global so everyone sees it regardless of order
  local ok, name = pcall(GetSpellName, i, "spell")
  if ok then return name end
  return nil
end

local function HasSpellByExactName(name)
  local i=1
  while true do local n=GetSpellNameSafe(i); if not n then break end
    if n==name then return true end
    i=i+1
  end
  return false
end

local function PlayerKnows(baseName)
  local want = NormalizeBaseName(baseName)
  local i=1
  while true do local n=GetSpellNameSafe(i); if not n then break end
    if NormalizeBaseName(n)==want then return n end
    i=i+1
  end
  return nil
end

local function FindSpellIndexAndTextureByBase(baseName)
  if not baseName then return nil,nil end
  local want = NormalizeBaseName(baseName)
  local i=1
  while true do local n=GetSpellNameSafe(i); if not n then break end
    if NormalizeBaseName(n)==want then
      local tex = GetSpellTexture and GetSpellTexture(i, "spell") or nil
      return i, tex
    end
    i=i+1
  end
  return nil,nil
end

-- ==== Recall/Call detection ====
local recallSpell
local function DetectRecall()
  if HasSpellByExactName("Totemic Call")   then return "Totemic Call"   end
  if HasSpellByExactName("Totemic Recall") then return "Totemic Recall" end
  return nil
end

-- ==== Macro icon: prefer a Recall-looking icon, fallback to "totem" ====
local function RecallIconIndex()
  if not GetMacroIconInfo then return 1 end
  for i=1,400 do local tex=GetMacroIconInfo(i); if not tex then break end
    local key = string.lower(tex)
    if string.find(key, "recall", 1, true) or string.find(key, "totemiccall", 1, true) then return i end
  end
  for i=1,400 do local tex=GetMacroIconInfo(i); if not tex then break end
    if string.find(string.lower(tex), "totem", 1, true) then return i end
  end
  return 1
end

-- ==== Element buttons: icon/label swap ====
function TotemBar.UpdateElementButton(which)
  EnsureDB()
  local pick = _G.TotemBarDB.chosen[which]
  local base  = "TotemBar_"..(BTNNAME[which] or which)
  local icon  = _G[base.."Icon"]
  local label = _G[base.."Label"]
  if not icon or not label then return end

  if pick then
    local _, tex = FindSpellIndexAndTextureByBase(pick)
    if tex then icon:SetTexture(tex); icon:Show(); label:Hide(); return end
  end
  icon:Hide()
  label:SetText(BTNNAME[which] or which); label:Show()
end

function TotemBar.UpdateAllButtons()
  TotemBar.UpdateElementButton("EARTH")
  TotemBar.UpdateElementButton("FIRE")
  TotemBar.UpdateElementButton("WATER")
  TotemBar.UpdateElementButton("AIR")
end

-- ==== Macro build/write ====
local function GetMacroIndexByNameCompat(name)
  if GetMacroIndexByName then
    local idx = GetMacroIndexByName(name)
    if idx and idx>0 then return idx end
  end
  local g,c = GetNumMacros()
  local total = (g or 0) + (c or 0)
  for i=1,total do local mName = GetMacroInfo(i); if mName==name then return i end end
  return nil
end

local function BuildMacroBody()
  EnsureDB()
  local db = _G.TotemBarDB
  local lines = {}

  if recallSpell then table.insert(lines, "/cast "..recallSpell) end

  local function add(slot)
    local pick = db.chosen[slot]
    -- Safety: skip Fire Nova Totem if somehow present
    if slot == "FIRE" and pick == "Fire Nova Totem" then
      pick = nil
      db.chosen.FIRE = nil
      Log("Fire Nova Totem is not supported and was removed from your Fire selection.")
    end
    if pick then
      local learned = PlayerKnows(pick)
      table.insert(lines, "/cast "..(learned or pick))
    end
  end

  -- After Recall: Fire, Earth, Water, Air
  add("FIRE"); add("EARTH"); add("WATER"); add("AIR")

  if table.getn(lines)==0 then
    return "/script DEFAULT_CHAT_FRAME:AddMessage('TotemBar: No spells selected');"
  end
  return table.concat(lines, "\n")
end

function TotemBar_EnsureOrUpdateMacro()
  EnsureDB()
  local name = (_G.TotemBarDB.macroName or "TotemDrop")
  local body = BuildMacroBody()
  local g,c  = GetNumMacros(); g,c = g or 0, c or 0
  local idx  = GetMacroIndexByNameCompat(name)
  local iconIndex = RecallIconIndex()

  if idx then
    local isChar = (idx > g)
    pcall(EditMacro, idx, name, iconIndex, body, isChar and 0 or 1, isChar and 1 or 0)
  else
    if not pcall(CreateMacro, name, iconIndex, body, 0, 1) then
      pcall(CreateMacro, name, iconIndex, body, 1, 0)
    end
  end
  Log("Macro updated.")
end

-- ==== Position save/restore (absolute left/top) ====
function TotemBar_SavePosition(frame)
  EnsureDB()
  local uiScale = UIParent:GetEffectiveScale() or 1
  local fScale  = frame:GetEffectiveScale() or 1
  local left, top = frame:GetLeft(), frame:GetTop()
  if not left or not top then return end
  _G.TotemBarDB.pos.left = left * fScale / uiScale
  _G.TotemBarDB.pos.top  = top  * fScale / uiScale
end

local function RestorePosition(frame)
  EnsureDB()
  frame:ClearAllPoints()
  local p = _G.TotemBarDB.pos
  if p and p.left and p.top then
    local uiScale = UIParent:GetEffectiveScale() or 1
    local fScale  = frame:GetEffectiveScale() or 1
    local x = p.left * uiScale / fScale
    local y = p.top  * uiScale / fScale
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
end

local function TotemBar_ResetPosition()
  TotemBarFrame:ClearAllPoints()
  TotemBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  TotemBar_SavePosition(TotemBarFrame)
  Log("position reset to center.")
end

-- ==== Dropdown menu ====
local menu = {}
function TotemBar_ShowMenu(elementKey, anchor)
  EnsureDB()
  menu = {}
  local ek = elementKey

  table.insert(menu, {
    text = "(none)",
    func = function()
      EnsureDB()
      _G.TotemBarDB.chosen[ek] = nil
      if CloseDropDownMenus then CloseDropDownMenus() end
      TotemBar.UpdateElementButton(ek)
      After(0.05, TotemBar_EnsureOrUpdateMacro)
      Log(tostring(ek).." set to none.")
    end
  })

  for _, baseName in ipairs(TOTEMS[ek]) do
    -- capture per-iteration copies (Lua 5.0 closure safety)
    local bn  = baseName
    local ek2 = ek

    local learned = PlayerKnows(bn)
    if learned then
      table.insert(menu, {
        text = learned,
        func = function()
          EnsureDB()
          _G.TotemBarDB.chosen[ek2] = bn
          if CloseDropDownMenus then CloseDropDownMenus() end
          TotemBar.UpdateElementButton(ek2)
          After(0.05, TotemBar_EnsureOrUpdateMacro)
          -- tostring-guard to avoid concat errors even if something's off
          Log(tostring(ek2).." → "..tostring(PlayerKnows(bn) or bn))
        end
      })
    end
  end

  if table.getn(menu)==1 then
    table.insert(menu, { text="(no known totems of this element)", notClickable=true, isTitle=true, disabled=true })
  end

  if not TotemBar_DropDown then return end
  UIDropDownMenu_Initialize(TotemBar_DropDown, function()
    for _, item in ipairs(menu) do UIDropDownMenu_AddButton(item, 1) end
  end, "MENU")
  ToggleDropDownMenu(1, nil, TotemBar_DropDown, anchor, 0, 0)
end

-- ==== Slash commands ====
SLASH_TOTEMBAR1 = "/totembar"
SlashCmdList["TOTEMBAR"] = function(msg)
  msg = string.lower(msg or "")
  if msg=="macro" or msg=="makemacro" then
    TotemBar_EnsureOrUpdateMacro(); Log("Macro |cff00ff00"..((_G.TotemBarDB.macroName) or "TotemDrop").."|r updated.")
  elseif msg=="show" then
    TotemBarFrame:Show()
  elseif msg=="hide" then
    TotemBarFrame:Hide()
  elseif msg=="resetpos" or msg=="reset" then
    TotemBar_ResetPosition()
  elseif msg=="dump" then
    if TB_DebugOn() then
      EnsureDB(); local d=_G.TotemBarDB
      DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffTotemBar:|r Picks FIRE=%s EARTH=%s WATER=%s AIR=%s",
        tostring(d.chosen.FIRE), tostring(d.chosen.EARTH), tostring(d.chosen.WATER), tostring(d.chosen.AIR)))
    end
  elseif msg=="showmacro" then
    if TB_DebugOn() then
      local body = BuildMacroBody()
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffTotemBar:|r Macro preview:")
      for line in string.gfind(body, "([^\n]+)") do DEFAULT_CHAT_FRAME:AddMessage("|cffdddddd"..line.."|r") end
    end
  elseif msg=="log on" then
    EnsureDB(); _G.TotemBarDB.debug=true; Info("Logging |cff00ff00ON|r")
  elseif msg=="log off" then
    EnsureDB(); _G.TotemBarDB.debug=false; Info("Logging |cffff0000OFF|r")
  else
    Info("Commands: /totembar show | hide | resetpos | macro | dump | showmacro | log on|off")
  end
end

-- ==== OnLoad / events ====
function TotemBar_OnLoad(frame)
  frame:RegisterEvent("VARIABLES_LOADED")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:RegisterEvent("SPELLS_CHANGED")
  frame:RegisterEvent("LEARNED_SPELL_IN_TAB")

  frame:SetMovable(true); frame:EnableMouse(true)
  if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
  frame:SetToplevel(true)
  if frame.SetUserPlaced then frame:SetUserPlaced(true) end

  frame:SetScript("OnEvent", function()
    if event=="VARIABLES_LOADED" or event=="PLAYER_LOGIN" then
      EnsureDB(); RestorePosition(TotemBarFrame); TotemBar.SizeToFit()
      TotemBar.UpdateAllButtons()
      recallSpell = DetectRecall()
      After(0.05, TotemBar_EnsureOrUpdateMacro)
    elseif event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" then
      recallSpell = DetectRecall()
      TotemBar.UpdateAllButtons()
      After(0.10, TotemBar_EnsureOrUpdateMacro)
    end
  end)
end
