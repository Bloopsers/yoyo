function init()
  self.buyFactor = config.getParameter("buyFactor", root.assetJson("/merchant.config").defaultBuyFactor)

  object.setInteractive(true)
end

function onInteraction(args)
  local interactData = config.getParameter("interactData")

  local paneLayout = root.assetJson("/interface/windowconfig/merchant.config:paneLayout")
  paneLayout.buySellTabs.tabs[1].children["featuredItem"] = {
    type = "image",
    file = "/objects/yoyomaster/star.png",
    position = {19, 196},
    zLevel = 10
  }
  paneLayout.buySellTabs.tabs[1].children["featuredText"] = {
    type = "label",
    value = "^gray;Featured",
    hAnchor = "right",
    position = {158, 205},
    zLevel = 10
  }
  paneLayout = sb.jsonMerge(paneLayout, interactData.paneLayoutOverride)
  interactData.paneLayoutOverride = paneLayout

  local storeInventory = config.getParameter("storeInventory")

  local featuredItems = storeInventory.timed

  local getFeaturedItem = function()
    local num = math.floor(os.time() / config.getParameter("rotationTime")) % #featuredItems + 1
    if featuredItems[num].universeFlag then
      if not world.universeFlagSet(featuredItems[num].universeFlag) then
        featuredItems[num] = nil
        getFeaturedItem()
      end
    end
    return storeInventory.timed[num]
  end

  table.insert(interactData.items, getFeaturedItem())

  for index,item in pairs(storeInventory.static) do 
    table.insert(interactData.items, item)
  end

  return { "OpenMerchantInterface", interactData }
end

function getFeaturedItem(featuredItems)
  local num = math.floor(os.time() / config.getParameter("rotationTime")) % featuredItems + 1
end

function buy()

end