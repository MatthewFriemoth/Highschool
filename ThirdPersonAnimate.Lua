-- 2017 Matthew Friemoth

local BASE_WALKSPEED = 16
local BASE_SENSITIVITY = 200
------------------------------------------------------------	SERVICES
local UIS 			= 	game:GetService("UserInputService");
local tweenService 	= 	game:GetService("TweenService");
local runService 	= 	game:GetService("RunService");
------------------------------------------------------------	PLAYER
local player = game.Players.LocalPlayer;

local camera = workspace.CurrentCamera;
local mouse = player:GetMouse();

------------------------------------------------------------	CHARACTER
repeat 
	wait();
until (player.Character and player.Character:IsDescendantOf(workspace));

local character = player.Character;
local humanoid = character:WaitForChild("Humanoid");
local THINGS = character:WaitForChild("THINGS");

local defaultAnimations = character:WaitForChild("DefaultAnimations");
--local mouseUnitVal = THINGS:WaitForChild("MouseUnit");

local HRP = character:WaitForChild("HumanoidRootPart");
local head = character:WaitForChild("Head");
local upperTorso = character:WaitForChild("UpperTorso");
local lowerTorso = character:WaitForChild("LowerTorso");
local RUarm = character:WaitForChild("RightUpperArm");
local LUarm = character:WaitForChild("LeftUpperArm");

local neck = head:WaitForChild("Neck");
local waist = upperTorso:WaitForChild("Waist");

local walkSpeed = BASE_WALKSPEED;
local sensitivity = BASE_SENSITIVITY

------------------------------------------------------------	ANIMATIONS
local Animations = {};

--Create animations from DefaultAnimations folder
for _,v in pairs(defaultAnimations:GetChildren())do
	
	Animations[v.Name] = humanoid:LoadAnimation(v);
	
end
print("Animations Loaded");
Animations.Play = function(name, overRide)
	
	local animTrack = Animations[name]
	
	if not animTrack.IsPlaying or overRide then
		
		animTrack:Play()
		
	end
	
end

Animations.Stop = function(name)
	
	Animations[name]:Stop()
	
end

Animations.Pause = function(name)
	
	Animations[name]:AdjustSpeed(0)
	
end

Animations.Unpause = function(name)
	
	Animations[name]:AdjustSpeed(1)
	
end

Animations.Reverse = function(name)
	
	Animations[name]:AdjustSpeed(-1)
	
end
------------------------------------------------------------	ACTIONS

local Actions = {};
--Booleans
Actions.IsCrouching = THINGS.IsCrouching;
Actions.IsClimbing= THINGS.IsClimbing;
Actions.IsFalling = THINGS.IsFalling;
Actions.IsFocusing = THINGS.IsFocusing;
Actions.IsJumping = THINGS.IsJumping;
Actions.IsMoving = THINGS.IsMoving;
Actions.IsSprinting = THINGS.IsSprinting;
Actions.IsHoldingTool = THINGS.IsHoldingTool;
local jumping -- for script only, not reliable
--Functions
Actions.Is = function(action)
	
	return Actions["Is"..action].Value
	
end
Actions.Set = function(action, value)
	Actions["Is"..action].Value = value
end
Actions.Crouch = function(activate)
	
	if activate then
		
		Actions.Set("Crouching",true)
		
		walkSpeed = BASE_WALKSPEED - 4
		--Tweens.Play("DownView")
		if not Actions.Is("Falling") then
			
			if Actions.Is("Moving") then
			
				Animations.Stop("Run")
				Animations.Play("Crouch")
			
			else
			
				Animations.Stop("Idle1")
				Animations.Play("IdleCrouch")
			
			end
			
		end
		
	else
	
		Actions.Set("Crouching", false)
		
		walkSpeed = BASE_WALKSPEED
		--module.Tweens.Play("UpView")
		
		if Actions.Is("Moving") then
			
			Animations.Stop("Crouch")
			Animations.Play("Run")
		
		else
			
			Animations.Stop("IdleCrouch")		
			Animations.Play("Idle1")
			
		end

	end
	
end
Actions.Sprint = function(activate)
	
	if activate then
		
		Actions.Set("Sprinting", true)
		
		if Actions.Is("Focusing") then
			
			--ActionsList.Focus(false)
			
		end
		
		if Actions.Is("Crouching") then
		
			Actions.Crouch(false);
		
		end
		
		walkSpeed = BASE_WALKSPEED + 5
		
	else
		
		Actions.Set("Sprinting", false)
		
		if not Actions.Is("Crouching") then
			
			walkSpeed = BASE_WALKSPEED
			
		end
		
		
	end

end

Actions.StartMoving = function(activate)
	
	if activate then
		
		Actions.Set("Moving", true)
	
		if Actions.Is("Crouching") then
			
			Animations.IdleCrouch:Stop();
			Animations.Crouch:Play();
			
		else
			
			Animations.Idle1:Stop();
			Animations.Run:Play();
			
		end
	
	else
	
		Actions.Set("Moving", false)
		
		if Actions.Is("Crouching") then
			
			Animations.Crouch:Stop();
			Animations.IdleCrouch:Play();
		
		else
			
			Animations.Run:Stop();
			Animations.Idle1:Play();
			
		end
		
	end
	
end

------------------------------------------------------------	INPUT
--[[
	
Replaced by CharacterWalking
	
humanoid.Running:connect(function(speed)

    if speed > 0 then
	
		Actions.StartMoving(true);
	
    else
	
		Actions.StartMoving(false);
		
    end

end)
--]]
local function CharacterWalking(activate)
	
	if activate ~= Actions.Is("Moving") then
		
		Actions.StartMoving(activate);
		
	end
	
end

character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		Actions.Set("HoldingTool", true)
	end
end)

character.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") then
		Actions.Set("HoldingTool", false)
	end
end)

humanoid.Climbing:connect(function(speed)
	
	if speed > 0 then
		
		
		Animations.Unpause("Climb", false)
		
	elseif speed == 0 then
		
		Animations.Pause("Climb")
		
	else
		
		Animations.Reverse("Climb")
		
	end	
	
end)

humanoid.Jumping:connect(function(active)

	if active then
		
		jumping = true
		Actions.Set("Falling", true)
		
		Animations.Play("Jump",true)	
		
	end	
	
end)

humanoid.FreeFalling:connect(function(active)
	
	if active then
		
		Actions.Set("Falling", true)
		
		Animations.Play("FreeFall",false)
		
	else
		
		Actions.Set("Falling", false)
		
		Animations.Stop("Jump")
		Animations.Stop("FreeFall")
		
		if Actions.Is("Jumping") and Actions.Is("Jumping") then
			
			Actions.Crouch(false)
			
		end
		
		if Actions.Is("Crouching") then
			
			Actions.Crouch(true);
			
		end
		
		jumping = false
		
	end	
	
end)

humanoid.StateChanged:connect(function(old, new)
	
	if new == Enum.HumanoidStateType.Climbing then
		
		Animations.Play("Climb", false)
		Actions.Set("Climbing", true)
		
	elseif old == Enum.HumanoidStateType.Climbing then
	
		Animations.Stop("Climb")
		Actions.Set("Climbing", false)
		
	end
	
end)

UIS.InputBegan:connect(function(input, gameProcessed)
	
	if not gameProcessed then
		
		if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
			
			if Actions.Is("Crouching") then
		
				Actions.Crouch(false)
			
			else
			
				Actions.Crouch(true)
		
			end
			
		end
		
		if input.KeyCode == Enum.KeyCode.LeftShift then
			
			if Actions.Is("Crouching") then
		
				Actions.Crouch(false)
				
			end
			
			Actions.Sprint(true)	--pcall(.Actions.Sprint,true) // Not sure what this does
			
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				
		--	Actions.Focus(true)
			
		end
	
	end
	
end)

UIS.InputEnded:connect(function(input,gameProcessed)
	
	if input.KeyCode == Enum.KeyCode.LeftShift then
			
		if not Actions.Is("Crouching") then
				
			Actions.Sprint(false)
			
		end
		
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			
		if Actions.Is("Focusing") then
			
			--Actions.Focus(false)	--pcall(.Actions.Focus,false)
			
		end
			
	end
	
end)

------------------------------------------------------------	CHARACTER RENDER LOOP
local headrot = 0

runService:BindToRenderStep("CharacterRot", 3, function(step)
	
	if humanoid then
		
		humanoid.WalkSpeed = walkSpeed;
		
	end

	if HRP and upperTorso and head and waist and neck then
				
		local lookVector = HRP.CFrame.lookVector
		local rot = -(math.atan2(lookVector.X, lookVector.Z) - math.pi)
				
		local diff = shared.cameraAngles.Y - rot

		if math.abs(diff) < math.pi/2 then
					
			headrot = diff
					
		elseif math.abs(diff) > math.pi * (3/2) then
					
			headrot = (diff - math.pi*2)
					
		else
						
			humanoid.RootPart.CFrame = humanoid.RootPart.CFrame:Lerp(CFrame.new(HRP.CFrame.p) * CFrame.Angles(0, -shared.cameraAngles.Y, 0),step * math.abs(diff))

		end
				
		waist.C0 = CFrame.new(waist.C0.p) * CFrame.Angles(0,-headrot * 0.5,0) * CFrame.Angles(-shared.cameraAngles.X * 0.75,0,0)
		neck.C0 = CFrame.new(neck.C0.p) * CFrame.Angles(0,-headrot * 0.5,0) * CFrame.Angles(-shared.cameraAngles.X * 0.25, 0, 0)			
		
	end
	
end)

runService:BindToRenderStep("Twist", 2, function()
	
	if character and humanoid and HRP and HRP:IsDescendantOf(workspace) then
		
		if Actions.Is("Focusing") then
		
			humanoid.RootPart.CFrame = CFrame.new(humanoid.RootPart.CFrame.p) * CFrame.Angles(0,-shared.cameraAngles.Y,0)
			
		end
					
	end
	
end)

------------------------------------------------------------	CONTROL
local function UpdateCharacterMovement()
	
	if character and humanoid then
	
		local moveDir = Vector3.new()
		--humanoid.AutoRotate = true;
		if UIS:IsKeyDown(Enum.KeyCode.W) then
			moveDir = moveDir + shared.cameraCFrameRotY.lookVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.S) then
			moveDir = moveDir - shared.cameraCFrameRotY.lookVector
			--humanoid.AutoRotate = false;
		end
		if UIS:IsKeyDown(Enum.KeyCode.D) then
			moveDir = moveDir + shared.cameraCFrameRotY.rightVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) then
			moveDir = moveDir - shared.cameraCFrameRotY.rightVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
				humanoid.Jump = true
			end
		end
		shared.moveDirRelCam = moveDir;
		CharacterWalking(moveDir ~= Vector3.new());
		humanoid:Move(moveDir)
	
	end
			
end

------------------------------------------------------------	EVENTS

UIS.InputBegan:connect(function(input, gameProcessed)
	
	if not gameProcessed then
		
		UpdateCharacterMovement()
		
		if input.UserInputType == Enum.UserInputType.MouseButton3 then
			
			--SwitchShoulderView()
			
		end	
		
	end
	
	if input.KeyCode == Enum.KeyCode.LeftAlt then
			
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
			
	end
	
end)

UIS.InputEnded:connect(function(input, gameProcessed)
	
	if not gameProcessed then
		
		UpdateCharacterMovement()

	end
	
	if input.KeyCode == Enum.KeyCode.LeftAlt then
			
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		UIS.MouseIconEnabled = false
			
	end
	
end)


UIS.InputChanged:connect(function(input, gamedProcessed)
	
	if not gamedProcessed then
		
		local YROT = shared.cameraAngles.Y + input.Delta.X / sensitivity
		if YROT > math.pi * 2 then
			
			YROT = YROT - math.pi * 2
			
		elseif YROT < 0 then
			
			YROT = YROT + math.pi * 2
			
		end
		local XROT = math.min(math.pi/2, math.max(-math.pi/2, shared.cameraAngles.X + input.Delta.Y / sensitivity))
		shared.cameraCFrameRotY = CFrame.Angles(0, -YROT, 0)
		shared.cameraCFrameRotX = CFrame.Angles(-XROT, 0, 0)
		shared.cameraAngles = Vector2.new(XROT, YROT)
		
		UpdateCharacterMovement()
		
	end
	
end)

game["Run Service"]:BindToRenderStep("Camera", 1, function()
	
	if character and HRP and head then
		
		local cameraRoot = HRP.Position
		local CamRot = shared.cameraCFrameRotY * shared.cameraCFrameRotX

		camera.CFrame = CamRot * CFrame.new(shared.cameraOffset) + cameraRoot + Vector3.new(0, 3, 0)
		
	end
	
end)
