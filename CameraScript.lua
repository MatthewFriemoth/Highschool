--2017 Matthew Friemoth
local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
---------------------
Sens = 400
local Character
local Humanoid
local gyro = nil
------------------------------------------------------------
local ViewAngles = Vector2.new()
local start = tick()
game["Run Service"]:BindToRenderStep("Camera",1,function()
	local is_Character = Character and Character.Parent == workspace
	if is_Character and Humanoid and Humanoid.RootPart and Character:FindFirstChild("Head") then
		local CharPos = Humanoid.RootPart.Position
		local HeadPos = Character.Head.Position
		if gyro then
			gyro.CFrame = CFrame.Angles(0,-ViewAngles.X,0)
		end
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		for _,v in pairs(Character:GetDescendants())do
			if v:IsA("BasePart") and not v.Parent:IsA("Tool") and v.Name ~= "BulletTrail" then -- Bullet for testing
				v.LocalTransparencyModifier = 1
			end
		end
		local CameraRotation = CFrame.Angles(0,-ViewAngles.X,0)*CFrame.Angles(-ViewAngles.Y,0,0)
		camera.CFrame = CameraRotation+camera.CFrame.p:Lerp(Vector3.new(CharPos.X,HeadPos.Y,CharPos.Z),.6)
	else
		camera.CFrame = CFrame.new(0,25,0)*CFrame.Angles(0,(tick()-start)/3,0)*CFrame.Angles(math.rad(-30),0,0)*CFrame.new(0,0,80)
	end
end)
UIS.InputChanged:connect(function(input,gamed)
	if not gamed then
		local XROT = ViewAngles.X + input.Delta.X/Sens
		local YROT = math.min(math.pi/2,math.max(-math.pi/2,ViewAngles.Y + input.Delta.Y/Sens))
		ViewAngles = Vector2.new(XROT,YROT)
	end
end)
local function UpdateCharacter(char)
	if char then
		Character = char
		Humanoid = char:WaitForChild("Humanoid")
		gyro = script.RotationGyro:Clone()
		gyro.Parent = Character:WaitForChild("HumanoidRootPart")
	end
end
UpdateCharacter(player.Character)
player.CharacterAdded:connect(UpdateCharacter)
