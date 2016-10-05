--@ pid planarvector quadraticintercept getbearingtopoint
-- Waypoint move module
MTW_ThrottlePID = PID.create(WaypointMoveConfig.ThrottlePIDConfig, -1, 1)

if not WaypointMoveConfig.MinimumSpeed then WaypointMoveConfig.MinimumSpeed = 0 end

-- Scale desired speed up (or down) depending on angle between velocities
function MTW_MatchSpeed(Velocity, TargetVelocity, Faster)
   local Speed = Velocity.magnitude
   local TargetSpeed = TargetVelocity.magnitude
   -- Already calculated magnitudes...
   local VelocityDirection = Velocity / Speed
   local TargetVelocityDirection = TargetVelocity / TargetSpeed

   local CosAngle = Vector3.Dot(TargetVelocityDirection, VelocityDirection)
   local MinimumSpeed = WaypointMoveConfig.MinimumSpeed
   if CosAngle > 0 then
      local DesiredSpeed = TargetSpeed
      -- Can take CosAngle into account and scale RelativeApproachSpeed appropriately,
      -- but K.I.S.S. for now.
      DesiredSpeed = DesiredSpeed + Mathf.Sign(Faster) * WaypointMoveConfig.RelativeApproachSpeed
      return math.max(MinimumSpeed, DesiredSpeed),Speed
   else
      -- Angle between velocities >= 90 degrees, go minimum speed
      return MinimumSpeed,Speed
   end
end

-- Move to a waypoint (using yaw & throttle only)
function MoveToWaypoint(I, Waypoint, AdjustHeading, WaypointVelocity)
   local Offset,TargetPosition = PlanarVector(CoM, Waypoint)
   local Distance = Offset.magnitude

   if not WaypointVelocity then
      -- Stationary waypoint, just point and go
      if Distance >= WaypointMoveConfig.MaxDistance then
         local Bearing = GetBearingToPoint(Waypoint)
         AdjustHeading(Bearing)
         SetThrottle(WaypointMoveConfig.ClosingDrive)
      else
         SetThrottle(0)
      end
   else
      local Direction = Offset / Distance

      -- TODO Maybe use a globally-cached velocity?
      local Velocity = I:GetVelocityVector()
      -- Constrain our velocity and waypoint velocity to XZ plane
      Velocity.y = 0
      local TargetVelocity = Vector3(WaypointVelocity.x, 0, WaypointVelocity.z)
      -- Predict intercept
      local TargetPoint = QuadraticIntercept(CoM, Velocity, TargetPosition, TargetVelocity)

      local Bearing = GetBearingToPoint(TargetPoint)
      AdjustHeading(Bearing)

      if Distance >= WaypointMoveConfig.ApproachDistance then
         -- Go full throttle and catch up
         SetThrottle(WaypointMoveConfig.ClosingDrive)
      else
         -- Only go faster if waypoint is ahead of us
         local Faster = Vector3.Dot(I:GetConstructForwardVector(), Direction)
         -- Attempt to match speed
         local DesiredSpeed,Speed = MTW_MatchSpeed(Velocity, TargetVelocity, Faster)
         -- Use PID to set throttle
         local Error = DesiredSpeed - Speed
         local CV = MTW_ThrottlePID:Control(Error)
         local Drive = math.max(0, math.min(1, CurrentThrottle + CV))
         SetThrottle(Drive)
      end
   end
end