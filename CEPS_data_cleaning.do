***Database Merging***
use cepsw1studenten.dta, clear	// Open T1 student survey database file
merge 1:1 ids using cepsw2studenten.dta	// Merge T2 student survey database using Student ID 'ids'
drop if _merge == 1 | _merge == 2	// Delete data in T2 student database that cannot match with T1 `ids`
drop _merge

merge 1:1 ids using cepsw1parenten.dta	// Merge T1 parent survey database using Student ID 'ids'
drop if _merge == 1 | _merge == 2	// Delete data in T1 parent database that cannot match with T1 `ids`
drop _merge

merge 1:1 ids using cepsw2parenten.dta	// Merge T2 parent survey database using Student ID 'ids'
drop if _merge == 1 | _merge == 2	// Delete data in T2 parent database that cannot match with T1 `ids`

summarize ids

***Data Cleaning***
*Educational aspiration
recode c22 (10=.)(1=6)(2 3 =9)(4 5=12)(6=15)(7=16)(8=19)(9=22), gen(t1_educational_aspiration)	// Recode dependent variable 'T1 Educational aspiration'

recode w2b18 (10=.)(1=6)(2 3 =9)(4 5=12)(6=15)(7=16)(8=19)(9=22), gen(t2_educational_aspiration)	// Recode dependent variable 'T2 Educational aspiration'
summarize t1_educational_aspiration t2_educational_aspiration


*Risk factors coding
recode a10 (1=1) (2/3=0), gen(t1_physical_risk)	// Recode 'T1 serious illness'
gen t2_physical_risk = 0 if !missing(w2c0701a, w2c0702a, w2c0703a, w2c0704a, w2c0705a, w2c0706a) // Recode 'T2 serious illness'
replace t2_physical_risk = 1 if w2c0701a == 3 | w2c0702a == 3 | w2c0703a == 3 | w2c0704a == 3 | w2c0705a == 3 | w2c0706a == 3


egen t1_psychological_risk = rowmean(a1801 a1802 a1803 a1804 a1805)		//Recode 'T1 excessive negative emotions'
egen t2_psychological_risk = rowmean(w2c2501 w2c2502 w2c2503 w2c2504 w2c2506)	// Recode 'T2 excessive negative emotions'


gen t1_family_poverty_risk = steco_5c	// Recode 'T1 family poverty'
gen t2_family_poverty_risk = w2a09	// Recode 'T2 family poverty'


recode be22 (1=1) (2=0), gen(t1_family_illness_risk)	// Recode 'T1 serious illness of a family member'
recode w2be26 (1=1) (2=0), gen(t2_family_illness_risk)	// Recode 'T2 serious illness of a family member'


gen vulnerable_child = cond(( (t1_physical_risk == 1) + (t1_psychological_risk > 3) + (t1_family_poverty_risk < 3) + (t1_family_illness_risk == 1) ) >= 2, 1, 0)
ta vulnerable_child
bysort vulnerable_child: summarize t1_educational_aspiration t2_educational_aspiration

*School support factors coding
gen t1_teacher = c1704	// Recode 'T1 My teacher and I have a good relationship'
gen t2_teacher = w2b0603	// Recode 'T2 My teacher and I have a good relationship'

gen t1_peer = c1706		// Recode 'T1 My classmates are very nice to me'
gen t2_peer = w2b0605	// Recode 'T2 My classmates are very nice to me'

gen t1_class = c1708	// Recode 'T1 The class atmosphere is good'
gen t2_class = w2b0606	// Recode 'T2 The class atmosphere is good'

gen t1_school = c1710 	// Recode 'T1 The school atmosphere is good'
gen t2_school = w2b0608	// Recode 'T2 The school atmosphere is good'

*Grouping and control variables
gen hukou = sthktype	// Recode 'current Hukou'(1=rural Hukou) 
gen gender = stsex	// Recode 'Gender'(1=male)
gen total_score = tr_chn + tr_mat + tr_eng  // Recode 'performance' (1=good performance)
egen score_standard = std(total_score)
recode score_standard (1/max = 1) (min/-1 = 0) (else= .), gen(academic_performance) 

recode a03 (1 = 0) (else = 1) , gen(ethnicity) 	//Recode 'ethnic nationality'(1=Ethnic Minority, 0=Han ethnicity )
recode a01 (1 = 1) (2 = 0) , gen(only_child) 	//Recode 'Only child'(1=only child )
recode a08 (1 = 0) (2 = 1) , gen(educational_migration) 	//Recode 'Educational Migration'(1=Not live in the local county/district )
gen parents_education = max(b06, b07)
recode parents_education (1=0)(2 =6)(3 4 =9)(5 6=12)(7=15)(8=16)(9=19)	//Recode 'Parents' highest educational level'


summarize t1_physical_risk t2_physical_risk t1_psychological_risk t2_psychological_risk t1_family_poverty_risk ///
	t2_family_poverty_risk t1_family_illness_risk t2_family_illness_risk t1_teacher t2_teacher ///
	t1_peer t2_peer t1_class t2_class t1_school t2_school t1_educational_aspiration t2_educational_aspiration ///
	hukou gender academic_performance ethnicity only_child educational_migration parents_education
	 
save mergedata.dta, replace
