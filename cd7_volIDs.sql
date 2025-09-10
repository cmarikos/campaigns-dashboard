SELECT DISTINCT
sr.DWID
, COALESCE(vp.likely_cell_phone, vp.likely_land_phone) AS phone_number
, INITCAP(v.firstname) AS firstname
, INITCAP(v.lastname) AS lastname
, INITCAP(v.regdeliveryaddrline) AS address
, INITCAP(v.regaddrcity) AS city
, v.regaddrstate AS state
, v.mailaddrzip AS zip
FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_survey_responses` AS sr

LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__person` AS v
  ON sr.DWID = v.DWID

LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__phones` AS vp
  ON v.DWID = vp.dwid

WHERE sr.SurveyQuestionLongName = '2025 Volunteer Ask'
  AND sr.SurveyResponseName = 'Yes'
  AND COALESCE(vp.likely_cell_phone, vp.likely_land_phone) IS NOT NULL
  AND v.regaddrstate = 'AZ'