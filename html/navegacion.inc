<!--
     @file navegacion.inc
     
     @brief HTML que como pieza de menú de usuario conectado es
     insertado en los archivos .html del sitio web de una sesión
     abierta.
     
     @ingroup Frontend
     
     @author Alejandro Salamanca <alejandro@devenet.net>
     @author Virginia Kama <virginia@devenet.net>
     @author Josué Gutiérrez Quino <jgutierrez@devenet.net>
     @author Javier Ramiro Castillo Tarqui <jcastillo@devenet.net>

 
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
    <nav class="" role="navigation">
      <div class="nav-wrapper container">
        <a id="logo-container" href="./index.html" class="brand-logo">
          <img src="img/logo-fam-b.svg">
        </a>
        <ul id="userConnect" class="dropdown-content">
          <li><a href="login.html">Conectarse</a></li>
          <li><a href="create-account.html">Suscribirse</a></li>
          <li class="divider"></li>
          <li><a href="connect-info.html">Información</a></li>
        </ul>
        <ul id="adminMenu" class="dropdown-content">
          <li><a href="upload.html">Cargar datos</a></li>
          <li class="divider"></li>
          <li><a href="admin-acervos.html">Acervos</a></li>
          <li><a href="admin-fmunicipales.html">Fichas municipales</a></li>
          <li><a href="admin-fagregadas.html">Fichas agregadas</a></li>
          <li class="divider"></li>
          <li><a href="admin-users.html">Gestión de usuarios</a></li>
          <li><a href="admin-roles.html">Roles</a></li>
          <li><a href="admin-resources.html">Recursos</a></li>
          <li><a href="admin-options.html">Opciones del sistema</a></li>
        </ul>
        <ul class="right hide-on-med-and-down" id="mainMenu">
          <!--#include:menu.inc-->
          <li id="userMenuArea">
            <a id="userMenu" class="dropdown-trigger" href="#!" data-target="userConnect">
              <i class="material-icons left">person</i>
              <span id="userName">Iniciar sesión</span>
              <i class="material-icons right">arrow_drop_down</i>
            </a>
          </li>
        </ul>
        <ul id="nav-mobile" class="sidenav">
          <li><a href="#">Navbar Link</a></li>
        </ul>
        <a href="#" data-target="nav-mobile" class="sidenav-trigger"><i class="material-icons">menu</i></a>
      </div>
    </nav>
