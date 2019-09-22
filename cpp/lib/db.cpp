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
