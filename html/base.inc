<!--
     @file base.inc
     
     @brief Código HTML de base. Es compartido por todos los archivos
     HTML
     
     @ingroup Frontend
     
     @author Alejandro Salamanca <alejandro@devenet.net>
     @author Virginia Kama <virginia@devenet.net>
 
     This file is part of the indicadores-municipales distribution
     (https://fam.egob.org or
     https://github.com/DevenetSRL/indicadores).
     Copyright (c) 2019 Devenet SRL.

     This program is free software: you can redistribute it and/or modify  
     it under the terms of the GNU General Public License as published by  
     the Free Software Foundation, version 3.

     This program is distributed in the hope that it will be useful, but 
     WITHOUT ANY WARRANTY; without even the implied warranty of 
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
     General Public License for more details.

     You should have received a copy of the GNU General Public License 
     along with this program. If not, see <http://www.gnu.org/licenses/>.
-->
<html lang="es">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <meta http-equiv="Cache-control" content="private,max-age:3600">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1.0"/>
    <title><!--@title--></title>
    <link href="css/indicadores.min.css" type="text/css" rel="stylesheet" media="screen,projection"/>
    <script src="js/jquery-2.1.1.min.js"></script>
    <script src="js/jquery.validate.min.js"></script>
    <script src="js/messages_es.min.js"></script>
    <script src="js/chart.min.js"></script>
    <script src="<!--@userJavascript-->"></script>
  </head>
  <body class="<!--@bodyClass-->">
    <div class="main">
      <!--@main-->
    </div>
    <script src="js/materialize.min.js"></script>
  </body>
</html>

