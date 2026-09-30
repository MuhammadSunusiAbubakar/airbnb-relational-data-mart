# Airbnb Relational Data Mart (airbnb_dm)
## Database Implementation, Installation & Analytical Execution Manual
**Course:** Build a Data Mart in SQL (DLBDSPBDM01)  
**Student:** Muhammad Sunusi Abubakar  
**Matriculation Number:** 102401411  
**Study Program:** B.Sc. Data Science  
**Institution:** IU International University of Applied Sciences Hochschule, Germany  
**DBMS Engine:** MySQL 8.0 Community Server (InnoDB Engine)  
**Character Set & Collation:** utf8mb4 / utf8mb4_unicode_ci  

---

### 1. System Overview & Architecture Summary
The `airbnb_dm` relational database serves as an enterprise-grade data mart modeling the operational and transactional ecosystem of Airbnb:
* **Relational Normalization:** 22 physical entities engineered in Third Normal Form (3NF) to prevent insertion, update, and deletion anomalies.
* **Storage Engine:** MySQL InnoDB with complete ACID transactional guarantees, foreign key cascades, and domain CHECK validations.
* **Catalog Footprint:** 24 total registered objects (22 physical normalized tables + 2 production analytical views).
* **System Volume:** 453 populated rows with referential integrity (exceeding the >=20 entries/table threshold).
* **Physical Storage:** 912.00 KB total allocated database space (0.8906 MB).

---

### 2. File Manifest & Execution Order
Execute the accompanying production SQL scripts in the following order:

1. `01_airbnb_dm_setup.sql`:
   * Creates the `airbnb_dm` schema.
   * Compiles the complete 22-entity table DDL with primary, foreign, unique, and check constraints.
   * Seeds 453 records across all 5 dependency tiers with foreign key safety toggles.
2. `02_airbnb_dm_analytics_views.sql`:
   * Compiles production analytical views: `vw_platform_revenue_analytics` (platform take-rates and commission yields) and `vw_host_performance_occupancy` (Superhost KPIs and occupancy metrics).
   * Executes audit queries verifying the 24-hour delayed host escrow payout schedule and ternary dispute claim arbitration.

---

### 3. Step-by-Step Installation Instructions

#### Method A: Via MySQL Workbench (Recommended GUI)
1. Open MySQL Workbench and establish a connection to your local MySQL 8.0 instance.
2. Navigate to **File > Open SQL Script...** and select `01_airbnb_dm_setup.sql`.
3. Click the **Execute (lightning bolt)** button to build and populate the entire database.
4. Open `02_airbnb_dm_analytics_views.sql` via **File > Open SQL Script...**.
5. Execute the script to build the analytical view layer and run the verification test queries.

#### Method B: Via MySQL Command-Line Client / Terminal
Open your operating system terminal and run:
```bash
mysql -u root -p < 01_airbnb_dm_setup.sql
mysql -u root -p < 02_airbnb_dm_analytics_views.sql