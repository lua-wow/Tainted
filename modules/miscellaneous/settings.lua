local _, ns = ...
local C = ns.C

-- screenshots reads these at PLAYER_LOGIN
local screenshots = ns.ScreenShots
local cfg = C.miscellaneous.screenshots
screenshots.achievements = cfg.achievements
screenshots.boss_kills = cfg.boss_kills
screenshots.challenge_mode = cfg.challenge_mode
screenshots.levelup = cfg.levelup
screenshots.dead = cfg.dead
screenshots.messages = cfg.messages
screenshots.tracer = cfg.tracer
