/**
 * @file mapa-bolivia.cpp
 *
 * @brief Construye un archivo SVG del mapa de Bolivia, iluminando los
 * municipios que corresponden a algún agregado (departamento,
 * provincia, amdes, mancomunidad)
 *
 * @ingroup Middleware
 *
 * @author Alejandro Salamanca <alejandro@devenet.net>
 * @author Virginia Kama <virginia@devenet.net>
 * @author Josué Gutiérrez Quino <jgutierrez@devenet.net>
 * @author Javier Ramiro Castillo Tarqui <jcastillo@devenet.net>
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
#include <fstream>
#include <cgicc/Cgicc.h>
#include <cgicc/HTTPContentHeader.h>
#include <sstream>
#include <regex>
#include "lib/db.cpp"
#include "lib/cgi.h"
int main() {
    std::cout << cgicc::HTTPContentHeader( "image/svg+xml; charset=utf-8" );
    try {
            /* Recuperar valores del post */
        cgicc::Cgicc cgi;
        std::string id_autoagregado = cgi( "id_autoagregado" );
        std::string color = cgi( "color" );
            /* Ejecutar la consulta para recuperar los códigos INE */
        std::string connection = readFile( "/etc/indicadores/db.conf" );
        pqxx::connection c( connection );
        makeErrorOn( !c.is_open(), "Error al conectar la base de datos." );
        pqxx::work w(c);
        c.prepare( "codigos", "select aux.devolverCodigosAgregado( $1 )" );
        pqxx::result resultado = w.prepared( "codigos" )( id_autoagregado ).exec();
        std::cout << resultado[0][0].as<std::string>(); 
    } catch( const std::exception
             &e ) {
        std::cout << "Error en el requerimiento | " + std::string ( e.what() );
    }
    std::cout << std::endl;
    return 1;
}
