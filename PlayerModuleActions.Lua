--	Player Control Module
--	Pinkerten
--	08/09/18
------------------------------------------------------------	CONSTANTS
local BASE_SENSITIVITY = 200
local BASE_WALKSPEED = 14
local sensitivity = BASE_SENSITIVITY

------------------------------------------------------------	SERVICES
local UIS = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

------------------------------------------------------------	PLAYER
local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera
local mouse = player:GetMouse()

------------------------------------------------------------	GUI
local playerGUI = player:WaitForChild("PlayerGui")
local GUIList = {}

for _, gui in pairs(GUIList)do
	
	gui.Parent = playerGUI
	
end
------------------------------------------------------------	CHARACTER
local character = nil
local humanoid = nil
local HRP = nil

local function updateCharacter(char)
	
	if char then
		
		character = char
		humanoid = char:WaitForChild("Humanoid")
		HRP = char:WaitForChild("HumanoidRootPart")
		
	end
	
end

updateCharacter(player.Character)
player.CharacterAdded:connect(updateCharacter)

------------------------------------------------------------	MODULE

local module = {}

----------------------------------------------------	Camera

module.Camera = {}
module.Camera.View = "Right"
module.Camera.Angles = Vector2.new(0, 0)
module.Camera.Zoom = {}
local cameraZooms = {}

module.Camera.Get = function()
	
	return camera
	
end

module.Camera.GetSensitivity = function()
	
	return sensitivity
	
end

module.Camera.Zoom.Create = function(name, FOV, t)
	
	local tweenInfo = TweenInfo.new(t, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
	local tween = tweenService:Create(camera, tweenInfo, {FieldOfView = FOV})
	cameraZooms[name] = tween
	
	return tween
	
end

module.Camera.Zoom.Play = function(name)
	
	cameraZooms[name]:Play()
	
end

----------------------------------------------------	Mouse

module.Mouse = {}

module.Mouse.Get = function()
	
	return mouse
	
end

----------------------------------------------------	Character

module.Character = {}

module.Character.Get = function()
	
	return character
	
end

module.Character.GetDefaultWalkspeed = function()
	
	return BASE_WALKSPEED
	
end

module.Character.GetHumanoidRootPart = function()
	
	return HRP
	
end
module.Character.GetHumanoid = function()
	while not humanoid do
		wait()
	end
	return humanoid
	
end

----------------------------------------------------	GUI

local crosshairs = nil
module.GUI = {}
module.GUI.Crosshairs = {}
crosshairTweens = {}

module.GUI.Crosshairs.Get = function()
	
	return crosshairs
	
end

module.GUI.Crosshairs.AddRescale = function(name, size, t)
	
	local tweenInfo = TweenInfo.new(t, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
	local tween = tweenService:Create(crosshairs.Frame, tweenInfo, {Size = size})
	crosshairTweens[name] = tween
	
	return tween
	
end

module.GUI.Crosshairs.PlayRescale = function(name)
	
	crosshairTweens[name]:Play()
	
end

module.GUI.AddCrosshairs = function(newcrosshairs)
	
	crosshairs = newcrosshairs
	
end

----------------------------------------------------	Animations
module.Animations = {}
local AnimationList = {}

module.Animations.Create = function(name, animation)
	
	AnimationList[name] = humanoid:LoadAnimation(animation)
	
end

module.Animations.Play = function(name, overRide)
	
	local animTrack = AnimationList[name]
	
	if not animTrack.IsPlaying or overRide then
		
		animTrack:Play()
		
	end
	
end

module.Animations.Cancel = function(name)
	
	AnimationList[name]:Stop()
	
end

module.Animations.Pause = function(name)
	
	AnimationList[name]:AdjustSpeed(0)
	
end

module.Animations.Unpause = function(name)
	
	AnimationList[name]:AdjustSpeed(1)
	
end

module.Animations.Reverse = function(name)
	
	AnimationList[name]:AdjustSpeed(-1)
	
end

----------------------------------------------------	Tweens
module.Tweens = {}
local TweensList = {}

module.Tweens.Create = function(name, object, tweeninfo, properties)
	
	local tween = tweenService:Create(object, tweeninfo, properties)
	TweensList[name] = tween
	
	return tween
	
end

module.Tweens.Play = function(name)
	
	TweensList[name]:Play()
	
end

----------------------------------------------------	Actions
module.Actions = {}
local ActionsList = {}

ActionsList["Moving"] 		= false
ActionsList["HoldingTool"] 	= false
ActionsList["Crouching"] 	= false
ActionsList["Sprinting"] 	= false
ActionsList["Jumping"] 		= false
ActionsList["Focusing"] 	= false

module.Actions.DoAction = {}

module.Actions.IsDoing = function(name)
	
	return ActionsList[name]
	
end

module.Actions.DoAction.Focus = function(activate)
	
	if activate then
		
		humanoid.AutoRotate = false
		ActionsList.Focusing = true
		humanoid.WalkSpeed = 10

		if ActionsList.Crouching then
			
			humanoid.WalkSpeed = 8
			
		end
		
		if ActionsList.Sprinting then
			
			ActionsList.DoAction.Sprint(false)
			
		end
		
		sensitivity = BASE_SENSITIVITY*2
		
		if crosshairs then
			
			module.GUI.Crosshairs.PlayRescale("Focusing")
			
		end
		
	else
		
		humanoid.AutoRotate = true
		ActionsList.Focusing = false
		humanoid.WalkSpeed = 14
		
		if ActionsList.Crouching then
			
			humanoid.WalkSpeed = 10
			
		end
		
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			
			ActionsList.DoAction.Sprint(true)
			
		end
		
		sensitivity = BASE_SENSITIVITY
		
		if crosshairs then
			
			module.GUI.Crosshairs.PlayRescale("Norm")
			
		end
		
	end
	
end

module.Actions.DoAction.Sprint = function(activate)
	
	if activate then
		
		if ActionsList.Focusing then
			
			ActionsList.DoAction.Focus(false)
			
		end
		
		if ActionsList.Crouching then
		
			ActionsList.DoAction.Crouch(false)
		
		end
		
		humanoid.WalkSpeed = BASE_WALKSPEED + 5
		
	else
		
		if not ActionsList.Crouching then
			
			humanoid.WalkSpeed = BASE_WALKSPEED
			
		end
		
		
	end

end

module.Actions.DoAction.Crouch = function(activate)
	
	if activate then
		
		ActionsList.Crouching = true
		
		humanoid.WalkSpeed = BASE_WALKSPEED - 4
		module.Tweens.Play("DownView")
		
		if ActionsList.Moving then
			
			module.Animations.Cancel("Run")
			module.Animations.Play("Crouch")
			
		else
			
			module.Animations.Cancel("Idle1")
			module.Animations.Play("IdleCrouch")
			
		end
		
		if ActionsList.HoldingTool then
			
			--module.Animations.Cancel("ToolHold")
			--module.Animations.Play("CrouchToolHold")
			
		end
		
	else
	
		ActionsList.Crouching = false
		
		humanoid.WalkSpeed = BASE_WALKSPEED
		module.Tweens.Play("UpView")
		
		if ActionsList.Moving then
			
			module.Animations.Cancel("Crouch")
			module.Animations.Play("Run")
		
		else
			
			module.Animations.Cancel("IdleCrouch")		
			module.Animations.Play("Idle1")
			
		end
		
		--module.Animations.Cancel("CrouchToolHold")
		
		if ActionsList.HoldingTool then
			
			--module.Animations.Play("ToolHold")
			
		end
		
	end
	
end

module.Actions.DoAction.StartMoving = function(activate)
	
	if activate then
		
		ActionsList.Moving = true
	
		if ActionsList.Crouching then
			
			module.Animations.Cancel("IdleCrouch")
			module.Animations.Play("Crouch")
			
		else
			
			module.Animations.Cancel("Idle1")
			module.Animations.Play("Run")
			
		end
	
	else
	
		ActionsList.Moving = false
		
		if ActionsList.Crouching then
			
			module.Animations.Cancel("Crouch")
			module.Animations.Play("IdleCrouch")
		
		else
			
			module.Animations.Cancel("Run")
			module.Animations.Play("Idle1")
			
		end
		
	end
	
end


return module
