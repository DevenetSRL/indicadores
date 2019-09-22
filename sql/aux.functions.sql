-- @file aux.functions.sql
--
-- @brief Funciones del esquema aux.
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

create or replace function aux.autocompletarMunicipios(
    token_          text )            -- + User connection token
returns void
language 'plpgsql'
as $__$
declare
    row_             record;
    idUser_          integer;
    procesarTexto_   text;
begin
    idUser_ = sg.comprobarAcceso( token_, 2000 );
    for row_ in
        select
            cod_ine,
            coalesce( cod_ine::text , '')
                || ' - ' || coalesce( nombre, '' )
                || ' - ' || coalesce( otros_nombres, '' )
                || ' - ' || coalesce( provincia, '' )
                || ' - ' || coalesce( amdes, '' )
                || ' - ' || coalesce( mancomunidad, '' ) as procesar,
            cod_ine
                || ': ' || coalesce( nombre, '' )
                || ' (' || abreviatura || '/' || coalesce( provincia, '' ) || ')' as autocompletado
          from
            municipios
              join
            aux.departamentos on ( cod_ine / 10000 = id_departamento )
    loop
       row_.procesar = glb.grafiasSimilares( row_.procesar );
       if exists ( select 1 from aux.automunicipios where cod_ine = row_.cod_ine ) then
           update aux.automunicipios
              set
                equivalente = row_.procesar,
                autocompleto = row_.autocompletado
              where
                cod_ine = row_.cod_ine;
       else
           insert into aux.automunicipios ( cod_ine, equivalente, autocompleto, id_creator, id_modificator )
           values ( row_.cod_ine, row_.procesar, row_.autocompletado, idUser_, idUser_ );
       end if;
    end loop;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

create or replace function aux.autocompletarAgregados(
    token_          text )            -- + User connection token
returns void
language 'plpgsql'
as $__$
declare
    rowDepartamento_  record;
    rowProvincia_     record;
    rowMancomunidad_  record;
    rowAmdes_         record;
    depto_            text;
    idUser_           integer;
    procesarTexto_    text;
    columnaOrigen_    text;
    autocompleto_     text;
    equivalente_      text;
    valor_            text;
begin
    idUser_ = sg.comprobarAcceso( token_, 2000 );
    -- Para departamentos
    for rowDepartamento_ in
        select distinct
            departamento
          from
            municipios
     loop
        columnaOrigen_ = 'departamento';
        valor_         = rowDepartamento_.departamento;
        autocompleto_  = 'Departamento: ' || valor_;
        equivalente_   = glb.grafiasSimilares( valor_ );
        if exists ( select 1 from aux.autoagregados
                      where columna_origen = columnaOrigen_
                            and valor = valor_ ) then
            update aux.autoagregados set
                autocompleto   = autocompleto_,
                equivalente    = equivalente_,
                columna_origen = columnaOrigen_,
                valor          = valor_
              where
                columna_origen = columnaOrigen_
                and valor = valor_;
        else
            insert into aux.autoagregados (
                autocompleto,
                equivalente,
                columna_origen,
                valor,
                id_creator,
                id_modificator )
              values (
                autocompleto_,
                equivalente_,
                columnaOrigen_,
                valor_,
                idUser_,
                idUser_ );
        end if;   
     end loop;

    -- Para provincias
    for rowProvincia_ in
        select 
            provincia, departamento
          from
            municipios
        group by 1 ,2
     loop
        columnaOrigen_ = 'provincia';
        valor_         = rowProvincia_.provincia;
        autocompleto_  = 'Provincia: ' || valor_ || ' (' || rowProvincia_.departamento || ')';
        equivalente_   = glb.grafiasSimilares( valor_ );
        if exists ( select 1 from aux.autoagregados
                      where columna_origen = columnaOrigen_
                            and valor = valor_ and autocompleto = autocompleto_ ) then
            update aux.autoagregados set
                autocompleto   = autocompleto_,
                equivalente    = equivalente_,
                columna_origen = columnaOrigen_,
                valor          = valor_
              where
                columna_origen = columnaOrigen_
                and valor = valor_;
        else
            insert into aux.autoagregados (
                autocompleto,
                equivalente,
                columna_origen,
                valor,
                id_creator,
                id_modificator )
              values (
                autocompleto_,
                equivalente_,
                columnaOrigen_,
                valor_,
                idUser_,
                idUser_ );
        end if;   
     end loop;

    -- Para mancomunidad (parte 1)
    for rowMancomunidad_ in
        select distinct
                  lista
                from
                  unnest(
                     string_to_array(
                     trim(
                          regexp_replace (  
                              regexp_replace( 
                                  regexp_replace(
                                       regexp_replace(
                                           ( select string_agg( mancomunidad, ',' ) from municipios mu  ),
                                             '[\]\[]',
                                             '',
                                             'g' ),
                                      ' *" *, *"',
                                      '","',
                                      'g'
                                   ), '^"', '', 'g'), '"$', '', 'g' )
                         ),
                  '","',
                  'g'
                )
                ) lista
                order by 1
     loop
        columnaOrigen_ = 'mancomunidad';
        valor_         = rowMancomunidad_.lista;
        autocompleto_  = 'Mancomunidades: ' || valor_;
        equivalente_   = glb.grafiasSimilares( valor_ );
        if exists ( select 1 from aux.autoagregados
                      where columna_origen = columnaOrigen_
                            and valor = valor_ ) then
            update aux.autoagregados set
                autocompleto   = autocompleto_,
                equivalente    = equivalente_,
                columna_origen = columnaOrigen_,
                valor          = valor_
              where
                columna_origen = columnaOrigen_
                and valor = valor_;
        else
            insert into aux.autoagregados (
                autocompleto,
                equivalente,
                columna_origen,
                valor,
                id_creator,
                id_modificator )
              values (
                autocompleto_,
                equivalente_,
                columnaOrigen_,
                valor_,
                idUser_,
                idUser_ );
        end if;   
     end loop;
    -- Para amdess
    for rowAmdes_ in
        select distinct
            amdes
          from
            municipios
     loop
        columnaOrigen_ = 'amdes';
        valor_         = rowAmdes_.amdes;
        autocompleto_  = 'Amdes: ' || valor_;
        equivalente_   = glb.grafiasSimilares( rowAmdes_.amdes );
        if exists ( select 1 from aux.autoagregados
                      where columna_origen = columnaOrigen_
                            and valor = valor_ ) then
            update aux.autoagregados set
                autocompleto   = autocompleto_,
                equivalente    = equivalente_,
                columna_origen = columnaOrigen_,
                valor          = valor_
              where
                columna_origen = columnaOrigen_
                and valor = valor_;
        else
            insert into aux.autoagregados (
                autocompleto,
                equivalente,
                columna_origen,
                valor,
                id_creator,
                id_modificator )
              values (
                autocompleto_,
                equivalente_,
                columnaOrigen_,
                valor_,
                idUser_,
                idUser_ );
        end if;   
     end loop;
     columnaOrigen_ = 'nacional';
     valor_ = 'Bolivia';
     autocompleto_ = 'Nacional: ' || valor_;
     equivalente_ = glb.grafiasSimilares( valor_ );
            insert into aux.autoagregados (
                id_autoagregado,
                autocompleto,
                equivalente,
                columna_origen,
                valor,
                id_creator,
                id_modificator )
              values (
                -1,
                autocompleto_,
                equivalente_,
                columnaOrigen_,
                valor_,
                idUser_,
                idUser_ );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

create or replace function aux.crearDepartamento(
    token_          text,            -- + User connection token
    idDepartamento_ integer,
    departamento_   text,
    abreviatura_    text,
    svg_            text )
returns void
language 'plpgsql'
as $__$
declare
    idUser_          integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2000 );
    insert into aux.departamentos (
        id_departamento,
        departamento,
        abreviatura,
        svg,
        id_creator,
        id_modificator )
      values (
        idDepartamento_,
        departamento_,
        abreviatura_,
        svg_,
        idUser_,
        idUser_ );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

create or replace function aux.leerArchivo(
    file_ text )  
returns text
language 'plpgsql'
as $__$
declare
    contenido_ text;
    tmp_     text;
begin
    file_ = quote_literal( file_ );
    tmp_ = quote_ident( uuid_generate_v4()::text );
    execute 'create temp table ' || tmp_ || ' ( content text )';
    execute 'copy ' || tmp_ || ' from ' || file_;
    execute 'select string_agg( content, E''\n'') from ' || tmp_ into contenido_;
    execute 'drop table ' || tmp_;
    return contenido_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

create or replace function aux.devolverCodigosAgregado(
    idAgregado_            integer )
    -- color_                 integer )
returns text
language 'plpgsql'
as $__$
declare
    tipoAgregado_ text;
    agregado_     text;
    filtro_       text;
    query_        text;
    archivo_      text;
    ruta_         text;
    row_          record;
    id_           text;
begin
    select columna_origen, valor into tipoAgregado_, agregado_ from aux.autoagregados where id_autoagregado = idAgregado_;
    if tipoAgregado_ is null then
      return '';
    end if;
    if tipoAgregado_ = 'nacional' then
         query_ = 'select cod_ine from municipios';
    elsif tipoAgregado_ = 'departamento' then
        query_ = format( $$ select cod_ine from municipios where departamento = '%s' $$, agregado_ );
    elsif tipoAgregado_ = 'provincia' then
        query_ = format( $$ select cod_ine from municipios where provincia = '%s' $$, agregado_ );
    elsif tipoAgregado_ = 'amdes' then
        query_ = format( $$ select cod_ine from municipios where amdes = '%s' $$, agregado_ );
    elsif tipoAgregado_ = 'mancomunidad' then
        filtro_ = 'mancomunidad like ''%"' || agregado_ ||'"%''';
        query_ = format( $$ select cod_ine from municipios where %s $$, filtro_ );
    end if;
    ruta_ = aux.leerArchivo( '/etc/indicadores/ruta-mapas.conf' );
    archivo_ = aux.leerArchivo( ruta_ || 'mapas/bolivia-m.svg' );
    for row_ in execute query_ loop
        id_ = row_.cod_ine::text;
        archivo_= replace( archivo_, id_, id_ ||  '" style="fill:#fff' );
    end loop;
    return archivo_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;



