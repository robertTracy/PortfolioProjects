--SELECT *
--FROM PortfolioProject..CovidDeaths$
--ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1,2

--Looking at Total Cases Vs Total Deaths Jan 2020 to April 2021
--Shows the likelihood of dying if you catch the virus in that country during that time period.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths$
WHERE location like '%states%'
AND continent is not null
ORDER BY 1,2

--Looking at the Total Cases VS Population
--Showing what percentage of population got Covid during the time period
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_infected
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%states%'
ORDER BY 1,2


--Looking at Countries with highest infection rate compared to their population

SELECT location, population, MAX(total_cases) as top_infection_ct, MAX((total_cases/population))*100 AS top_percent_infected
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY top_percent_infected DESC

--Showing countries with the highest death count per population

SELECT location, MAX(CAST(total_deaths as INT)) as total_death_ct -- need to cast total_deaths as an integer to display properly because data type is varchar
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%states%'
WHERE continent IS NOT NULL --When continent is null, that means the continent is included in the list of locations which messes up the column
GROUP BY location --Need to group by because there is an aggregate function
ORDER BY total_death_ct DESC

--Correct way to get numbers for continent

SELECT location, MAX(CAST(total_deaths as INT)) as total_death_ct 
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%states%'
WHERE continent IS NULL 
GROUP BY location --Need to group by because there is an aggregate function
ORDER BY total_death_ct DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT
--Showing the continents with the highest death count
SELECT continent, MAX(CAST(total_deaths as INT)) as total_death_ct 
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%states%'
WHERE continent IS NOT NULL 
GROUP BY continent --Need to group by because there is an aggregate function
ORDER BY total_death_ct DESC

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int)) / SUM(new_cases) * 100 as death_percentage
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int)) / SUM(new_cases) * 100 as death_percentage
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

-- Looking at total population vs vaccination - total people who have been vaccinated.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingtotalvaccinated 
-- can also use SUM(CONVERT(int, vac.new_vaccinations)) --line above provides a column to add a rolling total.
--, (rollingtotalvaccinated/dea.population)*100  --cannot use the brand new column without creating a temp table
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- Use CTE

With PopvsVac (continent, location, date, population, new_vaccinations, rollingtotalvaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingtotalvaccinated 
-- can also use SUM(CONVERT(int, vac.new_vaccinations)) --line above provides a column to add a rolling total.
--, (rollingtotalvaccinated/dea.population)*100  --cannot use the brand new column without creating a temp table or CTE
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (rollingtotalvaccinated/population*100) as percentvaccinated
FROM PopvsVac

--TEMP Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE  #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingtotalvaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingtotalvaccinated 
-- can also use SUM(CONVERT(int, vac.new_vaccinations)) --line above provides a column to add a rolling total.
--, (rollingtotalvaccinated/dea.population)*100  --cannot use the brand new column without creating a temp table or CTE
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (rollingtotalvaccinated/population*100) as percentvaccinated
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingtotalvaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3