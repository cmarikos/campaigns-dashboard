-- updated 8/21/2025

CREATE OR REPLACE VIEW `prod-organize-arizon-4e1c0a83.viewers_dataset.campaigns_deep_canvass` AS(
WITH doors AS(
SELECT 
cw.pctnum
, COUNT(DISTINCT vb.vb_voterbase_household_id||CAST(c.DateCanvassed AS DATE)) AS doors
FROM `prod-organize-arizon-4e1c0a83.raze_ngpvan_data.TSM_OneAZ_ContactsContacts_VF` AS c

LEFT JOIN `prod-organize-arizon-4e1c0a83.targetsmart_AZ.voter_base_latest` as vb
  ON c.VanID = vb.vb_smartvan_id

-- dictionary table for contactypeid to contact type name since the VAN pipeline is... lacking
LEFT JOIN `prod-organize-arizon-4e1c0a83.viewers_dataset.contacttypeid` AS t
  ON c.ContactTypeID = t.ContactTypeID

-- targetsmart precinct id to pctnum crosswalk so I can map canvassing in looker, details in az_precincts repo on how to make this
INNER JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.targetsmart_pctnum_crosswalk` AS cw
  ON vb.vb_vf_national_precinct_code = cw.vb_vf_national_precinct_code

  WHERE CAST(c.DateCanvassed AS DATE) > '2025-01-01'
  AND c.CanvassedBy IS NOT NULL
  AND t.ContactTypeName = 'Walk'
  AND (cw.pctnum LIKE 'YU%' OR cw.pctnum LIKE 'PM%' OR cw.pctnum LIKE 'CH%')

  GROUP BY 1
),

attempts AS(
SELECT 
cw.pctnum
, COUNT(c.VanID) AS attempts
FROM `prod-organize-arizon-4e1c0a83.raze_ngpvan_data.TSM_OneAZ_ContactsContacts_VF` AS c

LEFT JOIN `prod-organize-arizon-4e1c0a83.targetsmart_AZ.voter_base_latest` as vb
  ON c.VanID = vb.vb_smartvan_id

-- dictionary table for contactypeid to contact type name since the VAN pipeline is... lacking
LEFT JOIN `prod-organize-arizon-4e1c0a83.viewers_dataset.contacttypeid` AS t
  ON c.ContactTypeID = t.ContactTypeID

-- targetsmart precinct id to pctnum crosswalk so I can map canvassing in looker, details in az_precincts repo on how to make this
INNER JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.targetsmart_pctnum_crosswalk` AS cw
  ON vb.vb_vf_national_precinct_code = cw.vb_vf_national_precinct_code

  WHERE CAST(c.DateCanvassed AS DATE) > '2025-01-01'
  AND c.CanvassedBy IS NOT NULL
  AND t.ContactTypeName = 'Walk'
  AND (cw.pctnum LIKE 'YU%' OR cw.pctnum LIKE 'PM%' OR cw.pctnum LIKE 'CH%')

  GROUP BY 1
),

contacts AS(
SELECT 
cw.pctnum
,  COUNT(c.VanID) AS contacts
FROM `prod-organize-arizon-4e1c0a83.raze_ngpvan_data.TSM_OneAZ_ContactsContacts_VF` AS c

LEFT JOIN `prod-organize-arizon-4e1c0a83.targetsmart_AZ.voter_base_latest` as vb
  ON c.VanID = vb.vb_smartvan_id

-- dictionary table for contactypeid to contact type name since the VAN pipeline is... lacking
LEFT JOIN `prod-organize-arizon-4e1c0a83.viewers_dataset.contacttypeid` AS t
  ON c.ContactTypeID = t.ContactTypeID

-- ditto above comment for this table
LEFT JOIN `prod-organize-arizon-4e1c0a83.viewers_dataset.resultid` AS r 
  ON c.ResultID = r.ResultID

-- targetsmart precinct id to pctnum crosswalk so I can map canvassing in looker, details in az_precincts repo on how to make this
INNER JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.targetsmart_pctnum_crosswalk` AS cw
  ON vb.vb_vf_national_precinct_code = cw.vb_vf_national_precinct_code

  WHERE CAST(c.DateCanvassed AS DATE) > '2025-01-01'
  AND c.CanvassedBy IS NOT NULL
  AND t.ContactTypeName = 'Walk'
  AND r.ResultShortName = 'Canvassed'
  AND (cw.pctnum LIKE 'YU%' OR cw.pctnum LIKE 'PM%' OR cw.pctnum LIKE 'CH%')

  GROUP BY 1
)

SELECT 
pg.GEOMETRY
, pg.PCTNUM 
, pg.COUNTY
, a.attempts
, d.doors
, c.contacts
FROM `prod-organize-arizon-4e1c0a83.geofiles.az_precincts_geo` AS pg

INNER JOIN attempts AS a
 ON pg.PCTNUM = a.pctnum

INNER JOIN doors AS d
  ON pg.PCTNUM = d.pctnum

INNER JOIN contacts AS c
  ON pg.PCTNUM = c.pctnum

)
