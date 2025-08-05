# Campaigns Dashboard (currently CD7 only)

This repository documents the workflow for the **CD7 2025 campaigns dashboard**. It includes:

- A **BigQuery view** that aggregates canvassing activity by precinct and joins geometry for mapping.
- A **Python script** to merge four **VAN Contact History Report** exports (VAN limits downloads for the contact history report to 14-day windows), producing a single CSV you can load into BigQuery

> **Scope:** This code represents work done in **Congressional District 7 (CD7)** for the 2025 cycle.

---

## Contents

- [Overview](#overview)
- [Data Flow](#data-flow)
- [Prerequisites](#prerequisites)
- [BigQuery Objects & Sources](#bigquery-objects--sources)
- [Create the BigQuery View](#create-the-bigquery-view)
- [Merge VAN Exports (Python)](#merge-van-exports-python)
- [Loading the Merged CSV to BigQuery](#loading-the-merged-csv-to-bigquery)
- [Output Columns (View)](#output-columns-view)
- [Notes & Assumptions](#notes--assumptions)
- [Refreshing the Data](#refreshing-the-data)
- [Troubleshooting](#troubleshooting)
- [Change Log](#change-log)

---

## Overview

The dashboard aggregates canvassing **attempts** and **successful canvasses** by **precinct (`pctnum`)** & **date** and tags activity as **pre-primary** or **post-primary** using a July 15, 2025 threshold. Geometry is joined for map visualization, and the dataset is filtered to **CD7**.

---

## Data Flow

1. **Export** VAN Contact History Reports in four 14-day chunks.
2. **Merge** the four CSVs locally with the provided Python script, producing `combined_CD7_2025.csv`.
3. **Load** the merged CSV into BigQuery table `prod-organize-arizon-4e1c0a83.work_2025.cd7_special`.
4. **Query/View:** The BigQuery view (`viewers_dataset.cd7_2025_dashboard_geo`) joins:
   - Catalist district table (for `dwid` and `state` filtering),
   - Precinct crosswalk (for `pctnum`),
   - Precinct geometry (for `COUNTY` and `GEOMETRY`),
   - and filters to **CD7**.

---

## Prerequisites

- **Python** 3.x with `pandas` installed.
- Access to **Google BigQuery** project `prod-organize-arizon-4e1c0a83` and referenced datasets.
- **VAN Contact History Report** exports with **`DWID`** added to the VAN report to enable joins to the Catalist file.

---

## BigQuery Objects & Sources

- **Target View (creates/overwrites):**  
  `prod-organize-arizon-4e1c0a83.viewers_dataset.cd7_2025_dashboard_geo`

- **Source Tables:**
  - `prod-organize-arizon-4e1c0a83.work_2025.cd7_special` — merged VAN contact history (from the Python script output).
  - `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__district` — Catalist district info (used to limit to `state = 'AZ'` and join on `dwid`).
  - `prod-organize-arizon-4e1c0a83.rich_christina_proj.catalist_pctnum_crosswalk_native` — provides `pctnum` via `uniqueprecinctcode`.
  - `prod-organize-arizon-4e1c0a83.geofiles.az_precincts_geo` — precinct geometry and attributes (used for `COUNTY`, `GEOMETRY`, and `CONGRESSIO` = 7 filter).

---

## Create the BigQuery View

> **Note:** The view expects `work_2025.cd7_special` to be up to date with merged VAN data containing at least `DWID`, `Date Canvassed`, and `Result`.

```sql
CREATE OR REPLACE VIEW `prod-organize-arizon-4e1c0a83.viewers_dataset.cd7_2025_dashboard_geo` AS(

  WITH canvassed AS(
    SELECT 
    COUNT(s.DWID) AS canvassed
    , s.`Date Canvassed` AS date_canvassed
    , CASE 
        WHEN s.`Date Canvassed` <= '2025-07-15' THEN 'pre-primary'
        WHEN s.`Date Canvassed` > '2025-07-15' THEN 'post-primary'
        ELSE null
      END AS campaign_phase
    , cw.pctnum


    FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_special` AS s

    -- join nation file limit to AZ to remove multi state dupes
    LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__district` AS d
      ON s.DWID = d.dwid 

    -- join in crosswalk for pctnum
    LEFT JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.catalist_pctnum_crosswalk_native` AS cw
      ON d.uniqueprecinctcode = cw.uniqueprecinctcode

    -- national file has records for all state registrations, need to limit to AZ only
    WHERE d.state = 'AZ'
      AND s.Result = 'Canvassed'

    GROUP BY 2,3,4
    ORDER BY 2,3,4
  )

  , attempted AS(
    SELECT 
    COUNT(s.DWID) AS attempted
    , s.`Date Canvassed` AS date_canvassed
    , CASE 
        WHEN s.`Date Canvassed` <= '2025-07-15' THEN 'pre-primary'
        WHEN s.`Date Canvassed` > '2025-07-15' THEN 'post-primary'
        ELSE null
      END AS campaign_phase
    , cw.pctnum


    FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_special` AS s

    -- join nation file limit to AZ to remove multi state dupes
    LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__district` AS d
      ON s.DWID = d.dwid 

    -- join in crosswalk for pctnum
    LEFT JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.catalist_pctnum_crosswalk_native` AS cw
      ON d.uniqueprecinctcode = cw.uniqueprecinctcode

    -- national file has records for all state registrations, need to limit to AZ only
    WHERE d.state = 'AZ'

    GROUP BY 2,3,4
    ORDER BY 2,3,4
  )

  SELECT
    c.pctnum
    , c.canvassed
    , a.attempted
    , c.campaign_phase
    , g.COUNTY
    , g.GEOMETRY
  FROM canvassed AS c
  LEFT JOIN attempted AS a
    ON c.pctnum = a.pctnum AND c.date_canvassed = a.date_canvassed

  LEFT JOIN `prod-organize-arizon-4e1c0a83.geofiles.az_precincts_geo` AS g
    ON c.pctnum = g.PCTNUM

  WHERE g.CONGRESSIO = 7
);
```

---

## Merge VAN Exports (Python)

> **Why:** VAN limits Contact History Report exports to 14-day windows; merging four windows yields the complete CD7 period.

**Input:** Four VAN CSVs with **DWID** included, e.g.:

- `ContactHistoryReport-1 - ContactHistoryReport-1160430803.csv`  
- `ContactHistoryReport-2 - ContactHistoryReport-3215510414.csv`  
- `ContactHistoryReport-3 - ContactHistoryReport-8785442276.csv`  
- `ContactHistoryReport-4 - ContactHistoryReport-17273723297.csv`  

**Script:**

```python
import pandas as pd

# List of CSV file paths
csv_files = [
    'ContactHistoryReport-1 - ContactHistoryReport-1160430803.csv',
    'ContactHistoryReport-2 - ContactHistoryReport-3215510414.csv',
    'ContactHistoryReport-3 - ContactHistoryReport-8785442276.csv',
    'ContactHistoryReport-4 - ContactHistoryReport-17273723297.csv'
]

# Read and concatenate all CSVs into one DataFrame
df_combined = pd.concat([pd.read_csv(file) for file in csv_files], ignore_index=True)

# Optional: Preview the combined DataFrame
print(df_combined.head())

# Export to a new CSV file
df_combined.to_csv('combined_CD7_2025.csv', index=False)
```

**Run:**
```bash
python3 csv_union.py
```

This produces `combined_CD7_2025.csv`.

---

## Loading the Merged CSV to BigQuery

Load `combined_CD7_2025.csv` into:
```
prod-organize-arizon-4e1c0a83.work_2025.cd7_special
```

**Required columns referenced by the view:**
- `DWID`
- `Date Canvassed`
- `Result`
/
One flag that should be fixed in future iterations is the the `combined_CD7_2025.csv` and underlying VAN reports by default have spaces in column headers, it still works, but I should have subbed those for underscores in the csv_union script.
---

## Output Columns (View)

The view `viewers_dataset.cd7_2025_dashboard_geo` returns:

- `pctnum` — Precinct identifier from the Catalist crosswalk.
- `canvassed` — Count of records with `Result = 'Canvassed'` (by date, `pctnum`, phase).
- `attempted` — Count of all records regardless of `Result` (by date, `pctnum`, phase).
- `campaign_phase` — `'pre-primary'` if `Date Canvassed` ≤ `2025-07-15`; `'post-primary'` if > `2025-07-15`.
- `COUNTY` — County name from precinct geometry table.
- `GEOMETRY` — Precinct geometry for mapping.

Filtered to `g.CONGRESSIO = 7` (CD7 only).

---

## Notes & Assumptions

- **State filter:** Records limited to **Arizona** via `d.state = 'AZ'` in the Catalist district table. This is a national file so there are duplicates if people have been registered in multiple states. If you have a state file only this is not necessry.
- **Successful canvass vs. attempts:**  
  - `canvassed` counts only `Result = 'Canvassed'`.  
  - `attempted` counts all records (no `Result` filter).
- **Precinct mapping:** `pctnum` is sourced by joining Catalist `uniqueprecinctcode` to the crosswalk, then to the precinct geometry table by `PCTNUM`.
- **Phase cutoff:** The campaign phase threshold is **July 15, 2025**, the date of the primary election.
- **CD filter:** Final output restricted to **CD7** through `CONGRESSIO = 7`.

---

## Troubleshooting

- **Missing `DWID`:** Ensure your VAN export includes the **DWID** column; it is required for the Catalist join.
- **Null `pctnum`:** If some rows lack `pctnum`, verify the `uniqueprecinctcode` coverage in the crosswalk.
- **Pctnum*** is an AZ unique precinct code system that I created [in this geo-files repo](https://github.com/cmarikos/geo-precincts). This allows me to work between Targetsmart and Catalist and avoid issues with duplicative and inconsistent naming conventions for AZ precincts.
- **Date comparisons:** If `Date Canvassed` imports as TEXT, convert to DATE/DATETIME for consistency—or confirm the string format compares correctly to `'2025-07-15'`.
- **Geometry join:** Verify `PCTNUM` formats (string vs number) match between crosswalk and geometry tables.

---

## Change Log

- **Initial CD7 build:** Added merge script for four VAN exports; created `cd7_2025_dashboard_geo` view joining Catalist, crosswalk, and precinct geometry; filtered to CD7 with pre/post primary phase tagging.
