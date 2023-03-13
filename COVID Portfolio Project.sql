-- Select data we will be using from CovidDeaths table

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- Looking at Total Cases vs Total Deaths
-- This shows the likelihood of dying from contracting Covid based on country

SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/total_cases)*100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2



-- Looking at the Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT location, date, total_cases, population, (CONVERT(float, total_cases)/population)*100 AS PercentInfected
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2



-- Looking at each Countries Highest Number of Covid Cases and comparing it to its Population

SELECT location, population, MAX(total_cases) AS HighestInfectedCount, MAX((CONVERT(float, total_cases)/population))*100 AS MaxPercentInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY MaxPercentInfected DESC



-- Showing Countries with Highest Death Count...

SELECT location, population, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

-- ... and Countries with Highest Percentage of Population Death

SELECT location, population, MAX(total_deaths) AS TotalDeathCount, MAX(CONVERT(float, total_deaths)/population)*100 AS PercentDeathofPopulation
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentDeathofPopulation DESC

-- Showing the Total Deaths of each Continent

SELECT continent, max(total_deaths) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- Looking at New Deaths vs Population

SELECT continent, location, date, population, new_deaths, SUM(new_deaths) OVER (PARTITION BY location ORDER BY location, date) AS RunningDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 2,3

-- Making a temp table and inserting previous query
-- Then looking at Percentage of Country Population that has died from Covid 

DROP TABLE IF EXISTS #NewDeathvsPop
CREATE TABLE #NewDeathvsPop
(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_deaths NUMERIC,
    RunningDeathCount NUMERIC
)
INSERT INTO #NewDeathvsPop
SELECT continent, location, date, population, new_deaths, SUM(new_deaths) OVER (PARTITION BY location ORDER BY location, date) AS RunningDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

SELECT *, (CAST(RunningDeathCount AS FLOAT)/population)*100 AS PercentNewDeaths
FROM #NewDeathvsPop
ORDER BY 2,3





-- Joining CovidDeaths table with CovidVaccinations table

SELECT * 
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date



-- Looking at Population vs Vaccinations
-- Includes Running Count of Vaccinations in each Country

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningVacCount
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Making a CTE with the previous query in order to calculate the Percentage of Population Vaccinated

WITH PopvsVac (continent, location, date, population, new_vaccinations, RunningVacCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningVacCount
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
)
SELECT *, (CAST(RunningVacCount AS FLOAT)/population)*100 AS PercentVaccinated
FROM PopvsVac
ORDER BY 2,3

GO
-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningVacCount
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL