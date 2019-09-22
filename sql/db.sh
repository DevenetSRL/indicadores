#!/bin/bash
sinpsql=$(ps ax|grep psql|grep -v grep 2>/dev/null)
if [ "$sinpsql" != "" ]; then
    echo Las sesiones psql han sido forzadas a cierre.
    killall psql
fi

dropdb indicadores
createdb indicadores
psql indicadores -f db.sql 2>/tmp/.errores.log 1>/dev/null
grep ERROR /tmp/.errores.log
exit 0
