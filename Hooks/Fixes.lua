if not Global.editor_mode then
	return
end

local F = table.remove(RequiredScript:split("/"))
local UnitIds = Idstring("unit")

local civ = F == "elementspawncivilian"
if F == "coreelementarea" then
	core:module("CoreElementArea")
	function ElementAreaTrigger:init(...)
		ElementAreaTrigger.super.init(self, ...)

		self._last_project_amount_all = 0
		self:_finalize_values()
	end
	function ElementAreaTrigger:_finalize_values()
		if self._shapes then
			for _, shape in pairs(self._shapes) do
				shape:destroy()
			end
		end
		self._shapes = {}
		self._shape_elements = {}
		self._rules_elements = {}
		if not self._values.use_shape_element_ids then
			if not self._values.shape_type or self._values.shape_type == "box" then
				self:_add_shape(CoreShapeManager.ShapeBoxMiddle:new({
					position = self._values.position,
					rotation = self._values.rotation,
					width = self._values.width,
					depth = self._values.depth,
					height = self._values.height
				}))
			elseif self._values.shape_type == "cylinder" then
				self:_add_shape(CoreShapeManager.ShapeCylinderMiddle:new({
					position = self._values.position,
					rotation = self._values.rotation,
					height = self._values.height,
					radius = self._values.radius
				}))
			elseif self._values.shape_type == "sphere" then
				self:_add_shape(CoreShapeManager.ShapeSphere:new({
					position = self._values.position,
					rotation = self._values.rotation,
					height = self._values.height,
					radius = self._values.radius
				}))
			end
		end
		self._inside = {}
	end
elseif civ or F == "elementspawnenemydummy" then
	local C = civ and ElementSpawnCivilian or ElementSpawnEnemyDummy
	--Makes sure unit path is updated.
	Hooks:PostHook(C, "_finalize_values", "EditorFinalizeValues", function(self)
		if self._values.enemy then
			self._enemy_name = self._values.enemy and Idstring(self._values.enemy) or nil
		end
		if not self._enemy_name then
			if civ then
				self._enemy_name = Idstring("units/characters/civilians/dummy_civilian_1/dummy_civilian_1")
			else
				self._enemy_name = Idstring("units/payday2/characters/ene_swat_1/ene_swat_1")
			end
		end 
	end)
	--Makes sure element doesn't crash in editor.
	local orig = C.produce
	function C:produce(params, ...)
		local enemy = self._enemy_name or self:value("enemy")
		if (not params or not params.name) and (not enemy or not PackageManager:has(UnitIds, enemy:id())) then
			return
		end
		return orig(self, params, ...)
	end
elseif F == "levelstweakdata" then
	Hooks:PostHook(LevelsTweakData, "init", "BLEInstanceFix", function(self)
		if BeardLib.current_level and Global.editor_loaded_instance then
			local instance = BeardLib.current_level
			local id = Global.game_settings.level_id
			self[id] = table.merge(clone(instance._config), {
				name_id = "none",
				briefing_id = "none",
				world_name = instance._levels_less_path,
				ai_group_type = self.ai_groups.default,
				intro_event = "nothing",
				outro_event = "nothing",
				custom = true
			})
		end
	end)
elseif F == "jobmanager" then
	function JobManager:current_mission_filter()
		if not self._global.current_job then
			return
		end
		return {Global.current_mission_filter} or self:current_stage_data().mission_filter
	end
end