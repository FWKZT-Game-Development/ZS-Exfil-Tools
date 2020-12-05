local start_pos = vector_origin
local end_pos
local storage = {}

hook.Add( "InitPostEntity", "Exfil.CreateToolTable", function()
    if GAMEMODE_NAME == "sandbox" then
        storage[ game.GetMap() ] = {}
    end
end )

local function ExfilDataHasArea(stage)
    for _, data in ipairs( storage[ game.GetMap() ] ) do
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
            ExfilTime = EXFIL_TIME or 5,
            ExfilDeadline = 120 --GAMEMODE.TimeToExfil
        } 
    }
    table.insert( storage[game.GetMap()], data )
end

--example : exfil_create testarea
concommand.Add("exfil_create", function( ply, cmd, args )
    if not ExfilDataHasArea(args[1]) then
        CreateMapData( args[1] )
    else
        ply:ChatPrint("[EXFIL] error : Map data has already been created!")
    end
    PrintTable(storage)
end)

--example : exfil_origin testarea
concommand.Add("exfil_origin", function( ply, cmd, args )
    start_pos = ply:GetEyeTrace().HitPos

    for _, data in ipairs( storage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == args[1] then
                stored.Pos = start_pos
            end
        end
    end

    PrintTable(storage)
end)
--example : exfil_size testarea 200 200 200
concommand.Add("exfil_size", function( ply, cmd, args )
    end_pos = Vector( args[2], args[3], args[4] )
    for _, data in ipairs( storage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == args[1] then
                stored.BoxSize = end_pos
            end
        end
    end

    PrintTable(storage)
end)
--example : exfil_config testarea 0 3 5 120
concommand.Add("exfil_config", function( ply, cmd, args )
    for _, data in ipairs( storage[ game.GetMap() ] ) do
        for area, stored in pairs( data ) do
            if area == args[1] then
                stored.OverrideExfilBool = args[2]
                stored.ZombieSlayDelay = args[3]
                stored.ExfilTime = args[4]
                stored.ExfilDeadline = args[5]
            end
        end
    end

    PrintTable(storage)
end)
--example : exfil_save
concommand.Add("exfil_save", function( ply, cmd, args )
    local tab = util.TableToJSON( storage )
    file.CreateDir( "exfil" )
    file.Write( "exfil/"..game.GetMap()..".json", tab)

    ply:ChatPrint("[EXFIL] Map data has now been saved.")
end)

hook.Add( "PostDrawTranslucentRenderables", "ZS.ExfilTool", function( bDepth, bSkybox )
    if ( bSkybox ) then return end
    if storage[ game.GetMap() ] then
        for area, data in pairs( storage[ game.GetMap() ] ) do
            for area, stored in pairs( data ) do
                if stored.Pos ~= nil then
                    render.SetColorMaterial()
                    render.DrawBox( stored.Pos, Angle(0,0,0), Vector(0,0,0), stored.BoxSize or Vector(25,25,25), Color( 161, 255, 156, math.floor( math.sin( CurTime() * 8 ) * 5 ) + 10 ) )
                    render.DrawWireframeBox( stored.Pos, Angle(0,0,0), Vector(0,0,0), stored.BoxSize or Vector(25,25,25), Color( 161, 255, 156 ), true )
                end
            end
        end
    end
end )