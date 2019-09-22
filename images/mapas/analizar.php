<?php

$codIne = $argv[1];

$file = file_get_contents( $codIne . '.svg' );

$file = preg_replace( '/id="[0-9]+"/', '', $file );
$file = preg_replace( '/[^0-9,-]/', ' ', $file );
$file = preg_replace( '/  +/', ' ', $file );

$pares = explode( ' ', $file );
$xmin = $xmax = $ymin = $ymax = null;
foreach ( $pares as $par ) {
    $vals = explode( ',', $par );
    if ( sizeOf( $vals ) != 2 ) continue;
    $x = $vals[0];
    $y = $vals[1];
    if ( is_null( $xmin ) ) $xmin = $x;
    if ( is_null( $xmax ) ) $xmax = $x;
    if ( is_null( $ymin ) ) $ymin = $y;
    if ( is_null( $ymax ) ) $ymax = $y;
    $xmin = min( $x, $xmin );
    $xmax = max( $x, $xmax );
    $ymin = min( $y, $ymin );
    $ymax = max( $y, $ymax );
}



printf( "%d %d %d %d", $xmin, $ymin, abs( $xmax - $xmin ), abs( $ymax - $ymin ) );




/* pares=$(grep $cod_ine bolivia.svg.bak | \ */
/*                sed -e "s/$cod_ine//" \ */
/*                    -e 's/[^0-9,-]/ /g' \ */
/*                    -e 's/  *\/ /g' \ */
/*                    -e "s/ /\n/g" ) | \ */
/*     while read line */
/*     do */
/*         echo "$line" */
/*     done */


/* exit */

/* cp ../municipio_geo/Bolivia.svg bolivia.svg.bak */
/* while IFS=, read id cod_ine */
/* do */
/*     echo $cod_ine.svg */
/*     perl -i -p -e 's/municipio_geo_'$id'"/'$cod_ine'"/g;' bolivia.svg.bak */
/*     echo '<?xml version="1.0" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg xmlns="http://www.w3.org/2000/svg" viewBox = "-283 -1000 1233 764" version = "1.1">' > $cod_ine.svg */
/*     grep $cod_ine bolivia.svg.bak >> $cod_ine.svg */
/*     echo '</svg>' >> $cod_ine.svg */
/* done < mapas.csv */


?>
