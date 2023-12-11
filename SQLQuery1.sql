 
-----------------------------------------

-- Selecting data from CovidDeaths where continent is not null and ordering by columns 3 and 4
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

-- Selecting specific columns from CovidDeaths where continent is not null and ordering by columns 1 and 2
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Calculating DeathPercentage for locations with 'states' in the name
SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    CASE
        WHEN TRY_CAST(total_cases AS FLOAT) IS NULL OR TRY_CAST(total_deaths AS FLOAT) IS NULL OR TRY_CAST(total_cases AS FLOAT) = 0 THEN NULL
        ELSE (TRY_CAST(total_deaths AS FLOAT) / TRY_CAST(total_cases AS FLOAT)) * 100
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND Location LIKE '%states%'
ORDER BY Location, date;

-- Calculating PercentPopulaationInfected for locations with 'states' in the name
SELECT
    Location,
    date,
    total_cases,
    population,
    CASE
        WHEN TRY_CAST(population AS FLOAT) IS NULL OR TRY_CAST(total_cases AS FLOAT) IS NULL OR TRY_CAST(population AS FLOAT) = 0 THEN NULL
        ELSE (TRY_CAST(total_cases AS FLOAT) / TRY_CAST(population AS FLOAT)) * 100
    END AS PercentPopulaationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND Location LIKE '%states%'
ORDER BY Location, date;

-- Finding countries with the highest infection rate compared to their population
SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((Total_cases / Population)) * 100 AS PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentagePopulationInfected DESC;

-- Finding countries with the highest death count according to population
SELECT Location, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Finding total death count by continent
SELECT continent, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global numbers: total_cases, total_deaths, and DeathPercentage
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

-- Calculating RollingPeopleVaccinated and PercentPopulationVaccinated
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated) AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        ISNULL(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date), 0) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)

-- Final query using the CTE to calculate RpvPercentage
SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS RpvPercentage
FROM PopvsVac;

-- Creating a temporary table for PercentPopulationVaccinated
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Populating the temporary table with data
INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    ISNULL(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date), 0) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Querying the temporary table with RpvPercentage
SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS RpvPercentage
FROM #PercentPopulationVaccinated;

-- Drop the existing view
DROP VIEW IF EXISTS PercentPopulationVaccinated;

-- Create the view in a new batch
GO


-- Creating a view for later data visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    ISNULL(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date), 0) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated






