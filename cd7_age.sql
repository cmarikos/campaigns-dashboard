CREATE OR REPLACE VIEW `prod-organize-arizon-4e1c0a83.viewers_dataset.cd7_results_age` AS(
SELECT
CASE 
   WHEN cr.ResultShortName <> 'Canvassed' THEN 'Not Canvassed'
   WHEN cr.ResultShortName = 'Canvassed' THEN 'Canvassed'
END AS canvass_result
, CASE
    WHEN a.age < 18 THEN "under 18"
    WHEN a.age BETWEEN 18 AND 24 THEN "18-24"
    WHEN a.age BETWEEN 25 AND 34 THEN "25-34"
    WHEN a.age BETWEEN 35 AND 44 THEN "35-44"
    WHEN a.age BETWEEN 45 AND 54 THEN "45-54"
    WHEN a.age BETWEEN 55 AND 64 THEN "55-64"
    WHEN a.age >= 65 THEN "65+"
    ELSE NULL
  END AS Age_Buckets
, COUNT(cr.DWID) AS voters
FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_canvass_results` AS cr

LEFT JOIN `proj-tmc-mem-mvp.catalist_enhanced.enh_catalist__ntl_current` AS a
     ON cr.DWID = a.dwid

GROUP BY 1,2
ORDER BY 1,2
)