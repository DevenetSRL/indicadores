#  @file makefile.sh in SQL area
#  
#  @brief Revisa los cambios en el código fuente SQL y regenera la
#  base de datos
#  
#  @ingroup Backend
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
sql=$(wildcard *sql)
ddl=$(wildcard *ddl)
dml=$(wildcard *dml)
csv=$(wildcard csv/*csv)

all: $(sql) $(ddl) $(dml) $(csv)
	@sh db.sh
