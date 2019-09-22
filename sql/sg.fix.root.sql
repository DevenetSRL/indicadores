insert into sg.usuarios ( usuario, correo, clave, id_creator, id_modificator )
    values ( 'root', 'info@devenet.net', crypt( 'admin', gen_salt( 'bf' ) ), 1, 1 );

alter table sg.usuarios add constraint creator foreign key (id_creator)
     references sg.usuarios (id_usuario) on delete restrict on update cascade;
alter table sg.usuarios add constraint modificator foreign key (id_modificator)
     references sg.usuarios (id_usuario) on delete restrict on update cascade;

\set token `echo "select sg.conectarUsuario( 1 )"|psql -t indicadores|xargs`
------------------------------------------------------------------------------
