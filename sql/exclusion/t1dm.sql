WITH desc_con AS ( -- All descendants of the 201826 T2DM SNOMED concept
    SELECT c.descendant_concept_id
    FROM omop.concept_ancestor c
    WHERE c.ancestor_concept_id = 201254 -- base query
),

p_info AS ( -- Get the year of birth for each patient
    SELECT  p.person_id,
            p.year_of_birth
    FROM omop.person p
),

diag_info AS ( -- get the first diagnosis of T2DM for each patient
    SELECT  co.person_id,
            co.condition_concept_id,
            MIN(co.condition_start_datetime) AS first_diag,
            ROW_NUMBER() OVER(PARTITION BY co.person_id ORDER BY co.condition_start_datetime) as rn
    FROM omop.condition_occurrence co
    JOIN desc_con d ON co.condition_concept_id = d.descendant_concept_id
    GROUP BY co.person_id, co.condition_concept_id, co.condition_start_datetime
)

SELECT  d.person_id,
        d.condition_concept_id,
        d.first_diag,
        (YEAR(d.first_diag) - p.year_of_birth) AS age_at_first_diag
FROM diag_info d
JOIN p_info p ON d.person_id = p.person_id
WHERE d.rn = 1