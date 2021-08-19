-- Select all
SELECT * FROM Covid19..CovidDeaths
ORDER BY 3

SELECT * FROM Covid19..CovidVaccinations
Where location = 'mexico' 
ORDER BY 3

-- New Tests
SELECT location, date, cast(new_tests as int) as NewTests FROM Covid19..CovidVaccinations
ORDER BY 3 desc

-- Cases
Select location, date, total_cases, new_cases, total_deaths, population
From Covid19..CovidDeaths
Order by 1,2

-- Total deaths as a percentage of Total infections (UK), over time --

Select location, date, total_cases, total_deaths, population, (cast((total_deaths/total_cases)*100 as decimal(6,3))) as "Death%"
From Covid19..CovidDeaths
Where location = 'United Kingdom'
Order by 1,2

-- Percentage of population to have been infected (UK) --

Select location, date, total_cases, population, (cast((total_cases/population)*100 as decimal(6,3))) as "Infection%"
From Covid19..CovidDeaths
Where location = 'United Kingdom'
Order by 1,2


-- % of population that have been infected, by location, most to least --
Select location, max(total_cases) as Cases, population, max(cast(((total_cases/population))*100 as decimal(6,3))) as "Infection%"
From Covid19..CovidDeaths
where continent is not null
Group by location, population 
Order by 4 desc

-- % of population that have been infected, by location, most to least - CONTINENTS/WORLD --
Select location, max(cast(total_cases as int)) as Cases, population, max(cast(((total_cases/population))*100 as decimal(6,3))) as "Infection%"
From Covid19..CovidDeaths
where continent is null
Group by location, population 
Order by 4 desc

-- Deaths by location, most to least --
Select location, max(cast(total_deaths as int)) as Deaths
From Covid19..CovidDeaths
where continent is not null
Group by location
Order by Deaths desc

-- Worldwide Cases/Deaths --

Select sum(new_cases) as Cases, sum(cast(new_deaths as int)) as Deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as "Death%"
From Covid19..CovidDeaths
where continent is not null
Order by 1, 2 

-- No. of new vaccinations per day per location--

Select deaths.location, deaths.date, (cast(vax.new_vaccinations as int)) as NewVaccinations
from Covid19..CovidDeaths deaths
Join Covid19..CovidVaccinations Vax
On deaths.location = vax.location
and deaths.date = vax.date
Where deaths.continent is not null
Order by 1,2 



-- No. of vaccinations & tests given etc, % of population to be vaccinated at least once. For each/selected Country --

-- [Anomalies in the data mean that total_vaccination figures or people_fully_vaccinated figures are recorded
-- on a day with no new_vaccination records,
-- hence there may be a slight decrease in PctPopVaccinated in rare instances]

With PopVax (continent, location, date, population, new_tests, IncrementalTests, people_fully_vaccinated, new_vaccinations, IncrementalVaccinations)
as
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_tests,
			sum(cast(vax.new_tests as decimal)) Over (Partition by deaths.location 
			Order by deaths.location, cast(deaths.date as nvarchar(128))) as IncrementalTests,
			vax.people_fully_vaccinated, vax.new_vaccinations,
			sum(cast(vax.new_vaccinations as decimal)) Over (Partition by deaths.location 
			Order by deaths.location, cast(deaths.date as nvarchar(128))) as IncrementalVaccinations
			
			From Covid19..CovidDeaths deaths 
			Join Covid19..CovidVaccinations vax
			on deaths.location = vax.location
			and deaths.date = vax.date
			Where deaths.continent is not null
			)
Select location, population, date, IncrementalTests, (cast((IncrementalTests/population)*100 as decimal (6,3))) as TestsPer100People,
			IncrementalVaccinations, new_vaccinations, people_fully_vaccinated,
-- isnull(people_fully_vaccinated,'No Data') as PeopleFullyVaccinated,
-- ^ Ideally use previous value instead of null
			(cast(((IncrementalVaccinations-people_fully_vaccinated)/population)*100 as decimal (6,3))) as PctPopVaccinated
			
from PopVax 
			Where location = 'United Kingdom'



-- [[Creating Views]] --

-- Total deaths as a percentage of Total infections (UK), over time --
Create View PctTotalDeathsUK as
Select location, date, total_cases, total_deaths, population, (cast((total_deaths/total_cases)*100 as decimal(6,3))) as "Death%"
From Covid19..CovidDeaths
Where location = 'United Kingdom'

-- Percentage of population to have been infected (UK) --
Create View PctPopInfectedUK as
Select location, date, total_cases, population, (cast((total_cases/population)*100 as decimal(6,3))) as "Infection%"
From Covid19..CovidDeaths
Where location = 'United Kingdom'

-- % of population that have been infected, by location, most to least - CONTINENTS/WORLD --
Create View ContinentsInfections as
Select location, max(cast(total_cases as int)) as Cases, population, max(cast(((total_cases/population))*100 as decimal(6,3))) as "Infection%"
From Covid19..CovidDeaths
where continent is null
Group by location, population 

-- Deaths by location --
Create View CountryDeaths as
Select location, max(cast(total_deaths as int)) as Deaths
From Covid19..CovidDeaths
where continent is not null
Group by location

-- Daily new vaccines --
Create View DailyVaccinesByCountry as
Select deaths.location, deaths.date, (cast(vax.new_vaccinations as int)) as NewVaccinations
from Covid19..CovidDeaths deaths
Join Covid19..CovidVaccinations Vax
On deaths.location = vax.location
and deaths.date = vax.date
Where deaths.continent is not null

-- Tests and Vaccines, totals by country --
Create View TestVax as
Select deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_tests,
			sum(cast(vax.new_tests as decimal)) Over (Partition by deaths.location 
			Order by deaths.location, cast(deaths.date as nvarchar(128))) as IncrementalTests,
			vax.people_fully_vaccinated, vax.new_vaccinations,
			sum(cast(vax.new_vaccinations as decimal)) Over (Partition by deaths.location 
			Order by deaths.location, cast(deaths.date as nvarchar(128))) as IncrementalVaccinations
			
			From Covid19..CovidDeaths deaths 
			Join Covid19..CovidVaccinations vax
			on deaths.location = vax.location
			and deaths.date = vax.date
			Where deaths.continent is not null
			