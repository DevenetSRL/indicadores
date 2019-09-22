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
