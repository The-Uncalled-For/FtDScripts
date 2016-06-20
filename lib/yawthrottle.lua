--@ commons pid
YawPID = PID.create(YawPIDValues[1], YawPIDValues[2], YawPIDValues[3], -1.0, 1.0)

-- Adjusts heading toward relative bearing
function AdjustHeading(I, Bearing)
   local __func__ = "AdjustHeading"

   Bearing = Avoidance(I, Bearing)
   local CV = YawPID:Control(Bearing) -- SetPoint of 0
   if Debugging then Debug(I, __func__, "Error = %f, CV = %f", Bearing, CV) end
   if CV > 0.0 then
      I:RequestControl(Mode, YAWRIGHT, CV)
   elseif CV < 0.0 then
      I:RequestControl(Mode, YAWLEFT, -CV)
   end
end

-- Adjust heading toward a given world point
function AdjustHeadingToPoint(I, Point)
   AdjustHeading(I, -I:GetTargetPositionInfoForPosition(0, Point.x, 0, Point.z).Azimuth)
end

-- Sets throttle
function SetDriveFraction(I, Drive)
   I:RequestControl(Mode, MAINPROPULSION, Drive)
end
