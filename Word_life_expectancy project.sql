-- World Life Expectancy Project (Data Cleaning)
SELECT * FROM worldlifeexpectancy;

-- Identifying duplicates
SELECT *
FROM
(
SELECT Row_ID, CONCAT(Country, Year), 
ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_num
FROM worldlifeexpectancy) new_tab
WHERE Row_num > 1
;

-- Deleting the duplicates

DELETE FROM worldlifeexpectancy
WHERE Row_ID IN
(
SELECT Row_ID
FROM (SELECT Row_ID, CONCAT(Country, Year), 
ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_num
FROM worldlifeexpectancy) new_tab
WHERE Row_num > 1 )
;


-- There are only two statuses, developed and developing
-- Using self join to fill status column where it is blank

UPDATE worldlifeexpectancy t1
JOIN worldlifeexpectancy t2
	ON t1.country = t2. country
SET t1.status = 'Developing'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developing'
;

UPDATE worldlifeexpectancy t1
JOIN worldlifeexpectancy t2
	ON t1.country = t2. country
SET t1.status = 'Developed'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developed'
;

-- Using self join to fill Life Expectancy column where it is blank with average life expectancy in the year before and after

UPDATE worldlifeexpectancy t1
JOIN worldlifeexpectancy t2
	ON t1.Country = t2.Country 
    AND t1.Year = t2.Year - 1
JOIN worldlifeexpectancy t3
	ON t1.Country = t3.Country 
    AND t1.Year = t3.Year + 1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2, 1)
WHERE  t1.`Life expectancy` = ''
;

-- Some data issues. The adult mortality are probably not well reported
SELECT Country, Year, `Adult Mortality`
FROM worldlifeexpectancy
WHERE `Adult Mortality` LIKE '_'
;

-- EXPLORATORY DATA ANALYSIS

-- Average life expectancy in the past 16 years by Country

SELECT DISTINCT(Country), ROUND(AVG(`Life expectancy`) OVER(PARTITION BY Country ORDER BY  Country), 1) AS Average_Life_Expectancy
FROM worldlifeexpectancy
WHERE `Life expectancy` <> 0
ORDER BY Average_Life_Expectancy DESC;

-- Comparing the years and the average life expectancy in those years

SELECT Year, 
ROUND(AVG(`Life expectancy`), 2) AS Average_Life_Expectancy_Over_the_Years
FROM worldlifeexpectancy
WHERE `Life expectancy` <> 0
GROUP BY Year 
ORDER BY Year ASC;

-- Minimum and Maximum life expectancy

SELECT Country, 
MIN(`Life expectancy`) AS Minimum_Life_expectancy, 
MAX(`Life expectancy`) AS Maximum_Life_expectancy,
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`), 1) AS Life_increase_16_years
FROM worldlifeexpectancy
GROUP BY Country
HAVING Minimum_Life_expectancy <> 0 
AND Maximum_Life_expectancy <> 0
ORDER BY Life_increase_16_years DESC
;

SELECT 
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS High_GDP_Count,
AVG(CASE WHEN GDP >= 1500 THEN `Life Expectancy` ELSE NULL END) AS High_GDP_Life_Expectancy,
SUM(CASE WHEN GDP < 1500 THEN 1 ELSE 0 END) AS Low_GDP_Count,
AVG(CASE WHEN GDP < 1500 THEN `Life Expectancy` ELSE NULL END) AS Low_GDP_Life_Expectancy
FROM worldlifeexpectancy;

/*  How many developed and developing countries do we have? and the average life expectancy between 
the developed and developing countries (About 13 years difference) */

SELECT Status, 
COUNT(DISTINCT Country) AS Count_of_status, 
ROUND(AVG(`Life Expectancy`),1) AS Average_Life_exp_status
FROM worldlifeexpectancy
GROUP BY Status
;


-- BMI in the developed countries

SELECT Country, 
ROUND(AVG(BMI),1) AS BMIS
FROM worldlifeexpectancy
WHERE BMI <> 0
AND Status = 'Developed'
GROUP BY Country
ORDER BY BMIS DESC
;

-- Underweight (No developed country is underweight)

SELECT Country, 
ROUND(AVG(BMI),1) AS Average_bmi
FROM worldlifeexpectancy
WHERE BMI <> 0
AND Status = 'Developed'
GROUP BY Country
HAVING Average_bmi < 18.5 
ORDER BY Average_bmi DESC
;

-- No developed country have a normal average weight
SELECT Country, 
ROUND(AVG(BMI),1) AS Average_bmi
FROM worldlifeexpectancy
WHERE BMI <> 0
AND Status = 'Developed'
GROUP BY Country
HAVING Average_bmi BETWEEN 18.5 AND 24.9
ORDER BY Average_bmi DESC
;

-- Two developed countries are overweight
SELECT Country, 
ROUND(AVG(BMI),1) AS Average_bmi
FROM worldlifeexpectancy
WHERE BMI <> 0
AND Status = 'Developed'
GROUP BY Country
HAVING Average_bmi BETWEEN 25.0 AND 29.9
ORDER BY Average_bmi DESC
;

-- 30 developed countries have an average bmi that classifies them as obese > 30 kg/m**2
SELECT Country, 
ROUND(AVG(BMI),1) AS Average_bmi
FROM worldlifeexpectancy
WHERE BMI <> 0
AND Status = 'Developed'
GROUP BY Country
HAVING Average_bmi > 30
ORDER BY Average_bmi DESC
;
-- BMI in developing countries

SELECT Country, 
ROUND(AVG(BMI),1) AS BMI
FROM worldlifeexpectancy
WHERE BMI <> 0
AND Status = 'Developing'
GROUP BY Country
ORDER BY BMI 
;

-- Underweight (37 developing countries have bmi classified as underweight)

SELECT Country, 
ROUND(AVG(BMI),1) AS Average_bmi
FROM worldlifeexpectancy
WHERE BMI <> 0
AND Status = 'Developing'
GROUP BY Country
HAVING Average_bmi < 18.5 
ORDER BY Average_bmi DESC
;

-- 19 developing countries have a normal weight
SELECT Country, 
ROUND(AVG(BMI),1) AS Average_bmi
FROM worldlifeexpectancy
WHERE BMI <> 0
AND Status = 'Developing'
GROUP BY Country
HAVING Average_bmi BETWEEN 18.5 AND 24.9
ORDER BY Average_bmi DESC
;

-- 90 developing countries have an average bmi that classifies them as obese > 30 kg/m**2
SELECT Country, 
ROUND(AVG(BMI),1) AS Average_bmi
FROM worldlifeexpectancy
WHERE BMI <> 0
AND Status = 'Developing'
GROUP BY Country
HAVING Average_bmi > 30
ORDER BY Average_bmi DESC
;

-- High GDP countries  goes to school more than low GDP

SELECT 
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS High_GDP_Count,
ROUND(AVG(CASE WHEN GDP >= 1500 THEN Schooling ELSE NULL END),1) AS High_GDP_Schooling,
SUM(CASE WHEN GDP < 1500 THEN 1 ELSE 0 END) AS Low_GDP_Count,
ROUND(AVG(CASE WHEN GDP < 1500 THEN Schooling ELSE NULL END),1) AS High_GDP_Schooling
FROM worldlifeexpectancy;

-- Identifying the GDP status of the country whether high or low
SELECT Country, GDP_status
FROM
(SELECT Country,
CASE
WHEN GDP > 1500 THEN 'High_GDP'
ELSE 'Low_GDP'
END AS GDP_status
FROM worldlifeexpectancy
) GDP_table
;

-- Rolling total of the Adult mortality

SELECT 
Country, 
Year, 
`Adult mortality`, 
SUM(`Adult mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total_Adult_Mortality
FROM worldlifeexpectancy
WHERE `Adult mortality` NOT LIKE '_'  -- This is excluding the adult mortality that are incompletely reported.
;

-- Total number of deaths in the last 16 years by country
SELECT Country, 
MAX(Rolling_Total_Adult_Mortality) AS Number_of_deaths
FROM (
SELECT 
Country, 
Year, 
`Adult mortality`, 
SUM(`Adult mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total_Adult_Mortality
FROM worldlifeexpectancy
WHERE `Adult mortality` NOT LIKE '_'
) AS Running_total_table
GROUP BY Country
ORDER BY Number_of_deaths DESC
;

-- It will be nice to add continent to this data so as to explore the data continentally.



