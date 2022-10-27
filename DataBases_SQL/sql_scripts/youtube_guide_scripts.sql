-- If dvdrental doesn't appear do the following
-- On the connection, right-click -> Edit connection -> Connection settings -> 
-- on the tabbed panel, select PostgreSQL, check the box Show all databases.

-- Tutorial from https://www.youtube.com/watch?v=qfyynHBFOsM&t=1079s

--------

select * from coviddeaths c  limit 100;
select * from covidvaccinations c2   limit 100;

--------- The Order by Argment based on Index
select * from coviddeaths 
order by 3, 4;

-------- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by 1,2

-------- -- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
order by 1,2

-- Let's Fiter Location with Like 
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
where "location" like '%Rus%'
order by 1,2


---------- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
order by 1,2

-- and for Russia
Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
Where location like '%Rus%'
order by 1,2


--------------------- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  
Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc;

--- Same for Russia
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  
Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Where location like '%Rus%'
Group by Location, Population
order by PercentPopulationInfected desc


-------------------- Countries with Highest Death Count per Population 
-- Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
Select Location, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths
Where continent is not null 
-- try turning off and on Where continent is not null  and see what happens with continents
Group by Location
order by TotalDeathCount desc

--CHECK COLUMN DATA TYPE --------------------------
SELECT
    column_name,
    data_type,
    character_maximum_length AS max_length,
    character_octet_length AS octet_length
FROM
    information_schema.columns
WHERE
    table_schema = 'public' AND 
    table_name = 'coviddeaths' AND
    column_name = 'total_deaths';


--- Russia
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where location like '%Rus%'
Group by Location


------------------------------------ BREAKING THINGS DOWN BY CONTINENT--------------------------------

-- Showing contintents with the highest death count per population

--Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
Select continent, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc


------------------ GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, 
SUM(new_deaths) as total_deaths,
SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
-- where continent is not null 
order by 1,2

-------------------------- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations)
OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
-- order by 2,3
order by 5 desc

-------------------------------WINDOW FUNCTIONS/ PARTITION BY and OVER -----------------------------------------
-- https://www.postgresql.org/docs/current/tutorial-window.html#:~:text=The%20PARTITION%20BY%20clause%20within,partition%20as%20the%20current%20row.

-- A WINDOW function performs a calculation across a set of table rows that are somehow related to the current row. 
-- This is comparable to the type of calculation that can be done with an aggregate function. However,
--  window functions do not cause rows to become grouped into a single output row 
-- like non-window aggregate calls would. Instead, the rows retain their separate identities

-- A window function call always contains an OVER clause directly following the window function's name 
-- and argument(s). 
-- This is what syntactically distinguishes it from a normal function or non-window aggregate. 
-- The OVER clause determines exactly how the rows of the query are split up for processing by the 
-- window function. The PARTITION BY clause within OVER divides the rows into groups, or partitions, 
-- that share the same values of the PARTITION BY expression(s). For each row, the window function is 
-- computed across the rows that fall into the same partition as the current row.

select * from coviddeaths c limit 100;

select continent, location, life_expectancy, date, new_cases, avg(new_cases)  
over (partition by location) 
from coviddeaths ; 

-- And for our country
select continent, location, life_expectancy, date,  new_cases, avg(new_cases)  
over (partition by location) 
from coviddeaths 
where location like '%Rus%'; 


---To compare AGAINTS normal agg function Below Query will result Position Error
select continent, location, life_expectancy, new_cases, avg(total_cases) 
from coviddeaths ; 

----------- RANK in partition--------
-- As shown here, the rank function produces a numerical rank for each distinct ORDER BY value 
-- in the current row's partition, using the order defined by the ORDER BY clause. 
-- rank needs no explicit parameter, because its behavior is entirely determined by the OVER clause.

-- CHECK BELOW 30 and 30 for Afghnanistan, Same rank twice
-- Because new_cases are same
select continent, location, life_expectancy, date, new_cases, 
   rank () over (partition by location order by new_cases desc) 
from coviddeaths ; 


-- Russia
select continent, location, life_expectancy, date, new_cases, 
   rank () over (partition by location order by new_cases desc) 
from coviddeaths 
where location like '%Rus%';

----
select location, date, new_cases, sum(new_cases) over (order by new_cases desc) 
from coviddeaths 
where new_cases is not null and location !='World';


--------------------- CHECK COLUMN DATA TYPE --------------------------
SELECT
    column_name,
    data_type,
    character_maximum_length AS max_length,
    character_octet_length AS octet_length
FROM
    information_schema.columns
WHERE
    table_schema = 'public' AND 
    table_name = 'covidvaccinations' AND
    column_name = 'new_vaccinations';

   
   
------------------------------- SELECT Results vs Tables/ Saving Selection as a New_Table  
------- Adding a new column
------- ALTER TABLE
------- CHanging column datatype
------- Checking Cast
   
create table covidvaccinations_temp as (
    select * , new_vaccinations as new_vaccinations_var FROM covidvaccinations
  )

select new_vaccinations_var from covidvaccinations_temp limit 10;

-- change datatype for new_vaccinations
-------------------- ALTER TABLE  
   
ALTER TABLE covidvaccinations_temp ALTER COLUMN new_vaccinations_var TYPE VARCHAR;
-- ALTER TABLE CovidVaccinations ALTER COLUMN new_vaccinations TYPE integer USING new_vaccinations::integer;


---CHECK COLUMN DATA TYPE / You can do it also in the Tree left panel 
SELECT
    column_name,
    data_type,
    character_maximum_length AS max_length,
    character_octet_length AS octet_length
FROM
    information_schema.columns
WHERE
    table_schema = 'public' AND 
    table_name = 'covidvaccinations_temp' AND
    column_name = 'new_vaccinations_var';
   
   
----------TRYING AGG FUNC On VARCHAR//// Total Population vs Vaccinations
--------- SQL ERROR - You might need to add Explicit type casts
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations_var,
SUM (CAST(cast(new_vaccinations_var as float) as numeric))
-- SUM(CONVERT(int,vac.new_vaccinations))
OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations_temp vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
-- order by 2,3
order by 5 desc;

--- WHY VARCHAR IS CAUSING PROBLEMS - EXPLANATION
--- NOTE SCIENTOFIC Notation below
SELECT CAST(nullif(new_vaccinations_var, '0') AS integer) from covidvaccinations_temp ;

--working versions
select CAST(cast('3.160926e+06' as float) as numeric)
select CAST(cast(new_vaccinations_var as float) as numeric) from covidvaccinations_temp




   

----------------------------------- BACK TO QUERIES FROM TUT --------------------------------------
-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

---- Compare this and below, 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) 
OVER (Partition by dea.Location Order by dea.location) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.location like '%Alb%'
order by 2,3

-- adding dea.Date in partition by 
-- Now, it adds up new_vaccinatins in rollingpeople, just scroll down and see
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) 
OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.location like '%Alb%'
order by 2,3



------------------ Using CTE to perform Calculation on Partition By in previous query -----------------------

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations != 0 
)
Select *, (RollingPeopleVaccinated/Population)*100 as Prop
From PopvsVac

----------------------------



   
 




