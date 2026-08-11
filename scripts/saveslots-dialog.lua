local dialog = include("fe/saveslots-dialog")
local util = include("modules/util")
local metrics = include("metrics")
local serverdefs = include("modules/serverdefs")
local version = include("modules/version")
local simdefs = include("sim/simdefs")

local oldContinueCampaign, idx, subFn = upvalueUtil.find(dialog.init, "continueCampaign", 10)
if idx then
	local function continueCampaign(dialog, campaign, ...)
		-- check if there is a pending situation that still hasn't been removed from the campaign events, even though situation is nil
		if campaign.situation == nil and campaign.cbf_pendingSituation and campaign.campaignEvents then
			local found = false
			for i, event in ipairs(campaign.campaignEvents) do
				if
					event.eventType == simdefs.CAMPAIGN_EVENTS.GOTO_MISSION
					and campaign.cbf_pendingSituation.prevMissionName == event.mission
				then
					found = true
					campaign.cbf_pendingSituation.prevMissionName = nil
					table.remove(campaign.campaignEvents, i)
					break
				end
			end
			if found then
				local user = savefiles.getCurrentGame()
				user.data.saveSlots[user.data.currentSaveSlot] = campaign

				user.data.num_games = (user.data.num_games or 0) + 1
				campaign.recent_build_number = util.formatGameInfo()
				campaign.missionVersion = version.VERSION

				campaign.situation = campaign.cbf_pendingSituation
				campaign.cbf_pendingSituation = nil
				campaign.preMissionNetWorth = serverdefs.CalculateNetWorth(campaign)

				if not user.data.saveScumLevelSlots then
					user.data.saveScumLevelSlots = {}
				end

				user.data.saveScumLevelSlots[user.data.currentSaveSlot] =
					util.tcopy(user.data.saveSlots[user.data.currentSaveSlot])
				user:save()
				metrics.app_metrics:incStat("new_games")
			end
		end
		oldContinueCampaign(dialog, campaign, ...)
	end
	debug.setupvalue(subFn, idx, continueCampaign)
end
