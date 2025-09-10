CREATE OR REPLACE VIEW `{{project_id}}.{{analytics_dataset}}.cd7_results_income` AS(
WITH t AS (
  SELECT
    CASE WHEN cr.ResultShortName = 'Canvassed' THEN 'Canvassed' ELSE 'Not Canvassed' END AS canvass_result,
    REPLACE(m.catalistmodel_income_bin, '"', '') AS income_bin,
    COUNT(cr.DWID) AS voters
  FROM `{{project_id}}.{{work_dataset}}.cd7_canvass_results` AS cr
  LEFT JOIN `{{external_project_id}}.{{external_dataset}}.cln_catalist__models` AS m
    ON cr.DWID = m.dwid
  WHERE m.catalistmodel_voteprop2025 IS NOT NULL
  GROUP BY 1, 2
),
income_order AS (
  SELECT bin, pos
  FROM UNNEST([
    'Less than $20,000',
    '$20,000 - $30,000',
    '$30,000 - $50,000',
    '$50,000 - $75,000',
    '$75,000 - $100,000',
    '$100,000 - $150,000',
    'Greater than $150,000'
  ]) AS bin WITH OFFSET pos
)
SELECT t.*
FROM t
LEFT JOIN income_order o ON t.income_bin = o.bin
ORDER BY
  CASE t.canvass_result WHEN 'Canvassed' THEN 1 ELSE 2 END,
  COALESCE(o.pos, 999)

)