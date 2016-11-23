--! gunshipquad
--@ getselfinfo firstrun periodic
--@ shieldmanager dualprofile threedofspinner altitudecontrol threedof gunship-ai
ShieldManager = Periodic.create(ShieldManager_UpdateRate, ShieldManager_Control, 3)
MissileMain = Periodic.create(Missile_UpdateRate, MissileMain_Update, 2)
Quadcopter = Periodic.create(Quadcopter_UpdateRate, Altitude_Control, 1)
GunshipAI = Periodic.create(AI_UpdateRate, GunshipAI_Update)

Control_Reset = ThreeDoF_Reset

function Update(I) -- luacheck: ignore 131
   if not I:IsDocked() then
      GetSelfInfo(I)

      if FirstRun then FirstRun(I) end

      Quadcopter:Tick(I)

      if ActivateWhen[I.AIMode] then
         GunshipAI:Tick(I)

         -- Suppress default AI
         I:TellAiThatWeAreTakingControl()
      else
         ThreeDoF_Reset()
      end

      SetAltitude(DesiredControlAltitude)
      ThreeDoFSpinner_Update(I)
      ThreeDoF_Update(I)

      MissileMain:Tick(I)
   else
      ThreeDoFSpinner_Disable(I)
   end

   ShieldManager:Tick(I)
end
