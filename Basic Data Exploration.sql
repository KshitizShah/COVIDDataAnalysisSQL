-- Checking if data has been correctly imported

SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- selecting data that I will be using:
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- looking at total cases v/s total deaths
-- Likelihood of dying if you contracted COVID in India overall
SELECT Location , date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS 'DeathPercentage'
FROM PortfolioProject..CovidDeaths
WHERE location like 'india' 
ORDER BY 1,2 DESC

--Total Cases V/S Population
-- Shows percentage of population that has gotten COVID-19 
SELECT Location , date, total_cases,population, (total_cases/population)*100 AS 'InfectionRate'
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2 DESC

-- Highest infection rates: all countries
SELECT Location , population , MAX(total_cases) as 'Highest Infection Count per Country',population, MAX((total_cases/population))*100 AS 'InfectionRate'
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY 5 DESC

-- Highest death rates: all countries
SELECT Location , MAX(CAST(total_deaths as INT)) as 'DeathToll', MAX((Cast(total_deaths as int)/population))*100 AS 'Death Percentage'
FROM PortfolioProject..CovidDeaths
WHERE continent is not null and total_deaths is not null
GROUP BY Location
ORDER BY DeathToll DESC

-- Break things down by continent
SELECT location , MAX(CAST(total_deaths as INT)) as 'DeathToll', MAX((Cast(total_deaths as int)/population))*100 AS 'Death Percentage'
FROM PortfolioProject..CovidDeaths
WHERE continent is null and total_deaths is not null
GROUP BY location
ORDER BY DeathToll DESC

-- Not correct; picking the country with the highest  cases in any continent

SELECT continent , MAX(CAST(total_deaths as INT)) as 'DeathToll', MAX((Cast(total_deaths as int)/population))*100 AS 'Death Percentage'
FROM PortfolioProject..CovidDeaths
WHERE continent is not null and total_deaths is not null
GROUP BY continent
ORDER BY DeathToll DESC

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) TOTALCASES, SUM(CAST(new_deaths as INT)) TOTALDEATHS, (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 AS 'DeathPercentage'
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%' 
WHERE Continent is not null
GROUP BY date
ORDER BY DeathPercentage DESC

SELECT SUM(new_cases) TOTALCASES, SUM(CAST(new_deaths as INT)) TOTALDEATHS, (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 AS 'DeathPercentage'
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%' 
WHERE Continent is not null
ORDER BY DeathPercentage DESC

-- COVID VACCINATIONS

SELECT * 
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
	ON DEA.location=VAC.location
	AND DEA.date = VAC.date


	-- TOTAL POPULATION V/S Vaccination

	SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations AS NEWVACCINATION,
	SUM(cast(VAC.new_vaccinations as BIGINT)) OVER (PARTITION BY  DEA.location)
	FROM PortfolioProject..CovidDeaths DEA
	JOIN PortfolioProject..CovidVaccinations VAC
		ON DEA.location=VAC.location
		AND DEA.date = VAC.date
		WHERE DEA.continent is not null
	ORDER BY 2,3,5 DESC 

	-- same as above using convert function
	SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(CONVERT(bigint,VAC.new_vaccinations)) OVER (PARTITION BY  DEA.location ORDER BY DEA.location, DEA.date) as CUMULATIVEPEOPLEVACCINATED
	FROM PortfolioProject..CovidDeaths DEA
	JOIN PortfolioProject..CovidVaccinations VAC
		ON DEA.location=VAC.location
		AND DEA.date = VAC.date
		WHERE DEA.continent is not null
	ORDER BY 2,3

	--USING CTE -
	WITH PopVSVAC(Continent, Location, Date, Population,New_Vaccinations, CumulativePeopleVaccinated)
	as 
	(
	SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(CONVERT(bigint,VAC.new_vaccinations)) OVER (PARTITION BY  DEA.location ORDER BY DEA.location, DEA.date) as CUMULATIVEPEOPLEVACCINATED
	FROM PortfolioProject..CovidDeaths DEA
	JOIN PortfolioProject..CovidVaccinations VAC
		ON DEA.location=VAC.location
		AND DEA.date = VAC.date
		WHERE DEA.continent is not null
	)
	SELECT *, (CumulativePeopleVaccinated/Population)* 100 AS percentage
	FROM PopVSVAC


	-- Using TEMPTABLE
	DROP TABLE IF EXISTS #Popvaccinated
	CREATE TABLE #Popvaccinated
	(
	 Continent nVarchar(255), Location nVarchar(255), Date datetime, Population numeric,New_Vaccinations numeric, CumulativePeopleVaccinated numeric
	)
	INSERT INTO #Popvaccinated
	SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(CONVERT(bigint,VAC.new_vaccinations)) OVER (PARTITION BY  DEA.location ORDER BY DEA.location, DEA.date) as CUMULATIVEPEOPLEVACCINATED
	FROM PortfolioProject..CovidDeaths DEA
	JOIN PortfolioProject..CovidVaccinations VAC
		ON DEA.location=VAC.location
		AND DEA.date = VAC.date
		WHERE DEA.continent is not null
	
	
	SELECT *, (CumulativePeopleVaccinated/Population)* 100 AS percentage
	FROM #Popvaccinated

	-- Creating view to store data for later visualizations
	
	CREATE VIEW PercentPopulationVaccinated AS 
	SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(CONVERT(bigint,VAC.new_vaccinations)) OVER (PARTITION BY  DEA.location ORDER BY DEA.location, DEA.date) as CUMULATIVEPEOPLEVACCINATED
	FROM PortfolioProject..CovidDeaths DEA
	JOIN PortfolioProject..CovidVaccinations VAC
		ON DEA.location=VAC.location
		AND DEA.date = VAC.date
		WHERE DEA.continent is not null
	
	Select *
	FROM PercentPopulationVaccinated