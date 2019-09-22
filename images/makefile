#  @file makefile.sh in images area
#  
#  @brief Revisa los cambios en las imágenes y las publica
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

#  Nota: para reducir svg se puede usar
#  https://jakearchibald.github.io/svgomg/

path=../../www/img

svgs=$(wildcard *svg)
tsvgs=$(patsubst %,$(path)/%,$(svgs))

fotoAlcaldes=$(wildcard fotos/alcalde.foto/*jpg)
tFotoAlcaldes=$(patsubst fotos/alcalde.foto/%.jpg,$(path)/fotos/alcalde.foto_alcalde/%-7.jpg,$(fotoAlcaldes))

pieces=$(wildcard pieces/*svg)
tpieces=$(patsubst %,$(path)/%,$(pieces))

maps=$(wildcard mapas/[0-9][0-9][0-9][0-9][0-9].svg mapas/bolivia*.svg)
tmaps=$(patsubst %,$(path)/%,$(maps))

othermaps=$(wildcard mapas/[0-9].svg)
tothermaps=$(patsubst %,$(path)/%,$(othermaps))

all : $(tsvgs) $(tpieces) $(tmaps) $(tothermaps) $(tFotoAlcaldes) 

$(tsvgs): $(path)/%:%
	@cp $< $@

$(tpieces): $(path)/%:%
	@cp $< $@

$(tmaps): $(path)/%:%
	@cp $< $@

$(tothermaps): $(path)/%:%
	@cp $< $@

$(tFotoAlcaldes): $(path)/fotos/alcalde.foto_alcalde/%-7.jpg:fotos/alcalde.foto/%.jpg
	@echo Procesando $@
	@cp $< $@
