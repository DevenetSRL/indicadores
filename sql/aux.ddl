-- @file aux.ddl
--
-- @brief Estructura de datos del esquema aux.  El esquema aux es un
-- esquema auxiliar utilizado para datos de trabajo
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

create table aux.automunicipios(
  id_automunicipio              serial primary key,
  cod_ine                       integer null,
  equivalente                   text,
  autocompleto                  text,                 
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index automunicipios_creator     on aux.automunicipios (id_creator);
create index automunicipios_modificator on aux.automunicipios (id_modificator);
create index automunicipios_codigo      on aux.automunicipios (cod_ine);
comment on table  aux.automunicipios                            is 'Autocompletar municipios//Autocomplete municipalities ';
comment on column aux.automunicipios.id_automunicipio           is 'Identificador de autocompletador//Identifier autocomplete';
comment on column aux.automunicipios.cod_ine                    is 'Código INE//INE cod';
comment on column aux.automunicipios.equivalente                is 'Equivalente procesado//Processed equivalent ';
comment on column aux.automunicipios.autocompleto               is 'Resultado autocompletar//Autocomplete result';
comment on column aux.automunicipios.enabled                    is 'Registro activo//Enabled row|HIDE_BROWSE|HIDE_FILTER';
comment on column aux.automunicipios.id_creator                 is 'Creador//Creator|HIDE_ALL';
comment on column aux.automunicipios.date_of_creation           is 'Creación//Creation|HIDE_ALL';
comment on column aux.automunicipios.id_modificator             is 'Modificador//Modificator|HIDE_ALL';
comment on column aux.automunicipios.last_modification          is 'Modificación//Modification|HIDE_ALL';

create table aux.autoagregados(
  id_autoagregado               serial primary key,
  autocompleto                  text,                 
  equivalente                   text,
  columna_origen                text,
  valor                         text,
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index autoagregados_creator     on aux.autoagregados (id_creator);
create index autoagregados_modificator on aux.autoagregados (id_modificator);

comment on table  aux.autoagregados                            is 'Autocompletar municipios//Autocomplete aggregates';
comment on column aux.autoagregados.id_autoagregado            is 'Identificador de autoagregado//Identifier';
comment on column aux.autoagregados.autocompleto               is 'Resultado autocompletar//Autocomplete result';
comment on column aux.autoagregados.equivalente                is 'Equivalente procesado//Processed equivalent';
comment on column aux.autoagregados.columna_origen             is 'Columna orígen del tipo//Origin column';
comment on column aux.autoagregados.valor                      is 'Valor de la columna orígen//Valor';
comment on column aux.autoagregados.enabled                    is 'Registro activo//Enabled row|HIDE_BROWSE|HIDE_FILTER';
comment on column aux.autoagregados.id_creator                 is 'Creador//Creator|HIDE_ALL';
comment on column aux.autoagregados.date_of_creation           is 'Creación//Creation|HIDE_ALL';
comment on column aux.autoagregados.id_modificator             is 'Modificador//Modificator|HIDE_ALL';
comment on column aux.autoagregados.last_modification          is 'Modificación//Modification|HIDE_ALL';

create table aux.departamentos(
  id_departamento               serial primary key,
  departamento                  text,
  abreviatura                   text,
  svg                           text,
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index departamentos_creator     on aux.departamentos (id_creator);
create index departamentos_modificator on aux.departamentos (id_modificator);
comment on table  aux.departamentos                            is 'Autocompletar municipios//Autocomplete municipalities ';
comment on column aux.departamentos.id_departamento            is 'Identificador de autocompletador//Identifier';
comment on column aux.departamentos.departamento               is 'Departamento//Department ';
comment on column aux.departamentos.abreviatura                is 'Abreviatura//Acronym';
comment on column aux.departamentos.svg                        is 'Mapa SVG//SVG Map';
comment on column aux.departamentos.enabled                    is 'Registro activo//Enabled row|HIDE_BROWSE|HIDE_FILTER';
comment on column aux.departamentos.id_creator                 is 'Creador//Creator|HIDE_ALL';
comment on column aux.departamentos.date_of_creation           is 'Creación//Creation|HIDE_ALL';
comment on column aux.departamentos.id_modificator             is 'Modificador//Modificator|HIDE_ALL';
comment on column aux.departamentos.last_modification          is 'Modificación//Modification|HIDE_ALL';
