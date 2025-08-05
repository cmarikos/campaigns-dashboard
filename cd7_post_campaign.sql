CREATE OR REPLACE VIEW `prod-organize-arizon-4e1c0a83.viewers_dataset.cd7_2025_dashboard_geo` AS(

  WITH canvassed AS(
    SELECT 
    COUNT(s.DWID) AS canvassed
    , s.`Date Canvassed` AS date_canvassed
    , CASE 
        WHEN s.`Date Canvassed` <= '2025-07-15' THEN 'pre-primary'
        WHEN s.`Date Canvassed` > '2025-07-15' THEN 'post-primary'
        ELSE null
      END AS campaign_phase
    , cw.pctnum


    FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_special` AS s

    -- join nation file limit to AZ to remove multi state dupes
    LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__district` AS d
      ON s.DWID = d.dwid 

    -- join in crosswalk for pctnum
    LEFT JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.catalist_pctnum_crosswalk_native` AS cw
      ON d.uniqueprecinctcode = cw.uniqueprecinctcode

    -- national file has records for all state registrations, need to limit to AZ only
    WHERE d.state = 'AZ'
      AND s.Result = 'Canvassed'

    GROUP BY 2,3,4
    ORDER BY 2,3,4
  )

  , attempted AS(
    SELECT 
    COUNT(s.DWID) AS attempted
    , s.`Date Canvassed` AS date_canvassed
    , CASE 
        WHEN s.`Date Canvassed` <= '2025-07-15' THEN 'pre-primary'
        WHEN s.`Date Canvassed` > '2025-07-15' THEN 'post-primary'
        ELSE null
      END AS campaign_phase
    , cw.pctnum


    FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_special` AS s

    -- join nation file limit to AZ to remove multi state dupes
    LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__district` AS d
      ON s.DWID = d.dwid 

    -- join in crosswalk for pctnum
    LEFT JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.catalist_pctnum_crosswalk_native` AS cw
      ON d.uniqueprecinctcode = cw.uniqueprecinctcode

    -- national file has records for all state registrations, need to limit to AZ only
    WHERE d.state = 'AZ'

    GROUP BY 2,3,4
    ORDER BY 2,3,4
  )

  SELECT
    c.pctnum
    , c.canvassed
    , a.attempted
    , c.campaign_phase
    , g.COUNTY
    , g.GEOMETRY
  FROM canvassed AS c
  LEFT JOIN attempted AS a
    ON c.pctnum = a.pctnum AND c.date_canvassed = a.date_canvassed

  LEFT JOIN `prod-organize-arizon-4e1c0a83.geofiles.az_precincts_geo` AS g
    ON c.pctnum = g.PCTNUM

  WHERE g.CONGRESSIO = 7
)