local entity_names = {
  "steam-engine",
  "steam-turbine",
  "accumulator",
  "electric-furnace",
  "electric-mining-drill",
  "radar",
  "assembling-machine-1",
  "assembling-machine-2",
  "assembling-machine-3",
  "lab",
  "solar-panel",
  "nuclear-reactor",
  "inserter",
  "fast-inserter",
  "express-inserter",
  "long-handed-inserter",
  "filter-inserter",
  "stack-inserter",
  "stack-filter-inserter"
}
  
function has_value (tab, val)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

script.on_event(defines.events.on_built_entity, function(event)
  -- game.print(event.created_entity.name)
  onBuildHandler(event.created_entity) 
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
  onBuildHandler(event.created_entity) 
end)

script.on_configuration_changed(function(data)
  local destroyed_poles = 0
  local added_poles = 0
  for i, surface in pairs (game.surfaces) do
    local pole_entities = surface.find_entities_filtered{name='ci-pole'}
    if pole_entities then
      -- game.print ('pole_entities '..#pole_entities)
      for j, pole_entity in pairs (pole_entities) do
        if surface.count_entities_filtered{name=entity_names, position = pole_entity.position, limit = 1} == 0 then
          destroyed_poles = destroyed_poles + 1
          pole_entity.destroy()
        end
      end
    end
    local entities = surface.find_entities_filtered{name=entity_names}
    if entities then
      -- game.print ('entities '..#entities)
      for j, entity in pairs (entities) do
        if surface.count_entities_filtered{name='ci-pole', area=entity.bounding_box, limit = 1} == 0 then
          -- game.print ('adding poles to '..entity.name)
          added_poles = added_poles + 1
          spam_poles (entity)
        end
      end
    end
  end
  if (added_poles+destroyed_poles) > 0 then
    game.print ('SS migration: added poles to '..added_poles..' entities, removed '..destroyed_poles..' poles without entities')
  end
end)


function spam_poles (entity)
  local area = entity.bounding_box
  -- game.print (serpent.line (area))
  local is_placed = false
  local lt_x = math.floor(area.left_top.x)+0.5
  local lt_y = math.floor(area.left_top.y)+0.5
  local rb_x = math.ceil(area.right_bottom.x)-0.5
  local rb_y = math.ceil(area.right_bottom.y)-0.5
  for y = lt_y, rb_y do
    for x = lt_x, rb_x do
      if y == lt_y or y == rb_y or x == lt_x or x == rb_x then 
        entity.surface.create_entity{name = 'ci-pole', position = {x=x, y=y}, force = entity.force}
        is_placed = true
        -- game.print ('x='..x..' y='..y)
      end
    end
  end
  if not is_placed then
    surface.create_entity{name = 'ci-pole', position = entity.position, force = entity.force}
  end
end

function onBuildHandler(entity) 
  if has_value (entity_names, entity.name) then
    spam_poles (entity)
  end
end

script.on_event(defines.events.on_pre_player_mined_item, function(event)
  onMinedHandler(event.entity) 
end)

script.on_event(defines.events.on_robot_pre_mined, function(event)
  onMinedHandler(event.entity) 
end)

function onMinedHandler(entity) 
  if has_value (entity_names, entity.name) then
    local surface = entity.surface
    local position = entity.position
    -- game.print ('position: '.. serpent.line (position))
    local pole_entity = surface.find_entity('ci-pole', position)
    if pole_entity then 
      -- game.print ('b position: '.. serpent.line (pole_entity.position))
      pole_entity.destroy()
    else
      local pole_entities = surface.find_entities_filtered({name = 'ci-pole', area = entity.bounding_box})
      if pole_entities then
        -- game.print ('amount: '.. (#pole_entities))
        for i, pole in pairs (pole_entities) do
          -- game.print ('c position: '.. serpent.line (pole.position))
          pole.destroy()
        end
      end
    end
  end
end
