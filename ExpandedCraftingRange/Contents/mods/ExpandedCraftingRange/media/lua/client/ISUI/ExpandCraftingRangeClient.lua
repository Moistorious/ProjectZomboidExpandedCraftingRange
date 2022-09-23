require "IsBuildMenu"

ISBuildMenu.doBuildMenu = function(player, context, worldobjects, test)

	if test and ISWorldObjectContextMenu.Test then return true end

	if getCore():getGameMode()=="LastStand" then
		return;
	end

    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

	if playerObj:getVehicle() then return; end

    ISBuildMenu.woodWorkXp = playerObj:getPerkLevel(Perks.Woodwork);
    local thump = nil;

	local square = nil;

	-- destroy item with sledgehammer
	if not isClient() or getServerOptions():getBoolean("AllowDestructionBySledgehammer") then
        local sledgehammer = playerInv:getFirstTypeEvalRecurse("Sledgehammer", predicateNotBroken)
        if not sledgehammer then
            sledgehammer = playerInv:getFirstTypeEvalRecurse("Sledgehammer2", predicateNotBroken)
        end
		if sledgehammer and not sledgehammer:isBroken() then
			if test then return ISWorldObjectContextMenu.setTest() end
            context:addOption(getText("ContextMenu_Destroy"), worldobjects, ISWorldObjectContextMenu.onDestroy, playerObj, sledgehammer)
		end
	end

	-- we get the thumpable item (like wall/door/furniture etc.) if exist on the tile we right clicked
	for i,v in ipairs(worldobjects) do
		square = v:getSquare();
		if instanceof(v, "IsoThumpable") and not v:isDoor() then
			if not MultiStageBuilding.getStages(playerObj, v, ISBuildMenu.cheat):isEmpty() then
				thump = v
			end
		end
	end

	if thump then
        local stages = MultiStageBuilding.getStages(playerObj, thump, ISBuildMenu.cheat);
		if not stages:isEmpty() then
			for i=0,stages:size()-1 do
				local stage = stages:get(i);
				local option = context:addOption(stage:getDisplayName(), worldobjects, ISBuildMenu.onMultiStageBuild, stage, thump, player);
				local items = stage:getItemsLua();
				local perks = stage:getPerksLua();
				local tooltip = ISToolTip:new();
				tooltip:initialise();
				tooltip:setVisible(false);
				tooltip:setName(stage:getDisplayName());
				if ISBuildMenu.cheat then
					tooltip.description = "";
				else
					tooltip.description = getText("Tooltip_craft_Needs") .. ": ";
				end
				tooltip:setTexture(stage:getSprite());
				local notAvailable = false;
				if not ISBuildMenu.cheat then
					for x=0,stage:getItemsToKeep():size()-1 do
						local itemString = stage:getItemsToKeep():get(x);
                        if itemString == "Base.Hammer" then
                            local hammer = playerInv:getFirstTagEvalRecurse("Hammer", predicateNotBroken)
                            if hammer then
                                itemString = hammer:getFullType()
                            end
                        end
                        local item = ISBuildMenu.GetItemInstance(itemString);
                        if item then
                            if playerInv:containsTypeEvalRecurse(itemString, predicateNotBroken) then
                                tooltip.description = tooltip.description .. " <RGB:1,1,1> " .. item:getName() .. " <LINE> ";
                            else
                                tooltip.description = tooltip.description .. " <RGB:1,0,0> " .. item:getName() .. " <LINE> ";
                                notAvailable = true;
                            end
                        end
                    end
					tooltip.description = tooltip.description .. " <LINE> ";
					for x,v in pairs(items) do
                        local item = ISBuildMenu.GetItemInstance(x);
						if item then
							if instanceof(item, "DrainableComboItem") then
                                local drainable = playerInv:getFirstTypeEvalArgRecurse(x, predicateDrainableUsesInt, tonumber(v))
                                if not drainable then
                                    drainable = playerInv:getFirstTypeRecurse(x)
                                end
                                local useLeft = 0;
								if drainable and drainable:getDrainableUsesInt() >= tonumber(v) then
									useLeft = drainable:getDrainableUsesInt()
									tooltip.description = tooltip.description .. " <RGB:0,1,0> " .. item:getName() .. " " .. useLeft .. "/" .. v .. " <LINE> ";
								else
									if drainable then
										useLeft = drainable:getDrainableUsesInt()
									end
									tooltip.description = tooltip.description .. " <RGB:1,0,0> " .. item:getName() .. " " .. useLeft .. "/" .. v .. " <LINE> ";
									notAvailable = true;
								end
							else
								if ISBuildMenu.countMaterial(player, x) >= tonumber(v) then
									tooltip.description = tooltip.description .. " <RGB:0,1,0> " .. item:getName() .. " " .. playerInv:getItemCount(x) .. "/" .. v .. " <LINE> ";
								else
									tooltip.description = tooltip.description .. " <RGB:1,0,0> " .. item:getName() .. " " .. playerInv:getItemCount(x) .. "/" .. v .. " <LINE> ";
									notAvailable = true;
								end
							end
						end
					end
					tooltip.description = tooltip.description .. " <LINE> ";
					for x,v in pairs(perks) do
						local perk = PerkFactory.getPerk(x);
						if playerObj:getPerkLevel(x) >= tonumber(v) then
							tooltip.description = tooltip.description .. " <RGB:0,1,0> " .. getText("IGUI_perks_" .. perk:getType():toString()) .. " " .. playerObj:getPerkLevel(x) .. "/" ..  v .. " <LINE>";
						else
							tooltip.description = tooltip.description .. " <RGB:1,0,0> " .. getText("IGUI_perks_" .. perk:getType():toString()) .. " " .. playerObj:getPerkLevel(x) .. "/" ..  v .. " <LINE>";
							notAvailable = true;
						end
					end
					local knownRecipe = stage:getKnownRecipe()
					if knownRecipe then
						tooltip.description = tooltip.description .. " <LINE> "
						if playerObj:getKnownRecipes():contains(stage:getKnownRecipe()) then
							tooltip.description = tooltip.description .. " <RGB:0,1,0> " .. getText("Tooltip_vehicle_requireRecipe", getRecipeDisplayName(knownRecipe)) .. " <LINE>"
						else
							tooltip.description = tooltip.description .. " <RGB:1,0,0> " .. getText("Tooltip_vehicle_requireRecipe", getRecipeDisplayName(knownRecipe)) .. " <LINE>"
							notAvailable = true
						end
					end
					option.notAvailable = notAvailable;
				end
				option.toolTip = tooltip;
			end
		end
	end

	-- build menu
	-- if we have any thing to build in our inventory
	if ISBuildMenu.haveSomethingtoBuild(player) then

		if test then return ISWorldObjectContextMenu.setTest() end

		local buildOption = context:addOption(getText("ContextMenu_Build"), worldobjects, nil);
		-- create a brand new context menu wich contain our different material (wood, stone etc.) to build
		local subMenu = ISContextMenu:getNew(context);
		-- We create the different option for this new menu (wood, stone etc.)
		-- check if we can build something in wood material
		if haveSomethingtoBuildWood(player) then
			-- we add the subMenu to our current option (Build)
			context:addSubMenu(buildOption, subMenu);

			------------------ WALL ------------------
			local wallOption = subMenu:addOption(getText("ContextMenu_Wall"), worldobjects, nil);
			local subMenuWall = subMenu:getNew(subMenu);
			context:addSubMenu(wallOption, subMenuWall);
			ISBuildMenu.buildWallMenu(subMenuWall, wallOption, player);
			------------------ FENCE ------------------
			local fenceOption = subMenu:addOption(getText("ContextMenu_Fence"), worldobjects, nil);
			local subMenuFence = subMenu:getNew(subMenu);
			context:addSubMenu(fenceOption, subMenuFence);
			ISBuildMenu.buildFenceMenu(subMenuFence, fenceOption, player);
			------------------ DOOR/GATE ------------------
			local doorOption = subMenu:addOption(getText("ContextMenu_DoorGate"), worldobjects, nil);
			local subMenuDoor = subMenu:getNew(subMenu);
			context:addSubMenu(doorOption, subMenuDoor);
			ISBuildMenu.buildDoorMenu(subMenuDoor, doorOption, player);
			------------------ WINDOW ------------------
--			local windowOption = subMenu:addOption(getText("ContextMenu_Window"), worldobjects, nil);
--			local subMenuWindow = subMenu:getNew(subMenu);
--			context:addSubMenu(windowOption, subMenuWindow);
--			ISBuildMenu.buildWindowMenu(subMenuWindow, windowOption, player);
			------------------ STAIRS ------------------
			local stairsOption = subMenu:addOption(getText("ContextMenu_Stairs"), worldobjects, nil);
			local subMenuStairs = subMenu:getNew(subMenu);
			context:addSubMenu(stairsOption, subMenuStairs);
			ISBuildMenu.buildStairsMenu(subMenuStairs, stairsOption, player);
			------------------ FLOOR ------------------
			local floorOption = subMenu:addOption(getText("ContextMenu_Floor"), worldobjects, nil);
			local subMenuFloor = subMenu:getNew(subMenu);
			context:addSubMenu(floorOption, subMenuFloor);
			ISBuildMenu.buildBetterFloorMenu(subMenuFloor, floorOption, player);
			------------------ FURNITURE ------------------
			local furnitureOption = subMenu:addOption(getText("ContextMenu_Furniture"), worldobjects, nil);
			local subMenuFurniture = subMenu:getNew(subMenu);
			context:addSubMenu(furnitureOption, subMenuFurniture);
			ISBuildMenu.buildFurnitureMenu(subMenuFurniture, context, furnitureOption, player);
			------------------ LIGHT SOURCES ------------------
			local lightOption = subMenu:addOption(getText("ContextMenu_Light_Source"), worldobjects, nil);
			local subMenuLight = subMenu:getNew(subMenu);
			context:addSubMenu(lightOption, subMenuLight);
			ISBuildMenu.buildLightMenu(subMenuLight, lightOption, player);
			------------------ MISC ------------------
			local miscOption = subMenu:addOption(getText("ContextMenu_Misc"), worldobjects, nil);
			local subMenuMisc = subMenu:getNew(subMenu);
			context:addSubMenu(miscOption, subMenuMisc);
			ISBuildMenu.buildMiscMenu(subMenuMisc, miscOption, player);
		end
	end

	-- dismantle stuff
	-- TODO: RJ: removed it for now need to see exactly how it works as now we have a proper right click to dismantle items...
	-- if playerInv:containsTypeRecurse("Saw") and playerInv:containsTypeRecurse("Screwdriver") then
	--  	if test then return ISWorldObjectContextMenu.setTest() end
	--  	context:addOption(getText("ContextMenu_Dismantle"), worldobjects, ISBuildMenu.onDismantle, playerObj);
	-- end



end