local store = include("sim/units/store")
local mainframe_abilities = include("sim/abilities/mainframe_abilities")

local createProgramUnitData = store.createProgramUnitData
store.createProgramUnitData = function(abilityName, sim, ...)
	local unitData = createProgramUnitData(abilityName, sim, ...)
	local abilityDef = mainframe_abilities[abilityName]
	local onTooltip = unitData.onTooltip
	unitData.onTooltip = function(tooltip, unit, ...)
		onTooltip(tooltip, unit, ...)
		if abilityDef.dlcFooter then
			tooltip:addFooter(abilityDef.dlcFooter[1], abilityDef.dlcFooter[2])
		end
	end
	return unitData
end

-- only necessary when playing without function library - it already makes store.createStoreItems use the createProgramUnitData
-- from the store table instead of the local upvalue. it's fine, in that case we just don't find the upvalue and bail out.
local _, idx, subFn = upvalueUtil.find(store.createStoreItems, "createProgramUnitData", 5)
if idx then
	debug.setupvalue(subFn, idx, store.createProgramUnitData)
end