--! airship
--@ commons firstrun periodic
--@ shieldmanager balloonmanager dualprofile sixdof altitudecontrol airshipdefaults naval-ai
-- Airship main
BalloonManager = Periodic.create(BalloonManager_UpdateRate, BalloonManager_Control, 4)
ShieldManager = Periodic.create(ShieldManager_UpdateRate, ShieldManager_Control, 3)
MissileMain = Periodic.create(Missile_UpdateRate, MissileMain_Update, 2)
AltitudeControl = Periodic.create(AltitudeControl_UpdateRate, Altitude_Control, 1)
NavalAI = Periodic.create(AI_UpdateRate, NavalAI_Update)

Control_Reset = SixDoF_Reset

function Update(I) -- luacheck: ignore 131
   C = Commons.create(I)
   if FirstRun then FirstRun(I) end
   if not C:IsDocked() then
      AltitudeControl:Tick(I)

      if ActivateWhen[I.AIMode] then
         NavalAI:Tick(I)

         -- Suppress default AI
         I:TellAiThatWeAreTakingControl()
      else
         NavalAI_Reset()
      end

      Altitude_Apply(I, DodgeAltitudeOffset)
      SixDoF_Update(I)

      MissileMain:Tick(I)
   else
      NavalAI_Reset()
      SixDoF_Disable(I)
   end

   ShieldManager:Tick(I)
   BalloonManager:Tick(I)
end
