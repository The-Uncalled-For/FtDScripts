--! faketdc
--@ commons periodic missiledriver faketdc
-- FakeTDC main

GuidanceInfos = {
   {
      Controller = FakeTDC.new(Config),
      MinAltitude = Limits.MinAltitude,
      MaxAltitude = Limits.MaxAltitude,
      MinRange = Limits.MinRange * Limits.MinRange,
      MaxRange = Limits.MaxRange * Limits.MaxRange,
      WeaponSlot = MissileWeaponSlot,
      TargetSelector = MissileTargetSelector,
   }
}

function SelectGuidance(_, _)
   return 1
end

-- Main update loop
function MissileMain_Update(I)
   MissileDriver_Update(I, GuidanceInfos, SelectGuidance)
end

MissileMain = Periodic.new(UpdateRate, MissileMain_Update)

function Update(I) -- luacheck: ignore 131
   C = Commons.new(I)
   if not C:IsDocked() then
      MissileMain:Tick(I)
   end
end
