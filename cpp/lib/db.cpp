/**
 * @file db.cpp
 *
 * @brief Librería de gestión de funciones avanzadas de base de datos.
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

template <class T>
std::string queryAsJsonWP( std::string query,
                             std::initializer_list<T> list,
                             int options = OPTIONS_BY_DEFAULT ) {
    Json::Value json = post2json();
    std::string connection = readFile( "/etc/indicadores/db.conf" );
    pqxx::connection c( connection );
    makeErrorOn( !c.is_open(), "Error al conectar la base de datos." );
    pqxx::work w(c);
    c.prepare( "procedure", query );
    pqxx::prepare::invocation w_invocation = w.prepared( "procedure" );
    for ( auto elem : list ) {
        w_invocation( json[elem].asString() );
    }
    pqxx::result r = w_invocation.exec();
    w.commit();
    if ( (int)( options & DO_NOT_SEND_RESULT ) == 0 ) {
        std::cout
            << cgicc::HTTPContentHeader( "application/json; charset=utf-8" )
            << std::endl
            << r[0][0].as<std::string>()
            << std::endl;
    }
    return r[0][0].as<std::string>();
}

template <class T>
pqxx::result execQueryAsResult( std::string query,
                                std::initializer_list<T> list ) {
    Json::Value json = post2json();
    std::string connection = readFile( "/etc/indicadores/db.conf" );
    pqxx::connection c( connection );
    makeErrorOn( !c.is_open(), "Error al conectar la base de datos." );
    pqxx::work w(c);
    c.prepare( "procedure", query );
    pqxx::prepare::invocation w_invocation = w.prepared( "procedure" );
    for ( auto elem : list ) {
        w_invocation( json[elem].asString() );
    }
    pqxx::result r = w_invocation.exec();
    w.commit();
    return r;
}
