fx_version 'cerulean'
game 'gta5'

name 'Painel_Mecanica'
description 'Painel Mecânica - Ryze Custom'
author 'Ryze RP'
version '1.0.0'

lua54 'yes'

dependency 'screenshot-basic'

shared_scripts {
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@vrp/lib/utils.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}
