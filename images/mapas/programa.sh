#!/bin/bash
# http://geo.gob.bo/download/?w=fondos&l=municipio_geo | Descarga del archivo de municipios en formato .shp
# https://www.qgis.org | Para transformacion del archivo .shp a bolivia.svg
# Ampliación 1:1000000, plugin SimpleSvg https://issues.qgis.org/projects/simplesvg
# El archivo generado es bolivia.svg
cp bolivia.svg bolivia.svg.bak

perl -i -p -e 's/\n//g;' bolivia.svg.bak
perl -i -p -e 's/<g/\n<g/g;' bolivia.svg.bak

while IFS=, read id cod_ine
do
    echo $cod_ine.svg
    perl -i -p -e 's/municipio_geo_'$id'"/'$cod_ine'"/g;' bolivia.svg.bak
    echo '<?xml version="1.0" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg xmlns="http://www.w3.org/2000/svg" viewBox=_completar_ version = "1.1">' > $cod_ine.svg
    grep $cod_ine bolivia.svg.bak >> $cod_ine.svg
    echo '</svg>' >> $cod_ine.svg
    viewBox='viewBox="'$(php analizar.php $cod_ine)'"'
    perl -i -p -e "s/viewBox=_completar_/$viewBox/g;" $cod_ine.svg
done < mapas.csv

for codDepto in 1 2 3 4 5 6 7 8 9
do
    echo '<?xml version="1.0" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg xmlns="http://www.w3.org/2000/svg" viewBox=_completar_ version = "1.1">' > $codDepto.svg
    grep "g id=\"$codDepto.*\"" bolivia.svg.bak >> $codDepto.svg
    echo '</svg>' >> $codDepto.svg
    viewBox='viewBox="'$(php analizar.php $codDepto)'"'
    perl -i -p -e "s/viewBox=_completar_/$viewBox/g;" $codDepto.svg
done
         
rm bolivia.svg.bak
