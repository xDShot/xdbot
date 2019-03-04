-- PRAISE FLOATS
local vec = Vector(12, 12, 0)
local ang = Angle()
print(vec:Angle()) -- Fucked up

vec = Vector(12, 12, 0.001)
print(vec:Angle()) -- Now correct

vec = Vector(65.001, 0.001, 199.001)
ang = vec:Angle()
ang:Normalize()
print(ang)
