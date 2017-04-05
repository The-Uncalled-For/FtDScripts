-- 3DOF CONFIGURATION

YawPIDConfig = {
   Kp = .3,
   Ti = 5,
   Td = .4,
}
ForwardPIDConfig = {
   Kp = .5,
   Ti = 5,
   Td = .1,
}
RightPIDConfig = {
   Kp = .5,
   Ti = 5,
   Td = .1,
}

-- THRUST HACK CONFIGURATION

-- Use thrust hack instead of standard Lua control of thrusters.
-- Requires a drive maintainer facing in the given direction.
-- Drive maintainer should be set up on its own drive (e.g. tertiary).
-- All related jets should be bound to that drive.
ThrustHackDriveMaintainerFacing = nil
