WITH icustay AS (
    SELECT HADM_ID, SUM(LOS) AS LOS_ICU 
    FROM mimiciii.icustays 
    GROUP BY HADM_ID
), 
callout AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS CALLOUT_COUNT 
    FROM mimiciii.callout 
    GROUP BY HADM_ID
),
diags AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS DIAG_COUNT 
    FROM mimiciii.diagnoses_icd 
    GROUP BY HADM_ID
),
preps AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS PRES_COUNT 
    FROM mimiciii.prescriptions 
    GROUP BY HADM_ID
),
procs AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS PROC_COUNT 
    FROM mimiciii.procedures_icd 
    GROUP BY HADM_ID
),
cpts AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS CPT_COUNT 
    FROM mimiciii.cptevents 
    GROUP BY HADM_ID
),
labs AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS LAB_COUNT 
    FROM mimiciii.labevents 
    GROUP BY HADM_ID
),
inputs_cv AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS INPUTS_CV_COUNT 
    FROM mimiciii.inputevents_cv 
    GROUP BY HADM_ID
),
inputs_mv AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS INPUTS_MV_COUNT 
    FROM mimiciii.inputevents_mv 
    GROUP BY HADM_ID
),
outputs AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS OUTPUT_COUNT 
    FROM mimiciii.outputevents 
    GROUP BY HADM_ID
),
transfers AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS TRANSFER_COUNT 
    FROM mimiciii.transfers 
    GROUP BY HADM_ID
),
micros AS (
    SELECT HADM_ID, COUNT(HADM_ID) AS MICRO_COUNT 
    FROM mimiciii.microbiologyevents 
    GROUP BY HADM_ID
),
diafeature AS (
    SELECT 
        hadm_id,
        MAX(CASE 
            WHEN substring(icd9_code,1,3) = '038' THEN 1
            WHEN substring(icd9_code,1,4) in ('0202','7907','1179','1125') THEN 1
            WHEN substring(icd9_code,1,5) = '11281' THEN 1
            ELSE 0 
        END) AS sepsis,
        MAX(CASE 
            WHEN substring(icd9_code,1,4) in ('7991') THEN 1
            WHEN substring(icd9_code,1,5) in ('51881','51882','51885','78609') THEN 1
            ELSE 0 
        END) AS respiratory,
        MAX(CASE 
            WHEN substring(icd9_code,1,4) in ('4580','7855','4580','4588','4589','7963') THEN 1
            WHEN substring(icd9_code,1,5) in ('785.51','785.59') THEN 1
            ELSE 0 
        END) AS cardiovascular,
        MAX(CASE 
            WHEN substring(icd9_code,1,3) in ('584','580','585') THEN 1
            ELSE 0 
        END) AS renal,
        MAX(CASE 
            WHEN substring(icd9_code,1,3) in ('570') THEN 1
            WHEN substring(icd9_code,1,4) in ('5722','5733') THEN 1
            ELSE 0 
        END) AS hepatic,
        MAX(CASE 
            WHEN substring(icd9_code,1,4) in ('2862','2866','2869','2873','2874','2875') THEN 1
            ELSE 0 
        END) AS hematologic,
        MAX(CASE 
            WHEN substring(icd9_code,1,4) in ('2762') THEN 1
            ELSE 0 
        END) AS metabolic,
        MAX(CASE 
            WHEN substring(icd9_code,1,3) in ('293') THEN 1
            WHEN substring(icd9_code,1,4) in ('3481','3483') THEN 1
            WHEN substring(icd9_code,1,5) in ('78001','78009') THEN 1
            ELSE 0 
        END) AS neurologic
    FROM mimiciii.diagnoses_icd
    GROUP BY hadm_id
)
SELECT 
    adm.subject_id, 
    adm.hadm_id,
    coalesce(icustay.LOS_ICU, 0) AS LOS_ICU,
    coalesce(callout.CALLOUT_COUNT, 0) AS CALLOUT_COUNT,
    coalesce(diags.DIAG_COUNT, 0) AS DIAG_COUNT,
    coalesce(preps.PRES_COUNT, 0) AS PRES_COUNT,
    coalesce(procs.PROC_COUNT, 0) AS PROC_COUNT,
    coalesce(cpts.CPT_COUNT, 0) AS CPT_COUNT,
    coalesce(labs.LAB_COUNT, 0) AS LAB_COUNT,
    coalesce(inputs_cv.INPUTS_CV_COUNT, 0) AS INPUTS_CV_COUNT,
    coalesce(inputs_mv.INPUTS_MV_COUNT, 0) AS INPUTS_MV_COUNT,
    coalesce(outputs.OUTPUT_COUNT, 0) AS OUTPUT_COUNT,
    coalesce(transfers.TRANSFER_COUNT, 0) AS TRANSFER_COUNT,
    coalesce(micros.MICRO_COUNT, 0) AS MICRO_COUNT,
    coalesce(diafeature.sepsis, 0) AS sepsis,
    CASE
        WHEN coalesce(co_dx.respiratory, 0) = 1 OR coalesce(co_proc.respiratory, 0) = 1 
            OR coalesce(co_dx.cardiovascular, 0) = 1 
            OR coalesce(co_dx.renal, 0) = 1 OR coalesce(co_proc.renal, 0) = 1 
            OR coalesce(co_dx.hepatic, 0) = 1 
            OR coalesce(co_dx.hematologic, 0) = 1 
            OR coalesce(co_dx.metabolic, 0) = 1 
            OR coalesce(co_dx.neurologic, 0) = 1 OR coalesce(co_proc.neurologic, 0) = 1
        THEN 1
        ELSE 0 
    END AS organ_failure,
    coalesce(co_dx.respiratory, 0) AS respiratory,
    coalesce(co_dx.cardiovascular, 0) AS cardiovascular,
    coalesce(co_dx.renal, 0) AS renal,
    coalesce(co_dx.hepatic, 0) AS hepatic,
    coalesce(co_dx.hematologic, 0) AS hematologic,
    coalesce(co_dx.metabolic, 0) AS metabolic,
    coalesce(co_dx.neurologic, 0) AS neurologic,
    coalesce(vitals.HeartRate_Min, 0) AS HeartRate_Min,
    coalesce(vitals.HeartRate_Max, 0) AS HeartRate_Max,
    coalesce(vitals.HeartRate_Mean, 0) AS HeartRate_Mean,
    coalesce(vitals.SysBP_Min, 0) AS SysBP_Min,
    coalesce(vitals.SysBP_Max, 0) AS SysBP_Max,
    coalesce(vitals.SysBP_Mean, 0) AS SysBP_Mean,
    coalesce(vitals.DiasBP_Min, 0) AS DiasBP_Min,
    coalesce(vitals.DiasBP_Max, 0) AS DiasBP_Max,
    coalesce(vitals.DiasBP_Mean, 0) AS DiasBP_Mean,
    coalesce(vitals.MeanBP_Min, 0) AS MeanBP_Min,
    coalesce(vitals.MeanBP_Max, 0) AS MeanBP_Max,
    coalesce(vitals.MeanBP_Mean, 0) AS MeanBP_Mean,
    coalesce(vitals.RespRate_Min, 0) AS RespRate_Min,
    coalesce(vitals.RespRate_Max, 0) AS RespRate_Max,
    coalesce(vitals.RespRate_Mean, 0) AS RespRate_Mean,
    coalesce(vitals.TempC_Min, 0) AS TempC_Min,
    coalesce(vitals.TempC_Max, 0) AS TempC_Max,
    coalesce(vitals.TempC_Mean, 0) AS TempC_Mean,
    coalesce(vitals.SpO2_Min, 0) AS SpO2_Min,
    coalesce(vitals.SpO2_Max, 0) AS SpO2_Max,
    coalesce(vitals.SpO2_Mean, 0) AS SpO2_Mean,
    coalesce(vitals.Glucose_Min, 0) AS Glucose_Min,
    coalesce(vitals.Glucose_Max, 0) AS Glucose_Max,
    coalesce(vitals.Glucose_Mean, 0) AS Glucose_Mean
FROM mimiciii.admissions AS adm
LEFT JOIN mimiciii.patients AS pts ON adm.subject_id = pts.subject_id
LEFT JOIN icustay ON adm.hadm_id = icustay.hadm_id
LEFT JOIN callout ON adm.hadm_id = callout.hadm_id
LEFT JOIN diags ON adm.hadm_id = diags.hadm_id
LEFT JOIN preps ON adm.hadm_id = preps.hadm_id
LEFT JOIN procs ON adm.hadm_id = procs.hadm_id
LEFT JOIN cpts ON adm.hadm_id = cpts.hadm_id
LEFT JOIN labs ON adm.hadm_id = labs.hadm_id
LEFT JOIN inputs_cv ON adm.hadm_id = inputs_cv.hadm_id
LEFT JOIN inputs_mv ON adm.hadm_id = inputs_mv.hadm_id
LEFT JOIN outputs ON adm.hadm_id = outputs.hadm_id
LEFT JOIN transfers ON adm.hadm_id = transfers.hadm_id
LEFT JOIN micros ON adm.hadm_id = micros.hadm_id
LEFT JOIN diafeature ON adm.hadm_id = diafeature.hadm_id
LEFT JOIN vitals ON adm.hadm_id = vitals.hadm_id;
