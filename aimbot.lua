--[[

    Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
    https://github.com/Exunys

]]

--// Cache

local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick, select = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick, select
local Vector2new, Vector3new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing.new, TweenInfo.new
local getupvalue, mousemoverel, tablefind, tableremove, stringlower, stringsub, mathclamp = debug.getupvalue, mousemoverel or (Input and Input.MouseMove), table.find, table.remove, string.lower, string.sub, math.clamp

-- Optimisation des services Roblox en stockant les références au début
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Gestion améliorée des métatables pour plus de compatibilité avec les exploiters
local GameMetatable = getrawmetatable(game) or {
    __index = function(self, Index) return self[Index] end,
    __newindex = function(self, Index, Value) self[Index] = Value end
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex

-- Variables
local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}
local Connect, Disconnect = game.DescendantAdded.Connect, game.DescendantAdded.Disconnect
local Degrade, GetRenderProperty, SetRenderProperty = false, nil, nil

-- Fonction pour détecter et configurer les propriétés de rendu
local function ConfigureDrawingProperties()
    local success, result = pcall(function()
        local TemporaryDrawing = Drawingnew("Line")
        GetRenderProperty = getupvalue(getmetatable(TemporaryDrawing).__index, 4)
        SetRenderProperty = getupvalue(getmetatable(TemporaryDrawing).__newindex, 4)
        TemporaryDrawing:Remove()
    end)
    
    if not success then
        Degrade = true
        GetRenderProperty = function(Object, Key) return Object[Key] end
        SetRenderProperty = function(Object, Key, Value) Object[Key] = Value end
    end
end

ConfigureDrawingProperties()

-- Vérification d'exécution multiple
if ExunysDeveloperAimbot and ExunysDeveloperAimbot.Exit then
    ExunysDeveloperAimbot:Exit()
end

-- Environnement global pour le module
getgenv().ExunysDeveloperAimbot = {
    DeveloperSettings = {
        UpdateMode = "RenderStepped",
        TeamCheckOption = "TeamColor",
        RainbowSpeed = 1
    },

    Settings = {
        Enabled = true,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        OffsetToMoveDirection = false,
        OffsetIncrement = 15,
        Sensitivity = 0,
        Sensitivity2 = 3.5,
        LockMode = 1,
        LockPart = "Head",
        TriggerKey = Enum.UserInputType.MouseButton2,
        Toggle = false
    },

    FOVSettings = {
        Enabled = true,
        Visible = true,
        Radius = 90,
        NumSides = 60,
        Thickness = 1,
        Transparency = 1,
        Filled = false,
        RainbowColor = false,
        RainbowOutlineColor = false,
        Color = Color3fromRGB(255, 255, 255),
        OutlineColor = Color3fromRGB(0, 0, 0),
        LockedColor = Color3fromRGB(255, 150, 150)
    },

    Blacklisted = {},
    FOVCircle = Drawingnew("Circle"),
    FOVCircleOutline = Drawingnew("Circle")
}

local Environment = getgenv().ExunysDeveloperAimbot

-- Fonction pour annuler le verrouillage de la cible
local function CancelLock()
    Environment.Locked = nil

    local FOVCircle = Degrade and Environment.FOVCircle or Environment.FOVCircle.__OBJECT
    SetRenderProperty(FOVCircle, "Color", Environment.FOVSettings.Color)
    __newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)

    if Animation then
        Animation:Cancel()
    end
end

-- Fonction pour obtenir le joueur le plus proche
local function GetClosestPlayer()
    local Settings = Environment.Settings
    local LockPart = Settings.LockPart

    if not Environment.Locked then
        RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000

        for _, Value in next, Players:GetPlayers() do
            local Character = Value.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

            if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, Value.Name) and Character and Character:FindFirstChild(LockPart) and Humanoid then
                local PartPosition, TeamCheckOption = Character[LockPart].Position, Environment.DeveloperSettings.TeamCheckOption

                if Settings.TeamCheck and Value[TeamCheckOption] == LocalPlayer[TeamCheckOption] then
                    continue
                end

                if Settings.AliveCheck and Humanoid.Health <= 0 then
                    continue
                end

                if Settings.WallCheck then
                    local BlacklistTable = LocalPlayer.Character:GetDescendants()

                    for _, Descendant in next, Character:GetDescendants() do
                        table.insert(BlacklistTable, Descendant)
                    end

                    if #Camera:GetPartsObscuringTarget({PartPosition}, BlacklistTable) > 0 then
                        continue
                    end
                end

                local Vector, OnScreen, Distance = Camera:WorldToViewportPoint(PartPosition)
                Vector = Vector2new(Vector.X, Vector.Y)
                Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude

                if Distance < RequiredDistance and OnScreen then
                    RequiredDistance, Environment.Locked = Distance, Value
                end
            end
        end
    elseif (UserInputService:GetMouseLocation() - Vector2new(Camera:WorldToViewportPoint(Environment.Locked.Character[LockPart].Position))).Magnitude > RequiredDistance then
        CancelLock()
    end
end

-- Fonction de chargement initiale
local function Load()
    OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")

    local Settings, FOVCircle, FOVCircleOutline, FOVSettings = Environment.Settings, Environment.FOVCircle, Environment.FOVCircleOutline, Environment.FOVSettings

    if not Degrade then
        FOVCircle, FOVCircleOutline = FOVCircle.__OBJECT, FOVCircleOutline.__OBJECT
    end

    SetRenderProperty(FOVCircle, "ZIndex", 2)
    SetRenderProperty(FOVCircleOutline, "ZIndex", 1)

    ServiceConnections.RenderSteppedConnection = Connect(RunService[Environment.DeveloperSettings.UpdateMode], function()
        if FOVSettings.Enabled and Settings.Enabled then
            for Index, Value in next, FOVSettings do
                if Index == "Color" then
                    continue
                end

                if pcall(GetRenderProperty, FOVCircle, Index) then
                    SetRenderProperty(FOVCircle, Index, Value)
                    SetRenderProperty(FOVCircleOutline, Index, Value)
                end
            end

            SetRenderProperty(FOVCircle, "Color", (Environment.Locked and FOVSettings.LockedColor) or FOVSettings.RainbowColor and GetRainbowColor() or FOVSettings.Color)
            SetRenderProperty(FOVCircleOutline, "Color", FOVSettings.RainbowOutlineColor and GetRainbowColor() or FOVSettings.OutlineColor)

            SetRenderProperty(FOVCircleOutline, "Thickness", FOVSettings.Thickness + 1)
            SetRenderProperty(FOVCircle, "Position", UserInputService:GetMouseLocation())
            SetRenderProperty(FOVCircleOutline, "Position", UserInputService:GetMouseLocation())
        else
            SetRenderProperty(FOVCircle, "Radius", 0)
            SetRenderProperty(FOVCircleOutline, "Radius", 0)
        end

        GetClosestPlayer()

        if Settings.Enabled and Environment.Locked then
            __newindex(UserInputService, "MouseDeltaSensitivity", Settings.Sensitivity)
            local CameraPosition, LockPart = Camera.CFrame.Position, Environment.Locked.Character[Settings.LockPart].Position

            local Direction = (LockPart - CameraPosition).Unit
            local TargetPosition = Camera:WorldToViewportPoint(CameraPosition + Direction)
            TargetPosition = Vector2new(TargetPosition.X, TargetPosition.Y)

            local MouseLocation = UserInputService:GetMouseLocation()
            local Smoothness = tableremove({Settings.Sensitivity2, 5})

            Animation = TweenService:Create(MouseLocation, TweenInfonew(Smoothness), {Position = TargetPosition}):Play()
            MouseLocation = Vector2new((TargetPosition.X - MouseLocation.X) / Smoothness, (TargetPosition.Y - MouseLocation.Y) / Smoothness)

            mousemoverel(MouseLocation.X, MouseLocation.Y)
        end
    end)
end

Load()
