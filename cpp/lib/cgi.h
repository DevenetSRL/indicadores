#include "cgicc/CgiDefs.h"
#include "cgicc/HTTPHTMLHeader.h"
#include <cgicc/CgiDefs.h>
#include <cgicc/CgiEnvironment.h>
#include <cgicc/Cgicc.h>
#include <cgicc/HTMLClasses.h>
#include <cgicc/HTTPContentHeader.h>
#include <cgicc/HTTPCookie.h>
#include <cgicc/CgiInput.h>
#include <ctime>
#include <exception>
#include <fstream>
#include <initializer_list>
#include <iostream>
#include <jsoncpp/json/json.h>
#include <math.h>
#include <pqxx/pqxx> 
#include <sstream>
#include <string>
#include <regex>

#define OPTIONS_BY_DEFAULT   0
#define DO_NOT_SEND_RESULT   1

void queryAsJSon( std::string query );
pqxx::result queryAsResult( std::string query  );
void makeErrorOn( bool condition,  std::string message );
void coutError( std::string menssage );
std::string readFile( std::string fileName );
Json::Value post2json();
