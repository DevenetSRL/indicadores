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
