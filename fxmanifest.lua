fx_version "cerulean"
lua54 "yes"
game "gta5"
use_experimental_fxv2_oal "yes"

author "DevDaddyJacob"
description "A FiveM script to sync lights on emergency fleets"
version "1.0.0"

shared_scripts {
	"config.lua",
	"shared/logging.lua",
	"shared/utils.lua",
}

client_scripts {
	"client/utils.lua",
	"client/main.lua",
}

server_scripts {
	"server/main.lua",
}
