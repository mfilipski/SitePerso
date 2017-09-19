program tsmat
	syntax varlist (min=2) [if] [in] [aweight fweight iweight] [, Mname(string) by(string) Save Format(str) ] 
	tempvar
* get the numbers of levels 
tempvar g1
egen `g1' = group(`by') 
qui sum `g1' 
local numby = r(max) 


* run the tabstat command
tabstat `varlist' `if' `in' [`weight' `exp'] , save by(`by') format(`format')

* Convert results to a matrix
matrix tsmat = r(Stat1)
local  names = r(name1)

if `numby' > 1 { 
	foreach n of numlist 2/`numby' { 
		mat tsmat = tsmat \ r(Stat`n')
		local names = "`names' `r(name`n')'"
	} 
}
else {
	di "matrix only has one category" 
}
mat rownames tsmat = `names'

* Rename if a name was provided 
if "`mname'" != "" {
	di "Chosen name for matrices is `mname'"
	mat rename tsmat `mname' 
	mat list `mname' 
}
else { 
	di "Default matrix name is tsmat" 
	mat list tsmat 
}
end

