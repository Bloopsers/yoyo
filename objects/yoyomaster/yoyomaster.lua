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

  local timedSeed = function() return math.floor(os.time() / config.getParameter("rotationTime")) end

  local getItem = function(pool)
    local item = pool.items[math.random(#pool.items)]
    while contains(interactData.items, item) do
      item = pool.items[math.random(#pool.items)]
    end
    return item
  end

  math.randomseed(timedSeed())

  for i,pool in ipairs(storeInventory.timed) do
    for roll = 1, pool.roll do
      table.insert(interactData.items, getItem(pool))
    end
  end

  for index,item in ipairs(storeInventory.static) do 
    table.insert(interactData.items, item)
  end

  return { "OpenMerchantInterface", interactData }
end