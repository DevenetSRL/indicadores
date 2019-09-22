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
