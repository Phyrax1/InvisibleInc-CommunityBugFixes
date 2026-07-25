-- Additional escapeMission scripts
local cbf_util = include(SCRIPT_PATHS.qoala_commbugfix .. "/cbf_util")
local constants = include(SCRIPT_PATHS.qoala_commbugfix .. "/constants")
local simdefs = include("sim/simdefs")
local util = include("client_util")

local function UNIT_ENTERED_TILE_WITH_TAG(tag, unit)
	return {
		trigger = simdefs.TRG_UNIT_WARP,
		fn = function(sim, eventData)
			local eventunit = eventData.unit
			if unit == eventunit then
				if unit:getLocation() then
					local x1, y1 = unit:getLocation()
					local cell = sim:getCell(x1, y1)
					if sim:getQuery().cellHasTag(sim, cell, tag) then
						if not sim:isVersion("0.17.11") or not unit:isKO() then
							if not unit:getTraits().alerted then
								return true
							end
						end
					end
				end
			end
		end,
	}
end

local function initFoundPrisoner(sim)
    if sim:getParams().foundPrisoner == nil then
        local spawnAgentOption = cbf_util.simCheckFlag(sim, "cbf_detention_spawnagent")
        if spawnAgentOption == constants.MISSIONDETCENTER_SPAWNAGENT.FIRSTAGENT or spawnAgentOption ==
                constants.MISSIONDETCENTER_SPAWNAGENT.ALWAYS then
            -- First detention center should always have an agent.
            sim:getParams().foundPrisoner = true
        elseif spawnAgentOption == constants.MISSIONDETCENTER_SPAWNAGENT.FIFTYFIFTY then
            sim:getParams().foundPrisoner = false
        end
    end
end

local function init(scriptMgr, sim)
    initFoundPrisoner(sim)
    
	if sim:getParams().side_mission == "compile" then
		scriptMgr:addHook("CBF_compile_fix", function(script, sim)
			-- wait for the same trigger, but with a higher priority
			script:waitFor(util.extend(UNIT_ENTERED_TILE_WITH_TAG("scientistFinal", sim._scientist))({ priority = 10 }))
			local unit = sim._scientist
			if not unit:getBrain():getInterest() then
				local x0, y0 = sim:getCells("scientistFinal")[1]
				-- give him the interest again (spawnInterest also calls processReactions so it immediately updates the situation)
				unit:getBrain():spawnInterest(x0, y0, sim:getDefs().SENSE_DEBUG, sim:getDefs().REASON_NOTICED)
			end
		end)
	end
end

return {init = init}
