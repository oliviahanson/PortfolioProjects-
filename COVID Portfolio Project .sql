SELECT * 
FROM AAPortfolioProject.CovidDeaths 
WHERE continent !="" AND continent IS NOT NULL
ORDER BY 3,4 

/*SELECT * 
FROM AAPortfolioProject.CovidVaccinations cv 
ORDER BY 3,4 ;*/

-- Select Data we will use--

SELECT location , `date` , total_cases , new_cases, total_deaths , population 
FROM AAPortfolioProject.CovidDeaths 
ORDER BY 1,2 

-- Looking at Total Cases vs Total Deaths 
-- Shows likelihood of dying if you contract covid in Canada-- 
SELECT location , `date` , total_cases , total_deaths, (total_deaths/total_cases) * 100 as DeathPercetage
FROM AAPortfolioProject.CovidDeaths
WHERE location like '%canada%'
ORDER BY 1,2

-- Looking at Total Cases vs Population -- 
-- Shows Percentage of Population that got Covid -- 
SELECT location , `date` , total_cases , population , (total_cases/population) * 100 as PercentPopulationInfected
FROM AAPortfolioProject.CovidDeaths
WHERE location like '%canada%'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population -- 
SELECT location , population , MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 as PercentPopulationInfected
FROM AAPortfolioProject.CovidDeaths
-- WHERE location like '%canada%'
GROUP BY location , population
ORDER BY PercentPopulationInfected desc 

-- Showing Countries with Highest Death Count per Population -- 

SELECT location,   MAX(total_deaths) as TotalDeathCount 
FROM AAPortfolioProject.CovidDeaths 
-- WHERE location like '%canada%'
WHERE continent !="" AND continent IS NOT NULL
GROUP BY location 
ORDER BY TotalDeathCount desc 

-- LET'S BREAK THINGS DOWN BY CONTINENT 
-- Showing continents with highest death count per population 
SELECT continent ,   MAX(total_deaths) as TotalDeathCount 
FROM AAPortfolioProject.CovidDeaths 
-- WHERE location like '%canada%'
WHERE continent !="" AND continent IS NOT NULL
GROUP BY continent 
ORDER BY TotalDeathCount desc 

-- Correct query!!-- 
/*SELECT location ,   MAX(total_deaths) as TotalDeathCount
FROM AAPortfolioProject.CovidDeaths 
WHERE continent ="" 
GROUP BY location
ORDER BY TotalDeathCount desc */


-- Global Numbers

SELECT `date` , SUM(new_cases) as total_cases , SUM(new_deaths) as total, SUM(new_deaths)/SUM(new_cases) * 100 as DeathPercetage
FROM AAPortfolioProject.CovidDeaths
-- WHERE location like '%canada%'
WHERE continent !="" AND continent IS NOT NULL
GROUP BY `date` 
ORDER BY 1,2

-- Total Cases and Total Deaths with death percentage 
SELECT SUM(new_cases) as total_cases , SUM(new_deaths) as total, SUM(new_deaths)/SUM(new_cases) * 100 as DeathPercetage
FROM AAPortfolioProject.CovidDeaths
-- WHERE location like '%canada%'
WHERE continent !="" AND continent IS NOT NULL
-- GROUP BY `date` 
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations 

SELECT dea.continent, dea.location , dea.`date`, dea.population , vac.new_vaccinations 
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.`date`) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population) * 100 
FROM AAPortfolioProject.coviddeaths dea
JOIN AAPortfolioProject.CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.`date` = vac.`date` 
WHERE dea.continent !="" AND dea.continent IS NOT NULL
ORDER BY 2, 3

-- USE CTE --
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location , dea.`date`, dea.population , vac.new_vaccinations 
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.`date`) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population) * 100 
FROM AAPortfolioProject.coviddeaths dea
JOIN AAPortfolioProject.CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.`date` = vac.`date` 
WHERE dea.continent !="" AND dea.continent IS NOT NULL
ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population) * 100 
FROM PopvsVac 


-- TEMP TABLE

-- DID NOT WORK -- example straight from ALEX 
CREATE TABLE PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population numeric, 
New_vaccinations numeric, 
RollingPeopleVaccinated numeric
)

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location , dea.`date`, dea.population , vac.new_vaccinations 
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.`date`) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population) * 100 
FROM AAPortfolioProject.coviddeaths dea
JOIN AAPortfolioProject.CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.`date` = vac.`date` 
WHERE dea.continent !="" AND dea.continent IS NOT NULL
-- ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/Population) * 100 
FROM PercentPopulationVaccinated

-- CODE THAT WORKS -- 

-- Drop the table if it already exists to avoid conflicts
DROP TABLE IF EXISTS PercentPopulationVaccinated;

-- Create the table
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255), 
    Location VARCHAR(255), 
    Date DATETIME, 
    Population DECIMAL(15, 2), 
    New_vaccinations DECIMAL(15, 2), 
    RollingPeopleVaccinated DECIMAL(15, 2)
);


-- Insert data into the table
INSERT INTO PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    IFNULL(NULLIF(vac.new_vaccinations, ''), 0) AS new_vaccinations, -- Handle empty strings
    SUM(IFNULL(NULLIF(vac.new_vaccinations, ''), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM AAPortfolioProject.coviddeaths dea
JOIN AAPortfolioProject.CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date 
WHERE dea.continent != "" 
AND dea.continent IS NOT NULL;

-- Query the table to calculate the percentage vaccinated
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentVaccinated
FROM PercentPopulationVaccinated;

-- Creating View to Store Data for Later Visualizations 
CREATE VIEW PercentPopulationVaccinatedView as 
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    IFNULL(NULLIF(vac.new_vaccinations, ''), 0) AS new_vaccinations, -- Handle empty strings
    SUM(IFNULL(NULLIF(vac.new_vaccinations, ''), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM AAPortfolioProject.coviddeaths dea
JOIN AAPortfolioProject.CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date 
WHERE dea.continent != "" 
AND dea.continent IS NOT NULL;

SELECT * 
FROM PercentPopulationVaccinatedView

