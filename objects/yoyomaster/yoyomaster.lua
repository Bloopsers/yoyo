require "/scripts/util.lua"

function init()
  self.buyFactor = config.getParameter("buyFactor", root.assetJson("/merchant.config").defaultBuyFactor)

  object.setInteractive(true)
end

function onInteraction(args)
  local interactData = config.getParameter("interactData")

  local paneLayout = root.assetJson("/interface/windowconfig/merchant.config:paneLayout")
  paneLayout = sb.jsonMerge(paneLayout, interactData.paneLayoutOverride)
  interactData.paneLayoutOverride = paneLayout

  local storeInventory = config.getParameter("storeInventory")

  local timedRandom = function(max) return math.floor(os.time() / config.getParameter("rotationTime")) % max + 1 end

  local getItems = function(pool)
    local items = {}
    for i,group in ipairs(pool) do
      math.randomseed(timedRandom(#group.items))
      for i=1, group.roll do
        table.insert(items, group.items[math.random(#group.items)]) 
      end
    end
    return items
  end

  for i,item in ipairs(getItems(storeInventory.timed)) do
    table.insert(interactData.items, item)
  end

  for index,item in ipairs(storeInventory.static) do 
    table.insert(interactData.items, item)
  end

  return { "OpenMerchantInterface", interactData }
end