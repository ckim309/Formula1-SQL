-- cleaning data frame
update F1..races$
set name = 'Sao Paulo Grand Prix'
where name = 'São Paulo Grand Prix';

-- fixing pit stop time for 2021 season
UPDATE F1..pit_stops$
SET duration = 
	REPLACE(
		REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(
										REPLACE(
											REPLACE(duration, '0.0187658', '27.01361'),
										'0.0173001', '24.54731'),
									'0.000762384', '65.870'),
								'0.0231588', '33.20923'),
							'0.0237081', '34.08376'),
						'0.0167738', '24.09259'),
					'0.0168559', '24.16349'),
				'0.0115321', '16.36375'),
			'0.0115261', '16.35856'),
		'0.0125879', '18.07591'),
	'0.0125772', '18.06674')
FROM F1..pit_stops$;


-- HOW DID MAX VERSTAPPEN BEAT LEWIS HAMILTON, A 7 TIME WORLD CHAMPION, IN 2021 --

-- Lewis Hamilton and Max Verstappen driver info
SELECT *
FROM F1..drivers$
WHERE forename = 'Lewis' AND surname = 'Hamilton' 
OR forename = 'Max' AND surname = 'Verstappen';

-- 2021 season race by race points comparison
-- temp table --
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

-- HAM/VER 2021: season race by race points comparison
SELECT date, name, code, DriverStanding, points, 
	sum(points) over(partition by code order by date) as CumalitivePts
FROM HamVer 
order by date, code;

-- Season 2021: win percentage
select TOP 6 dri.code,
	SUM(CASE WHEN res.position = 1 THEN 1 ELSE 0 END) AS TotalWins,
	(CAST(ROUND(100.0 * SUM(CASE WHEN res.position = 1 THEN 1 ELSE 0 END)/
		COUNT(CASE WHEN res.position = 1 THEN 1 ELSE 0 END), 2) AS float)) AS WinPercentage
FROM F1..results$ res LEFT JOIN F1..races$ rac 
		ON res.raceId = rac.raceId
	LEFT JOIN F1..drivers$ dri 
		ON dri.driverId = res.driverId
	LEFT JOIN F1..status$ sta 
		ON sta.statusId = res.statusId
WHERE rac.year = 2021
GROUP BY dri.code
HAVING sum(res.position) > 0
ORDER BY TotalWins DESC;

-- HAM/VER 2021: temp table starting positions, finishing positions, fastest lap time
select dri.code, 
	CAST (rac.date as date) AS date, 
	rac.name, res.grid, res.position,
	FORMAT(res.fastestLapTime, 'mm:ss') AS FastestLapTime,  
	fastestLapSpeed AS TopSpeed,
	sta.status
INTO HamVer2
FROM F1..results$ res LEFT JOIN F1..races$ rac 
		ON res.raceId = rac.raceId
	LEFT JOIN F1..drivers$ dri 
		ON dri.driverId = res.driverId
	LEFT JOIN F1..status$ sta 
		ON sta.statusId = res.statusId
where (dri.code = 'HAM' or dri.code = 'VER')
AND year = 2021
ORDER BY rac.date, dri.code;

-- HAM/VER 2021: pit stops
SELECT cast(rac.date as date) AS date, 
	rac.name, dri.code,
	COUNT(pit.stop) as TotalPitStops,
	AVG(pit.duration) as AvgPitTime
FROM F1..pit_stops$ pit LEFT JOIN F1..results$ res
		ON pit.driverId = res.driverId
			AND pit.raceId = res.driverId
	LEFT JOIN F1..races$ rac
		ON rac.raceId = pit.raceId
	LEFT JOIN F1..drivers$ dri
		ON dri.driverId = pit.driverId
WHERE pit.raceId between 1051 and 1073
	AND (pit.driverId = 1 or pit.driverId = 830)
GROUP BY rac.date, rac.name, dri.code
ORDER BY rac.date,dri.code;



-- COMPARING LEWIS HAMILTON TO VALTTERI BOTTAS WHEN THEY WERE TEAMMATES AT MERCEDES --

-- data cleaning
UPDATE HamVer2
SET FastestLapTime = REPLACE(FastestLapTime, '46:34','01:21')
WHERE name = 'Hungarian Grand Prix';

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
WHERE dri.code = 'HAM' or dri.code = 'BOT' 
	AND con.name like 'Merc%'
GROUP BY dri.code, res.driverId; -- HAM AND BOT were at Mercedes together from raceId 969

-- temporary table for BOT and HAM when racing for Mercedes
SELECT race.year, race.name, dri.code, res.grid, res.positionOrder AS DriverStanding, res.points, 
cast(res.fastestLapTime as time (2)) AS FastestLapTime
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
SUM(CASE WHEN DriverStanding = 1 THEN 1 ELSE 0 END) AS NumOfFirstPlace,
CONCAT(CAST(ROUND(100.0 * SUM(CASE WHEN DriverStanding <= 3 THEN 1 ELSE 0 END)/COUNT(DriverStanding), 2) AS float), '%') AS 'Podium%',
CONCAT(CAST(ROUND(100.0 * SUM(CASE WHEN DriverStanding = 1 THEN 1 ELSE 0 END)/COUNT(DriverStanding), 2) AS float), '%') AS 'P1%'
FROM BotHam
GROUP BY code;
