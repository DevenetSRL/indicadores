function getUserData() {
    userData = {};
    if ( typeof imToken === 'undefined' ) imToken = '';
    if ( imToken !== '' )
        $.post( "ws/getUserData", JSON.stringify( {token:imToken} ), 'json' )
        .done(function(data) {
            if ( data.status !== 'ok' ) return;
            userData = data;
            var userInfo = '<li class="userData"><span>';
            if ( userData.nombre == null ) {
                userData.nombre = userData.usuario;
            }
            userInfo += '<i class="material-icons">person</i> '
                + userData.nombre + '<br/>';
            if ( userData.posicion !== null ) {
                userInfo += '<i class="material-icons">device_hub</i> '
                    + userData.posicion + '<br/>';
            }
            if ( userData.institucion !== null ) {
                userInfo += '<i class="material-icons">account_balance</i> '
                    + userData.institucion + '<br/>';
            }
            userInfo += '</span></li>';
            $( "#userConnect" ).html( userInfo + '<li><a href="login.html"><i class="material-icons left">folder_shared</i>Perfil</a></li><li><a href="create-account.html"><i class="material-icons left">vpn_key</i>Password</a></li><li class="divider"></li><li><a href="logout.html"><i class="material-icons left">lock_open</i>Desconectarse</a></li>' );
            $( "#userName" ).text( userData.usuario );
            $( "<li>" )
                .append( $( "<a>", { class:"dropdown-trigger", href:"#!", "data-target":"adminMenu" } )
                         .append( $( "<i>", { class:"material-icons left", text: "settings" } ) )
                         .append( "Administración" )
                         .append( $( "<i>", { class:"material-icons right", text: "arrow_drop_down" } ) )
                       )
                .insertBefore( $( "#userMenuArea" ) );
            $(".dropdown-trigger").dropdown();
        } )
        .fail( cleanUser );    
}

function cleanUser() {
    imToken = '';
    userData = {};
    localStorage.removeItem( 'imToken' );
}

var userData = {}; // Datos del usuario
var imToken = window.localStorage['imToken'] || ''; // Token de conexión
var errEl = {}; // Elemento de despliegue de error

function logout() {
    if ( imToken === '' ) {
        window.location.href = 'index.html';
        return;
    }
    $.post( "ws/logout", JSON.stringify( {token:imToken} ), 'json' ).
        done( function ( data ) {
            $( "#confirm" ).text( 'Usuario desconectado' );
            console.log( data ) ;
        } );
    cleanUser();
}

function login() {
    cleanUser();
    $("#login-form").validate({
        rules: {
            user: { required: true, minlength: 4 },
            passw: { required: true, minlength: 5 },
        },
        errorElement: "em",
        submitHandler: function(form) {
            $.post( 'ws/login', JSON.stringify({login:$('#cuser').val(),passw:$('#cpassw').val()}), 'json' )
                .done( function( data ) {
                    if ( data.status === 'ok' ) {
                        localStorage.setItem( 'imToken', data.token );
                        window.location.href = 'index.html';
                        return;
                    }
                    $( '#errorMessage' ).text( data.message );
                } )
                .fail( function( fail ) {
                    $( '#errorMessage' ).text( fail.status + ' ' + fail.statusText );
                } );
            return false;
        }
    });
}

function ok() {
    getUserData();
    M.updateTextFields();
    $(".dropdown-trigger").dropdown();
}

function mensajeError( data ) {
    $( '#browse' ).html( data.message );
}

function mostrarTabla( data, pk, editPrg, delPrg, htmlEl ) {
    if ( typeof data[0] === 'undefined' ) {
        return '<div class="aviso">No se han encontrado registros</div>';
    }
    var html = '<table class="responsive-table striped"><tr>';
    for ( col in data[0] ) {
        if ( col == pk || col.substring(0,1)=='_' ) {
            continue;
        }
        html += '<th>' + col + '</th>';
    }    
    html += '<th>Operación</th>';
    html += '</tr>';
    for ( fila in data ) {
        if ( data[fila]['_estado'] == false || data[fila]['_Estado'] == false  ) { 
            html += '<tr class="grey-text">';
        }else{
            html += '<tr>';
        }
        for ( col in data[fila] ) {
            if ( col == pk || col.substring(0,1)=='_' ) {
                continue;
            }
            html += '<td>' + data[fila][col] + '</td>';
        }
        html += '<td>'
            + boton( pk, data[fila][pk], 'edit', editPrg )
            + boton( pk, data[fila][pk], 'delete', delPrg, true )
            + '</td>';
        html += '</tr>';
    }
    html += '</table>';
    $( '#' + htmlEl ).html( html );
}

// function autoComplete( data ){    
//     html +='<div class="row"><div class="col s12"><div class="row"><div class="input-field col s10"><i class="material-icons prefix">search</i><input type="text" id="autocomplete-input" class="autocomplete"><label for="autocomplete-input">Ficha de Municipio</label></div><div class="input-field col s2"><a class="waves-effect waves-light btn" href="index.html">Volver</a></div></div></div></div>'
//     var obj = {};
//     for (fila in data) {
//         obj[data[fila]['Nombre']] = null;
//     }
//     console.log(obj);
//     $('input.autocomplete').autocomplete(
//       obj
//     );
// }

function boton( idName, idValue, icon, program, confirm ) {
    var anchor = $( '<a>', {
        href: program + '?' + idName + '=' + idValue } )
        .append( $( '<i>', { class:"material-icons",
                             text: icon } ) )
    if ( confirm ) {
        anchor.attr(
            "onclick",
            "return confirm('¿Desea eliminar este registro?')" );
    }
    return anchor.prop('outerHTML');
}

function errorPlacement( error, element ) {
    var placement = $( element ).data( 'error' );
    if ( placement ) {
        $( placement ).append( error )
    } else {
        error.insertAfter( element );
    }
}

function get( getName ) {
    var url = new URL( window.location.href );
    console.log( url );
    return url.searchParams.get( getName );
}

function post( url, data, callback ) {
    $.post(
        url, data == null ? {} : JSON.stringify( data ), 'json' )
        .done( function( data ) {
            if ( data.status === 'ok' ) {
                if ( typeof callback === 'function' ) {
                    callback( data );
                }
                if ( typeof callback === 'string' ) {
                    window.location.href = callback;
                }
                return;
            }
            mensajeError( data );
        } )
        .fail( mensajeError );
};

function PopupCenter( url, title, w, h ) {
    var dualScreenLeft = window.screenLeft != undefined
        ? window.screenLeft : window.screenX;
    var dualScreenTop = window.screenTop != undefined
        ? window.screenTop : window.screenY;    
    var width = window.innerWidth
        ? window.innerWidth : document.documentElement.clientWidth
        ? document.documentElement.clientWidth : screen.width;
    var height = window.innerHeight
        ? window.innerHeight : document.documentElement.clientHeight
        ? document.documentElement.clientHeight : screen.height;
    
    var systemZoom = width / window.screen.availWidth;
    var left = (width - w) / 2 / systemZoom + dualScreenLeft
    var top = (height - h) / 2 / systemZoom + dualScreenTop
    var newWindow = window.open(
        url, title, 'scrollbars=yes, width='
            + w / systemZoom + ', height='
            + h / systemZoom + ', top='
            + top + ', left=' + left );
    if ( window.focus ) newWindow.focus();
    return newWindow;
}


