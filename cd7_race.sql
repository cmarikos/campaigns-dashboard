CREATE OR REPLACE VIEW `{{project_id}}.{{analytics_dataset}}.cd7_results_race` AS(
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
FROM `{{project_id}}.{{work_dataset}}.cd7_canvass_results` AS cr

LEFT JOIN `{{external_project_id}}.catalist_enhanced.enh_catalist__ntl_current` AS v
     ON cr.DWID = v.dwid

GROUP BY 1,2
ORDER BY 1,2
)