SELECT
sr.SurveyQuestionLongName
, CASE
    WHEN sr.SurveyResponseName = 'strong support' THEN 'Strong Grijalva'
    WHEN sr.SurveyResponseName = 'lean support' THEN 'Lean Grijalva'
    WHEN sr.SurveyResponseName = 'weak support' THEN 'Weak Grijalva'
    WHEN sr.SurveyResponseName = 'no response' THEN 'No Response'
    WHEN sr.SurveyResponseName = 'unsure' THEN 'Undecided'
    ELSE  sr.SurveyResponseName
  END AS SurveyResponseName
, COUNT(sr.DWID)
FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_survey_responses` AS sr

GROUP BY 1,2
ORDER BY 1,2