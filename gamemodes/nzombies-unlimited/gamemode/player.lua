local PLAYER = FindMetaTable("Player")

local datatables = {}
function nzu.AddPlayerNetworkVar(type, name, extended)
	if not datatables[type] then datatables[type] = {} end
	local slot = table.insert(datatables[type], {name, extended})

	-- Install into all current players
	if SERVER then
		for k,v in pairs(player.GetAll()) do
			if v.nzu_dt then
				v:NetworkVar(type, slot, name, extended)
			end
		end
	elseif LocalPlayer().nzu_dt then
		LocalPlayer():NetworkVar(type, slot, name, extended)
	end
end

local notifies = {}
function nzu.AddPlayerNetworkVarNotify(name, func) -- Doesn't really work on client right now :/
	if not notifies[name] then notifies[name] = {} end
	table.insert(notifies[name], func)

	-- Install into all current players
	if SERVER then
		for k,v in pairs(player.GetAll()) do
			if v.nzu_dt then
				v:NetworkVarNotify(name, func)
			end
		end
	elseif LocalPlayer().nzu_dt then
		LocalPlayer():NetworkVarNotify(name, func)
	end
end

function nzu.InstallPlayerNetworkVars(ply)
	ply:InstallDataTable()

	for k,v in pairs(datatables) do
		for slot,data in pairs(v) do
			ply:NetworkVar(k, slot, data[1], data[2])
		end
	end

	for k,v in pairs(notifies) do
		for k2,v2 in pairs(v) do
			ply:NetworkVarNotify(k, v2)
		end
	end

	-- This will get overwritten if something else does ply:InstallDataTable() as the "dt" will be a new empty table
	-- We use this to check whether our default non-class network vars exist, or not
	ply.nzu_dt = true
end

hook.Add("OnEntityCreated", "nzu_PlayerNetworkVars", function(ply)
	if ply:IsPlayer() then
		nzu.InstallPlayerNetworkVars(ply)
	end
end)

--[[-------------------------------------------------------------------------
Models and stuff
---------------------------------------------------------------------------]]
if CLIENT then
	CreateConVar( "cl_playercolor", "0.24 0.34 0.41", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	CreateConVar( "cl_weaponcolor", "0.30 1.80 2.10", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	CreateConVar( "cl_playerskin", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The skin to use, if the model has any" )
	CreateConVar( "cl_playerbodygroups", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The bodygroups to use, if the model has any" )
end

if SERVER then
	-- Skin not actually set? Copied from Sandbox
	function PLAYER:UpdateModel()
		local c_mdl = self:GetInfo("cl_playermodel")
		local mdl = player_manager.TranslatePlayerModel(c_mdl)
		util.PrecacheModel(mdl)
		self:SetModel(mdl)
		self:SetPlayerColor(Vector(self:GetInfo("cl_playercolor")))

		local col = Vector(self:GetInfo("cl_weaponcolor"))
		if col:Length() == 0 then
			col = Vector(0.001, 0.001, 0.001)
		end
		self:SetWeaponColor(col)
	end
	
	hook.Add("PlayerInitialSpawn", "nzu_PlayerInit", function(ply)
		ply:UpdateModel()
	end)
end