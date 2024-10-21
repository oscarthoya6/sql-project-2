# sql-project-2
You can use spreadsheet software, programming language or a BI tool for this Section.
1.	Show total sales across the three months in Rongo and Murang’a.
2.	Determine the total sales and sales per product group for the two areas for the three months. How do the two areas compare?
3.	What is the most popular product in Rongo? What is the proportion of the best-seller relative to all sales in the area?
4.	How many Lanterns were sold on December 13, 2023, in the Rongo area?
5.	How many Phones were sold in Murang’a in January 2024?


1.	Unit Age Days Excluding Free Days - which is the number of days between the registration date and a given portfolio date excluding free days included.
2.	Unit Age Weeks Excluding Free Days - which is the number of weeks between the registration date and a given portfolio date excluding free days included.
3.	Unit Proportional Age (UPA) - which is Unit Age Days divided by Planned Repayment Days at a given date (in 1 decimal place). 
4.	Status - which tags an account at a given time as either ENABLED or DISABLED (Go through the Data Dictionary provided to understand how to do this)
Question: How many days on average does it take each of the product groups to complete 0.1 UPA?


It’s now time to cover two metrics we use to measure our collection performance - repayment speed and disabled rates.
Definitions:
	Disabled rates across portfolio date: This is the number of distinct accounts disabled on a given date over the number of all distinct units under repayment.
	Repayment speed across portfolio date: This is the amount collected from all accounts (excluding deposit) on a given date divided by the amount expected on that date.
Questions:
	Compute the Disabled rates for each portfolio date. What is the disabled rate for June 9, 2024, for all accounts in the sample?
	What is the Repayment speed for Lanterns in the Rongo area on July 18, 2024? Consider accounts registered in the first half of the month only.
Let’s move forward to calculate repayment speed and disabled rates for aggregated data - instead of looking at daily data, we will explore weekly aggregations.

	Disabled rates across portfolio week: This is the number of distinct disabled accounts divided by the distinct count of all units, where, count distinct is done at customer and date level of aggregation, that is, (COUNT DISTINCT angaza_id || portfolio_date)
Example:

Assume that we have 8 units under repayment for the week of April 8 (April 8-15). For a perfect week, we need the 8 units to be enabled for 7 days each giving us 8*7=56 ‘units’ in total. 3 units were disabled for a total of 7 days. Therefore:

 Disabled rate for April 8 = 7/56 = 0.125 = 12.5%.
Questions:
	Compute and plot disabled rates across portfolio weeks from the week of Jan 15 to July 15, 2024, split by area. How does Rongo and Murang’a compare?
	Compute and plot repayment speed across Unit Age Weeks from week 1 to 10, split by area. How does Rongo and Murang’a compare?

