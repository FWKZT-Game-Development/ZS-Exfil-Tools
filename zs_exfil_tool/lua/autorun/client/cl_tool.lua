local start_pos = vector_origin
local end_pos

ExfilStorage = ExfilStorage or {}
ExfilCount = ExfilCount or 0

local selected = CreateConVar("exfil_select", "", FCVAR_USERINFO)
local show = CreateConVar("exfil_show", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY)

hook.Add( "InitPostEntity", "Exfil.CreateToolTable", function()
    if GAMEMODE_NAME == "sandbox" or GAMEMODE_NAME == "zombiesurvival" then
        ExfilStorage[ game.GetMap() ] = {}

        --Load json data so we can let devs view positions.
        local files, dirs = file.Find( "exfil/*", "DATA" )
        for _, map in ipairs( files ) do
            if string.TrimRight(map,".json") == string.lower(game.GetMap()) then
                local f = file.Open( "exfil/"..string.lower(game.GetMap())..".json", "r", "DATA" )
                local stored_mapdata = util.JSONToTable( f:ReadLine() )

                for i, data in pairs( stored_mapdata ) do
                    for area, d in pairs( data ) do
                        table.insert( ExfilStorage[game.GetMap()], d )
                        ExfilCount = ExfilCount + 1
                    end
                end
            end
        end
    end
end )

local function ExfilDataHasArea(stage)
    for _, data in ipairs( ExfilStorage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == stage then
                return true
            end
        end
    end

    return false
end

local function CreateMapData(area)
    local data = {
        [ area ] = {
            Pos = Vector(0,0,0),
            BoxSize = Vector( 25, 25, 25 ),
            OverrideExfilBool = 0,
            ZombieSlayDelay = 1,
            ExfilTime = EXFIL_TIME,
            ExfilDeadline = 120, --GAMEMODE.TimeToExfil
            UseHatch = 0
        } 
    }
    table.insert( ExfilStorage[game.GetMap()], data )
end

local closest = nil

if CLIENT then
    hook.Add("Think", "ExfilToolgunGetClosest", function()
        if not show:GetBool() then return end
        local bestDist = math.huge
        if ExfilStorage[ game.GetMap() ] then
            for area, data in pairs( ExfilStorage[ game.GetMap() ] ) do
                for area, stored in pairs( data ) do
                    local calc = (stored.Pos + stored.BoxSize / 2):DistToSqr(LocalPlayer():GetPos())
                    if calc < bestDist then
                        bestDist = calc
                        closest = area
                    end
                end
            end
        end
    end)
end

cvars.AddChangeCallback("exfil_select", function(convar, oldValue, newValue)
    if newValue == "" then
        GetConVar("exfil_px"):SetFloat(0)
        GetConVar("exfil_py"):SetFloat(0)
        GetConVar("exfil_pz"):SetFloat(0)
        GetConVar("exfil_override"):SetInt(0)
        GetConVar("exfil_slaydelay"):SetFloat(1)
        GetConVar("exfil_time"):SetFloat(EXFIL_TIME or 7)
        GetConVar("exfil_deadline"):SetFloat(120)
        GetConVar("exfil_usehatch"):SetInt(0)
        return
    end
    if ExfilStorage[ game.GetMap() ] then
        for area, data in pairs( ExfilStorage[ game.GetMap() ] ) do
            for area, stored in pairs( data ) do
                if area == newValue then
                    GetConVar("exfil_px"):SetFloat(stored.Pos.x)
                    GetConVar("exfil_py"):SetFloat(stored.Pos.y)
                    GetConVar("exfil_pz"):SetFloat(stored.Pos.z)
                    GetConVar("exfil_override"):SetInt(stored.OverrideExfilBool or 0)
                    GetConVar("exfil_slaydelay"):SetFloat(stored.ZombieSlayDelay)
                    GetConVar("exfil_time"):SetFloat(stored.ExfilTime or EXFIL_TIME or 7)
                    GetConVar("exfil_deadline"):SetFloat(stored.ExfilDeadline)
                    GetConVar("exfil_usehatch"):SetInt(stored.UseHatch or 0)
                end
            end
        end
    end
end)

concommand.Add("exfil_apply", function(ply, cmd, args)
    for _, data in ipairs( ExfilStorage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == selected:GetString() then
                stored.OverrideExfilBool = GetConVar("exfil_override"):GetInt()
                stored.ZombieSlayDelay = GetConVar("exfil_slaydelay"):GetFloat()
                stored.ExfilTime = GetConVar("exfil_time"):GetFloat()
                stored.ExfilDeadline = GetConVar("exfil_deadline"):GetFloat()
                stored.UseHatch = GetConVar("exfil_usehatch"):GetInt()
            end
        end
    end
end)

concommand.Add("exfil_select_closest", function(ply, cmd, args)
    if closest then
        if selected:GetString() == closest and not GetConVar("exfil_menu"):GetBool() then
            selected:SetString("")
            return
        end
        GetConVar("exfil_menu"):SetBool(false)
        selected:SetString(closest)
    end
end)

--example : exfil_create testarea
concommand.Add("exfil_create", function( ply, cmd, args )
    args[1] = args[1] or "exfil" .. ExfilCount + 1
    if not ExfilDataHasArea(args[1]) then
        CreateMapData( args[1] )
        ExfilCount = ExfilCount + 1
    else
        ply:ChatPrint("[EXFIL] error : Map data has already been created!")
    end
    PrintTable(ExfilStorage)
    selected:SetString(args[1])
end)

--example : exfil_delete testarea
concommand.Add("exfil_delete", function( ply, cmd, args )
    args[1] = args[1] or selected:GetString()
    for _, data in ipairs( ExfilStorage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == args[1] then
                table.remove( ExfilStorage[ game.GetMap() ], _ )
                ExfilCount = ExfilCount - 1
                LocalPlayer():ConCommand("exfil_select \"\"")
            end
        end
    end
    PrintTable(ExfilStorage)
end)

--example : exfil_origin testarea
concommand.Add("exfil_origin", function( ply, cmd, args )
    args[1] = args[1] or selected:GetString()
    start_pos = ply:GetEyeTrace().HitPos

    for _, data in ipairs( ExfilStorage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == args[1] then
                stored.Pos = start_pos
            end
        end
    end

    --PrintTable(ExfilStorage)
end)

--example : exfil_pos testarea 10 10 10
concommand.Add("exfil_pos", function( ply, cmd, args )
    args[1] = args[1] or selected:GetString()
    for _, data in ipairs( ExfilStorage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == args[1] then
                stored.Pos = Vector( args[2], args[3], args[4] )
            end
        end
    end

    --PrintTable(ExfilStorage)
end)

--example : exfil_size testarea 200 200 200
concommand.Add("exfil_size", function( ply, cmd, args )
    args[1] = args[1] or selected:GetString()
    end_pos = Vector( args[2], args[3], args[4] )
    for _, data in ipairs( ExfilStorage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == args[1] then
                stored.BoxSize = end_pos
            end
        end
    end

    --PrintTable(ExfilStorage)
end)

--example : exfil_config testarea 0 3 5 120 0
concommand.Add("exfil_config", function( ply, cmd, args )
    args[1] = args[1] or selected:GetString()
    for _, data in ipairs( ExfilStorage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == args[1] then
                stored.OverrideExfilBool = args[2]
                stored.ZombieSlayDelay = args[3]
                stored.ExfilTime = args[4]
                stored.ExfilDeadline = args[5]
                stored.UseHatch = args[6]
            end
        end
    end

    PrintTable(ExfilStorage)
end)

--example : exfil_save
concommand.Add("exfil_save", function( ply, cmd, args )
    local tab = util.TableToJSON( ExfilStorage )
    file.CreateDir( "exfil" )
    file.Write( "exfil/" .. game.GetMap() .. ".json", tab)

    PrintTable(ExfilStorage)

    ply:ChatPrint("[EXFIL] Map data has now been saved.")
end)

concommand.Add("exfil_print", function(ply, cmd, args)
    PrintTable(ExfilStorage)
end)

hook.Add( "PostDrawTranslucentRenderables", "ZS.ExfilTool", function( bDepth, bSkybox )
    if not show:GetBool() then return end
    if ( bSkybox ) then return end
    if ExfilStorage[ game.GetMap() ] then
        for area, data in pairs( ExfilStorage[ game.GetMap() ] ) do
            for area, stored in pairs( data ) do
                if stored.Pos ~= nil and GetConVar("exfil_select"):GetString() ~= area then
                    local oc = Color(161, 255, 156)
                    
                    if area == closest then
                        oc = Color(255, 255, 0)
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
                end
            end
        end
    end
end )
