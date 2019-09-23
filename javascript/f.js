/**
 * @file p.js
 *
 * @brief Scrip en el frontend que contiene las funciones de
 * representación de datos (gráficos, mapas, tablas, pies, etc) en las
 * fichas svg.
 *
 * @ingroup Frontend
 *
 * @author Alejandro Salamanca <alejandro@devenet.net>
 * @author Virginia Kama <virginia@devenet.net>
 * @author Josué Gutiérrez Quino <jgutierrez@devenet.net>
 * @author Javier Ramiro Castillo Tarqui <jcastillo@devenet.net>
 *
 */
function pie( json, id ) {
    var contenedor = $( '#' + id );
    var elementos = contenedor.find( "circle" );
    var base = $( elementos[0] );
    var padre = base.parent();
    var cx0 = parseFloat( base.attr( 'cx' ) );
    var cy0 = parseFloat( base.attr( 'cy' ) );
    var r = parseFloat( base.attr( 'r' ) );
    var fontSize = r * 0.1;
    /* Radio explosión */
    var rxp = 0.05 * r;
    /* Calcular la cantidad de elementos y su total absoluto */
    var sumatoria = 0;
    for ( var i in json ) {
        sumatoria += json[i];
    }
    var anguloInicial = 0;
    var anguloFinal    = 2 * Math.PI;
    var elementos = contenedor.find( "tspan[tipo*=porcentaje]" );
    var conPorcentaje = elementos.length > 0;
    var elPorcentaje = conPorcentaje ? $( elementos[0] ) : null;

    var elementos = contenedor.find( "tspan[tipo*=etiqueta]" );
    var conEtiqueta = elementos.length > 0;
    var elEtiqueta = conEtiqueta ? $( elementos[0] ) : null;

    var elementos = contenedor.find( "path[tipo*=linea]" );
    var conLinea = elementos.length > 0;
    var elLinea = conLinea ? $( elementos[0] ) : null;
    
    var colores = [];
    contenedor.find( "rect[tipo*=color]" ).each(
        function( i, el ) {
            var barraColor = $( el );
            colores.push( barraColor.attr( 'style' ).replace(
                new RegExp( '^.*fill:([^;]+);.*' ), '\$1' ) );
            barraColor.remove();
        } );
    var colorActual = colores.length - 1;

    for ( var i in json ) {
        var porcentaje = json[i] / sumatoria;
        colorActual = ( colorActual + 1 ) % colores.length;
        if ( porcentaje > 0 ) {
            var delta = porcentaje * 2 * Math.PI;
            var arcSweep = porcentaje <= 0.5 ? ' 0 1 ' : ' 1 1 ';
            var anguloMedio = anguloInicial + delta / 2;
            cx = cx0 + rxp * Math.cos( anguloMedio );
            cy = cy0 + rxp * Math.sin( anguloMedio );
            if ( porcentaje < 1 ) {
                var x1 = r * Math.cos( anguloInicial ) + cx;
                var y1 = r * Math.sin( anguloInicial ) + cy;
                anguloFinal = anguloInicial + delta;
                var x2 = r * Math.cos( anguloFinal ) + cx;
                var y2 = r * Math.sin( anguloFinal ) + cy;
                var d = 'M ' + cx + ',' + cy + ' L ' + x1 + ',' + y1
                    + ' A ' + r  + ' ' + r  + ' 0' + arcSweep
                    + x2 + ' ' + y2 + ' Z';
                var slice = document.createElementNS(
                    'http://www.w3.org/2000/svg', 'path' );
                slice.setAttribute( 'd', d );
            } else {
                var slice = document.createElementNS(
                    'http://www.w3.org/2000/svg', 'circle' );
                slice.setAttribute( 'cx', cx );
                slice.setAttribute( 'cy', cy );
                slice.setAttribute( 'r', r );
            }
            slice.setAttribute( 'fill', colores[colorActual] );
            slice.setAttribute( 'stroke', 'none' );
            padre.append( slice );
            if ( conPorcentaje ) {
                /* Se coloca el porcentaje al 75% del radio */
                var x3 = r * 0.75 * Math.cos( anguloMedio ) + cx0;
                var y3 = r * 0.75 * Math.sin( anguloMedio ) + cy0;
                var alineacionM = elPorcentaje.attr( 'style' )
                    .replace( new RegExp( '^(.*text-anchor:)[^;]+(;.*)' ),
                              '\$1middle\$2' );
                
                var porc = elPorcentaje.clone()
                    .text( Math.round( porcentaje * 100 ) + '%' )
                    .attr( 'x', x3 ).attr( 'y', y3 )
                    .attr( 'style', alineacionM );
                elPorcentaje.parent().append( porc );
            }
            var desp = 0;
            if ( conEtiqueta ) {
                if ( conLinea ) {
                    /* Se coloca la etiqueta al 115% del radio */
                    var x5 = r * Math.cos( anguloMedio ) + cx;
                    var y5 = r * Math.sin( anguloMedio ) + cy;
                    var x6 = ( r * 1.15 + rxp ) * Math.cos( anguloMedio ) + cx0;
                    var y6 = ( r * 1.15 + rxp ) * Math.sin( anguloMedio ) + cy0;
                    var d = 'M ' + x5 + ',' + y5 + ' L ' + x6 + ',' + y6;
                    var linea = elLinea.clone().attr( 'd', d );
                    contenedor.append( linea );
                    var anguloGr = 360 - ( ( anguloMedio * 180 ) / Math.PI );
                    anguloGr = anguloGr > 1 ? anguloGr : anguloGr*-1;
                    if ( anguloGr > 90 && anguloGr < 270 ) {
                        desp = - 1;
                        var eti = elEtiqueta.attr( 'style' )
                            .replace(
                                new RegExp( '^(.*text-anchor:)[^;]+(;.*)' ),
                                '\$1end\$2' );
                    } else {
                        desp = 1;
                        var eti = elEtiqueta.attr( 'style' )
                            .replace(
                                new RegExp( '^(.*text-anchor:)[^;]+(;.*)' ),
                                '\$1start\$2' ); 
                    }
                    var xA = x6;
                    var yA = y6;
                    var xB = xA + desp;
                    var yB = yA + fontSize / 2;
                    var etiqu = elEtiqueta.clone()
                        .text( i )
                        .attr( 'x', xB ).attr( 'y', yB ).attr( 'style', eti );
                    elEtiqueta.parent().append( etiqu );
                }
            }
        }
        anguloInicial = anguloFinal;
    }
    if ( conPorcentaje ) {
        elPorcentaje.parent().appendTo( contenedor );
        elPorcentaje.remove();
    }
    if ( conEtiqueta ) {
        elEtiqueta.parent().appendTo( contenedor );
        elEtiqueta.remove();
    }
    if ( conLinea ) {
        elLinea.parent().appendTo( contenedor );
        elLinea.remove();
    }
    base.remove();
}


function tabla ( json, id ) {
    /* Ubicar el elemento del id */
    var idFondo   = $( '#' + id );
    var elementos = idFondo.find( "rect[tipo*='fondo']" );
    var fondo = $( elementos[0] );
    var alto = parseFloat( fondo.attr( 'height' ) );
    var x0 = parseFloat( fondo.attr( 'x' ) );
    var y0 = parseFloat( fondo.attr( 'y' ) );
    var margen = parseFloat( fondo.attr( 'margin' ) );
    var columnas = [];
    var elementos = idFondo.find( "rect[tipo*='cuerpo']" );
    var altoCelda = parseFloat( $( elementos[0] ).attr( 'height' ) );
    
    var elementos = idFondo.find( "rect[tipo*='cuerpo']" );
    var cuerpo = $( elementos[0] );

    var elementos = idFondo.find( "tspan[tipo*='data']" );
    var data = $( elementos[0] );
    
    var maxCols = 0;
    var elementos = idFondo.find( "tspan[tipo*='titulo']" ).each(
        function( i, el ) {
            maxCols++;
            var jqEl = $( el );
            var j = parseInt( jqEl.attr( 'col' ) );
            var style = jqEl.attr( 'style' );
            var alineacion = style.replace(
                new RegExp( '^.*text-align:([^;]+);.*' ), '\$1' );
            var alto = parseFloat( style.replace(
                new RegExp( '^.*font-size:([0-9.]+).*' ), '\$1' ) );
            var campo = jqEl.attr( 'campo' );
            columnas[j-1] = { alineacion: alineacion, altoTexto: alto,
                              campo: campo, texto: jqEl };
        } );
    var elementos = idFondo.find( "rect[tipo*='encabezado']" ).each(
        function( i, el ) {
            var jqEl = $( el );
            var width = parseFloat( jqEl.attr( 'width' ) );
            var height = parseFloat( jqEl.attr( 'height' ) );
            var j = parseInt( jqEl.attr( 'col' ) );
            var x = parseFloat( jqEl.attr( 'x' ) ); /* dato aniadido */
            columnas[j-1].ancho = width;
            columnas[j-1].altoCaja = height;
            columnas[j-1].fondo = jqEl;
            columnas[j-1].x = x;
        } );
    var h = y0 + margen;
    var maxAlto = 0;
    for ( var i in columnas ) {
        var col = columnas[i];
        col.fondo.attr( 'y', h );
        col.texto.attr( 'y', h + ( col.altoCaja - col.altoTexto ) / 2
                        + col.altoTexto );
        if ( maxAlto < col.altoCaja ) maxAlto = col.altoCaja;
    }
    h += maxAlto - altoCelda;
    var modeloCuerpo = data.parent();
    for ( var d in json ) {
        h += altoCelda + 1;
        if ( alto < h + altoCelda - y0 ) break;
        for ( var i in columnas ) {
            var clonData = clone( data, modeloCuerpo );
            var estilo = clonData.attr( 'style' );
            var ancla = columnas[i].alineacion == 'center'
                ? 'middle' : columnas[i].alineacion;
            var altoTxt = parseFloat( estilo.replace(
                new RegExp( '^.*font-size:([0-9.]+).*' ), '\$1' ) );
            var posTxtY = h + ( parseFloat( cuerpo.attr( 'height' ) )
                                + altoTxt ) / 2;
            estilo = estilo.replace(
                new RegExp( '^(.*text-align:)[^;]+(;.*)' ),
                '\$1' + columnas[i].alineacion + '\$2' )
                .replace(
                    new RegExp( '^(.*text-anchor:)[^;]+(;.*)' ),
                    '\$1' + ancla + '\$2' );
            if ( columnas[i].alineacion == 'end' ) {
                var xTxt = columnas[i].x + columnas[i].ancho - 2;
            } else if ( columnas[i].alineacion == 'center' ) {
                var xTxt = columnas[i].x + columnas[i].ancho / 2;
            } else {
                var xTxt = columnas[i].x + 2;
            }
            clonData.attr( 'x', xTxt ).attr( 'y', posTxtY )
                .attr( 'style', estilo )
                .text( json[d][columnas[i].campo] );
            cuerpo.clone()
                .attr( 'x', columnas[i].x )
                .attr( 'y', h )
                .attr( 'width', columnas[i].ancho )
                .insertBefore( modeloCuerpo );
        }
    }
    cuerpo.remove();
    data.remove();
}


function piramide( json, id ) {
    /* Ubicar el elemento del id */
    var contenedor = $( '#' + id );
    var fondo = $( contenedor.find( "rect[tipo*='fondo']" )[0] );
    var barra = $( contenedor.find( "rect[tipo*='barra']" )[0] );
    var text = $( contenedor.find( "tspan[tipo*='edad']" )[0] );
    text.attr( 'style',
               text.attr( 'style' )
               .replace( new RegExp( 'font-size:[^;]+;' ),
                         'font-size:' + altoTexto + 'pt;' )
               .replace( new RegExp( 'text-align:[^;]+;' ),
                         'text-align:center' )
               .replace( new RegExp( '^(.*text-anchor:)[^;]+(;.*)' ),
                         '\$1middle\$2' ) );
    var linea  = $( contenedor.find( "path[tipo*='linea']" )[0] );
    var escala = $( contenedor.find( "tspan[tipo*='escala']" )[0] );
    var titulo = $( contenedor.find( "tspan[tipo*='titulo']" )[0] );
    var flecha = $( contenedor.find( "path[tipo*='arrow']" )[0] );
    var ancho = parseFloat( fondo.attr( 'width' ) );
    var altoTotal = parseFloat( fondo.attr( 'height' ) );
    var altoEscala = 5;
    var altoTick = 1;
    var alto = altoTotal - altoEscala - 2;
    var x0 = parseFloat( fondo.attr( 'x' ) );
    var y0 = parseFloat( fondo.attr( 'y' ) );
    var cantidad = json.length;
    var altoPistas = alto / cantidad;
    var altoBarra = 0.5 * altoPistas;
    var altoTexto = 0.4 * altoPistas;

    var despY = 0.25 * altoPistas;
    var despTxt = altoBarra - ( altoBarra - altoTexto ) / 2 + 1;
    var anchoTexto = altoTexto * 5;

    var barraMax = ( ancho - 4 - anchoTexto ) / 2;

    var maxBar = 0;
    for ( var i in json ) {
        if ( json[i].h > maxBar ) maxBar = json[i].h;
        if ( json[i].m > maxBar ) maxBar = json[i].m;
    }
    var etiqueta = '';
    var factor = 1;
    if ( maxBar < 1000 ) {
        etiqueta = '';
        factor = 1;
    } else if ( maxBar < 1000000 ) {
        etiqueta = ' (miles)';
        factor = 1000;
    } else {
        etiqueta = ' (millones)';
        factor = 1000000;
    }
    var maxEscala = maxBar/factor;
    var ajuste = maxEscala < 5 ? .5 : 5;
    maxEscala = Math.round( maxEscala/ajuste ) * ajuste;
    if ( maxBar < maxEscala * factor ) {
        maxBar = maxEscala * factor;
    }
    var altoTxtEscala = parseFloat( escala.attr( 'style' ).replace(
        new RegExp( '^.*font-size:([0-9.]+).*' ), '\$1' ) );
    escala.attr( 'style',
                 escala.attr( 'style' )
                 .replace( new RegExp( '^(.*text-anchor:)[^;]+(;.*)' ),
                           '\$1middle\$2' ) );
    clone( escala ).text( 'Población' + etiqueta ) // poblacionHombres
        .attr( 'x', x0 + barraMax / 2 )
        .attr( 'y', y0 + altoTotal - 1 );
    clone( escala ).text( 'Población' + etiqueta ) // poblacionMujeres
        .attr( 'x', x0 + ( ancho + anchoTexto + barraMax ) / 2 )
        .attr( 'y', y0 + altoTotal - 1 );
    clone( titulo ).text( 'Grupo de edad' ) // Grupo de edades
        .attr( 'x', ancho / 2 + x0 )
        .attr( 'y', y0 + altoTotal - 1 );
    var orX = x0 + barraMax + 2 - barraMax / maxBar * maxEscala * factor;
    var orY = y0 + altoTotal - altoEscala / 2 - 1 - altoTxtEscala - altoTick;
    var orXR = x0 + ancho / 2 + anchoTexto / 2;
    var maxAltoFlecha = altoEscala / 2 / 6;
    linea.attr( 'd',
                'M ' + orX + ',' + ( orY + altoTick )
                + ' v ' + ( - altoTick )
                + ' h ' + ( maxEscala * factor * barraMax / maxBar )
                + ' v ' + ( altoTick )
                + ' m ' + ( - maxEscala * factor * barraMax / maxBar / 2 ) + ', 0'
                + ' v ' + ( - altoTick )
                + ' M ' + orXR + ',' + ( orY + altoTick )
                + ' v ' + ( - altoTick )
                + ' h ' + ( maxEscala * factor * barraMax / maxBar )
                + ' v ' + ( altoTick )
                + ' m ' + ( - maxEscala * factor * barraMax / maxBar / 2 ) + ', 0'
                + ' v ' + ( - altoTick ) );
    flecha.attr( 'd', 
                 ' M ' + ( x0 + ( ancho / 2 ) ) + ',' + orY
                 + ' l ' + 2 * maxAltoFlecha + ',' + 5 * maxAltoFlecha
                 + ' ' + -1.6 * maxAltoFlecha + ',' + -2 * maxAltoFlecha
                 + ' v ' + 5 * maxAltoFlecha
                 + ' h ' + -0.8 * maxAltoFlecha
                 + ' v ' + -5 * maxAltoFlecha
                 + ' l ' + -1.6 * maxAltoFlecha + ',' + 2 * maxAltoFlecha
                 + ' z' );
    escala  // Max valor izquierda
        .attr( 'x', x0 + ( barraMax + 2 - barraMax / maxBar * maxEscala * factor ) )
        .attr( 'y', y0 + altoTotal - altoEscala / 2 - 1 )
        .text( maxEscala );
    clone( escala ) // Med valor izquierda
        .attr( 'x', x0 + ( barraMax + 2 - barraMax / maxBar * maxEscala * factor / 2 ) )
        .text( Math.round( maxEscala * 10 / 2 ) / 10 );
    clone( escala )  // Min valor izquierda
        .attr( 'x', x0 + barraMax + 2 )
        .text( 0 );
    clone( escala ) // Max valor derecha
        .attr( 'x', x0 + ancho / 2 + anchoTexto / 2 + barraMax / maxBar * maxEscala * factor )
        .text( maxEscala );
    clone( escala ) // Med valor derecha
        .attr( 'x', x0 + ancho / 2 + anchoTexto / 2 + barraMax / maxBar * maxEscala * factor / 2 )
        .text( Math.round( maxEscala * 10 / 2 ) / 10 );
    clone( escala )  // Min valor derecha
        .attr( 'x', x0 + ancho / 2 + anchoTexto / 2 )
        .text( 0 );
    var h = y0;
    var contenedorTexto = text.parent();
    for ( var i in json ) {
        /* Para el texto */
        var txt = clone( text, contenedorTexto );
        var estilo = txt.attr( 'style' )
            .replace( new RegExp( 'font-size:[^;]+;' ),
                      'font-size:' + altoTexto + 'pt;' )
            .replace( new RegExp( 'text-align:[^;]+;' ),
                      'text-align:center' )
            .replace( new RegExp( '^(.*text-anchor:)[^;]+(;.*)' ),
                      '\$1middle\$2' );
        txt.attr( 'style', estilo ).attr( 'x', ancho / 2 + x0 )
            .attr( 'y', h + despTxt ).text(json[i].t);
        // var txt1 = document.createElementNS( 'http://www.w3.org/2000/svg', 'title' );
        // txt1.textNode( json[i].h );
        clone( barra, contenedor ) // BarraIzq
            .attr( 'width', barraMax / maxBar * json[i].h )
            .attr( 'x', x0 + barraMax + 2 - barraMax / maxBar * json[i].h )
            .attr( 'y', h + despY )
            .attr( 'height', altoBarra )
            .append( $( document.createElementNS( 'http://www.w3.org/2000/svg', 'title' ) )
                     .text( json[i].h ) );
        clone( barra, contenedor ) // BarraDer
            .attr( 'width', barraMax / maxBar * json[i].m )
            .attr( 'x', x0 + ancho / 2 + anchoTexto / 2 )
            .attr( 'y', h + despY ).attr( 'height', altoBarra )
            .append( $( document.createElementNS( 'http://www.w3.org/2000/svg', 'title' ) )
                     .text( json[i].m ) );
        h += altoPistas;
    }
    barra.remove();
    text.remove();
    titulo.remove();
//    flecha.remove();
}

function multiLinea( texto, id ) {
    var contenedorL = $( '#' + id );
    var elementos = contenedorL.find( "rect" );
    var fondo = $( elementos[0] );
    var ancho = parseFloat( fondo.attr( 'width' ) );
    var alto = parseFloat( fondo.attr( 'height' ) );
    var x0 = parseFloat( fondo.attr( 'x' ) );
    var y0 = parseFloat( fondo.attr( 'y' ) );
    var elementos = contenedorL.find( "text" );
    var parrafo = $( elementos[0] );
    var elementos = contenedorL.find( "tspan" );
    var text = $( elementos[0] );
    var altoTxt = parseFloat( text.attr( 'style' ).replace(
        new RegExp( '^.*font-size:([0-9.]+).*' ), '\$1' ) );
    var elementos = contenedorL.find( "circle[tipo*='vineta']" );
    var tieneVineta = elementos.length > 0;
    if ( tieneVineta ){
        var anchoVineta = altoTxt / 2.1 + 2;
        var vineta = $( elementos[0] );
        var r = parseFloat( vineta.attr( 'r' ) );
    } else {
        var anchoVineta = 0;
        var vineta = {};
    }
    var max = ( ancho - 2 - anchoVineta - ( tieneVineta ? 0 : 2 ) ) / altoTxt * 2.1;
    texto = texto.trim().replace( new RegExp ( ' +', 'g'), ' ');
    texto = texto.trim().replace( new RegExp ( ' *\n *', 'g'), '\n');
    var h = y0;
    var lineas = texto.split( '\\n' );
    var existeParrafo = false;
    for ( var i in lineas ){
        if ( existeParrafo ) {
            clone( text, parrafo )
                .attr( 'x', x0 + 2 + anchoVineta )
                .attr( 'y', h )
                .text( txtTspan );
        }
        var palabras = lineas[i].split( ' ');
        var txtTspan = '';
        existeParrafo = true;
        h += altoTxt * 1.15;
        if ( h - x0 > alto ) break;
        if ( tieneVineta ) {
            var vin = vineta.clone()
                .attr( 'cx', x0 + 2 + r ).attr( 'cy', h - altoTxt / 2 * 1.15 + r );
            vin.appendTo( contenedorL );
        }
        for ( var i in palabras ) {
            if ( txtTspan.length + palabras[i].length <= max ) {
                txtTspan += ( txtTspan.length > 0 ? ' ' : '' ) + palabras[i];
            } else {
                var clon = text.clone().attr( 'x', x0 + 2 + anchoVineta )
                    .attr( 'y', h ).text( txtTspan );
                clon.appendTo( parrafo );
                h += altoTxt * 1.15;
                txtTspan = palabras[i];
                if ( h - x0 > alto ) break;
            }   
        }
    }
    if ( h - x0 <= alto && existeParrafo ) {
        var clon = text.clone().attr( 'x', x0 + 2 + anchoVineta )
            .attr( 'y', h ).text( txtTspan );
        clon.appendTo( parrafo );
    }
    text.remove();
    vineta.remove();
}

function clone( element, parent ) {
    parent = typeof parent !== 'undefined' ? parent : element.parent();
    var clon = element.clone();
    clon.appendTo( parent );
    return clon;
}

function xLinkLinea( lineas, id ) {
    if ( lineas == '' ) {
        document.getElementById( id ).innerHTML = ""; return;
    }
    lineas = JSON.parse( lineas );
    if ( lineas.length == 0 ) return;
    var contenedorL = $( '#' + id );
    var elementos = contenedorL.find( "rect" );
    var fondo = $( elementos[0] );
    var ancho = parseFloat( fondo.attr( 'width' ) );
    var alto = parseFloat( fondo.attr( 'height' ) );
    var x0 = parseFloat( fondo.attr( 'x' ) );
    var y0 = parseFloat( fondo.attr( 'y' ) );
    var elementos = contenedorL.find( "text" );
    var parrafo = $( elementos[0] );
    var elementos = contenedorL.find( "tspan" );
    var text = $( elementos[0] );
    var altoTxt = parseFloat( text.attr( 'style' ).replace(
        new RegExp( '^.*font-size:([0-9.]+).*' ), '\$1' ) );
    var elementos = contenedorL.find( "circle[tipo*='vineta']" );
    var tieneVineta = elementos.length > 0;
    if ( tieneVineta ){
        var anchoVineta = altoTxt / 2.1 + 2;
        var vineta = $( elementos[0] );
        var r = parseFloat( vineta.attr( 'r' ) );
    } else {
        var anchoVineta = 0;
        var vineta = {};
    }
    var max = ( ancho - 2 - anchoVineta - ( tieneVineta ? 0 : 2 ) ) / altoTxt * 2.1;
    var h = y0;
    var existeParrafo = false;
    var ancla = document.createElementNS( 'http://www.w3.org/2000/svg', 'a' );
    var txtAncla = document.createElementNS(
        'http://www.w3.org/2000/svg', 'text' );
    txtAncla.setAttribute( 'style', text.attr( 'style' ) );
    ancla.setAttribute( 'target', '_blank' );
    ancla.appendChild( txtAncla );
    for ( var i in lineas ){
        if ( existeParrafo ) {
            ancla.setAttributeNS(
                "http://www.w3.org/1999/xlink", "href",
                "https://www.lexivox.org/norms/" + idActual + ".xhtml" );
            clone( $( ancla ), contenedorL )
                .find( 'text' ).each( function ( i, el ) {
                    $( el ).text( txtTspan )
                        .attr( 'x', x0 + 2 + anchoVineta )
                        .attr( 'y', h );

                } );
                    
        }
        var palabras = lineas[i].tit.split( ' ' );
        var txtTspan = '';
        existeParrafo = true;
        var idActual = lineas[i].id;
        h += altoTxt * 1.15;
        if ( h - x0 > alto ) break;
        if ( tieneVineta ) {
            var vin = vineta.clone()
                .attr( 'cx', x0 + 2 + r ).attr( 'cy', h - altoTxt / 2 * 1.15 + r );
            vin.appendTo( contenedorL );
        }
        for ( var i in palabras ) {
            if ( txtTspan.length + palabras[i].length <= max ) {
                txtTspan += ( txtTspan.length > 0 ? ' ' : '' ) + palabras[i];
            } else {
                ancla.setAttributeNS(
                    "http://www.w3.org/1999/xlink", "href",
                    "https://www.lexivox.org/norms/" + idActual + ".xhtml" );
            clone( $( ancla ), contenedorL )
                .find( 'text' ).each( function ( i, el ) {
                    $( el ).text( txtTspan )
                        .attr( 'x', x0 + 2 + anchoVineta )
                        .attr( 'y', h );

                } );
                h += altoTxt * 1.15;
                txtTspan = palabras[i];
            // text.parent().wrap( ancla );
                if ( h - x0 > alto ) break;
            }   
        }
    }
    if ( h - x0 <= alto && existeParrafo ) {
        ancla.setAttributeNS(
            "http://www.w3.org/1999/xlink", "href",
            "https://www.lexivox.org/norms/" + idActual + ".xhtml" );
        clone( $( ancla ), contenedorL )
            .find( 'text' ).each( function ( i, el ) {
                $( el ).text( txtTspan )
                        .attr( 'x', x0 + 2 + anchoVineta )
                        .attr( 'y', h );

                } );

    }
    text.remove();
    vineta.remove();
}

function mostrarImagen( url, id ) {
    var el = document.getElementById( id );
    el.setAttributeNS( "http://www.w3.org/1999/xlink", "href", url );
    el.setAttribute( 'preserveAspectRatio', 'xMidYMid' );
}

function mostrarMapaDepartamento( codIne, id ) {
    var el = document.getElementById( id );
    el.setAttributeNS( "http://www.w3.org/1999/xlink",
                       "href",
                       './ws/mapa-ficha?cod_ine=' + codIne + '&color=fff' );
    el.setAttribute( 'preserveAspectRatio', 'xMidYMid' );
}


function mostrarMapaBolivia( idAutoagregado, id ) {
    var el = document.getElementById( id );
    el.setAttributeNS(
        "http://www.w3.org/1999/xlink",
        "href",
        './ws/mapa-bolivia?id_autoagregado='
            + idAutoagregado + '&color=fff' );
    el.setAttribute( 'preserveAspectRatio', 'xMidYMid' );
}
