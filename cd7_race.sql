CREATE OR REPLACE VIEW `prod-organize-arizon-4e1c0a83.viewers_dataset.cd7_results_race` AS(
SELECT
CASE 
   WHEN cr.ResultShortName <> 'Canvassed' THEN 'Not Canvassed'
   WHEN cr.ResultShortName = 'Canvassed' THEN 'Canvassed'
END AS canvass_result
, CASE 
     WHEN (v.race IS NULL OR v.race = 'unknown') THEN 'Unknown'
     WHEN v.race = 'asian' THEN 'AAPI'
     WHEN v.race = 'black' THEN 'Black'
     WHEN v.race = 'caucasian' THEN 'White'
     WHEN v.race = 'hispanic' THEN 'Latinx'
     WHEN v.race = 'nativeAmerican' THEN 'Native American'
     ELSE v.race
END AS race   
, COUNT(cr.DWID) AS voters
FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_canvass_results` AS cr

LEFT JOIN `proj-tmc-mem-mvp.catalist_enhanced.enh_catalist__ntl_current` AS v
     ON cr.DWID = v.dwid

GROUP BY 1,2
ORDER BY 1,2
)