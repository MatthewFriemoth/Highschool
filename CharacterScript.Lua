--2017 Matthew Friemoth
--==========================================================================================================================Services
local UIS = game:GetService("UserInputService")
local ACTION_SERVICE = game:GetService("ContextActionService")
local TWEEN_SERVICE = game:GetService("TweenService")
local GAME_ASSETS = game.ReplicatedStorage:WaitForChild("Assets")
local GAME_SETTINGS = require(game.ReplicatedStorage:WaitForChild("Settings"))
local WEAPON_STATS = require(game.ReplicatedStorage:WaitForChild("WeaponStats"))

--==========================================================================================================================Player
local PLAYER = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local MOUSE = PLAYER:GetMouse()

----------------------------------------------------------GUI
local MAIN_GUI = script:WaitForChild("GUIS")
local TOOL_GUI = MAIN_GUI:WaitForChild("ToolGui")
	local CURSOR_GUI = TOOL_GUI:WaitForChild("Cursor")
	
----------------------------------------------------------Character
local Character = nil
local Humanoid = nil

-----------------------Animations
local charRig = nil
local clientAnimations = {}
local serverAnimations = {}
local currentServerAnimation = ""
local currentClientAnimation = ""
local stance = "Stand"
local action = "Rest"

-----------------------Input
local is_clicking = false
-----------------------Tool
local Tool = nil

--==========================================================================================================================SETUP
--game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

for _,v in pairs(script.GUIS:GetChildren())do
	v.Parent = PLAYER:WaitForChild("PlayerGui")
end

--==========================================================================================================================ENVIROMENT
local function PlaySound(sound,part)
	if part then
		sound = GAME_ASSETS.Sounds:FindFirstChild(sound):Clone()
		sound.Parent = part
		sound:Play()
		spawn(function()
			wait(sound.TimeLength)
			sound:Destroy()
		end)
	end
end
local function BroadcastSound(...)
	game.ReplicatedStorage.PlaySound:FireServer(...)
	PlaySound(...)
end
game.ReplicatedStorage.PlaySound.OnClientEvent:connect(PlaySound)
--==========================================================================================================================ANIMATIONS
local function LoadServerAnimation(AnimationSource)
	local AnimationPack = {}
	for i,AnimationTrack in pairs(AnimationSource:GetChildren())do
		AnimationPack[AnimationTrack.Name] = Humanoid:LoadAnimation(AnimationTrack)
	end
	serverAnimations[AnimationSource.Name] = AnimationPack
end
local function LoadClientAnimation(AnimationSource)
	print(AnimationSource.Name)
	local AnimationPack = {}
	for i,CFrameValue in pairs(AnimationSource:GetChildren())do
		AnimationPack[CFrameValue.Name] = TWEEN_SERVICE:Create(CharRig[CFrameValue.Name],TweenInfo.new(.25),{["Value"] = CFrameValue.Value})
	end
	clientAnimations[AnimationSource.Name] = AnimationPack
end
local function StopClientAnimations()
	currentClientAnimation = ""
end
local function StopServerAnimations()
	if currentServerAnimation then
		for _,AnimPack in pairs(serverAnimations)do
			for _,Anim in pairs(AnimPack)do
				Anim:Stop()
			end
		end
	end
end
local function StopAllAnimations()
	StopClientAnimations()
	StopServerAnimations()
end
local function PlayServerAnimation(Anim)
	StopServerAnimations()
	currentServerAnimation = Anim
	serverAnimations[Anim]["Transition"]:Play()
end
local function PlayClientAnimation(Anim)
	currentClientAnimation = Anim
	for _,tween in pairs(clientAnimations[Anim])do
		tween:Play()
	end
end
local function LoadDefaultAnimations()
	for _,v in pairs(GAME_ASSETS.DefaultAnimations.Client:GetChildren())do
		LoadClientAnimation(v)
	end
	for _,v in pairs(GAME_ASSETS.DefaultAnimations.Server:GetChildren())do
		LoadServerAnimation(v)
	end
end
--local function Walking()
--	local anim = Animations[currentAnimation]
--	if anim then
--		anim.Movement:Play()
--	end
--end
--local function StoppedWalking()
--	local anim = Animations[currentAnimation]
--	if anim then
--		anim.Idle:Play()
--	end
--end
local function SyncCharacter() 
	if stance == "Stand" then
		Humanoid.HipHeight = 1.350
		if action == "Rest" then
			Humanoid.WalkSpeed = GAME_SETTINGS["Default Speed"]
			Humanoid.JumpPower = GAME_SETTINGS["Default Jump"]
			StopAllAnimations()
		elseif action == "Hold" then
			Humanoid.WalkSpeed = GAME_SETTINGS["Default Speed"]
			Humanoid.JumpPower = GAME_SETTINGS["Default Jump"]
			PlayServerAnimation("StandHold")
			PlayClientAnimation("Hold")
		elseif action == "Focus" then
			Humanoid.WalkSpeed = GAME_SETTINGS["Focus Speed"]
			Humanoid.JumpPower = GAME_SETTINGS["Default Jump"]
			PlayServerAnimation("StandHold")
			PlayClientAnimation("Focus")
		end
	elseif stance == "Crouch" then
		Humanoid.HipHeight = .6
		if action == "Rest" then
			Humanoid.WalkSpeed = GAME_SETTINGS["Crouch Speed"]
			Humanoid.JumpPower = GAME_SETTINGS["Crouch Jump"]
			PlayServerAnimation("CrouchRest")
			PlayClientAnimation("Rest")
		elseif action == "Hold" then
			Humanoid.WalkSpeed = GAME_SETTINGS["Crouch Speed"]
			Humanoid.JumpPower = GAME_SETTINGS["Crouch Jump"]
			PlayServerAnimation("CrouchHold")
			PlayClientAnimation("Hold")
		elseif action == "Focus" then
			Humanoid.WalkSpeed = GAME_SETTINGS["Crouch Focus Speed"]
			Humanoid.JumpPower = GAME_SETTINGS["Crouch Focus Jump"]
			PlayServerAnimation("CrouchHold")
			PlayClientAnimation("Focus")
		end
	elseif stance == "Prone" then
		Humanoid.HipHeight = .1
		if action == "Rest" then
			Humanoid.WalkSpeed = GAME_SETTINGS["Prone Speed"]
			Humanoid.JumpPower = GAME_SETTINGS["Prone Jump"]
			PlayServerAnimation("ProneRest")
			PlayClientAnimation("ProneRest")
		elseif action == "Hold" then
			Humanoid.WalkSpeed = GAME_SETTINGS["Prone Speed"]
			Humanoid.JumpPower = GAME_SETTINGS["Prone Jump"]
			PlayServerAnimation("ProneHold")
			PlayClientAnimation("Hold")
		elseif action == "Focus" then
			Humanoid.WalkSpeed = GAME_SETTINGS["Prone Focus Speed"]
			Humanoid.JumpPower = GAME_SETTINGS["Prone Focus Jump"]
			PlayServerAnimation("ProneHold")
			PlayClientAnimation("Focus")
		end
	elseif stance == "Sprint" then
		Humanoid.HipHeight = 1.350
		Humanoid.WalkSpeed = GAME_SETTINGS["Sprint Speed"]
		Humanoid.JumpPower = GAME_SETTINGS["Sprint Jump"]
		if Tool then
			PlayServerAnimation("SprintHold")
			PlayClientAnimation("Sprint")
		else
			StopAllAnimations()
		end
	end
	if action == "Reload" then
		PlayClientAnimation("Reload")
	end
end
--==========================================================================================================================WEAPON
local function ShootEffect(gun)
	gun = gun or Tool.Model
	PlaySound("GunFire",gun.Sight)
	gun.MuzzlePart.MuzzleFlash:Emit(1)
	gun.MuzzlePart.BulletEmmiter:Emit(1)
	gun.MuzzlePart.Smoke:Emit(1)
end
game.ReplicatedStorage.ShootEffect.OnClientEvent:connect(ShootEffect)
local function Kick()
	local ticks = 4
	local KickX = .04*Tool.Stats.Recoil
	local KickY = (math.random(0,10)-5)/500*Tool.Stats.Recoil
	local KickAngle = CFrame.Angles(KickX,KickY,0)
	CharRig.RightHand.Value = CharRig.RightHand.Value * KickAngle
	CharRig.LeftLowerArm.Value = CharRig.LeftLowerArm.Value * KickAngle
	for i = 1,ticks do
		wait()
		CharRig.RightHand.Value = CharRig.RightHand.Value * CFrame.Angles(-KickX/ticks,-KickY/ticks,0)
		CharRig.LeftLowerArm.Value = CharRig.LeftLowerArm.Value * CFrame.Angles(-KickX/ticks,-KickY/ticks,0)
	end
end
local function Projectile()
	local beamstart = Tool.MuzzlePart.Position
	local start = Tool.Sight.Position
	local dir = Tool.Sight.CFrame.lookVector*1000
	local hit,pos = workspace:FindPartOnRay(Ray.new(start,dir),Character)
	game.ReplicatedStorage.Shoot:FireServer(Tool.Model,hit,pos)
end
local function Shoot()
	if Tool and Tool.Mag.Value > 0 and not Tool.reloading and Tool.bulletready and stance ~= "Sprint" then
		Tool.Mag.Value = Tool.Mag.Value - 1
		Tool.bulletready = false
		Projectile()
		spawn(Kick)
		ShootEffect()
		print(Tool.Model)
		game.ReplicatedStorage.ShootEffect:FireServer(Tool.Model)
		wait(60/Tool.Stats.RPM)
		if Tool then
			Tool.bulletready = true
			if Tool.Stats.ActionType == "Auto" and is_clicking then
				Shoot()
			end
		end
	end
end
local function Reload()
	Tool.reloading = true
	action = "Reload"
	SyncCharacter()
	wait(.5)
	action = "Rest"
	if Tool then
		Tool.Mag.Value = Tool.Stats.MagCapacity
		Tool.reloading = false
		action = "Hold"
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			action = "Focus"
		end
	end
	SyncCharacter()
end
local function UnequipTool()
	if Tool then
		Tool = nil
		action = "Rest"
		StopAllAnimations()
		LoadDefaultAnimations()
	end
end
local function EquipTool(newTool)
	UnequipTool()
	if newTool then
		Tool = {}
		Tool.Model = newTool
		newTool.Parent = Character
		if newTool:FindFirstChild("Gun") then
			Tool.Assets = newTool.Assets
			Tool.Stats = WEAPON_STATS[newTool.Name]
			for _,v in pairs(newTool:GetChildren())do
				Tool[v.Name] = v
			end
			Tool.Mag = newTool.Assets.Mag
			Tool.Mag.Value = Tool.Stats.MagCapacity
			Tool.focusing = false
			Tool.clicking = false
			Tool.reloading = false
			Tool.bulletready = true
			local grip = Character.RightHand:WaitForChild("RightGrip")
			local FocusAnim = Tool.Assets["Focus"]
			FocusAnim.RightUpperArm.Value = (FocusAnim.RightLowerArm.Value * FocusAnim.RightHand.Value * grip.C0 * newTool.Handle.CFrame:toObjectSpace(newTool.Sight.CFrame)):inverse()
			LoadClientAnimation(FocusAnim)
		end
		action = "Hold"
		SyncCharacter()
	end
end
ACTION_SERVICE.LocalToolEquipped:connect(EquipTool)
ACTION_SERVICE.LocalToolUnequipped:connect(UnequipTool)
--==========================================================================================================================INPUT
UIS.InputBegan:connect(function(input,gamed)
	local Key = input.KeyCode
	if not gamed and Character then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			is_clicking = true
			if Tool then
				spawn(Shoot)
			end
		end
		if Key == Enum.KeyCode.R then
			Reload()
		elseif Key == Enum.KeyCode.LeftControl then
			if stance == "Stand" then
				stance = "Crouch"
			elseif stance == "Crouch" then
				stance = "Prone"
			elseif stance == "Prone" then
				stance = "Stand"
			end
		elseif Key == Enum.KeyCode.LeftShift then
			if not Tool or (Tool and not Tool.reloading) then
				stance = "Sprint"
				if Tool then
					action = "Hold"
				else
					action = "Rest"
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if Tool then
				action = "Focus"
				if stance == "Sprint" then
					stance = "Stand"
				end
			end
		end
		SyncCharacter()
	end
end)
UIS.InputEnded:connect(function(input,gamed)
	local Key = input.KeyCode
	if not gamed and Character then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			is_clicking = false
		end
		if Key == Enum.KeyCode.LeftShift then
			if not Tool or (Tool and not Tool.reloading) then
				if stance == "Sprint" then
					stance = "Stand"
					if Tool and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
						action = "Focus"
					end
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if action == "Focus" then
				if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
					stance = "Sprint"
				end
				if Tool then
					action = "Hold"
				else
					action = "Rest"
				end
			end
		end
		SyncCharacter()
	end
end)
--==========================================================================================================================RENDERSTEP
local lasttick = tick()
game["Run Service"]:BindToRenderStep("Input",2,function()
	local newtick = tick()
	local step = newtick-lasttick
	lasttick = newtick
	if CharRig and Character and Character.Parent == workspace then
		Camera.CFrame = (Camera.CFrame)*CharRig.CamOffset.Value
		UIS.MouseIconEnabled = Tool == nil
		if Tool then
			if action == "Focus" then
				CURSOR_GUI.Visible = false
			else
				CURSOR_GUI.Visible = true
				local spot,pos = game.Workspace:FindPartOnRay(Ray.new(Tool.Sight.Position,Tool.Sight.CFrame.lookVector*100),Character)
				local screenpos = Camera:WorldToScreenPoint(pos)
				CURSOR_GUI.Position = UDim2.new(0,screenpos.X-CURSOR_GUI.Size.X.Offset/2,0,screenpos.Y-CURSOR_GUI.Size.Y.Offset/2)
			end
		else
			CURSOR_GUI.Visible = false
		end
		if currentClientAnimation~= "" then
			Character.RightUpperArm.LocalTransparencyModifier = 0
			Character.RightLowerArm.LocalTransparencyModifier = 0
			Character.RightHand.LocalTransparencyModifier = 0 
			Character.RightUpperArm.Anchored = true
			Character.RightLowerArm.Anchored = true
			Character.RightHand.Anchored = true
			Character.RightUpperArm.RightShoulder.Part1 = nil
			Character.RightLowerArm.RightElbow.Part1 = nil
			Character.RightHand.RightWrist.Part1 = nil
			
			local lerppos = Character.RightUpperArm.Position:Lerp((Camera.CFrame * CharRig.RightUpperArm.Value).p,.95)
			local lerprot = Character.RightUpperArm.CFrame:Lerp(Camera.CFrame * CharRig.RightUpperArm.Value,.85)
			Character.RightUpperArm.CFrame = CFrame.new(lerppos)*(lerprot-lerprot.p)
			Character.RightLowerArm.CFrame = Character.RightUpperArm.CFrame * CharRig.RightLowerArm.Value
			Character.RightHand.CFrame  = Character.RightLowerArm.CFrame * CharRig.RightHand.Value
			if Tool then
				Tool.Handle.CFrame = Character.RightHand.CFrame*CFrame.new(0, -0.149999633, -8.77836754e-08, 1, 4.31581502e-05, 4.80200768e-10, 9.29503585e-10, -3.26636873e-05, 1, 4.31581502e-05, -1, -3.26636873e-05)
			end
			
			Character.LeftUpperArm.LocalTransparencyModifier = 0
			Character.LeftLowerArm.LocalTransparencyModifier = 0
			Character.LeftHand.LocalTransparencyModifier = 0
			Character.LeftUpperArm.Anchored = true
			Character.LeftLowerArm.Anchored = true
			Character.LeftHand.Anchored = true
			Character.LeftUpperArm.LeftShoulder.Part1 = nil
			Character.LeftLowerArm.LeftElbow.Part1 = nil
			Character.LeftHand.LeftWrist.Part1 = nil
			local lerppos = Character.LeftUpperArm.Position:Lerp((Camera.CFrame * CharRig.LeftUpperArm.Value).p,.95)
			local lerprot = Character.LeftUpperArm.CFrame:Lerp(Camera.CFrame * CharRig.LeftUpperArm.Value,.85)
			Character.LeftUpperArm.CFrame = CFrame.new(lerppos)*(lerprot-lerprot.p)
			Character.LeftLowerArm.CFrame = Character.LeftUpperArm.CFrame * CharRig.LeftLowerArm.Value
			Character.LeftHand.CFrame = Character.LeftLowerArm.CFrame * CharRig.LeftHand.Value
		else
			Character.RightUpperArm.RightShoulder.Part1 = Character.RightUpperArm
			Character.RightLowerArm.RightElbow.Part1 = Character.RightLowerArm
			Character.RightHand.RightWrist.Part1 = Character.RightHand
			Character.LeftUpperArm.LeftShoulder.Part1 = Character.LeftUpperArm
			Character.LeftLowerArm.LeftElbow.Part1 = Character.LeftLowerArm
			Character.LeftHand.LeftWrist.Part1 = Character.LeftHand
			Character.RightUpperArm.Anchored = false
			Character.RightLowerArm.Anchored = false
			Character.RightHand.Anchored = false
			Character.LeftUpperArm.Anchored = false
			Character.LeftLowerArm.Anchored = false
			Character.LeftHand.Anchored = false
		end
	else
		CURSOR_GUI.Visible = false
		UIS.MouseIconEnabled = true
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end
end)
--==========================================================================================================================CHARACTER SETUP
local function UpdateCharacter(newChar)
	if newChar then
		Character = newChar
		CharRig = script.DefaultCharRig:Clone()
		CharRig.Parent = script
		Humanoid = Character:WaitForChild("Humanoid")
		wait()
		LoadDefaultAnimations()
		StopAllAnimations()
--		Humanoid.Running:connect(function(speed)
--			if speed > 0 then
--				Walking()
--			else
--				StoppedWalking()
--			end
--		end)
	end
end
PLAYER.CharacterRemoving:connect(function()
	Character = nil
	UnequipTool()
	stance = "Stand"
	action = "Rest"
	CharRig:Destroy()
end)
PLAYER.CharacterAdded:connect(UpdateCharacter)
UpdateCharacter(PLAYER.Character)
