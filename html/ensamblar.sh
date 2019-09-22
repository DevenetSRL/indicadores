#!/bin/bash

#  @file ensamblar.sh
#  
#  @brief Script para unir los archivos HTML a partir de piezas,
#  componentes y variables.
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


# Se pueden usar múltiples plantillas
# Se llama a otra plantilla con la instrucción
#   <!--#include:otra-plantilla.html-->
# Se asigna un valor con
#   <!--#set:variable=nuevo valor-->
# Se usa un valor con
#   <!--@variable-->

function evaluarPlantilla {
    local TPLFILE="$1"
    local TPLCONTENT="$(<$TPLFILE)"
    local L=''
    local INCLUDES=$(grep -Po '<!--\s*#include:.*?-->' "$TPLFILE")
    OLDIFS="$IFS"
    IFS=$'\n'
    for L in $INCLUDES; do
	local INCLFNAME=$(echo -n "$L"|grep -Po '(?<=#include:).*?(?=-->)')
	local INCLFCONTENT="$(evaluarPlantilla ${INCLFNAME})"
	TPLCONTENT="${TPLCONTENT//$L/$INCLFCONTENT}"
    done
    IFS="$OLDIFS"
    echo -n "$TPLCONTENT"
}

function procesarPlantilla {
    local TPLTEXT="$(evaluarPlantilla $1)"
    if [ ! "$2" = "" ]; then
	local INCLFCONTENT="$(evaluarPlantilla ${2})"
	TPLTEXT="${TPLTEXT//<!--@main-->/$INCLFCONTENT}"
    fi
    local SETS=$(echo -n "$TPLTEXT"|grep -Po '<!--#set:.*?-->')
    local L=''
    OLDIFS="$IFS"
    IFS=$'\n'
    for L in $SETS; do
	local SET=$(echo -n "$L"|grep -Po '(?<=#set:).*?(?=-->)')
	local SETVAR="${SET%%=*}"
	local SETVAL="${SET#*=}"
	TPLTEXT="${TPLTEXT//$L/}"
	TPLTEXT="${TPLTEXT//<!--@${SETVAR}-->/${SETVAL}}"
    done
    IFS="$OLDIFS"
    echo -n "$TPLTEXT"
}

nombre=$(basename $1)
if [ "$nombre" = "lienzo.html" ]
then
    cat $1
else
    procesarPlantilla base.inc $1
fi
