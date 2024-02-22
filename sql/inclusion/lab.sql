-- getting glucose level data
WITH fbs AS (
    SELECT  m.measurement_id, 
            m.person_id, 
            m.measurement_source_value, 
            m.measurement_concept_id, 
            m.[_measurement_name], 
            m.value_source_value as value,
            m.measurement_datetime
    FROM [cdm].[measurement] m
    WHERE m.measurement_concept_id = 3004501
    AND m.measurement_datetime BETWEEN '2013-06-01' AND '2023-09-30'
),

-- getting hba1c data
hba1c AS (
    SELECT  m.measurement_id, 
            m.person_id, 
            m.measurement_source_value,    
            m.measurement_concept_id, 
            m.[_measurement_name], 
            m.value_source_value as value,
            m.measurement_datetime
    FROM [cdm].[measurement] m
    WHERE m.measurement_concept_id = 3004410
    AND m.measurement_datetime BETWEEN '2013-06-01' AND '2023-09-30'
),

-- getting ogtt data
-- ** this criteria have been modified from the original P'Burin cohort
-- ** because OMOP concept code for 1st step of OGTT will include other glucose level lab
-- ** so we will use OGTT >= 200 criteria at step 2, 3, 4 of OGTT instead
ogtt AS (
    SELECT  m.measurement_id, 
            m.person_id, 
            m.measurement_source_value, 
            m.measurement_concept_id, 
            m.[_measurement_name], 
            m.value_source_value as value
    FROM [cdm].[measurement] m
    WHERE m.measurement_concept_id IN (3006717, 3014716, 3027457)
    AND m.measurement_datetime BETWEEN '2013-06-01' AND '2023-09-30'
),

fbs_crit AS (
    SELECT  f.person_id,
            COUNT(*) as cnt
    FROM fbs f
    WHERE TRY_CAST(f.value as int) >= 126
    GROUP BY f.person_id
),

hba1c_crit AS (
    SELECT  h.person_id,
            COUNT(*) as cnt
    FROM hba1c h
    WHERE TRY_CAST(h.value as DECIMAL(4,1)) >= 6.5
    GROUP BY h.person_id
),

fbs_hb_crit AS (
    SELECT  f.person_id, 
                f.cnt as f_count, 
                h.cnt as h_count,
                f.cnt + h.cnt as total_count
    FROM fbs_crit f
    JOIN hba1c_crit h on f.person_id = h.person_id
),

ogtt_hn AS (
    SElECT  o.person_id
    FROM ogtt o
    WHERE TRY_CAST(o.value as float) >= 200
    GROUP BY o.person_id
), -- n_patients = 1737

fbs_hn AS (
    SELECT person_id
    FROM fbs_crit
    WHERE cnt > 2
), -- n_patients = 57427

hba1c_hn AS (
    SELECT person_id
    FROM hba1c_crit
    WHERE cnt > 2
), -- n_patients = 58969

fbs_hb_hn AS (
    SELECT person_id
    FROM fbs_hb_crit
    WHERE total_count = 2
) -- n_patients = 8584

-- getting the final list of patients
SELECT person_id
FROM hba1c_hn
UNION 
SELECT person_id
FROM fbs_hn
UNION
SELECT person_id
FROM fbs_hb_hn
UNION
SELECT person_id
FROM ogtt_hn
-- total number 72092 pt.

--------------------------------------------
--- Note
-- HbA1c Use measurement_source_value = 5099
-- concept = 3004410

-- Glucose concept = 3004501
-- 400317	Blood sugar
-- 0322	Glucose tolerance 1
-- 5103	Glucose heparin
-- 0013	Glucose (NaF)

-- OGTT
-- measurement_source_value = '0321','0322','0323','0324','0325','0326'
-- concept = 3014716
-- 3004501	0322 -- 1st step of OGTT --> means fasting glucose
-- 3006717	0324
-- 3014716	0323
-- 3027457	0325
