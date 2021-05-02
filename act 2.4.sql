use BluePrint

--1) Listar los nombres de proyecto y costo estimado de aquellos proyectos cuyo costo estimado sea mayor al promedio de costos.

select 
	P.Nombre as Proyecto,
	P.CostoEstimado 
from Proyectos as P
where P.CostoEstimado > (select AVG(P.CostoEstimado) from Proyectos as P)



--2) Listar razón social, cuit y contacto (email, celular o teléfono) de aquellos clientes 
--   que no tengan proyectos que comiencen en el año 2020.

select 
	C.RazonSocial,
	C.CUIT,
	COALESCE(C.EMail, C.Celular, C.Telefono) as Contacto 
from Clientes as C
where C.ID not in (select P.IDCliente from Proyectos as P where YEAR(P.FechaInicio) = '2020')



--3) Listado de países que no tengan clientes relacionados.

select P.Nombre
from Paises as P	
where P.ID not in (
	select distinct P.ID from Paises as P
	inner join Ciudades as C on C.IDPais = P.ID
	inner join Clientes as CL on CL.IDCiudad = C.ID
)



--4) Listado de proyectos que no tengan tareas registradas.

select P.Nombre
from Proyectos as P
where P.ID not in (
	select distinct P.ID from Proyectos as P
	inner join Modulos as M on M.IDProyecto = P.ID
	inner join Tareas as T on T.IDModulo = M.ID
)




--5) Listado de tipos de tareas que no registren tareas pendientes.

--------- REVISAR -------------
select TT.Nombre as 'Tarea'
from TiposTarea as TT
where TT.ID not in (
	select TT.ID from TiposTarea as TT
	inner join Tareas as T on T.IDTipo = TT.ID
)



--6) Listado con ID, nombre y costo estimado de proyectos cuyo costo estimado sea menor al costo estimado 
--   de cualquier proyecto de clientes extranjeros (clientes que no sean de Argentina o no tengan asociado un país).


---------- REVISAR ----------------------------------
select 
	P.ID, P.Nombre, P.CostoEstimado
from Proyectos as P
where P.CostoEstimado < all (
	select PR.CostoEstimado from Proyectos as PR
	left join Clientes as CL on CL.ID = PR.IDCliente
	left join Ciudades as C on C.ID = CL.IDCiudad
	left join Paises as P on P.ID = C.IDPais
	where P.Nombre not like 'Argentina' or CL.IDCiudad is null
)



--7) Listado de apellido y nombres de colaboradores que hayan demorado más en una tarea que
--   el colaborador de la ciudad de 'Buenos Aires' que más haya demorado.

select
	CONCAT(C.Nombre,' ' ,C.Apellido) as Colaborador
from Colaboradores as C
where C.ID in (
	select C.ID from Colaboradores as C
	inner join Colaboraciones as CB on CB.IDColaborador = C.ID
	where CB.Tiempo > (
		select MAX(CB2.Tiempo) from Colaboraciones as CB2
		inner join Colaboradores as C2 on C2.ID = CB2.IDColaborador
		inner join Ciudades on Ciudades.ID = C2.IDCiudad
		where Ciudades.Nombre like 'Buenos Aires'
	)
)



--8) Listado de clientes indicando razón social, nombre del país (si tiene) y 
--   cantidad de proyectos comenzados y cantidad de proyectos por comenzar.

select
	CL.RazonSocial,
	COALESCE((select P.Nombre from Paises as P
		inner join Ciudades as C on C.IDPais = P.ID
		inner join Clientes as CL2 on CL2.IDCiudad = C.ID
		where CL2.ID = CL.ID
	), ' - ') as Pais,
	(select COUNT(distinct P.ID) from Proyectos as P 
	where P.IDCliente = CL.ID and
	--P.FechaFin > GETDATE() and
	P.FechaInicio < GETDATE()) as 'Proyectos comenzados',
	(select COUNT(distinct P.ID) from Proyectos as P 
	where P.IDCliente = CL.ID and
	--P.FechaFin > GETDATE() and
	P.FechaInicio > GETDATE()) as 'Proyectos por comenzar'
from Clientes as CL



--9) Listado de tareas indicando nombre del módulo, nombre del tipo de tarea, 
--cantidad de colaboradores externos que la realizaron y cantidad de colaboradores internos que la realizaron.

select distinct
	M.Nombre as Modulo,
	 (select TT.Nombre from TiposTarea as TT
	inner join Tareas as T on T.IDTipo = TT.ID
	inner join Modulos as M2 on M2.ID = T.IDModulo
	where M2.ID = M.ID) as Tarea	
from Modulos as M




/*10 Listado de proyectos indicando nombre del proyecto, costo estimado,
cantidad de módulos cuya estimación de fin haya sido exacta, cantidad de
módulos con estimación adelantada y cantidad de módulos con estimación
demorada.
Adelantada → estimación de fin haya sido inferior a la real.
Demorada → estimación de fin haya sido superior a la real.
11 Listado con nombre del tipo de tarea y total abonado en concepto de
honorarios para colaboradores internos y total abonado en concepto de
honorarios para colaboradores externos.
12 Listado con nombre del proyecto, razón social del cliente y saldo final del
proyecto. El saldo final surge de la siguiente fórmula:
Costo estimado - Σ(HCE) - Σ(HCI) * 0.1
Siendo HCE → Honorarios de colaboradores externos y HCI → Honorarios de
colaboradores internos.
13 Para cada módulo listar el nombre del proyecto, el nombre del módulo, el total
en tiempo que demoraron las tareas de ese módulo y qué porcentaje de
tiempo representaron las tareas de ese módulo en relación al tiempo total de
tareas del proyecto.
14 Por cada colaborador indicar el apellido, el nombre, 'Interno' o 'Externo' según
su tipo y la cantidad de tareas de tipo 'Testing' que haya realizado y la
cantidad de tareas de tipo 'Programación' que haya realizado.
NOTA: Se consideran tareas de tipo 'Testing' a las tareas que contengan la
palabra 'Testing' en su nombre. Ídem para Programación.
15 Listado apellido y nombres de los colaboradores que no hayan realizado
tareas de 'Diseño de base de datos'.
16 Por cada país listar el nombre, la cantidad de clientes y la cantidad de
colaboradores.
17 Listar por cada país el nombre, la cantidad de clientes y la cantidad de
colaboradores de aquellos países que no tengan clientes pero sí
colaboradores.
18 Listar apellidos y nombres de los colaboradores internos que hayan realizado
más tareas de tipo 'Testing' que tareas de tipo 'Programación'.
19 Listar los nombres de los tipos de tareas que hayan abonado más del
cuádruple en colaboradores internos que externos
20 Listar los proyectos que hayan registrado igual cantidad de estimaciones
demoradas que adelantadas y que al menos hayan registrado alguna
estimación adelantada y que no hayan registrado ninguna estimación exacta.*/