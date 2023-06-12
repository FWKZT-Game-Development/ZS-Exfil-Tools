TOOL.Category = "ZS - FWKZT"
TOOL.Name = "#tool.exfil.name"

if ( CLIENT ) then
	language.Add( "tool.exfil.name", "Exfil Tool" )
	language.Add( "tool.exfil.desc", "Exfil area creation tool" )

	language.Add( "tool.exfil.left", "Start new exfil area" )
	language.Add( "tool.exfil.left_1_1", "Choose area size" )
	language.Add( "tool.exfil.left_1_2", "Choose area height" )

	language.Add( "tool.exfil.left_2_1", "Edit selected area" )

	language.Add( "tool.exfil.right", "Select existing area" )
	language.Add( "tool.exfil.right_1_1", "Step back" )

	language.Add( "tool.exfil.right_2_1", "Reselect/Cancel selection" )

	language.Add( "tool.exfil.reload", "Set position" )

	language.Add( "tool.exfil.delete", "Delete Selection" )

	language.Add( "tool.exfil.name", "Exfil Name" )

	
	language.Add( "tool.exfil.slaydelay", "Zombie slay delay" )
	language.Add( "tool.exfil.slaydelay.help", "How long to wait until slaying zombies" )
	
	language.Add( "tool.exfil.time", "Time to escape" )
	language.Add( "tool.exfil.time.help", "Aamount of time to escape once in area" )
	
	language.Add( "tool.exfil.deadline", "Exfil deadline" )
	language.Add( "tool.exfil.deadline.help", "Allowed time to get to exfil and escape" )
	
	language.Add( "tool.exfil.usehatch", "Use escape hatch?" )
	
	language.Add( "tool.exfil.override", "Override?" )
	language.Add( "tool.exfil.override.help", "Leave as default." )
	
	language.Add( "tool.exfil.apply", "Apply To Selection" )

	language.Add( "tool.exfil.save", "Save File" )
end

TOOL.ClientConVar["editmode"] = "0"
TOOL.ClientConVar["cx"] = "0"
TOOL.ClientConVar["cy"] = "0"
TOOL.ClientConVar["cz"] = "0"
TOOL.ClientConVar["px"] = "0"
TOOL.ClientConVar["py"] = "0"
TOOL.ClientConVar["pz"] = "0"
TOOL.ClientConVar["menu"] = "0"
TOOL.ClientConVar["slaydelay"] = "0"
TOOL.ClientConVar["time"] = "0"
TOOL.ClientConVar["deadline"] = "0"
TOOL.ClientConVar["usehatch"] = "0"
TOOL.ClientConVar["override"] = "0"

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "left_2_1", stage = 2 },
	{ name = "left_1_1", stage = 1, op = 1 },
	{ name = "left_1_2", stage = 1, op = 2 },
	{ name = "right", stage = 0 },
	{ name = "right_1_1", stage = 1 },
	{ name = "right_2_1", stage = 2 },
	{ name = "reload", stage = 1 },
	{ name = "reload", stage = 2 },
}

function TOOL:Deploy()
	if CLIENT then return end
	local owner = self:GetOwner()
	owner:ConCommand("exfil_editmode 0")
	self:SetOperation(1)
	self:SetStage(0)
	owner:ConCommand("exfil_select \"\"")
	if self.ExfilCreated then
		owner:ConCommand("exfil_delete")
	end
end

function TOOL:Holster()
	if CLIENT then return end
	local owner = self:GetOwner()
	owner:ConCommand("exfil_editmode 0")
	self:SetOperation(1)
	self:SetStage(0)
	owner:ConCommand("exfil_select \"\"")
	if self.ExfilCreated then
		owner:ConCommand("exfil_delete")
	end
end

function TOOL:LeftClick( trace )
	if CLIENT then return end

	local owner = self:GetOwner()
	
	if owner:GetInfo("exfil_select") == "" then
		self:SetStage(0)
	end

	if self:GetStage() == 1 then
		if self:GetOperation() == 1 then
			owner:ConCommand("exfil_cx " .. trace.HitPos.x - self:GetClientNumber("px", 0))
			owner:ConCommand("exfil_cy " .. trace.HitPos.y - self:GetClientNumber("py", 0))
			
			owner:ConCommand("exfil_editmode 2")

			self:SetOperation(2)

			return true
		elseif self:GetOperation() == 2 then
			local cz = trace.HitPos.z - self:GetClientNumber("pz", 0)
			owner:ConCommand("exfil_cz " .. cz)
			
			owner:ConCommand("exfil_size " .. owner:GetInfo("exfil_select") .. " " .. self:GetClientNumber("cx", 25) .. " " .. self:GetClientNumber("cy", 25) .. " " .. cz)

			owner:ConCommand("exfil_editmode 0")
			
			owner:ConCommand("exfil_select \"\"")

			self.ExfilCreated = false

			self:SetStage(0)
			
			return true
		end
	end
	
	if self:GetStage() == 0 then
		self.ExfilCreated = true
		owner:ConCommand("exfil_create")
		owner:ConCommand("exfil_origin")
		
		owner:ConCommand("exfil_editmode 1")

		owner:ConCommand("exfil_px " .. trace.HitPos.x)
		owner:ConCommand("exfil_py " .. trace.HitPos.y)
		owner:ConCommand("exfil_pz " .. trace.HitPos.z)

		self:SetStage(1)
		self:SetOperation(1)
	end

	if self:GetStage() == 2 then
		owner:ConCommand("exfil_editmode 1")

		self:SetStage(1)
		self:SetOperation(1)
	end

	return true
end

function TOOL:RightClick( trace )
	if CLIENT then return end
	local owner = self:GetOwner()
	if owner:GetInfo("exfil_select") == "" then
		self:SetStage(0)
	end
	if self:GetStage() == 1 then
		local editMode = GetConVar("exfil_editmode"):GetInt()
		if editMode > 0 then
			owner:ConCommand("exfil_editmode " .. editMode - 1)
	
			if self:GetOperation() == 2 then
				self:SetOperation(1)
			elseif self:GetOperation() == 1 then
				self:SetStage(0)
	
				if self.ExfilCreated then
					owner:ConCommand("exfil_delete")
				end
			end
		end
		return
	end

	owner:ConCommand("exfil_select_closest")
	self:SetStage(2)

	timer.Simple(0, function()
		if owner:GetInfo("exfil_select") == "" then
			self:SetStage(0)
		end
	end)
end

function TOOL:Reload( trace )
	if CLIENT then return end
	local owner = self:GetOwner()
	if owner:GetInfo("exfil_select") == "" then
		self:SetStage(0)
	end
	if self:GetStage() >= 1 then
		local owner = self:GetOwner()
		owner:ConCommand("exfil_pos " .. owner:GetInfo("exfil_select") .. " " .. trace.HitPos.x .. " " .. trace.HitPos.y .. " " .. trace.HitPos.z)
		owner:ConCommand("exfil_px " .. trace.HitPos.x)
		owner:ConCommand("exfil_py " .. trace.HitPos.y)
		owner:ConCommand("exfil_pz " .. trace.HitPos.z)
	end
end

-- This function/hook is called every frame on client and every tick on the server
function TOOL:Think()
	if CLIENT then return end
end

local function ReconstructListView(listView)
	listView:Clear()

	for _, entry in ipairs(ExfilStorage[game.GetMap()]) do
		local name = table.GetKeys(entry)[1]
		local line = listView:AddLine(name)
		line.data = { exfil_select = name, exfil_menu = "1" }

		if GetConVar("exfil_select"):GetString() == name then line:SetSelected(true) end
	end
end

function TOOL.BuildCPanel( CPanel )
	LocalPlayer():ConCommand("exfil_show 1")

	local exfilMenu

	local namePanel = vgui.Create("DTextEntry", CPanel)
	namePanel:SetPlaceholderText(GetConVar("exfil_select"):GetString())
	namePanel.OnEnter = function(self)
		local old = GetConVar("exfil_select"):GetString()
		local new = self:GetValue()
		self:SetText("")
		if old == new then return end

		for i, data in ipairs( ExfilStorage[ game.GetMap() ] ) do
			for area, stored in pairs( data ) do
				if area == new then
					return
				end
				if area == old then
					ExfilStorage[ game.GetMap() ][ i ][ old ] = nil
					ExfilStorage[ game.GetMap() ][ i ][ new ] = stored
				end
				self:SetPlaceholderText(new)
			end
		end

		ReconstructListView(exfilMenu)
	end

	local delete = CPanel:AddControl("Button", { Label = "#tool.exfil.delete" })
	delete.DoClick = function(self)
		LocalPlayer():ConCommand("exfil_delete")
		exfilMenu:RemoveLine(exfilMenu:GetSelectedLine())
	end

	exfilMenu = CPanel:AddControl("ListBox", { Label = "#tool.exfil.name", Height = 17 * 25 })
	exfilMenu:SetMultiSelect(false)
	ReconstructListView(exfilMenu)

	CPanel:AddPanel(namePanel)

	CPanel:AddControl("Slider", { Label = "#tool.exfil.slaydelay", Type = "Int", Min = 0, Max = 60, Help = true, Command = "exfil_slaydelay" })
	CPanel:AddControl("Slider", { Label = "#tool.exfil.time", Type = "Int", Min = 0, Max = 60, Help = true, Command = "exfil_time" })
	CPanel:AddControl("Slider", { Label = "#tool.exfil.deadline", Type = "Int", Min = 0, Max = 300, Help = true, Command = "exfil_deadline" })
	CPanel:AddControl("CheckBox", { Label = "#tool.exfil.usehatch", Help = false, Command = "exfil_usehatch" })
	CPanel:AddControl("CheckBox", { Label = "#tool.exfil.override", Help = true, Command = "exfil_override" })
	
	CPanel:AddControl("Button", { Label = "#tool.exfil.apply", Command = "exfil_apply" })
	CPanel:AddControl("Button", { Label = "#tool.exfil.save", Command = "exfil_save" })

	cvars.AddChangeCallback("exfil_select", function(convar, oldValue, newValue)
		if newValue ~= "" then
			namePanel:SetPlaceholderText(newValue)
			ReconstructListView(exfilMenu)
		end
	end)
end

hook.Add("PostDrawTranslucentRenderables", "ExfilToolgunDraw", function(_, bDrawingSkybox)
	if GetConVar("exfil_show") and not GetConVar("exfil_show"):GetBool() then return end
	if bDrawingSkybox then return end
	if ExfilStorage and ExfilStorage[ game.GetMap() ] then
		for area, data in pairs( ExfilStorage[ game.GetMap() ] ) do
			for area, stored in pairs( data ) do
				
				if GetConVar("exfil_select"):GetString() == area then
					local editMode = GetConVar("exfil_editmode"):GetInt()
					if editMode == 0 then
						local oc = Color( 255, 157, 0 )
					
						if GetConVar("exfil_menu"):GetBool() then
							oc = Color(0, 179, 255)
						end

						local r = oc.r
						local g = oc.g
						local b = oc.b
						
						render.SetColorMaterial()
						render.DrawBox( stored.Pos, Angle(0,0,0), Vector(0,0,0), stored.BoxSize or Vector(25,25,25), Color( r, g, b, math.floor( math.sin( CurTime() * 8 ) * 5 ) + 10 ) )
						render.DrawWireframeBox( stored.Pos, Angle(0,0,0), Vector(0,0,0), stored.BoxSize or Vector(25,25,25), Color( r, g, b ), false )

						local pos, distance, ang, alpha
						local eyepos = EyePos()
						combined_vec = stored.BoxSize
						local vx,vy,vz = combined_vec.x, combined_vec.y, combined_vec.z
				
						vx = vx/2
						vy = vy/2
						vz = 64
				
						pos = stored.Pos+Vector( vx, vy, vz )
				
						distance = eyepos:DistToSqr(pos)
	
						alpha = math.min(255, math.sqrt(distance / 5))
						ang = (eyepos - pos):Angle()
						ang:RotateAroundAxis(ang:Right(), 270)
						ang:RotateAroundAxis(ang:Up(), 90)
				
						cam.IgnoreZ(true)
						cam.Start3D2D(pos, ang, math.max(1200, math.sqrt(distance)) / 5000)
						local oldfogmode = render.GetFogMode()
						render.FogMode(0)
				
						surface.SetFont( "Trebuchet24" )
						surface.SetTextColor( 255, 255, 255, alpha )
						surface.SetTextPos( 0, 0 ) 
						surface.DrawText( area )
				
						render.FogMode(oldfogmode)
						cam.End3D2D()
						cam.IgnoreZ(false)
					elseif editMode == 1 then
						local eyeTrace = LocalPlayer():GetEyeTrace()
						local x, y = eyeTrace.HitPos.x - stored.Pos.x, eyeTrace.HitPos.y - stored.Pos.y

						render.SetColorMaterial()
						render.DrawWireframeBox( stored.Pos, Angle(0,0,0), Vector(0,0,0), Vector(x, y, 0), Color( 161, 255, 156 ), false )
						render.DrawLine(Vector(eyeTrace.HitPos.x, eyeTrace.HitPos.y, stored.Pos.z), eyeTrace.HitPos, Color(161, 255, 156), false)
					elseif editMode == 2 then
						local eyeTrace = LocalPlayer():GetEyeTrace()
						local cx = GetConVar("exfil_cx"):GetFloat()
						local cy = GetConVar("exfil_cy"):GetFloat()

						render.SetColorMaterial()
						render.DrawBox( stored.Pos, Angle(0,0,0), Vector(0,0,0), Vector(cx, cy, 0), Color( 161, 255, 156, math.floor( math.sin( CurTime() * 8 ) * 5 ) + 10 ) )
						
						render.DrawWireframeBox( stored.Pos, Angle(0,0,0), Vector(0,0,0), Vector(cx, cy, eyeTrace.HitPos.z - stored.Pos.z), Color( 161, 255, 156 ), false )
					end
				end
			end
		end
	end
end)
