/**
 * @file mapa-ficha.cpp
 *
 * @brief Webservice que construye un mapa departamental iluminando un
 * municipio en particular.
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
// #include "lib/cgi.h"

int main() {
    std::cout << cgicc::HTTPContentHeader( "image/svg+xml; charset=utf-8" );
    try {
        cgicc::Cgicc cgi;
        std::string cod_ine = cgi( "cod_ine" );
        std::string color = cgi( "color" );
        std::ifstream inFile;
        std::stringstream archivo;
        archivo << "../img/mapas/" << cod_ine.substr( 0, 1 ) << ".svg";
        inFile.open( archivo.str() );
        std::stringstream strStream;
        strStream << inFile.rdbuf();
        std::string fileSvg = strStream.str();
        std::stringstream replace;
        replace << cod_ine << "\" style=\"fill:#" << color;
        fileSvg = std::regex_replace(
            fileSvg, std::regex( cod_ine ), replace.str() );
        fileSvg = std::regex_replace(
            fileSvg, std::regex( "class=\"mapa" ), "style=\"stroke:#fff;stroke-width: 4px;fill:none" );
        std::cout << fileSvg;
    } catch( const std::exception
             &e ) {
        std::cout << "Error en el requerimiento | " + std::string ( e.what() );
    }
    std::cout << std::endl;
    return 1;
}
