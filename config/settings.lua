local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

local blankTex = A.textures.blank

C["general"] = {
    ["uiScale"] = 0.64, -- 0.52,
    ["backdrop"] = {
        ["color"] = E:CreateColor(0.15, 0.15, 0.15),
        ["texture"] = blankTex
    },
    ["border"] = {
        ["size"] = 1,
        ["color"] = E:CreateColor(0, 0, 0),
        ["texture"] = blankTex
    },
    ["background"] = {
        ["multiplier"] = 0.30
    },
    ["highlight"] = {
        ["color"] = E:CreateColor(0.84, 0.75, 0.65)
    }
}

C["actionbars"] = {
    ["enabled"] = true,
    ["font"] = "Tainted Outlined",
    ["size"] = 34,
    ["spacing"] = 5,
    ["bar6"] = false,
    ["bar7"] = false,
    ["bar8"] = false,
    ["pet"] = {
        ["size"] = 30,
        ["spacing"] = 5
    },
    ["stance"] = {
        ["size"] = 27,
        ["spacing"] = 5,
        ["horizontal"] = false,
    },
    ["extra"] = {
        ["size"] = 40,
        ["spacing"] = 5
    },
}

C["auras"] = {
    ["enabled"] = true,
    ["font"] = "Tainted Outlined",
    ["size"] = 30,
    ["spacing"] = 3,
    ["rows"] = 3,
    ["columns"] = 12,
    ["sort"] = {
        ["method"] = "TIME",        -- "INDEX", "NAME" or "TIME"
        ["direction"] = "+"         -- "+" or "-"
    }
}

C["blizzard"] = {
    ["font"] = "Tainted",
    ["ghost"] = E.isRetail,
    ["mirrortimers"] = true,
    ["talkinghead"] = E.isRetail,
    ["uiwidgets"] = true,
    ["raid_utility"] = E.isRetail
}

C["chat"] = {
    ["margin"] = 5,
	["width"] = 450,
	["height"] = 205,
	["font"] = "Tainted",
	["text"] = {
		["fading"] = {
			["enabled"] = false,
			["timer"] = 60
		}
	},
    ["history"] = {
        ["enabled"] = true,
        ["threshold"] = 0,
    },
    ["link"] = {
        ["color"] = E:CreateColor(0.08, 1.00, 0.36),
        ["brackets"] = true
    }
}

C["datatexts"] = {
    ["enabled"] = true,
	["font"] = "Tainted",
	["colors"] = {
        ["class"] = true,
		["text"] = E:CreateColor(1.00, 1.00, 1.00),
		["value"] = E:CreateColor(1.00, 1.00, 1.00),
        ["highlight"] = E:CreateColor(1.00, 1.00, 0.00)
	},
    ["clock"] = {
        ["values"] = {
            ["military"] = "24-hour format",
            ["civilian"] = "12-hour format"
        },
        ["format"] = "military"
    },
	["elements"] = {
        -- left chat
		[1] = "Guild",
		[2] = "Character",
		[3] = "Friends",
        -- right chat
		[4] = "System",
		[5] = "MicroMenu",
		[6] = "Gold",
        -- minimap
		[7] = "Time",
		[8] = "Coords"
	}
}

C["maps"] = {
    ["enabled"] = true,
    ["font"] = "Tainted",
    ["worldmap"] = {
        ["scale"] = 0.80,
        ["coords"] = true
    },
}

C["miscellaneous"] = {
    ["font"] = "Tainted",
    ["texture"] = blankTex,
    ["threatbar"] = true,
    ["screenshots"] = {
        ["enabled"] = true,                 -- enables plugin.
        ["achievements"] = true,            -- enables screenshots of earned achievements.
        ["boss_kills"] = false,             -- enables screenshots of successful boss encounters.
        ["challenge_mode"] = E.isRetail,    -- enables screenshots of successful challenge modes / mythic keys.
        ["levelup"] = true,                 -- enables screenshots when player level up.
        ["dead"] = false,                   -- enables screenshots when player dies.
    },
    ["skyriding_race"] = true,
    ["mythic"] = {
        ["autokeystone"] = true,
        ["portals"] = true
    }
}

C["tooltips"] = {
    ["enabled"] = true,
    ["font"] =  "Tainted Outlined",
    ["texture"] = blankTex
}

C["unitframes"] = {
    ["enabled"] = true,
    ["font"] = "Tainted Outlined",
    ["texture"] = blankTex,
    ["monochrome"] = true,
    ["color"] = E:CreateColor(0.10, 0.10, 0.10),
    ["health"] = {
        ["temploss"] = {
            ["texture"] = A.textures.reduction
        },
        ["prediction"] = {
            ["colors"] = {
                ["self"] = E:CreateColor(0.31, 0.45, 0.63, 0.40),
                ["other"] = E:CreateColor(0.31, 0.45, 0.63, 0.40),
                ["absorb"] = E:CreateColor(0.82, 0.71, 0.23, 0.35),
                ["healAbsorb"] = E:CreateColor(0.82, 0.71, 0.23, 0.35)
            }
        }
    },
    ["power"] = {
        ["height"] = 4,
        ["prediction"] = {
            ["color"] = E:CreateColor(1.00, 1.00, 1.00, 0.35)
        }
    },
    ["auras"] = {
        ["size"] = 27,
        ["spacing"] = 3
    },
    ["debuffs"] = {
        ["desaturate"] = true
    },
    ["portrait"] = {
        ["enabled"] = false,
        ["model"] = "3D",       -- "2D", "CLASS", "3D"
        ["alpha"] = 0.35
    },
    -- class power
    ["classpower"] = {
        ["width"] = 235,
        ["height"] = 16,
        ["spacing"] = 5,
        ["anchor"] = { "CENTER", UIParent, "CENTER", 0, -308 }
    },
    ["totems"] = {
        ["icons"] = true,
        ["size"] = 32,
        ["spacing"] = 5,
        ["width"] = 235,
        ["height"] = 16,
        ["anchor"] = { "CENTER", UIParent, "CENTER", 0, -200 }
    },
    -- castbar
    ["castbar"] = {
        ["font"] = "Tainted",
        ["colors"] = {
            -- ["text"] = E:CreateColor(0.84, 0.75, 0.65),
            ["text"] = E:CreateColor(1.00, 1.00, 1.00),
            ["latency"] = E:CreateColor(0.69, 0.31, 0.31, 0.75),
            ["casting"] = E:CreateColor(0.29, 0.77, 0.30),
            ["channeling"] = E:CreateColor(0.29, 0.77, 0.30),
            ["empowering"] = E:CreateColor(0.29, 0.77, 0.30),
            ["notInterruptible"] = E:CreateColor(0.85, 0.09, 0.09)
        }
    },
    -- units
    ["player"] = {
        ["enabled"] = true,
        ["width"] = 267,
        ["height"] = 30,
        ["auras"] = false,
        ["castbar"] = {
            ["mode"] = "detached",
            ["width"] = 350,
            ["height"] = 20,
            ["icon"] = true,
            ["latency"] = true
        },
        ["buffs"] = {
            ["selfBuffs"] = true
        },
        ["tags"] = {
            ["name"] = "[classification][difficulty][level]|r [namecolor][namelong]|r",
            ["power"] = "[powercolor][curpp]|r",
            ["health"] = "[healthcolor][curhp]|r",
        }
    },
    ["target"] = {
        ["enabled"] = true,
        ["width"] = 267,
        ["height"] = 30,
        ["auras"] = true,
        ["castbar"] = {
            ["mode"] = "detached",
            ["width"] = 350,
            ["height"] = 20,
            ["icon"] = true
        },
        ["tags"] = {
            ["name"] = "[classification][difficulty][level]|r [namecolor][namelong]|r",
            ["health"] = "[healthcolor][curhp]|r"
        }
    },
    ["targettarget"] = {
        ["enabled"] = true,
        ["width"] = 177,
        ["height"] = 30,
        ["auras"] = false,
        ["tags"] = {
            ["name"] = "[namecolor][namemedium]|r",
            ["health"] = "[healthcolor][curhp]|r"
        }
    },
    ["focus"] = {
        ["enabled"] = true,
        ["width"] = 205,
        ["height"] = 25,
        ["auras"] = true,
        ["castbar"] = {
            ["mode"] = "embedded",
            ["icon"] = true
        },
        ["tags"] = {
            ["name"] = "[classification][difficulty][level]|r [namecolor][namemedium]|r",
            ["health"] = "[healthcolor][perhp]%|r"
        }
    },
    ["focustarget"] = {
        ["enabled"] = true,
        ["width"] = 205,
        ["height"] = 25,
        ["auras"] = false,
        ["tags"] = {
            ["name"] = "[classification][difficulty][level]|r [namecolor][namemedium]|r",
            ["health"] = "[healthcolor][perhp]%|r"
        }
    },
    ["pet"] = {
        ["enabled"] = true,
        ["width"] = 205,
        ["height"] = 25,
        ["auras"] = true,
        ["castbar"] = {
            ["mode"] = "embedded",
            ["icon"] = true
        },
        ["tags"] = {
            ["name"] = "[namecolor][nameshort]|r [difficulty][level]|r",
            ["health"] = "[healthcolor][perhp]%|r"
        }
    },
    ["arena"] = {
        ["enabled"] = true,
        ["width"] = 205,
        ["height"] = 25,
        ["auras"] = true,
        ["castbar"] = {
            ["mode"] = "embedded",
            ["icon"] = true
        },
        ["tags"] = {
            ["name"] = "[classification][difficulty][level]|r [namecolor][namemedium]|r",
            ["health"] = "[healthcolor][curhp]|r"
        }
    },
    ["boss"] = {
        ["enabled"] = true,
        ["width"] = 205,
        ["height"] = 25,
        ["auras"] = true,
        ["castbar"] = {
            ["mode"] = "embedded",
            ["icon"] = true
        },
        ["tags"] = {
            ["name"] = "[classification][difficulty][level]|r [namecolor][namemedium]|r",
            ["health"] = "[healthcolor][perhp]%|r"
        }
    },
    ["nameplate"] = {
        ["enabled"] = true,
        ["width"] = 185,
        ["height"] = 16,
        ["auras"] = true,
        ["castbar"] = {
            ["mode"] = "detached",
            ["icon"] = true
        },
        ["tags"] = {
            -- ["name"] = "[classification][difficulty][level]|r [hostility][name]|r",
            ["name"] = "[classification][difficulty][level]|r [name]",
            ["health"] = "[healthcolor][perhp]%|r"
        },
        ["minAlpha"] = 0.30,
        ["notSelectedAlpha"] = 0.50,
        ["selectedAlpha"] = 1.0,
        ["selectedScale"] = 1.2
    },
    ["raid"] = {
        ["enabled"] = true,
        ["width"] = 90,
        ["height"] = 58,
        ["auras"] = false,
        ["tags"] = {
            ["name"] = "[raidcolor][nameshort]|r"
        },
        ["debuffs"] = true,
        ["auratrack"] = {
            ["enabled"] = true,
            ["icons"] = true,
            ["spellTextures"] = true
        },
        ["solo"] = false,
        ["rangeAlpha"] = 0.30,
        ["xOffset"] = 5,
        ["yOffset"] = 5,
        ["unitsPerColumn"] = 5,
        ["columnSpacing"] = 5
    }
}
