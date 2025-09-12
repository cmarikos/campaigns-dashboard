CREATE OR REPLACE VIEW `prod-organize-arizon-4e1c0a83.viewers_dataset.cd7_2025_dashboard_geo` AS(

  WITH canvassed AS(
    SELECT 
    COUNT(s.DWID) AS canvassed
    , s.DateCanvassed
    , CASE 
        WHEN s.DateCanvassed <= '2025-07-15' THEN 'pre-primary'
        WHEN s.DateCanvassed > '2025-07-15' THEN 'post-primary'
        ELSE null
      END AS campaign_phase
    , cw.pctnum

    FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_canvass_results` AS s

    -- join nation file limit to AZ to remove multi state dupes
    LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__district` AS d
      ON s.DWID = d.dwid 

    -- join in crosswalk for pctnum
    LEFT JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.catalist_pctnum_crosswalk_native` AS cw
      ON d.uniqueprecinctcode = cw.uniqueprecinctcode

    -- national file has records for all state registrations, need to limit to AZ only
    WHERE d.state = 'AZ'
      AND s.ResultShortName = 'Canvassed'

    GROUP BY 2,3,4
    ORDER BY 2,3,4
  )

  , attempted AS(
    SELECT 
    COUNT(s.DWID) AS attempted
    , s.DateCanvassed
    , CASE 
        WHEN s.DateCanvassed <= '2025-07-15' THEN 'pre-primary'
        WHEN s.DateCanvassed > '2025-07-15' THEN 'post-primary'
        ELSE null
      END AS campaign_phase
    , cw.pctnum


    FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_canvass_results` AS s

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
  
  ,doors_canvassed AS(
    SELECT 
    COUNT(DISTINCT p.regaddrline1||s.DateCanvassed) AS doors_canvassed
    , s.DateCanvassed
    , CASE 
        WHEN s.DateCanvassed <= '2025-07-15' THEN 'pre-primary'
        WHEN s.DateCanvassed > '2025-07-15' THEN 'post-primary'
        ELSE null
      END AS campaign_phase
    , cw.pctnum

    FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_canvass_results` AS s

     -- join nation file limit to AZ to remove multi state dupes
    LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__district` AS d
      ON s.DWID = d.dwid 

    -- join in crosswalk for pctnum
    LEFT JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.catalist_pctnum_crosswalk_native` AS cw
      ON d.uniqueprecinctcode = cw.uniqueprecinctcode
    
    -- join in person table for reg address for door count
    LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__person` AS p
      ON s.DWID = p.dwid

    -- national file has records for all state registrations, need to limit to AZ only
    WHERE d.state = 'AZ'
      AND s.ResultShortName = 'Canvassed'

    GROUP BY 2,3,4
    ORDER BY 2,3,4
  )
  
  , doors_attempted AS(
   SELECT 
    COUNT(DISTINCT p.regaddrline1||s.DateCanvassed) AS doors_attempted
    , s.DateCanvassed
    , CASE 
        WHEN s.DateCanvassed <= '2025-07-15' THEN 'pre-primary'
        WHEN s.DateCanvassed > '2025-07-15' THEN 'post-primary'
        ELSE null
      END AS campaign_phase
    , cw.pctnum

    FROM `prod-organize-arizon-4e1c0a83.work_2025.cd7_canvass_results` AS s

     -- join nation file limit to AZ to remove multi state dupes
    LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__district` AS d
      ON s.DWID = d.dwid 

    -- join in crosswalk for pctnum
    LEFT JOIN `prod-organize-arizon-4e1c0a83.rich_christina_proj.catalist_pctnum_crosswalk_native` AS cw
      ON d.uniqueprecinctcode = cw.uniqueprecinctcode
    
    -- join in person table for reg address for door count
    LEFT JOIN `proj-tmc-mem-mvp.catalist_cleaned.cln_catalist__person` AS p
      ON s.DWID = p.dwid

    -- national file has records for all state registrations, need to limit to AZ only
    WHERE d.state = 'AZ'
     
    GROUP BY 2,3,4
    ORDER BY 2,3,4
  )

  SELECT
    c.pctnum
    , c.canvassed
    , a.attempted
    , da.doors_attempted
    , dc.doors_canvassed
    , c.campaign_phase
    , g.COUNTY
    , g.GEOMETRY
  FROM canvassed AS c
  LEFT JOIN attempted AS a
    ON c.pctnum = a.pctnum AND c.DateCanvassed = a.DateCanvassed
  
  LEFT JOIN doors_canvassed AS dc
    ON c.pctnum = dc.pctnum AND c.DateCanvassed = dc.DateCanvassed
  
  LEFT JOIN doors_attempted AS da
    ON c.pctnum = da.pctnum AND c.DateCanvassed = da.DateCanvassed
  
    
  LEFT JOIN `prod-organize-arizon-4e1c0a83.geofiles.az_precincts_geo` AS g
    ON c.pctnum = g.PCTNUM

)