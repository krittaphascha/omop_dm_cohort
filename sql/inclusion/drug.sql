WITH drug_order AS (
    SELECT  d.person_id,
            d.drug_source_value,
            MIN(d.drug_exposure_start_date) as first_drug_start_date,
            ROW_NUMBER() OVER(PARTITION BY d.person_id ORDER BY d.drug_exposure_start_date) as rn
    FROM [omop].[drug_exposure] d
    WHERE d.drug_concept_id IN (
        SELECT drug_concept_id 
			    FROM 
			        omop.mart__drug_exposure mde
			    WHERE 
			        drug_source_value IN (
			            'GLUTB1', 'GLUTB5', 'BYEI10', 'DAOT', 'GLITB', 'GLITBC', 'DIATM',
			        'DIATM3', 'DIATM60', 'GLITC', 'GLITCM3', 'GLITCM6', 'GLITD80',
			        'GLITG80', 'AMAT2', 'AMAT3', 'AMAT4', 'GLITD2', 'GLITD4', 'GLITG2',
			        'GLITL2', 'GLITL3', 'GLITL4', 'GLIT', 'GLITP5', 'MINT5', 'GLUTR',
			        'NOVIR1', 'NOVIM1', 'NOVIMF', 'LEVIL', 'LANIC', 'LANIT', 'SEMI',
			        'TOUI', 'APIIP', 'APRIP', 'BIOIN', 'GENIN', 'GENINC', 'HUMIN',
			        'HUMINC1', 'INSI', 'INSIC1', 'WININ10', 'HUMILC1', 'HUMIM5',
			        'HUMIMC1', 'ACTIC1', 'ACTIPH', 'BIOIR', 'GENIR', 'GENIRC', 'HUMIR',
			        'WINIR10', 'BIOIM', 'GENIM', 'GENIMC', 'GENIMC50', 'HUMI7',
			        'HUMIC1', 'MIXI', 'MIXIP1', 'WINIM10', 'GLUT5', 'GLUT8', 'GLUTXR',
			        'GLUTXR1', 'METTDE1', 'METTDE75', 'METTF', 'METTF8', 'METTFM5',
			        'METTFM8', 'GLUTV505', 'GLUTV525', 'ACTTM15', 'AVATM', 'JANTM50',
			        'JANTM5010', 'JANTMX5', 'JANTMX10', 'ACTTO1', 'ACTTO3', 'ACTTO45',
			        'PIOT15', 'PIOT30', 'NOVT1', 'NOVT2', 'NOVT5', 'AVAT4', 'AVAT8',
			        'ONGT5', 'JANT1', 'JANT5', 'GALT5', 'VILTD', 'BAST2', 'BAST3',
			        'SAXI', 'VICIP18', 'GALTM500', 'GALTM1000', 'TRATJ5', 'KOMT2',
			        'KOMT5', 'AMATM', 'TRATD251', 'TRATD255', 'FORT10', 'NEST',
			        'OSET2515', 'OSET2530', 'JART10', 'JART25', 'TREIS', 'JARTD5',
			        'JARTD125', 'INVT100', 'INVT300', 'LUST5', 'LUST25', 'XIGT5',
			        'XIGT10', 'ZEMT', 'GLYT10', 'GLYT25', 'RYZI', 'TRUI15', 'TRUI75',
			        'XULI', 'SOLIQ33', 'SOLIQ50', 'ZAFT', 'OZEI1', 'OZEI05', 'OZEI025',
			        'RYBT3', 'RYBT7', 'RYBT14', 'TENT20', 'SUGT5', 'ZEMTM'
			    ) AND drug_concept_id != 0)
    AND d.drug_exposure_start_date BETWEEN '2013-06-01' AND '2023-09-30'
    GROUP BY d.person_id, d.drug_exposure_start_date, d.drug_source_value
), -- Full generic names drug list is available in doc/steps.md

p_info AS ( -- Get patients info
    SELECT p.person_id, p.year_of_birth
    FROM omop.person p
)

SELECT d.person_id,
       d.drug_source_value,
         d.first_drug_start_date,
       (YEAR(d.first_drug_start_date) - p.year_of_birth) AS age_at_first_drug
FROM drug_order d
JOIN p_info p ON d.person_id = p.person_id
WHERE d.rn = 1
