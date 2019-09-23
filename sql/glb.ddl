-- @file glb.ddl
--
-- @brief Estructura de datos del esquema glb.  El esquema glb es un
-- esquema de datos y funciones comunes
--
-- @ingroup Backend
--
-- @author Alejandro Salamanca <alejandro@devenet.net>
-- @author Virginia Kama <virginia@devenet.net>
-- @author Josué Gutiérrez Quino <jgutierrez@devenet.net>
-- @author Javier Ramiro Castillo Tarqui <jcastillo@devenet.net>

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

create table glb.options (
  id_option                     serial primary key,
  opt_key                       text not null unique,
  opt_value                     text,
  description                   text,
  enabled                       boolean not null default true,
  id_creator                    integer not null,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null,
  last_modification             timestamp with time zone not null default now()
);
create index glb_options_opt_key     on glb.options (opt_key);
create index glb_options_creator     on glb.options (id_creator);
create index glb_options_modificator on glb.options (id_modificator);
comment on table  glb.options                     is 'Opciones//Options';
comment on column glb.options.id_option           is 'Opción//Option';
comment on column glb.options.opt_key             is 'Clave//Key';
comment on column glb.options.opt_value           is 'Valor//Value';
comment on column glb.options.id_creator          is 'Creador//Creator|HIDE_ALL';
comment on column glb.options.date_of_creation    is 'Creación//Creation|HIDE_ALL';
comment on column glb.options.id_modificator      is 'Modificador//Modificator|HIDE_ALL';
comment on column glb.options.last_modification   is 'Modificación//Modification|HIDE_ALL';
