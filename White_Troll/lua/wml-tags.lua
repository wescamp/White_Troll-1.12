local helper = wesnoth.require "lua/helper.lua"
local wml_actions = wesnoth.wml_actions

function wml_actions.whisper( cfg )
	local cfg = cfg.__literal
	cfg.message = string.format ( "<small><i>%s</i></small>", tostring( cfg.message ) )
	wml_actions.message( cfg )
end

function wml_actions.get_side_recalls_worth( cfg )
	-- this tag allows calculating the strenght of a player side, by converting its recallable units
	-- and summons in gold. It does not take leaders and already recalled units in account.
	-- Usage:
	--[get_side_recalls_worth]
        --	side=1 # or a StandardSideFilter
        --	variable=side_1_worth
        --[/get_side_recalls_worth]

	-- acquire side
	local side = wesnoth.get_sides( cfg )[1] or helper.wml_error "[get_side_recalls_worth]'s filter didn't match any side"
	local variable = cfg.variable or helper.wml_error "[get_side_recalls_worth] missing required variable= attribute"
	-- acquire its recall list
	local recall_list = wesnoth.get_recall_units( { side = side.side } )
	-- get its gold
	local gold = side.gold
	-- sort recall list
	-- criteria: higher level, then higher cost
	local function compare( unit1, unit2 )
		return unit1.__cfg.level > unit2.__cfg.level or ( unit1.__cfg.level == unit2.__cfg.level and unit1.__cfg.cost > unit2.__cfg.cost )
	end
	
	table.sort( recall_list, compare )
	
	local worth = 0
	
	for index, unit in ipairs( recall_list ) do
		-- if a side cannot recall more unit, exit
		if gold < side.__cfg.recall_cost then break end
		-- if a unit costs less than the recall fee, exit
		if unit.__cfg.cost < side.__cfg.recall_cost then break end
		
		worth = worth + unit.__cfg.cost
		gold = gold - side.__cfg.recall_cost
	end
	worth = worth + gold
	
	-- handle summoners
	local summoners = wesnoth.get_units( { side = side.side, { 'and', { ability = 'summon_melime', { 'or', { ability = 'summon_eruannon' } } } } })
	for index, unit in ipairs( summoners ) do
		local mana = unit.variables.mana
		-- currently our summons are:
		-- Mudcrawler, 3 mana, 5 gold
		-- Animated Rock, 5 mana, 17 gold
		-- Giant Ant, 5 mana, 12 gold
		-- Spaling Wose, 5 mana, 10 gold
		-- I'll assume 10 gold for all of them
		local summons = math.floor( mana / 5 )
		local summons_worth = summons * 10
		worth = worth + summons_worth
	end
	
	wesnoth.set_variable( variable, worth )
end
