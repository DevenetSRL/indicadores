-- @file im.functions.sql
--
-- @brief Funciones del esquema im.
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

-- + > im.mergeTemplateWithData: [R|public.*] Mezcla acervos con plantilla
 -- + Los acervos a considerar, deben estar activos
create or replace function im.mergeTemplateWithData(
    codIne_       integer,        -- + Cod INE
    template_     text )          -- + Template
returns text                    -- + Merged template
language 'plpgsql'
as $__$
declare
    oldTemplate_   text;
    values_        text[];
    columnas_      text[];
    expressions_   text[];
    oldExpression_ text;
    expression_    text;
    field_         text;
    function_      text;
    tmpTxt_        text;
    relations_     text[];
    table_         text;
    row_           record;
    count_         integer;
    validCols_     text;
    keys_          text[];
    vals_          text[];
    valor_         text;
    upload_        text;
    query_         text;
    otherParams_   text;
    claveUpload_   text;
    fechaUpload_   text;
    titulo_        text;
    editor_        text;
    fuentes_       text = '';
    campo_         text;
    aggCols_       text;
    validCols2_    text;
begin
    oldTemplate_ = template_;
    template_ = replace( template_, E'\n', '' );
    template_ = replace( template_, E'\r', '' );
    template_ = regexp_replace( template_, '^[^{]*{{ ', '{{ ' );
    values_ = string_to_array( template_, '{{ ' );
    for i in array_lower( values_, 1 ) + 1..array_upper( values_, 1 ) loop
        oldExpression_ = replace( regexp_replace( values_[i], ' }}.*$', '' ), ' ', '' );
        expression_ = lower( oldExpression_ );
        field_ = regexp_replace( expression_, '^.*:', '' );
        field_ = regexp_replace( field_, '@.*$', '' );
        if expression_ <> field_ then
            expressions_ = array_append( expressions_, oldExpression_ );
        end if;
        if length( field_ ) > 0
            and coalesce( field_ != all( columnas_ ), true ) then
            columnas_ = array_append( columnas_, field_ );
            table_ = regexp_replace( field_, '\..*', '' );
            if coalesce( table_ != all( relations_ ), true ) then
                relations_ = array_append( relations_, table_ );
            end if;
        end if;
    end loop;
    for row_ in
        select
            ac.id_acervo,
            ac.identificador,
            x.id_upload,
            x.fecha,
            ac.titulo,
            ac.editor,
            array_agg( c.nombre_columna ) as campos            
          from
            im.acervos ac
              join
            ( select identificador, upload_date as fecha, max( id_upload ) as id_upload  from im.uploads group by 1, 2 ) x
                using ( identificador )
              join
            im.columnas c
                using ( id_acervo )
          where
            ac.enabled
            and identificador = any( relations_ )
          group by
            1, 2, 3, 4
    loop
        if not im.comprobarExistenciaTablaAcervos( row_.identificador ) then
            continue;
        end if;
        execute
            format( 'select count(*) from %I', row_.identificador )
          into
            count_;
        if count_ = 0 then
            continue;
        end if;
        aggCols_   = '';
        validCols2_ = '';
        for i in array_lower( columnas_, 1 ) .. array_upper( columnas_, 1 ) loop
            campo_ = regexp_replace ( columnas_[i], '^(.+)\.(.+)', '\2' );
            if left( columnas_[i], length( row_.identificador ) ) <> row_.identificador then
                continue;
            end if;
            if campo_ = 'cod_ine' or  campo_ = any( row_.campos ) then
                aggCols_   = aggCols_ || regexp_replace ( columnas_[i], '^(.+)\.(.+)', '\2' ) || '::text,';
                validCols2_ = validCols2_ || '''' || columnas_[i] || '''::text,';
            end if;
        end loop;
        aggCols_ = 'array[' || aggCols_ || ' cod_ine::text ' || ']';
        validCols2_ = 'array[' || validCols2_ || '''cod_ine''::text' || ']';
        upload_ = case when row_.identificador = 'municipios' then '' else ' and id_upload = ' || row_.id_upload end;
        query_ = format( 'select %s, %s from %s where cod_ine = %s %s',
                          aggCols_, validCols2_, row_.identificador, codIne_, upload_ );
        execute query_ into vals_, keys_ ;
        -- fuentes
        titulo_ = replace( upper( left( row_.titulo, 1 ) ) || lower( substring( row_.titulo, 2, length( row_.titulo ) ) ), 'bolivia', 'Bolivia' );
        fuentes_ = fuentes_ || titulo_ || ', ' || row_.editor || ', ' || fmt.fecha( row_.fecha::text )::text || '\n';
        for i in array_lower( keys_, 1 ) .. array_upper( keys_, 1 ) loop
            valor_ = coalesce( vals_[i], '' );
            field_ = keys_[i];
            oldTemplate_ = replace( oldTemplate_, '{{ ' || field_ || ' }}', valor_ );
            if array_length( expressions_, 1 ) is not null then
                for j in array_lower( expressions_, 1 ) .. array_upper( expressions_, 1 ) loop
                    expression_ = expressions_[j];
                    tmpTxt_ = regexp_replace( expression_, '^.*:', '' );
                    otherParams_ = regexp_replace( tmpTxt_, '^.*@|^[^@]*$', '' );
                    if otherParams_ <> '' then
                       tmpTxt_ = regexp_replace( tmpTxt_, '@.*$', '' );
                    end if;
                    if tmpTxt_ = field_ then
                        function_ = regexp_replace( expression_, ':.*$', '' );
                        if otherParams_ <> '' then
                           if ( function_ = 'mostrarImagen' ) then
                               oldTemplate_ = replace(
                                   oldTemplate_,
                                   '{{ ' || expression_ || ' }}', fmt.mostrarImagen( valor_, field_, codIne_::text, row_.id_upload::text, otherParams_ ) );
                           else
                               oldTemplate_ = replace(
                                   oldTemplate_,
                                   '{{ ' || expression_ || ' }}',
                                   im.executeFunction( function_, valor_, otherParams_ ) );
                           end if;
                        else
                            oldTemplate_ = replace(
                                oldTemplate_,
                                '{{ ' || expression_ || ' }}',
                                im.executeFunction( function_, valor_ ) );
                        end if;
                    end if;
                end loop;
            end if;
        end loop;
    end loop;
    fuentes_ = '<script>$(document).ready(
                function() { multiLinea( "'
                || substring( fuentes_, 0, length( fuentes_ ) -1 )
                || '", ''\1'' ); } );</script>';
    oldTemplate_ = regexp_replace(
        oldTemplate_,
        '{{ fuentes:@([^ ]+) }}', fuentes_, 'g'  );
    return trim( replace( oldTemplate_, E'\n', ' ' ) );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.preprocessSVG: Preprocesa un SVG a formato moustache
create or replace function im.preprocessSVG(
    svg_     text )             -- + Contenido SVG(en XML)
returns text                    -- + Contenido preparado
language 'plpgsql'
as $__$
begin
    -- Buscar los saltos de línea (y espacios) y reemplazarlos por
    -- espacio
    svg_ = regexp_replace( svg_, E'[\\n\\r ]+', ' ', 'g' );
    svg_ = regexp_replace( svg_, '> <', '><', 'g' );

    -- Buscar el inicio de etiqueta y agregar salto de línea
    svg_ = regexp_replace( svg_, '<([^/])', E'\n<\\1', 'g' );

    -- Reemplazar los elementos con atributo field con el valor en
    -- moustache
    --   Atributo href por la derecha:
    svg_ = regexp_replace(
         svg_,
         '(<[^ ]+ [^>]*)field="([^"]+)"([^>]*)xlink:href="[^"]+"([^>]*>)',
         E'\\1\\3xlink:href="{{ \\2 }}"\\4',
         'g' );
    --   Atributo href por la izquierda:
    svg_ = regexp_replace(
         svg_,
         '(<[^ ]+ [^>]*)xlink:href="[^"]+"([^>]*)field="([^"]+)"([^>]*>)',
         E'\\1\\2xlink:href="{{ \\3 }}"\\4',
         'g' );
    --   Elementos:
    svg_ = regexp_replace(
         svg_,
         '(<[^ ]+ [^>]*)field="([^"]+)"([^>]*>)[^<]+(</[^>]+>)',
         E'\\1\\3{{ \\2 }}\\4',
         'g' );
    --   Grupos id por la izquierda:
    svg_ = regexp_replace(
         svg_,
         '(<[^ ]+ [^>]*id=")([^"]+)("[^>]*)script="([^"]+)"([^>]*>)',
         E'\\1\\2\\3\\5\n{{ \\4@\\2 }}',
         'g' );
    svg_ = regexp_replace(
         svg_,
         '(<[^ ]+ [^>]*)script="([^"]+)"([^>]*id=")([^"]+)"([^>]*>)',
         E'\\1\\3\\4"\\5{{ \\2@\\4 }}',
         'g' );
    return svg_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.executeFunction(text): Ejecuta una función (si existe)
create or replace function im.executeFunction(
    functionName_     text,     -- + Nombre de la función
    parameter_        text )    -- + Parámetro
returns text                    -- + Contenido modificado
language 'plpgsql'
as $__$
declare
    result_ text;
    test_   text;
begin
    test_ = ( 'fmt.' || functionName_ || '(text)' )::regprocedure;
    parameter_ = replace( parameter_, '''', '''''' );
    execute format( $$select fmt.%s( '%s' )$$, functionName_, parameter_ ) into result_;
    return result_;
exception when others then
    raise warning 'La función %(text) no existe para el texto %', functionName_, parameter_;
    return parameter_;
end;$__$;

-- + > im.executeFunction(text,text): Ejecuta una función (si existe)
create or replace function im.executeFunction(
    functionName_     text,     -- + Nombre de la función
    parameter1_       text,     -- + Primer Parámetro
    parameter2_       text )    -- + Primer Parámetro
returns text                    -- + Contenido modificado
language 'plpgsql'
as $__$
declare
    result_ text;
    test_   text;
begin
    test_ = ( 'fmt.' || functionName_ || '(text,text)' )::regprocedure;
    parameter1_ = replace( parameter1_, '''', '''''' );
    parameter2_ = replace( parameter2_, '''', '''''' );
    execute format( $$select fmt.%s( '%s', '%s' )$$, functionName_, parameter1_, parameter2_ ) into result_;
    return result_;
exception when others then
    raise warning 'La función %(text,text) no existe para los parámetros % y %', functionName_, parameter1_, parameter2_;
    return parameter1_;
end;$__$;

--Infocard_pieces
-- + > im.createInfoCardPieces: [C|im.piezas_fichas] Crear coordenadas
create or replace function im.crearInfoFichasPieces(
    token_       text,             -- + User connection token
    x_           integer,          -- + Axis x
    y_           integer,          -- + Axis y
    tipo_        text default '',  -- + Type
    valor_       text default '')  -- + Value
returns void                     -- +
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    insert into im.piezas_fichas (
        x,
        y,
        "tipo",
        "valor",
        id_creator,
        id_modificator
    ) values (
        x_,
        y_,
        tipo_,
        valor_,
        idUsuario_,
        idUsuario_
    );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- LIST
-- + > im.listInfoCardPieces: [R|im.piezas_fichas] Lista
create or replace function im.listInfoCardPieces(
    token_         text,                  -- + User connection token
    idSelPiezaF_   integer default null,  -- + Id cardH
    estado_        boolean default null   -- + True, actives, False inactives, null both
)
returns text
language 'plpgsql'
as $__$
declare
    idInfoCardP_   integer;
begin
    idInfoCardP_ = sg.comprobarAcceso( token_, 2500 );
    return json_build_object(
        'data', (
            select
                 array_to_json( array_agg( row_to_json( allinfocardp ) ) )
               from
                (
                  select
                      row_to_json(t)
                    from (
                      select
                          id_pieza_ficha,
   			  "x" as "Eje X",
   			  "y" as "Eje Y",
   			  "tipo" as "Tipo",
   			  "valor" as "Valor",
                          enabled as "_Estado"
                        from
                          im.piezas_fichas icp
                        where
                          ( estado_ is null
                            or icp.enabled = estado_ )
                          and
                           ( idSelPiezaF_ is null
                             or id_pieza_ficha = idSelPiezaF_ )
                    ) t ) allinfocardp ),
       'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--DATA
-- + > im.dataInfoCardPieces: [R|im.piezas_fichas] Datos
create or replace function im.dataInfoCardPieces(
    token_         text,           -- + User connection token
    idSelPiezaF_   integer )       -- + infoCardP id
returns text                         -- +
language 'plpgsql'
as $__$
declare
    idInfoCardP_   integer;
begin
    idInfoCardP_ = sg.comprobarAcceso( token_, 2500 );
    if not exists ( select 1 from im.piezas_fichas where id_pieza_ficha = idSelPiezaF_ ) then
        raise exception 'infoCardP not found';
    end if;
    return
        ( select
              row_to_json(t)
            from (
              select
                  id_pieza_ficha,
                  x,
                  y,
                  "tipo",
                  "valor",
                  'ok' as status
                from
                  im.piezas_fichas
                where
                  id_pieza_ficha = idSelPiezaF_
            ) t );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- NEW
-- + > im.newinfoCardPieces: [C|im.piezas_fichas] Crea una nueva ficha agregada en el sistema
 -- + Nota: Los municipios se manejan por letras
create or replace function im.newinfoCardPieces(
    token_       text,            -- + User connection token
    x_           integer,         -- + Axis x
    y_           integer,         -- + Axis y
    tipo_        text default '', -- + Type
    valor_       text default '') -- + Value

returns text                     -- +
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
    idInfoCardP_   integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    insert into im.piezas_fichas (
        x,
        y,
        "tipo",
        "valor",
        id_creator,
        id_modificator
    ) values (
        x_,
        y_,
        tipo_,
        valor_,
        idUsuario_,
        idUsuario_)
      returning
        id_pieza_ficha
      into
        idInfoCardP_;
    return json_build_object(
        'message', 'infoCardP created succefully',
        'idinfoCardP', idInfoCardP_,
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--EDIT
-- + > im.editInfoCardPieces: [U|im.piezas_fichas] Actualizar datos de municipios agregados
create or replace function im.editInfoCardPieces(
    token_         text,             -- + User connection token
    idSelPiezaF_   integer,          -- + Id infocard piece
    x_             integer,          -- + Axis x
    y_             integer,          -- + Axis y
    tipo_          text default '',  -- + Type
    valor_         text default '')  -- + Value
returns text                          -- +
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from im.piezas_fichas where id_pieza_ficha = idSelPiezaF_) then
       raise exception 'infoCardP not found';
    end if;
    update im.piezas_fichas
      set
         "x" = x_,
         "y" = y_,
         "tipo" = tipo_,
         "valor" = valor_
      where
        id_pieza_ficha = idSelPiezaF_;
    return json_build_object(
        'message', 'infoCardP saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--DEL
-- + > im.delinfoCardPieces: [D|im.piezas_fichas] Elimina un municipios del sistema
create or replace function im.delinfoCardPieces(
    token_           text,             -- + User connection token
    idSelPiezaF_     integer)          -- + infoCardP id
returns text                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_       integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (
        select 1 from im.piezas_fichas where id_pieza_ficha = idSelPiezaF_ )
    then
       raise exception 'infoCardP not found';
    end if;
    update im.piezas_fichas
      set
        enabled = false
      where
        id_pieza_ficha = idSelPiezaF_;
    return json_build_object(
        'message', 'infoCardP saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


----------------------------------------------------------------

-- + > im.crearAcervos: [C|im.acervos,im.columnas] Crear un acervo de datos
create or replace function im.crearAcervos(
    token_          text,            -- + User connection token
    identificador_  text,            -- + Identificador (nombre de la tabla)
    titulo_         text,            -- + Título
    editor_         text,            -- + Editor/Institución
    columnas_       text[],          -- + Columnas (campo|tipo|descripcion)
    asunto_         text default '', -- + Asunto
    descripcion_    text default '', -- + Descripción
    contribuidor_   text default '', -- + Otros colaboradores
    cobertura_      text default '', -- + Alcance
    creador_        text default '', -- + Creador
    fecha_          text default '', -- + Fecha
    tipo_           text default '', -- + Tipo
    formato_        text default '', -- + Formato
    fuente_         text default '', -- + Fuente
    lenguaje_       text default '', -- + Idioma
    relacion_       text default '', -- + Relaciones
    copyRight_     text default '') -- + Derechos de autor
returns void
language 'plpgsql'
as $__$
declare
    idAcervos_   integer;
    idUsuario_   integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    -- Validar identificador
    identificador_ = lower( trim( identificador_ ) );
    if regexp_matches( identificador_, '^[^a-z][^a-z0-9_]+$', 'g' ) then
        raise exception 'Identificador "%" tiene caracteres invalidos', identificador_;
    end if;
    if length( identificador_ ) < 5 then
        raise exception 'Identificador "%" es muy corto (min. 5 caracteres)', identificador_;
    end if;
    -- Validar título
    titulo_ = lower( trim( titulo_ ) );
    if length( titulo_ ) < 5 then
        raise exception 'Título "%" es muy corto (min. 5 caracteres)', identificador_;
    end if;
    insert into im.acervos (
        "identificador",
        "titulo",
        "asunto",
        "descripcion",
        "editor",
        "cobertura",
        "creador",
        "contribuidor",
        "fecha",
        "tipo",
        "formato",
        fuente,
        "lenguaje",
        "relacion",
        "copy_right",
        enabled,
        id_creator,
        id_modificator
    ) values (
        identificador_,
        titulo_,
        asunto_,
        descripcion_,
        editor_,
        cobertura_,
        creador_,
        contribuidor_,
        fecha_,
        tipo_,
        formato_,
        fuente_,
        lenguaje_,
        relacion_,
        copyRight_,
        false,
        idUsuario_,
        idUsuario_
    )
    returning id_acervo
    into idAcervos_;
    if array_length( columnas_, 1) > 0 then
        perform im.crearColumnas( token_, idAcervos_, columnas_ );
    end if;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > im.crearColumnas: [C|im.columnas] Crear las columnas de un acervo
create or replace function im.crearColumnas(
    token_       text,            -- + User connection token
    idAcervos_   integer,         -- + Id acervos
    columnas_    text[] )         -- + Array of columnas
returns void                     -- +
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
    nombreColumna_  text;
    tipoColumna_    text;
    descColumna_    text;
    textos_         text[];
    estado_         boolean;
    id_             integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    select
         id_acervo,
         enabled
       into
         id_, estado_
       from
         im.acervos
       where
         id_acervo = idAcervos_;
    if id_ is null then
        raise exception 'Acervos no encontrados';
    end if;
    if estado_ then
        raise exception 'No puede modificar columnas en Acervos activos';
    end if;
    -- Creación de las columnas
    for i in array_lower( columnas_, 1 )..array_upper( columnas_, 1 ) loop
         textos_ = string_to_array( columnas_[i], '|' );
         nombreColumna_ = trim( coalesce( lower( textos_[1] ), '' ) );
         tipoColumna_ = textos_[2];
         descColumna_ = textos_[3];
         if length( nombreColumna_ ) < 2 then
             raise exception 'Columna % nombre % es muy corto. (Min. 2 caracteres)', i, nombreColumna_;
         end if;
         if not nombreColumna_ ~ '^[a-z][a-z0-9_]+$' then
             raise exception 'Columna % nombre % tiene caracteres invalidos.', i, nombreColumna_;
         end if;
    end loop;
    delete from im.columnas where id_acervo = idAcervos_;
    alter sequence orden_columna_seq restart with 1;
    insert into im.columnas (
        id_acervo,
        nombre_columna,
        tipo_columna,
        descripcion,
        id_creator,
        id_modificator )
      select
          id_acervo,
          c_name,
          c_type,
          descripcion,
          id_creator,
          id_modificator
        from
          ( select
                idAcervos_ as id_acervo,
                regexp_replace( lower( cols[1] ), '[^a-z0-9_]', '', 'g' ) as c_name,
                cols[2] as c_type,
                cols[3] as descripcion,
                idUsuario_ as id_creator,
                idUsuario_ as id_modificator
              from
                ( select string_to_array( s, '|' ) cols from
                    ( select s from unnest( columnas_ ) s ) col ) coldata
          ) finaldata
        where
          c_name not in ( 'cod_ine', 'id_upload' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    -- drop table pruebacsv;
    return ;
end;$__$;

-- + > im.activarAcervos: Activar la tabla de un acervo
create or replace function im.activarAcervos(
    token_         text,           -- + User connection token
    identificador_ text )          -- + Identificador (nombre de la tabla)
returns void
language 'plpgsql'
as $__$
declare
    idUsuario_    integer;
    idAcervos_    integer;
    titulo_       text;
    editor_       text;
    asunto_       text;
    descripcion_  text;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    select
        id_acervo,
        titulo,
        editor,
        asunto,
        descripcion
      into
        idAcervos_,
        titulo_,
        editor_,
        asunto_,
        descripcion_
      from
        im.acervos
      where
        identificador = identificador_;
    if idAcervos_ is null then
        raise exception 'Identificador "%" no encontrado. No se puede activar', identificador_;
    end if;
    identificador_ = lower( trim( identificador_ ) );
    if regexp_matches( identificador_, '^[^a-z][^a-z0-9_]+$', 'g' ) then
        raise exception 'Identificador "%" tiene caracteres invalidos. No se puede activar', identificador_;
    end if;
    if length( identificador_ ) < 5 then
        raise exception 'Identificador "%" es muy corto (min. 5 caracteres). No se puede activar', identificador_;
    end if;
    -- Validar título
    titulo_ = lower( trim( titulo_ ) );
    if length( titulo_ ) < 5 then
        raise exception 'Título de "%" es muy corto (min. 5 caracteres). No se puede activar', identificador_;
    end if;
    -- Validar fuente
    editor_ = lower( trim( editor_ ) );
    if length( editor_ ) < 5 then
        raise exception 'Editor de "%" es muy corto (min. 5 chars). No se puede activar', identificador_;
    end if;
    -- Validar asunto
    asunto_ = lower( trim( asunto_ ) );
    if length( asunto_ ) < 5 then
        raise exception 'Asunto de "%" es muy corto (min. 5 caracteres). No se puede activar', identificador_;
    end if;
    -- Validar descripción
    descripcion_ = lower( trim( descripcion_ ) );
    if length( descripcion_ ) < 5 then
        raise exception 'Descripcion de "%" es muy corto (min. 5 caracteres). No se puede activar', identificador_;
    end if;
    update im.acervos set enabled = true where identificador = identificador_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
end;$__$;

-- + > im.crearTablaAcervos: Crear la tabla de un acervo de datos (por id)
create or replace function im.crearTablaAcervos(
    token_       text,             -- + User connection token
    idAcervos_   integer )         -- + Identificador (nombre de la tabla)
returns void
language 'plpgsql'
as $__$
declare
    identificador_ integer;
begin
    raise exception 'muajaja';
    identificador_ = im.obtenerIdentificadorAcervos( idAcervos_ );
    if identificador_ is null then
        raise exception 'idAcervos no encontrado';
    end if;
    perform im.crearTablaAcervos( token_, identificador_ );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > im.crearTablaAcervos: Crear la tabla de un acervo de datos (por tablename)
create or replace function im.crearTablaAcervos(
    token_          text,            -- + User connection token
    identificador_  text )           -- + Identificador (nombre de la tabla)
returns void
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    -- Verificar que el acervo existe
    if not exists ( select 1 from im.acervos where identificador = identificador_ ) then
        raise exception 'Acervos % no encontrado', identificador_;
    end if;
    -- Verificar que el acervo está activo
    if not exists ( select 1 from im.acervos where identificador = identificador_ and enabled ) then
        raise exception 'Acervos % no está activo', identificador_;
    end if;
    -- Verificar que no existe la tabla
    if im.comprobarExistenciaTablaAcervos( identificador_ ) then
        raise exception 'Tabla % ya creada', identificador_;
    end if;
    execute im.crearSqlTablaAcervos( token_, identificador_ );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > im.comprobarExistenciaTablaAcervos: Verifica si existe la tabla de un acervo
create or replace function im.comprobarExistenciaTablaAcervos(
    identificador_  text )           -- + Identificador (nombre de la tabla)
returns boolean                   -- + Depende se si existe o no la tabla
language 'plpgsql'
as $__$
begin
    return exists ( select
                        1
                      from
                        pg_tables
                      where
                        schemaname = 'public'
                        and tablename = identificador_ );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return false;
end;$__$;

-- + > im.crearSqlTablaAcervos: Construir el SQL de creación una tabla de acervo
create or replace function im.crearSqlTablaAcervos(
    token_          text,             -- + User connection token
    identificador_  text,             -- + Identificador (nombre de la tabla)
    nombreTabla_    text default '' ) -- + Nombre de la tabla (nombre de la tabla)
returns text
language 'plpgsql'
as $__$
declare
    idAcervos_    integer;
    idUsuario_    integer;
    titulo_       text;
    sqlCreate_    text = '';
    sqlIndex_     text = '';
    sqlPK_        text = '';
    sqlCols_      text = '';
    sqlComments_  text = '';
    col_          record;
    fragment_     text = '';
    integrity_    text = ' on delete restrict on update cascade';
    temporary_    boolean = false;
    base_         boolean;
    _             text = E'\n';
    __            text = E',\n';
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    -- Extraer información del acervo
    select
        id_acervo,
        titulo
      into
        idAcervos_,
        titulo_
      from
        im.acervos
      where
        identificador = identificador_;
    -- Verifica que el acervo exista
    if idAcervos_ is null then
        raise exception 'Acervos "%" no encontrado', identificador_;
    end if;
    -- Verificar si existen columnas en el acervo
    if not exists( select 1 from im.columnas where id_acervo = idAcervos_ ) then
        raise exception 'Columna de acervos "%" no estan definidas', identificador_;
    end if;
    -- Definir las variables de estado
    base_ = ( identificador_ = 'municipios' );
    temporary_ = ( nombreTabla_ != '' );
    if not temporary_ then
        nombreTabla_ = identificador_;
    end if;
    -- SQL para crear la tabla del acervo
    -- Agregar cod_ine, comentario e índice
    sqlCols_ = '  cod_ine integer not null';
    if temporary_ or base_ then
        sqlCols_ = sqlCols_ ||__;
        sqlPK_ = 'cod_ine';
    else
        sqlPK_ = 'cod_ine, id_upload';
        sqlCols_ = sqlCols_
            || ' constraint ine references municipios (cod_ine)'
            || integrity_ ||__;
        -- Agregar id_upload
        sqlCols_ = sqlCols_
            || '  id_upload integer not null constraint upload '
            'references im.uploads (id_upload)' || integrity_ ||__ ;
    end if;
    if not temporary_ then
        sqlComments_ = format(
            'comment on table %I is %L;%s', nombreTabla_, titulo_, _ );
        sqlComments_ = sqlComments_
            || format(
                $$comment on column %I.cod_ine is 'Código INE';%s$$,
                nombreTabla_, _ );
    end if;
    if not temporary_ and not base_ then
        sqlComments_ = sqlComments_
            || format(
                $$comment on column %I.id_upload is 'Carga masiva';%s$$,
                nombreTabla_, _ );
        sqlIndex_ = sqlIndex_
            || format(
                 'create index %1$s_cod_ine on %1$I (cod_ine);%2$s'
                 'create index %1$s_id_upload on %1$I (id_upload);%2$s',
                 nombreTabla_, _ );
    end if;
    -- Agregar nombre del municipio
    if temporary_ and not base_ then
        sqlCols_ = sqlCols_ || '  nombre text' ||__;
        sqlComments_ = sqlComments_
            || format(
                $$comment on column %I.%I is 'Nombre del municipio';%s$$,
                nombreTabla_, 'nombre', _ );
    end if;
    for col_ in
        select
            "nombre_columna",
            tipo_columna,
            descripcion
          from
            im.columnas
          where
            id_acervo = idAcervos_
          order by
            orden_columna
    loop
        if not temporary_ then
            sqlComments_ = sqlComments_
                || format(
                    $$comment on column %I.%I is %L;%s$$,
                    nombreTabla_, col_.nombre_columna, col_.descripcion, _ );
        end if;
        if col_.tipo_columna = 'document' then
            col_.tipo_columna = 'text';
        end if;
        if col_.tipo_columna = 'number' then
            col_.tipo_columna = 'float';
        end if;
        sqlCols_ = sqlCols_
            || format( $$  %I %s%s$$, col_.nombre_columna, col_.tipo_columna, __ );
    end loop;
    if temporary_ then
        fragment_ = 'temporary ';
    end if;
    sqlCreate_ = format(
       $$create %stable %I (%s%s  primary key ( %s )%s);%s%s%s$$,
       fragment_, nombreTabla_, _, sqlCols_, sqlPK_, _, _,
       sqlIndex_, sqlComments_ );
    return sqlCreate_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.cargaAcervos: Carga un archivo csv en la db
create or replace function im.cargaAcervos(
    token_          text,            -- + User connection token
    identificador_  text,            -- + Identificador (nombre de la tabla)
    descripcion_    text,            -- + Descripción de la carga
    nombreArchivo_  text )           -- + Archivo CSV a importar
returns void
language 'plpgsql'
as $__$
declare
    idUsuario_       integer;
    sql_             text;
    campos_          text;
    columnas_        text;
    idActualizacion_ integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    -- Verificar que no existe la tabla
    if not im.comprobarExistenciaTablaAcervos( identificador_ ) then
        raise exception 'Tabla % debe ser creado', identificador_;
    end if;
    if identificador_ = 'municipios'
        and ( select count(*) from municipios ) > 0 then
        raise exception 'Table % ya esta poblado', identificador_;
    end if;
    -- Verificar si la estructura es correcta
    sql_ = im.crearSqlTablaAcervos( token_, identificador_, 'pruebacsv' )
        || E'\n'
        || format( $$copy pruebacsv from '%s' header csv;$$, nombreArchivo_ );
    execute sql_;
    insert into im.uploads (
        descripcion,
        identificador,
        upload_date,
        enabled,
        id_creator,
        id_modificator )
      values (
        descripcion_,
        identificador_,
        date( now() ),
        false,
        idUsuario_,
        idUsuario_ )
      returning
        id_upload
      into
        idActualizacion_;
    -- Calculando las columnas (en el mismo orden)
    select
        string_agg( col.nombre_columna, ', ' )
      into
        columnas_
      from (
        select
            c.nombre_columna
          from
            im.acervos a
              join
            im.columnas c using ( id_acervo )
          where
            a.identificador = identificador_
          order by
            c.orden_columna
      ) col;
    if identificador_ = 'municipios' then
        sql_ = format(
            $$insert into %1$I ( cod_ine, %2$s )
                select cod_ine, %2$s from %3$I$$,
            identificador_, columnas_, 'pruebacsv' );
    else
        sql_ = format(
            $$insert into %1$I ( id_upload, cod_ine, %2$s )
                select %3$L, cod_ine, %2$s from %4$I$$,
            identificador_, columnas_, idActualizacion_, 'pruebacsv' );
    end if;
    execute sql_;
    -- Borrando la tabla temporal
    drop table pruebacsv;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > im.crearInfoFichas: [C|im.fichas] Crear una ficha municipal
create or replace function im.crearInfoFichas(
    token_       text,             -- + User connection token
    titulo_      text,             -- + Card titulo
    svg_         text default '',  -- + Svg template
    descripcion_ text default '' ) -- + Descripcion
returns void                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    titulo_ = trim( coalesce( titulo_, '' ) );
    if titulo_ = '' then
        raise exception 'Título no puede ser vacio';
    end if;
    insert into im.fichas (
        titulo,
        svg,
        "descripcion",
        enabled,
        id_creator,
        id_modificator
    ) values (
        titulo_,
        svg_,
        descripcion_,
        false,
        idUsuario_,
        idUsuario_
    );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > im.activarInfoFicha: [U|im.fichas] Activar una ficha municipal
create or replace function im.activarInfoFicha(
    token_       text,             -- + User connection token
    idFicha_     integer )         -- + Id horizontal card
returns void                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    if not exists( select 1 from im.fichas where id_ficha = idFicha_ ) then
        raise notice 'Ficha % no encontrada', idFicha_;
    end if;
    update im.fichas
      set
        enabled = true,
        id_modificator = idUsuario_ ,
        last_modification = now()
      where
        id_ficha = idFicha_;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

create or replace function im.actualizarDatosCarrusel(
    token_          text )            -- + User connection token
returns void
language 'plpgsql'
as $__$
declare
    row_             record;
    idUsuario_       integer;
    tabla_           text;
    columna_         text;
    valor_           integer;
    codIne_          integer;
    municipio_       text;
    valorFormateado_ text;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    update im.carrusel set enabled = false;
    for row_ in
        select id_carrusel, columna, operacion, formato
        from im.carrusel
        where columna is not null and operacion is not null
    loop
       select
           a.identificador,
           c.nombre_columna
         into
           tabla_,
           columna_
         from
           im.columnas c
             join
           im.acervos a
             using( id_acervo )
         where
           c.id_columna = row_.columna;
       codIne_ = null;
       municipio_ = 'Todos los municipios';
       if row_.operacion = 'max' or row_.operacion = 'min' then
           execute format( $$ select %s( %I ) from %I $$, row_.operacion, columna_, tabla_ )
           into valor_;
           execute format( $$ select cod_ine from %I where %I = %s limit 1$$, tabla_, columna_, valor_ ) into codIne_;
           execute format( $$ select nombre from municipios where cod_ine = %L $$, codIne_ )
           into municipio_;
       else
           execute format( $$ select %s( %I ) from %I $$, row_.operacion, columna_, tabla_ )
           into valor_;
       end if;
       execute format( $$ select %s( '%s' ) $$, row_.formato, valor_::text ) into valorFormateado_;
       update
           im.carrusel
         set
           resultado = valorFormateado_,
           cod_ine = codIne_,
           municipio = municipio_,
           enabled = true
         where
           id_carrusel = row_.id_carrusel;
    end loop;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > listaCarrusel: [R|im.carrusel] Lista para el carrusel
create or replace function im.listaCarrusel()
returns text
language 'plpgsql'
as $__$
declare
begin
    return json_build_object(
       'status', 'ok',
       'data', ( select
                     json_agg( t )
                   from
                     (
                       select
                          descripcion,
                          resultado,
                          municipio,
                          cod_ine,
                          icono
                         from
                           im.carrusel
                         order by
                           municipio
                      ) t
                 )
           );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

create or replace function im.crearCarrusel(
    token_         text,            -- + User connection token
    descripcion_   text,            -- + Descripción de la columna
    columna_       integer,         -- + Nombre de la columna
    operacion_     text,            -- + Operación de la columna
    resultado_     text,            -- + Resultado de la operación
    municipio_     text,            -- + Municipio
    formato_       text,            -- + formato del campo
    icono_         text default '') -- + Ícono del carrusel
returns void
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    insert into im.carrusel (
        descripcion,
        columna,
        operacion,
        resultado,
        municipio,
        icono,
        formato,
        enabled,
        id_creator,
        id_modificator
    ) values (
        descripcion_,
        columna_,
        operacion_,
        resultado_,
        municipio_,
        icono_,
        formato_,
        true,
        idUsuario_,
        idUsuario_
    );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;


-----------------------------------------------------------------------------------------

-- + > im.updateAcervos: [U|im.acervos,im.columnas] Modificar datos de un acervo
create or replace function im.updateAcervos(
    token_          text,            -- + User connection token
    identificador_  text,            -- + Identificador (nombre de la tabla)
    titulo_         text,            -- + Título
    editor_         text,            -- + Editor/Institución
    asunto_         text,            -- + Asunto
    descripcion_    text,            -- + Descripción
    contribuidor_   text,            -- + Otros colaboradores
    cobertura_      text,            -- + Alcance
    creador_        text,            -- + Creador
    fecha_          text,            -- + Fecha
    tipo_           text,            -- + Tipo
    formato_        text,            -- + Formato
    fuente_         text,            -- + Fuente
    lenguaje_       text,            -- + Idioma
    relacion_       text,            -- + Relaciones
    copyRight_     text,            -- + Derechos de autor
    columnas_       text[] )         -- + Columnas (campo|tipo|descripcion)
returns void                      -- +
language 'plpgsql'
as $__$
declare
    idAcervos_     integer;
    idUsuario_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    select id_acervo into idAcervos_ from im.acervos where identificador = identificador_;
    if idAcervos_ is null then
        raise exception 'Identifier "%" not found', identificador_;
    end if;
    -- Validar título
    titulo_ = lower( trim( titulo_ ) );
    if length( titulo_ ) < 5 then
        raise exception 'Titulo "%" is too short (min. 5 chars)', identificador_;
    end if;
    -- Validar fuente
    editor_ = lower( trim( editor_ ) );
    if length( editor_ ) < 5 then
        raise exception 'Editor "%" is too short (min. 5 chars)', identificador_;
    end if;
    -- Validar asunto
    asunto_ = lower( trim( asunto_ ) );
    if length( asunto_ ) < 5 then
        raise exception 'Subject "%" is too short (min. 5 chars)', identificador_;
    end if;
    -- Validar descripción
    descripcion_ = lower( trim( descripcion_ ) );
    if length( descripcion_ ) < 5 then
        raise exception 'Descripcion "%" is too short (min. 5 chars)', identificador_;
    end if;
    update im.acervos set
        "identificador" = identificador_,
        "titulo" = titulo_,
        "asunto" = asunto_,
        "descripcion" = descripcion_,
        "editor" = editor_,
        "cobertura" = cobertura_,
        "creador" = creador_,
        "contribuidor" = contribuidor_,
        "fecha" = fecha_,
        "tipo" = tipo_,
        "formato" = formato_,
        fuente = fuente_,
        "lenguaje" = lenguaje_,
        "relacion" = relacion_,
        "copy_right" = copyRight_,
        id_modificator = idUsuario_ ,
        last_modification = now()
      where
        identificador = identificador_;
    -- Creación de las columnas
    perform im.crearColumnas( token_, idAcervos_, columnas_ );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > im.testCsvAcervos: Prueba la validez de un archivo csv
create or replace function im.testCsvAcervos(
    token_       text,            -- + User connection token
    identificador_  text,            -- + Identificador (nombre de la tabla)
    nombreArchivo_    text )           -- + Archivo CSV a importar
returns text
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
    sqlCreate_   text;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    -- Verificar que existe la tabla
    if not im.comprobarExistenciaTablaAcervos( identificador_ ) then
        raise exception 'Table % must be created', identificador_;
    end if;
    -- crear una tabla temporal
    sqlCreate_ = im.crearSqlTablaAcervos(
        token_, identificador_, 'pruebacsv', true, false );
    sqlCreate_ = sqlCreate_ || E'\n'
        || format( $$copy pruebacsv from '%s' header csv;$$, nombreArchivo_ );
    return sqlCreate_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    -- drop table pruebacsv;
    return '';
end;$__$;

-- + > im.getEmptyCSV: Construye un archivo csv vacío
create or replace function im.getEmptyCSV(
    token_          text,            -- + User connection token
    identificador_  text )           -- + Identificador (nombre de la tabla)
returns text
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
    idAcervos_   integer;
    csv_         text;
    qCommas_     integer;
    commas_      text;
    row_         record;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    -- Verificar que existe el acervo
    select id_acervo into idAcervos_ from im.acervos where identificador = identificador_;
    if idAcervos_ is null then
        raise exception 'Acervos % not found', identificador_;
    end if;
    -- Construir los encabezados
    select
        string_agg( "nombre_columna", ',' ),
        count( * )
      into
        csv_,
        qCommas_
      from (
        select
            "nombre_columna"
          from
            im.columnas
          where
            id_acervo = idAcervos_
          order by
            orden_columna
        ) cols;
    if identificador_ != 'municipios' then
        csv_ = 'nombres' || csv_;
        qCommas_ = qCommas_ + 1;
    end if;
    csv_ = 'cod_ine' || csv_ || '¶';
    commas_ = repeat( ',', qCommas_ );
    -- Rellenar con códigos INE y nombres de municipio
    for row_ in select cod_ine from municipios order by 1 loop
        csv_ = csv_ || row_.cod_ine || commas_ || '¶';
    end loop;
    return csv_;
    return replace( csv_, '¶', E'\n' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    -- drop table pruebacsv;
    return '';
end;$__$;

-- + > im.getEmptyCSV: Construye un archivo csv vacío
create or replace function im.getEmptyAcervos(
    token_         text,            -- + User connection token
    identificador_ text )           -- + Identificador (nombre de la tabla)
returns table (
    cod_ine        integer,
    nombre         text,
    commas         text )
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
    idAcervos_     integer;
    headers_       text;
    qColumnas_     integer;
    csv_           text;
    qCommas_       integer;
    commas_        text;
    row_           record;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    -- Verificar que existe el acervo
    select id_acervo into idAcervos_ from im.acervos where identificador = identificador_;
    if idAcervos_ is null then
        raise exception 'Acervos % not found', identificador_;
    end if;
    -- Construir los encabezados
    select
        string_agg( "nombre_columna", ',' ),
        count( * )
      into
        headers_,
        qColumnas_
      from (
        select
            "nombre_columna"
          from
            im.columnas
          where
            id_acervo = idAcervos_
          order by
            orden_columna
        ) cols;
    if identificador_ != 'municipios' then
        csv_ = 'municipio' || csv_;
    end if;
    return query
       select
         0,
         'Nombre'::text,
         headers_;
    return query
       select
         m.cod_ine,
         trim( m.nombre ),
         repeat( ',', qColumnas_ )::text
       from
         municipios m
       order by
         1;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    -- drop table pruebacsv;
    return ;
end;$__$;

-- + > im.deleteAcervos: [D|im.acervos] Eliminar un acervo (no activo)
create or replace function im.deleteAcervos(
    token_         text,            -- + User connection token
    identificador_ text )           -- + Acervos Identifier
returns void                     -- +
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
    idAcervos_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    select id_acervo into idAcervos_ from im.acervos where identificador = identificador_;
    if idAcervos_ is null then
        raise exception 'Acervos "%" not found', identificador_;
    end if;
    perform im.deleteAcervos( token_, idAcervos_ );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return ;
end;$__$;

-- + > im.deleteAcervos: [D|im.acervos] Eliminar un acervo (no activo)
create or replace function im.deleteAcervos(
    token_       text,            -- + User connection token
    idAcervos_   integer )        -- + Id acervos
returns void                     -- +
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
    columnName_  text;
    tipoColumna_ text;
    descColumna_ text;
    textos_      text[];
    estado_      boolean;
    id_          integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    select
         id_acervo,
         enabled
       into
         id_, estado_
       from
         im.acervos
       where
         id_acervo = idAcervos_;
    if id_ is null then
        raise exception 'Acervos not found';
    end if;
    if estado_ then
        raise exception 'Can''t delete acervos, because it was activated';
    end if;
    delete from im.columnas where id_acervo = idAcervos_;
    delete from im.acervos where id_acervo = idAcervos_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return ;
end;$__$;

-- + > im.reportAcervos: [R|im.acervos, im.columnas] Informe completo de un acervo
create or replace function im.reportAcervos(
    identificador_ text )          -- + Identifier of Acervos
returns text                    -- + Json del informe
language 'plpgsql'
as $__$
declare
    idAcervos_   integer;
begin
    select id_acervo into idAcervos_ from im.acervos where identificador = identificador_;
    if idAcervos_ is null then
        raise exception 'Acervos not found';
    end if;
    return im.reportAcervos( idAcervos_ );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.reportAcervos: [R|im.acervos, im.columnas] Informe completo de un acervo
create or replace function im.reportAcervos(
    idAcervos_   integer )       -- + Id Acervos
returns text                    -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    if not exists( select 1 from im.acervos where id_acervo = idAcervos_ ) then
        raise exception 'Acervos not found';
    end if;
    return (
      select
          row_to_json(t)
        from (
          select
              "identificador" as "Identificador",
              "titulo" as "Título",
              "asunto" as "Asunto",
              "descripcion" as "Descripción",
              "editor" as "Fuente",
              "cobertura" as "Alcance",
              "creador" as "Creador",
              "contribuidor" as "Contribuidor",
              "fecha" as "Fecha de acuerdo",
              "tipo" as "Tipo de información",
              "formato" as "Formato",
              fuente as "Fuente original",
              "lenguaje" as "Idioma",
              "relacion" as "Relación",
              "copy_right" as "Derechos",
              "enabled" as "_Estado",
              ( select array_to_json(array_agg(row_to_json(d)))
                    from (
                      select
                          orden_columna,
                          nombre_columna,
                          tipo_columna,
                          descripcion
                        from
                          im.columnas
                        where
                          id_acervo = acq.id_acervo
                        order by
                          orden_columna
                  ) d
              ) as "Columnas"
            from
              im.acervos acq
            where
              id_acervo = idAcervos_
          ) t
    );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.completeAcervosList: [R|im.acervos, im.columnas] Lista completa de acervo
create or replace function im.completeAcervosList(
    estado_    boolean default null -- + Status: true acties, false inctives null All
)
returns text                  -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    return
      ( select
            array_to_json( array_agg( row_to_json( mergedAcervos ) ) )
          from
            ( select
                  row_to_json( selectAcervos )
                from
                  ( select
                        "identificador",
                        "titulo",
                        "asunto",
                        "descripcion",
                        "editor",
                        "cobertura",
                        "creador",
                        "contribuidor",
                        "fecha",
                        "tipo",
                        "formato",
                        fuente,
                        "lenguaje",
                        "relacion",
                        "copy_right",
                        "enabled",
                        id_creator,
                        date_of_creation,
                        id_modificator,
                        last_modification,
                        ( select
                              array_to_json( array_agg( row_to_json( columnData ) ) )
                            from
                              ( select
                                    nombre_columna,
                                    tipo_columna,
                                    descripcion
                                  from
                                    im.columnas
                                  where
                                    id_acervo = acq.id_acervo
                                  order by
                                    orden_columna
                              ) columnData
                        ) as columnas
                      from
                        im.acervos acq
                      where
                        estado_ is null
                        or acq.enabled = estado_
                  ) selectAcervos
            ) mergedAcervos
      );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.simpleAcervosList: [R|im.acervos, im.columnas] Lista simple de acervos
create or replace function im.simpleAcervosList(
    estado_     boolean default null -- + True, actives, False inactives, null both
)
returns text                    -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    return
      ( select
            array_to_json( array_agg( row_to_json( mergedAcervos ) ) )
          from
            ( select
                  row_to_json( selectAcervos )
                from
                  ( select
                        "identificador",
                        "titulo",
                        "asunto",
                        "descripcion",
                        "editor",
                        "cobertura",
                        "creador",
                        "contribuidor",
                        "fecha",
                        "tipo",
                        "formato",
                        fuente,
                        "lenguaje",
                        "relacion",
                        "copy_right",
                        "enabled",
                        id_creator,
                        date_of_creation,
                        id_modificator,
                        last_modification
                      from
                        im.acervos acq
                      where
                        estado_ is null
                        or acq.enabled = estado_
                  ) selectAcervos
            ) mergedAcervos
      );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + > im.updateinfoCard: [U|im.fichas] Modificar una ficha municipal
create or replace function im.updateinfoCard(
    token_       text,             -- + User connection token
    idFicha_     integer,          -- + Id horizontal card
    titulo_      text,             -- + Titulo
    html_        text default '',  -- + Html template
    pdf_         text default '',  -- + Pdf template
    descripcion_ text default '' ) -- + Descripcion
returns void                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    if not exists( select 1 from im.fichas where id_ficha = idFicha_ ) then
        raise notice 'Card % not found', idFicha_;
    end if;
    titulo_ = trim( coalesce( titulo_, '' ) );
    if titulo_ = '' then
        raise exception 'Titulo can''t be empty';
    end if;
    update im.fichas
      set
        titulo = titulo_,
        html = html_,
        pdf = pdf_,
        "descripcion" = descripcion_,
        id_modificator = idUsuario_ ,
        last_modification = now()
      where
        id_ficha = idFicha_;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;


-- + > im.deleteinfoCard: [D|im.fichas] Eliminar una ficha municipal
create or replace function im.deleteinfoCard(
    token_       text,          -- + User connection token
    idFicha_   integer )        -- + Id horizontal card
returns void                    -- +
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    delete from im.fichas where id_ficha = idFicha_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return ;
end;$__$;

-- + > im.tituloListinfoCard: [R|im.fichas] Lista de fichas municipales
create or replace function im.tituloListinfoCard( )
returns text                    -- + Json of records
language 'plpgsql'
as $__$
declare
begin
    return
      ( select
            array_to_json( array_agg( row_to_json( d ) ) )
          from
            ( select
                  ch.titulo,
                  ch.descripcion
                from
                  im.fichas ch
            ) d
      );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.createCardV: [C|im.sintesis] Crear una ficha agregada
create or replace function im.createCardV(
    token_       text,             -- + User connection token
    titulo_      text,             -- + Card titulo
    svg_         text default '',
    descripcion_ text default '',  -- + Descripcion
    html_        text default '',  -- + Html template
    pdf_         text default ''  )  -- + Pdf template 
returns void                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    titulo_ = trim( coalesce( titulo_, '' ) );
    if titulo_ = '' then
        raise exception 'Titulo can''t be empty';
    end if;
    insert into im.sintesis (
        titulo,
        svg,
        html,
        pdf,
        "descripcion",
        enabled,
        id_creator,
        id_modificator
    ) values (
        titulo_,
        svg_,
        html_,
        pdf_,
        descripcion_,
        false,
        idUsuario_,
        idUsuario_
    );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > im.updateCardV: [U|im.sintesis] Modificar una ficha agregada
create or replace function im.updateCardV(
    token_       text,             -- + User connection token
    idAgregado_  integer,          -- + Id vertical card
    titulo_      text,             -- + Titulo
    html_        text default '',  -- + Html template
    pdf_         text default '',  -- + Pdf template
    descripcion_ text default '' ) -- + Descripcion
returns void                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    if not exists( select 1 from im.sintesis where id_sintesis = idAgregado_ ) then
        raise notice 'Card % not found', idAgregado_;
    end if;
    titulo_ = trim( coalesce( titulo_, '' ) );
    if titulo_ = '' then
        raise exception 'Titulo can''t be empty';
    end if;
    update im.sintesis
      set
        titulo = titulo_,
        html = html_,
        pdf = pdf_,
        "descripcion" = descripcion_,
        id_modificator = idUsuario_ ,
        last_modification = now()
      where
        id_sintesis = idAgregado_;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > im.activateCardV: [U|im.sintesis] Activar una ficha agregada
create or replace function im.activateCardV(
    token_       text,             -- + User connection token
    idAgregado_  integer )         -- + Id vertical card
returns void                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    if not exists( select 1 from im.sintesis where id_sintesis = idAgregado_ ) then
        raise notice 'Card % not found', idAgregado_;
    end if;
    update im.sintesis
      set
        enabled = true,
        id_modificator = idUsuario_ ,
        last_modification = now()
      where
        id_sintesis = idAgregado_;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > im.deleteCardV: [D|im.sintesis] Eliminar una ficha agregada
create or replace function im.deleteCardV(
    token_       text,          -- + User connection token
    idAgregado_  integer )        -- + Id vertical card
returns void                    -- +
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    delete from im.sintesis where id_sintesis = idAgregado_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return ;
end;$__$;

-- + > im.tituloListCardV: [R|im.sintesis] Lista de fichas agregadas
create or replace function im.tituloListCardV( )
returns text                    -- + Json of records
language 'plpgsql'
as $__$
declare
begin
    return
      ( select
            array_to_json( array_agg( row_to_json( d ) ) )
          from
            ( select
                  ch.titulo,
                  ch.descripcion
                from
                  im.sintesis ch
            ) d
      );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + > im.showTemplate: [R|public.*] Mezcla acervos con plantilla
 -- + Los acervos a considerar, deben estar activos
create or replace function im.showTemplate(
    codIne_     integer,        -- + Cod INE
    idFicha_    integer,        -- + Id Horizontal Template
    formato_    text )          -- + Format: 'pdf' or 'html'
returns text                    -- + Merged template
language 'plpgsql'
as $__$
declare
    pdf_        text;
    html_       text;
    id_         integer;
begin
    if formato_ != 'pdf' and formato_ != 'html' then
        raise exception 'Format only can be pdf or html';
    end if;
    select
        id_ficha,
        html,
        pdf
      into
        id_,
        html_,
        pdf_
      from
        im.fichas
      where
        id_ficha = idFicha_;
    if id_ is null then
        raise exception 'Id Card is not found';
    end if;
    if formato_ = 'pdf' then
        return im.mergeTemplateWithData( codIne_, pdf_ );
    else
        return im.mergeTemplateWithData( codIne_, html_ );
    end if;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.simpleFichasMunicipalesList: [R|im.fichas] Lista simple de fichas municipales
create or replace function im.simpleFichasMunicipalesList(
    estado_     boolean default null -- + True, actives, False inactives, null both
)
returns text                    -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    return
      ( select
            array_to_json( array_agg( row_to_json( mergedCards ) ) )
          from
            ( select
                  row_to_json( selectCards ) as data,
                  'ok' as status
                from
                  ( select
                        "titulo",
                        "descripcion"
                      from
                        im.fichas acq
                      where
                        estado_ is null
                        or acq.enabled = estado_
                  ) selectCards
            ) mergedCards
      );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.simpleFichasAgregadasList: [R|im.sintesis] Lista simple de fichas municipales agregadas
create or replace function im.simpleFichasAgregadasList(
    estado_     boolean default null -- + True, actives, False inactives, null both
)
returns text                         -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    return
      ( select
            array_to_json( array_agg( row_to_json( mergedCards ) ) )
          from
            ( select
                  row_to_json( selectCards )
                from
                  ( select
                        "titulo",
                        "descripcion"
                      from
                        im.sintesis acq
                      where
                        estado_ is null
                        or acq.enabled = estado_
                  ) selectCards
            ) mergedCards
      );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


--ACERVOS
-- LIST
-- + > im.listAcervos: [R|im.acervos] Lista de acervos
create or replace function im.listAcervos(
    token_            text,                  -- + User connection token
    idSelAcervos_     integer default null,  -- + Id resource
    estado_           boolean default null   -- + True, actives, False inactives, null both
)
returns text
language 'plpgsql'
as $__$
declare
    idAcervos_     integer;
begin
    idAcervos_ = sg.comprobarAcceso( token_, 2500 );
    return json_build_object(
        'data', (
            select
                 array_to_json(array_agg(row_to_json(allacervos)))
               from
                (
                  select
                      row_to_json(t)
                    from (
                      select
                          id_acervo,
                          "identificador" as "Identificador",
                          "titulo" as "Título",
                          "asunto" as "Tema",
                          "descripcion" as "Descripción",
                          "editor" as "Publicador",
                          "fecha" as "Fecha",
                          "enabled" as "_Estado"
                        from
                          im.acervos acq
                        where
                          ( estado_ is null
                            or acq.enabled = estado_ )
                          and
                           ( idSelAcervos_ is null
                             or id_acervo = idSelAcervos_ )
                    ) t ) allacervos ),
       'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--DATA
-- + > im.dataAcervos: [R|im.acervos] Datos de un acervo
create or replace function im.dataAcervos(
    token_           text,           -- + User connection token
    idSelAcervos_    integer )       -- + Acervos id
returns text                         -- +
language 'plpgsql'
as $__$
declare
    idAcervos_       integer;
begin
    idAcervos_ = sg.comprobarAcceso( token_, 2500 );
    if not exists ( select 1 from im.acervos where id_acervo = idSelAcervos_ ) then
        raise exception 'Acervos not found';
    end if;
    return
        ( select
              row_to_json(t)
            from (
              select
                  id_acervo,
                  identificador,
                  titulo,
                  asunto,
                  descripcion,
                  editor,
                  cobertura,
                  creador,
                  contribuidor,
                  "fecha",
                  "tipo",
                  format,
                  fuente,
                  "lenguaje",
                  relacion,
                  copy_right,
                  'ok' as status
                from
                  im.acervos
                where
                  id_acervo = idSelAcervos_
            ) t );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- NEW
-- + > im.newAcervos: [C|im.acervos] Crea un nuevo acervo para el sistema
 -- + Nota: Los acervos se manejan por letras
create or replace function im.newAcervos(
    token_          text,            -- + User connection token
    identificador_  text,            -- + Identifier acervos
    titulo_         text,            -- + Titulo aquis
    asunto_         text default '', -- + Subject acervos
    descripcion_    text default '', -- + Descripcion acervos
    editor_         text default '', -- + Editor acervos
    cobertura_      text default '', -- + Cobertura acervos
    creador_        text default '', -- + Creador acervos
    contribuidor_   text default '', -- + Contribuidor acervos
    fecha_          text default '', -- + Date acervos
    tipo_           text default '', -- + Type acervos
    formato_        text default '', -- + Format acervos
    fuente_         text default '', -- + Source acervos
    lenguaje_       text default '', -- + Language acervos
    relacion_       text default '', -- + Relacion acervos
    copyRight_      text default '') -- + Roghts acervos

returns text                     -- +
language 'plpgsql'
as $__$
declare
    idUsuario_     integer;
    idAcervos_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    insert into im.acervos (
        identificador,
        titulo,
        asunto,
        descripcion,
        editor,
        cobertura,
        creador,
        contribuidor,
        date,
        type,
        format,
        source,
        language,
        relacion,
        copy_right,
        id_creator,
        id_modificator)
      values (
        identificador_,
        titulo_,
        asunto_,
        descripcion_,
        editor_,
        cobertura_,
        creador_,
        contribuidor_,
        fecha_,
        tipo_,
        formato_,
        fuente_,
        lenguaje_,
        relacion_,
        copyRight_,
        idUsuario_,
        idUsuario_ )
      returning
        id_acervo
      into
        idAcervos_;
    return json_build_object(
        'message', 'Acervos created succefully',
        'idAcervos', idAcervos_,
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--EDIT
-- + > im.editAcervos: [U|im.acervos] Actualizar datos de acervos
create or replace function im.editAcervos(
    token_          text,             -- + User connection token
    idSelAcervos_   integer,          -- + Id resource
    identificador_  text,             -- + Identifier acervos
    titulo_         text,             -- + Titulo aquis
    asunto_         text default '',  -- + Subject acervos
    descripcion_    text default '',  -- + Descripcion acervos
    editor_         text default '',  -- + Editor acervos
    cobertura_      text default '',  -- + Cobertura acervos
    creador_        text default '',  -- + Creador acervos
    contribuidor_   text default '',  -- + Contribuidor acervos
    fecha_          text default '',  -- + Date acervos
    tipo_           text default '',  -- + Type acervos
    formato_        text default '',  -- + Format acervos
    fuente_         text default '',  -- + Source acervos
    lenguaje_       text default '',  -- + Language acervos
    relacion_       text default '',  -- + Relacion acervos
    copyRight_      text default '')  -- + Roghts acervos
returns text                          -- +
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from im.acervos where id_acervo = idSelAcervos_) then
       raise exception 'Acervos not found';
    end if;
    update im.acervos
      set
         "identificador" = identificador_,
         "titulo" = titulo_,
         "asunto" = asunto_,
         "descripcion" = descripcion_,
         "editor" = editor_,
         "cobertura" = cobertura_,
         "creador" = creador_,
         "contribuidor" = contribuidor_,
         "fecha" = fecha_,
         "tipo" = tipo_,
         "formato" = formato_,
         fuente = fuente_,
         "lenguaje" = lenguaje_,
         "relacion" = relacion_,
         "copy_right" = copyRight_
      where
        id_acervo = idSelAcervos_;
    return json_build_object(
        'message', 'Acervos saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--DEL
-- + > im.delAcervos: [D|im.acervos] Elimina un acervos del sistema
create or replace function im.delAcervos(
    token_          text,             -- + User connection token
    idSelAcervos_   integer)          -- + Acervos id
returns text                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from im.acervos where id_acervo = idSelAcervos_) then
       raise exception 'Acervos not found';
    end if;
    update im.acervos
      set
        enabled = false
      where
        id_acervo = idSelAcervos_;
    return json_build_object(
        'message', 'Acervos saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- LISTA MUNICIPIOS

-- LIST
-- + > im.listinfoCard: [R|im.fichas] Lista de municipios
create or replace function im.listinfoCard(
    token_          text,                  -- + User connection token
    idSelinfoCard_  integer default null,  -- + Id infoCard
    estado_         boolean default null   -- + True, actives, False inactives, null both
)
returns             text
language 'plpgsql'
as $__$
declare
    idFicha_        integer;
begin
    idFicha_ = sg.comprobarAcceso( token_, 2500 );
    return json_build_object(
        'data', (
            select
                 array_to_json(array_agg(row_to_json(allcardsh)))
               from
                (
                  select
                      row_to_json(t)
                    from (
                      select
                          id_ficha,
   			  "titulo" as "Título",
--   			  "svg" as Svg,
   			  "descripcion" as "Descripción",
                          "enabled" as "_Estado"
                        from
                          im.fichas car
                        where
                          ( estado_ is null
                            or car.enabled = estado_ )
                          and
                           ( idSelinfoCard_ is null
                             or id_ficha = idSelinfoCard_ )
                    ) t ) allcardsh ),
       'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.datainfoCard: [R|im.fichas] Datos de la ficha de un municipio
create or replace function im.datainfoCard(
    token_          text,           -- + User connection token
    idSelinfoCard_  integer )       -- + infoCard id
returns text                               -- +
language 'plpgsql'
as $__$
declare
    idFicha_        integer;
begin
    idFicha_ = sg.comprobarAcceso( token_, 2500 );
    if not exists ( select 1 from im.fichas where id_ficha = idSelinfoCard_ ) then
        raise exception 'infoCard not found';
    end if;
    return
        ( select
              row_to_json(t)
            from (
              select
                  id_ficha,
                  titulo,
                  svg,
                  "descripcion",
                  'ok' as status
                from
                  im.fichas
                where
                  id_ficha = idSelinfoCard_
            ) t );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.newinfoCard: [C|im.fichas] Crea un nuevo acervo para el sistema
 -- + Nota: Los municipios se manejan por letras
create or replace function im.newinfoCard(
    token_          text,             -- + User connection token
    titulo_         text,             -- + Card titulo
    svg_            text default '',  -- + Svg template
    descripcion_    text default '' ) -- + Descripcion
returns text                     -- +
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
    idFicha_        integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    insert into im.fichas (
        titulo,
        svg,
        "descripcion",
        id_creator,
        id_modificator
    ) values (
        titulo_,
        svg_,
        descripcion_,
        idUsuario_,
        idUsuario_ )
      returning
        id_ficha
      into
        idFicha_;
    return json_build_object(
        'message', 'infoCard created succefully',
        'idinfoCard', idFicha_,
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.editinfoCard: [U|im.fichas] Actualizar datos de municipios
create or replace function im.editinfoCard(
    token_          text,             -- + User connection token
    idSelinfoCard_  integer,          -- + Id cardH
    titulo_         text,             -- + Card titulo
    svg_            text default '',  -- + Svg template
    descripcion_    text default '' ) -- + Descripcion
returns text                          -- +
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from im.fichas where id_ficha = idSelinfoCard_) then
       raise exception 'infoCard not found';
    end if;
    update im.fichas
      set
         "titulo" = titulo_,
         "svg" = svg_,
         "descripcion" = descripcion_
      where
        id_ficha = idSelinfoCard_;
    return json_build_object(
        'message', 'infoCard saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.delinfoCard: [D|im.fichas] Elimina un municipios del sistema
create or replace function im.delinfoCard(
    token_           text,             -- + User connection token
    idSelinfoCard_   integer)          -- + infoCard id
returns text                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from im.fichas where id_ficha = idSelinfoCard_) then
       raise exception 'infoCard not found';
    end if;
    update im.fichas
      set
        enabled = false
      where
        id_ficha = idSelinfoCard_;
    return json_build_object(
        'message', 'infoCard saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- MUNIC AGREGADOS
-- LIST
-- + > im.listCardV: [R|im.sintesis] Lista de municipios agregados
create or replace function im.listCardV(
    token_          text,                  -- + User connection token
    idSelCardV_     integer default null,  -- + Id cardH
    estado_         boolean default null   -- + True, actives, False inactives, null both
)
returns text
language 'plpgsql'
as $__$
declare
    idAgregado_     integer;
begin
    idAgregado_ = sg.comprobarAcceso( token_, 2500 );
    return json_build_object(
        'data', (
            select
                 array_to_json( array_agg( row_to_json( allcardsv ) ) )
               from
                (
                  select
                      row_to_json(t)
                    from (
                      select
                          id_sintesis,
   			  "titulo" as "Título",
   			  "html" as "Código",
   			  "pdf" as "Pdf",
   			  "descripcion" as "Descripción",
                          "enabled" as "_Estado"
                        from
                          im.sintesis car
                        where
                          ( estado_ is null
                            or car.enabled = estado_ )
                          and
                           ( idSelCardV_ is null
                             or id_sintesis = idSelCardV_ )
                    ) t ) allcardsv ),
       'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--DATA
-- + > im.dataCardV: [R|im.sintesis] Datos de la ficha de un municipio
create or replace function im.dataCardV(
    token_          text,           -- + User connection token
    idSelCardV_     integer )       -- + CardV id
returns text                         -- +
language 'plpgsql'
as $__$
declare
    idAgregado_     integer;
begin
    idAgregado_ = sg.comprobarAcceso( token_, 2500 );
    if not exists ( select 1 from im.sintesis where id_sintesis = idSelCardV_ ) then
        raise exception 'CardV not found';
    end if;
    return
        ( select
              row_to_json(t)
            from (
              select
                  id_sintesis,
                  titulo,
                  html,
                  pdf,
                  "descripcion",
                  'ok' as status
                from
                  im.sintesis
                where
                  id_sintesis = idSelCardV_
            ) t );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- NEW
-- + > im.newCardV: [C|im.sintesis] Crea una nueva ficha agregada en el sistema
 -- + Nota: Los municipios se manejan por letras
create or replace function im.newCardV(
    token_          text,            -- + User connection token
    titulo_         text,             -- + Card titulo
    html_           text default '',  -- + Html template
    pdf_            text default '',  -- + Pdf template
    descripcion_    text default '' ) -- + Descripcion

returns             text                     -- +
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
    idAgregado_     integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    insert into im.sintesis (
        titulo,
        html,
        pdf,
        "descripcion",
        id_creator,
        id_modificator
    ) values (
        titulo_,
        html_,
        pdf_,
        descripcion_,
        idUsuario_,
        idUsuario_ )
      returning
        id_sintesis
      into
        idAgregado_;
    return json_build_object(
        'message', 'CardV created succefully',
        'idAgregado', idAgregado_,
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--EDIT
-- + > im.editCardV: [U|im.sintesis] Actualizar datos de municipios agregados
create or replace function im.editCardV(
    token_          text,             -- + User connection token
    idSelCardV_     integer,          -- + Id cardH
    titulo_         text,             -- + Card titulo
    html_           text default '',  -- + Html template
    pdf_            text default '',  -- + Pdf template
    descripcion_    text default '' ) -- + Descripcion
returns text                          -- +
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from im.sintesis where id_sintesis = idSelCardV_) then
       raise exception 'CardV not found';
    end if;
    update im.sintesis
      set
         "titulo" = titulo_,
         "html" = html_,
         "pdf" = pdf_,
         "descripcion" = descripcion_
      where
        id_sintesis = idSelCardV_;
    return json_build_object(
        'message', 'CardV saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--DEL
-- + > im.delCardV: [D|im.sintesis] Elimina un municipios del sistema
create or replace function im.delCardV(
    token_          text,             -- + User connection token
    idSelCardV_     integer)          -- + CardV id
returns text                       -- +
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from im.sintesis where id_sintesis = idSelCardV_) then
       raise exception 'CardV not found';
    end if;
    update im.sintesis
      set
        enabled = false
      where
        id_sintesis = idSelCardV_;
    return json_build_object(
        'message', 'CardV saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > im.generateInfoCards: [R|public.*] Mezcla acervos con plantilla
create or replace function im.generateInfoCards(
    token_          text,           -- + User connection token
    idFicha_        integer )          -- + idInfoCard
returns table (
    cod_ine         integer,
    info_card       text )
language 'plpgsql'
as $__$
declare
    idUsuario_      integer;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    return query
        select
            mun.cod_ine,
            trim( im.mergeTemplateWithData(
                mun.cod_ine,
                im.preprocessSVG( info.svg ) ) )
          from
            municipios   mun,
            im.fichas info
          where
            info.id_ficha = idFicha_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

--------------------------------------------------------------------

-- Web Service 3
-- + Devuelve json con todos los municipios que conciden con una palabra
create or replace function im.autolistarMunicipios(
   buscar_        text
)
returns text                        -- + Json del informe
language 'plpgsql'
as $__$
begin
    buscar_ = glb.grafiasSimilares( buscar_ );
    return json_build_object(
       'status', 'ok',
       'message' , 'Realizado',
       'data', ( select
                     json_agg( t )
                   from
                     (
                       select
                          cod_ine as id,
                          autocompleto as "desc"
                        from
                          aux.automunicipios
                        where
                          glb.buscarMultiPalabras( equivalente, buscar_ )
                          -- ' ' || equivalente like '%' || buscar_ || '%'
                    ) t
               )
    );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- Web Service 4
-- + Devuelve json con todos los agregados que conciden con una palabra
create or replace function im.autolistarAgregados(
   buscar_        text
)
returns text                        -- + Json del informe
language 'plpgsql'
as $__$
begin
    buscar_ = glb.grafiasSimilares( buscar_ );
    return json_build_object(
       'status', 'ok',
       'message' , 'Realizado',
       'data', ( select
                     json_agg( t )
                   from
                     (
                       select
                          id_autoagregado as id,
                          autocompleto as "desc"
                        from
                          aux.autoagregados
                        where
                          equivalente like '%' || buscar_ || '%'
                          and buscar_ not like ''
                    ) t
               )
    );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + Devueve id, servicio, valor solicitado
create or replace function im.devolverTipo(
   tipo_          text,           -- + Tipo de agregado : departamento, provincia, mancomunidad/amdes
   identificador_ text
)
returns json                        -- + Json del informe
language 'plpgsql'
as $__$
declare
    query_   text;
    srv_     text;
    id_      text;
    table_   text;
    campo_   text;
    lbl_     text;
    resultado_ text;
begin

     id_ = 'cod_ine';
     table_ = 'municipios';
     campo_ = tipo_;
     lbl_ = 'nombre';
     if ( tipo_ = 'departamento') then
        srv_ = 8;
        id_ = 'cod_ine/10000';
        table_ = 'municipios';
        campo_ = '(cod_ine)/10000';
        lbl_ = 'provincia';
     end if;
     if ( tipo_ = 'provincia') then
        srv_ = 7;
     end if;
     if ( tipo_ = 'amdes') then
        srv_ = 5;
     end if;
     if ( tipo_ = 'mancomunidad') then
        srv_ = 10;
     end if;
     query_ = format( $$
         select
             json_agg(t)
           from  
             (
     	       select
                   distinct
                   %s as "id",
     	           %s as "lbl",
     	           %s as "srv"
                 from
                   %s
                 where
                   %s = '%s'
                   ) t $$,
                 id_,
                 lbl_,
                 srv_,
                 table_,
                 campo_,
                 identificador_ );
       execute query_ into resultado_;
       return resultado_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- Web Service 2
-- + Muestra la ficha general del municipio
create or replace function im.mostrarFicha(
   codIne_        integer           -- + Codigo INE del municipio
)
returns text                        -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    if not exists ( select 1 from municipios where cod_ine = codIne_ ) then
      raise exception 'Municipio no encontrado ';
    end if;
    return json_build_object(
       'status', 'ok',
       'data', ( select
                     json_build_object( 
                         'municipio', nombre,
                         'departamento', departamento,
                         'amdes', amdes,
                         'provincia', provincia,
                         'mancomunidad', mancomunidad,
                         'munProvincia', im.devolverTipo( 'provincia' , provincia ),
                         'fichas', im.fichaSintesis( 'im.fichas', 'id_ficha' )
                     )
                   from
                     municipios
                   where
                     cod_ine = codIne_
               )
           );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + Devuelve listas de departamentos, provincias, mancomunidades y amdes
create or replace function im.devolverListas(
   deseado_   text,           -- + Dato a obtener
   columna_   text,           -- + Columna requerida: departamento,provincia,mancomunidad,amdes
   valor_     text            -- + Dato de comparación
)
returns json                        -- + Json del informe
language 'plpgsql'
as $__$
declare
    query_        text;
    resultado_    text;
begin             
     query_ = format( $$
         select
             json_agg( t )
           from
             (
                select
                    distinct %1$s as lbl, %1$s as id
                  from
                    municipios
                  where
                    %2$s = '%3$s'
                  order by
                    1
             ) t $$,
             deseado_,
             columna_,
             valor_ );
       execute query_ into resultado_;
       return resultado_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- Web Service 5
-- + Muestra la ficha general de Amdes o Mancomunidad
create or replace function im.mostrarAmdes(
   asociacion_        text           -- + Identificador de amdes o mancomunidad
)
returns text                        -- + Json del informe
language 'plpgsql'
as $__$
declare
   idAutoagregado_  integer;
begin
    if not exists ( select 1 from municipios where amdes = asociacion_ ) then
      raise exception 'La asociación no fue encontrada.';
    end if;
    select id_autoagregado into idAutoagregado_ from aux.autoagregados where asociacion_ = valor;    
    return json_build_object(
       'status', 'ok',
       'data', ( select
                     json_build_object(
                          'departamento', ( select distinct departamento from municipios where amdes = asociacion_ ),
                          'provincias', im.devolverListas( 'provincia', 'amdes', asociacion_ ),
                          'mancomunidades', im.concatenarJson( asociacion_, 'amdes' ),
                          'sintesis', im.fichaSintesis( 'im.sintesis', 'id_sintesis' ),
                          'id_depto', ( select distinct cod_ine/10000 from municipios where amdes = asociacion_ ),
                          'id_autoagregado', idAutoagregado_
                     )
               )
           );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;



-- Web Service 7
-- + Muestra la ficha de provincias con sus datos
create or replace function im.mostrarProvincia(
   provincia_        text           -- + Identificador de provincias
)
returns text                        -- + Json del informe
language 'plpgsql'
as $__$
declare
  idAutoagregado_ integer;
begin
    if not exists ( select 1 from municipios where provincia = provincia_ ) then
      raise exception 'La provincia no fue encontrada.';
    end if;
    select id_autoagregado into idAutoagregado_ from aux.autoagregados where provincia_ = valor;    
    return json_build_object(
       'status', 'ok',
       'data', ( select
                     json_build_object(
                        'provincia', ( select distinct provincia from municipios where provincia = provincia_ ),
                        'departamento',  ( select distinct departamento from municipios where provincia = provincia_ ) ,
                        'amdes', im.devolverListas( 'amdes', 'provincia', provincia_ ),
                        'munProvincias', im.devolverTipo( 'provincia', provincia_ ),
                        'sintesis', im.fichaSintesis( 'im.sintesis', 'id_sintesis' ),
                        'mancomunidades', im.concatenarJson( provincia_, 'provincia' ),
                        'id_provincia', ( select distinct cod_ine/100 from municipios where provincia = provincia_ ),
                        'id_autoagregado', idAutoagregado_
                     )
               )
           );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + función que devuelve las fichas de sintesis y Fichas normales
create or replace function im.fichaSintesis(
   tabla_        text,           -- + Nombre de la tabla 
   idTabla_      text         -- + Identificador de la tabla 
)
returns json                     -- + Json del informe
language 'plpgsql'
as $__$
declare
   query_     text;
   resultado_ text;
begin
      query_ = format( $$
           select
               json_agg( t )
             from
               (
                 select
                    %s as "id",
                    titulo as "lbl"
                 from
                    %s
                 where
                    %s
               ) t $$,
               idTabla_,
               tabla_,
               'enabled' );
       execute query_ into resultado_;
       return resultado_;      
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- Web Service 8
-- + Muestra la ficha de provincias con sus datos
create or replace function im.mostrarDepartamento(
   departamento_        text           -- + Identificador de provincias
)
returns text                        -- + Json del informe
language 'plpgsql'
as $__$
declare
 idAutoagregado_ integer;
begin
    if not exists ( select 1 from municipios where departamento = departamento_ ) then
      raise exception 'El departamento no fue encontrado.';
    end if;
    select id_autoagregado into idAutoagregado_ from aux.autoagregados where departamento_ = valor;
    raise notice 'Auto agregado%', idAutoagregado_;
    return json_build_object(
       'status', 'ok',
       'data', ( select
                     json_build_object(
                        'provincias', im.devolverListas( 'provincia', 'departamento', departamento_ ),
                        'amdes', im.devolverListas( 'amdes', 'departamento', departamento_ ),
                        'mancomunidades', im.concatenarJson( departamento_, 'departamento' ),
                        'sintesis', im.fichaSintesis( 'im.sintesis', 'id_sintesis' ),
                        'id_depto', ( select distinct cod_ine/10000 from municipios where departamento = departamento_ ),
                        'id_autoagregado', idAutoagregado_
                     )
           ) );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- Web Service 9
-- + Muestra todos los departamentos
create or replace function im.departamentos(
)
returns json                        -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    return json_build_object(
       'status', 'ok',
       'data', ( select
               json_agg( t )
             from
               (
                  select
                     departamento as "lbl", id_departamento as "id"
                  from
                      aux.departamentos
                  order by
                      1
               ) t ) ); 
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- Web Service 6
-- + Muestra la ficha nacional de bolivia
create or replace function im.mostrarFichaNacional(
)
returns text                        -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    return json_build_object(
       'status', 'ok',
       'data', ( select
                     json_build_object(              
                           'sintesis', im.fichaSintesis( 'im.sintesis', 'id_sintesis' ),
                           'id_autoagregado', -1,
                           'amdes', ( select
                                          json_agg( a )
                                        from
                                          (
                                           select
                                               distinct amdes as "lbl",
                                               amdes as "id"
                                             from
                                               municipios
                                          ) a
                                    )
   	             )
                 )
           );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

create or replace function im.concatenarJson(
    valor_        text,
    columna_      text
)
returns json                        -- + Json del informe
language 'plpgsql'
as $__$
declare
    query_    text;
begin
   raise notice '%-%',valor_,columna_;
   execute format( $$ select string_agg( mancomunidad, ',' ) from municipios mu where %s = '%s' $$, columna_, valor_ ) into query_;
   return ( select json_agg( t )
            from
              (
                select distinct
                  lista as "lbl", lista as "id"
                from
                  unnest(
                     string_to_array(
                     trim(
                          regexp_replace (  
                              regexp_replace( 
                                  regexp_replace(
                                       regexp_replace(
                                           ( query_  ),
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
                order by 1 ) t );
                
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- web service 10
create or replace function im.mostrarMancomunidad(
   mancomunidad_        text           -- + Identificador de mancomunidad
)
returns text                           -- + Json del informe
language 'plpgsql'
as $__$
declare
    idAutoagregado_ integer;
begin
    if not exists (
          select 1 from municipios where mancomunidad like '%' || mancomunidad_ || '%' ) then
      raise exception 'La mancomunidad no fue encontrada.';
    end if;
    select id_autoagregado into idAutoagregado_ from aux.autoagregados where mancomunidad_ = valor;    
    return json_build_object(
       'status', 'ok',
       'data', ( select
                     json_build_object(
                        'data_mancomunidad', im.filtroManco( mancomunidad_ ),
                        'sintesis', im.fichaSintesis( 'im.sintesis', 'id_sintesis' ),
                        'id_autoagregado', idAutoagregado_
                     )
               )
           );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

create or replace function im.filtroManco(
   mancomunidad_   text             -- + Dato a obtener
)
returns json                        -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    return ( select
                 json_agg (t)
               from ( 
                     select distinct
                         m.departamento,
                     	 m.cod_ine / 10000 idDepartamento,
                     	 m.provincia,
                     	 m.nombre,
                     	 m.cod_ine
                       from
                         municipios m
                          join
                         ( select replace( autocompleto, 'Mancomunidades: ', '' ) as manco from aux.autoagregados where columna_origen = 'mancomunidad' and equivalente like '%' || glb.grafiasSimilares( mancomunidad_ ) || '%' ) x
                     	    on ( m.mancomunidad ilike '%' || x.manco || '%' )
                       order by
                         m.cod_ine
                    ) t );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- Web Service 20
-- + Muestra el mapa del departamento e ilumina la provincia y el municipio
create or replace function im.mapaDepartamentoMunicipio(
    codIne_  integer,
    color_   text )
returns text                        -- + svg del mapa
language 'plpgsql'
as $__$
declare
    mapa_ text;
begin
    select
        svg
      into
        mapa_
      from
        aux.departamentos
      where
        id_departamento = codIne_ / 10000;
    if mapa_ is null then
        raise exception 'Código de municipio inexistente';
    end if;
    -- Colocar el departamento en color color_
    mapa_ = replace( mapa_, '{color}', color_ );
    mapa_ = regexp_replace( mapa_, '(id="' || ( codIne_ / 100 ) || '")', '\1 class="lighten-3 ' || color_ || '"', 'g' );
    mapa_ = regexp_replace( mapa_, '(id="' || codIne_ || '")', '\1 class="' || color_ || '"', 'g' );
    return json_build_object(
       'status', 'ok',
       'data', mapa_ );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + Web service 11
create or replace function im.mostrarAgregado(
   agregado_        integer           -- + Identificador agregado
)
returns text                        -- + Json del informe
language 'plpgsql'
as $__$
declare
  columna_   text;
  valor_     text;
  llamada_   text;
begin
    if not exists ( select 1 from aux.autoagregados where id_autoagregado = agregado_ ) then
      raise exception 'Agregado no encontrado ';
    end if;
    select columna_origen, valor into columna_, valor_ from aux.autoagregados where id_autoagregado = agregado_;
    return json_build_object(
       'status', 'ok',
       'columna', columna_ ,
       'valor', valor_ );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + Genera todas las fichas de algún id_ficha
create or replace function im.generarFichasParaTodosLosMunicipios(
   token_          text,
   idFicha_        integer,
   ruta_           text -- + Identificador de la ficha
)
returns void
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
    row_         record;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    if not exists ( select 1 from im.fichas where id_ficha = idFicha_ and enabled ) then
        raise exception 'Ficha inexistente ';
    end if;
    for row_ in select cod_ine from municipios loop
        execute format( $$
            copy ( select im.mergeTemplateWithData( %1$s, im.preprocessSVG( ( select svg from im.fichas where id_ficha = %2$s ) ) ) ) to '%3$s/f-%2$s/%1$s-%2$s.svg' $$, row_.cod_ine, idFicha_, ruta_ );
    end loop;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + Genera todas las fichas de algún id_ficha
create or replace function im.generarFichasParaUnMunicipio(
   token_          text,
   idFicha_        integer,
   codIne_         integer,
   ruta_           text -- + Identificador de la ficha
)
returns void
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
    row_         record;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    if not exists ( select 1 from im.fichas where id_ficha = idFicha_ and enabled ) then
        raise exception 'Ficha inexistente ';
    end if;
    for row_ in select cod_ine from municipios where cod_ine = codIne_ loop
        execute format( $$
            copy ( select im.mergeTemplateWithData( %1$s, im.preprocessSVG( ( select svg from im.fichas where id_ficha = %2$s ) ) ) ) to '%3$s/f-%2$s/%1$s-%2$s.svg' $$, row_.cod_ine, idFicha_, ruta_ );
    end loop;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + Genera la ficha síntesis de un autoagregado
create or replace function im.generarUnaFichaSintesis(
   token_          text,
   idSintesis_     integer,
   idAutoagregado_ integer,
   ruta_           text -- + Identificador de la ficha
)
returns void
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
    row_         record;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    if not exists ( select 1 from im.sintesis where id_sintesis = idSintesis_ and enabled ) then
        raise exception 'Síntesis inexistente ';
    end if;
    ruta_ = aux.leerArchivo( '/etc/indicadores/paths.conf' ) || ruta_;
    for row_ in select id_autoagregado from aux.autoagregados where id_autoagregado = idAutoagregado_ loop
        execute format( $$
            copy ( select im.prepararFichaSintesis( %1$s, im.preprocessSVG( ( select svg from im.sintesis where id_sintesis = %2$s ) ) ) ) to '%3$s/s-%2$s/%1$s-%2$s.svg' $$, row_.id_autoagregado, idSintesis_, ruta_ );
    end loop;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;


-- + > im.prepararFichaSintesis: [R|public.*] Mezcla acervos con plantilla ( Fichas de Síntesis )
 -- + Los acervos a considerar, deben estar activos.
create or replace function im.prepararFichaSintesis(
    idAutoagregado_       integer,        -- + Id del autoagregado
    template_             text )          -- + Template
returns text                    -- + Merged template
language 'plpgsql'
as $__$
declare
    oldTemplate_   text;
    values_        text[];
    columnas_      text[];
    campo_         text;
    expressions_   text[];
    oldExpression_ text;
    expression_    text;
    field_         text;
    function_      text;
    tmpTxt_        text;
    relations_     text[];
    table_         text;
    row_           record;
    keys_          text[];
    vals_          text[];
    valor_         text;
    query_         text;
    otherParams_   text;
    filtro_        text;
    agregado_      text;
    tipoAgregado_  text;
    aggCols_       text;
    validCols_     text;
    fuentes_       text = '';
    mapaBolivia_   text;
    upload_        text;
begin
    -- Filtro de autoagregado 
    select
        columna_origen,
        valor
      into
        tipoAgregado_,
        agregado_
      from
        aux.autoagregados
      where
        id_autoagregado = idAutoagregado_;
    if tipoAgregado_ is null then
      return template_;
    end if;
    if tipoAgregado_ = 'nacional' then
       filtro_ = ' cod_ine in ( ' || ( select string_agg( cod_ine::text, ',' ) from municipios ) || ' )';
    elsif tipoAgregado_ = 'departamento' then
       filtro_ = ' cod_ine/10000 = ' || ( select id_departamento from aux.departamentos where departamento = agregado_ );
    elsif tipoAgregado_ = 'provincia' then
       filtro_ = ' cod_ine/100 = ' || ( select cod_ine/100 from municipios where provincia = agregado_ limit 1 );
    elsif tipoAgregado_ = 'amdes' then
       filtro_ = ' cod_ine/10000 = ' || ( select cod_ine/10000 from municipios where amdes = agregado_ limit 1 );
    elsif tipoAgregado_ = 'mancomunidad' then
       filtro_ = ' cod_ine in ( ' || ( select string_agg( cod_ine::text, ',' ) from municipios where mancomunidad like '%"'|| agregado_ || '"%' ) || ' )'; 
    end if;
    oldTemplate_ = template_;
    template_ = replace( template_, E'\n', '' );
    template_ = replace( template_, E'\r', '' );
    template_ = regexp_replace( template_, '^[^{]*{{ ', '{{ ' );
    values_ = string_to_array( template_, '{{ ' );
    for i in array_lower( values_, 1 ) + 1..array_upper( values_, 1 ) loop
        oldExpression_ = replace( regexp_replace( values_[i], ' }}.*$', '' ), ' ', '' );
        expression_ = lower( oldExpression_ );
        field_ = regexp_replace( expression_, '^.*:', '' );
        field_ = regexp_replace( field_, '@.*$', '' );
        if expression_ <> field_ then
            expressions_ = array_append( expressions_, oldExpression_ );
        end if;
        if length( field_ ) > 0
            and coalesce( field_ != all( columnas_ ), true ) then
            columnas_ = array_append( columnas_, field_ );
            table_ = regexp_replace( field_, '\..*', '' );
            if coalesce( table_ != all( relations_ ), true ) then
                relations_ = array_append( relations_, table_ );
            end if;
        end if;
    end loop;
    for row_ in
        select
            a.id_acervo,
            a.identificador,
            x.id_upload,
            x.fecha,
            a.titulo,
            a.editor,
            array_agg( c.nombre_columna ) as campos
          from
            im.acervos a
              join
            ( select identificador, upload_date as fecha, max( id_upload ) as id_upload  from im.uploads group by 1, 2 ) x
                using ( identificador )
              join
            im.columnas c
                using ( id_acervo )
          where
            a.enabled
            and a.identificador = any( relations_ )
          group by
            1, 2, 3, 4
    loop
        if not im.comprobarExistenciaTablaAcervos( row_.identificador ) then
            continue;
        end if;
        aggCols_   = '';
        validCols_ = '';
        for i in array_lower( columnas_, 1 ) .. array_upper( columnas_, 1 ) loop
            campo_ = regexp_replace ( columnas_[i], '^(.+)\.(.+)#(.+)', '\2' );
            if left( columnas_[i], length( row_.identificador ) ) <> row_.identificador then
                continue;
            end if;
            if campo_ = 'cod_ine' or campo_ = any( row_.campos ) then
                if lower( regexp_replace ( columnas_[i], '^(.+)#', '' ) ) = 'string_agg' then
                    aggCols_   = aggCols_ ||regexp_replace ( columnas_[i], '^(.+)\.(.+)#(.+)', '\3(\2::text, '','')' ) || ',';
                else
                    aggCols_   = aggCols_ ||regexp_replace ( columnas_[i], '^(.+)\.(.+)#(.+)', '\3(\2)::text' ) || ',';
                end if;
                validCols_ = validCols_ || '''' || columnas_[i] || ''',';
            end if;
        end loop;
        if aggCols_ = '' then
            continue;
        end if;
        -- fuentes
        fuentes_ = fuentes_ || row_.titulo || ', ' || row_.editor || ', ' || fmt.fecha( row_.fecha::text )::text || '\n';
        aggCols_ = 'array[' || left( aggCols_, length( aggCols_ ) - 1 ) || ']';
        validCols_ = 'array[' || left( validCols_, length( validCols_ ) - 1 ) || ']';
        upload_ = case when row_.identificador = 'municipios' then '' else ' and id_upload = ' || row_.id_upload end;
        query_ = format( 'select %s, %s from %s where %s %s',
                          aggCols_, validCols_, row_.identificador, filtro_, upload_ );
        execute query_ into vals_, keys_ ;
        for i in array_lower( keys_, 1 ) .. array_upper( keys_, 1 ) loop
            valor_ = coalesce( vals_[i], '' );
            field_ = keys_[i];
            oldTemplate_ = replace( oldTemplate_, '{{ ' || field_ || ' }}', valor_ );
            if array_length( expressions_, 1 ) is not null then
                for j in array_lower( expressions_, 1 ) .. array_upper( expressions_, 1 ) loop
                    expression_ = expressions_[j];
                    tmpTxt_ = regexp_replace( expression_, '^.*:', '' );
                    otherParams_ = regexp_replace( tmpTxt_, '^.*@|^[^@]*$', '' );
                    if otherParams_ <> '' then
                       tmpTxt_ = regexp_replace( tmpTxt_, '@.*$', '' );
                    end if;
                    if tmpTxt_ = field_ then
                        function_ = regexp_replace( expression_, ':.*$', '' );          
                        if otherParams_ <> '' then
                           oldTemplate_ = replace(
                               oldTemplate_,
                               '{{ ' || expression_ || ' }}',
                               im.executeFunction( function_, valor_, otherParams_ ) );
                        else
                            oldTemplate_ = replace(
                                oldTemplate_,
                                '{{ ' || expression_ || ' }}',
                                im.executeFunction( function_, valor_ ) );
                        end if;
                    end if;
                end loop;
            end if;
        end loop;
    end loop;
    -- Genera el script de fuentes en la plantilla SVG
    fuentes_ = '<script>$(document).ready(
                function() { multiLinea( "'
                || substring( fuentes_, 0, length( fuentes_ ) -1 )
                || '", ''\1'' ); } );</script>';
    oldTemplate_ = regexp_replace(
        oldTemplate_,
        '{{ fuentes:@([^ ]+) }}', fuentes_, 'g'  );    
    -- Genera el nombre del agregado en la plantilla SVG
    oldTemplate_ = regexp_replace(
        oldTemplate_,
        '{{ agregado }}', initcap( tipoAgregado_ )|| ' : ' || agregado_, 'g'  );
   -- Genera el script del mapa de Boliva en la plantilla SVG
    mapaBolivia_ = '<script>$(document).ready( 
                function() { mostrarMapaBolivia( '
                || idAutoagregado_
                || ', ''\1'' ); } );</script>';   
    oldTemplate_ = regexp_replace(
        oldTemplate_,
        '{{ mapaBolivia:@([^ ]+) }}', mapaBolivia_, 'g'  );    
    return trim( replace( oldTemplate_, E'\n', ' ' ) );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + Genera todas las síntesis de algún id_sintesis
create or replace function im.generarFichasParaTodosLosAgregados(
   token_          text,
   idSintesis_     integer,
   ruta_           text -- + Identificador de la ficha
)
returns void
language 'plpgsql'
as $__$
declare
    idUsuario_   integer;
    row_         record;
begin
    idUsuario_ = sg.comprobarAcceso( token_, 2000 );
    if not exists ( select 1 from im.sintesis where id_sintesis = idSintesis_ and enabled ) then
        raise exception 'Síntesis inexistente ';
    end if;
    for row_ in select id_autoagregado from aux.autoagregados loop
        execute format( $$
            copy ( select im.prepararFichaSintesis( %1$s, im.preprocessSVG( ( select svg from im.sintesis where id_sintesis = %2$s ) ) ) ) to '%3$s/s-%2$s/%1$s-%2$s.svg' $$, row_.id_autoagregado, idSintesis_, ruta_ );
    end loop;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;
