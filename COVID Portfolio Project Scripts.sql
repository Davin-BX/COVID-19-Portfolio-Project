--First Step is to Explore the Data
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

-- Looking at Total Cases vs Total Deaths
--Select The Specific Data that we are going to be using

SELECT Location, date, total_cases,  total_deaths, (CONVERT(FLOAT, total_deaths)/NULLIF(CONVERT(FLOAT, total_cases), 0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Finding out the likelihood of dying if you contract covid in whichever country you reside
SELECT Location, date, total_cases,  total_deaths, (CONVERT(FLOAT, total_deaths)/NULLIF(CONVERT(FLOAT, total_cases), 0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- We can narrow down this data further to look at the likelihood of dying from contracting covid in a specific country

-- An Example of how we could narrow down this data for a specific country. This Example specifically is used to find the likelihood of dying if you contract COVID in the United States
SELECT Location, date, total_cases,  total_deaths, (CONVERT(FLOAT, total_deaths)/NULLIF(CONVERT(FLOAT, total_cases), 0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2

--We can now expand and alter this code to find the answers to various other inquiries we may have.

-- Looking at Total Cases vs Population
-- Shows what percentage of the various countries population was diagnosed with COVID
SELECT Location, date, population, total_cases, (CONVERT(FLOAT, total_cases)/NULLIF(CONVERT(FLOAT, population), 0))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at Countries with Highest Infection Rate
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((CONVERT(FLOAT, total_cases)/NULLIF(CONVERT(FLOAT, population), 0)))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Rates
SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE location != 'World' AND location NOT LIKE '%income%' AND continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount desc

-- Showing Continents with Highest Death Rates
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Total COVID Cases Around the World
SELECT SUM(CAST(new_cases AS BIGINT)) AS TotalNewCases, 
SUM(CAST(new_deaths AS BIGINT)) AS TotalNewDeaths, SUM(CAST(new_deaths AS BIGINT))/NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total New Cases VS Total New Deaths around The World over Time
SELECT date, SUM(CAST(new_cases as int)) AS TotalNewCases, 
SUM(CAST(new_deaths AS int)) AS TotalNewDeaths, SUM(CAST(new_deaths AS float))/NULLIF(SUM(CAST(new_cases AS float)), 0)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations
WITH PopVsVac (Continent, Location, date, Population, New_Vaccinations, RollingNumberOfVaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) 
OVER (Partition by dea.location Order by dea.location, dea.date) AS RollingNumberOfVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN portfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingNumberOfVaccinations/Population)*100 AS PercentageVaccinatedPerDay
FROM PopVsVac

--Creating a Temporary Table Allows for Convenient Access to Data from The 2 Databases

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations nvarchar(MAX),
RollingNumberOfVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingNumberOfVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN portfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingNumberOfVaccinations/Population)*100 AS PercentageVaccinatedPerDay
FROM #PercentPopulationVaccinated

--Creating a View to Store Data for Later Visualizations
Create View PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingNumberOfVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN portfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated