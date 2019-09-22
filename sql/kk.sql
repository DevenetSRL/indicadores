-- \i im.functions.sql
-- \set token `echo "select sg.connectUser( 1 )"|psql -t indicadores|xargs`
-- \set csv_path `pwd`
-- \echo :csv_path

-- select im.makeSqlAcquisTable( :'token', 'municipios' );

-- select im.makeSqlAcquisTable( :'token', 'direccion' );

-- select im.makeSqlAcquisTable( :'token', 'direccion', 'muejaja' );

-- select im.makeAcquisTable( :'token', 'direccion' );

-- select im.MakeSqlAcquisTable( :'token', 'municipios', 'pruebacsv' );

-- \set csv_path `pwd`
-- select im.uploadAcquis(
--     :'token',
--     'municipios',
--     'Carga inicial de datos',
--     :'csv_path' || '/municipios.csv' );


--copy ( select * from im.getEmptyAcquis( sg.connectUser( 1 ), 'municipios' ) ) to '/tmp/kk,csv' csv delimiter '|' quote '"' FORCE_QUOTE *;
-- select im.uploadAcquis(
--      :'token',
--      'municipios',
--      'primera carga de datos',
--      :'csv_path' || '/municipios.csv' );

-- select im.getEmptyCSV( :'token', 'municipios' );

-- select im.testCsvAcquis(
--      :'token',
--      'municipios',
--      '/tmp/municipios.csv' );

-- + > im.getCodIneData: [R|puplic.*] Une la información de todos los acervos
 -- + Los acervos a considerar, deben estar activos
create or replace function im.mergeTemplateWithData(
    codIne_     integer,        -- + Cod INE
    template_   text )          -- + Template
returns text                    -- + Merged template
language 'plpgsql'
as $__$
declare
   oldTemplate_ text;
   values_      text[];
   columns_     text[];
   field_       text;
   relations_   text[];
   table_       text;
   row_         record;
   count_       integer;
   validCols_   text;
   keys_        text[];
   vals_        text[];
   upload_      text;
begin
    oldTemplate_ = template_;
    template_ = replace( template_, E'\n', '' );
    template_ = replace( template_, E'\r', '' );
    template_ = regexp_replace( template_, '^[^{]*{{ ', '{{ ' );
    values_ = string_to_array( template_, '{{ ' );
    for i in array_lower( values_, 1 ) + 1..array_upper( values_, 1 ) loop
        field_ = trim( regexp_replace( values_[i], ' }}.*$', '' ) );
        if length( field_ ) > 5
            and coalesce( field_ != all( columns_ ), true ) then
            columns_ = array_append( columns_, field_ );
            table_ = regexp_replace( field_, '\..*', '' );
            if coalesce( table_ != all( relations_ ), true ) then
                relations_ = array_append( relations_, table_ );
            end if;
        end if;
    end loop;
    for row_ in
        select
            id_acquis,
            identifier
          from
            im.acquis
          where
            enabled
            and identifier = any( relations_ )
    loop
        if not im.checkIfExistsAcquisTable( row_.identifier ) then
            continue;
        end if;
        execute
            format( 'select count(*) from %I', row_.identifier )
          into
            count_;
        if count_ = 0 then
            continue;
        end if;
        select
            string_agg( column_name, ',' )
          into
            validCols_
          from
            ( select
                  column_name
                from
                  im.columns
                where
                  id_acquis = row_.id_acquis
                  and ( row_.identifier || '.' || column_name ) = any( columns_ )
            ) colvalids;
        upload_ = ' order by id_upload desc limit 1';
        if row_.identifier = 'municipios' then
             upload_ = '';
        end if;
        execute
            format(
               $$ select
                      array[ %1$s ], string_to_array( '%1$s', ',' )
                    from
                      %2$I
                    where
                      cod_ine = %3$L
                    %4$s
               $$,
               validCols_, row_.identifier, codIne_, upload_ )
          into
            vals_, keys_;        
        for i in array_lower( keys_, 1 ) .. array_upper( keys_, 1 ) loop
            oldTemplate_ = replace(
               oldTemplate_,
               '{{ ' || row_.identifier || '.' || keys_[i] || ' }}',
               coalesce( vals_[i], '' ) );
        end loop;
    end loop;
    return oldTemplate_ || 'nada de nada';
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

select im.mergeTemplateWithData( 20201,
'<h1> {hola Revisar todos acervos activos}
{{ municipios.otros_nombres }} {{ municipios.departamento }} {{ municipios.provincia }}
<span>
{{ municipios.departamento }}

{{ municipios.nombre }}  {{ alcaldes.nombre }}

{{ municipios.javier }}

\title{{{ direccion.web }}}

<b>Sección:</b> {{ municipios.seccion }} <b>Circunscripción:</b> {{ municipios.circunscripcion }}




{{ municipios.departamento }} {{ municipios.provincia }}

{{ alcaldes.nombre }}' );
