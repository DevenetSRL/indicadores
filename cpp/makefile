# Make que genera todos los archivos cpp del actual directorio y a los
# ejecutables, los coloca en ../www/ws/
# apt install libjsoncpp-dev libcgicc-dev libpqxx-dev
# postgresql-plperl


path=../../www/ws/
wlibs=-lpqxx -lcgicc -ljsoncpp
sources=$(wildcard *cpp)
targets=$(patsubst %.cpp,$(path)/%,$(sources))
objects=$(patsubst %.cpp,obj/%.o,$(sources))
dbLibCpps=$(shell grep -l db.cpp *cpp)
nodbLibCpps=$(shell grep -L db.cpp *cpp)
objectsDb=$(patsubst %.cpp,obj/%.o,$(dbLibCpps))
objectsNoDb=$(patsubst %.cpp,obj/%.o,$(nodbLibCpps))

all : $(targets)

$(targets): $(objectsDb) $(objectsNoDb)


$(objectsDb): obj/%.o:%.cpp lib/cgi.o lib/db.o
	@c++ -c $< -o $@
	@c++ $(wlibs) lib/cgi.o lib/db.o $@ -o $(path)$(subst obj/,,$(subst .o,,$@))
	@echo $(subst obj/,,$(subst .o,,$@))

$(objectsNoDb): obj/%.o:%.cpp lib/cgi.o
	@c++ -c $< -o $@
	@c++ $(wlibs) lib/cgi.o $@ -o $(path)$(subst obj/,,$(subst .o,,$@))
	@echo $(subst obj/,,$(subst .o,,$@))

lib/cgi.o: lib/cgi.h lib/cgi.cpp
	@c++ -c lib/cgi.cpp -o lib/cgi.o
	@echo ***CGI.lib

lib/db.o: lib/db.cpp lib/cgi.o
	@c++ -c lib/db.cpp -o lib/db.o
	@echo ***DB.lib

clean:
	@rm obj/* $(path)/* lib/cgi.o
	@echo Proyecto limpio. Escriba make para volver a generarlo.

commit:
	cd ../
	svn commit -m 'Indicadores: Cambios varios'

show:
	@echo Con DB $(dbLibCpps) $(objectsDb) 
	@echo Sin DB $(nodbLibCpps)

