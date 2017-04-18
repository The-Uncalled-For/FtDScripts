--! warship
--@ commons firstrun periodic
--@ shieldmanager dualprofile sixdof ytdefaults naval-ai
-- Warship main
ShieldManager = Periodic.create(ShieldManager_UpdateRate, ShieldManager_Control, 2)
MissileMain = Periodic.create(Missile_UpdateRate, MissileMain_Update, 1)
NavalAI = Periodic.create(AI_UpdateRate, NavalAI_Update)

Control_Reset = SixDoF_Reset

function Update(I) -- luacheck: ignore 131
   C = Commons.create(I)
   if FirstRun then FirstRun(I) end
   if not C:IsDocked() then
      if ActivateWhen[I.AIMode] then
         NavalAI:Tick(I)

         -- Suppress default AI
         I:TellAiThatWeAreTakingControl()

         SixDoF_Update(I)
      else
         NavalAI_Reset()
      end

      MissileMain:Tick(I)
   else
      NavalAI_Reset()
      SixDoF_Disable(I)
   end

   ShieldManager:Tick(I)
end
