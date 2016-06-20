--! hover
--@ commons gettarget pid
AltitudePID = PID.create(AltitudePIDValues[1], AltitudePIDValues[2], AltitudePIDValues[3], CanReverseBlades and -30 or 0, 30)

Spinners = {}

function ClassifySpinners(I)
   local __func__ = "ClassifySpinners"

   Spinners = {}
   for i = 0,I:GetSpinnerCount()-1 do
      if I:IsSpinnerDedicatedHelispinner(i) then
         local Info = I:GetSpinnerInfo(i)
         local UpFraction = Vector3.Dot(Info.LocalRotation * Vector3.up,
                                        Vector3.up)
         if math.abs(UpFraction) > 0.001 then -- Sometimes there's -0
            if Debugging then Debug(I, __func__, "Index %d UpFraction %f", i, UpFraction) end
            local Spinner = {
               Index = i,
               UpFraction = UpFraction
            }
            Spinners[#Spinners+1] = Spinner
         end
      end
   end
end

function Update(I)
   local __func__ = "Update"

   ClassifySpinners(I)

   if I.AIMode ~= "off" then
      GetSelfInfo(I)

      local DesiredAltitude
      if GetTarget(I) then
         DesiredAltitude = DesiredAltitudeCombat
      else
         DesiredAltitude = DesiredAltitudeIdle
      end

      if not AbsoluteAltitude then
         -- Add terrain height under CoM
         local Height = I:GetTerrainAltitudeForPosition(CoM)
         -- Check additional look-ahead positions
         local Velocity = I:GetVelocityVector()
         for i,t in pairs(AltitudeLookAhead) do
            Height = math.max(Height, I:GetTerrainAltitudeForPosition(CoM + Velocity * t))
         end
         -- Finally, don't fly lower than sea level
         Height = math.max(Height, 0)
         DesiredAltitude = DesiredAltitude + Height
      end

      local CV = AltitudePID:Control(DesiredAltitude - Altitude)

      if Debugging then Debug(I, __func__, "Altitude %f CV %f", Altitude, CV) end

      for i,Spinner in pairs(Spinners) do
         I:SetSpinnerContinuousSpeed(Spinner.Index, CV / Spinner.UpFraction)
      end
   else
      for i,Spinner in pairs(Spinners) do
         I:SetSpinnerContinuousSpeed(Spinner.Index, 0)
      end
   end
end
