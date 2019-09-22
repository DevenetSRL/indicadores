.PHONY: sql cpp html sass 

all:
	@cd cpp        && $(MAKE) -s 
	@cd sass       && $(MAKE) -s 
	@cd javascript && $(MAKE) -s 
	@cd html       && $(MAKE) -s 
	@cd images     && $(MAKE) -s 
	@cd fonts      && $(MAKE) -s
	@echo Done.

html:
	@cd html && make

sass:
	@cd sass && make

sql:
	@echo Regenerando la base de datos
	@cd sql && make -s

clean:
	@sudo find cpp -name '*.o' -exec rm "{}" \;
	@sudo find ../www/ -type f -exec rm "{}" \;
	@echo Archivos de producción y código objeto borrados

cpp:
	@if [ "$(ls cpp/obj)" != "" ]; then rm cpp/obj/*.o; fi
	@cd cpp && $(MAKE) -s 
