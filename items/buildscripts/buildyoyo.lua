require "/scripts/util.lua"
require "/scripts/staticrandom.lua"

function build(directory, config, parameters, level, seed)
    configParameter = function(keyName, defaultValue)
        if parameters[keyName] ~= nil then
            return parameters[keyName]
        elseif config[keyName] ~= nil then
            return config[keyName]
        else
            return defaultValue
        end
    end

    config.tooltipFields = {}

    self.yoyoTypes = {"light", "heavy"}
    local yoyoType = configParameter("yoyoType", "light")

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
            table.insert(config.counterweights, randomFromList(
                             builderConfig.counterweights, seed,
                             "counterweights"))
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

        config.price = (config.price or 0) *
                           root.evalFunction("itemLevelPriceMultiplier",
                                             configParameter("level", 1))
    end

    local params = sb.jsonMerge(config, parameters)

    config.tooltipFields.lengthLabel = string.format("%s (+%s)",
                                                     params.maxLength,
                                                     params.extraLength)

    local power = params.projectileParameters.power *
                      root.evalFunction("weaponDamageLevelMultiplier",
                                        configParameter("level", 1))
    config.tooltipFields.damageLabel = round(power, 1)

    elementalType = configParameter("elementalType", "physical")
    if elementalType ~= "physical" then
        config.tooltipFields.damageKindImage =
            "/interface/elements/" .. elementalType .. ".png"
    end

    local stringImage = configParameter("stringImage",
                                        "/items/active/weapons/yoyos/string.png")
    local stringOffset = configParameter("stringOffset", {0, 0})

    if parameters.inventoryIcon then
        local iconBase = parameters.inventoryIcon
        if type(parameters.inventoryIcon) == "table" then
            iconBase = parameters.inventoryIcon[1].image
        end
        parameters.inventoryIcon = {
            {image = iconBase},
            {image = stringImage .. params.stringColor, offset = stringOffset}
        }
    else
        config.inventoryIcon = {
            {
                image = type(config.inventoryIcon) == "table" and
                    config.inventoryIcon[1] or config.inventoryIcon
            },
            {image = stringImage .. params.stringColor, offset = stringOffset}
        }
    end

    local time = params.projectileParameters.maxYoyoTime
    if time and time >= 100 then time = "Infinite" end
    config.tooltipFields.durationLabel = tostring(time)

    local name = "^gray;No Counterweight"
    local icon = "/interface/tooltips/counterweightbase.png"
    if params.counterWeightName ~= "" then name = params.counterWeightName end
    if params.counterWeightIcon ~= "" then icon = params.counterWeightIcon end
    config.tooltipFields.counterWeightIconImage = icon
    config.tooltipFields.counterWeightNameLabel = name

    -- config.tooltipFields.stringIconImage = params.currentStringIcon
    -- config.tooltipFields.stringNameLabel = params.currentStringName

    config.twoHanded = configParameter("")

    return config, parameters
end

function round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces > 0 then
        local mult = 10 ^ numDecimalPlaces
        return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end
