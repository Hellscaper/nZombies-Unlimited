
local function generatesettingspanel(ext)
	local p = vgui.Create("nzu_ExtensionPanel")
	p:SetExtension(ext)
	return p
end

local function createextensionsettingspanel(ext, pnl)
	--[[local p = vgui.Create("DPanel")
	p:SetBackgroundColor(Color(0,255,0))
	p:SetSize(100,500)

	extpanels[ext]:SetContents(p)]]

	local p = vgui.Create("nzu_ExtensionPanel", pnl)
	p:SetExtension(nzu.GetExtension(ext))

	if IsValid(pnl.Contents) then pnl.Contents:Remove() end
	timer.Simple(0, function()
		if pnl:GetExpanded() then
			pnl:SetTall(p:GetTall() + pnl.Header:GetTall())
		else
			pnl.OldHeight = p:GetTall() + pnl.Header:GetTall()
			pnl:DoExpansion(true)
		end
		pnl:SetContents(p)
	end)
end

local tounload = {}
local function checkboxchange(self,b)
	if not nzu.IsExtensionLoaded(self.Extension) then
		if b then
			nzu.RequestLoadExtension(self.Extension)
		end
	else
		if b then
			tounload[self.Extension] = nil
		else
			tounload[self.Extension] = true
		end
		
		local num = table.Count(tounload)
		self.SaveButton:SetText(num > 0 and "Save and Unload Extensions ("..num..")" or "Save to Settings file")
	end
end

local function generateextensionpanel(ext, save)
	local f = vgui.Create("DCollapsibleCategory")
	local details = nzu.GetExtensionDetails(ext)

	f:SetLabel((details and details.Name or "[Unknown Name]") .. " ["..ext.."]")

	local checkbox = f.Header:Add("DCheckBoxLabel")
	checkbox:Dock(RIGHT)
	checkbox:SetWide(20)
	checkbox:SetChecked(nzu.IsExtensionLoaded(ext))
	checkbox:SetDisabled(not nzu.IsAdmin(LocalPlayer()))
	f.LoadedCheckbox = checkbox

	if nzu.IsExtensionLoaded(ext) then
		createextensionsettingspanel(ext, f)
	else
		local p = vgui.Create("DPanel", f)
		local lbl = vgui.Create("DLabel", p)
		lbl:SetText("Extension not loaded.")
		lbl:SetTextColor(Color(255,0,0))
		lbl:SetContentAlignment(5)
		lbl:Dock(FILL)
		p:SetTall(30)
		f:SetContents(p)
	end
	
	checkbox.Extension = ext
	checkbox.SaveButton = save
	checkbox.OnChange = checkboxchange

	return f
end

local columns = 3
local pad = 3
nzu.AddSpawnmenuTab("Extension Settings", "DPanel", function(panel)
	panel.ExtensionPanels = {}

	local top = panel:Add("DPanel")
	top:SetTall(60)
	top:Dock(TOP)
	top:DockPadding(5,5,5,5)

	local save = top:Add("DButton")
	save:SetText("Save to Settings file")
	save:Dock(RIGHT)
	save:SetWide(300)
	save.DoClick = function(s)
		if table.Count(tounload) > 0 then
			local txt = "Do you wish to Save and reload the map? The following Extensions will be unloaded: "
			for k,v in pairs(tounload) do
				txt = txt .. "\n- "..k
			end
			Derma_Query(txt, "Config load confirmation",
				"Reload the map and Unload Extensions", function()
					nzu.RequestUnloadExtensions(table.GetKeys(tounload))
				end,
				"Cancel"
			):SetSkin("nZombies Unlimited")
		else
			nzu.RequestSaveConfigSettings(nzu.CurrentConfig)
		end
	end

	local curconfig = top:Add("nzu_ConfigPanel")
	curconfig:Dock(LEFT)
	curconfig:SetWide(400)

	local fill = panel:Add("Panel")
	fill:Dock(FILL)

	local block = panel:Add("DPanel")
	block:SetBackgroundColor(Color(50,0,0,200))
	block:SetZPos(1)
	block:Dock(FILL)

	if nzu.CurrentConfig then
		curconfig:SetConfig(nzu.CurrentConfig)
		block:SetVisible(false)
	else
		curconfig:SetVisible(false)
	end
	save:SetDisabled(not nzu.CurrentConfig or nzu.CurrentConfig.Type ~= "Local")

	local alert = block:Add("DLabel")
	alert:SetFont("Trebuchet24")
	alert:SetText("Load a Local Config to change its Settings.")
	alert:Dock(FILL)
	alert:SetContentAlignment(5)
	alert:SetTextColor(Color(255,0,0))
	hook.Add("nzu_ConfigLoaded", curconfig, function(s,config)
		if config then
			print("We're here")
			curconfig:SetConfig(config)
			curconfig:SetVisible(true)
		else
			curconfig:SetVisible(false)
		end
		local cantedit = not config or config.Type ~= "Local"
		block:SetVisible(cantedit)
		save:SetDisabled(cantedit)
	end)

	panel.Lists = {}
	for i = 1,columns do
		local p = fill:Add("DScrollPanel")
		p:Dock(LEFT)
		p:DockMargin(pad,2,0,2)

		panel.Lists[i] = p
	end

	function panel:PerformLayout()
		local w = (self:GetWide() - pad)/columns - pad
		for i = 1,columns do
			panel.Lists[i]:SetWide(w)
		end
	end

	local loadedexts = 1
	for k,v in pairs(nzu.GetExtensionList()) do
		local f = generateextensionpanel(v, save)
		panel.Lists[loadedexts]:Add(f)
		f:Dock(TOP)
		f:SetHeight(50)

		loadedexts = loadedexts < columns and loadedexts + 1 or 1
		panel.ExtensionPanels[v] = f
	end

	hook.Add("nzu_ExtensionLoaded", panel, function(s, ext)
		local pnl = s.ExtensionPanels[ext]
		if pnl then
			pnl.LoadedCheckbox:SetChecked(true)
			createextensionsettingspanel(ext, pnl)
		end
	end)
end, "icon16/plugin.png", "Control Config Settings and Extensions")

