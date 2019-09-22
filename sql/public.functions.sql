-- @file public.functions.sql
--
-- @brief Funciones del esquema público. Son funciones auxiliares. No
-- deben existir en producción.
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

-- + > simpleMunicipiosList: [R|municipios] Lista simple de municipios
create or replace function simpleMunicipiosList()
returns text                    -- + Json del informe
language 'plpgsql'
as $__$
declare
begin
    if not im.comprobarExistenciaTablaAcervos( 'municipios' ) then
        raise exception 'Municipios not found';
    end if;
    return
      ( select
            array_to_json( array_agg( row_to_json( mergedMunicipios ) ) )
          from
            ( select
                  row_to_json( selectMunicipios )
                from
                  ( select
                        cod_ine,
                        nombre,
                        otros_nombres,
                        seccion,
                        departamento,
                        provincia,
                        amdes
                      from
                        municipios acq
                      order by
                        cod_ine
                  ) selectMunicipios
            ) mergedMunicipios
      );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > listMunicipios: [R|municipios] Lista de municipios
create or replace function listMunicipios()
returns text                        -- + Json del informe
language 'plpgsql'
as $__$
begin
    return json_build_object(
       'status', 'ok',
       'data', ( select
                     json_agg( t )
                   from
                     (
                       select 
                          cod_ine as "_cod_ine",
                          departamento as "Departamento",
                          provincia as "Provincia",
                          cod_ine as "Código INE",
                          nombre as "Nombre",
                          coalesce( otros_nombres, '' ) as "Otros Nombres"
                        from
                          municipios mun
                        order by
                          cod_ine
                    ) t
               )
    );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > listInfoCards: [R|im.fichas] Lista de Fichas Municipales
create or replace function listInfoCards()
returns text
language 'plpgsql'
as $__$
declare
    idinfoCard_     integer;
begin

    return json_build_object(
       'status', 'ok',
       'data', ( select
                     json_agg( t )
                   from
                     (
                       select 
                           titulo,
                           id_ficha
                         from
                           im.fichas
                         where
                           enabled
                         order by
                           1
                      ) t
                 )
     );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;
