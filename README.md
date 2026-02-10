# 🚚 Amazon Logistics Data Analysis & Optimization

![MySQL](https://img.shields.io/badge/MySQL-005C84?style=for-the-badge&logo=mysql&logoColor=white)
![Data Analysis](https://img.shields.io/badge/Data%20Analysis-FFA116?style=for-the-badge&logo=amazon&logoColor=black)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)

## 📌 Project Overview
**Author:** Mahesh Katula  
**Domain:** Supply Chain & Logistics Analytics

Amazon handles millions of shipments daily. As volume increases, so do challenges like route congestion, warehouse bottlenecks, and delivery delays. 

This project utilizes **Advanced SQL** to analyze the delivery network, identifying root causes of delays and providing data-driven recommendations to improve the **Global On-Time Delivery Percentage**.

---

## 🎥 Project Walkthrough
I have recorded a detailed video explaining the analysis, SQL logic, and key findings of this project.

### [▶️ Click Here to Watch the Video Explanation](https://drive.google.com/file/d/1Zj5GxmIIO6Nl9sMSSg4seTVlkkUWqwNG/view?usp=drive_link)

---

## 📂 Repository Contents
| File Name | Description |
| :--- | :--- |
| **`Amazon_Logistics_Analysis.sql`** | The complete SQL script containing data cleaning, transformation, and analytical queries. |
| **`Amazon_Logistics_Project.pdf`** | A detailed presentation deck summarizing findings, visualizations, and strategic recommendations. |

---

## 🛠️ Tech Stack & SQL Skills
* **Database:** MySQL
* **Data Cleaning:** `COALESCE`, `CAST`, Duplicate Removal
* **Advanced Techniques:** * **CTEs** (Common Table Expressions) for modular logic.
    * **Window Functions** (`ROW_NUMBER`, `DENSE_RANK`) for ranking and stratification.
    * **Aggregations** (`GROUP BY`, `HAVING`) for summary statistics.
* **Metrics:** Efficiency Ratios, KPI Calculation, Time-Difference Calculations.

---

## 📊 Project Scope & Analysis

### 🔹 Task 1: Data Cleaning & Integrity
Before analysis, the dataset was scrubbed to ensure accuracy.
* **Duplicate Removal:** Utilized a CTE with `ROW_NUMBER()` partitioned by `Order_ID` to identify and delete duplicate records.
* **Null Handling:** Imputed missing `Traffic_Delay_Min` values using the **average delay specific to each route** (rather than a global average) to maintain data granularity.
* **Validation:** Enforced logical consistency (e.g., ensuring Delivery Date > Order Date).

### 🔹 Task 2: Delivery Delay Analysis
* Calculated the precise delay (`Actual_Arrival - Expected_Arrival`) for every shipment.
* Identified the **Top 10 Routes** with the highest average delay duration.
* Used `DENSE_RANK()` to prioritize orders with the most severe delays within each warehouse.

### 🔹 Task 3: Route Optimization (Crucial Insights)
* **Efficiency Ratio:** Engineered a custom metric: **"Distance-to-Time Efficiency Ratio"**.
* Identified specific routes that are short in distance but take disproportionately long to travel.
* Flagged **High-Risk Routes** where >20% of shipments failed to meet the delivery deadline.

### 🔹 Task 4: Warehouse Performance
* Analyzed processing throughput to identify facility bottlenecks.
* Used CTEs to compare individual **Warehouse Processing Times** against the **Global Average**.
* Ranked facilities based on their contribution to total network delays.

### 🔹 Task 5: Agent Reliability
* Ranked Delivery Agents based on **On-Time Delivery Percentage**.
* Identified underperforming agents (scoring **<80%**) for targeted retraining programs.
* Correlated **Agent Speed vs. Reliability** to determine if rushing deliveries led to errors.

### 🔹 Task 6 & 7: Tracking & KPIs
* Analyzed shipment checkpoints to find common reasons for failure (Weather, Traffic, Operations).
* **Final KPI:** Calculated the **Global On-Time Delivery Percentage** (Found to be **56%**).

---

## 🚀 Key Findings & Recommendations
Based on the SQL analysis, the following strategic actions are recommended:

1.  **Route Re-Planning:** Immediate review of the specific routes identified in Task 3 that exhibit low efficiency ratios despite short distances.
2.  **Warehouse Operations:** Deep-dive investigation into the bottom 3 warehouses (identified in Task 4) that are consistently slower than the global average.
3.  **Agent Training:** Initiate a performance improvement plan for agents identified in Task 5 with <80% on-time rates.

---

## 📬 Contact
**Mahesh Katula** *Connect with me on LinkedIn!* [![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-black?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/mahesh-katula-mk777)
