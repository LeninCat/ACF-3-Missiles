local ACF             = ACF
local Clock           = ACF.Utilities.Clock
local Contraption     = ACF.Contraption
local Countermeasures = ACF.Classes.Countermeasures
local NextUpdate      = 0
local Ancestors       = {}

local function GetAncestor(Entity)
	local Ancestor = Contraption.GetAncestor(Entity)

	if not IsValid(Ancestor) then return end
	if Ancestor == Entity then return end
	if Ancestor.DoNotTrack then return end

	return Ancestor
end

local function UpdateValues(Entity)
	if not IsValid(Entity) then return end

	local PhysObj  = Entity:GetPhysicsObject()
	local Velocity = Entity:GetVelocity()
	local PrevPos  = Entity.Position
	local Position

	if IsValid(PhysObj) then
		Position = Entity:LocalToWorld(PhysObj:GetMassCenter())
	else
		Position = Entity:GetPos()
	end

	-- Entities being moved around by SetPos will have a velocity of 0
	-- By using the difference between positions we can get a proper value
	if Velocity:LengthSqr() == 0 and PrevPos then
		Velocity = (Position - PrevPos) / Clock.DeltaTime
	end

	Entity.Position = Position
	Entity.Velocity = Velocity
end

-- Maintain ancestors array
hook.Add("OnEntityCreated", "ACF Entity Tracking", function(Entity)
	if not IsValid(Entity) then return end
	if not Entity.IsACFBaseplate then return end

	Ancestors[Entity] = true

	Entity:CallOnRemove("ACF Entity Tracking", function()
		Ancestors[Entity] = nil
		Entity.Position = nil
		Entity.Velocity = nil
	end)
end)

hook.Add("ACF_OnTick", "ACF Entity Tracking", function()
	for Ancestor in pairs(Ancestors) do
		UpdateValues(Ancestor)
	end
end)

local function GetAncestorEntities()
	return Ancestors
end

function ACF.GetEntitiesInCone(Position, Direction, Degrees, Contraption)
	local Result = {}

	for Entity in pairs(GetAncestorEntities()) do
		if not IsValid(Entity) then continue end
		if Contraption and Entity:GetContraption() == Contraption then continue end
		-- Skip disabled baseplates here

		if Countermeasures.ConeContainsPos(Position, Direction, Degrees, Entity:GetPos()) then
			Result[Entity] = true
		end
	end

	return Result
end

function ACF.GetEntitiesInSphere(Position, Radius, Contraption)
	local Result = {}
	local RadiusSqr = Radius * Radius

	for Entity in pairs(GetAncestorEntities()) do
		if not IsValid(Entity) then continue end
		if Contraption and Entity:GetContraption() == Contraption then continue end
		-- Skip disabled baseplates here

		if Position:DistToSqr(Entity:GetPos()) <= RadiusSqr then
			Result[Entity] = true
		end
	end

	return Result
end
