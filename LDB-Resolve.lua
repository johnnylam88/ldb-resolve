--[[
	Credits
	To Dridzt for Vengeance Status – which gave me an initial idea how I could detect the vengeance buff, and how to check for the value
	To Shackleford for LDB-Threat – I had no clue how to write a data source
]]--

local addonName, ns = ...
local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(addonName)

local API_CreateFrame = CreateFrame
local API_GetAddOnMetadata = GetAddOnMetadata
local API_GetSpellBookItemInfo = GetSpellBookItemInfo
local API_GetSpellInfo = GetSpellInfo
local API_UnitAura = UnitAura
local API_UnitClass = UnitClass

local select = select
local tonumber = tonumber

local addonVersion = API_GetAddOnMetadata(addonName, "Version")
local addon = API_CreateFrame("Frame", addonName)
local defaultLDB = {
	icon = "Interface\\Icons\\Ability_Paladin_ShieldofVengeance",
	type = "data source",
	text = 0,
	value = 0,
}
local LDBResolve = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, defaultLDB)

local isTank = false
local playerClass = select(2, API_UnitClass("player"))
local resolveSpellName = API_GetSpellInfo(158298)	-- known Resolve spell ID

-- Table of classes with a tanking specialization.
local tankClass = {
	DEATHKNIGHT = true,
	DRUID = true,
	MONK = true,
	PALADIN = true,
	WARRIOR = true,
}

local function EventHandler(self, event, ...)
	if self[event] then
		self[event](self, event, ...)
	end
end

-- Addon initialization.
do
	addon:RegisterEvent(IsAddOnLoaded('AddonLoader') and 'ADDON_LOADED' or 'PLAYER_LOGIN')
	addon:SetScript('OnEvent', EventHandler)
end

-- Frame events.
function LDBResolve:OnTooltipShow()
	self:AddLine("|cff00ff00"..addonName.." "..addonVersion.."|r")
	self:AddLine("|cffffffff"..L['Displays the current value of your Resolve buff'].."|r")
end

-- Game events.
function addon:ACTIVE_TALENT_GROUP_CHANGED()
	self:UpdateTankStatus()
	self:SetLDBDisplay(self:GetResolve())
end

function addon:ADDON_LOADED(event, name)
	if name == addonName then
		-- Unregister ADDON_LOADED event so that this handler only runs once.
		self:UnregisterEvent(event)
		self:PLAYER_LOGIN(event)
	end
end

function addon:PLAYER_LOGIN()
	-- Set the default LDB display values when entering the world.
	self:SetLDBDisplay(defaultLDB.value, defaultLDB.icon)

	if tankClass[playerClass] then
		self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
		self:RegisterEvent('UNIT_LEVEL')
		self:UpdateTankStatus()
		self:SetLDBDisplay(self:GetResolve())
	end
end

function addon:UNIT_AURA(event, unit)
	if unit == "player" and isTank then
		self:SetLDBDisplay(self:GetResolve())
	end
end

function addon:UNIT_LEVEL(event, unit)
	if unit == "player" then
		self:ACTIVE_TALENT_GROUP_CHANGED()
	end
end

-- Public methods.
function addon:GetResolve()
	local _, _, icon, _, _, _, _, _, _, _, _, _, _, _, value = API_UnitAura("player", resolveSpellName)
	icon = icon or defaultLDB.icon
	value = value or 0
	return value, icon
end

function addon:SetLDBDisplay(value, icon)
	LDBResolve.icon = icon
	LDBResolve.value = value or 0
	LDBResolve.text = LDBResolve.value
end

function addon:UpdateTankStatus()
	-- Player is considered to be in a tanking specialization if the passive spell
	-- "Resolve" is present in the player's spellbook.
	local spellId = select(2, API_GetSpellBookItemInfo(ResolveSpellName))
	if spellId and tankClass[playerClass] then
		isTank = true
		self:RegisterEvent('UNIT_AURA')
	else
		isTank = false
		self:UnregisterEvent('UNIT_AURA')
	end
end
