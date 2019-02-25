if SERVER then
	AddCSLuaFile()
	resource.AddFile("vgui/ttt/exho_martyrdom.png")
	resource.AddFile("sound/martyrdom/grenade_bounce.mp3")
	util.AddNetworkString("shouldmartyr")
	local d_shouldmartyr = {}
	local t_shouldmartyr = {}
	
	hook.Add("Tick","send_shouldmartyr",function()
		for k, v in pairs(player.GetAll()) do
			if v:Alive() then
				if v:GetRole() == ROLE_DETECTIVE then
					net.Start("shouldmartyr")
					net.WriteTable(d_shouldmartyr)
					net.Send(v)
				elseif v:GetRole() == ROLE_TRAITOR then
					net.Start("shouldmartyr")
					net.WriteTable(t_shouldmartyr)
					net.Send(v)
				end
			end
		end
	end)

	hook.Add("TTTOrderedEquipment", "PraiseTheNade", function(ply)
		--print( ply:HasEquipmentItem(EQUIP_MARTYR)) -- HasEquipmentItem does not work in the Death hook, this works nicely
		if ply:HasEquipmentItem(EQUIP_MARTYR) then
			if ply:GetRole() == ROLE_DETECTIVE then
				table.insert(d_shouldmartyr, ply)
			elseif ply:GetRole() == ROLE_TRAITOR then
				table.insert(t_shouldmartyr, ply)
			end
		end
	end)
	
	local function GrenadeHandler(ply, infl, att)
		if table.HasValue(d_shouldmartyr, ply) or table.HasValue(t_shouldmartyr, ply) then
			local proj = "ttt_martyr_proj" -- Create our grenade
			local martyr = ents.Create(proj)
			martyr:SetPos(ply:GetPos())
			martyr:SetAngles(ply:GetAngles())
			martyr:Spawn()
			martyr:SetThrower(ply) -- Someone has to be accountible for this tragedy!
			martyr:EmitSound( "martyrdom/grenade_bounce.mp3" )
		
			local spos = ply:GetPos()
			local tr = util.TraceLine({start=spos, endpos=spos + Vector(0,0,-32), mask=MASK_SHOT_HULL, filter=ply})
		
			timer.Simple(3, function()
				martyr:Explode(tr)
				table.RemoveByValue(d_shouldmartyr, ply) -- No need to explode again,
				table.RemoveByValue(t_shouldmartyr, ply) -- you have fufilled your purpose
			end)
		end
	end
	
	local function Resettin()	
		table.Empty(d_shouldmartyr)
		table.Empty(t_shouldmartyr)
	end
	hook.Add("TTTPrepareRound", "hoobalooba", Resettin)
	hook.Add("PlayerDeath", "hoobalooba", GrenadeHandler)

else

	local c_shouldmartyr = {}
	net.Receive("shouldmartyr", function()
		table.Empty(c_shouldmartyr)
		c_shouldmartyr = net.ReadTable()
	end)

	hook.Add("PostPlayerDraw", "Draw_shouldmartyr", function(ply)
		if not LocalPlayer():Alive() then return end
		if LocalPlayer():GetRole() == ROLE_INNOCENT then return end
		if not table.HasValue(c_shouldmartyr, ply) then return end
		if ply == LocalPlayer() and GetViewEntity() == LocalPlayer()
			and (GetConVar('thirdperson') and GetConVar('thirdperson'):GetInt() != 0) then return end
		if not ply:Alive() then return end
		
		local pos = ply:GetPos() + Vector(0, 0, ply:GetModelRadius() + 20)

		local attachment = ply:GetAttachment(ply:LookupAttachment('eyes'))
		if attachment then
			pos = ply:GetAttachment(ply:LookupAttachment('eyes')).Pos + Vector(0, 0, 20)
		end
		
		local color_var = 255
		render.SetMaterial(Material('vgui/ttt/exho_martyrdom.png'))
		render.DrawSprite(pos, 12, 12, Color(color_var, color_var, color_var, 255))
	end)
	
	local function Resettin()	
		table.Empty(c_shouldmartyr)
	end
	hook.Add("TTTPrepareRound", "hoobalooba", Resettin)

end

hook.Add("InitPostEntity", "FindAMartyr", function()
	-- Just an absoulute fallback in case a server doesn't run that version
	EQUIP_MARTYR = ( GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 1024

	local MartyrDumb = {
		id = EQUIP_MARTYR,
		loadout = false,
		type = "item_passive",
		material = "vgui/ttt/exho_martyrdom.png",
		name = "Martyrdom",
		desc = "Drops a live grenade upon your death!\n"
	}
	table.insert( EquipmentItems[ROLE_TRAITOR], MartyrDumb )
	table.insert( EquipmentItems[ROLE_DETECTIVE], MartyrDumb )
end)
