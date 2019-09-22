/**
 * @file cgi.cpp
 *
 * @brief Librería que maneja las funciones principales de captura de
 * datos desde el frontend y su gestión en la base de datos
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
#include "cgi.h"

std::string post;

Json::Value post2json() {
    Json::Value json;
    Json::Reader reader;
    makeErrorOn( !reader.parse( post, json ),
                 " Failed to parse Json " + post
                 + reader.getFormattedErrorMessages() );
    return json;
}

void queryAsJSon( std::string query  ) {
    std::string connection = readFile( "/etc/indicadores/db.conf" );
    pqxx::connection c( connection );
    makeErrorOn( !c.is_open(), "Error al conectar la base de datos." );
    pqxx::nontransaction nt(c);
    pqxx::result r = nt.exec( query );
    std::cout << cgicc::HTTPContentHeader( "application/json; charset=utf-8" );
    std::cout << r[0][0] << std::endl;
}

pqxx::result queryAsResult( std::string query  ) {
    std::string connection = readFile( "/etc/indicadores/db.conf" );
    pqxx::connection c( connection );
    makeErrorOn( !c.is_open(), "Error al conectar la base de datos." );
    pqxx::nontransaction nt(c);
    pqxx::result r = nt.exec( query );
    return r;
}

void makeErrorOn( bool condition,  std::string message ) {
    if ( condition ) throw std::runtime_error( message );
}

void coutError( std::string message ) {
    Json::Value json;
    std::regex search( ".*@ERROR: ?([^@]+)@.*\n.*", std::regex::extended ); 
    json["message"] = regex_replace( message, search, "$1" );
    json["status"] = "error";
    std::cout << cgicc::HTTPContentHeader( "application/json; charset=utf-8" )
            << json;
}

std::string readFile( std::string fileName ) {
    std::ifstream inFile;
    inFile.open( fileName );
    std::stringstream strStream;
    strStream << inFile.rdbuf();
    return strStream.str();
}
