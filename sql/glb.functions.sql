-- @file glb.functions.sql
--
-- @brief Funciones del esquema glb.
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

-- + > glb.checkError: Marcar un error en el backend para el middleware
create or replace function glb.checkError(
    STATE       text,           -- + Estado del error
    ERRM        text )          -- + Mensaje de error
returns text                    -- + Mensaje ajustado para el middleware
language 'plpgsql' immutable
as $__$
begin
    if left( STATE, 1 ) = 'P' -- Class P0 — PL/pgSQL Error
       and left( ERRM, 7 ) != '@ERROR:' then
        ERRM = format( $$@ERROR: %s@$$, ERRM );
    end if;
    return ERRM;
end;
$__$;

create or replace function glb.grafiasSimilares( texto_ text ) -- + Texto a procesar
returns text
language 'plpgsql'
as $__$
begin
       texto_ = lower( texto_ );
       texto_ = replace( texto_, 'v', 'b' ); 
       texto_ = replace( texto_, 'ka', 'ca' ); 
       texto_ = replace( texto_, 'ko', 'co' ); 
       texto_ = replace( texto_, 'ku', 'cu' ); 
       texto_ = replace( texto_, 'za', 'sa' ); 
       texto_ = replace( texto_, 'zo', 'so' ); 
       texto_ = replace( texto_, 'zu', 'su' ); 
       texto_ = replace( texto_, 'ze', 'se' ); 
       texto_ = replace( texto_, 'ce', 'se' ); 
       texto_ = replace( texto_, 'zi', 'si' ); 
       texto_ = replace( texto_, 'ci', 'si' ); 
       texto_ = replace( texto_, 'gi', 'ji' ); 
       texto_ = replace( texto_, 'ge', 'je' ); 
       texto_ = replace( texto_, 'hua', 'wa' ); 
       texto_ = replace( texto_, 'gua', 'wa' ); 
       texto_ = replace( texto_, 'ke', 'que' ); 
       texto_ = replace( texto_, 'ki', 'qui' ); 
       texto_ = replace( texto_, 'z', 's' ); 
       texto_ = replace( texto_, 'í', 'i' ); 
       texto_ = replace( texto_, 'ó', 'o' ); 
       texto_ = replace( texto_, 'ú', 'u' ); 
       texto_ = replace( texto_, 'á', 'a' ); 
       texto_ = replace( texto_, 'é', 'e' ); 
       texto_ = replace( texto_, 'll', 'y' ); 
       texto_ = replace( texto_, 'ñ', 'n' );
       texto_ = regexp_replace( texto_, '[^a-z0-9]', ' ', 'g' ); 
       texto_ = regexp_replace( texto_, '  +', ' ', 'g' ); 
   return trim( texto_ );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + Busca varias palabras dentro de una cadena
create or replace function glb.buscarMultiPalabras(
   texto_         text,
   buscar_        text
)
returns boolean                        -- + Éxito
language 'plpgsql'
as $__$
declare
   particulas_  text[];
   salida_ text = '';
begin
    particulas_ = string_to_array( buscar_, ' ' );
    for i in array_lower( particulas_, 1 )..array_upper( particulas_, 1 ) loop
        if position( particulas_[i] in texto_ ) = 0 then
            return false;
        end if;
        salida_ = salida_ || ' ' || particulas_[i];
    end loop;
    return true;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return false;
end;$__$;


----------------------------------------------------------------
-- + > glb.sysOpt: Obtener un parámetro u opción del sistema
create or replace function glb.sysOpt(
    key_        text )          -- + Option key
returns text                    -- + Valor de la opción de configuración
language 'plpgsql'
as $__$
declare
    valor_  text;
begin
    select opt_value into valor_ from glb."options" where opt_key = key_;
    return coalesce( valor_, '' );
end;$__$;

-- + > glb.sysOptI: Obtener un parámetro u opción como entero
create or replace function glb.sysOptI(
    key_        text )          -- + Option key
returns integer                 -- + Valor entero de la opción de configuración
language 'plpgsql'
as $__$
begin
    return glb.sysOpt( key_ )::integer;
end;$__$;

-- + > glb.sysOptB: Obtener un parámetro u opción como booleano
create or replace function glb.sysOptB(
    key_        text )          -- + Option key
returns boolean                 -- + Valor booleano de la opción de configuración
language 'plpgsql'
as $__$
declare
    valor_ text;
begin
    valor_ = lower( glb.sysOpt( key_ ) );
    return valor_ = any( '{yes,si,1,true,verdad,verdadero}' );
end;$__$;

-- + > glb.emailValid: Validar si es un mail válido
create or replace function glb.emailValid(
    email_      text )          -- + User email
returns bool
language plperlu
as $__$
    use Email::Address;
    my @addresses = Email::Address->parse($_[0]);
    return scalar(@addresses) > 0 ? 1 : 0;
$__$;


-- + > glb.newOption: [C|glb.options] Crea una opción de configuración
create or replace function glb.newOption(
    token_      text,           -- + User connection token
    key_        text,           -- + Option key
    valor_      text,           -- + Option value
    desc_       text )          -- + Opt description
returns text                    -- + Json de éxito
language 'plpgsql'
as $__$
declare
    idUser_     integer;
    idOption_   integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    key_ = trim( coalesce( key_, '' ) );
    if key_ = '' then
        raise exception 'The option key can''t be empty';
    end if;
    insert into glb.options (
        opt_key,
        opt_value,
        description,
        id_creator,
        id_modificator)
      values (
        key_,
        valor_,
        desc_,
        idUser_,
        idUser_ )
      returning
        id_option
      into
        idOption_;
    return json_build_object(
        'message', 'Option created succefully',
        'idOption', idOption_,
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;
$__$;

-- + > glb.listOptions: [R|glb.options] Lista de opciones
create or replace function glb.listOptions(
    token_      text,                   -- + User connection token
    idOption_   integer default null,   -- + Id option 
    status_     boolean default null    -- + True, actives, False inactives, null both
)
returns text                    -- + Json del informe
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    return json_build_object(
        'data', (
            select
                 array_to_json(array_agg(row_to_json(alloptions)))
               from
                (
                  select
                      row_to_json(t)
                    from (
                      select
                         "id_option",
                         "opt_key" as "Opción",
                         "opt_value" as "Valor",
                         "description" as "Descripción",
                         "enabled" as "Estado"
                        from
                          glb.options opt
                        where
                          ( status_ is null
                            or opt.enabled = status_ )
                          and
                           ( idOption_ is null
                             or id_option = idOption_ )
                    ) t ) alloptions ),
       'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > glb.dataOption: [R|glb.options] Datos de una opcion
create or replace function glb.dataOption(
    token_      text,           -- + User connection token
    idOption_   integer )       -- + Option id
returns text                    -- + Json del informe
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    if not exists ( select 1 from glb.options where id_option = idOption_ ) then
        raise exception 'Option not found';
    end if;
    return 
        ( select
              row_to_json(t)
            from (
              select
                  id_option,
                  opt_key,
                  opt_value,
                  description,
                  'ok' as status
                from
                  glb.options
                where
                  id_option = idOption_
            ) t );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > glb.editOption: [U|glb.options] Actualizar datos de opciones
create or replace function glb.editOption(
    token_          text,             -- + User connection token
    idOption_       integer,          -- + Id option
    optValue_       text,             -- + Value option
    description_    text)             -- + Description option
returns text                          -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from glb.options where id_option = idOption_) then
       raise exception 'Option not found';
    end if;
    update glb.options
      set
        "opt_value" = optValue_,
        "description" = description_
      where
        id_option = idOption_;
    return json_build_object(
        'message', 'Option saved', 
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > glb.delOptions: [D|glb.options] Borrar una opción
create or replace function glb.delOptions(
    token_      text,               -- + User connection token
    idOption_   integer)            -- + Option id
returns text                        -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from glb.options where id_option = idOption_) then
       raise exception 'Option not found';
    end if;
    update glb.options
      set
        enabled = false
      where
        id_option = idOption_;
    return json_build_object(
        'message', 'Option saved', 
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


