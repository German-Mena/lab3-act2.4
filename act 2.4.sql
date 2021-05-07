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
--   de cualquier proyecto de clientes nacionales (clientes extranjeros o que no tengan asociado un país).

-- EN EL PDF LA CONSIGNA ES OTRA

select 
	P.ID, P.Nombre, P.CostoEstimado
from Proyectos as P
where P.CostoEstimado < all (
	select PR.CostoEstimado from Proyectos as PR
	left join Clientes as CL on CL.ID = PR.IDCliente
	left join Ciudades as C on C.ID = CL.IDCiudad
	left join Paises as P on P.ID = C.IDPais
	where P.Nombre = 'Argentina' or CL.IDCiudad is null
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

select 
	M.Nombre as Modulo,
	TT.Nombre as Tarea,
	(
		select count(distinct C.ID) from Colaboradores as C
		inner join Colaboraciones as CO on CO.IDColaborador = C.ID
		inner join Tareas as T on T.ID = CO.IDTarea
		where M.ID = T.IDModulo and TT.ID = T.IDTipo and C.Tipo = 'I'
	) as 'internos',
	(
		select count(distinct C.ID) from Colaboradores as C
		inner join Colaboraciones as CO on CO.IDColaborador = C.ID
		inner join Tareas as T on T.ID = CO.IDTarea
		where M.ID = T.IDModulo and TT.ID = T.IDTipo and C.Tipo = 'E'
	) as 'externos'
from Modulos as M
	inner join Tareas as T on T.IDModulo = M.ID
	inner join TiposTarea as TT on TT.ID = T.IDTipo
--order by M.Nombre asc, TT.Nombre asc



--10) Listado de proyectos indicando nombre del proyecto, costo estimado, cantidad de módulos cuya estimación de fin haya sido exacta,
--    cantidad de módulos con estimación adelantada y cantidad de módulos con estimación demorada.
--    Adelantada → estimación de fin haya sido inferior a la real.
--    Demorada → estimación de fin haya sido superior a la real.

select 
	P.Nombre as Proyecto,
	P.CostoEstimado as 'Costo Estimado',
	(
		select count(distinct M.ID) from Modulos as M
		where M.IDProyecto = P.ID and M.FechaEstimadaFin = M.FechaFin
	) as 'Exacta',
	(
		select count(distinct M.ID) from Modulos as M
		where M.IDProyecto = P.ID and M.FechaFin < M.FechaEstimadaFin
	) as 'Adelantada',
	(
		select count(distinct M.ID) from Modulos as M
		where M.IDProyecto = P.ID and M.FechaFin > M.FechaEstimadaFin
	) as 'Demorada'
from Proyectos as P



--11) Listado con nombre del tipo de tarea y total abonado en concepto de honorarios para colaboradores internos y 
--    total abonado en concepto de honorarios para colaboradores externos.

select TT.Nombre as Tarea,
	(
		select sum(CO.PrecioHora * CO.Tiempo) from Colaboradores as C
		inner join Colaboraciones as CO on CO.IDColaborador = C.ID
		inner join Tareas as T on T.ID = CO.IDTarea
		where C.Tipo = 'I' and T.IDTipo = TT.ID
	) as Internos,
	(
		select sum(CO.PrecioHora * CO.Tiempo) from Colaboradores as C
		inner join Colaboraciones as CO on CO.IDColaborador = C.ID
		inner join Tareas as T on T.ID = CO.IDTarea
		where C.Tipo = 'E' and T.IDTipo = TT.ID
	) as Externos
from TiposTarea as TT



--12) Listado con nombre del proyecto, razón social del cliente y saldo final del proyecto. El saldo final surge de la siguiente fórmula:
--    Costo estimado - Σ(HCE) - Σ(HCI) * 0.1
--    Siendo HCE → Honorarios de colaboradores externos y HCI → Honorarios de colaboradores internos.

select P.Nombre as Proyecto, CL.RazonSocial,
(P.CostoEstimado - 
	(	--IMPORTANTE: CUANDO OPERE ARITMETICAMENTE, AGREGAR FUNCION IS NULL
		select isnull(sum(CO.PrecioHora * CO.Tiempo),0) from Colaboradores as C
		inner join Colaboraciones as CO on CO.IDColaborador = C.ID
		inner join Tareas as T on T.ID = CO.IDTarea
		inner join Modulos as M on M.ID = T.IDModulo
		where M.IDProyecto = P.ID and C.Tipo = 'E'
	) - 
	(
		select isnull(sum(CO.PrecioHora * CO.Tiempo),0) from Colaboradores as C
		inner join Colaboraciones as CO on CO.IDColaborador = C.ID
		inner join Tareas as T on T.ID = CO.IDTarea
		inner join Modulos as M on M.ID = T.IDModulo
		where M.IDProyecto = P.ID and C.Tipo = 'I'
	) * 0.1)as 'Saldo Final'
from Proyectos as P	
	inner join Clientes as CL on CL.ID = P.IDCliente



--13) Para cada módulo listar el nombre del proyecto, el nombre del módulo, el total en tiempo que 
--    demoraron las tareas de ese módulo y qué porcentaje de tiempo representaron las tareas de ese módulo
--    en relación al tiempo total de tareas del proyecto.

select P.Nombre as Proyecto, M.Nombre as Modulo,
(
	select isnull(sum(C.Tiempo),0) from Colaboraciones as C
	inner join Tareas as T on T.ID = C.IDTarea
	inner join Modulos as M2 on M2.ID = T.IDModulo
	where T.IDModulo = M.ID and M2.IDProyecto = P.ID
	--where T.IDModulo = M.ID -- ESTO TAMBIEN FUNCIONA
) as Tiempo,
(
	(
		(
			select isnull(sum(C.Tiempo),0) from Colaboraciones as C
			inner join Tareas as T on T.ID = C.IDTarea
			inner join Modulos as M2 on M2.ID = T.IDModulo
			where T.IDModulo = M.ID and M2.IDProyecto = P.ID
		) * 1.0 / 
		(
			select isnull(sum(C.Tiempo),1) from Colaboraciones as C
			inner join Tareas as T on T.ID = C.IDTarea
			inner join Modulos as M2 on M2.ID = T.IDModulo
			where M2.IDProyecto = P.ID
		) * 1.0
	) * 100
) as '%'
from Proyectos as P
inner join Modulos as M on M.IDProyecto = P.ID



--14) Por cada colaborador indicar el apellido, el nombre, 'Interno' o 'Externo' según su tipo y la cantidad de tareas de tipo 'Testing'
--    que haya realizado y la cantidad de tareas de tipo 'Programación' que haya realizado.
--    NOTA: Se consideran tareas de tipo 'Testing' a las tareas que contengan la palabra 'Testing' en su nombre. Ídem para Programación.
	
select C.Apellido, C.Nombre, 
case 
	when C.Tipo like 'I' then 'Interno'
	--when C.Tipo like 'E' then 'Externo'
	else 'Externo'
End as Tipo, 
(
	select count(*) from Colaboraciones as COL
	inner join Tareas as T on T.ID = COL.IDTarea
	inner join TiposTarea as TT on TT.ID = T.IDTipo
	where COL.IDColaborador = C.ID and TT.Nombre like '%Testing%'
) as Testing,
(
	select count(*) from Colaboraciones as COL
	inner join Tareas as T on T.ID = COL.IDTarea
	inner join TiposTarea as TT on TT.ID = T.IDTipo
	where COL.IDColaborador = C.ID and TT.Nombre like '%Programación%'
) as Programacion
from Colaboradores as C



--15) Listado apellido y nombres de los colaboradores que no hayan realizado tareas de 'Diseño de base de datos'.

-- MAL
select distinct C.Apellido, C.Nombre--, TT.Nombre
from Colaboradores as C
left join Colaboraciones as CO on CO.IDColaborador = C.ID
left join Tareas as T on T.ID = CO.IDTarea
left join TiposTarea as TT on TT.ID = T.IDTipo
where TT.Nombre not like 'Diseño de base de datos'
order by C.Apellido asc
-- No se puede resolver solo con joins ya que trae los registros de los colaboradores que no hayan realizado
-- este tipo de tarea aunque lo hayan hecho.

select C.Nombre, C.Apellido
from Colaboradores as C
where C.ID not in (
	select distinct CO.IDColaborador from Colaboraciones as CO
	left join Tareas as T on T.ID = CO.IDTarea
	left join TiposTarea as TT on TT.ID = T.IDTipo
	where TT.Nombre like 'Diseño de base de datos'
)



--16) Por cada país listar el nombre, la cantidad de clientes y la cantidad de colaboradores.

select P.Nombre as Pais,
(
	select count(CL.ID) from Clientes as CL
	inner join Ciudades as C on C.ID = CL.IDCiudad
	where C.IDPais = P.ID
) as Clientes,
(
	select count(CO.ID) from Colaboradores as CO
	inner join Ciudades as C on C.ID = CO.IDCiudad
	where C.IDPais = P.ID
) as Colaboradores
from Paises as P



--17) Listar por cada país el nombre, la cantidad de clientes y la cantidad de colaboradores de aquellos países
--    que no tengan clientes pero sí colaboradores.


--FORMA LARGA
select P.Nombre as Pais,
(
	select count(CL.ID) from Clientes as CL
	inner join Ciudades as C on C.ID = CL.IDCiudad
	where C.IDPais = P.ID
) as Clientes,
(
	select count(CO.ID) from Colaboradores as CO
	inner join Ciudades as C on C.ID = CO.IDCiudad
	where C.IDPais = P.ID
) as 'Colaboradores'
from Paises as P
where (
	select count(CL.ID) from Clientes as CL
	inner join Ciudades as C on C.ID = CL.IDCiudad
	where C.IDPais = P.ID
) = 0 and (
	select count(CO.ID) from Colaboradores as CO
	inner join Ciudades as C on C.ID = CO.IDCiudad
	where C.IDPais = P.ID
) > 0  



--18) Listar apellidos y nombres de los colaboradores internos que hayan realizado más tareas de tipo 'Testing' que tareas de tipo 'Programación'.

select CO.Apellido, CO.Nombre
from Colaboradores as CO
where ((
	select count(*) from Colaboraciones as C
	inner join Tareas as T on T.ID = C.IDTarea
	inner join TiposTarea as TT on TT.ID = T.IDTipo
	inner join Colaboradores as CO1 on CO1.ID = C.IDColaborador
	where CO1.Tipo like 'I' and TT.Nombre like '%Testing%' and CO1.ID = CO.ID
) > (
	select count(*) from Colaboraciones as C
	inner join Tareas as T on T.ID = C.IDTarea
	inner join TiposTarea as TT on TT.ID = T.IDTipo
	inner join Colaboradores as CO2 on CO2.ID = C.IDColaborador
	where CO2.Tipo like 'I' and TT.Nombre like '%Programación%' and CO2.ID = CO.ID
))



--19 Listar los nombres de los tipos de tareas que hayan abonado más del cuádruple en colaboradores internos que externos

select TT.Nombre as 'Nombre del tipo de tarea'
from TiposTarea as TT
where ((
	select isnull(sum(C.PrecioHora * C.Tiempo),0) from Tareas as T
	inner join Colaboraciones as C on C.IDTarea = T.ID
	inner join Colaboradores as COL on COL.ID = C.IDColaborador
	inner join TiposTarea as TT2 on TT2.ID = T.IDTipo
	where COL.Tipo like 'I' and TT2.ID = TT.ID
) > 4 * (
	select isnull(sum(C.PrecioHora * C.Tiempo),0) from Tareas as T
	inner join Colaboraciones as C on C.IDTarea = T.ID
	inner join Colaboradores as COL on COL.ID = C.IDColaborador
	inner join TiposTarea as TT2 on TT2.ID = T.IDTipo
	where COL.Tipo like 'E' and TT2.ID = TT.ID
))



--20) Listar los proyectos que hayan registrado igual cantidad de estimaciones demoradas que adelantadas y que al menos
--    hayan registrado alguna estimación adelantada y que no hayan registrado ninguna estimación exacta.

select P.Nombre as Proyectos
from Proyectos as P
where (
	(
		select count(distinct M.ID) from Modulos as M
		where M.FechaEstimadaFin > M.FechaFin and M.IDProyecto = P.ID
	) = (
		select count(distinct M.ID) from Modulos as M
		where M.FechaEstimadaFin < M.FechaFin and M.IDProyecto = P.ID
	) and (
		select count(distinct M.ID) from Modulos as M
		where M.FechaEstimadaFin < M.FechaFin and M.IDProyecto = P.ID
	) > 0 and (
		select count(distinct M.ID) from Modulos as M
		where M.FechaEstimadaFin = M.FechaFin and M.IDProyecto = P.ID
	) = 0
)