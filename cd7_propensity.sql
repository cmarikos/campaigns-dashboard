CREATE OR REPLACE VIEW `prod-organize-arizon-4e1c0a83.viewers_dataset.cd7_results_propensity` AS(
SELECT
m.catalistmodel_voteprop2025
, COUNT(cr.DWID) AS voters

FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_canvass_results` AS cr

LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__models` AS m
     ON cr.DWID = m.dwid

WHERE m.catalistmodel_voteprop2025 IS NOT NULL

GROUP BY 1
ORDER BY 1
)