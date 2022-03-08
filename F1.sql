-- drivers that did not finish a race in 2021
SELECT rac.raceId, dri.surname, rac.name, sta.status
FROM F1..results$ res LEFT JOIN F1..races$ rac ON res.raceId = rac.raceId
LEFT JOIN F1..drivers$ dri ON dri.driverId = res.driverId
LEFT JOIN F1..status$ sta ON sta.statusId = res.statusId
WHERE year = 2021 and position IS NULL
ORDER BY rac.raceId;

-- finding the fastest lap time per track from 2011 to 2021
SELECT rac.year, rac.name, 
	CAST(MIN(fastestLapTime) AS time(2)) AS FastestLapTime
FROM F1..results$ res LEFT JOIN F1..races$ rac ON res.raceId = rac.raceId
LEFT JOIN F1..drivers$ dri ON dri.driverId = res.driverId
WHERE rac.year BETWEEN 2011 AND 2021
GROUP BY rac.year, rac.name
ORDER BY rac.year, rac.name;

-- number of wins per driver throughout F1 history
SELECT dri.forename + ' ' + dri.surname as DriverName, 
	SUM(res.position) AS TotalWins
FROM F1..results$ res LEFT JOIN F1..races$ rac ON res.raceId = rac.raceId
LEFT JOIN F1..drivers$ dri ON dri.driverId = res.driverId
WHERE res.position = 1
GROUP BY dri.forename + ' ' + dri.surname
ORDER BY sum(res.position) DESC;



-- COMPARING LEWIS HAMILTON TO VALTTERI BOTTAS WHEN THEY WERE TEAMMATES AT MERCEDES

-- finding Lewis Hamilton and Valtteri Bottas
SELECT *
FROM F1..drivers$
WHERE forename = 'Lewis' AND surname = 'Hamilton' 
OR forename = 'Valtteri' AND surname = 'Bottas';

-- finding when HAM and BOT were at Mercedes together
SELECT dri.code, min(res.raceId) AS FirstMercRace, 
	MAX(res.raceId) AS LastMercRace
FROM F1..results$ res LEFT JOIN F1..constructors$ con 
		ON res.constructorId = con.constructorId
	LEFT JOIN F1..drivers$ dri 
		ON res.driverId = dri.driverId
WHERE dri.code = 'HAM' or dri.code = 'BOT' AND con.name like 'Merc%'
GROUP BY dri.code, res.driverId; -- HAM AND BOT were at Mercedes together from raceId 969

-- temporary table for BOT and HAM when racing for Mercedes
SELECT race.year, race.name, dri.code, res.grid, res.positionOrder AS DriverStanding, res.points, 
cast(res.fastestLapTime as time (2)) as FastestLapTime
INTO BotHam
FROM F1..constructors$ con JOIN F1..results$ res 
		ON (con.constructorId = res.constructorId)
	LEFT JOIN F1..drivers$ dri 
		ON (dri.driverId = res.driverId)
	LEFT JOIN F1..races$ race
		ON (race.raceId = res.raceId)
WHERE res.raceId >= 969
	AND dri.code = 'HAM' or dri.code = 'BOT' 
	AND con.name like 'Merc%';

-- BOT/HAM: temp table
select *
from BotHam;

-- BOT/HAM: 2017-2021 season comparison
SELECT year, code, 
max(DriverStanding) AS WorstRaceFinish,
min(points) AS LeastPtsScored,
min(DriverStanding) AS BestRaceFinish,
max(points) AS MostPtsScored,
round(avg(points), 2) AS AvgPointsPerRace,
sum(points) as TotaPoints
FROM BotHam
GROUP BY code, year;

-- BOT/HAM career: average points per race, podium (top 3) finishes, P1 (first place) finishes
SELECT code,
COUNT(year) as NumOfRaces,
ROUND(AVG(points), 2) AS AvgPointsPerRace,
SUM(CASE WHEN DriverStanding <= 3 THEN 1 ELSE 0 END) AS NumOfPodiums,
CONCAT(CAST(ROUND(100.0 * SUM(CASE WHEN DriverStanding <= 3 THEN 1 ELSE 0 END)/COUNT(DriverStanding), 2) AS float), '%') AS 'Podium%',
CONCAT(CAST(ROUND(100.0 * SUM(CASE WHEN DriverStanding = 1 THEN 1 ELSE 0 END)/COUNT(DriverStanding), 2) AS float), '%') AS 'P1%'
FROM BotHam
GROUP BY code;


-- LEWIS HAMILTON VS MAX VERSTAPPEN IN 2021 --

-- Lewis Hamilton and Max Verstappen driver info
SELECT *
FROM F1..drivers$
WHERE forename = 'Lewis' AND surname = 'Hamilton' 
OR forename = 'Max' AND surname = 'Verstappen';

-- 2021 season race by race points comparison
-- creating temp table --
SELECT cast(rac.date AS date) AS date, 
	rac.name, dri.code, res.positionText AS DriverStanding, res.points
	INTO HamVer
FROM F1..constructors$ con JOIN F1..results$ res 
		ON (con.constructorId = res.constructorId)
	JOIN F1..drivers$ dri 
		ON (dri.driverId = res.driverId)
	JOIN F1..races$ rac
		ON (rac.raceId = res.raceId)
WHERE (dri.code = 'HAM' or dri.code = 'VER')
		AND rac.year >= 2021
GROUP BY rac.date, rac.name, dri.code, res.points, res.positionText;

-- HAM/VER: 2021 season race by race points comparison
SELECT date, name, code, DriverStanding, points, 
	sum(points) over(partition by code order by date) as CumalitivePts
FROM HamVer 
order by date, code;
