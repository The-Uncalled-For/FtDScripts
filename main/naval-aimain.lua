--! naval-ai
--@ commons firstrun periodic
--@ sixdof ytdefaults naval-ai
NavalAI = Periodic.create(UpdateRate, NavalAI_Update)

Control_Reset = SixDoF_Reset

function Update(I) -- luacheck: ignore 131
   C = Commons.create(I)
   if FirstRun then FirstRun(I) end
   if not C:IsDocked() then
      if ActivateWhen[I.AIMode] then
         NavalAI:Tick(I)

         -- Suppress default AI
         I:TellAiThatWeAreTakingControl()
      else
         NavalAI_Reset()
         SixDoF_Reset()
      end

      SixDoF_Update(I)
   else
      NavalAI_Reset()
      SixDoF_Disable(I)
   end
end
