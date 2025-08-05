WITH dems AS(
  SELECT DISTINCT
    vb.vb_vf_cd
    ,
    , COUNT(vb.voterbase_id) AS registered_dems
  FROM `prod-organize-arizon-4e1c0a83.targetsmart_AZ.voter_base_latest` AS vb

  LEFT JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.targetsmart_pctnum_crosswalk` AS cw

  WHERE vb_tsmart_state = 'AZ'
    AND vb_vf_cd = 7
    AND vb_vf_party = 'Democrat'

  GROUP BY 1
  ORDER BY 1 
)



SELECT
  cd.GEOMETRY
  , cd.DISTRICT
  , cd.Representatives
  , u.registered_voters
  , u.registered_dems
FROM dems AS d

LEFT JOIN
)


