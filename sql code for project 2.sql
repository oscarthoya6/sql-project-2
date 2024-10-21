---my database sunking has two tables known as payments, accounts

/* preparing the data by adding the following attributes: unit_age_days, unit_age_week, unit_proportional_age to the Accounts Payment Information view */

SELECT 
    a.angaza_id,
    a.area,
    a.daily_price,
    a.upfront_price,
    a.expected_repayment_days,
    a.registration_date,
    a.free_days_included,
    a.product_group,
    a.country,
    p.portfolio_date,
    p.days_to_cutoff,
    p.amount_toward_follow_on,

    -- Calculating 'unit age days'
    DATEDIFF(DAY, a.registration_date, p.portfolio_date) AS unit_age_days,

    -- Calculating 'unit age week'
    DATEDIFF(DAY, a.registration_date, p.portfolio_date) / 7.0 AS unit_age_week,

    -- Calculating 'unit proportional age'
    round(DATEDIFF(DAY, a.registration_date, p.portfolio_date) * 1.0 / a.expected_repayment_days,1) AS unit_proportional_age

FROM 
    sunking..accounts a
JOIN 
    sunking..payments p
ON 
    a.angaza_id = p.angaza_id;

	---end



/* Calculating how many days on average does it take each of the product groups to complete 0.1 UPA */

WITH ProportionalAge AS (
    SELECT 
        a.product_group,
        DATEDIFF(DAY, a.registration_date, p.portfolio_date) AS unit_age_days,
        round(DATEDIFF(DAY, a.registration_date, p.portfolio_date) * 1.0 / a.expected_repayment_days,1) AS unit_proportional_age
    FROM 
        sunking..accounts a
    JOIN 
        sunking..payments p
    ON 
        a.angaza_id = p.angaza_id
)
SELECT 
    product_group,
    AVG(unit_age_days) AS avg_days_for_0_1_unit_proportional_age
FROM 
    ProportionalAge
WHERE 
    unit_proportional_age = 0.1
GROUP BY 
    product_group;

---end



/* Computing the Disabled rates and repayment speed for each portfolio date */

WITH DisabledRates AS (
    SELECT 
        p.portfolio_date,
        COUNT(DISTINCT CASE WHEN p.days_to_cutoff <= 0 THEN p.angaza_id END) AS disabled_count,
        COUNT(DISTINCT CASE WHEN p.days_to_cutoff > 0 THEN p.angaza_id END) AS active_count
    FROM 
        sunking..payments p
    GROUP BY 
        p.portfolio_date
),
RepaymentSpeed AS (
    SELECT 
        p.portfolio_date,
        SUM(p.amount_toward_follow_on) AS total_payment_on_date,
        SUM(a.daily_price) AS total_expected_daily_price
    FROM 
        sunking..payments p
    JOIN 
        sunking..accounts a
    ON 
        p.angaza_id = a.angaza_id
    GROUP BY 
        p.portfolio_date
)
SELECT 
    d.portfolio_date,

    -- Calculating 'Disabled rates across portfolio date'
    CASE 
        WHEN d.active_count > 0 THEN d.disabled_count * 1.0 / d.active_count
        ELSE NULL
    END AS disabled_rate_across_portfolio_date,

    -- Calculating 'Repayment speed across portfolio date'
    CASE 
        WHEN r.total_expected_daily_price > 0 THEN r.total_payment_on_date * 1.0 / r.total_expected_daily_price
        ELSE NULL
    END AS repayment_speed_across_portfolio_date

FROM 
    DisabledRates d
JOIN 
    RepaymentSpeed r
ON 
    d.portfolio_date = r.portfolio_date

--- can add this line of code in above, filtering portfolio date as june 09 2024
--Where r.portfolio_date = '2024-06-09'

---end



/* lets find Disabled rate for June 9, 2024 */

WITH DisabledRates AS (
    SELECT 
        p.portfolio_date,
        COUNT(DISTINCT CASE WHEN p.days_to_cutoff <= 0 THEN p.angaza_id END) AS disabled_count,
        COUNT(DISTINCT CASE WHEN p.days_to_cutoff > 0 THEN p.angaza_id END) AS active_count
    FROM 
        sunking..payments p
    WHERE 
        p.portfolio_date = '2024-06-09'
    GROUP BY 
        p.portfolio_date
)
SELECT 
    portfolio_date,
    CASE 
        WHEN active_count > 0 THEN disabled_count * 1.0 / active_count
        ELSE NULL
    END AS disabled_rate
FROM 
    DisabledRates;

-- 2. Repayment speed for Lanterns in Rongo on July 18, 2024 (first half of the month registration)

WITH RepaymentSpeed AS (
    SELECT 
        p.portfolio_date,
        SUM(p.amount_toward_follow_on) AS total_payment_on_date,
        SUM(a.daily_price) AS total_expected_daily_price
    FROM 
        sunking..payments p
    JOIN 
        sunking..accounts a
    ON 
        p.angaza_id = a.angaza_id
    WHERE 
        p.portfolio_date = '2024-07-18'
        AND a.product_group = 'Lanterns'
        AND a.area = 'Rongo'
        AND DAY(a.registration_date) <= 15 -- first half of the month
    GROUP BY 
        p.portfolio_date
)
SELECT 
    portfolio_date,
    CASE 
        WHEN total_expected_daily_price > 0 THEN total_payment_on_date * 1.0 / total_expected_daily_price
        ELSE NULL
    END AS repayment_speed
FROM 
    RepaymentSpeed;

	---end




/* Computing disabled rates across portfolio weeks from the week of Jan 15 to July 15, 2024, and how Rongo and Murang’a compare */

WITH WeeklyData AS (
    SELECT 
        DATEADD(WEEK, DATEDIFF(WEEK, 0, p.portfolio_date), 0) AS portfolio_week,
        a.area,
        p.angaza_id,
        p.days_to_cutoff,
        DATEDIFF(DAY, a.registration_date, p.portfolio_date) AS days_enabled
    FROM 
        sunking..payments p
    JOIN 
        sunking..accounts a ON p.angaza_id = a.angaza_id
    WHERE 
        p.portfolio_date BETWEEN '2024-01-15' AND '2024-07-15'
),

DisabledCounts AS (
    SELECT 
        portfolio_week,
        area,
        COUNT(DISTINCT angaza_id) AS total_units,
        SUM(CASE WHEN days_to_cutoff <= 0 THEN days_enabled END) AS total_days_disabled
    FROM 
        WeeklyData
    GROUP BY 
        portfolio_week, area
),

DisabledRate AS (
    SELECT 
        portfolio_week,
        area,
        CASE 
            WHEN total_units > 0 THEN total_days_disabled * 1.0 / (total_units * 7)
            ELSE NULL
        END AS disabled_rate
    FROM 
        DisabledCounts
)

-- Pivot to make 'Muranga' and 'Rongo' as columns and portfolio_week as rows
SELECT 
    portfolio_week,
    [Murang'a] AS disabled_rate_muranga,  
    [Rongo] AS disabled_rate_rongo   
FROM 
    DisabledRate
PIVOT (
    MAX(disabled_rate)
    FOR area IN ([Murang'a], [Rongo])   
) AS PivotTable
ORDER BY 
    portfolio_week;

---end




/* Computing repayment speed across Unit Age Weeks from week 1 to 10, and how Rongo and Murang’a compare */

WITH WeeklyPayments AS (
    SELECT 
        DATEADD(WEEK, DATEDIFF(WEEK, 0, p.portfolio_date), 0) AS week_start,
        a.area,
        SUM(p.amount_toward_follow_on) AS total_collected,
        SUM(a.daily_price) AS total_expected
    FROM 
        sunking..payments p
    JOIN 
        sunking..accounts a 
       ON p.angaza_id = a.angaza_id
    WHERE 
        DATEPART(WEEK, p.portfolio_date) BETWEEN 1 AND 10
    GROUP BY 
        DATEADD(WEEK, DATEDIFF(WEEK, 0, p.portfolio_date), 0), a.area
),

RepaymentSpeed AS (
    SELECT 
        week_start,
        area,
        CASE 
            WHEN total_expected > 0 THEN total_collected * 1.0 / total_expected
            ELSE NULL
        END AS repayment_speed
    FROM 
        WeeklyPayments
)

-- Pivot the repayment speed for each area into columns
SELECT 
    week_start,
    [Murang'a] AS repayment_speed_muranga,
    [Rongo] AS repayment_speed_rongo
FROM 
    RepaymentSpeed
PIVOT (
    MAX(repayment_speed)  
    FOR area IN ([Murang'a], [Rongo])  
) AS PivotTable
ORDER BY 
    week_start;
