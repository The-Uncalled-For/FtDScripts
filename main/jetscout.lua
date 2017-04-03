--! jetscout
--@ commons firstrun periodic
--@ cameratrack shieldmanager altitudecontrol sixdof gunship-ai
CameraTrack = Periodic.create(CameraTrack_UpdateRate, CameraTrack_Update, 3)
ShieldManager = Periodic.create(ShieldManager_UpdateRate, ShieldManager_Control, 2)
Hover = Periodic.create(Hover_UpdateRate, Altitude_Control, 1)
GunshipAI = Periodic.create(AI_UpdateRate, GunshipAI_Update)

Control_Reset = SixDoF_Reset

function Update(I) -- luacheck: ignore 131
   C = Commons.create(I, true)
   if FirstRun then FirstRun(I) end
   if not C:IsDocked() then
      Hover:Tick(I)

      if ActivateWhen[I.AIMode] then
         GunshipAI:Tick(I)

         -- Suppress default AI
         I:TellAiThatWeAreTakingControl()
      else
         SixDoF_Reset()
         DodgeAltitudeOffset = nil
      end

      if DodgeAltitudeOffset then
         AdjustAltitude(DodgeAltitudeOffset, MinAltitude)
      else
         SetAltitude(DesiredControlAltitude+ControlAltitudeOffset, MinAltitude)
      end
      SixDoF_Update(I)

      CameraTrack:Tick(I)
   end

   ShieldManager:Tick(I)
end