-- A fake game adapter for the tracker: the same functions as Game/WowApi.lua, driven by
-- plain tables the tests fill in.

local FakeGame = {}

function FakeGame.New()
	local game = {
		now = 100,                 -- GetTime()
		epoch = 1800000000,        -- time()
		world = true,              -- IsWorldPvP()
		units = {},                -- unit -> { key, info, targetingMe }
		playerGUID = "Player-1-ME",
		petGUID = nil,
		byGUID = {},               -- guid -> PlayerInfoByGUID result
		group = {},                -- guid -> true for group members and their pets
		inCombat = false,          -- InCombat()
		recap = nil,               -- DeathRecap() result
		recapWhy = "unavailable",
		timers = {},
		context = { zone = "Los Baldíos", subZone = "El Cruce", mapID = 1413, x = 0.5, y = 0.5, myLevel = 30 },
	}

	function game.Now() return game.now end
	function game.Time() return game.epoch end
	function game.After(delay, callback) game.timers[#game.timers + 1] = { delay = delay, callback = callback } end
	function game.NewTicker() return {} end
	function game.IsWorldPvP() return game.world end
	function game.UnitExists(unit) return game.units[unit] ~= nil end
	function game.ReadEnemy(unit)
		local unitData = game.units[unit]
		if not unitData or unitData.friendly then
			return nil
		end
		local copy = {}
		for key, value in pairs(unitData.info or {}) do copy[key] = value end
		return unitData.key, copy
	end
	function game.IsTargetingPlayer(unit)
		return game.units[unit] ~= nil and game.units[unit].targetingMe == true
	end
	function game.OwnGUIDs() return game.playerGUID, game.petGUID end
	function game.IsGroupGUID(guid) return game.group[guid] == true end
	function game.InCombat() return game.inCombat end
	function game.PlayerInfoByGUID(guid) return game.byGUID[guid] end
	function game.CurrentContext()
		local context = { t = game.epoch }
		for key, value in pairs(game.context) do context[key] = value end
		return context
	end
	function game.DeathRecap()
		if game.recap then
			return game.recap
		end
		return nil, game.recapWhy
	end

	-- Test helpers ---------------------------------------------------------------------

	-- An enemy behind a unit token. info.guid is his GUID.
	function game.SetUnit(unit, key, info, targetingMe)
		game.units[unit] = { key = key, info = info, targetingMe = targetingMe }
	end

	-- Runs the pending timers (and the ones they queue).
	function game.RunTimers()
		while #game.timers > 0 do
			local timer = table.remove(game.timers, 1)
			game.now = game.now + timer.delay
			timer.callback()
		end
	end

	return game
end

return FakeGame
