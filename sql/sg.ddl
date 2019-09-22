-- @file sg.ddl
--
-- @brief Estructura de datos del esquema sg.  El esquema sg es un
-- esquema auxiliar utilizado para datos y funciones de seguridad. La
-- seguridad del sitio web está basada en usuarios y roles.
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

create table sg.usuarios (
  id_usuario                    serial primary key,
  usuario                       text,
  correo                        text not null unique,
  clave                         text not null,
  roles                         text default '',
  "nombre"                      text,
  institucion                   text,
  "posicion"                    text,
  enabled                       boolean not null default true,
  id_creator                    integer not null,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null,
  last_modification             timestamp with time zone not null default now()
);
create index sg_usuarios_id_creator     on sg.usuarios (id_creator);
create index sg_usuarios_id_modificator on sg.usuarios (id_modificator);
comment on table  sg.usuarios                     is 'Usuarios//Users';
comment on column sg.usuarios.id_usuario          is 'Usuario//User';
comment on column sg.usuarios.usuario             is 'Usuario//Login';
comment on column sg.usuarios.correo              is 'Correo//Mail';
comment on column sg.usuarios.clave               is 'Clave//Password';
comment on column sg.usuarios.roles               is 'Roles//Roles';
comment on column sg.usuarios.nombre              is 'Nombre Completo//Name';
comment on column sg.usuarios.institucion         is 'Institución//Institution';
comment on column sg.usuarios.posicion            is 'Cargo//Position';
comment on column sg.usuarios.enabled             is 'Activo//Active';
comment on column sg.usuarios.id_creator          is 'Creador//Creator';
comment on column sg.usuarios.date_of_creation    is 'Creación//Creation';
comment on column sg.usuarios.id_modificator      is 'Modificador//Modificator';
comment on column sg.usuarios.last_modification   is 'Modificación//Modification';

create table sg.roles (
  id_rol                        serial primary key,
  codigo                        char not null unique,
  "rol"                         text not null unique,
  descripcion                   text,
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index sg_roles_creator     on sg.roles (id_creator);
create index sg_roles_modificator on sg.roles (id_modificator);
comment on table  sg.roles                     is 'Roles//Roles';
comment on column sg.roles.id_rol              is 'Rol//Rol';
comment on column sg.roles.codigo              is 'Código//Code';
comment on column sg.roles."rol"               is 'Rol//Rol';
comment on column sg.roles.descripcion         is 'Descripción//Description';
comment on column sg.roles.enabled             is 'Activo//Active';
comment on column sg.roles.id_creator          is 'Creador//Creator';
comment on column sg.roles.date_of_creation    is 'Creación//Creation';
comment on column sg.roles.id_modificator      is 'Modificador//Modificator';
comment on column sg.roles.last_modification   is 'Modificación//Modification';

create table sg.recursos (
  id_recurso                    serial primary key,
  codigo                        integer not null unique,                         
  descripcion                   text,
  roles                         text default '',
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index sg_recursos_creator     on sg.recursos (id_creator);
create index sg_recursos_modificator on sg.recursos (id_modificator);
comment on table  sg.recursos                     is 'Recursos//Recursos';
comment on column sg.recursos.id_recurso          is 'Rol//Resource';
comment on column sg.recursos.codigo              is 'Código//Code';
comment on column sg.recursos.descripcion         is 'Descripción//Description';
comment on column sg.recursos.enabled             is 'Activo//Active';
comment on column sg.recursos.id_creator          is 'Creador//Creator';
comment on column sg.recursos.date_of_creation    is 'Creación//Creation';
comment on column sg.recursos.id_modificator      is 'Modificador//Modificator';
comment on column sg.recursos.last_modification   is 'Modificación//Modification';

create table sg.token (
    id_token       serial primary key,
    id_usuario     integer not null constraint c_usuario references sg.usuarios (id_usuario) on delete restrict on update cascade,
    acceso_token   uuid default uuid_generate_v4() not null unique,
    coneccion      timestamp with time zone not null default current_timestamp
);

create table sg.suscriptores (
  id_suscriptor                 serial primary key,
  token                         uuid default uuid_generate_v4() not null unique,
  usuario                       text,
  correo                        text not null unique,
  clave                         text not null,
  "nombre"                      text,
  institucion                   text,
  "posicion"                    text,
  date_of_creation              timestamp with time zone not null default now(),
  comentario                    text default '',
  genero                        char(1) check ( genero in ( 'F' , 'M' ) )
);
comment on table  sg.suscriptores                   is 'Suscriptores//Suscriptors';
comment on column sg.suscriptores.id_suscriptor     is 'Suscriptor//Suscriptor';
comment on column sg.suscriptores.usuario           is 'Usuario//Login';
comment on column sg.suscriptores.correo            is 'Correo//Mail';
comment on column sg.suscriptores.token             is 'Token//Token';
comment on column sg.suscriptores.clave             is 'Clave//Password';
comment on column sg.suscriptores."nombre"          is 'Nombre Completo//Name';
comment on column sg.suscriptores.institucion       is 'Institución//Institution';
comment on column sg.suscriptores.posicion          is 'Cargo//Position';
comment on column sg.suscriptores.date_of_creation  is 'Creación//Creation';
comment on column sg.suscriptores.comentario        is 'Comentario//Comment';
comment on column sg.suscriptores.genero            is 'Género//Gender';
