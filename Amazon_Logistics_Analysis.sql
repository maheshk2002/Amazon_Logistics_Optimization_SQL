-- Identify and delete duplicate Order_ID records.
WITH Duplicate_Finder AS (
SELECT Order_ID, ROW_NUMBER() OVER (
	PARTITION BY Order_ID 
	ORDER BY Order_Date -- Keeps the earliest entry if dates differ
) AS row_num FROM Orders
)
-- Deleting rows where row_num is greater than 1
DELETE FROM Orders
WHERE Order_ID IN (
    SELECT Order_ID 
    FROM Duplicate_Finder 
    WHERE row_num > 1
);
-- Replace null Traffic_Delay_Min with the average delay for that route
-- find null values
SELECT
    COUNT(*) AS Null_Count FROM
	-- Routes -- There is no null values in routes table
    Warehouses -- Null values present in warehouses table
WHERE Traffic_Delay_Min IS NULL;
    
SET SQL_SAFE_UPDATES = 0; -- Turn off safe mode
Update warehouses as w set Traffic_Delay_Min = (
	select Avg(r.Traffic_Delay_Min) from Routes as r join Orders as o
    on o.Route_ID=r.Route_ID where w.Warehouse_ID=o.Warehouse_ID
) where Traffic_Delay_Min is null;
SET SQL_SAFE_UPDATES = 1; -- Turn safe mode back on (Good practice)

-- Convert all date columns into YYYY-MM-DD format using SQL functions
SET SQL_SAFE_UPDATES = 0; -- Turn off safe mode
UPDATE Orders 
SET 
    Order_Date = DATE_FORMAT(Order_Date, '%Y-%m-%d'),
    Expected_Delivery_Date = DATE_FORMAT(Expected_Delivery_Date, '%Y-%m-%d'),
    Actual_Delivery_Date = DATE_FORMAT(Actual_Delivery_Date, '%Y-%m-%d');
SET SQL_SAFE_UPDATES = 1; -- Turn safe mode back on (Good practice)

-- Ensure that no Actual_Delivery_Date is before Order_Date
select * from orders WHERE Actual_Delivery_Date < Order_Date;

-- Calculate delivery delay (in days) for each order
SELECT 
    Order_ID, 
    Actual_Delivery_Date, 
    Expected_Delivery_Date,
    DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days
FROM Orders;

-- Find Top 10 delayed routes based on average delay days.
SELECT r.Route_ID, r.Start_Location, r.End_Location, 
    AVG(DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date)) 
    AS Avg_Delay_Days
FROM Orders o JOIN Routes r ON o.Route_ID = r.Route_ID
WHERE o.Delivery_Status = 'Delayed'
GROUP BY r.Route_ID, r.Start_Location, r.End_Location
ORDER BY Avg_Delay_Days DESC
LIMIT 10;

-- Use window functions to rank all orders by delay within each warehouse.
SELECT Warehouse_ID, Order_ID, Expected_Delivery_Date, Actual_Delivery_Date,
    DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days,
    -- DENSE_RANK ensures no numbers are skipped in the ranking sequence
    DENSE_RANK() OVER (
        PARTITION BY Warehouse_ID 
        ORDER BY DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) DESC
    ) AS Delay_Rank
FROM Orders
WHERE Delivery_Status = 'Delayed'; 

-- Calculated Avg delivery time, Avg traffic delay, Distance-to-time efficiency ratio for each route
SELECT r.Route_ID, r.Start_Location, r.End_Location,
    -- 1. Average delivery time (Order_Date to Actual_Delivery_Date)
    round(AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)), 1) AS Avg_Delivery_Time_Days,
    -- 2. Average traffic delay (from the Routes table)
    round((r.Traffic_Delay_Min)) AS Avg_Traffic_Delay_Min,
    -- 3. Distance-to-time efficiency ratio
    round((r.Distance_KM / r.Average_Travel_Time_Min), 2) AS Efficiency_Ratio
FROM Routes r JOIN Orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Route_ID, r.Start_Location, r.End_Location, r.Distance_KM, r.Average_Travel_Time_Min
ORDER BY r.Route_ID;

-- Identified Top 3 Routes with the Worst Efficiency Ratio
SELECT Route_ID, Start_Location, End_Location, 
round((Distance_KM / Average_Travel_Time_Min), 2) 
AS Efficiency_Ratio FROM Routes 
ORDER BY Efficiency_Ratio ASC
LIMIT 3;

-- Routes with >20% delayed shipments
SELECT Route_ID,
-- Step 1: Count orders that were actually delayed
COUNT(CASE WHEN Delivery_Status = 'Delayed' THEN 1 END) AS Delayed_Orders,
-- Step 2: Count the total number of orders for that route
COUNT(*) AS Total_Orders,
-- Step 3: Calculate the percentage and round it
ROUND((COUNT(CASE WHEN Delivery_Status = 'Delayed' THEN 1 END) / COUNT(*)) * 100, 2) 
AS Delay_Percentage FROM Orders
GROUP BY Route_ID HAVING Delay_Percentage > 20
ORDER BY Delay_Percentage DESC;

-- Recommend potential routes for optimization
SELECT r.Route_ID, r.Start_Location, r.End_Location,
ROUND((r.Distance_KM / r.Average_Travel_Time_Min), 2) AS Efficiency_Ratio,
r.Traffic_Delay_Min, delay_stats.Delay_Percentage
FROM Routes r JOIN (
    SELECT 
	Route_ID, 
	ROUND((COUNT(CASE WHEN Delivery_Status = 'Delayed' THEN 1 END) / COUNT(*)) * 100, 2) AS Delay_Percentage
    FROM Orders
    GROUP BY Route_ID
) AS delay_stats ON r.Route_ID = delay_stats.Route_ID
WHERE 
    (r.Distance_KM / r.Average_Travel_Time_Min) < 0.6 -- Slow routes
    AND delay_stats.Delay_Percentage > 20             -- High failure routes
ORDER BY delay_stats.Delay_Percentage DESC;

-- Top 3 warehouses with the highest average processing time.
SELECT Warehouse_ID, Location, Processing_Time_Min FROM warehouses
ORDER BY Processing_Time_Min DESC LIMIT 3;

-- Calculate total vs. delayed shipments for each warehouse
SELECT Warehouse_ID, COUNT(Order_ID) as Total_Shipments, 
SUM(CASE WHEN Delivery_Status = 'Delayed' THEN 1 ELSE 0 END) as Delayed_Shipments
FROM orders GROUP BY Warehouse_ID -- ORDER BY Total_Shipments DESC;
ORDER BY Warehouse_ID;

-- Using CTE to find bottleneck warehouses where processing time > global average.
WITH Global_Average_Table AS ( -- CTE 1: Calculate the benchmark (Global Average)
    SELECT AVG(Processing_Time_Min) AS Global_Avg
    FROM Warehouses
), -- We use a comma here to define the next CTE, NOT the 'WITH' keyword
-- CTE 2: Identify only the warehouses that exceed that benchmark
Bottleneck_List AS (
    SELECT w.Warehouse_ID, w.Location, w.Processing_Time_Min, g.Global_Avg
    FROM Warehouses w CROSS JOIN Global_Average_Table g
    WHERE w.Processing_Time_Min > g.Global_Avg
)
SELECT * FROM Bottleneck_List 
ORDER BY Processing_Time_Min DESC;

-- Rank warehouses based on on-time delivery percentage.
WITH OnTime_Percentage_CTE AS (
    SELECT Warehouse_ID,
	ROUND((SUM(CASE WHEN Delivery_Status = 'On Time' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) 
    AS On_Time_Percentage FROM Orders GROUP BY Warehouse_ID
)
SELECT Warehouse_ID, On_Time_Percentage,
    DENSE_RANK() OVER (ORDER BY On_Time_Percentage DESC) AS Warehouse_Rank
FROM OnTime_Percentage_CTE;

-- Rank agents (per route) by on-time delivery percentage
SELECT Agent_ID, Route_ID, On_Time_Percentage,
DENSE_RANK() OVER (
        PARTITION BY Route_ID 
        ORDER BY On_Time_Percentage DESC
    ) AS Agent_Route_Rank
FROM Delivery_Agents;

-- Find agents with on-time % < 80%
SELECT Agent_ID, Route_ID, On_Time_Percentage
FROM Delivery_Agents
WHERE On_Time_Percentage < 80
ORDER BY On_Time_Percentage ASC;

-- Compare average speed of top 5 vs bottom 5 agents using subqueries.
SELECT 
    (SELECT AVG(Avg_Speed_KM_HR) FROM (
        SELECT Avg_Speed_KM_HR FROM Delivery_Agents 
        ORDER BY On_Time_Percentage DESC LIMIT 5
    ) AS Top_5) AS Top5_Agents_Avg_Speed,
    (SELECT AVG(Avg_Speed_KM_HR) FROM (
        SELECT Avg_Speed_KM_HR FROM Delivery_Agents 
        ORDER BY On_Time_Percentage ASC LIMIT 5
    ) AS Bottom_5) AS Bottom5_Agents_Avg_Speed,
    -- Calculate the difference to show the gap
    (SELECT AVG(Avg_Speed_KM_HR) FROM (
        SELECT Avg_Speed_KM_HR FROM Delivery_Agents 
        ORDER BY On_Time_Percentage DESC LIMIT 5
    ) AS Top_5) - 
    (SELECT AVG(Avg_Speed_KM_HR) FROM (
        SELECT Avg_Speed_KM_HR FROM Delivery_Agents 
        ORDER BY On_Time_Percentage ASC LIMIT 5
    ) AS Bottom_5) AS Speed_Gap;
    
 --   For each order, list the last checkpoint and time.
WITH Ranked_Checkpoints AS (
    SELECT Order_ID, Checkpoint, Checkpoint_Time,
        -- Rank by time first, then by the Checkpoint name to break ties
        ROW_NUMBER() OVER (
            PARTITION BY Order_ID 
            ORDER BY Checkpoint_Time DESC, Checkpoint DESC
        ) AS Recent_Rank
    FROM Shipment_Tracking
)
SELECT Order_ID, Checkpoint AS Last_Checkpoint, Checkpoint_Time AS Last_Time
FROM Ranked_Checkpoints WHERE Recent_Rank = 1
ORDER BY Order_ID;

-- Most common delay reasons (excluding None).
SELECT Delay_Reason, COUNT(*) AS Occurrence_Count
FROM Shipment_Tracking
WHERE Delay_Reason IS NOT NULL AND Delay_Reason != 'None'
GROUP BY Delay_Reason
ORDER BY Occurrence_Count DESC;

-- Identify orders with >2 delayed checkpoints
SELECT Order_ID, COUNT(*) AS Delayed_Checkpoints_Count
FROM Shipment_Tracking
WHERE Delay_Reason IS NOT NULL AND Delay_Reason != 'None'
GROUP BY Order_ID HAVING COUNT(*) > 2;

-- Average Delivery Delay per Region (Start_Location).
SELECT r.Start_Location AS Region,
ROUND(AVG(DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date)), 2) 
AS Avg_Delivery_Delay_Days FROM Orders o
JOIN Routes r ON o.Route_ID = r.Route_ID
GROUP BY r.Start_Location
ORDER BY Avg_Delivery_Delay_Days DESC;

-- On-Time Delivery %
SELECT COUNT(*) AS Total_Deliveries,
SUM(CASE WHEN Delivery_Status = 'On Time' THEN 1 ELSE 0 END) 
AS Total_On_Time_Deliveries,
ROUND(
(SUM(CASE WHEN Delivery_Status = 'On Time' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 
2
) AS On_Time_Percentage
FROM Orders;

-- Average Traffic Delay per Route
SELECT Route_ID,
ROUND(AVG(Traffic_Delay_Min), 2) AS Avg_Traffic_Delay_Min
FROM Routes GROUP BY Route_ID ORDER BY Route_ID;
-- ORDER BY Avg_Traffic_Delay_Min DESC;
