-- @file sg.functions.sql
--
-- @brief Funciones del esquema sg.
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

-- + > sg.desconectaUsuario: Desconecta un usuario conectado
create or replace function sg.desconectaUsuario(
    token_     text )       -- + Usuario id
returns text
language 'plpgsql'
as $__$
declare
    response_ boolean;
begin
    if not exists ( select 1 from sg.token where acceso_token::text = token_ ) then
        raise exception 'Conexion de usuario no encontrada';
    end if;
    delete from sg.token where acceso_token::text = token_;
    return json_build_object(
        'message', 'Usuario desconectado',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + > sg.comprobarToken: Verifica si el token está activo
create or replace function sg.comprobarToken(
    token_     text )       -- + Usuario id
returns text
language 'plpgsql'
as $__$
begin
    return json_build_object(
        'valid', exists ( select 1 from sg.token where acceso_token::text = token_ ),
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + > sg.conectarUsuario: Conecta un usuario dado su id
 -- + Crea un token de acceso para un usuario. Si ya existe
 -- + conexión, ésta es eliminada
create or replace function sg.conectarUsuario(
    idUser_     integer )       -- + User id
returns text
language 'plpgsql'
as $__$
declare
    token_      text;
begin
    if not exists ( select 1 from sg.usuarios where id_usuario = idUser_ ) then
        raise exception 'Usuario no encontrado';
    end if;
    delete from sg.token where id_usuario = idUser_;
    insert into sg.token ( id_usuario )
      values ( idUser_ )
      returning acceso_token
      into token_;
    return token_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > sg.comprobarAcceso: [CUD|sc.tokens] Establece si el token tiene acceso al recurso
 -- + Verifica que el usuario (según sus roles) puede o no acceder
create or replace function sg.comprobarAcceso(
    token_       text,          -- + Token de conexión de usuario
    code_        integer )      -- + Código numérico de recurso
returns integer                 -- + Id del usuario
language 'plpgsql'
as $__$
declare
    iduser_        integer;
    resourceRoles_ text;
    userRoles_     text;
begin
    select id_usuario into idUser_ from sg.token where acceso_token::text = token_;
    if idUser_ is null then
        raise exception 'User is not connected';
    end if;
    -- TODO: Borrar a root en producción
    if idUser_ = 1 then
        return 1;
    end if;
    select roles into userRoles_ from sg.usuarios where id_usuario = idUser_;
    select roles into resourceRoles_ from sg.recursos where codigo = code_;
    if userRoles_ ~ '[' || resourceRoles_ || ']' then
        return idUser_;
    end if;
    raise exception 'Credenciales insuficientes para acceder al recurso';
    return 0;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return 0;
end;$__$;

--ROLES
-- + > sg.createRole: [C|sc.roles] Insertar rol en el sistema
 -- + Nota: Los roles se manejan por letras
-- + crearRol
create or replace function sg.crearRol(
    token_       text,          -- + User connection token
    code_        char,          -- + Código de una letra
    role_        text,          -- + Nombre simbólico del rol
    description_ text )         -- + Descripción del rol
returns void
language 'plpgsql'
as $__$
declare
    iduser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 1000 );
    code_ = trim( code_ );
    role_ = trim( role_ );
    if code_ = '' then
        raise exception 'Role code can not be empty';
    end if;
    if role_ = '' then
        raise exception 'Role name can not be empty';
    end if;
    insert into sg.roles ( codigo, rol, descripcion, id_creator, id_modificator )
        values ( code_, role_, description_, idUser_, idUser_ );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

---RESOURCES
-- + > sg.createResource: [C|sc.resources] Insertar recurso en el sistema
 -- + Nota: los recursos se manejan por su código numérico
 -- + crearRecurso
create or replace function sg.crearRecurso(
    token_       text,          -- + User connection token
    code_        integer,       -- + Código numérico
    description_ text )         -- + Descripción del resource
returns void
language 'plpgsql'
as $__$
declare
    iduser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 1000 );
    if code_ <= 0 then
        raise exception 'Resource code must be positive';
    end if;
    insert into sg.recursos ( codigo, descripcion, id_creator, id_modificator )
        values ( code_, description_, idUser_, idUser_ );
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + asignarRolesRecurso | asignarRolesRecurso
-- + > sg.asignarRolesRecurso: [U|sc.resources] Asignar roles a un recurso
 -- + Actualiza los roles del recurso
create or replace function sg.asignarRolesRecurso(
    token_        text,          -- + User connection token
    codeResource_ integer,       -- + Código numérico de recurso
    codeRole_     text )         -- + Uno o más códigos de rol
returns void
language 'plpgsql'
as $__$
declare
    iduser_     integer;
    codes_      char[];
begin
    idUser_ = sg.comprobarAcceso( token_, 1000 );
    if not exists ( select 1 from sg.recursos where codigo = codeResource_ ) then
        raise exception 'Resource code not found';
    end if;
    codeRole_ = upper( trim( codeRole_ ) );
    if codeRole_ = '' then
        raise warning 'Can not remove all roles from resource';
    end if;
    select array_to_string(
        array(
            select distinct
                s
              from
                unnest( string_to_array( codeRole_, null ) ) s
                  join
                sg.roles r on ( r.codigo = s )
              order by 1 ), '') as r
        into codeRole_;
    if codeRole_ = '' then
        raise warning 'Invalid roles has been used';
    end if;
    update sg.recursos set roles = codeRole_ where codigo = codeResource_;
    return;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > sg.conectarUsuario: Conectar usuario dado su email
 -- + Crea un token de acceso para un usuario. Si ya existe
 -- + conexión, ésta es eliminada
create or replace function sg.autenticar(
    usuario_      text,            -- + User usuario
    password_     text )           -- + User password
returns text
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    if coalesce( usuario_, '' ) = '' then
        raise exception 'Usuario esta vacio';
    end if;
    select
        id_usuario
      into
        idUser_
      from
        sg.usuarios
      where
        usuario = usuario_
        and clave = crypt( password_, clave );
    if idUser_ is null then
        raise exception 'Usuario o clave incorrecto';
    end if;
    return json_build_object(
        'token', sg.conectarUsuario( idUser_ ),
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--------------------------------------------------------------

-- aceptarSuscripcion
-- + > sg.aceptarSuscripcion: [U|sg.suscribers] Aceptar una suscripción
create or replace function sg.aceptarSuscripcion(
    token_       text )            -- + Token de usuario
returns integer                    -- + 
language 'plpgsql'
as $__$
declare
    idUser_ integer;
begin
    if not exists( select 1 from sg.suscriptores where token = token_::uuid ) then
       raise exception 'Suscription requirement not found';
    end if;
    insert into sg.usuarios (
        usuario,
        correo,
        clave,
        "nombre",
        institucion,
        "posicion",
        id_creator,
        id_modificator )
    select
        usuario,
        correo,
        crypt( clave, gen_salt( 'bf' ) ),
        "nombre",
        institucion,
        "posicion",
        1,
        1
      from
        sg.suscriptores
      where
        token = token_::uuid
    returning
        id_usuario
    into
        idUser_;
    update
        sg.usuarios
      set
        id_creator = idUser_,
        id_modificator = idUser_
      where
        id_usuario = idUser_;
    delete from  sg.suscriptores where token = token_::uuid;
    return idUser_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return 0;
end;$__$;


-- + > sg.suscribe: [C|sg.suscribers] Crear una suscripción
create or replace function sg.suscribe(
    usuario_     text,             -- + User usuario
    email_       text,             -- + User email
    password1_   text,             -- + User password
    password2_   text,             -- + User password confirm
    gender_      char,             -- + Gender (must be F or M)
    name_        text default '',  -- + Real user name
    institution_ text default '',  -- + Institution
    position_    text default '',  -- + Position
    comment_     text default '' ) -- + Comment
returns text                       -- + 
language 'plpgsql'
as $__$
declare
    minLength_  integer;
    idUser_     integer;
begin
    -- Check if usuario is valid and not already created
    usuario_ = trim( coalesce( usuario_, '' ) );
    if usuario_ = '' then
        raise exception 'User usuario can not be empty';
    end if;
    if exists( select 1 from sg.usuarios where usuario = usuario_ )
       or exists( select 1 from sg.suscriptores where usuario = usuario_ ) then
        raise exception 'User usuario % already picked', usuario_;
    end if;
    -- Check if mail is valid and not already created
    email_ = trim( coalesce( email_, '' ) );
    if email_ = '' then
        raise exception 'User mail can not be empty';
    end if;
    if exists( select 1 from sg.usuarios where correo = email_ )
       or exists( select 1 from sg.suscriptores where correo = email_ ) then
        raise exception 'User mail % already used', email_;
    end if;
    if not glb.emailValid( email_ ) then
        raise exception 'Invalid user mail %', email_;
    end if;
    -- Check if password is enought strong
    password1_ = trim( password1_ );
    password2_ = trim( password2_ );
    if glb.sysOptB( 'pass_contain_uppercase' ) and  password1_ ~ '^[^A-Z]+$' then
        raise exception 'Password must contain uppercase letters';
    end if;
    if glb.sysOptB( 'pass_contain_lowercase' ) and  password1_ ~ '^[^a-z]+$' then
        raise exception 'Password must contain lowercase letters';
    end if;
    if glb.sysOptB( 'pass_contain_digits' ) and  password1_ ~ '^[^0-9]+$' then
        raise exception 'Password must contain digits';
    end if;
    minLength_ = glb.sysOptI( 'pass_min_length' );
    if length( password1_ ) < minLength_ then
        raise exception 'Password must contain almost % digits', minLength_;
    end if;
    if password1_ <> password2_ then
        raise exception 'Password and confirmation does not match';
    end if;
    if gender_ not in ( 'F', 'M' ) then
        raise exception 'Gender must be "F" or "M"';
    end if;    
    insert into sg.suscriptores (
        usuario,
        correo,
        clave,
        "nombre",
        institucion,
        "posicion",
        comentario,
        genero )
      values (
        usuario_,
        email_,
        password1_,
        name_,
        institution_,
        position_,
        comment_,
        gender_ );
    return json_build_object(
        'status', 'ok',
        'message', 'Se envió un correo para confirmar su suscripción.'
    );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > sg.crearUsuario: [C|sc.users] Crear un usuario en el sistema
 -- + Crea un usuario en el sistema
create or replace function sg.crearUsuario(
    token_       text,             -- + User connection token
    usuario_     text,             -- + User usuario
    email_       text,             -- + User email
    password_    text,             -- + User password
    roles_       text,             -- + User rol
    name_        text default '',  -- + Real user name
    institution_ text default '',  -- + Institution
    position_    text default '' ) -- + Position
returns text                       -- + 
language 'plpgsql'
as $__$
declare
    minLength_     integer;
    idUser_        integer;
    idUserCreated_ integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    -- Check if mail is valid and not already created
    email_ = trim( coalesce( email_, '' ) );
    if email_ = '' then
        raise exception 'Correo del usuario vacío';
    end if;
    if exists( select 1 from sg.usuarios where correo = email_ ) then
        raise exception 'El correo del usuario % ya existe', email_;
    end if;
    if not glb.emailValid( email_ ) then
        raise exception 'Correo de usuario inválido %', email_;
    end if;
    -- Check if password is enought strong
    password_ = trim( password_ );
    if glb.sysOptB( 'pass_contain_uppercase' ) and  password_ ~ '^[^A-Z]+$' then
        raise exception 'Password must contain uppercase letters';
    end if;
    if glb.sysOptB( 'pass_contain_lowercase' ) and  password_ ~ '^[^a-z]+$' then
        raise exception 'Password must contain lowercase letters';
    end if;
    if glb.sysOptB( 'pass_contain_digits' ) and  password_ ~ '^[^0-9]+$' then
        raise exception 'Password must contain digits';
    end if;
    minLength_ = glb.sysOptI( 'pass_min_length' );
    if length( password_ ) < minLength_ then
        raise exception 'Password must contain almost % digits', minLength_;
    end if;
    insert into sg.usuarios (
        usuario,
        correo,
        clave,
        roles,
        "nombre",
        institucion,
        "posicion",
        id_creator,
        id_modificator )
      values (
        usuario_,
        email_,
        crypt( password_, gen_salt( 'bf' ) ),
        roles_,
        name_,
        institution_,
        position_,
        idUser_,
        idUser_ )       
      returning
        id_usuario
      into
        idUserCreated_;
    return json_build_object(
        'message', 'User created succefully',
        'idUser', idUserCreated_,
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + actualizarDatosUsuario
-- + > sg.actualizarDatosUsuario: [U|sc.users] Actualizar datos de usuario
create or replace function sg.actualizarDatosUsuario(
    token_       text,             -- + User connection token
    idSelUser_   integer,          -- + User id
    name_        text,             -- + Real user name
    institution_ text,             -- + Institution
    position_    text )            -- + Position
returns void                       -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 1000 );
    if not exists (select 1 from sg.usuarios where id_usuario = idSelUser_) then
       raise exception 'User not found';
    end if;
    update sg.usuarios
      set
        "nombre" = name_,
        institucion = institution_,
        "posicion" = position_
      where
        id_usuario = idSelUser_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + > sg.actualizarCorreoUsuario: [U|sc.users] Actualizar el email de usuario
create or replace function sg.actualizarCorreoUsuario(
    token_       text,             -- + User connection token
    idSelUser_   integer,          -- + User id
    email_       text )            -- + Email
returns void                       -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 1000 );
    if not exists (select 1 from sg.usuarios where id_usuario = idSelUser_) then
       raise exception 'User not found';
    end if;
    -- Check if mail is valid and not already created
    email_ = trim( coalesce( email_, '' ) );
    if email_ = '' then
        raise exception 'Empty user mail';
    end if;
    if exists( select 1 from sg.usuarios where correo = email_ ) then
        raise exception 'User mail % already exists', email_;
    end if;
    if not glb.emailValid( email_ ) then
        raise exception 'Invalid user mail %', email_;
    end if;
    update sg.usuarios
      set
        correo = email_
      where
        id_usuario = idSelUser_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + cambiarClave
-- + > sg.cambiarClave: [U|sc.users] Cambiar la contrasena de usuario
create or replace function sg.cambiarClave(
    token_        text,             -- + User connection token
    idSelUser_    integer,          -- + User id
    oldPassword_  text,             -- + Old Password
    newPassword1_ text,             -- + New Password
    newPassword2_ text )            -- + Repeat New Passwod
returns void                        -- + 
language 'plpgsql'
as $__$
declare
    minLength_  integer;
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 1000 );
    if not exists (select 1 from sg.usuarios where id_usuario = idSelUser_) then
       raise exception 'User not found';
    end if;
    -- Check if password is enought strong
    newPassword1_ = trim( newPassword1_ );
    newPassword2_ = trim( newPassword2_ );
    if glb.sysOptB( 'pass_contain_uppercase' ) and  newPassword1_ ~ '^[^A-Z]+$' then
        raise exception 'Password must contain uppercase letters';
    end if;
    if glb.sysOptB( 'pass_contain_lowercase' ) and  newPassword1_ ~ '^[^a-z]+$' then
        raise exception 'Password must contain lowercase letters';
    end if;
    if glb.sysOptB( 'pass_contain_digits' ) and  newPassword1_ ~ '^[^0-9]+$' then
        raise exception 'Password must contain digits';
    end if;
    minLength_ = glb.sysOptI( 'pass_min_length' );
    if length( newPassword1_ ) <= minLength_ then
        raise exception 'Password must contain almost % digits', minLength_;
    end if;
    if newPassword1_ <> newPassword2_ then
        raise exception 'Password and confirmation does not match';
    end if;
    update sg.usuarios
      set
        clave = crypt( password1_, gen_salt( 'bf' ) )
      where
        id_usuario = idSelUser_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + asignarRolUsuario
-- + > sg.asignarRolUsuario: [U|sc.users] Asignar un rol al usuario
create or replace function sg.asignarRolUsuario(
    token_       text,             -- + User connection token
    idSelUser_   integer,          -- + User id
    code_        char )            -- + Rol code
returns void                       -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
    roles_      text;
    id_         integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 1000 );
    select roles, id_usuario into roles_, id_ from sg.usuarios where id_usuario = idSelUser_;
    if id_ is null then
        raise exception 'User not found';
    end if;
    raise notice '%', code_;
    if position( code_ in roles_ ) > 0 then
        return;
    end if;
    update sg.usuarios
      set
        roles = coalesce( roles, '' ) || code_
      where
        id_usuario = idSelUser_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + quitarRolUsuario
-- + > sg.quitarRolUsuario: [U|sc.users] Quitar un rol al usuario
create or replace function sg.quitarRolUsuario(
    token_       text,             -- + User connection token
    idSelUser_   integer,          -- + User id
    code_        char )            -- + Rol code
returns void                       -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 1000 );
    if not exists (select 1 from sg.usuarios where id_usuario = idSelUser_) then
       raise exception 'User not found';
    end if;
    update sg.usuarios
      set
        roles = replace( roles, code_, '' )
      where
        id_usuario = idSelUser_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + borrarUsuario
-- + > sg.borrarUsuario: [D|sc.users] Borrar un usuario
create or replace function sg.borrarUsuario(
    token_       text,             -- + User connection token
    idSelUser_   integer)          -- + User id
returns text                       -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from sg.usuarios where id_usuario = idSelUser_) then
       raise exception 'User not found';
    end if;
    update sg.usuarios
      set
        enabled = false
      where
        id_usuario = idSelUser_;
    return json_build_object(
        'message', 'User saved', 
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + recuperarUsuario
-- + > sg.recuperarUsuario: [U|sc.users] Recupera un usuario
create or replace function sg.recuperarUsuario(
    token_       text,             -- + User connection token
    idSelUser_   integer)          -- + User id
returns void                       -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 1000 );
    if not exists (select 1 from sg.usuarios where id_usuario = idSelUser_) then
       raise exception 'User not found';
    end if;
    update sg.usuarios
      set
        enabled = true
      where
        id_usuario = idSelUser_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + listarUsuario
-- + > sg.listUser: [R|sc.users] Lista de usuarios
create or replace function sg.listarUsuario(
    token_      text,                 -- + User connection token
    idUsers_    integer default null, -- + Id user
    status_     boolean default null  -- + True, actives, False inactives, null both
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
                 array_to_json(array_agg(row_to_json(allusers)))
               from
                (
                  select
                      row_to_json(t)
                    from (
                      select
                          id_usuario,
                          usuario as "Usuario",
                          correo as "Correo",
                          roles as "Rol",
                          "nombre" as "Nombre",
                          institucion as "Institución",
                          "posicion" as "Posición",
                          enabled as "_Estado"
                        from
                          sg.usuarios usr
                        where
                          ( status_ is null
                            or usr.enabled = status_ )
                          and
                           ( idUsers_ is null
                             or id_usuario = idUsers_ )
                    ) t ) allusers ),
       'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + datosUsuario
-- + > sg.datosUsuario: [R|sc.users] Datos de un Usuario
create or replace function sg.datosUsuario(
    token_      text,           -- + User connection token
    idUsers_   integer )        -- + User id
returns text                    -- + Json del informe
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    if not exists ( select 1 from sg.usuarios where id_usuario = idUsers_ ) then
        raise exception 'User not found';
    end if;
    return 
        ( select
              row_to_json(t)
            from (
              select
                  id_usuario,
                  usuario,
                  correo,
                  roles,
                  "nombre",
                  institucion,
                  "posicion",
                  enabled,
                  'ok' as status
                from
                  sg.usuarios
                where
                  id_usuario = idUsers_
            ) t );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--TODO: Tarea: anmentar los 2 campos de auditoria
--+ editarUsuarios
-- + > sg.editarUsuarios: [U|sc.users] Actualizar datos de usuarios
create or replace function sg.editarUsuarios(
    token_          text,             -- + User connection token
    email_          text,             -- + Email user
    roles_          text,             -- + Rol user
    name_           text,             -- + Name user
    institution_    text,             -- + Institution user
    position_       text)             -- + Position user
returns text                          -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from sg.usuarios where correo = email_) then
       raise exception 'User not found';
    end if;
    update sg.usuarios
      set
        "roles" = roles_,
        "nombre" = name_,
        "institucion" = institution_,
        "posicion" = position_
      where
        correo = email_;
    return json_build_object(
        'message', 'User saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + usuarioDatos
-- + > sg.usuarioDatos: [R|sc.users] Datos de un usuario
create or replace function sg.usuarioDatos(
    token_     text              -- + User id
)
returns text                     -- + Json del informe
language 'plpgsql'
as $__$
declare
    json_ text;
begin
    select
        row_to_json( t )
      into
        json_
      from
        ( select
              'ok' as status,
              usuario,
              "nombre",
              "posicion",
              institucion
            from
              sg.usuarios
            where
              id_usuario = (
                  select
                      id_usuario
                    from
                      sg.token
                    where
                      acceso_token::text = token_ )
        ) t;
    if json_ is null then
        raise exception 'User not found';
    end if;
    return json_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--TODO: ¿Se usa esta función?
---- + > sg.resourceAddRole: [U|sc.resources] Asignar un rol al recurso
--create or replace function sg.resourceAddRole(
--    token_         text,             -- + User connection token
--    idSelResource_ integer,          -- + User id
--    rol_           char )            -- + Rol code
--returns void                         -- + 
--language 'plpgsql'
--as $__$
--declare
--    idResource_ integer;
--    roles_      text;
--    id_         integer;
--begin
--    idResource_ = sg.comprobarAcceso( token_, 1000 );
--    select roles, id_resource into roles_, id_ from sg.recursos where id_resource = idSelResource_;
--    if id_ is null then
--        raise exception 'User not found';
--    end if;
--    raise notice '%', rol_;
--    if position( rol_ in roles_ ) > 0 then
--        return;
--    end if;
--    update sg.recursos
--      set
--        roles = coalesce( roles, '' ) || rol_
--      where
--        id_resource = idSelResource_;
--exception when others then
--    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
--    return;
--end;$__$;

--TODO: ¿Se usa esta función?
---- + > sg.resourceDelRole: [U|sc.resources] Quitar un rol al recurso
--create or replace function sg.resourceDelRole(
--    token_         text,             -- + User connection token
--    idSelResource_ integer,          -- + User id
--    rol_           char )            -- + Rol code
--returns void                         -- + 
--language 'plpgsql'
--as $__$
--declare
--    idResource_     integer;
--begin
--    idResource_ = sg.comprobarAcceso( token_, 1000 );
--    if not exists ( select 1 from sg.recursos where id_resource = idSelResource_ ) then
--       raise exception 'User not found';
--    end if;
--    update sg.recursos
--      set
--        roles = replace( roles, rol_, '' )
--      where
--        id_resource = idSelResource_;
--exception when others then
--    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
--    return;
--end;$__$;

-- + actualizarDatosRol
-- + > sg.updateDataRole: [U|sc.roles] Actualizar los datos de un rol
create or replace function sg.actualizarDatosRol(
    token_        text,             -- + User connection token
    idSelRol_     integer,          -- + Rol id
    code_         text,             -- + Rol code
    description_  text)             -- + Rol description
returns void                        -- + 
language 'plpgsql'
as $__$
declare
    idRole_       integer;
begin
    idRole_ = sg.comprobarAcceso( token_, 1000 );
    if not exists (select 1 from sg.roles where id_rol = idSelRol_) then
       raise exception 'Rol not found';
    end if;
    update sg.roles
      set
        codigo = code_,
        descripcion = description_
      where
        id_rol = idSelRol_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + asignarRolRoles
-- + > sg.asignarRolRoles: [U|sc.roles] Asignar un rol a roles
create or replace function sg.asignarRolRoles(
    token_         text,             -- + User connection token
    idSelRol_      integer,          -- + Rol id
    code_          char )            -- + Rol code
returns void                         -- + 
language 'plpgsql'
as $__$
declare
    idRole_     integer;
    roles_      text;
    id_         integer;
begin
    idRole_ = sg.comprobarAcceso( token_, 1000 );
    select roles, id_rol into roles_, id_ from sg.roles where id_rol = idSelRol_;
    if id_ is null then
        raise exception 'Rol not found';
    end if;
    raise notice '%', code_;
    if position( code_ in roles_ ) > 0 then
        return;
    end if;
    update sg.roles
      set
        "role" = coalesce( "role", '' ) || code_
      where
        id_rol = idSelRol_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + quitarRolRoles
-- + > sg.quitarRolRoles: [U|sc.roles] Quitar un rol a roles
create or replace function sg.quitarRolRoles(
    token_         text,             -- + User connection token
    idSelRol_      integer,          -- + User id
    rol_           char )            -- + Rol code
returns void                         -- + 
language 'plpgsql'
as $__$
declare
    idRol_     integer;
begin
    idRol_ = sg.comprobarAcceso( token_, 1000 );
    if not exists ( select 1 from sg.roles where id_rol = idSelRol_ ) then
       raise exception 'Rol not found';
    end if;
    update sg.roles
      set
        "role" = replace( "role", rol_, '' )
      where
        id_rol = idSelRol_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + borrarRol | deleteRol
-- + > sg.borrarRol: [D|sc.roles] Borra un rol
create or replace function sg.borrarRol(
    token_         text,             -- + User connection token
    idSelRol_      integer)          -- + Rol id
returns void                         -- + 
language 'plpgsql'
as $__$
declare
    idRole_     integer;
begin
    idRole_ = sg.comprobarAcceso( token_, 1000 );
    if not exists ( select 1 from sg.roles where id_rol = idSelRol_ ) then
      raise exception 'Resource not found';
    end if;
    update sg.roles
      set
        enabled = false
      where
        id_rol = idSelRol_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + recuperarRol
-- + > sg.recuperarRol: [U|sc.roles] Recupera un rol
create or replace function sg.recuperarRol(
    token_         text,        -- + User connection token
    idSelRol_      integer)     -- + Resource id
returns void                    -- + 
language 'plpgsql'
as $__$
declare
    idRole_     integer;
begin
    idRole_ = sg.comprobarAcceso( token_, 1000 );
    if not exists ( select 1 from sg.roles where id_rol = idSelRol_ ) then
      raise exception 'Resource not found';
    end if;
    update sg.roles
      set
        enabled = true
      where
        id_rol = idSelRol_;
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return;
end;$__$;

-- + listarRoles
-- + > sg.listarRoles: [R|sc.roles] Lista de roles
create or replace function sg.listarRoles(
    token_      text,                  -- + Rol connection token
    idRoles_    integer default null,  -- + Id rol
    status_     boolean default null   -- + True, actives, False inactives, null both
)
returns text
language 'plpgsql'
as $__$
declare
    idRol_     integer;
begin
    idRol_ = sg.comprobarAcceso( token_, 2500 );
    return json_build_object(
        'data', (
            select
                 array_to_json(array_agg(row_to_json(allroles)))
               from
                (
                  select
                      row_to_json(t)
                    from (
                      select
                          id_rol,
                          "codigo" as "Código",
                          "rol" as "Rol",
                          "descripcion" as "Descripción",
                          "enabled" as "_Estado"
                        from
                          sg.roles rol
                        where
                          ( status_ is null
                            or rol.enabled = status_ )
                          and
                           ( idRoles_ is null
                             or id_rol = idRoles_ )
                    ) t ) allroles ),
       'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- + nuevoRol
-- + > sg.nuevoRol: [C|sc.roles] Insertar rol en el sistema
 -- + Nota: Los roles se manejan por letras
create or replace function sg.nuevoRol(
    token_       text,           -- + User connection token
    code_        text,           -- + Role code
    role_        text,           -- + Name role
    desc_        text )          -- + Opt description
returns text                     -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
    idRole_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    code_ = trim( coalesce( code_, '' ) );
    if code_ = '' then
        raise exception 'The role key can''t be empty';
    end if;
    insert into sg.roles (
        codigo,
        "rol",
        descripcion,
        id_creator,
        id_modificator)
      values (
        code_,
        role_,
        desc_,
        idUser_,
        idUser_ )
      returning
        id_rol
      into
        idRole_;
    return json_build_object(
        'message', 'Role created succefully',
        'idRole', idRole_,
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + editarRol
-- + > sg.editarRol: [U|sc.roles] Actualizar datos de roles
create or replace function sg.editarRol(
    token_         text,             -- + User connection token
    idSelRole_     integer,          -- + Id rol
    code_          text,             -- + Code rol
    role_          text,             -- + Role name
    description_   text)             -- + Description rol
returns text                          -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from sg.roles where id_rol = idSelRole_) then
       raise exception 'Role not found';
    end if;
    update sg.roles
      set
        "codigo" = code_,
        "rol" = role_,
        "descripcion" = description_
      where
        id_rol = idSelRole_;
    return json_build_object(
        'message', 'Role saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- borrarRol
-- + > sg.delRole: [D|sc.roles] Borrar un rol
create or replace function sg.delRole(
    token_       text,             -- + Role connection token
    idSelRole_   integer)          -- + Role id
returns text                       -- + 
language 'plpgsql'
as $__$
declare
    idRole_     integer;
begin
    idRole_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from sg.roles where id_rol = idSelRole_) then
       raise exception 'Role not found';
    end if;
    update sg.roles
      set
        enabled = false
      where
        id_rol = idSelRole_;
    return json_build_object(
        'message', 'Role saved', 
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- + > sg.dataRole: [R|sc.roles] Datos de un rol
-- + datosRol
create or replace function sg.datosRol(
    token_       text,           -- + Role connection token
    idSelRole_   integer )       -- + Role id
returns text                    -- + 
language 'plpgsql'
as $__$
declare
    idRole_     integer;
begin
    idRole_ = sg.comprobarAcceso( token_, 2500 );
    if not exists ( select 1 from sg.roles where id_rol = idSelRole_ ) then
        raise exception 'Role not found';
    end if;
    return 
        ( select
              row_to_json(t)
            from (
              select
                  id_rol,
                  codigo,
                  "rol",
                  descripcion,
                  'ok' as status
                from
                  sg.roles
                where
                  id_rol = idSelRole_
            ) t );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;


-- LIST
-- + > sg.listResource: [R|sc.resources] Lista de recursos
-- + listarRecursos
create or replace function sg.listarRecursos(
    token_            text,                  -- + User connection token
    idSelResource_    integer default null,  -- + Id resource
    status_           boolean default null   -- + True, actives, False inactives, null both
)
returns text
language 'plpgsql'
as $__$
declare
    idResource_     integer;
begin
    idResource_ = sg.comprobarAcceso( token_, 2500 );
    return json_build_object(
        'data', (
            select
                 array_to_json(array_agg(row_to_json(allresources)))
               from
                (
                  select
                      row_to_json(t)
                    from (
                      select
                          id_recurso,
                          "codigo" as "Código",
                          "roles" as "Roles",
                          "descripcion" as "Descripción",
                          "enabled" as "_Estado"
                        from
                          sg.recursos res
                        where
                          ( status_ is null
                            or res.enabled = status_ )
                          and
                           ( idSelResource_ is null
                             or id_recurso = idSelResource_ )
                    ) t ) allresources ),
       'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--DATA
-- + > sg.dataResource: [R|sc.resources] Datos de un recurso
-- + datosRecurso
create or replace function sg.datosRecurso(
    token_           text,           -- + User connection token
    idSelResource_   integer )       -- + Resource id
returns text                         -- + 
language 'plpgsql'
as $__$
declare
    idResource_     integer;
begin
    idResource_ = sg.comprobarAcceso( token_, 2500 );
    if not exists ( select 1 from sg.recursos where id_recurso = idSelResource_ ) then
        raise exception 'Resource not found';
    end if;
    return 
        ( select
              row_to_json(t)
            from (
              select
                  id_recurso,
                  codigo,
                  "roles",
                  descripcion,
                  'ok' as status
                from
                  sg.recursos
                where
                  id_recurso = idSelResource_
            ) t );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

-- NEW
-- + > sg.newResource: [C|sc.resources] Crea un nuevo recurso para el sistema
 -- + Nota: Los recursos se manejan por letras
 -- + nuevoRecurso
create or replace function sg.nuevoRecurso(
    token_       text,           -- + User connection token
    code_        integer,        -- + Resource code
    roles_       text,           -- + Resource roles
    description_ text )          -- + Opt description
returns text                     -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
    idResource_ integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    insert into sg.recursos (
        codigo,
        "roles",
        descripcion,
        id_creator,
        id_modificator )
      values (
        code_,
        roles_,
        description_,
        idUser_,
        idUser_ )
      returning
        id_recurso
      into
        idResource_;
    return json_build_object(
        'message', 'Resource created succefully',
        'idResource', idResource_,
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--EDIT
-- + editarRecurso
-- + > sg.editarRecurso: [U|sc.resources] Actualizar datos de recursos
create or replace function sg.editarRecurso(
    token_         text,             -- + User connection token
    idSelResource_ integer,          -- + Id resource
    code_          integer,          -- + Code resource
    roles_         text,             -- + Resource name
    description_   text)             -- + Description resource
returns text                          -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from sg.recursos where id_recurso = idSelResource_) then
       raise exception 'Resource not found';
    end if;
    update sg.recursos
      set
        "codigo" = code_,
        "roles" = roles_,
        "descripcion" = description_
      where
        id_recurso = idSelResource_;
    return json_build_object(
        'message', 'Resource saved',
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;

--DEL
-- + borrarRecurso
-- + > sg.borrarRecurso: [D|sc.resources] Elimina un recursos del sistema
create or replace function sg.borrarRecurso(
    token_           text,             -- + User connection token
    idSelResource_   integer)          -- + Resource id
returns text                       -- + 
language 'plpgsql'
as $__$
declare
    idUser_     integer;
begin
    idUser_ = sg.comprobarAcceso( token_, 2500 );
    if not exists (select 1 from sg.recursos where id_recurso = idSelResource_) then
       raise exception 'Resource not found';
    end if;
    update sg.recursos
      set
        enabled = false
      where
        id_recurso = idSelResource_;
    return json_build_object(
        'message', 'Resource saved', 
        'status', 'ok' );
exception when others then
    raise exception '%', glb.checkError( SQLSTATE, SQLERRM );
    return '';
end;$__$;
