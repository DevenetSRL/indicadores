\i sg.functions.sql
\set token `echo "select sg.connectUser( 1 )"|psql -t indicadores|xargs`

-- -- Caso de prueba de sg.createUser
-- \echo 1 Verificar que no se puede crear el mismo usuario dos veces

--select id_user, email, login  from sg.users;
--select sg.createUser( :'token','ariel', 'ariel@devenet.net', 'UnaPruebaDe123', 'AM', 'Ariel SCC','nada','dev' );
--select id_user, email, login  from sg.users;

-- \echo 2 Verificar si el email es correcto
-- delete from sg.users where id_user > 1;
-- select sg.createUser( :'token', 'ariel.devenet.net', 'UnaPruebaDe123', 'UnaPruebaDe123' );
-- select sg.createUser( :'token', 'arieldevenet.net', 'UnaPruebaDe123', 'UnaPruebaDe123' );
-- select id_user, email  from sg.users;

-- \echo 3 Verificar si el password es correcto
-- delete from sg.users where id_user > 1;
-- select sg.createUser( :'token', 'ariel@devenet.net', 'UnaPruebaDe64565', 'UnaPruebaDe123' );
-- select id_user, email  from sg.users;

-- \echo 4 Verificar si el password tiene caracteres con mayuscula y numeros
-- delete from sg.users where id_user > 1;
-- select sg.createUser( :'token', 'ariel@devenet.net', 'unaprueba', 'unaprueba' );
-- select id_user, email  from sg.users;

--caso de prueba de sg.updateEmailUser
-- \echo 5 Verifica si el email se actualiza
-- delete from sg.users where id_user > 1;
-- select sg.createUser( :'token', 'ariel@devenet.net', 'UnaPruebaDe123', 'UnaPruebaDe123' );
-- select id_user, email  from sg.users;
-- select sg.updateEmailUser( :'token', 19, 'arielo@devenet.net' );
-- select id_user, email  from sg.users;

--caso de prueba de sg.changePassword
-- \echo 6 Verifica si el password se cambia
-- delete from sg.users where id_user > 1;
-- select sg.createUser( :'token', 'ariel@devenet.net', 'UnaPruebaDe123', 'UnaPruebaDe123' );
-- select id_user, email  from sg.users;
-- select sg.changePassword( :'token', id_user, 'UnaPruebaDe123', 'UnaPruebaDe123456' );
-- select id_user, email  from sg.users;

--caso de prueba de sg.userAddRole
-- \echo 7 Verifica si se adiciona un solo Rol
-- select id_user, email, roles  from sg.users;
-- select sg.userAddRole( :'token', 28, 'W' );
-- select id_user, email, roles  from sg.users;

-- \echo 8 Verifica si se adiciona mas de un Rol
-- select id_user, email, roles  from sg.users;
-- select sg.userAddRole( :'token', 28, 'AMOR' );
-- select id_user, email, roles  from sg.users;

--caso de prueba de sg.userDelRole
-- \echo 9 Verifica si se le quita un rol al usuario
-- select id_user, email, roles  from sg.users;
-- select sg.userDelRole( :'token', 28, 'OR' );
-- select id_user, email, roles  from sg.users;

-- \echo 10 Verifica si se le quita mas de un rol al usuario
-- select id_user, email, roles  from sg.users;
-- select sg.userDelRole( :'token', 28, 'OR' );
-- select id_user, email, roles  from sg.users;

--caso de prueba de sg.recuUser
-- \echo 11 Recupera a un usuario que fue borrado
-- select id_user, email,  enabled from sg.users;
-- select sg.recuUser( :'token', 28);
-- select id_user, email,  enabled from sg.users;

--caso de prueba de sg.listUser
-- \echo 12 Verifica el listado del json
-- select sg.listUser(true);

--RESOURCES

--caso de prueba de sg.createResource
-- \echo 13 Verifica la creacion de un rol
-- delete from sg.resources where id_resource > 1;
-- select sg.createResource( :'token', 1234, 'Prueba de creacion' );
-- select id_resource, code, description  from sg.resources;

-- caso de prueba de sg.updateDataResource
-- \echo 14 Actualiza los datos de resource
-- select sg.updateDataResource(:'token', 1, 4321, 'otra descripcion');
-- select id_resource, code, description  from sg.resources;

-- caso de prueba de sg.resourceAddRole
-- \echo 15 adiciona nuevos roles a al recurso
-- select id_resource, code, description, roles  from sg.resources;
-- select sg.resourceAddRole(:'token', 1,'A');
-- select id_resource, code, description, roles  from sg.resources;

-- caso de prueba de sg.resourceDelRole
-- \echo 16 Verifica que se eliminen roles a un recurso
-- select id_resource, code, description, roles  from sg.resources;
-- select sg.resourceDelRole(:'token', 1,'ORAMAMA');
-- select id_resource, code, description, roles  from sg.resources;

-- caso de prueba sg.deleteResource
-- \echo 17 Virifica si se borra un recurso
-- select id_resource, code, description, roles, enabled  from sg.resources;
-- select sg.deleteResource(:'token', 1);
-- select id_resource, code, description, roles, enabled  from sg.resources;

-- caso de prueba sg.recuResource
-- \echo 18 Virifica si se recupera un recurso
-- select id_resource, code, description, roles, enabled  from sg.resources;
-- select sg.recuResource(:'token', 1);
-- select id_resource, code, description, roles, enabled  from sg.resources;

--caso de prueba de sg.listUser
-- \echo 19 Verifica el listado del json
-- select sg.listResource(true);

--ROLES

--caso de prueba de sg.createRol
-- \echo 20 Verifica la creacion de un rol
-- delete from sg.roles where id_role > 1;
-- select sg.createRole( :'token', 'S', 'A', 'prueba de creacion de rol' );
-- select id_role, code, "role",  description  from sg.roles;

-- caso de prueba de sg.updateDataRol
-- \echo 21 Actualiza los datos de rol
-- select id_role, code, "role", description  from sg.roles;
-- select sg.updateDataRol(:'token', 12, 'T', 'otra descripcion 6');
-- select id_role, code, "role", description  from sg.roles;

---todo hasta aqui estoy

--TODO: los verificar la salida de los roles

-- caso de prueba de sg.rolAddRol
-- \echo 22 adiciona nuevos roles a al recurso
-- select id_role, code, description  from sg.roles;
-- select sg.rolesAddRol(:'token', 1,'A');
-- select id_resource, code, description, roles  from sg.resources;

-- caso de prueba de sg.rolDelRole
-- \echo 23 Verifica que se eliminen roles a un recurso
-- select id_resource, code, description, roles  from sg.resources;
-- select sg.resourceDelRole(:'token', 1,'ORAMAMA');
-- select id_resource, code, description, roles  from sg.resources;

-- caso de prueba sg.deleteRol
-- \echo 24 Verifica si se borra un rol
-- select sg.createRole( :'token', 'S', 'A', 'prueba de creacion de rol' );
-- select id_role, code, "role",  description, enabled  from sg.roles;
-- select sg.deleteRol(:'token', 7);
-- select id_role, code, "role",  description, enabled  from sg.roles;

-- caso de prueba sg.recuRol
-- \echo 25 Verifica si se recupera un rol
-- select id_role, code, "role",  description, enabled  from sg.roles;
-- select sg.recuRol(:'token', 7);
-- select id_role, code, "role",  description, enabled  from sg.roles;

--caso de prueba de sg.listRol
-- \echo 26 Verifica el listado del json
-- select sg.listRol(true);

-- sg.newRole()
select sg.newRole( :'token', 'D', 'Digitalizador', 'prueba de creacion de rol' );
select id_role, code, "role",  description  from sg.roles;
