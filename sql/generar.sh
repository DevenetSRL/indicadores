r=/home/alejandro/projects
#r=/var/www/indicadores

r=$(grep 'images:' /etc/indicadores/paths.conf |cut -d\: -f2)


#make sql;
make
token=$(echo "select sg.conectarUsuario( 1 )"|psql -t indicadores|xargs)
echo "select id_ficha,im.generarFichasParaTodosLosMunicipios( '$token', id_ficha, '$r/www/img' ) from im.fichas where enabled"|psql indicadores
echo "select im.generarFichasParaTodosLosAgregados( '$token', id_sintesis, '$r/www/img' )" from im.sintesis where enabled|psql indicadores
