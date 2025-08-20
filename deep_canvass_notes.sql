CREATE OR REPLACE VIEW `prod-organize-arizon-4e1c0a83.viewers_dataset.deep_canvass_notes` AS (
SELECT DISTINCT
--cw.pctnum
 CAST(c.DateCanvassed AS DATE) AS DateCanvassed
, c.VanID
, vb.vb_tsmart_first_name
, vb.vb_tsmart_last_name
, vb.vb_tsmart_city
, n.NoteText
, c.CanvassedBy

FROM `prod-organize-arizon-4e1c0a83.raze_ngpvan_data.TSM_OneAZ_ContactsContacts_VF` AS c

LEFT JOIN `prod-organize-arizon-4e1c0a83.targetsmart_AZ.voter_base_latest` as vb
  ON c.VanID = vb.vb_smartvan_id

-- dictionary table for contactypeid to contact type name since the VAN pipeline is... lacking
LEFT JOIN `prod-organize-arizon-4e1c0a83.viewers_dataset.contacttypeid` AS t
  ON c.ContactTypeID = t.ContactTypeID

-- targetsmart precinct id to pctnum crosswalk so I can map canvassing in looker, details in az_precincts repo on how to make this
INNER JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.targetsmart_pctnum_crosswalk` AS cw
  ON vb.vb_vf_national_precinct_code = cw.vb_vf_national_precinct_code

LEFT JOIN `prod-organize-arizon-4e1c0a83.raze_ngpvan_data.TSM_OneAZ_ContactsNotes_VF` AS n
  ON c.VanID = n.VanID

LEFT JOIN `prod-organize-arizon-4e1c0a83.viewers_dataset.ResultsID` AS r
  ON c.ResultID = r.ResultID

WHERE CAST(c.DateCanvassed AS DATE) > '2025-01-01'
  AND c.CanvassedBy IS NOT NULL
  AND ContactTypeName = 'Walk'
  AND r.ResultShortName = 'Canvassed'
  AND (cw.pctnum LIKE 'YU%' OR cw.pctnum LIKE 'PM%')
)
