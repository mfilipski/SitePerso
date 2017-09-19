program tabmat
	syntax varlist (min=2) [if] [in] [aweight fweight iweight] [, Mname(string) ] 
tokenize `varlist' 
local v1 `1'
local v2 `2'
qui tabulate `v1' `v2' `if' `in' [`weight' `exp'] , matcell(tmat) 

tempvar one g1 g2
* get the numbers of levels 
egen `g1' = group(`v1') 
qui sum `g1' 
local v1max = r(max) 
egen `g2' = group(`v2') 
qui sum `g2' 
local v2max = r(max) 

* extract the names for rows: (in the right order!)
qui gen `one' = 1 

preserve 
	qui decode `v1' , gen(nam`v1') 
	qui drop if missing(nam`v1')
	collapse (sum) `one', by(`v1' nam`v1') 
	local v1values
	forvalues j = 1/`v1max' { 
		local v1values `"`v1values' `"`=nam`v1'[`j']'"'"' 
} 
restore 
mat rownames tmat = `v1values' 

* extract the names for columns: (in the right order!)
preserve 
	qui decode `v2' , gen(nam`v2') 
	qui drop if missing(nam`v2')
	collapse (sum) `one', by(`v2' nam`v2') 
	local v2values
	forvalues j = 1/`v2max' { 
		local v2values `"`v2values' `"`=nam`v2'[`j']'"'"'
} 
restore 
mat colnames tmat = `v2values' 

* Also generate row and col matrices 
mat rowx = J(`v2max',1,1) 
mat mmrow = tmat*rowx
mata : st_matrix("tmatR", 100 * st_matrix("tmat") :/ st_matrix("mmrow"))
mat rownames tmatR = `v1values' 
mat colnames tmatR = `v2values' 

mat colx = J(1,`v1max',1) 
mat mmcol = colx*tmat
mata : st_matrix("tmatC", 100 * st_matrix("tmat") :/ st_matrix("mmcol"))
mat rownames tmatC = `v1values' 
mat colnames tmatC = `v2values' 

mat drop mmrow mmcol rowx colx 


* List the final three matrices:
if "`mname'" != "" {
	di "Chosen name for matrices is `mname'"
	mat rename tmat `mname' 
	mat rename tmatR  `mname'R 
	mat rename tmatC  `mname'C  
	display "************ MATRIX OF COUNTS ***********************************"
	tabulate `v1' `v2' `if' `in' [`weight' `exp']
	mat list `mname' 
	display ""
	display "************ MATRIX OF % WITHIN ROWS ****************************"
	tabulate `v1' `v2' `if' `in' [`weight' `exp'] , row nof
	mat list `mname'R 
	display ""
	display "************ MATRIX OF % WITHIN COLS ****************************"
	tabulate `v1' `v2' `if' `in' [`weight' `exp'], col nof
	mat list `mname'C 
}
else { 
	di "Default matrix name is tmat" 
	display "************ MATRIX OF COUNTS ***********************************"
	tabulate `v1' `v2' `if' `in' [`weight' `exp']
	mat list tmat 
	display ""
	display "************ MATRIX OF % WITHIN ROWS ****************************"
	tabulate `v1' `v2' `if' `in' [`weight' `exp'] , row nof
	mat list tmatR 
	display ""
	display "************ MATRIX OF % WITHIN COLS ****************************"
	tabulate `v1' `v2' `if' `in' [`weight' `exp'], col nof
	mat list tmatC 
}

end

