#  @file makefile.sh in javascript area
#  
#  @brief Revisa los cambios realizados en los archivos javascrip
#  (*js), los minimiza y publica
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
path=../../www/js/

freeSources=$(wildcard *js)

freeTargets=$(patsubst %js,$(path)%min.js,$(freeSources))

sources=jquery/jquery-2.1.1.min.js  \
	chart/chart.min.js  \
	../sass/js/bin/materialize.min.js  \
        jquery-validation/dist/jquery.validate.min.js  \
        jquery-validation/dist/localization/messages_es.min.js

targets=$(patsubst %,$(path)%,$(notdir $(sources)))

all : $(targets) $(freeTargets)

$(path)jquery-2.1.1.min.js : jquery/jquery-2.1.1.min.js
	@cp $< $@
	echo jquery.js

$(path)chart.min.js : chart/chart.min.js
	@cp $< $@
	@echo chart.js

$(path)materialize.min.js : ../sass/js/bin/materialize.min.js
	@cp $< $@
	@echo materialize.js

$(path)jquery.validate.min.js : jquery-validation/dist/jquery.validate.min.js
	@cp $< $@
	@echo validate.js

$(path)messages_es.min.js : jquery-validation/dist/localization/messages_es.min.js
	@cp $< $@
	@echo messages.js

$(freeTargets) : $(path)%min.js:%js
	@echo Procesando $< a $@ 
	@uglifyjs $< 	--compress \
			--mangle \
			--source-map \
			--output $@ 
