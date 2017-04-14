--@ commons normalizebearing sign pid thrusthack
-- 6DoF module (Altitude, Yaw, Pitch, Roll, Forward/Reverse, Right/Left)
AltitudePID = PID.create(AltitudePIDConfig, -30, 30)
YawPID = PID.create(YawPIDConfig, -30, 30)
PitchPID = PID.create(PitchPIDConfig, -30, 30)
RollPID = PID.create(RollPIDConfig, -30, 30)
ForwardPID = PID.create(ForwardPIDConfig, -30, 30)
RightPID = PID.create(RightPIDConfig, -30, 30)

DesiredAltitude = 0
DesiredHeading = nil
DesiredPosition = nil
DesiredPitch = 0
DesiredRoll = 0

-- Keep them separated for now
SixDoF_LastPropulsionCount = 0
SixDoF_PropulsionInfos = {}
SixDoF_LastSpinnerCount = 0
SixDoF_SpinnerInfos = {}

SixDoF_UsesJets = (JetFractions.Altitude > 0 or JetFractions.Yaw > 0 or JetFractions.Pitch > 0 or JetFractions.Roll > 0 or JetFractions.Forward > 0 or JetFractions.Right > 0)
SixDoF_UsesSpinners = (SpinnerFractions.Altitude > 0 or SpinnerFractions.Yaw > 0 or SpinnerFractions.Pitch > 0 or SpinnerFractions.Roll > 0 or SpinnerFractions.Forward > 0 or SpinnerFractions.Right > 0)

APRThrustHackControl = ThrustHack.create(APRThrustHackDriveMaintainerFacing)
YLLThrustHackControl = ThrustHack.create(YLLThrustHackDriveMaintainerFacing)

function SetAltitude(Alt)
   DesiredAltitude = Alt
end

function AdjustAltitude(Delta) -- luacheck: ignore 131
   SetAltitude(C:Altitude() + Delta)
end

-- Sets heading to an absolute value, 0 is north, 90 is east
function SetHeading(Heading)
   DesiredHeading = Heading % 360
end

-- Adjusts heading toward relative bearing
function AdjustHeading(Bearing) -- luacheck: ignore 131
   SetHeading(C:Yaw() + Bearing)
end

-- Resets heading so yaw will no longer be modified
function ResetHeading()
   DesiredHeading = nil
end

function SetPosition(Pos)
   -- Make copy to be safe
   DesiredPosition = Vector3(Pos.x, Pos.y, Pos.z)
end

function AdjustPosition(Offset)
   DesiredPosition = C:CoM() + Offset
end

function ResetPosition()
   DesiredPosition = nil
end

function SetPitch(Angle) -- luacheck: ignore 131
   DesiredPitch = Angle
end

function SetRoll(Angle) -- luacheck: ignore 131
   DesiredRoll = Angle
end

function SixDoF_Reset()
   ResetHeading()
   ResetPosition()
end

function SixDoF_Classify(Index, BlockInfo, IsSpinner, Fractions, Infos)
   local CoMOffset = BlockInfo.LocalPositionRelativeToCom
   local LocalForwards = IsSpinner and (BlockInfo.LocalRotation * Vector3.up) or BlockInfo.LocalForwards
   local Info = {
      Index = Index,
      UpSign = 0,
      YawSign = 0,
      PitchSign = 0,
      RollSign = 0,
      ForwardSign = 0,
      RightSign = 0,
      IsVertical = false,
   }
   if math.abs(LocalForwards.y) > 0.001 then
      -- Vertical
      local UpSign = Sign(LocalForwards.y)
      Info.UpSign = UpSign * Fractions.Altitude
      Info.PitchSign = Sign(CoMOffset.z) * UpSign * Fractions.Pitch
      Info.RollSign = Sign(CoMOffset.x) * UpSign * Fractions.Roll
      Info.IsVertical = true
   else
      -- Horizontal
      local RightSign = Sign(LocalForwards.x)
      local ZSign = Sign(CoMOffset.z)
      Info.YawSign = RightSign * ZSign * Fractions.Yaw
      Info.ForwardSign = Sign(LocalForwards.z) * Fractions.Forward
      Info.RightSign = RightSign * Fractions.Right
   end
   if Info.UpSign ~= 0 or Info.PitchSign ~= 0 or Info.RollSign ~= 0 or Info.YawSign ~= 0 or Info.ForwardSign ~= 0 or Info.RightSign ~= 0 then
      table.insert(Infos, Info)
   end
end

function SixDoF_ClassifyJets(I)
   local PropulsionCount = I:Component_GetCount(PROPULSION)
   if PropulsionCount ~= SixDoF_LastPropulsionCount then
      SixDoF_LastPropulsionCount = PropulsionCount
      SixDoF_PropulsionInfos = {}

      for i = 0,PropulsionCount-1 do
         local BlockInfo = I:Component_GetBlockInfo(PROPULSION, i)
         SixDoF_Classify(i, BlockInfo, false, JetFractions, SixDoF_PropulsionInfos)
      end
   end
end

function SixDoF_ClassifySpinners(I)
   local SpinnerCount = I:GetSpinnerCount()
   if SpinnerCount ~= SixDoF_LastSpinnerCount then
      SixDoF_LastSpinnerCount = SpinnerCount
      SixDoF_SpinnerInfos = {}

      for i = 0,SpinnerCount-1 do
         -- Only process dediblades for now
         if I:IsSpinnerDedicatedHelispinner(i) then
            local BlockInfo = I:GetSpinnerInfo(i)
            SixDoF_Classify(i, BlockInfo, true, SpinnerFractions, SixDoF_SpinnerInfos)
         end
      end

      if DediBladesAlwaysUp then
         -- Flip signs on any spinners with negative UpSign
         for _,Info in pairs(SixDoF_SpinnerInfos) do
            local UpSign = Info.UpSign
            if UpSign < 0 then
               Info.UpSign = -UpSign
               Info.PitchSign = -Info.PitchSign
               Info.RollSign = -Info.RollSign
            end
         end
      end
   end
end

function SixDoF_Update(I)
   local AltitudeDelta = DesiredAltitude - C:Altitude()
   if not DediBladesAlwaysUp then
      -- Scale by vehicle up vector's Y component
      AltitudeDelta = AltitudeDelta * C:UpVector().y
   end
   -- Otherwise, the assumption is that it always points straight up ("always up")
   local AltitudeCV = AltitudePID:Control(AltitudeDelta)
   local YawCV = DesiredHeading and YawPID:Control(NormalizeBearing(DesiredHeading - C:Yaw())) or 0
   local PitchCV = PitchPID:Control(DesiredPitch - C:Pitch())
   local RollCV = RollPID:Control(DesiredRoll - C:Roll())

   local ForwardCV,RightCV = 0,0
   if DesiredPosition then
      local Offset = DesiredPosition - C:CoM()
      local ZProj = Vector3.Dot(Offset, C:ForwardVector())
      local XProj = Vector3.Dot(Offset, C:RightVector())
      ForwardCV = ForwardPID:Control(ZProj)
      RightCV = RightPID:Control(XProj)
   end

   if SixDoF_UsesJets then
      SixDoF_ClassifyJets(I)

      if DesiredHeading or DesiredPosition then
         -- Blip horizontal thrusters
         if not YLLThrustHackDriveMaintainerFacing then
            for i = 0,3 do
               I:RequestThrustControl(i)
            end
         else
            YLLThrustHackControl:SetThrottle(I, 1)
         end
      else
         -- Relinquish control
         YLLThrustHackControl:SetThrottle(I, 0)
      end
      -- Blip top & bottom thrusters
      if not APRThrustHackDriveMaintainerFacing then
         I:RequestThrustControl(4)
         I:RequestThrustControl(5)
      else
         APRThrustHackControl:SetThrottle(I, 1)
      end

      -- Set drive fraction accordingly
      for _,Info in pairs(SixDoF_PropulsionInfos) do
         if Info.IsVertical or DesiredHeading or DesiredPosition then
            -- Sum up inputs and constrain
            local Output = AltitudeCV * Info.UpSign + YawCV * Info.YawSign + PitchCV * Info.PitchSign + RollCV * Info.RollSign + ForwardCV * Info.ForwardSign + RightCV * Info.RightSign
            Output = math.max(0, math.min(30, Output))
            I:Component_SetFloatLogic(PROPULSION, Info.Index, Output / 30)
         else
            -- Restore full drive fraction for manual/stock AI control
            I:Component_SetFloatLogic(PROPULSION, Info.Index, 1)
         end
      end
   end

   if SixDoF_UsesSpinners then
      SixDoF_ClassifySpinners(I)

      -- Set spinner speed
      for _,Info in pairs(SixDoF_SpinnerInfos) do
         if Info.IsVertical or DesiredHeading or DesiredPosition then
            -- Sum up inputs and constrain
            local Output = AltitudeCV * Info.UpSign + YawCV * Info.YawSign + PitchCV * Info.PitchSign + RollCV * Info.RollSign + ForwardCV * Info.ForwardSign + RightCV * Info.RightSign
            Output = math.max(-30, math.min(30, Output))
            I:SetSpinnerContinuousSpeed(Info.Index, Output)
         else
            -- Zero out (for now) FIXME Probably doesn't work for ACB/drive maintainer override
            I:SetSpinnerContinuousSpeed(Info.Index, 0)
         end
      end
   end
end

function SixDoF_Disable(I)
   -- Disable drive maintainers, if any
   APRThrustHackControl:SetThrottle(I, 0)
   YLLThrustHackControl:SetThrottle(I, 0)
   if SixDoF_UsesSpinners then
      SixDoF_ClassifySpinners(I)
      -- And stop spinners as well
      for _,Info in pairs(SixDoF_SpinnerInfos) do
         I:SetSpinnerContinuousSpeed(Info.Index, 0)
      end
   end
end
