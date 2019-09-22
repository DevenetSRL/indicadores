\i im.functions.sql
\set token `echo "select sg.connectUser( 1 )"|psql -t indicadores|xargs`

select im.crearSqlTablaAcervos( :'token', 'municipios' );

select im.crearSqlTablaAcervos( :'token', 'direccion' );


--PRIMARY KEY(question_id, tag_id)
