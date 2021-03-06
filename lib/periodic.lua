-- Periodic implementation
Periodic = {}

function Periodic.new(Period, Function, Start)
   local self = {}

   self.Ticks = Start and Start or Period
   self.Period = Period
   self.Function = Function

   if Period then
      self.Tick = Periodic.Tick
   else
      -- If Period is nil, Tick does nothing
      self.Tick = function (_, _) end
   end

   return self
end

function Periodic:Tick(I)
   local Ticks = self.Ticks
   Ticks = Ticks + 1
   if Ticks >= self.Period then
      self.Ticks = 0
      self.Function(I)
   else
      self.Ticks = Ticks
   end
end
