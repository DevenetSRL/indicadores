/**
 * @file p.js
 *
 * @brief Scrip en el frontend que permite gestionar la presentación
 * de la información de municipios, mancomunidades, provincias, amdes,
 * departamentos y de toda Bolivia.
 *
 * @ingroup Frontend
 *
 * @author Alejandro Salamanca <alejandro@devenet.net>
 * @author Virginia Kama <virginia@devenet.net>
 * @author Josué Gutiérrez Quino <jquino@devenet.net>
 * @author Javier Ramiro Castillo Tarqui <rcastillo@devenet.net>
 *
 */

/* 
 * This file is part of the indicadores-municipales distribution
 * (https://fam.egob.org or
 * https://github.com/DevenetSRL/indicadores).
 * Copyright (c) 2019 Devenet SRL.
 * 
 * This program is free software: you can redistribute it and/or modify  
 * it under the terms of the GNU General Public License as published by  
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License 
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
*/
var dnfam = {
    colors: [ 'red', 'pink', 'purple',
              'deep-purple', 'indigo',
              'blue', 'light-blue', 'cyan',
              'teal', 'green', 'light-green',
              'lime', 'yellow', 'amber',
              'orange', 'deep-orange', 'brown',
              'grey', 'blue-grey' ],
    colorPos: 0,
    mapas: {},
    departamentos: null,
    idDepartamentos: {},
    deptosPorNombre: {},
    mapaBolivia: '',
    modo: null,
    fadeIn: 400,
    slideUp: 300,
    cProv: null,
    amdes: [
        'AMDEPAZ',
        'AGAMDECH',
        'AMDEBENI',
        'AMDECO',
        'AMDECRUZ',
        'AMDEOR',
        'AMDEPANDO',
        'AMDEPO',
        'AMT',
    ]
};
$(document).ready( function() {
    dnfam.portada   = $('#portada');
    dnfam.contenido = $('#contenido');
    armarCarrousel();
    armarAmdes();
    cargarDepartamentos();
    cargarMunicipios();
    $.post( 'ws/publico?srv=1', 'json' )

    ajaxAutocomplete(
        '#autofichas', 'ws/publico?srv=3', 'desc', 'id', mostrarMunicipio );
    ajaxAutocomplete(
        '#autoagregado', 'ws/publico?srv=4', 'desc', 'id', mostrarAgregado );
    mostrarContenido();
    if ( window.history && window.history.pushState ) {
        $( window ).on( 'popstate', function( event ) {
            if ( typeof event.originalEvent.state == 'string'
                 && event.originalEvent.state.includes( '|' ) ) {
                var dt = event.originalEvent.state.split( '|' );
                typeof dt[1] == 'undefined'
                    ? window[dt[0]]( true ) : window[dt[0]]( dt[1], true );
            }
        } );
    }
} );

function cargarDepartamentos() {
    $.post( 'ws/publico?srv=9', 'json' )
        .done( function( response ) {
            if ( response.status === 'ok' )
                dnfam.departamentos = response.data;
            for ( var i in response.data ) {
                dnfam.idDepartamentos[response.data[i].id] = response.data[i].lbl;
                dnfam.deptosPorNombre[response.data[i].lbl] = response.data[i].id;
            }
        } );
    $.ajax( {
        url: 'img/mapas/bolivia.svg',
        dataType: 'text',
        success: function( text ) {
            dnfam.mapaBolivia = text;
        } } );
}

function cargarMunicipios() {
    dnfam.municipios = {};
    $.post( 'ws/publico?srv=3', JSON.stringify( {"buscar":""} ), 'json' )
        .done( function( response ) {
            if ( response.status === 'ok' )
                for ( var i in response.data )
                    dnfam.municipios[response.data[i].id]
                = response.data[i].desc.replace( new RegExp( '.*: ' ), '' );
        } );
}

function armarCarrousel() {
    $.post( 'ws/publico?srv=1', 'json' )
        .done( function( response ) {
            if ( response.status === 'ok' ) {
                var html = '';
                dnfam.mejores = response.data;
                for ( var i in response.data ) {
                    response.data[i].color = nextColor( 2 );
                    response.data[i].colorInverso = getColor( 9 );
                    response.data[i].cod_ine = response.data[i].cod_ine == null
                        ? ''
                        : response.data[i].cod_ine;
                    response.data[i].funcionDatos = response.data[i].cod_ine == ''
                        ? 'mostrarNacional'
                        : 'mostrarMunicipio';
                    html += bigote( 'tplCarruselItem', response.data[i] );
                }
                $( '#carruselIndicadores' ).html( html ).carousel({shift: 200});
                autoplay( '#carruselIndicadores', 5000 );
            } } );
}

function armarAmdes() {
    var html = '';
    for ( var i = dnfam.amdes.length - 1; i > 0; i--) {
        var j = ( Math.random() * ( i + 1 ) ) >> 0;
        var temp = dnfam.amdes[i];
        dnfam.amdes[i] = dnfam.amdes[j];
        dnfam.amdes[j] = temp;
    }
    for ( var i in dnfam.amdes ) {
        html += bigote(
            'tplAmdes',
            {amdes: dnfam.amdes[i].toLowerCase(), AMDES: dnfam.amdes[i]} );
    }
    $( '#logosAmdes' ).html( html );
}

function autoplay( id, milliseconds ) {
    $( id ).carousel( 'next' );
    setTimeout( autoplay, milliseconds, id, milliseconds );
}

function getColor( jump ) {
    var pos = ( dnfam.colorPos + jump ) % dnfam.colors.length;
    return dnfam.colors[pos];
}

function nextColor( jump ) {
    jump = jump || 1;
    dnfam.colorPos = ( dnfam.colorPos + jump ) % dnfam.colors.length;
    return dnfam.colors[dnfam.colorPos];
}

function bigote( id, data, callback ) {
    var html = $( '#' + id ).html();
    /* Preparar los ids */
    html = html.replace( new RegExp( 'id="' + id, 'g'), 'id="' ); 
    for ( var i in data ) {
        html = html.replace( new RegExp('{{ ' + i + ' }}', 'g'), data[i] );
    }
    html = html.replace( new RegExp('src="" data="([^"]+)"', 'g'), 'src="\$1"' );
    return html;
}

function mostrarContenido( tipo ) {
    tipo = ( typeof tipo === 'undefined' ) ? true : tipo;
    if ( tipo ) {
        if ( !dnfam.modo )
            dnfam.contenido.slideUp(
                dnfam.slideUp, function() {
                    window.scrollTo( 0, 0 );
                    dnfam.portada.fadeIn( dnfam.fadeIn );
                } );
        else
            dnfam.portada.fadeIn( dnfam.fadeIn );
    } else {
        if ( dnfam.modo )
            dnfam.portada.slideUp(
                dnfam.slideUp, function() {
                    dnfam.contenido.fadeIn( dnfam.fadeIn );
                } );
        else
            dnfam.contenido.fadeIn( dnfam.fadeIn );
    }
    dnfam.modo = tipo;
}

function armarContenido( url, parametros, callbackSuccess, callbackOnLoad ) {
    dnfam.contenido.slideUp( dnfam.slideUp, function() {
        window.scrollTo( 0, 0 );
        $.post( url, JSON.stringify( parametros ), 'json' )
            .done( function( response ) {
                if ( response.status === 'ok'
                     && typeof callbackSuccess === 'function' ) {
                    dnfam.contenido.html( callbackSuccess( response.data ) );
                    mostrarContenido( false );
                    if ( typeof callbackOnLoad === 'function' ) {
                        callbackOnLoad();
                    }
                    return;
                }
                mensajeError( data.message );
            } )
            .fail( mensajeError );
    } );
}

function mensajeError( error ) {
    error = error || 'No se ha podido realizar la operación';
    M.toast( error );
    mostrarContenido( true );
}

function ajaxAutocomplete( id, url, showField, idField, choice ) {
    $( '#' . id ).val( 'sin valor' )
        .click( function() {
            $(this).setSelectionRange( 0, inputAutocomplete.value.length);
        } );
    var instance = M.Autocomplete.init(
        document.querySelectorAll( id ), {
            limit: 6,
            minLength: 2,
            onAutocomplete: function( val ) {
                var data = this.options.data;
                var id = null;
                for ( i in data ) {
                    if ( data[i][this.showFieldName] == val ) {
                        id = data[i][this.idFieldName];
                        break;
                    }
                }
                if ( id !== null ) choice( id );
            }
        } )[0];
    instance.ajaxUrl = url;
    instance.showFieldName = showField;
    instance.idFieldName = idField;
    instance.dropdown.options.belowOrigin = true;
    instance.dropdown.options.coverTrigger = false;
    instance._renderDropdown = function(data, val) {
        this._resetAutocomplete();
        this.count = data == null ? 0 : data.length;
        for ( var i = 0; i < data.length; i++ ) {
            if ( i >= this.options.limit ) break;
            $( this.container )
                .append(
                    $('<li>').append(
                        $( '<span>',
                           { text: data[i][this.showFieldName] } ) ) );
        }
        if ( this.count > 6 )
            $(this.container).append(
                $('<li>',
                  {class: "small", text: ( this.count - 6 ) + ' más...' } )
                    .click(function (event) { event.stopPropagation(); } ) );
    };
    instance.open = function() {
        var val = this.el.value.toLowerCase();
        this._resetAutocomplete();
        if (val.length >= this.options.minLength) {
            var self = this;
            $.post( this.ajaxUrl,
                    JSON.stringify( { buscar: val } ), 'json' )
                .done( function ( response ) {
                    self.options.data = response.data;
                    if ( response.data == null
                         || response.data.length == 0 ) {
                        self.dropdown.close();
                        self.isOpen = false;
                        return;
                    }
                    self._renderDropdown(self.options.data, val);
                    if (!self.dropdown.isOpen) {
                        self.dropdown.open();
                        self.isOpen = true;
                    } else {
                        self.dropdown.recalculateDimensions();
                    }
                } ) ;
        } else {
            this.dropdown.close();
            this.isOpen = false;
        }
    };
    instance.dropdown.constrainWidth = true;
}

function quitarId( lista, id ) {
    for ( var i in lista )
        if ( lista[i].id == id ) {
            delete lista[i];
            break;
        }
}

function coleccion( lista, estaticos, idEl ) {
    idEl = idEl || 'lblListaColeccion';
    var html = '<div class="collection">';
    for ( var i in lista ) {
        for ( var atributo in estaticos ) lista[i][atributo] = estaticos[atributo];
        html += bigote( idEl, lista[i] );
    }
    return html + '</div>';
}

function mapaDepartamento( idEl, id, color ) {
    var idDepto, idProv, idMun;
    if ( id < 10 ) {
        var idDepto = id;
    } else if ( id < 1000 ) {
        var idDepto = id / 100 >> 0;
        var idProv = id;
    } else {
        var idDepto = id / 10000 >> 0;
        var idProv = id / 100 >> 0;
        var idMun = id;
    }
    var mapaEl = $( idEl ).html( dnfam.mapas[idDepto] );
    mapaEl.find( 'path' ).each( function( i, el ) {
        el.setAttributeNS( null, 'class', color + ' lighten-2' );
        el.setAttributeNS( null, 'onclick', 'mostrarMunicipio( this.id )' );
        var title = document.createElementNS(
            'http://www.w3.org/2000/svg', 'title' );
        title.appendChild( document.createTextNode( dnfam.municipios[el.id] ) );
        el.appendChild( title );
    } );
    if ( idProv != null ) {
        mapaEl.find( '#' + idProv + ' path' ).each( function( i, el ) {
            el.setAttributeNS( null, 'class', color );
        } );
        mapaEl.find( '#' + idProv ).each( function( i, el ) {
            el.setAttributeNS( null, 'class', 'provinciaActual' );
        } );
    }
    if ( idMun != null ) {
        mapaEl.find( '#' + idMun ).each( function( i, el ) {
            el.setAttributeNS( null, 'class', color + ' darken-3' );
        } );
    }
}

function mapaBolivia( idEl, color ) {
    var mapaEl = $( idEl ).html( dnfam.mapaBolivia );
    mapaEl.find( 'path' ).each( function( i, el ) {
        el.setAttributeNS( null, 'class', color );
        var lbl = dnfam.idDepartamentos[el.id];
        var title = document.createElementNS(
            'http://www.w3.org/2000/svg', 'title' );
        title.appendChild( document.createTextNode( lbl ) );
        el.appendChild( title );
        el.setAttributeNS(
            null, 'onclick', "mostrarDepartamento( " + el.id + " )" );
    } );
}


function mejores( codIne ) {
    codIne = codIne || 0;
    var html = '';
    for ( var i in dnfam.mejores ) {
        if ( ( codIne === 0 && dnfam.mejores[i].cod_ine == null )
             || ( dnfam.mejores[i].cod_ine == codIne ) ) {
            dnfam.mejores[i].color = nextColor( 2 );
            dnfam.mejores[i].colorInverso = getColor( 9 );
            html += bigote( 'tplMejores', dnfam.mejores[i] );
        }
    }
    return html;
}

function cargarMapa( idDepto, callback ) {
    if ( typeof dnfam.mapas[idDepto] == 'undefined' ) {
        $.ajax( {
            url: 'img/mapas/' + idDepto + '.svg',
            dataType: 'text',
            success: function( text ) {
                dnfam.mapas[idDepto] = text;
                callback();
            } } );
    } else {
        callback();
    }
}

function mostrarMunicipio ( cod_ine, fromHistory ) {
    if ( fromHistory == null || !fromHistory )
        window.history.pushState( 'mostrarMunicipio|' + cod_ine, null, './#!' );
    $( '#autofichas' ).val( '' );
    cargarMapa(
        cod_ine / 10000 >> 0,
        function() {
            armarContenido(
                'ws/publico?srv=2', { codIne: cod_ine },
                function( data ) {
                    data.cod_ine = cod_ine;
                    data.amdesLogo = data.amdes.toLowerCase();
                    data.fichas = coleccion(
                        data.fichas, {funcion: 'abrirFicha'},
                        'lblListaColeccionFichas' );
                    data.color1 = nextColor( 1 );
                    data.color2 = getColor( 1 );
                    data.color3 = getColor( 9 );
                    data.id_depto = dnfam.deptosPorNombre[data.departamento];
                    var manc = JSON.parse( data.mancomunidad );
                    var mancomunidades = [];
                    for ( var i in manc )
                        mancomunidades.push( {id:manc[i], lbl:manc[i] } );
                    data.mancomunidad = coleccion(
                        mancomunidades, {funcion: 'mostrarMancomunidad'} );
                    data.munProvincia = coleccion(
                        data.munProvincia, {funcion: 'mostrarMunicipio'} );
                    data.departamentos = coleccion(
                        dnfam.departamentos, {funcion: 'mostrarDepartamento'} );
                    data.mejores = mejores( cod_ine );
                    return bigote( 'lblMostrarFicha', data );
                },
                function() {
                    mapaDepartamento( '#mapaDepartamento', cod_ine, 'blue' );
                    mapaBolivia( '#mapaBolivia', 'blue' );
                } );
        } );
    return false;
}

function mostrarNacional ( fromHistory ) {
    if ( fromHistory == null || !fromHistory )
        window.history.pushState( 'mostrarNacional|', null, './#!' );
    armarContenido(
        'ws/publico?srv=6', {},
        function( data ) {
            data.color1 = nextColor( 2 );
            data.color2 = getColor( 2 );
            data.color3 = getColor( 9 );
            data.amdes = coleccion( data.amdes, {funcion: 'mostrarAmdes'} );
            data.sintesis = coleccion(
                data.sintesis, {funcion: 'abrirSintesis'},
                'lblListaColeccionSintesis'  );
            data.mejores = mejores();
            return bigote( 'lblMostrarNacional', data );
        },
        function() {
            mapaBolivia( '#mapaBolivia', 'blue' );
        } );
    return false;
}

function mostrarDepartamento ( idDepartamento, fromHistory ) {
    if ( fromHistory == null || !fromHistory )
        window.history.pushState( 'mostrarDepartamento|' + idDepartamento, null, './#!' );
    var departamento = dnfam.idDepartamentos[idDepartamento];
    cargarMapa(
        idDepartamento,
        function() {
            armarContenido(
                'ws/publico?srv=8', {"departamento": departamento},
                function( data ) {
                    data.departamento = departamento;
                    data.color1 = nextColor( 2 );
                    data.color2 = getColor( 2 );
                    data.color3 = getColor( 9 );
                    var logo = data.amdes[0].lbl;
                    data.amdes = data.amdes[0].lbl;
                    data.amdesLogo = ( logo ).toLowerCase();
                    data.provincias = coleccion( data.provincias,
                                                 {funcion: 'mostrarProvincia'} );
                    data.departamentos = coleccion(
                        dnfam.departamentos, {funcion: 'mostrarDepartamento'} );
                    data.mancomunidades = coleccion(
                        data.mancomunidades, {funcion: 'mostrarMancomunidad'} );
                    data.sintesis = coleccion(
                        data.sintesis,
                        {funcion: 'abrirSintesis'},
                        'lblListaColeccionSintesis' );
                    var htmlMD = '';
                    for ( var i in dnfam.mejores ) {
                        if ( ( dnfam.mejores[i].cod_ine / 10000 >> 0 )
                             == data.id_depto ) {
                            dnfam.mejores[i].color = nextColor( 2 );
                            dnfam.mejores[i].colorInverso = getColor( 9 );
                            htmlMD += bigote( 'tplMejores', dnfam.mejores[i] );
                        }
                    }
                    data.mejores = htmlMD;
                    return bigote( 'lblMostrarDepartamento', data );
                },
                function() {
                    mapaDepartamento(
                        '#mapaDepartamento', idDepartamento, 'blue' );
                    mapaBolivia( '#mapaBolivia', 'blue' );
                } );
        } );
    return false;
}

function mostrarProvincia ( provincia, fromHistory ) {
    if ( fromHistory == null || !fromHistory )
        window.history.pushState( 'mostrarProvincia|' + provincia, null, './#!' );
    armarContenido(
        'ws/publico?srv=7', {"provincia": provincia},
        function( data ) {
            data.provincia = provincia;
            data.color1 = nextColor( 2 );
            data.color2 = getColor( 2 );
            data.color3 = getColor( 9 );
            data.amdes = data.amdes[0].lbl;
            data.amdesLogo = ( data.amdes ).toLowerCase();
            data.municipios = coleccion(
                data.municipios, {funcion: 'mostrarMunicipio'} );
            data.mancomunidades = coleccion(
                data.mancomunidades, {funcion: 'mostrarMancomunidad'} );
            data.munProvincias = coleccion(
                data.munProvincias, {funcion: 'mostrarMunicipio'} );
            data.sintesis = coleccion(
                data.sintesis, {funcion: 'abrirSintesis'},
                'lblListaColeccionSintesis' );
            data.id_depto = dnfam.deptosPorNombre[data.departamento]; 
            data.departamentos = coleccion(
                dnfam.departamentos, {funcion: 'mostrarDepartamento'} );
            var htmlMD = '';
            for ( var i in dnfam.mejores ) {
                if ( (dnfam.mejores[i].cod_ine / 100 >> 0) == data.id_provincia ) {
                    dnfam.mejores[i].color = nextColor( 2 );
                    dnfam.mejores[i].colorInverso = getColor( 9 );
                    htmlMD += bigote( 'tplMejores', dnfam.mejores[i] );
                }
            }
            data.mejores = htmlMD;
            dnfam.cProv = data.id_provincia;
            return bigote( 'lblMostrarProvincia', data );
        },
        function() {
            cargarMapa(
                dnfam.cProv / 100 >> 0,
                function() {
                    mapaDepartamento(
                        '#mapaDepartamento', dnfam.cProv, 'green' );
                } );
            mapaBolivia( '#mapaBolivia', 'blue' );
        });
    return false;
}

function mostrarAmdes ( amdes, fromHistory ) {
    if ( fromHistory == null || !fromHistory )
        window.history.pushState( 'mostrarAmdes|' + amdes, null, './#!' );
    armarContenido(
        'ws/publico?srv=5', {"asociacion": amdes},
        function( data ) {
            data.amdes = amdes;
            data.color1 = nextColor( 2 );
            data.color2 = getColor( 2 );
            data.color3 = getColor( 9 );
            data.amdesLogo = data.amdes.toLowerCase();
            mapaDepartamento( '#mapaDepartamento', data.id_depto, 'orange' );
            data.sintesis = coleccion(
                data.sintesis, {funcion: 'abrirSintesis'},
                'lblListaColeccionSintesis' );
            data.provincias = coleccion(
                data.provincias, {funcion: 'mostrarProvincia'} );
            data.mancomunidades = coleccion(
                data.mancomunidades, {funcion: 'mostrarMancomunidad'} );
            data.departamentos = coleccion(
                dnfam.departamentos, {funcion: 'mostrarDepartamento'} );
            return bigote( 'lblMostrarAmdes', data );
        },
        function() {
            mapaBolivia( '#mapaBolivia', 'blue' );            
        } );
    return false;
}

function mostrarMancomunidad ( mancomunidad, fromHistory ) {
    if ( fromHistory == null || !fromHistory )
        window.history.pushState( 'mancomunidad|' + mancomunidad, null, './#!' );
    armarContenido(
        'ws/publico?srv=10', {"mancomunidad": mancomunidad},
        function( data ) {
            var html = '';
            var html = '<div class="collection">';
            var codDe = 0;
            var codProv = 0;
            var mancos = data.data_mancomunidad;
            for ( var i in mancos ) {
                if ( codDe != ( mancos[i].cod_ine /10000 >> 0 ) ){
                    html += '<a href="#!" class="collection-item depto"'
                        +'onClick="mostrarDepartamento(\''
                        + mancos[i].iddepartamento + '\' )">'
                        + '<i class="material-icons left">layers</i>'
                        + mancos[i].departamento + '</a>';
                }
                if ( codProv != ( mancos[i].cod_ine /100 >> 0 ) ){
                    html += '<a href="#!" class="collection-item prov"'
                        +'onClick="mostrarProvincia(\''
                        + mancos[i].provincia + '\' )">'
                        + '<i class="material-icons left">terrain</i>'
                        + mancos[i].provincia + '</a>';
                }
                html += '<a href="#!" class="collection-item mun"'
                    +'onClick="mostrarMunicipio( '
                    + mancos[i].cod_ine + ' )">'
                    + '<i class="material-icons left">place</i>'
                    + mancos[i].nombre + '</a>';
                codDe = mancos[i].cod_ine /10000 >> 0;
                codProv = mancos[i].cod_ine /100 >> 0;
            }
            html += '</div>';
            data.armar =  html;
            data.mancomunidad = mancomunidad;
            data.color1 = nextColor( 2 );
            data.color2 = getColor( 2 );
            data.color3 = getColor( 9 );
            data.sintesis = coleccion(
                data.sintesis, {funcion: 'abrirSintesis'},
                'lblListaColeccionSintesis' );
            data.departamentos = coleccion(
                dnfam.departamentos, {funcion: 'mostrarDepartamento'} );
            return bigote( 'lblMostrarMancomunidad', data );
        },
        function() {
            mapaBolivia( '#mapaBolivia', 'blue' );            
        } );
    return false;
}

function mostrarAgregado ( autoagregado ) {
    $( '#autoagregado' ).val( '' );
    $.post(
        'ws/publico?srv=11', JSON.stringify( { agregado: autoagregado } ),
        'json' )
        .done( function( response ) {
            if ( response.status === 'ok' ) {
                mostrarContenido( false );
                switch ( response.columna ) {
                case 'nacional':
                    mostrarNacional();
                    break;
                case 'departamento':
                    mostrarDepartamento( dnfam.deptosPorNombre[response.valor] );
                    break;
                case 'provincia':
                    mostrarProvincia( response.valor );
                    break;
                case 'amdes':
                    mostrarAmdes( response.valor );
                    break;
                case 'mancomunidad':
                    mostrarMancomunidad( response.valor );
                    break;
                default:
                    break;
                }
                return;
            }
            mensajeError( data.message );
        } )
        .fail( mensajeError );
}

function abrirFicha( codIne, idFicha ) {
    var h = $(window).height();
    var w = $(window).width();
    if ( h > 72 * 11 ) h = 72 * 11;
    if ( w > 72 * 8.5 ) w = 72 * 8.5;
    window.open(
        './ficha.html?codIne=' + codIne + '&ficha=' + idFicha,
        codIne + '-' + idFicha,
        'toolbar=no ,location=0, status=no, scrollbars=1,'
            + 'titlebar=no, menubar=no, width=' + w + ', height=' + h ).focus();
    return false;
}

function abrirSintesis( idAgregado, idSintesis ) {
    var h = $(window).height();
    var w = $(window).width();
    if ( h > 72 * 11 ) h = 72 * 11;
    if ( w > 72 * 8.5 ) w = 72 * 8.5;
    window.open(
        './sintesis.html?idAgregado=' + idAgregado + '&idSintesis=' + idSintesis,
        idAgregado + '-' + idSintesis,
        'toolbar=no ,location=0, status=no, scrollbars=1,'
            + 'titlebar=no, menubar=no, width=' + w + ', height=' + h ).focus();
    return false;
}
