-- @file db.sql
--
-- @brief Archivo de generación de toda la base de datos del sitio web
--
-- @ingroup Backend
--
-- @author Alejandro Salamanca <alejandro@devenet.net>
-- @author Virginia Kama <virginia@devenet.net>
-- @author Josué Gutiérrez Quino <jquino@devenet.net>
-- @author Javier Ramiro Castillo Tarqui <rcastillo@devenet.net>

-- This file is part of the indicadores-municipales distribution
-- (https://fam.egob.org or
-- https://github.com/DevenetSRL/indicadores).
-- Copyright (c) 2019 Devenet SRL.
--
-- This program is free software: you can redistribute it and/or modify  
-- it under the terms of the GNU General Public License as published by  
-- the Free Software Foundation, version 3.
--
-- This program is distributed in the hope that it will be useful, but 
-- WITHOUT ANY WARRANTY; without even the implied warranty of 
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License 
-- along with this program. If not, see <http://www.gnu.org/licenses/>.

create language plperlu;

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

drop schema if exists glb cascade;
create schema glb;
comment on schema glb is 'Global';

drop schema if exists sg cascade;
create schema sg;
comment on schema sg is 'Seguridad';

drop schema if exists im cascade;
create schema im;
comment on schema im is 'Indicadores municipales';
        
drop schema if exists fmt cascade;
create schema fmt;
comment on schema fmt is 'Funciones de formato';

drop schema if exists aux cascade;
create schema aux;
comment on schema aux is 'Auxiliar';

\i glb.functions.sql
\i sg.functions.sql
\i im.functions.sql
\i fmt.functions.sql
\i public.functions.sql
\i aux.functions.sql

\i glb.ddl
\i sg.ddl
\i im.ddl
\i aux.ddl

\i sg.fix.root.sql

\i glb.dml
\i sg.dml
\i im.dml
\i aux.dml

-- Las tablas asociadas a los acervos, serán almacenadas en el esquema
-- público
