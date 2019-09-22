-- @file im.ddl
--
-- @brief Estructura de datos del esquema im.  El esquema im es un
-- esquema utilizado para datos y funciones referidas a los
-- indicadores municipales
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

create table im.acervos (
  id_acervo                    serial primary key,
  identificador                 text not null unique check ( length( identificador ) > 4 ),    
  titulo                        text not null,
  asunto                        text default '', 
  descripcion                   text default '',     
  editor                        text default '',   
  cobertura                     text default '',  
  creador                       text default '', 
  contribuidor                  text default '',     
  fecha                         text default '',
  tipo                          text default '',
  formato                       text default '',
  fuente                        text default '',
  lenguaje                      text default '',  
  relacion                      text default '',  
  copy_right                    text default '',
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index acervos_creator     on im.acervos (id_creator);
create index acervos_modificator on im.acervos (id_modificator);
comment on table  im.acervos                     is 'Acervo//Acervos';
comment on column im.acervos.id_acervo          is 'Acervo//Acervos'; -- Menu titulo
comment on column im.acervos.identificador       is 'Identificador//Identifier';
comment on column im.acervos.titulo              is 'Título//Titulo';
comment on column im.acervos.asunto              is 'Asunto//Subject';
comment on column im.acervos.descripcion         is 'Descripción//Descripcion';
comment on column im.acervos.editor              is 'Editor/Institución//Editor';
comment on column im.acervos.cobertura           is 'Alcance//Cobertura';
comment on column im.acervos.creador             is 'Creador//Creador';
comment on column im.acervos.contribuidor        is 'Otros colaboradores//Contribuidor';
comment on column im.acervos.fecha               is 'Fecha//Date';
comment on column im.acervos.tipo                is 'Tipo//Type';
comment on column im.acervos.formato             is 'Formato//Formato';
comment on column im.acervos.fuente              is 'Fuente//Fuente';
comment on column im.acervos.lenguaje            is 'Idioma//Language';
comment on column im.acervos.relacion            is 'Relaciones//Relation';
comment on column im.acervos.copy_right          is 'Propiedad intelectual//Rights';
comment on column im.acervos.enabled             is 'Registro activo//Enabled row';
comment on column im.acervos.id_creator          is 'Creador//Creator';
comment on column im.acervos.date_of_creation    is 'Creación//Creation';
comment on column im.acervos.id_modificator      is 'Modificador//Modificator';
comment on column im.acervos.last_modification   is 'Modificación//Modification';

create sequence orden_columna_seq;

create table im.columnas (
  id_columna                    serial primary key,
  id_acervo                    integer not null constraint acervos references im.acervos (id_acervo) on delete restrict on update cascade,
  nombre_columna                text not null check ( length( nombre_columna ) > 2 ),
  tipo_columna                  text,  -- Text, Number, Int, Date, Document
  descripcion                   text default '',     
  orden_columna                 integer default nextval( 'orden_columna_seq' ),
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index columnas_creator     on im.columnas (id_creator);
create index columnas_modificator on im.columnas (id_modificator);
comment on table  im.columnas                     is 'Columnas//Columnas';
comment on column im.columnas.id_columna          is 'Columna//Columnas'; -- Menu titulo
comment on column im.columnas.nombre_columna      is 'Nombre//Name';
comment on column im.columnas.tipo_columna        is 'Tipo//Type';
comment on column im.columnas.descripcion         is 'Descripción//Descripcion';
comment on column im.columnas.enabled             is 'Registro activo//Enabled row|HIDE_BROWSE|HIDE_FILTER';
comment on column im.columnas.id_creator          is 'Creador//Creator|HIDE_ALL';
comment on column im.columnas.date_of_creation    is 'Creación//Creation|HIDE_ALL';
comment on column im.columnas.id_modificator      is 'Modificador//Modificator|HIDE_ALL';
comment on column im.columnas.last_modification   is 'Modificación//Modification|HIDE_ALL';

create table im.uploads(
  id_upload                     serial primary key,
  descripcion                   text default '',
  identificador                 text not null check ( length( identificador ) > 4 ),    
  upload_date                   timestamp with time zone not null default now(),
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index uploads_creator     on im.uploads (id_creator);
create index uploads_modificator on im.uploads (id_modificator);
comment on table im.uploads                      is 'Subidas//Uploads';
comment on column im.uploads.id_upload           is 'Subida//Upload';
comment on column im.uploads.descripcion         is 'Descripción//Descripcion';
comment on column im.uploads.identificador       is 'Identificador//Identifier';
comment on column im.uploads.upload_date         is 'Creación//Creation|HIDE ALL';
comment on column im.uploads.enabled             is 'Registro activo//Enabled row|HIDE_BROWSE|HIDE_FILTER';
comment on column im.uploads.id_creator          is 'Creador//Creator|HIDE_ALL';
comment on column im.uploads.date_of_creation    is 'Creación//Creation|HIDE_ALL';
comment on column im.uploads.id_modificator      is 'Modificador//Modificator|HIDE_ALL';
comment on column im.uploads.last_modification   is 'Modificación//Modification|HIDE_ALL';

create table im.fichas(
  id_ficha                      serial primary key,
  titulo                        character varying (80) not null,
  svg                           text default '',
  descripcion                   text,  
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index fichas_creator     on im.fichas (id_creator);
create index fichas_modificator on im.fichas (id_modificator);
comment on table  im.fichas                     is 'Fichas Municipales//Municipals Cards ';
comment on column im.fichas.id_ficha            is 'Ficha Municipal//Municipal Card ';
comment on column im.fichas.titulo              is 'Título//Titulo';
comment on column im.fichas.svg                 is 'Documento svg//Document svg';
comment on column im.fichas.descripcion         is 'Descripción//Descripcion';
comment on column im.fichas.enabled             is 'Registro activo//Enabled row|HIDE_BROWSE|HIDE_FILTER';
comment on column im.fichas.id_creator          is 'Creador//Creator|HIDE_ALL';
comment on column im.fichas.date_of_creation    is 'Creación//Creation|HIDE_ALL';
comment on column im.fichas.id_modificator      is 'Modificador//Modificator|HIDE_ALL';
comment on column im.fichas.last_modification   is 'Modificación//Modification|HIDE_ALL';

create table im.sintesis(
  id_sintesis                   serial primary key,
  svg                           text default '',  
  titulo                        character varying (80) not null,
  html                          text default '',
  pdf                           text default '',
  descripcion                   text,
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index sintesis_creator     on im.sintesis (id_creator);
create index sintesis_modificator on im.sintesis (id_modificator);
comment on table  im.sintesis                     is 'Fichas Municipales//Municipals Cards ';
comment on column im.sintesis.id_sintesis         is 'Ficha Municipal//Municipal Card ';
comment on column im.sintesis.svg                 is 'Documento svg//Document svg';
comment on column im.sintesis.titulo              is 'Título//Titulo';
comment on column im.sintesis.html                is 'Documento html//Document html';
comment on column im.sintesis.pdf                 is 'Documento pdf//Document pdf';
comment on column im.sintesis.descripcion         is 'Descripción//Descripcion';
comment on column im.sintesis.enabled             is 'Registro activo//Enabled row|HIDE_BROWSE|HIDE_FILTER';
comment on column im.sintesis.id_creator          is 'Creador//Creator|HIDE_ALL';
comment on column im.sintesis.date_of_creation    is 'Creación//Creation|HIDE_ALL';
comment on column im.sintesis.id_modificator      is 'Modificador//Modificator|HIDE_ALL';
comment on column im.sintesis.last_modification   is 'Modificación//Modification|HIDE_ALL';

create table im.carrusel(
  id_carrusel                   serial primary key,
  descripcion                   text,
  columna                       integer not null constraint columna references im.columnas (id_columna) on delete restrict on update cascade,
  operacion                     text,
  resultado                     text,
  municipio                     text,
  cod_ine                       integer null,
  formato                       text,
  icono                         text,
  enabled                       boolean not null default true,
  id_creator                    integer not null constraint creator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  date_of_creation              timestamp with time zone not null default now(),
  id_modificator                integer not null constraint modificator references sg.usuarios (id_usuario) on delete restrict on update cascade,
  last_modification             timestamp with time zone not null default now()
);
create index carrusel_creator     on im.carrusel (id_creator);
create index carrusel_modificator on im.carrusel (id_modificator);
create index carrusel_columna     on im.carrusel (columna);
create index carrusel_codigo      on im.carrusel (cod_ine);
comment on table  im.carrusel                     is 'Carrusel de portada//Cover Carousel ';
comment on column im.carrusel.id_carrusel         is 'Identifcador de carrusel//Identifier carousel';
comment on column im.carrusel.descripcion         is 'Información de la columna//Column information';
comment on column im.carrusel.columna             is 'Columna procesada//Processed column ';
comment on column im.carrusel.operacion           is 'Operación consultada//Operation consulted';
comment on column im.carrusel.resultado           is 'Resultado de la operación//Operation result';
comment on column im.carrusel.municipio           is 'Municipio al que pertence el dato//Municipio al que pertence el dato';
comment on column im.carrusel.icono               is 'Icono del carrusel//Carousel icon';
comment on column im.carrusel.enabled             is 'Registro activo//Enabled row|HIDE_BROWSE|HIDE_FILTER';
comment on column im.carrusel.id_creator          is 'Creador//Creator|HIDE_ALL';
comment on column im.carrusel.date_of_creation    is 'Creación//Creation|HIDE_ALL';
comment on column im.carrusel.id_modificator      is 'Modificador//Modificator|HIDE_ALL';
comment on column im.carrusel.last_modification   is 'Modificación//Modification|HIDE_ALL';


