# Campaigns Dashboard (Sanitized Template)

This repository documents an example workflow for a campaigns dashboard. It includes:
- A warehouse view that aggregates canvassing activity by precinct and joins geometry for mapping.
- A small Python snippet to merge multiple CRM export CSVs into a single file for warehouse loading.

> **Note:** All identifiers below are **placeholders**. Replace them with your own values before executing.

---

## Contents
- Overview
- Data Flow
- Prerequisites
- Warehouse Objects & Sources
- Create the View (template)
- Merge CRM Exports (Python)
- Load the Merged CSV
- Output Columns (View)
- Notes & Assumptions
- Refreshing the Data
- Troubleshooting
- Change Log

---

## Overview

The dashboard aggregates canvassing attempts and successful canvasses by precinct (`pctnum`) & date, and tags activity as pre‑primary or post‑primary using a configurable primary‑date threshold.

---

## Data Flow
1. Export your CRM (e.g., contact history) reports in several time windows as CSVs.
2. Merge those CSVs locally with the provided Python snippet to produce one combined CSV.
3. Load the merged CSV into a staging table, e.g. `{{project_id}}.{{work_dataset}}.{{staging_table}}`.
4. Create a view `{{project_id}}.{{analytics_dataset}}.{{view_name}}` that joins:
   - **Voter‑file provider** districts table (for `dwid` and state filter),
   - **Precinct crosswalk** (to derive `pctnum` from vendor codes),
   - **Precinct geometry** (for `COUNTY` and `GEOMETRY`),
   - and filters to your target district.

---

## Prerequisites
- Python 3.x with `pandas` installed.
- Access to your warehouse (e.g., BigQuery).
- CRM export(s) that include `DWID` (or equivalent) for joins to the voter‑file table.

---

## Warehouse Objects & Sources (placeholders)

**Target View (creates/overwrites):**  
`{{project_id}}.{{analytics_dataset}}.{{view_name}}`

**Source Tables:**  
- `{{project_id}}.{{work_dataset}}.{{staging_table}}` — merged CRM contact history (from the Python output).  
- `{{external_project_id}}.{{external_dataset}}.{{district_table}}` — voter‑file district info (used for `state` filter and join on `dwid`).  
- `{{project_id}}.{{crosswalk_dataset}}.{{precinct_crosswalk_table}}` — provides `pctnum` via `uniqueprecinctcode`.  
- `{{project_id}}.{{geo_dataset}}.{{precinct_geo_table}}` — precinct geometry (`COUNTY`, `GEOMETRY`) used to filter to the target district.

---

## Create the View (template)

```sql
CREATE OR REPLACE VIEW `{{project_id}}.{{analytics_dataset}}.{{view_name}}` AS
WITH canvassed AS (
  SELECT
    COUNT(s.DWID) AS canvassed,
    s.`Date Canvassed` AS date_canvassed,
    CASE
      WHEN s.`Date Canvassed` <= '{{primary_date}}' THEN 'pre-primary'
      WHEN s.`Date Canvassed` >  '{{primary_date}}' THEN 'post-primary'
      ELSE NULL
    END AS campaign_phase,
    cw.pctnum
  FROM `{{project_id}}.{{work_dataset}}.{{staging_table}}` AS s
  LEFT JOIN `{{external_project_id}}.{{external_dataset}}.{{district_table}}` AS d
    ON s.DWID = d.dwid
  LEFT JOIN `{{project_id}}.{{crosswalk_dataset}}.{{precinct_crosswalk_table}}` AS cw
    ON d.uniqueprecinctcode = cw.uniqueprecinctcode
  WHERE d.state = '{{state_code}}'
    AND s.Result = 'Canvassed'
  GROUP BY 2,3,4
),
attempted AS (
  SELECT
    COUNT(s.DWID) AS attempted,
    s.`Date Canvassed` AS date_canvassed,
    CASE
      WHEN s.`Date Canvassed` <= '{{primary_date}}' THEN 'pre-primary'
      WHEN s.`Date Canvassed` >  '{{primary_date}}' THEN 'post-primary'
      ELSE NULL
    END AS campaign_phase,
    cw.pctnum
  FROM `{{project_id}}.{{work_dataset}}.{{staging_table}}` AS s
  LEFT JOIN `{{external_project_id}}.{{external_dataset}}.{{district_table}}` AS d
    ON s.DWID = d.dwid
  LEFT JOIN `{{project_id}}.{{crosswalk_dataset}}.{{precinct_crosswalk_table}}` AS cw
    ON d.uniqueprecinctcode = cw.uniqueprecinctcode
  WHERE d.state = '{{state_code}}'
  GROUP BY 2,3,4
)
SELECT
  c.pctnum,
  c.canvassed,
  a.attempted,
  c.campaign_phase,
  g.COUNTY,
  g.GEOMETRY
FROM canvassed AS c
LEFT JOIN attempted AS a
  ON c.pctnum = a.pctnum AND c.date_canvassed = a.date_canvassed
LEFT JOIN `{{project_id}}.{{geo_dataset}}.{{precinct_geo_table}}` AS g
  ON c.pctnum = g.PCTNUM
WHERE g.CONGRESSIO = {{target_district_number}};
```

---

## Merge CRM Exports (Python)

```python
import pandas as pd

csv_files = [
    'ContactHistoryReport-1.csv',
    'ContactHistoryReport-2.csv',
    'ContactHistoryReport-3.csv',
    'ContactHistoryReport-4.csv',
]

df_combined = pd.concat([pd.read_csv(f) for f in csv_files], ignore_index=True)
df_combined.to_csv('combined_target_district_2025.csv', index=False)
```

**Run:**  
```bash
python3 csv_union.py
```

This produces `combined_target_district_2025.csv`.

---

## Load the Merged CSV

Load `combined_target_district_2025.csv` into:  
`{{project_id}}.{{work_dataset}}.{{staging_table}}`

**Required columns referenced by the view:**
- `DWID`
- `Date Canvassed`
- `Result`

> Tip: If your CSV headers contain spaces, you can still reference them using backticks in BigQuery, but consider normalizing to underscores.

---

## Output Columns (View)
- `pctnum` — Precinct identifier from the crosswalk.
- `canvassed` — Count of records with `Result = 'Canvassed'` (by date, `pctnum`, phase).
- `attempted` — Count of all records regardless of `Result` (by date, `pctnum`, phase).
- `campaign_phase` — `'pre-primary'` if `Date Canvassed` ≤ `{{primary_date}}`; `'post-primary'` if > `{{primary_date}}`.
- `COUNTY` — County name from precinct geometry.
- `GEOMETRY` — Precinct geometry for mapping.

Filtered to `CONGRESSIO = {{target_district_number}}` (target district only).

---

## Notes & Assumptions
- State filter: Records limited via `d.state = '{{state_code}}'` in the district table.
- Successful canvass vs. attempts: `canvassed` filters `Result = 'Canvassed'`; `attempted` counts all rows.
- Precinct mapping: `pctnum` is sourced by joining vendor `uniqueprecinctcode` to your crosswalk, then to the precinct geometry on `PCTNUM`.
- Phase cutoff: `{{primary_date}}` is your primary‑election date.

---

## Troubleshooting
- Missing `DWID`: Ensure the CRM export includes the join key.
- Null `pctnum`: Verify the `uniqueprecinctcode` coverage in your crosswalk.
- Geometry join: Confirm your precinct geometry has `PCTNUM` and the target‑district attribute used for filtering.

---

## Change Log
See Git history for template updates.
