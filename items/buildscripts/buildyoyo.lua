require "/scripts/util.lua"
require "/scripts/staticrandom.lua"

function build(directory, config, parameters, level, seed)
    local configDefaults = root.assetJson("/items/active/weapons/yoyos/yoyodefaults.config")
    config = sb.jsonMerge(configDefaults, config)

    configParameter = function(keyName, defaultValue)
        if parameters[keyName] ~= nil then
            return parameters[keyName]
        elseif config[keyName] ~= nil then
            return config[keyName]
        else
            return defaultValue
        end
    end

    --Update old yoyo configs to the new format (so existing mods don't need to update)
    updateToNewFormat(config)
    
    --Generated weapon stuff
    if configParameter("generated", false) == true then
        if level and not configParameter("fixedLevel", false) then
            parameters.level = level
        end

        -- initialize randomization
        if seed then
            parameters.seed = seed
        else
            seed = configParameter("seed")
            if not seed then
                math.randomseed(util.seedTime())
                seed = math.random(1, 4294967295)
                parameters.seed = seed
            end
        end

        local builderConfig = config.builderConfig

        if not parameters.elementalType and builderConfig.elementalType then
            parameters.elementalType = randomFromList(
                                           builderConfig.elementalType, seed,
                                           "elementalType")
        end
        elementalType = configParameter("elementalType", "physical")

        if not parameters.company then
            parameters.company = randomFromList(builderConfig.companies, seed,
                                                "companies")
        end

        if not parameters.shortdescription and builderConfig.nameGenerator then
            parameters.shortdescription =
                parameters.company .. " " ..
                    root.generateName(util.absolutePath(directory,
                                                        builderConfig.nameGenerator),
                                      seed)
        end

        config.paletteSwaps = ""
        if builderConfig.palette then
            local palette = root.assetJson(
                                util.absolutePath(directory,
                                                  builderConfig.palette))
            local selectedSwaps = randomFromList(palette.swaps, seed,
                                                 "paletteSwaps")
            for k, v in pairs(selectedSwaps) do
                config.paletteSwaps = string.format("%s?replace=%s=%s",
                                                    config.paletteSwaps, k, v)
            end
        end

        if builderConfig.animationCustom then
            util.mergeTable(config.animationCustom or {},
                            builderConfig.animationCustom)
        end

        parameters.projectileParameters = parameters.projectileParameters or {}

        config.projectileParameters.power =
            randomInRange(config.projectileParameters.power, seed, "power")
        config.projectileParameters.knockback =
            randomInRange(config.projectileParameters.power, seed, "knockback")
        config.projectileParameters.damageRepeatTimeout =
            randomInRange(config.projectileParameters.damageRepeatTimeout, seed,
                          "damageRepeatTimeout")
        config.projectileParameters.yoyoSpeed =
            randomInRange(config.projectileParameters.yoyoSpeed, seed,
                          "yoyoSpeed")
        config.projectileParameters.maxYoyoTime =
            randomInRange(config.projectileParameters.maxYoyoTime, seed,
                          "maxYoyoTime")

        config.maxLength = randomIntInRange(config.maxLength, seed,
                                            "maxYoyoTime")

        if builderConfig.animationParts then
            config.animationParts = config.animationParts or {}
            config.iconAnimationParts = config.iconAnimationParts or {}
            if parameters.animationPartVariants == nil then
                parameters.animationPartVariants = {}
            end
            for k, v in pairs(builderConfig.animationParts) do
                if type(v) == "table" then
                    if v.variants and
                        (not parameters.animationPartVariants[k] or
                            parameters.animationPartVariants[k] > v.variants) then
                        parameters.animationPartVariants[k] =
                            randomIntInRange({1, v.variants}, seed,
                                             "animationPart" .. k)
                    end
                    config.animationParts[k] =
                        util.absolutePath(directory,
                                          string.gsub(v.projectilePath,
                                                      "<variant>",
                                                      parameters.animationPartVariants[k] or
                                                          ""))
                    config.iconAnimationParts[k] =
                        util.absolutePath(directory, string.gsub(v.iconPath,
                                                                 "<variant>",
                                                                 parameters.animationPartVariants[k] or
                                                                     ""))
                    config.animationParts[k] =
                        string.gsub(config.animationParts[k], "<company>",
                                    parameters.company or "")
                    config.iconAnimationParts[k] =
                        string.gsub(config.iconAnimationParts[k], "<company>",
                                    parameters.company or "")
                    if v.paletteSwap then
                        config.animationParts[k] =
                            config.animationParts[k] .. config.paletteSwaps
                        config.iconAnimationParts[k] =
                            config.iconAnimationParts[k] .. config.paletteSwaps
                        config.projectileParameters.yoyoImage =
                            config.animationParts[builderConfig.yoyoProjectilePart] ..
                                config.paletteSwaps
                    end
                    yoyoProjectileImage =
                        config.animationParts[builderConfig.yoyoProjectilePart]
                else
                    config.animationParts[k] = v
                end
            end
        end

        if builderConfig.counterweights then
            --table.insert(config.counterweights, randomFromList(builderConfig.counterweights, seed, "counterweights"))
        end

        local periodicActions = {}

        table.insert(periodicActions, {
            action = "particle",
            time = 0.006,
            ["repeat"] = true,
            rotate = true,
            specification = {
                type = "textured",
                image = yoyoProjectileImage,
                timeToLive = 0.007,
                layer = "front",
                flippable = true
            }
        })

        config.projectileParameters.periodicActions = periodicActions

        if not config.inventoryIcon and config.iconAnimationParts then
            config.inventoryIcon = jarray()
            local parts = builderConfig.iconDrawables or {}
            for _, partName in pairs(parts) do
                local drawable = {
                    image = config.iconAnimationParts[partName] ..
                        config.paletteSwaps
                }
                table.insert(config.inventoryIcon, drawable)
            end
        end

        config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))
    end
    --End generated code

    local configParameters = sb.jsonMerge(config, parameters)
    local yoyoConfig = configParameter("yoyoConfig")
    local yoyoUpgrades = configParameter("yoyoUpgrades")

    --Check invalid parameters
    --Make sure the class is light, heavy or trick (and use heavy as a default)
    yoyoConfig.class = getOrDefault(yoyoConfig, "class", "heavy", {"light", "heavy", "trick"})

    config.twoHanded = yoyoConfig.class ~= "light"

    --Populate tooltip fields
    config.tooltipFields = {}
    config.tooltipFields.lengthLabel = string.format("%s (+%s)", configParameters.maxLength, configParameters.extraLength)

    local power = configParameters.projectileParameters.power * root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))
    config.tooltipFields.damageLabel = util.round(power, 1)

    local elementalType = configParameter("elementalType", "physical")
    if elementalType ~= "physical" then
        config.tooltipFields.damageKindImage = "/interface/elements/" .. elementalType .. ".png"
    end

    --Adding string image to icon
    local stringImage = configParameter("stringImage", "/items/active/weapons/yoyos/string.png")
    local stringOffset = configParameter("stringOffset", {0, 0})

    if parameters.inventoryIcon and type(parameters.inventoryIcon) == "table" then
        parameters.inventoryIcon = parameters.inventoryIcon[1].image
    end

    local iconBase = configParameter("inventoryIcon", "/assetmissing.png")
    local newIcon = {}
    table.insert(newIcon, {image = (type(iconBase) == "table" and iconBase[1] or iconBase)})
    table.insert(newIcon, {image = stringImage .. configParameters.stringColor, offset = stringOffset})

    if parameters.inventoryIcon then
        parameters.inventoryIcon = newIcon
    else
        config.inventoryIcon = newIcon
    end

    --Time label (currently unused)
    local time = configParameters.projectileParameters.maxYoyoTime
    if time and time >= 100 then time = "Infinite" end
    config.tooltipFields.durationLabel = tostring(time)

    --Counterweight label
    config.tooltipFields.counterWeightIconImage = getOrDefault(configParameters, "counterWeightIcon", "/interface/tooltips/counterweightbase.png")
    config.tooltipFields.counterWeightNameLabel = getOrDefault(configParameters, "counterWeightName", "^gray;No Counterweight")

    -- config.tooltipFields.stringIconImage = configParameters.currentStringIcon
    -- config.tooltipFields.stringNameLabel = configParameters.currentStringName

    return config, parameters
end

function getOrDefault(table, key, defaultValue, allowedValues)
    if table[key] ~= nil then
        local value = table[key]

        --Empty strings are considered null
        if type(value) == "string" and string.len(value) <= 0 then
            return defaultValue
        end

        if allowedValues then
            if not contains(allowedValues, value) then
                return defaultValue
            end
        end

        return value
    end
    return defaultValue
end

function updateToNewFormat(config)
    config.yoyoConfig = {
        class = "heavy",
        projectileType = configParameter("projectileType", nil),
        projectileParameters = configParameter("projectileParameters", {}),
        usesYoyoUpgrades = configParameter("usesYoyoUpgrades", true),
        usesCounterweightUpgrades = configParameter("usesCounterweightUpgrades", ""),
        rope = configParameter("rope", {
            color = {202, 202, 202, 230},
            width = 0.8
        })
    }
    config.yoyoUpgrades = {
        counterweights = configParameter("counterweights", {}),
        extraLength = configParameter("extraLength", 0),
        currentStringType = configParameter("currentStringType", ""),
        stringColor = configParameter("stringColor", ""),
        counterWeightType = configParameter("counterWeightType", ""),
        counterWeightIcon = configParameter("counterWeightIcon", ""),
        counterWeightName = configParameter("counterWeightName", "")
    }
end
