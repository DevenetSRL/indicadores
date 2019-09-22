#!/bin/bash

#  @file minify.sh
#  
#  @brief Script para ofuscar y minimizar los archivos
#  html. Dependiendo de lo instalado, usa html-minifier o htmlmin
#  
#  @ingroup Frontend
#  
#  @author Alejandro Salamanca <alejandro@devenet.net>
#
#  This file is part of the indicadores-municipales distribution
#  (https://fam.egob.org or
#  https://github.com/DevenetSRL/indicadores).
#  Copyright (c) 2019 Devenet SRL.
#
#  This program is free software: you can redistribute it and/or modify  
#  it under the terms of the GNU General Public License as published by  
#  the Free Software Foundation, version 3.
#
#  This program is distributed in the hope that it will be useful, but 
#  WITHOUT ANY WARRANTY; without even the implied warranty of 
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License 
#  along with this program. If not, see <http://www.gnu.org/licenses/>.

echo Procesando $2
if [ "$(which htmlmin)" = "" ]; then
    html-minifier --collapse-whitespace --remove-comments \
                  --remove-optional-tags --remove-script-type-attributes \
                  --use-short-doctype --minify-css true \
                  --minify-js true \
                  /tmp/$1 -o $2
else
    htmlmin /tmp/$1 > $2
fi
