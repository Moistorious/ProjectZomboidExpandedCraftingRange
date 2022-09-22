require "IsBuildUtil"

function buildUtil.getMaterialOnGround(squareToCheck)
	local result = {}
	for x=squareToCheck:getX()-10,squareToCheck:getX()+10 do
		for y=squareToCheck:getY()-10,squareToCheck:getY()+10 do
			local square = getCell():getGridSquare(x,y,squareToCheck:getZ())
			local wobs = square and square:getWorldObjects() or nil
			if wobs ~= nil then
				for i = 1,wobs:size() do
					local obj = wobs:get(i-1)
					local item = obj:getItem()
					if buildUtil.predicateMaterial(item) then
						local items = result[item:getFullType()] or {}
						table.insert(items, item)
						result[item:getFullType()] = items
						result[item:getType()] = items
					end
				end
			end
		end
	end
	return result
end
