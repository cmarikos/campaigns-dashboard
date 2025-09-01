CREATE OR REPLACE VIEW `{{project_id}}.{{analytics_dataset}}.deep_canvass_notes` AS (
SELECT
--cw.pctnum
 CAST(c.DateCanvassed AS DATE) AS DateCanvassed
, c.VanID
, vb.vb_tsmart_first_name
, vb.vb_tsmart_last_name
, vb.vb_tsmart_city
, n.NoteText
, c.CanvassedBy

FROM `{{project_id}}.raze_ngpvan_data.TSM_OneAZ_ContactsContacts_VF` AS c

LEFT JOIN `{{project_id}}.targetsmart_AZ.voter_base_latest` as vb
  ON c.VanID = vb.vb_smartvan_id

-- dictionary table for contactypeid to contact type name since the CRM pipeline is... lacking
LEFT JOIN `{{project_id}}.{{analytics_dataset}}.contacttypeid` AS t
  ON c.ContactTypeID = t.ContactTypeID

-- targetsmart precinct id to pctnum crosswalk so I can map canvassing in looker, details in az_precincts repo on how to make this
INNER JOIN `{{project_id}}.{{crosswalk_dataset}}.targetsmart_pctnum_crosswalk` AS cw
  ON vb.vb_vf_national_precinct_code = cw.vb_vf_national_precinct_code

LEFT JOIN `{{project_id}}.raze_ngpvan_data.TSM_OneAZ_ContactsNotes_VF` AS n
  ON c.VanID = n.VanID

WHERE CAST(c.DateCanvassed AS DATE) > '2025-01-01'
  AND c.CanvassedBy IS NOT NULL
  AND ContactTypeName = 'Walk'
  --AND n.NoteText IS NOT NULL
  AND (cw.pctnum LIKE 'YU%' OR cw.pctnum LIKE 'PM%')
)
