--@ dodgecommon
-- Dodge (yaw-only) module
if not DodgePreferFront then
   function Dodge_LastDodge()
      -- Turn toward opposite side, reverse if behind CoM
      -- Also return opposite of Y impact, since it might be useful for
      -- non-surface ships.
      return -45*LastDodgeDirection[1] * LastDodgeDirection[3],-LastDodgeDirection[2],true
   end
else
   function Dodge_LastDodge()
      -- Turn into the predicted impact point
      return 45*LastDodgeDirection[1],-LastDodgeDirection[2],true
   end
end

function Dodge_NoDodge()
   return 0,0,false
end
