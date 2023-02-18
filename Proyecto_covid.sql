/*
Exploracion de los datos sobre el Covid 19 
Skills usados: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


/* Visualizando la tabla coviddeaths */

SELECT *
FROM portafolio_sql.coviddeaths
WHERE continent is not null 
ORDER BY 3,4

-- Desglose por pais
-- Total de casos vs total muertes

SELECT 
	location, 
    date, 
    total_cases, 
    total_deaths, 
    ROUND((total_deaths/total_cases)*100,2) as DeathPercentage
FROM portafolio_sql.coviddeaths
WHERE
	continent IS NOT NULL
    -- AND location like '%Afgha%'
order by 1,2

-- Total de casos vs la poblacion

SELECT 
	location, 
	date, 
    population_density AS population, 
    total_cases,  
    ROUND((total_cases/population_density)*100,2) as PercentPopulationInfected
FROM portafolio_sql.coviddeaths
--WHERE location LIKE '%Afgha%'
ORDER BY 1,2

-- Paises con la tasa de infeccion mas alta, en comparacion a la poblacion.

SELECT
	location, 
    population_density AS population, 
    MAX(total_cases) as HighestInfectionCount,  
    ROUND(MAX((total_cases/population_density))*100,2) as PercentPopulationInfected
FROM portafolio_sql.coviddeaths
-- WHERE location LIKE '%Argen%'
GROUP BY 1, 2
ORDER BY PercentPopulationInfected desc


-- Paises con mortalidad segun la poblacion

SELECT 
	location, 
    MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM portafolio_sql.coviddeaths
WHERE 
	continent is not null 
	-- AND location LIKE '%Argen%'
GROUP BY location
ORDER BY TotalDeathCount desc

-- Desglose por Continente
-- Mostrando los continentes con el mayor recuento de muertes por población

SELECT 
	continent, 
	MAX(Total_deaths) AS TotalDeathCount
FROM portafolio_sql.coviddeaths
WHERE 
	continent is not null
    -- AND location LIKE '%Venez%'
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Números Globales

SELECT
	SUM(new_cases) as total_cases, 
    SUM(new_deaths) as total_deaths, 
    SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
FROM portafolio_sql.coviddeaths
wHERE 
	continent is not null
    -- AND location like '%states%'
-- GROUP BY date
ORDER BY 1,2

-- Total Ppblacion vs Vacunacion
-- Muestra el porcentaje de población que ha recibido al menos una vacuna Covid

SELECT 
	d.continent, 
    d.location, 
    d.date, 
    d.population_density, 
    v.new_vaccinations,
    SUM((v.new_vaccinations)) OVER (Partition by d.population_density Order by d.population_density, d.Date) as RollingPeopleVaccinated
FROM portafolio_sql.coviddeaths AS d
	INNER JOIN portafolio_sql.covidvacunations AS v
		ON d.location = v.location
		AND d.date = v.date
WHERE d.continent is not null 
ORDER BY 2,3

-- Uso de CTE para realizar el cálculo en la partición por en la consulta anterior

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
	d.continent, 
    d.location, 
    d.date, 
    d.population_density, 
    v.new_vaccinations,
    SUM((v.new_vaccinations)) OVER (Partition by d.population_density Order by d.population_density, d.Date) as RollingPeopleVaccinated
FROM portafolio_sql.coviddeaths AS d
	INNER JOIN portafolio_sql.covidvacunations AS v
		ON d.location = v.location
		AND d.date = v.date
WHERE d.continent is not null 
)
SELECT *, 
	ROUND((RollingPeopleVaccinated/Population)*100,2)
FROM PopvsVac


-- Uso de la tabla temporal para realizar el cálculo en la partición por en la consulta anterior

DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated (
Continent VARCHAR(255),
Location VARCHAR(255),
Date DATE,
Population INT,
New_vaccinations INT,
RollingPeopleVaccinated INT
)

INSERT INTO PercentPopulationVaccinated
SELECT 
	d.continent, 
    d.location, 
    d.date, 
    d.population_density, 
    v.new_vaccinations, 
    SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
FROM portafolio_sql.coviddeaths AS d
	INNER JOIN portafolio_sql.covidvacunations AS v
		On d.location = v.location
		AND d.date = v.date

SELECT *, ROUND((RollingPeopleVaccinated/Population)*100,2)
FROM PercentPopulationVaccinated

-- Crear vista para almacenar datos para visualizaciones posteriores

CREATE  OR REPLACE VIEW VW_percentpopulationvaccinated AS (
SELECT 
	d.continent,
	d.location, 
    d.date, 
    d.population_density, 
    v.new_vaccinations, 
    SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
FROM portafolio_sql.coviddeaths AS d
	INNER JOIN portafolio_sql.covidvacunations AS v
		On d.location = v.location
		AND d.date = v.date
WHERE 
	d.continent is not null 
)
