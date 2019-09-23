-- @file fmt.functions.sql
--
-- @brief Funciones del esquema fmt.
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

-- + > sino: Convierte valor booleano en si/no
create or replace function fmt.sino(
    valor_            text )    -- + Altura (en m)
returns text                    -- + Altura con unidad
language 'plpgsql'
as $__$
declare
    result_ text;
begin
    return
        case
            when valor_ = 'true' or valor_ = 'TRUE' or valor_ = 't' then 'Si'
            else 'No'
        end;
exception when others then
    return 'No';
end;$__$;
comment on function fmt.sino(text) is
        'Dado un valor booleano, devuelve Si o No';

-- + > m2tokm2: Convierte un valor en m a Km
create or replace function fmt.mtokm(
    valor_            text )    -- + Metros
returns text                    -- + Kilómetros
language 'plpgsql'
as $__$
declare
    result_ text;
    m_     numeric;
begin
    m_ = valor_::numeric;
    return (round(  m_ / 1000, 1 ) )::text || ' Km';
exception when others then
    return valor_;
end;$__$;
comment on function fmt.mtokm(text) is
        'Convierte un valor en m a km y aumenta la unidad';

-- + > m2tokm2: Convierte un valor en Km²
create or replace function fmt.m2tokm2(
    valor_            text )    -- + Metros cuadrados
returns text                    -- + Kilómetros cuadrados
language 'plpgsql'
as $__$
declare
    result_ text;
    m2_     numeric;
    aux_    text;
begin
    m2_ = valor_::numeric;
    m2_ = round(  m2_ / 1000000, 1 );
    execute format( $$select fmt.millares( trunc( %s, 0 )::integer, ',' )$$, m2_ ) into result_;
    result_ = result_ || substr( m2_::text, position( '.' in m2_::text ) ) || ' Km²';
    return result_;
exception when others then
    return round(  m2_ / 1000000, 1 )::text || ' Km²';
end;$__$;
comment on function fmt.m2tokm2(text) is
        'Convierte un valor en m² a km² y aumenta la unidad';

-- + > msndm: Aumenta la unidad "msndm"
create or replace function fmt.msndm(
    valor_            text )    -- + Altura (en m)
returns text                    -- + Altura con unidad
language 'plpgsql'
as $__$
declare
    result_ text;
    m2_     integer;
begin
    m2_ = valor_::integer;
    return fmt.millares( m2_,',' )::text || ' msndm';
exception when others then
    return fmt.millares( m2_,',' )::text || ' msndm';
end;$__$;
comment on function fmt.msndm(text) is
        'Aumenta la unidad "msndm"';

-- + > mapaMunicipio: Muestra el mapa del municipio
create or replace function fmt.urlMapaMunicipio(
    codIne_          text )    -- + Código INE
returns text                    -- + SVG del mapa
language 'plpgsql'
as $__$
declare
    result_ text;
begin
    codIne_ = coalesce( codIne_, '' );
    if not exists( select 1 from municipios where cod_ine = codIne_ ) then
        raise exception 'Código Ine inexistente';
    end if;
    return format( $$%s/img/mapas/municipios/%s.svg$$,
        glb.sysOptI( 'web_root' ), codIne_ );
exception when others then
    return SQLERRM;
end;$__$;
comment on function fmt.urlMapaMunicipio(text) is
        'Url del mapa del municipio, dado su código INE';

-- + > mapaMunicipioDepartamento: Mapa del municipio y su departamento
create or replace function fmt.urlMapaDepartamento(
    codIne_          text )    -- + Código INE
returns text                    -- + SVG del mapa
language 'plpgsql'
as $__$
declare
    result_ text;
begin
    codIne_ = coalesce( codIne_, '' );
    if not exists( select 1 from municipios where cod_ine = codIne_ ) then
        raise exception 'Código Ine inexistente';
    end if;
    return format( $$%s/img/mapas/departamentos/%s.svg?codine=%s$$,
        glb.sysOptI( 'web_root' ), left( codIne_, 1 ), codIne_ );
exception when others then
    return SQLERRM;
end;$__$;
comment on function fmt.urlMapaDepartamento(text) is
        'Url del mapa del departamento y realce del área del municipio';

-- + > grados: Convierte un valor en °
create or replace function fmt.grados(
    valor_            text )    -- + Metros
returns text                    -- + Kilómetros
language 'plpgsql'
as $__$
declare
    result_ text;
    m_     numeric;
begin
    m_ = valor_::numeric;
    return round(  m_, 1 )::text || '°';
exception when others then
    return valor_;
end;$__$;
comment on function fmt.grados(text) is
        'Convierte un valor un decimal y agrega °';
        
-- + > vivienda: Agregao la unidad de viviendas
create or replace function fmt.vivienda(
    texto_            text )    -- + cantidad en texto
returns text
language 'plpgsql'
as $__$
declare
begin
    return fmt.millares( texto_::integer, ',' ) || ' viviendas';
exception when others then
    return m_;
end;$__$;
comment on function fmt.vivienda(text) is
        'Aumenta la unidad de viviendas a un valor.';
        
-- + > Tabla en SVG
create or replace function fmt.tablaTipoDesague    (
    tipoDesague_            text,
    id_                     text
    )
returns text
language 'plpgsql'
as $__$
declare
  valor_ text;
begin
    return ( format(
        $$<script>$(document).ready( function() { tabla( %s, '%s' ); } )</script>$$,
        tipoDesague_, id_ ) );
exception when others then
    return valor_;
end;$__$;
comment on function fmt.tablaTipoDesague( text, text ) is
        'Genera la instrucción para que javascript cree una tabla de datos';

-- + > Pirámide de población
create or replace function fmt.piramide(
    codIne_            text,     -- + Código INE
    idElement_         text )    -- + Id elemento SVG
returns text
language 'plpgsql'
as $__$
declare
   jsonResult_   text;
   columns_      text;
begin
    columns_ = '';
    for i in reverse 20..1 loop
          columns_ = columns_ || format(
            $$'{"t":"%1$s-%2$s","m":' || m_%1$s || ',"h":' || h_%1$s || '},' || $$,
            ( i - 1 ) * 5, i * 5 - 1 );
    end loop;
    columns_ = left( columns_, length( columns_ ) - 6 ) || '''';
    execute
        format( $$select %s from poblacion where cod_ine = %s order by id_upload desc limit 1
$$, columns_, codIne_ )
          into jsonResult_;
    return format(
        $$<script>$(document).ready( function() {piramide([%s],'%s');} )</script>$$,
        jsonResult_, idElement_ );
exception when others then
    return '<!-- Error en barras( ' || codIne_ || ' ) -->';
end;$__$;
comment on function fmt.piramide(text,text)
is 'Genera una la intrucción en javascript para crear la pirámide de población';
   
-- + > Formato para la fecha
create or replace function fmt.fecha(
    valor_            text )     -- + Valor a formatear
returns text
language 'plpgsql'
as $__$
declare
begin
    return to_char( valor_::date, 'DD/MM/YYYY' );
exception when others then
    return 'Error en la función';
end;$__$;
comment on function fmt.fecha(text) is 'Formato para la fecha en dd/mm/aa';
   
-- + > Obtiene el total de habitantes y adiciona la unidad de personas
create or replace function fmt.habitantes(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalHabitantes_    integer;
begin
    select
        ( mujer_rural + mujer_urbana + hombre_rural + hombre_urbana )
        into totalHabitantes_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalHabitantes_, ',' ) || ' personas' ;
exception when others then
    return totalHabitantes_ || ' habitantes';
end;$__$;
comment on function fmt.habitantes(text)
is 'Obtiene el total de habitantes en el municipio';
   
-- + > Cantidad niños en un municipio determinado
create or replace function fmt.cantidadninios(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalNinios_    text;
begin
    select
        ( h_0 + h_5 )::text into totalNinios_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalNinios_::integer, ',' ) || ' niños';
exception when others then
    return fmt.millares( totalNinios_::integer, ',' ) || ' niños';
end;$__$;
comment on function fmt.cantidadNinios(text)
is 'Obtiene el total de niños en el municipio';

-- + > Cantidad adultos mayores en un municipio determinado
create or replace function fmt.cantidadmayores(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalAdultos_    text;
begin
    select
        ( h_60 + h_65 + h_70 + h_75
        + h_80 + h_85 + h_90 + h_95 + h_100 )::text into totalAdultos_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalAdultos_::integer, ',' ) || ' hombres';
exception when others then
    return fmt.millares( totalAdultos_::integer, ',' ) || ' hombres';
end;$__$;
comment on function fmt.cantidadmayores(text)
is 'Obtiene el total de adultos mayores en el municipio';

-- + > multimlinea para normas
create or replace function fmt.multilinealeyes(
    norma_            text,
    id_               text    )
returns text
language 'plpgsql'
as $__$
declare
  valor_ text;
begin
    return ( format(
        $$<script>$(document).ready( function() { multiLinea( %s, '%s' ); } )</script>$$,
        norma_, id_ ) );
exception when others then
    return valor_;
end;$__$;
comment on function fmt.multilinealeyes( text, text ) is
        'Genera multilineas para las distintas leyes del municipio';

-- + > Formatea un valor con un separador
create or replace function fmt.millares(
    valor_            integer,
    separador_        text default ',' )
returns text
language 'plpgsql'
as $__$
declare
    nuevoSeparador_    text;
begin
    nuevoSeparador_ = '999' || separador_ || '999' || separador_ || '999';
    return trim( to_char( valor_, nuevoSeparador_ ) );
exception when others then
    return trim( to_char( valor_, nuevoSeparador_ ) );
end;$__$;
comment on function fmt.millares( integer, text ) is
        'Formatea un valor de acuerdo a un separador';

-- + > Tabla en SVG
create or replace function fmt.tablaTipoTenencia(
    tipoTenencia_            text,
    id_                      text
    )
returns text
language 'plpgsql'
as $__$
declare
  valor_ text;
begin
    return ( format(
        $$<script>$(document).ready( function() { tabla( %s, '%s' ); } )</script>$$,
        tipoTenencia_, id_ ) );
exception when others then
    return tipoTenencia_;
end;$__$;
comment on function fmt.tablaTipoTenencia( text, text )
is 'Genera la instrucción para que javascript cree una tabla de datos sobre el tipo de tenencia.';

-- + > Tabla en SVG
create or replace function fmt.tablaTipoAccesoAgua(
    tipoAcceso_            text,
    id_                     text
    )
returns text
language 'plpgsql'
as $__$
declare
begin
    return ( format(
        $$<script>$(document).ready( function() { tabla( %s, '%s' ); } )</script>$$,
        tipoAcceso_, id_ ) );
exception when others then
    return tipoAcceso_;
end;$__$;
comment on function fmt.tablaTipoAccesoAgua( text, text )
is 'Genera la instrucción para que javascript cree una tabla de datos sobre el tipo de acceso al agua.';

-- + > Genera la multilinea para que se formen lineas o viñetas de datos para las mancomunidades.
create or replace function fmt.multimanco(
    mancomunidad_            text,
    id_                      text
    )
returns text
language 'plpgsql'
as $__$
declare
begin
    if mancomunidad_ <> '' then
        mancomunidad_ = regexp_replace( mancomunidad_ , '[\[+\]+"+]','', 'g');
        mancomunidad_ = replace( mancomunidad_, ',', '\n' );
    else
        mancomunidad_ = 'Sin mancomunidad.';
    end if;
    return ( format(
        $$<script>$(document).ready( function() { multiLinea( "%s", "%s" ); } )</script>$$,
        mancomunidad_, id_ ) );
exception when others then
    return mancomunidad_;
end;$__$;
comment on function fmt.multimanco( text, text ) is
        'Genera la multilinea para que se formen lineas o viñetas de datos para las mancomunidades.';
        
-- + > multimlinea para normas
create or replace function fmt.listaleyes(
    texto_            text,
    id_               text )    -- + Metros
returns text                    -- + Kilómetros
language 'plpgsql'
as $__$
declare
begin
    return ( format(
        $$<script>$(document).ready( function() { xLinkLinea( '%s', '%s' ); } )</script>$$,
        texto_, id_ ) );
exception when others then
    return texto_;
end;$__$;
comment on function fmt.listaleyes(text,text) is
        'Pone enlaces a las normas en el SVG.';

create or replace function fmt.cantidadformateada(
    valor_            text )
returns text
language 'plpgsql'
as $__$
declare
begin
    return fmt.millares( valor_::integer, ',' ) || ' personas' ;
exception when others then
    return fmt.millares( valor_::integer, ',' ) || ' personas' ;
end;$__$;
comment on function fmt.cantidadformateada( text ) is
        'Formatea valor de los campos de un acervos con comas o espacios';

-- + > Cantidad adultos mayores en un municipio determinado
create or replace function fmt.cantidadmayoresmujeres(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalAdultosMujeres_    text;
begin
    select
        ( m_60 + m_65 + m_70 + m_75
        + m_80 + m_85 + m_90 + m_95 + m_100 )::text into totalAdultosMujeres_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalAdultosMujeres_::integer, ',' ) || ' mujeres';
exception when others then
    return fmt.millares( totalAdultosMujeres_::integer, ',' ) || ' mujeres';
end;$__$;
comment on function fmt.cantidadmayoresmujeres(text)
is 'Obtiene el total de adultos mayores del sexo femenino en el municipio';

-- + > Cantidad niños en un municipio determinado
create or replace function fmt.cantidadninias(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalNinias_    text;
begin
    select
        ( m_0 + m_5 )::text into totalNinias_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalNinias_::integer, ',' ) || ' niñas';
exception when others then
    return fmt.millares( totalNinias_::integer, ',' ) || ' niñas';
end;$__$;
comment on function fmt.cantidadninias(text)
is 'Obtiene el total de niñas en el municipio';


-- + > mostrarLogoAmde: Genéra un script para mostrar el logo de AMDE de forma dinámica
create or replace function fmt.mostrarLogoAmde(
    texto_            text,
    id_               text )    -- + Metros
returns text                    -- + Kilómetros
language 'plpgsql'
as $__$
declare
begin
    return format(
        $$<script>$(document).ready( function() { mostrarImagen( '%s', '%s' ); } )</script>$$,
        './img/' || lower( texto_ ) || '.svg', id_ );
exception when others then
    return texto_;
end;$__$;
comment on function fmt.mostrarLogoAmde(text,text) is
        'Muestra el logo de una AMDE de forma dinámica';

-- + > Genéra un script para mostrar la foto del alcalde de forma dinámica
create or replace function fmt.mostrarImagen(
    valor_            text,
    campo_            text,
    codIne_           text,
    upLoad_           text,
    id_               text )
returns text                
language 'plpgsql'
as $__$
declare
begin
    return format(
        $$<script>$(document).ready( function() { mostrarImagen( '%s', '%s' ); } )</script>$$,
        './img/fotos/'|| campo_||'_alcalde' || '/' || codIne_ || '-' || upLoad_ || '.' || lower( valor_ ), id_ );
exception when others then
    return valor_;
end;$__$;
comment on function fmt.mostrarImagen(text, text, text, text, text) is
        'Muestra la foto del alcalde municipal.';

-- + > Torta de población
create or replace function fmt.tortaPoblacion(
    codIne_            text,     -- + Código INE
    idElement_         text )    -- + Id elemento SVG
returns text
language 'plpgsql'
as $__$
declare
   jsonResult_   text;
begin
    select to_json( t )::text into jsonResult_
        from
            ( select
                 ( hombre_rural + hombre_urbana ) as "Hombres",
                 ( mujer_rural + mujer_urbana ) as "Mujeres"
               from
                 poblacion
               where cod_ine = codIne_::integer
               order by id_upload desc limit 1
            ) t;
    return format(
        $$<script>$(document).ready( function() {pie( %s, '%s' );} )</script>$$,
        jsonResult_, idElement_ );
exception when others then
    return '<!-- Error en tortaPoblacion( ' || codIne_ || ' ) -->';
end;$__$;
comment on function fmt.tortaPoblacion(text,text) is 'Genéra un script para una torta de población';


-- + > Multilinea Información fichas
create or replace function fmt.multiInformacion(
    texto_            text,
    id_               text
    )
returns text
language 'plpgsql'
as $__$
declare
begin
    return ( format(
        $$<script>$(document).ready( function() { multiLinea( "%s", "%s" ); } )</script>$$,
        texto_, id_ ) );
exception when others then
    return texto_;
end;$__$;
comment on function fmt.multiInformacion( text, text ) is
        'Genera título y editor de la ficha seleccionada.';

-- + > Muestra el mapa del municipio en las fichas 
create or replace function fmt.mostrarMapa(
    texto_            text,     -- + Campo a evaluar para la imagen
    id_               text )    -- + Identificador de elemento imagen
returns text 
language 'plpgsql'
as $__$
declare
begin
    return format(
        $$<script>$(document).ready( function() { mostrarImagen( '%s', '%s' ); } )</script>$$,
        './img/mapas/' || lower( texto_ ) || '.svg', id_ );
exception when others then
    return texto_;
end;$__$;
comment on function fmt.mostrarMapa(text,text) is
        'Muestra el mapa de un municipio';

-- + > Devuelve el resultado generado en el carrusel sumando la unidad mujeres
create or replace function fmt.mujeres(
    valor_            text )    -- + resultado obtenido del carrusel
returns text
language 'plpgsql'
as $__$
declare
begin
    return fmt.millares( valor_::integer, ',' ) || ' mujeres';
exception when others then
    return valor_;
end;$__$;
comment on function fmt.mujeres(text) is
        'Dado un resultado del carrusel adiciona la unidad de mujeres al valor';

-- + > Devuelve el resultado generado en el carrusel con la unidad de cantones
create or replace function fmt.cantones(
    valor_            text )    -- + resultado obtenido del carrusel
returns text
language 'plpgsql'
as $__$
declare
begin
    return fmt.millares( valor_::integer, ',' ) || ' cantones';
exception when others then
    return valor_;
end;$__$;
comment on function fmt.cantones(text) is
        'Dado un resultado del carrusel adiciona la unidad cantones al valor.';

-- + > Devuelve el resultado generado en el carrusel con la unidad de provincias
create or replace function fmt.provincia(
    valor_            text )    -- + resultado obtenido del carrusel
returns text
language 'plpgsql'
as $__$
declare
begin
    return fmt.millares( valor_::integer, ',' ) || ' provincias';
exception when others then
    return valor_;
end;$__$;
comment on function fmt.provincia(text) is
        'Dado un resultado del carrusel adiciona la unidad de  provincias al valor';
        
-- + > Devuelve el resultado generado en el carrusel con la unidad de hombres
create or replace function fmt.hombres(
    valor_            text )    -- + resultado obtenido del carrusel
returns text
language 'plpgsql'
as $__$
declare
begin
    return fmt.millares( valor_::integer, ',' ) || ' hombres';
exception when others then
    return valor_;
end;$__$;
comment on function fmt.hombres(text) is
        'Dado un resultado del carrusel adiciona unidad de hombres.';
create or replace function fmt.listaDeLeyes(
    texto_            text )    -- + Metros
returns text                    -- + Kilómetros
language 'plpgsql'
as $__$
declare
    row_    record;
    enlace_ text;
begin
    enlace_ = regexp_replace( texto_ , E'[[{]*"tit":"\([^"]+\)","id":"\([^"]+\)"[,}\]]*','<a xlink="https://lexivox.org/norms/\2.xhtml">\1</a>', 'g');
return enlace_;
exception when others then
    return enlace_;
end;$__$;
comment on function fmt.listaDeLeyes(text) is
        'Pone enlaces a las normas en el SVG.';

-- + > Obtiene el total de hombres y adiciona la unidad de hombres
create or replace function fmt.totalHombres(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalHombres_    integer;
begin
    select
        ( hombre_rural + hombre_urbana )into totalHombres_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalHombres_, ',' ) || ' hombres' ;
exception when others then
    return totalHombres_ || ' hombres';
end;$__$;
comment on function fmt.totalHombres( text )
is 'Obtiene el total de hombres en el municipio';

-- + > Obtiene el total de mujeres y adiciona la unidad de mujeres
create or replace function fmt.totalMujeres(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalMujeres_    integer;
begin
    select
        ( mujer_rural + mujer_urbana )into totalMujeres_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalMujeres_, ',' ) || ' mujeres' ;
exception when others then
    return totalMujeres_ || ' mujeres';
end;$__$;
comment on function fmt.totalMujeres( text )
is 'Obtiene el total de mujeres en el municipio';

-- + > Torta de viviendas
create or replace function fmt.tortaVivendas(
    codIne_            text,     -- + Código INE
    idElement_         text )    -- + Id elemento SVG
returns text
language 'plpgsql'
as $__$
declare
   jsonResult_   text;
begin
    select to_json( t )::text into jsonResult_
        from
            ( select
                 rural  as "Área rural",
                 urbana as "Área urbana"
               from
                 vivienda
               where cod_ine = codIne_::integer
               order by id_upload desc limit 1
            ) t;
    return format(
        $$<script>$(document).ready( function() {pie( %s, '%s' );} )</script>$$,
        jsonResult_, idElement_ );
exception when others then
    return '<!-- Error en tortaViviendas( ' || codIne_ || ' ) -->';
end;$__$;
comment on function fmt.tortaVivendas( text, text ) is 'Genéra un script para una torta de viviendas';

-- + > Torta de poblacion hombres en area rural, urbana y mujeres en area rural, urbana
create or replace function fmt.tortaUrbanoRural(
    codIne_            text,     -- + Código INE
    idElement_         text )    -- + Id elemento SVG
returns text
language 'plpgsql'
as $__$
declare
   jsonResult_   text;
begin
    select to_json( t )::text into jsonResult_
        from
            ( select
                 hombre_rural as "Hombre rural",
                 hombre_urbana as "Hombre urbana",
                 mujer_rural as "Mujer rural",
                 mujer_urbana as "Mujer urbana"
              from
                 poblacion
              where cod_ine = codIne_::integer
              order by id_upload desc limit 1
            ) t;
    return format(
        $$<script>$(document).ready( function() {pie( %s, '%s' );} )</script>$$,
        jsonResult_, idElement_ );
exception when others then
    return '<!-- Error en tortaUrbanoRural( ' || codIne_ || ' ) -->';
end;$__$;
comment on function fmt.tortaVivendas( text, text )
is 'Genéra un script para una torta de hombres  y mujeres en el área rural, urbana';

-- + > Formato para amentar  formato de decimales
create or replace function fmt.formatoMillares(
    valor_            text )
returns text
language 'plpgsql'
as $__$
declare
begin
    return fmt.millares( valor_::integer, ',' )::text;
exception when others then
    return valor_;
end;$__$;
comment on function fmt.formatoMillares( text ) is
        'Formatea un valor para ponerle decimales';
        
-- + > Dada una lista de códigos ine separados por coma, cuenta las provincias
create or replace function fmt.contarProvincias(
    valor_            text )
returns text
language 'plpgsql'
as $__$
declare
   cantidad_ text;
begin
    execute format(
        'select count(*)::text from ( select distinct cod_ine / 100 from municipios where cod_ine in ( %s ) ) x',
        valor_ ) into cantidad_;
    return cantidad_;
exception when others then
    return valor_;
end;$__$;
comment on function fmt.contarProvincias( text ) is
        'Cuenta las provincias de una lista de códigos ine separados por coma';

-- + > Dada una lista de códigos ine separados por coma, cuenta las mancomunidades
create or replace function fmt.contarMancomunidades(
    valor_            text )
returns text
language 'plpgsql'
as $__$
declare
   cantidad_ text;
   query_ text;
begin
    query_ = format(
        'select 
           count( distinct x ) 
         from 
           unnest ( ( select 
                         string_to_array ( string_agg( ( regexp_replace( mancomunidad , ''[\[+\]+"+]'','''', ''g'') ), '','' ), '','' ) 
                     from 
                         municipios where cod_ine in ( %s ) ) ) x', valor_ );
    execute query_ into cantidad_;
    return cantidad_;
exception when others then
    return valor_;
end;$__$;
comment on function fmt.contarProvincias( text ) is
        'Cuenta las mancomunidades de una lista de códigos ine separados por coma sin repetir los nombres de la mancomunidad';
        
-- + > Dada una lista de códigos ine separados por coma, cuenta municipios
create or replace function fmt.contarMunicipios(
    valor_            text )
returns text
language 'plpgsql'
as $__$
declare
   cantidad_ text;
begin
    execute format(
        'select count( x )::text from ( select cod_ine from municipios where cod_ine in ( %s ) ) x',
        valor_ ) into cantidad_;
    return cantidad_;
exception when others then
    return valor_;
end;$__$;
comment on function fmt.contarProvincias( text ) is
        'Cuenta los municipios de una lista de códigos ine separados por coma';

-- + > Dado el valor máximo de viviendas rurales , obtiene el nombre del municipio.
create or replace function fmt.maxRurales(
    valor_            text,
    id_               text )
returns text
language 'plpgsql'
as $__$
declare
   nombre_   text;
   valorFmt_ text;
begin
    valorFmt_ = fmt.millares( valor_::integer );
    execute format( $$
        select
            string_agg ( mu.nombre || ' - %2$s viviendas', '\n' )
          from
            vivienda v
              join
            municipios mu
                using ( cod_ine )
          where
            v.rural = %1$s $$, valor_, valorFmt_ ) into nombre_;
    return ( format(
        $$<script>$(document).ready( function() { multiLinea('%s', '%s' ); } )</script>$$,
        nombre_, id_ ) );
exception when others then
    return valor_;
end;$__$;
comment on function fmt.contarProvincias( text ) is
        'Obtiene el nombre del municipio con el mayor número de viviendas rurales.';

-- + > Dado el valor máximo de viviendas urbanas , obtiene el nombre del municipio.
create or replace function fmt.maxUrbanas(
    valor_            text,
    id_               text )
returns text
language 'plpgsql'
as $__$
declare
   nombre_   text;
   valorFmt_ text;
begin
    valorFmt_ = fmt.millares( valor_::integer );
    execute format( $$
        select
            string_agg ( mu.nombre || ' - %2$s viviendas', '\n' )
          from
            vivienda v
              join
            municipios mu
                using ( cod_ine )
          where
            v.urbana = %1$s $$, valor_, valorFmt_ ) into nombre_;
    return ( format(
        $$<script>$(document).ready( function() { multiLinea('%s', '%s' ); } )</script>$$,
        nombre_, id_ ) );
exception when others then
    return valor_;
end;$__$;
comment on function fmt.contarProvincias( text ) is
        'Obtiene el nombre del municipio con el mayor número de viviendas urbanas.';

-- + > Torta de poblacion hombres en area rural, urbana y mujeres en area rural, urbana
create or replace function fmt.tortapoblacionRuralUrbano(
    codIne_            text,     -- + Código INE
    idElement_         text )    -- + Id elemento SVG
returns text
language 'plpgsql'
as $__$
declare
   jsonResult_   text;
begin
    select to_json( t )::text into jsonResult_
        from
            ( select
                  ( hombre_rural + mujer_rural ) as "Poblacion rural",
                  ( hombre_urbana + mujer_urbana ) as "Poblacion urbana"
                from
                  poblacion
                where cod_ine = codIne_::integer
                order by id_upload desc limit 1
            ) t;
    return format(
        $$<script>$(document).ready( function() {pie( %s, '%s' );} )</script>$$,
        jsonResult_, idElement_ );
exception when others then
    return '<!-- Error en tortapoblacionRuralUrbano( ' || codIne_ || ' ) -->';
end;$__$;
comment on function fmt.tortaVivendas( text, text )
is 'Genéra un script para una torta de hombres  y mujeres en el área rural, urbana';

-- + > Genéra un script para mostrar la foto del alcalde de forma dinámica
create or replace function fmt.mapaDepartamento(
    codIne_            text,
    id_               text )
returns text                
language 'plpgsql'
as $__$
declare
begin
    return format(
        $$<script>$(document).ready( function() { mostrarMapaDepartamento( %s, '%s' ); } )</script>$$,
        codIne_ , id_ );
exception when others then
    return codIne_;
end;$__$;
comment on function fmt.mapaDepartamento( text, text ) is
        'Muestra el mapa del departamento.';


-- + > Dado el cod_ine , obtiene el nombre del municipio con el número mayor de viviendas con alcantarillado.
create or replace function fmt.tablaVivienda(
    valor_            text,
    id_               text )
returns text
language 'plpgsql'
as $__$
declare
    jsonVal_   json;
    jsonTxt_   text;
begin
    jsonVal_ = '[' || replace( replace( valor_, '[', '' ), ']', '' ) || ']';
    select
        array_to_json( array_agg( row_to_json( filas ) ) )
      into
        jsonTxt_
      from (
          select 
               t,
               sum(u) u,
               sum(r) r
             from
               json_to_recordset( jsonVal_ ) as x ( t text, u int, r int )
            group by
               1
            ) filas;
    return ( format(
        $$<script>$(document).ready( function() { tabla( %s, '%s' ); } )</script>$$, jsonTxt_, id_ ) );
exception when others then
    return 'Error' || SQLSTATE || SQLERRM;
end;$__$;
comment on function fmt.tablaVivienda( text, text ) is
'Dado el tipo de acceso al agua, tipo desague, tenencia obtiene la sumatoria de viviendas.';

-- + > Genéra un script para dibujar un pie
create or replace function fmt.pieViviendaRural(
    valor_            text,
    id_               text )
returns text
language 'plpgsql'
as $__$
declare
    jsonVal_   json;
    jsonTxt_   text;
begin
    jsonVal_ = '[' || replace( replace( valor_, '[', '' ), ']', '' ) || ']';
    select string_agg( '"' || t || '":' || r, ',' )  into jsonTxt_
    from( select 
               t ,
               sum(r) r
             from
               json_to_recordset( jsonVal_ ) as x ( t text, r int )
             group by 1
         ) t;
    return ( format(
        $$<script>$(document).ready( function() { pie( {%s}, '%s' ); } )</script>$$, jsonTxt_, id_ ) );
exception when others then
    return 'Error' || SQLSTATE || SQLERRM;
end;$__$;
comment on function fmt.pieViviendaRural( text, text ) is
'Dado el tipo de acceso al agua, tipo desague, tenencia obtiene la sumatoria de viviendas en área rural.';


-- + > Genéra un script para dibujar un pie
create or replace function fmt.pieViviendaUrbana(
    valor_            text,
    id_               text )
returns text
language 'plpgsql'
as $__$
declare
    jsonVal_   json;
    jsonTxt_   text;
begin
    jsonVal_ = '[' || replace( replace( valor_, '[', '' ), ']', '' ) || ']';
    select string_agg( '"' || t || '":' || u, ',' )  into jsonTxt_
    from( select 
               t ,
               sum(u) u
             from
               json_to_recordset( jsonVal_ ) as x ( t text, u int )
             group by 1
         ) t;
    return ( format(
        $$<script>$(document).ready( function() { pie( {%s}, '%s' ); } )</script>$$, jsonTxt_, id_ ) );
exception when others then
    return 'Error' || SQLSTATE || SQLERRM;
end;$__$;
comment on function fmt.pieViviendaRural( text, text ) is
'Dado el tipo de acceso al agua, tipo desague, tenencia obtiene la sumatoria de viviendas en área urbana.';

-- + > Torta de viviendas
create or replace function fmt.totalViviendas(
    valor_            text )     -- + Código INE
returns text
language 'plpgsql'
as $__$
declare
    totalviviendas_ integer;
begin
    execute format( $$ select
         sum( rural + urbana )
       from
         vivienda
       where cod_ine in ( %s )$$, valor_ ) into totalviviendas_;
    return fmt.formatoMillares( totalviviendas_::text ) ;
exception when others then
    return '<!-- Error en tortaViviendas( ' || codIne_ || ' ) -->';
end;$__$;
comment on function fmt.totalViviendas( text ) is 'Devuelve el total de viviendas';


-- + > Pirámide de población
create or replace function fmt.piramideTotal(
    valor_            text,     -- + Código INE
    idElement_         text )    -- + Id elemento SVG
returns text
language 'plpgsql'
as $__$
declare
   jsonResult_   text;
   columns_      text;
begin
    columns_ = '';
    for i in reverse 20..1 loop
          columns_ = columns_ || format(
            $$'{"t":"%1$s-%2$s","m":' || sum( m_%1$s )  || ',"h":' || sum( h_%1$s ) || '},' || $$,
            ( i - 1 ) * 5, i * 5 - 1 );
    end loop;
    columns_ = left( columns_, length( columns_ ) - 6 ) || '''';
    execute
        format( $$select %s from poblacion where cod_ine in ( %s ) 
$$, columns_, valor_ ) into jsonResult_;
    return format(
        $$<script>$(document).ready( function() {piramide([%s],'%s');} )</script>$$,
        jsonResult_, idElement_ );
exception when others then
    return '<!-- Error en barras( ' || codIne_ || ' ) -->';
end;$__$;
comment on function fmt.piramideTotal( text, text )
is 'Genera una la intrucción en javascript para crear la pirámide de población';

-- + > Obtiene el total de habitantes según el agregado y adiciona la unidad de personas
create or replace function fmt.habitantesAgregado(
    valores_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalHabitantes_    integer;
begin
    execute format( $$ select
                            sum( mujer_rural + mujer_urbana + hombre_rural + hombre_urbana )
                          from
                            poblacion
                          where cod_ine in ( %s ) $$, valores_ ) into totalHabitantes_;
    return fmt.millares( totalHabitantes_, ',' ) || ' personas' ;
exception when others then
    return totalHabitantes_ || ' habitantes';
end;$__$;
comment on function fmt.habitantesAgregado( text )
is 'Obtiene el total de habitantes según el agregado.';

-- + > Obtiene el total de habitantes según el agregado y adiciona la unidad de personas
create or replace function fmt.adultosAgregado(
    valores_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalAdultos_    integer;
begin
    execute format( $$ select
                            sum( h_60 + h_65 + h_70 + h_75
                                    + h_80 + h_85 + h_90 + h_95 + h_100 + m_60 + m_65 + m_70 + m_75
                                    + m_80 + m_85 + m_90 + m_95 + m_100 ) 
                          from
                            poblacion
                          where cod_ine in ( %s ) $$, valores_ ) into totalAdultos_;
    return fmt.millares( totalAdultos_, ',' );
exception when others then
    return totalAdultos_ || ' adultos';
end;$__$;
comment on function fmt.adultosAgregado( text )
is 'Obtiene el total de adultos según el agregado.';

-- + > Torta de población agregado
create or replace function fmt.tortaPoblacionAgregado(
    valores_            text,     -- + Código INE
    idElement_         text )    -- + Id elemento SVG
returns text
language 'plpgsql'
as $__$
declare
   jsonResult_   text;
begin
    execute format( $$ select to_json( t )
        from
            ( select
                 sum( hombre_rural + hombre_urbana ) as "Hombres",
                 sum( mujer_rural + mujer_urbana ) as "Mujeres"
               from
                 poblacion
               where cod_ine in ( %s )
            ) t $$, valores_ ) into jsonResult_;
    return format(
        $$<script>$(document).ready( function() {pie( %s, '%s' );} )</script>$$,
        jsonResult_, idElement_ );
exception when others then
    return '<!-- Error en tortaPoblacion( ' || valores_ || ' ) -->';
end;$__$;
comment on function fmt.tortaPoblacionAgregado( text, text) is 'Genéra un script para una torta de población agregada';

-- + > Cantidad adultos mayores en un municipio determinado
create or replace function fmt.totalAdultosMayores(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalAdultos_    text;
begin
    select
        ( h_60 + h_65 + h_70 + h_75 + h_80 + h_85 + h_90 + h_95 + h_100 +
        m_60 + m_65 + m_70 + m_75 + m_80 + m_85 + m_90 + m_95 + m_100 )::text into totalAdultos_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalAdultos_::integer, ',' );
exception when others then
    return fmt.millares( totalAdultos_::integer, ',' );
end;$__$;
comment on function fmt.totalAdultosMayores( text )
is 'Obtiene el total de adultos mayores en el municipio';

-- + > Cantidad niñas y niños entre las edades de 5 a 10 años en un municipio determinado
create or replace function fmt.totalninios5a10(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalNinios_    text;
begin
    select
        (  h_5 + m_5 )::text into totalNinios_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalNinios_::integer, ',' );
exception when others then
    return fmt.millares( totalNinios_::integer, ',' );
end;$__$;
comment on function fmt.totalAdultosMayores( text )
is 'Obtiene el total de niñas y niños entre las edades de 5 a 10 años en un municipio determinado';

-- + > Cantidad total de recien nacidos en un municipio determinado
create or replace function fmt.totalRecienNacidos(
    codIne_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalNacidos_    text;
begin
    select
        (  h_0 + m_0 )::text into totalNacidos_
      from
        poblacion
      where cod_ine = codIne_::integer
      order by id_upload desc limit 1;
    return fmt.millares( totalNacidos_::integer, ',' );
exception when others then
    return fmt.millares( totalNacidos_::integer, ',' );
end;$__$;
comment on function fmt.totalAdultosMayores( text )
is 'Obtiene el total de recien nacidos en un municipio determinado';

-- + > Obtiene el total de recién nacidos según el agregado y adiciona la unidad de personas
create or replace function fmt.totalRecienNacidosAgregado(
    valores_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalNacidos_    integer;
begin
    execute format( $$ select
                            sum( h_0 + m_0 )
                          from
                            poblacion
                          where cod_ine in ( %s ) $$, valores_ ) into totalNacidos_;
    return fmt.millares( totalNacidos_, ',' );
exception when others then
    return totalNacidos_ || ' adultos';
end;$__$;
comment on function fmt.totalRecienNacidosAgregado( text )
is 'Obtiene el total de recién nacidos según el agregado.';

-- + > Obtiene el total de recién nacidos según el agregado y adiciona la unidad de personas
create or replace function fmt.totalNinios(
    valores_            text )     -- + codigo INE
returns text
language 'plpgsql'
as $__$
declare
    totalNinios_    integer;
begin
    execute format( $$ select
                            sum( h_5 + m_5 )
                          from
                            poblacion
                          where cod_ine in ( %s ) $$, valores_ ) into totalNinios_;
    return fmt.millares( totalNinios_, ',' );
exception when others then
    return totalNinios_ || ' niños y niñas';
end;$__$;
comment on function fmt.totalNinios( text )
is 'Obtiene el total de niños y niñas en base al agregado.';
