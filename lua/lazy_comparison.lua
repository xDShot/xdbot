local function LZCMP( wanted )
	print( "Lazy Comparing", wanted )
	return wanted == 3
end

if LZCMP( 1 ) or LZCMP( 2 ) or LZCMP( 3 ) or LZCMP( 4 ) or LZCMP( 5 ) or LZCMP( 6 ) then
	print( "AHAHAHAHA GOTCHA" )
end

--[[
Lazy Comparing	1
Lazy Comparing	2
Lazy Comparing	3
AHAHAHAHA GOTCHA
]]--
