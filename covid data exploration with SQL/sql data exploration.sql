/* 

COVID 19 DATA EXPLORATION


Skills used: Joins, CTE's, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types

*/

-- connect to database 

-- CREATE DATABASE PortfolioProject
USE PortfolioProject


-- visualise first 10 rows of the datasets

SELECT TOP(10) * FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date
-- where clause excludes 'location' values that track counts by continent, by income class and globally


SELECT TOP(10) * FROM CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY location, date


-- Select initial data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
where continent is not null
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- likelihood of dying if you contract covid in the UK over time

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as PercentageCasesDeceased
FROM CovidDeaths
-- WHERE continent IS NOT NULL
WHERE location like '%united kingdom%'
ORDER BY 1,2


-- Total Cases vs Population
-- Percentage of UK population infected with Covid over time

SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
-- WHERE continent IS NOT NULL
WHERE location like '%United Kingdom%'
ORDER BY 1,2


-- Looking at countries with the Highest Infection Rates based on population size

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population)*100 as PercentPopulationInfected
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc


-- Looking at countries with the Highest Death Rates based on population size

SELECT location, population, MAX(CAST(total_deaths AS int)) AS HighestDeathCount, (MAX(CAST(total_deaths AS int))/population)*100 as PercentPopulationDeceased
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationDeceased desc


-- Looking at Countries with Highest Death Count

SELECT location, MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc




-- BREAKING THINGS DOWN BY CONTINENT




-- Looking at the continents with the highest death count

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc


-- GLOBAL NUMBERS

-- worldwide death percentage

SELECT SUM(new_cases) as total_cases
, SUM(CAST(new_deaths as int)) as total_deaths 
,(SUM(CAST(new_deaths as int))/SUM(new_cases))*100 as PercentageCasesDeceased
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- join our two tables
SELECT * 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date


-- Total Population vs Vaccinations
-- Looking at percentage of population that has received at least one covid vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- Using CTEs to use calculated columns with partition by

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)

SELECT * , (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;


-- Using TEMP TABLES to use calculated columns with partition by

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255)
, Location nvarchar(255)
, Date datetime
, Population numeric
, New_vacinnations numeric
, RollingPeopleVac numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVac
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3


SELECT * , (RollingPeopleVac/Population)*100
FROM #PercentPopulationVaccinated


-- create view to store data for later

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT * 
FROM PercentPopulationVaccinated
