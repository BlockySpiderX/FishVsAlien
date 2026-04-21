local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local WorldTimeServiceServer = {}
WorldTimeServiceServer.__index = WorldTimeServiceServer

local DAY_DURATION = 5 * 60
local NIGHT_DURATION = 2 * 60

local DAY_STATE = {
	--Ambient = Color3.fromRGB(145, 145, 145),
	--Brightness = 2.0,
	ClockTime = 13.5,
	--ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
	--ColorShift_Top = Color3.fromRGB(255, 244, 214),
	--EnvironmentDiffuseScale = 0.35,
	--EnvironmentSpecularScale = 0.35,
	--ExposureCompensation = 0.08,
	--OutdoorAmbient = Color3.fromRGB(160, 160, 160),
	--ShadowSoftness = 0.22,
}

local NIGHT_STATE = {
	--Ambient = Color3.fromRGB(42, 50, 84),
	--Brightness = 1.25,
	ClockTime = 1.5,
	--ColorShift_Bottom = Color3.fromRGB(14, 18, 36),
	--ColorShift_Top = Color3.fromRGB(67, 93, 170),
	--EnvironmentDiffuseScale = 0.18,
	--EnvironmentSpecularScale = 0.2,
	--ExposureCompensation = -0.18,
	--OutdoorAmbient = Color3.fromRGB(56, 67, 104),
	--ShadowSoftness = 0.7,
}

local function applyState(state)
	for property, value in state do
		Lighting[property] = value
	end
end

function WorldTimeServiceServer.new()
	local self = setmetatable({
		currentTween = nil,
		destroyed = false,
	}, WorldTimeServiceServer)

	applyState(DAY_STATE)

	task.spawn(function()
		self:runCycle()
	end)

	return self
end

function WorldTimeServiceServer:playStateTween(state, duration)
	if self.currentTween then
		self.currentTween:Cancel()
	end

	local tween = TweenService:Create(
		Lighting,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		state
	)

	self.currentTween = tween
	tween:Play()
	tween.Completed:Wait()
end

function WorldTimeServiceServer:runCycle()
	while not self.destroyed do
		self:playStateTween(NIGHT_STATE, NIGHT_DURATION)
		if self.destroyed then
			break
		end

		self:playStateTween(DAY_STATE, DAY_DURATION)
	end
end

function WorldTimeServiceServer:destroy()
	self.destroyed = true

	if self.currentTween then
		self.currentTween:Cancel()
		self.currentTween = nil
	end
end

return WorldTimeServiceServer
