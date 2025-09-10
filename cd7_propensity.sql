CREATE OR REPLACE VIEW `{{project_id}}.{{analytics_dataset}}.cd7_results_propensity` AS(
SELECT
m.catalistmodel_voteprop2025
, COUNT(cr.DWID) AS voters

FROM `{{project_id}}.{{work_dataset}}.cd7_canvass_results` AS cr

LEFT JOIN `{{external_project_id}}.{{external_dataset}}.cln_catalist__models` AS m
     ON cr.DWID = m.dwid

WHERE m.catalistmodel_voteprop2025 IS NOT NULL

GROUP BY 1
ORDER BY 1
)