CREATE DATABASE COVID_19_Analysis;

USE COVID_19_Analysis;

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

SELECT TOP 5 *
FROM dbo.worldometer_coronavirus_daily_data;

SELECT TOP 5 *
FROM dbo.worldometer_coronavirus_summary_data;

SELECT
    COUNT(*) AS Total_Daily_Records
FROM dbo.worldometer_coronavirus_daily_data;

SELECT
    COUNT(*) AS Total_Summary_Records
FROM dbo.worldometer_coronavirus_summary_data;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'worldometer_coronavirus_daily_data',
    'worldometer_coronavirus_summary_data'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;

SELECT
    SUM(total_confirmed) AS Total_Confirmed_Cases,
    SUM(total_deaths) AS Total_Deaths,
    SUM(total_recovered) AS Total_Recovered,
    SUM(active_cases) AS Total_Active_Cases,

    CAST(
        SUM(total_deaths) * 100.0 /
        NULLIF(SUM(total_confirmed), 0)
        AS DECIMAL(10,2)
    ) AS Death_Rate_Percentage,

    CAST(
        SUM(total_recovered) * 100.0 /
        NULLIF(SUM(total_confirmed), 0)
        AS DECIMAL(10,2)
    ) AS Recovery_Rate_Percentage

FROM dbo.worldometer_coronavirus_summary_data;

SELECT TOP 10
    country,
    continent,
    total_confirmed,
    total_deaths,
    total_recovered,
    active_cases
FROM dbo.worldometer_coronavirus_summary_data
ORDER BY total_confirmed DESC;

SELECT
    continent,
    SUM(total_confirmed) AS Total_Cases,
    SUM(total_deaths) AS Total_Deaths,
    SUM(total_recovered) AS Total_Recovered,
    SUM(active_cases) AS Active_Cases
FROM dbo.worldometer_coronavirus_summary_data
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Cases DESC;

SELECT
    country,
    total_confirmed,
    total_deaths,
    CAST(
        total_deaths * 100.0 /
        NULLIF(total_confirmed, 0)
        AS DECIMAL(10,2)
    ) AS Death_Rate_Percentage
FROM dbo.worldometer_coronavirus_summary_data
WHERE total_confirmed > 0
ORDER BY Death_Rate_Percentage DESC;

SELECT
    YEAR(TRY_CONVERT(DATE, [date])) AS Year,
    MONTH(TRY_CONVERT(DATE, [date])) AS Month,
    SUM(daily_new_cases) AS Monthly_New_Cases,
    SUM(daily_new_deaths) AS Monthly_New_Deaths
FROM dbo.worldometer_coronavirus_daily_data
WHERE TRY_CONVERT(DATE, [date]) IS NOT NULL
GROUP BY
    YEAR(TRY_CONVERT(DATE, [date])),
    MONTH(TRY_CONVERT(DATE, [date]))
ORDER BY Year, Month;

SELECT
    country,
    continent,
    total_confirmed,
    RANK() OVER (
        ORDER BY total_confirmed DESC
    ) AS Country_Rank
FROM dbo.worldometer_coronavirus_summary_data
ORDER BY Country_Rank;

WITH CountryRanking AS
(
    SELECT
        country,
        continent,
        total_confirmed,
        total_deaths,

        ROW_NUMBER() OVER (
            PARTITION BY continent
            ORDER BY total_confirmed DESC
        ) AS Country_Rank

    FROM dbo.worldometer_coronavirus_summary_data
    WHERE continent IS NOT NULL
)
SELECT *
FROM CountryRanking
WHERE Country_Rank <= 5
ORDER BY continent, Country_Rank;

WITH DailyCases AS
(
    SELECT
        country,
        TRY_CONVERT(DATE, [date]) AS Report_Date,
        SUM(daily_new_cases) AS New_Cases
    FROM dbo.worldometer_coronavirus_daily_data
    WHERE TRY_CONVERT(DATE, [date]) IS NOT NULL
    GROUP BY
        country,
        TRY_CONVERT(DATE, [date])
)
SELECT
    country,
    Report_Date,
    New_Cases,

    AVG(CAST(New_Cases AS FLOAT)) OVER (
        PARTITION BY country
        ORDER BY Report_Date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS Rolling_7_Day_Average

FROM DailyCases
ORDER BY country, Report_Date;

WITH MonthlyCases AS
(
    SELECT
        YEAR(TRY_CONVERT(DATE, [date])) AS Report_Year,
        MONTH(TRY_CONVERT(DATE, [date])) AS Report_Month,
        SUM(daily_new_cases) AS Total_New_Cases
    FROM dbo.worldometer_coronavirus_daily_data
    WHERE TRY_CONVERT(DATE, [date]) IS NOT NULL
    GROUP BY
        YEAR(TRY_CONVERT(DATE, [date])),
        MONTH(TRY_CONVERT(DATE, [date]))
)
SELECT TOP 10
    Report_Year,
    Report_Month,
    Total_New_Cases
FROM MonthlyCases
ORDER BY Total_New_Cases DESC;

SELECT
    continent,
    SUM(total_confirmed) AS Total_Cases,
    SUM(total_deaths) AS Total_Deaths,

    CAST(
        SUM(total_deaths) * 100.0 /
        NULLIF(SUM(total_confirmed), 0)
        AS DECIMAL(10,2)
    ) AS Death_Rate_Percentage

FROM dbo.worldometer_coronavirus_summary_data
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Death_Rate_Percentage DESC;