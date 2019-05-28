function is_target(candidate)
  return candidate.electric_output_flow_limit ~= nil
end

function target_entities(surface) 
  local entities = {}
  for _, v in pairs(surface.find_entities()) do
    if is_target(v) then
      table.insert(entities, v)
    end
  end
  return entities
end

function exist_target_entities(surface) 
  for _, v in pairs(surface.find_entities()) do
    if is_target(v) then
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
  for _, surface in pairs (game.surfaces) do
    local pole_entities = surface.find_entities_filtered{name='tf-pole'}
    if pole_entities then
      -- game.print ('pole_entities '..#pole_entities)
      for _, pole_entity in pairs (pole_entities) do
        if not exist_target_entities(surface) then -- FIXME: Search the entity at the position of pole_entity instead of whole surface.
          destroyed_poles = destroyed_poles + 1
          pole_entity.destroy()
        end
      end
    end
    local entities = target_entities(surface)
    if entities then
      -- game.print ('entities '..#entities)
      for _, entity in pairs (entities) do
        if surface.count_entities_filtered{name='tf-pole', area=entity.bounding_box, limit = 1} == 0 then
          -- game.print ('adding poles to '..entity.name)
          added_poles = added_poles + 1
          spam_poles (entity)
        end
      end
    end
  end
  if (added_poles+destroyed_poles) > 0 then
    -- game.print ('TF migration: added poles to '..added_poles..' entities, removed '..destroyed_poles..' poles without entities')
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
        entity.surface.create_entity{name = 'tf-pole', position = {x=x, y=y}, force = entity.force}
        is_placed = true
        -- game.print ('x='..x..' y='..y)
      end
    end
  end
  if not is_placed then
    surface.create_entity{name = 'tf-pole', position = entity.position, force = entity.force}
  end
end

function onBuildHandler(entity) 
  if is_target(entity) then
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
  if is_target(entity) then
    local surface = entity.surface
    local position = entity.position
    -- game.print ('position: '.. serpent.line (position))
    local pole_entity = surface.find_entity('tf-pole', position)
    if pole_entity then 
      -- game.print ('b position: '.. serpent.line (pole_entity.position))
      pole_entity.destroy()
    else
      local pole_entities = surface.find_entities_filtered({name = 'tf-pole', area = entity.bounding_box})
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
