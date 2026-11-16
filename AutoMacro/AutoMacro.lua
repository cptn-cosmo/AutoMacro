-- AutoMacro: creates per-character mouseover macros for healing spells,
-- dispels, buffs, resurrections and crowd control of the player's class, unless they already exist.

local ADDON = ...

-- Spells are referenced by (rank 1) spell ID so the lookup is locale-independent.
-- The macro casts by name without a rank, so the client always uses the highest rank known.
-- `short` is the macro name (max 16 characters, prefixed below).
local SPELLS = {
    PRIEST = {
        { id = 2050,  short = "Lesser Heal",  kind = "heal" },
        { id = 2054,  short = "Heal",         kind = "heal" },
        { id = 2060,  short = "Greater Heal", kind = "heal" },
        { id = 2061,  short = "Flash Heal",   kind = "heal" },
        { id = 139,   short = "Renew",        kind = "heal" },
        { id = 17,    short = "PW Shield",    kind = "heal" },
        { id = 527,   short = "Dispel Magic", kind = "dispel" },
        { id = 528,   short = "Cure Disease", kind = "dispel" },
        { id = 552,   short = "Abolish Dis",  kind = "dispel" },
        { id = 1243,  short = "PW Fort",      kind = "buff" },
        { id = 14752, short = "Divine Spirit",kind = "buff" },
        { id = 976,   short = "Shadow Prot",  kind = "buff" },
        { id = 6346,  short = "Fear Ward",    kind = "buff" },
        { id = 2006,  short = "Resurrection", kind = "res" },
    },
    DRUID = {
        { id = 5185,  short = "Healing Touch",kind = "heal" },
        { id = 8936,  short = "Regrowth",     kind = "heal" },
        { id = 774,   short = "Rejuv",        kind = "heal" },
        { id = 18562, short = "Swiftmend",    kind = "heal" },
        { id = 2782,  short = "Remove Curse", kind = "dispel" },
        { id = 8946,  short = "Cure Poison",  kind = "dispel" },
        { id = 2893,  short = "Abolish Pois", kind = "dispel" },
        { id = 1126,  short = "Mark of Wild", kind = "buff" },
        { id = 467,   short = "Thorns",       kind = "buff" },
        { id = 29166, short = "Innervate",    kind = "buff" },
        { id = 437138,short = "Revive",       kind = "res" },
        { id = 20484, short = "Rebirth",      kind = "res" },
        { id = 339,   short = "Ent Roots",    kind = "harm" },
    },
    PALADIN = {
        { id = 635,   short = "Holy Light",   kind = "heal" },
        { id = 19750, short = "Flash of Light",kind = "heal" },
        { id = 20473, short = "Holy Shock",   kind = "heal" },
        { id = 633,   short = "Lay on Hands", kind = "heal" },
        { id = 1152,  short = "Purify",       kind = "dispel" },
        { id = 4987,  short = "Cleanse",      kind = "dispel" },
        { id = 19740, short = "BoMight",      kind = "buff" },
        { id = 19742, short = "BoWisdom",     kind = "buff" },
        { id = 20217, short = "BoKings",      kind = "buff" },
        { id = 1038,  short = "BoSalvation",  kind = "buff" },
        { id = 19977, short = "BoLight",      kind = "buff" },
        { id = 20911, short = "BoSanctuary",  kind = "buff" },
        { id = 1022,  short = "BoProtection", kind = "buff" },
        { id = 1044,  short = "BoFreedom",    kind = "buff" },
        { id = 6940,  short = "BoSacrifice",  kind = "buff" },
        { id = 7328,  short = "Redemption",   kind = "res" },
    },
    SHAMAN = {
        { id = 331,   short = "Healing Wave", kind = "heal" },
        { id = 8004,  short = "Lesser HW",    kind = "heal" },
        { id = 1064,  short = "Chain Heal",   kind = "heal" },
        { id = 526,   short = "Cure Poison",  kind = "dispel" },
        { id = 2870,  short = "Cure Disease", kind = "dispel" },
        { id = 546,   short = "Water Walk",   kind = "buff" },
        { id = 131,   short = "Water Breath", kind = "buff" },
        { id = 2008,  short = "Ancestral Sp", kind = "res" },
    },
    MAGE = {
        { id = 475,   short = "Remove Curse", kind = "dispel" },
        { id = 1459,  short = "Arcane Int",   kind = "buff" },
        { id = 1008,  short = "Amplify Magic",kind = "buff" },
        { id = 604,   short = "Dampen Magic", kind = "buff" },
    },
    WARLOCK = {
        { id = 5697,  short = "Unending Brth",kind = "buff" },
        { id = 132,   short = "Detect Invis", kind = "buff" },
    },
}

local PREFIX = "@"                 -- macro names look like "@Flash Heal"
local ICON   = 134400              -- question mark => #showtooltip picks the spell icon
local MAX_CHAR_MACROS = MAX_CHARACTER_MACROS or 18
local MAX_ACCT_MACROS = MAX_ACCOUNT_MACROS or 120

local function Print(msg)
    print("|cff33ff99AutoMacro|r: " .. msg)
end

-- API compatibility (modern C_Spell first, legacy globals as fallback)
local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id)
    end
    return (GetSpellInfo(id))
end

local function KnowsSpell(id, name)
    if IsPlayerSpell and IsPlayerSpell(id) then return true end
    if IsSpellKnown and IsSpellKnown(id) then return true end
    -- Name lookup only resolves for spells in the player's spellbook; this also
    -- catches cases where Forever uses different spell IDs for the same spell.
    if name then
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(name)
            if info then return true end
        elseif GetSpellInfo then
            if GetSpellInfo(name) then return true end
        end
    end
    return false
end

-- Targeting conditions per spell kind.
local CONDITIONS = {
    heal   = "[@mouseover,help,nodead][help,nodead][@player]",
    dispel = "[@mouseover,help,nodead][help,nodead][@player]",
    buff   = "[@mouseover,help,nodead][help,nodead][@player]",
    res    = "[@mouseover,help,dead][help,dead]",
    harm   = "[@mouseover,harm,nodead][harm,nodead]",
}

local function BuildBody(spellName, kind)
    return "#showtooltip " .. spellName .. "\n"
        .. "/cast " .. (CONDITIONS[kind] or CONDITIONS.heal) .. " " .. spellName
end

-- True if any existing macro (account or character) already is a mouseover macro for this spell.
local function MouseoverMacroExists(macroName, spellName)
    if GetMacroIndexByName(macroName) > 0 then return true end
    local numAcct, numChar = GetNumMacros()
    local needle = spellName:lower()
    local function check(i)
        local _, _, body = GetMacroInfo(i)
        if body then
            local b = body:lower()
            if b:find("mouseover", 1, true) and b:find(needle, 1, true) then
                return true
            end
        end
    end
    for i = 1, numAcct do
        if check(i) then return true end
    end
    for i = MAX_ACCT_MACROS + 1, MAX_ACCT_MACROS + numChar do
        if check(i) then return true end
    end
    return false
end

-- Hide the prefix in action bar labels: "@Flash Heal" is shown as "Flash Heal".
-- Only touches the label FontString, so the macro name itself keeps the prefix.
local BAR_BUTTONS = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton",
    "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
}

local function StripLabel(fs, text)
    if text and text:sub(1, #PREFIX) == PREFIX then
        fs:SetText(text:sub(#PREFIX + 1))   -- re-enters the hook once, without the prefix
    end
end

local function HookBarLabels()
    for _, base in ipairs(BAR_BUTTONS) do
        for i = 1, 12 do
            local button = _G[base .. i]
            local fs = button and (button.Name or _G[base .. i .. "Name"])
            if fs and not fs.AutoMacroHooked then
                fs.AutoMacroHooked = true
                hooksecurefunc(fs, "SetText", StripLabel)
                StripLabel(fs, fs:GetText())
            end
        end
    end
end

local pending = false
local frame = CreateFrame("Frame")

local function Generate(verbose)
    if InCombatLockdown() then
        pending = true
        if verbose then Print("In combat, macros will be created afterwards.") end
        return
    end
    pending = false

    if AutoMacroDB and AutoMacroDB.disabled and not verbose then return end

    local _, class = UnitClass("player")
    local list = SPELLS[class]
    if not list then
        if verbose then Print("No heals, dispels or buffs defined for your class.") end
        return
    end

    local created, full = {}, false
    for _, entry in ipairs(list) do
        if not (AutoMacroDB.skip and AutoMacroDB.skip[entry.short]) then
            local name = SpellName(entry.id)
            if name and KnowsSpell(entry.id, name) then
                local macroName = (PREFIX .. entry.short):sub(1, 16)
                if not MouseoverMacroExists(macroName, name) then
                    local _, numChar = GetNumMacros()
                    if numChar >= MAX_CHAR_MACROS then
                        full = true
                        break
                    end
                    local ok, idx = pcall(CreateMacro, macroName, ICON, BuildBody(name, entry.kind), true)
                    if ok and idx then
                        created[#created + 1] = macroName
                    end
                end
            end
        end
    end

    if #created > 0 then
        Print("Created " .. #created .. " macro(s): " .. table.concat(created, ", "))
    elseif verbose then
        Print("All mouseover macros already exist.")
    end
    if full then
        Print("Character macro slots are full, some macros could not be created.")
    end
end

-- Throttle SPELLS_CHANGED, which can fire in bursts.
local scheduled = false
local function Schedule()
    if scheduled then return end
    scheduled = true
    C_Timer.After(2, function()
        scheduled = false
        Generate(false)
    end)
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            AutoMacroDB = AutoMacroDB or {}
            AutoMacroDB.skip = AutoMacroDB.skip or {}
        end
    elseif event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED" then
        if event == "PLAYER_LOGIN" then HookBarLabels() end
        Schedule()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pending then Generate(false) end
    end
end)

SLASH_AUTOMACRO1 = "/automacro"
SLASH_AUTOMACRO2 = "/am"
SlashCmdList.AUTOMACRO = function(msg)
    local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" or cmd == "run" then
        Generate(true)
    elseif cmd == "on" then
        AutoMacroDB.disabled = nil
        Print("Automatic generation enabled.")
        Generate(true)
    elseif cmd == "off" then
        AutoMacroDB.disabled = true
        Print("Automatic generation disabled. Use /am run to generate manually.")
    elseif cmd == "skip" and rest ~= "" then
        AutoMacroDB.skip[rest] = not AutoMacroDB.skip[rest] or nil
        Print((AutoMacroDB.skip[rest] and "Skipping " or "No longer skipping ") .. rest)
    elseif cmd == "list" then
        local _, class = UnitClass("player")
        for _, e in ipairs(SPELLS[class] or {}) do
            local name = SpellName(e.id) or ("#" .. e.id)
            local known = KnowsSpell(e.id, SpellName(e.id)) and "known" or "not known"
            local skip = AutoMacroDB.skip[e.short] and ", skipped" or ""
            Print(("%s [%s] %s (%s%s)"):format(PREFIX .. e.short, e.kind, name, known, skip))
        end
    else
        Print("/am run | on | off | list | skip <short name>")
    end
end
