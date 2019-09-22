/**
 * @file publico.cpp
 *
 * @brief Centralizador de webservices. Recibe el webservice a atender
 * (srv) y los demás parámetros requeridos.
 *
 * @ingroup Middleware
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
#include "lib/cgi.h"
#include "lib/db.cpp"

extern std::string post;

int main() {
    try {
        cgicc::Cgicc cgi;
        cgicc::CgiEnvironment env = cgi.getEnvironment();
        post = env.getPostData();
        std::string servicio = cgi( "srv" );
        switch ( std::stoi( servicio ) ) {
            case 1: // carrusel
                queryAsJSon( "select im.listaCarrusel()" );
                break;
            case 2: // mostrarFicha
                queryAsJsonWP( "select im.mostrarFicha( $1 )", { "codIne" } );
                break;
            case 3: // autolistarMunicipios
                queryAsJsonWP(
                    "select im.autolistarMunicipios( $1 )", { "buscar" } );
                break;
            case 4://"autolistarAgregados" :
                queryAsJsonWP(
                    "select im.autolistarAgregados( $1 )", { "buscar" } );
                break;
            case 5://"mostrarAmdes" :
                queryAsJsonWP(
                    "select im.mostrarAmdes( $1 )", { "asociacion" } );
                break;
            case 6://"mostrarFichaNacional" :
                queryAsJSon(
                    "select im.mostrarFichaNacional()" );
                break;
            case 7://"mostrarProvincia" :
                queryAsJsonWP(
                    "select im.mostrarProvincia( $1 )", { "provincia" } );
                break;
            case 8://"mostrarDepartamento" :
                queryAsJsonWP(
                    "select im.mostrarDepartamento( $1 )", { "departamento" } );
                break;
            case 9://"Listado de departamentos" :
                queryAsJSon(
                    "select im.departamentos()" );
                break;
            case 10://"mostrarMancomunidad" :
                queryAsJsonWP(
                    "select im.mostrarMancomunidad( $1 )", { "mancomunidad" } );
                break;
            case 11: // mostrarAgregado
                queryAsJsonWP( "select im.mostrarAgregado( $1 )", { "agregado" } );
                break;
            case 20://"mostrarMapaDepartamentoMunicipio" :
                queryAsJsonWP(
                    "select im.mapaDepartamentoMunicipio( $1, $2 )",
                    { "codIne", "color" } );
                break;
            default :
                coutError( "Servicio no encontrado" );
        }
    } catch( const std::exception
             &e ) {
        coutError( "Error en el requerimiento | " + std::string ( e.what() ) );
    }
    return 1;
}

