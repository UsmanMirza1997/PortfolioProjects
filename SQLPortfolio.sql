--SELECT *
--FROM PortfolioProject..CovidDeaths$
--ORDER BY 3, 4

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3, 4

--SELECT location, date, total_cases, new_cases, total_deaths, Population
--FROM PortfolioProject..CovidDeaths$
--ORDER BY 1,2

--Looking at Total Cases v.s Total Deaths
--Show likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location like '%Pak%' AND
continent is NOT NULL
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of popuation got Covid

SELECT location, date, total_cases, Population, (total_cases/Population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE location like '%Pak%' AND
continent is NOT NULL
ORDER BY 1,2

--Looking at Countries with highest Infection Rate compared to Population

SELECT location, MAX(total_cases) AS HighestInfectionCount, Population, MAX((total_cases/Population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%Pak%'
Where continent is NOT NULL
GROUP BY location, Population
ORDER BY PercentPopulationInfected desc

--Showing Countries with Highest Death Count per Population

SELECT location, MAX(cast(Total_Deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%Pak%'
Where continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc

--Showing continents with the highest death count per population

SELECT Continent, MAX(cast(Total_Deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%Pak%'
Where continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

--GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, SUM(cast(New_deaths as int))/SUM(New_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%Pak%'
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, SUM(cast(New_deaths as int))/SUM(New_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%Pak%'
WHERE continent is NOT NULL
--GROUP BY date
ORDER BY 1,2

--Looking at Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS 
 RollingPeopleVaccinated, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE Dea.continent is NOT NULL
ORDER BY 2,3

--Use CTE

WITH PopvsVac(Continent, location, date, Population,New_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS 
 RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE Dea.continent is NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
