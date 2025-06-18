function SetFlat()
% Sets all DM actuators to a flat map indefinitely

actuators = 1:140;
vals = zeros(140, 1);
flat = MakeShape([actuators' vals]);
SetShape(flat, 0)
end

