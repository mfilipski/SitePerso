$title Mini GE-LEWIE model
* This program creates the Monte-Carlo Results of chapter 3, table 8 (but with fewer repetitions, see line 111)
* It features the basic model of Chapter 3, but with Monte-Carlo calibration.

Option limrow=10, limcol=50
OPTION DECIMALS=2 ;

* Name the sets that will be used:
sets
i all accounts
g(i) goods
f(i) factors
h(i) households
var  variable names
mse  mean or standard error
;
parameter Alldata2(var,*,*,*,h,mse);

* Read in the data from LEWIE spreadsheet:
* the $call reads XL data and makes a .gdx file with it; you can do this once then star out the $call command to save time
* (unstar the "call" statement to re-read from the excel spreadsheet, which is what you want when changing the excel input file)
$call "gdxxrw input=Ch3_LEWIE_Inputs.xlsx output=Ch3_data_MonteCarlo.gdx index=IndexMC!A2"

* The "Index" tab of the XL spreadsheet tells the gdxxrw procedure where things are in the excel spreadsheet.
* It might seem confusing at first glance, but once you work through it you'll find it makes a lot of sense.
* First, we tell GAMS the names of all the sets and parameters to be assigned (initial) values from the excel input file.
* Then we have gams read in all the values as parameters. The program below will then use these
* parameters to initialize variables and assign values to model parameters. In the program, additional variables and parameters may be created
* from these.

* The index tab in the EXCEL input file for this program looks like this:

*Type   Name       Range                   Dimensions
*                                         rdim    cdim
*dset   i          LEWIE_MC!A4             1
*dset   var        LEWIE_MC!B4             1
*dset   h          LEWIE_MC!F2                     1
*dset   mse        LEWIE_MC!F3                     1
*dset   g          LEWIE_MC!C4             1
*dset   f          LEWIE_MC!E4:E300        1
*par    alldata2   LEWIE_MC!B2             4       2

* Which means:
* -the column going down from cell "LEWIE_MC!A4" contains the set i of all the accounts of the SAM
*   ...so you need to make sure this column contains all of those.

* NOTE: We use the "dset" instead of "set" command to define the sets and parameters, because it eliminates duplicates.

* -column "LEWIE_MC!B4" is where GAMS reads the names of all the variables to be assigned initial values
* -row (to the right of) "LEWIE_MC!F2" lists the household groups (no problem that these are repeated to make nice column headings)
* -row (to right of) "LEWIE_MC!F3" lists, under each household, the two statistics we'll read in on each estimated parameter: mean and se (standard error)
* -col (below) "LEWIE_MC!C4" will read in the names of all goods (again, no problem they repeat to make the neat input table)
* -col (below) "LEWIE_MC!E4" will read in the names of all factors (again, no problem they repeat to make the neat input table). This one is given as a
*    range just to show you can do that
* -We create a parameter called "alldata2" with all the indexes we've defined: in the 4 cols to the southeast of "LEWIE_MC!B2" and also in the two
*    rows to the southeast of this cell (inclusive). This is so we can read in all the data initially into a parameter matrix then assign the data
*    to model parameters and intial values of variables

* the $gdxin opens the data loading procedure and calls the .gdx file we just made
$gdxin Ch3_data_MonteCarlo.gdx
* The $load command loads in all the data in the input matrix; then we display to make sure it loaded properly
$load I G F H VAR MSE ALLDATA2
display i, g, f, h, var, mse, ALLDATA2 ;


* This option controls the decimals and display format
option alldata2:2:4:1;
display alldata2;

* Supply elasticity of labor
* "setlocal" gives a value to the local variable "supel", which can then be referenced anywhere using "%supel%"
$setlocal supel 1000

* Make subsets for calibration of the model
* name for the "phantom" element = put it in sets that might be empty in some simulations (GAMS dislikes empty sets)
$phantom null
* calibrating off of the SAM:
sets
* subsets
     gp(g)     produced goods /ag, nonag/
     gnt(g)    non-tradable goods /null, ag /
     gt(g)     tradable goods / exog, nonag/
     fx(f)     fixed factors /capi/
     ft(f)     tradable factors /labo,  purch/
     ftv(ft)   factors tradable in the village /null, labo/
     ftw(ft)   factors tradable with the world /purch/
;
alias (g,gg)
 (f,ff)
 (h,hh);



PARAMETERS
* Production
     pbeta(g,f,h)   Factor share of f in production of g by h (Cobb-Douglas exponent)
     pshift(g,h)    Shift parameter in production of g by h
     idsh(g,gg,h)   Share of intermediate demand for gg to produce g (Leontief coefficient for intermediate input)
     vash(g,h)      Share of value added (output price net of intermediate input component)
* Consumption
     calpha(g,h)    Expenditure share on consumption of g by h

* Market assumptions
     se(f)          Supply elasticity of factor f in the economy
* endowments
     yexog(h)       Exogenous household income
     hfsupel(f,h)   Factor supply elasticity for each household
     fixfac(g,f,h)  Fixed factor demand
;

* The following command sets the number of draws from each parameter distribution for the Monte Carlo method
*    to create confidence bands around simulation results; dr0*dr# where # is the number of draws desired
*    Note: a high # can significantly increase computation time. The table in the book used 1000 repetitions.
set draw /dr0*dr50/ ;


Parameter
* Values for VARIABLES in each draw
* **********************************
* Prices and values
     p_dr(g,draw)      Price of g on the village markets
     pva_dr(g,h,draw)  Price value added for each household
     r_dr(g,f,h,draw)  Rent for inputs fixed in production of g by h
     w_dr(f,draw)      Wage for tradable inputs (common for the village)
* Production
     qp_dr(g,h,draw)    Quantity of g produced by h
     tqp_dr(g,draw)     Total quantity produced in the village
     qva_dr(g,h,draw)   Quantity of value added produced by h
     id_dr(g,gg,h,draw) Intermediate demand for g in prodution of gg by h
     fd_dr(g,f,h,draw)  Factor demand for f in production of g by h
     hfd_dr(f,h,draw)   Household total use of factor f
     vfd_dr(f,draw)     Total use of factor f in the village
     hfsup_dr(f,h,draw) Factor supply of f from the household (elastic)

* Income and consumption
     y_dr(h,draw)      Nominal Income of household h
     cpi_dr(h,draw)    Consumer price index for household h
     ry_dr(h,draw)     Real income of household h
     qc_dr(g,h,draw)   Quantity of g consumed by h
     tqc_dr(g,draw)    Total consumption in the village
     cy_dr(draw)     Combined Nominal Income
     cry_dr(draw)     Comgined Real income

* Market clearing
     hms_dr(g,h,draw)   Marketed surplus of g in the household-economy
     vms_dr(g,draw)     Marketed surplus of g in the village economy
     hfms_dr(f,h,draw)  Marketed surplus of f in the household-economy
     vfms_dr(f,draw)    Marketed surplus of f in the village economy

* Values for PARAMETERS in each draw
* **********************************
     calpha_dr(g,h,draw)   Expenditure share in consumption function
     pbeta_dr(g,f,h,draw)  Factor share in production function
     pshift_dr(g,h,draw)   Shift parameter in production function
     vash_dr(g,h,draw)     Share of value added in production
     idsh_dr(g,gg,h,draw)  Share of Intermediate demand for gg in production of g
     tidsh_dr(g,h,draw)    Total share of intermediate inputs (1-vash)
     fixfac_dr(g,f,h,draw) Fixed factor in production

* Not explicitely in the model
     finc_dr(f,h,draw)   factor incomes
     hmsrat_dr(g,h,draw) ratio of consumption to production in hh
;


* The values that read straight from excel () (we denote these with 'xl' prefix):
parameter
* income and consumption
     xlfinc(f,h,mse)     hh factor income
     xlcalpha(g,h,mse)   expenditure shares

* Production and factor incomes
     xlhmsrat(g,h,mse)    ratio of consumption to production of item g in household hh
     xlidshtq(g,gg,h,mse) intermediate demand share of total production in the village
     xlfd(g,f,h,mse)      factor demand for f in production of g by household h
     xlid(g,gg,h,mse)     intermediate demand for gg in production of g by household h
;

* Read standard errors from the alldata spreadsheet (these come from econometric estimation of production
*    and expenditure functions using micro-survey data):
xlfinc(f,h,mse)   = alldata2("finc","","",f,h,mse) ;
xlcalpha(g,h,mse) = alldata2("calpha",g,"","",h,mse);
xlid(g,gg,h,mse)  = alldata2("id",gg,g,"",h,mse);
xlhmsrat(g,h,mse) = alldata2("qcshare",g,"","",h,mse);
xlfd(g,f,h,mse)   = alldata2("fd",g,"",f,h,mse) ;
display xlfinc, xlcalpha, xlid ;

* The estimated parameters (means) are the same for all draws; we assign these from parameters read in from
*    spreadsheet (with prefix 'xl') to parameters in model (defined above, without 'xl' prefix):
finc_dr(f,h,draw) = xlfinc(f,h,"mean");
calpha_dr(g,h,draw) = xlcalpha(g,h,"mean") ;
id_dr(g,gg,h,draw) = xlid(g,gg,h,"mean");
hmsrat_dr(gp,h,draw)=xlhmsrat(gp,h,"mean");
* Use factor demands from excel to compute factor shares:
pbeta_dr(g,f,h,draw)$xlfd(g,f,h,"mean") = xlfd(g,f,h,"mean")/sum(ff,xlfd(g,ff,h,"mean")) ;


* Now we can take the # random draws from the parameter distributions (and rescale to 1)
* This command takes draws from the distribution of xlfinc, assuming it is normal.
finc_dr(f,h,draw)$(not sameas(draw,"dr0")) = normal(xlfinc(f,h,"mean"),xlfinc(f,h,"se")) ;

* The following commands do the same for all other parameters (star or unstar them at will):
 id_dr(g,gg,h,draw)$(not sameas(draw,"dr0")) = normal(xlid(g,gg,h,"mean"),xlid(g,gg,h,"se"));
* for consumption alphas and production betas we need them to add up to one
parameter cal_tmp(g,h,draw) draws of calpha before rescale
          fd_tmp(g,f,h,draw) draws of fd for rescale into pbeta;
cal_tmp(g,h,draw)$(not sameas(draw,"dr0")) = normal(xlcalpha(g,h,"mean"),xlcalpha(g,h,"se")) ;
calpha_dr(g,h,draw)$sum(gg,cal_tmp(gg,h,draw)) = cal_tmp(g,h,draw)/sum(gg,cal_tmp(gg,h,draw)) ;
fd_tmp(g,f,h,draw)$(not sameas(draw,"dr0")) = normal(xlfd(g,f,h,"mean"),xlfd(g,f,h,"se")) ;
pbeta_dr(g,f,h,draw)$sum(ff,fd_tmp(g,ff,h,draw)) = fd_tmp(g,f,h,draw)/sum(ff,fd_tmp(g,ff,h,draw)) ;
hmsrat_dr(gp,h,draw)$(not sameas(draw,"dr0")) = normal(xlhmsrat(gp,h,"mean"),xlhmsrat(gp,h,"se")) ;



* Now we calibrate all other parameters, which depend on the above draws:
*=========================================================================
* Income for each draw is the sum of factor incomes across factors
y_dr(h,draw) = sum(f,finc_dr(f,h,draw)) ;
display y_dr ;

* Consumption is determined from income and consumption shares:
qc_dr(g,h,draw) = y_dr(h, draw)*calpha_dr(g,h,draw) ;
tqc_dr(g,draw) = sum(h,qc_dr(g,h,draw)) ;
display calpha_dr, qc_dr, y_dr ;

* That gives sales and production given that we know marketed surplus
display xlhmsrat ;
qp_dr(gp,h,draw) = qc_dr(gp,h,draw)/hmsrat_dr(gp,h,draw);
tqp_dr(gp,draw) = sum(h,qp_dr(gp,h,draw)) ;
display qp_dr, tqp_dr ;

* We compute intermediate demand shares which are useful in computations:
idsh_dr(g,gg,h,draw)$qp_dr(g,h,draw) = id_dr(g,gg,h,draw) / qp_dr(g,h,draw) ;
tidsh_dr(g,h,draw) = sum(gg,idsh_dr(g,gg,h,draw));
display id_dr, idsh_dr, tidsh_dr ;

* We can figure out the rest from there:
* Factor demands derived from factor shares and total value added (QP-ID)
fd_dr(g,f,h,draw)  = (qp_dr(g,h,draw) - sum(gg,id_dr(g,gg,h,draw))) * pbeta_dr(g,f,h,draw)  ;
display pbeta_dr, fd_dr ;
* Check factor shares for consistency (must add up to 1)
parameter betachk;
betachk(g,h,draw) = sum(ff,pbeta_dr(g,ff,h,draw)) ;
display betachk;
* Compute value-added for each draw
qva_dr(g,h,draw)   = sum(f, fd_dr(g,f,h,draw)) ;
pshift_dr(g,h,draw)$(qva_dr(g,h,draw)) = qva_dr(g,h,draw)/prod(f,fd_dr(g,f,h,draw)**pbeta_dr(g,f,h,draw)) ;

* ...and compute value added share for all activities
vash_dr(g,h,draw)$qp_dr(g,h,draw) = (qp_dr(g,h,draw)-sum(gg, id_dr(g,gg,h,draw))) / qp_dr(g,h,draw) ;
display id_dr, tidsh_dr, vash_dr ;

parameter tid_dr(g,draw) check of total input demand
          tqcid_dr(g,draw)  check of qc+id ;
tid_dr(g,draw)= sum((gg,h),id_dr(g,gg,h,draw)) ;
tqcid_dr(g,draw) = tid_dr(g,draw) + tqc_dr(g,draw) ;
display tqc_dr, tid_dr, tqcid_dr, tqp_dr ;

* and finally the labor supplies, proportionnal to the draws but rescaled:
parameter ftratio_dr(f,h,draw) ratio of hh labor supply to total fd (can sum to >1);
ftratio_dr(f,h,draw)$xlfinc(f,h,"mean") = xlfinc(f,h,"mean")/sum((gg,hh),fd_dr(gg,f,hh,draw)) ;
display ftratio_dr;
* Household factor supplies
hfsup_dr(ft,h,draw) = ftratio_dr(ft,h,draw) * sum((hh,g), fd_dr(g,ft,hh,draw));
fixfac_dr(g,fx,h,draw) = fd_dr(g,fx,h,draw) ;
display hfsup_dr ;


* MARKET AGGREGATES
* ================================================================================================
* Household factor demand aggregates
hfd_dr(f,h,draw)= sum(g,fd_dr(g,f,h,draw)) ;
vfd_dr(f,draw)= sum(h, hfd_dr(f,h,draw)) ;

* Marketed surpluses for goods
hms_dr(g,h,draw) = qp_dr(g,h,draw) - qc_dr(g,h,draw) - sum(gg,id_dr(gg,g,h,draw)) ;
vms_dr(g,draw) = sum(h,hms_dr(g,h,draw));

* Marketed surpluses for factors
hfms_dr(ft,h,draw) = hfsup_dr(ft,h,draw) - sum(g, fd_dr(g,ft,h,draw));
vfms_dr(ft,draw) = sum(h, hfms_dr(ft,h,draw));

display hms_dr, vms_dr, hfms_dr, vfms_dr ;

* wages and rents are set to one in the base (for all draws)
w_dr(ft,draw) = 1;
r_dr(g,fx,h,draw) = 1;

* last missing: Exogenous income (which will equalize incomes to expenditures and balance the economy)
parameter feinc_dr(h,draw) income from factor endowments in the household
          yexog_dr(h,draw) exogenous income residual;

* We make exogenous income the residual from Y-FD
feinc_dr(h,draw) = sum((g,fx),r_dr(g,fx,h,draw)*fd_dr(g,fx,h,draw)) + sum(ft, w_dr(ft,draw)*hfsup_dr(ft,h,draw)) ;
yexog_dr(h,draw) = y_dr(h,draw) - feinc_dr(h,draw) ;
display yexog_dr, feinc_dr;

* Initial values for prices
p_dr(g,draw) = 1 ;
pva_dr(g,h,draw) = p_dr(g,draw)*(1-tidsh_dr(g,h,draw)) ;
cpi_dr(h,draw) = sum(g,p_dr(g,draw)*calpha_dr(g,h,draw));
display p_dr, pva_dr, cpi_dr ;

* Combined nominal income
cy_dr(draw) = sum(h,y_dr(h,draw)) ;
display cy_dr ;


* ==================================
* MODEL STARTS HERE
* ==================================
VARIABLES
* Prices/values
     P(g)      Price of g on the village markets
     PVA(g,h)  Price value added
     R(g,f,h)  Rent for inputs fixed in production of g by h
     W(f)      Wage for tradable inputs (common for the village)
* Production
     QP(g,h)    Quantity of g produced by h
     QVA(g,h)  Quantity of value added created
     ID(g,gg,h) Intermediate demand for g in prodution of gg by h
     FD(g,f,h)  Factor demand for f in production of g by h
     HFD(f,h) Household total use of factors
     HFSUP(f,h) Household factor supply

* Income and consumption
     Y(h)      Nominal Income of household h
     CPI(h)    Consumer price index for household h
     RY(h)     Real income of household h
     QC(g,h)   Quantity of g consumed by h
     CY(h)     Combined Nominal Income
     CRY(h)    Combined Real income

* Market clearing
     HMS(g,h)  Marketed surplus of g in the household-economy
     VMS(g)    Marketed surplus of g in the village economy
     HFMS(f,h)  Marketed surplus of f in the household-economy
     VFMS(f)    Marketed surplus of f in the village economy
;

* Parameters with a "zero" suffix hold all initial values of a variable at the beginning of each solve
* (The model should reproduce all those values if it is solved without any shock to the economy)
parameters
     p0(g)      Price of g on the village markets
     pva0(g,h)  Price value added for each household
     r0(g,f,h)  Rent for inputs fixed in production of g by h
     w0(f)      Wage for tradable inputs (common for the village)
* Production
     qp0(g,h)    Quantity of g produced by h
     qva0(g,h)   Quantity of value added produced by h
     id0(g,gg,h) Intermediate demand for g in prodution of gg by h
     fd0(g,f,h)  Factor demand for f in production of g by h
     hfd0(f,h) Household total use of factors
     hfsup0(f,h) Elastic Factor supply from the household

* Income and consumption
     y0(h)      Nominal Income of household h
     cpi0(h)    Consumer price index for household h
     ry0(h)     Real income of household h
     qc0(g,h)   Quantity of g consumed by h
     cy0(h)     Combined Nominal Income
     cry0(h)    Combined Real income of household h

* Market clearing
     hms0(g,h)  Marketed surplus of g in the household-economy
     vms0(g)    Marketed surplus of g in the village economy
     hfms0(f,h)  Marketed surplus of f in the household-economy
     vfms0(f)    Marketed surplus of f in the village economy
;



* MODEL
EQUATIONS
* Household level:
* Prices in the economy
     EQ_PVA(g,h)    Defines prices as the household sees them

* Production block
     EQ_QP(g,h)     Defines quantities produced
     EQ_FD(g,f,h)   FOC: Defines factor demands
     EQ_ID(g,gg,h)  FOC: intermediate demands

* Income and consumption
     EQ_Y(h)        Defines household income
     EQ_QC(g,h)     Defines quantities of goods consumed by h

* Village-level:
* Market clearing
     EQ_HMS(g,h)    Defines marketed surplus of the household
     EQ_VMS(g)       Defines marketed surplus for the economy
     EQ_FIXMS(g)    Clears market for non-tradable goods

     EQ_HFMS(f,h)   Defines factor marketed surplus of the household
     EQ_VFMS(f)     Defines factor marketed surplus in the village
     EQ_FIXF(g,f,h) Fixed factor constraint
     EQ_FIXVF(ftv)  Factors tradable in the village only
     EQ_HFSUP(f,h)  Tradable factor supply elasticity

* Useful output:
* (those are definitional equations, not essential to the model itself):
     EQ_CPI(h)      Defines cpi
     EQ_RY(h)       Defines hh income in real terms

;


* Prices:
*-----------
* "value added prices", net of intermediate inputs
     EQ_PVA(g,h)..
          PVA(g,h) =E= P(g)- sum(gg,idsh(g,gg,h)*P(gg)) ;

* Production block:
*-------------------
* Cobb Douglas output:
     EQ_QP(g,h)..
          QP(g,h)*vash(g,h) =E= pshift(g,h)*prod(f,FD(g,f,h)**pbeta(g,f,h)) ;
* Factor demands (resulting of a standard profitmax)
* (value is rent or wage, depending whether it is a tradable factor or not)
     EQ_FD(g,f,h)$fd0(g,f,h)..
          FD(g,f,h)*[R(g,f,h)$fx(f) + W(f)$ft(f)]
                     =E= QP(g,h)*PVA(g,h)*pbeta(g,f,h) ;
* Intermediate input demand:
     EQ_ID(g,gg,h)..
          ID(g,gg,h) =E= QP(g,h)*idsh(g,gg,h) ;


* Income and consumption:
*-------------------------
     EQ_Y(h)..
          Y(h) =E=    sum((fx,gp), R(gp,fx,h)*FD(gp,fx,h))
                    + sum(ft$hfsup0(ft,h), W(ft)*hfsup(ft,h))
                    + yexog(h) ;


     EQ_QC(g,h)$pva0(g,h)..
          QC(g,h) =E= Y(h)*calpha(g,h)/ P(g) ;

* Village-level:
*-----------------
* Market clearing
     EQ_HMS(g,h)..   HMS(g,h) =E= QP(g,h) - QC(g,h) - sum(gg,ID(gg,g,h));
     EQ_VMS(g)..     VMS(g) =E= sum(h, HMS(g,h)) ;
     EQ_FIXMS(gnt).. VMS(gnt) =E= vms0(gnt) ;

     EQ_HFMS(ft,h)..  HFMS(ft,h) =E= hfsup(ft,h) - sum(gp,FD(gp,ft,h)) ;
     EQ_VFMS(ft)..    VFMS(ft)    =E= sum(h, HFMS(ft,h));
* Clearing rents and wages
     EQ_FIXF(g,fx,h)$gp(g)..   FD(g,fx,h) =E= fixfac(g,fx,h) ;
     EQ_FIXVF(ftv)..  VFMS(ftv)    =E= vfms0(ftv) ;

* Elastic Labor supply:
EQ_HFSUP(ftv,h)..
     HFSUP(ftv,h)/hfsup0(ftv,h) =E= W(ftv)**hfsupel(ftv,h) ;


* Useful output:
*-----------------------
     EQ_CPI(h)..
          CPI(h) =e= sum(g,P(g)*calpha(g,h));

     EQ_RY(h)..
          RY(h) =e= Y(h) / CPI(h);



MODEL miniLEWIE LEWIE model with Monte Carlo calibration /
EQ_PVA.PVA
EQ_FD.FD
EQ_QP.QP
EQ_ID.ID
EQ_QC.QC
EQ_Y.Y
EQ_CPI.CPI
EQ_RY.RY
EQ_HMS.HMS
EQ_VMS.VMS
EQ_FIXMS.P
EQ_HFMS.HFMS
EQ_VFMS.VFMS
EQ_FIXF.R
EQ_FIXVF.W
EQ_HFSUP.HFSUP
/ ;

*=========================================
* Model statement ends here.
*=========================================


parameters
* Base Model Solutions by Draw
     p1(g,draw)        Price of g on the village markets
     pva1(g,h,draw)    Price value added for each household
     r1(g,f,h,draw)    Rent for inputs fixed in production of g by h
     w1(f,draw)        Wage for tradable inputs (common for the village)
     qp1(g,h,draw)     Quantity of g produced by h
     qva1(g,h,draw)
     id1(g,gg,h,draw)  Intermediate demand for g in prodution of gg by h
     fd1(g,f,h,draw)   Factor demand for f in production of g by h
     hfd1(f,h,draw)    Household total use of factors
     y1(h,draw)        Nominal Income of household h
     cpi1(h,draw)      Consumer price index for household h
     ry1(h,draw)       Real income of household h
     qc1(g,h,draw)     Quantity of g consumed by h
     hms1(g,h,draw )   Marketed surplus of g in the household-economy
     vms1(g,draw)      Marketed surplus of g in the village economy
     hfms1(f,h,draw)   Marketed surplus of f in the household-economy
     vfms1(f,draw)     Marketed surplus of f in the village economy
     hfsup1(f,h,draw)  Tradable factor supply
     ly1(f,h,draw)     Labor income
     fxy1(f,h,draw)    capital income
     fixfac1(g,f,h,draw) fixed factor
     yexog1(h,draw)    exogenous income
     cy1(draw)       Combined Nominal Income
     cry1(draw)      Combined Real income
* Experiment Outcomes by Draw
     p2(g,draw)      Price of g on the village markets
     pva2(g,h,draw)  Price value added for each household
     r2(g,f,h,draw)  Rent for inputs fixed in production of g by h
     w2(f,draw)      Wage for tradable inputs (common for the village)
     qp2(g,h,draw)   Quantity of g produced by h
     qva2(g,h,draw)
     id2(g,gg,h,draw) Intermediate demand for g in prodution of gg by h
     fd2(g,f,h,draw)  Factor demand for f in production of g by h
     hfd2(f,h,draw)   Household total use of factors
     y2(h,draw)       Nominal Income of household h
     cpi2(h,draw)     Consumer price index for household h
     ry2(h,draw)      Real income of household h
     qc2(g,h,draw)    Quantity of g consumed by h
     hms2(g,h,draw)   Marketed surplus of g in the household-economy
     vms2(g,draw)     Marketed surplus of g in the village economy
     hfms2(f,h,draw)  Marketed surplus of f in the household-economy
     vfms2(f,draw)    Marketed surplus of f in the village economy
     hfsup2(f,h,draw) Tradable factor supply
     ly2(f,h,draw)    Labor income
     fxy2(f,h,draw)    capital income
     fixfac2(g,f,h,draw) fixed factor
     yexog2(h,draw)      exogenous income
     cy2(draw)       Combined Nominal Income
     cry2(draw)      Combined Real income
* Change from Base by Draw
     pD(g,draw)      Price of g on the village markets
     pvaD(g,h,draw)  Price value added for each household
     rD(g,f,h,draw)  Rent for inputs fixed in production of g by h
     wD(f,draw)      Wage for tradable inputs (common for the village)
     qpD(g,h,draw)   Quantity of g produced by h
     qvaD(g,h,draw)
     idD(g,gg,h,draw) Intermediate demand for g in prodution of gg by h
     fdD(g,f,h,draw)  Factor demand for f in production of g by h
     hfdD(f,h,draw)   Household total use of factors
     yD(h,draw)       Nominal Income of household h
     cpiD(h,draw)     Consumer price index for household h
     ryD(h,draw)      Real income of household h
     qcD(g,h,draw)    Quantity of g consumed by h
     hmsD(g,h,draw)   Marketed surplus of g in the household-economy
     vmsD(g,draw)     Marketed surplus of g in the village economy
     hfmsD(f,h,draw)  Marketed surplus of f in the household-economy
     vfmsD(f,draw)    Marketed surplus of f in the village economy
     hfsupD(f,h,draw) Tradable factor supply
     lyD(f,h,draw)    Labor income
     fxyD(f,h,draw)    capital income
     fixfacD(g,f,h,draw) fixed factor
     yexogD(h,draw)      exogenous income
     cyD(draw)       Combined Nominal Income
     cryD(draw)      Combined Real income
* Experiment Outcomes as % Change from Base by Draw
     pPC(g,draw)      Price of g on the village markets
     pvaPC(g,h,draw)  Price value added for each household
     rPC(g,f,h,draw)  Rent for inputs fixed in production of g by h
     wPC(f,draw)      Wage for tradable inputs (common for the village)
     qpPC(g,h,draw)    Quantity of g produced by h
     qvaPC(g,h,draw)
     idPC(g,gg,h,draw) Intermediate demand for g in prodution of gg by h
     fdPC(g,f,h,draw)  Factor demand for f in production of g by h
     hfdPC(f,h,draw)   Household total use of factors
     yPC(h,draw)       Nominal Income of household h
     cpiPC(h,draw)     Consumer price index for household h
     ryPC(h,draw)      Real income of household h
     qcPC(g,h,draw)    Quantity of g consumed by h
     hmsPC(g,h,draw)   Marketed surplus of g in the household-economy
     vmsPC(g,draw)     Marketed surplus of g in the village economy
     hfmsPC(f,h,draw)  Marketed surplus of f in the household-economy
     vfmsPC(f,draw)    Marketed surplus of f in the village economy
     hfsupPC(f,h,draw) Tradable factor supply
     lyPC(f,h,draw)     Labor income
     fxyPC(f,h,draw)    capital income
     fixfacPC(g,f,h,draw) fixed factor
     yexogPC(h,draw)      exogenous income
     cyPC(draw)       Combined Nominal Income
     cryPC(draw)      Combined Real income
;



*=========================================================================
*================= LOOP BEGINS============================================
*=========================================================================

loop(draw,
* Set initial values of variables (one draw for each loop)
QP.l(g,h) =  qp_dr(g,h,draw)  ;
ID.l(g,gg,h)=  id_dr(g,gg,h,draw);
FD.l(g,f,h)= fd_dr(g,f,h,draw)  ;
QVA.l(g,h) =  qva_dr(g,h,draw)  ;
HFD.l(f,h)=  hfd_dr(f,h,draw)   ;
Y.l(h)=     y_dr(h,draw)        ;
QC.l(g,h)=  qc_dr(g,h,draw)     ;
HMS.l(g,h)= hms_dr(g,h,draw)    ;
HFMS.l(f,h)= hfms_dr(f,h,draw)  ;
VMS.l(g) =vms_dr(g,draw) ;
VFMS.l(f) =vfms_dr(f,draw);
P.l(g) = p_dr(g,draw) ;
PVA.l(g,h) = pva_dr(g,h,draw) ;
R.l(g,f,h) = r_dr(g,f,h,draw);
W.l(f)   = w_dr(f,draw) ;
CPI.l(h) = cpi_dr(h,draw) ;
HFSUP.l(f,h) = hfsup_dr(f,h,draw) ;
* Set initial values of parameters
idsh(g,gg,h) = idsh_dr(g,gg,h,draw);
pbeta(g,f,h) = pbeta_dr(g,f,h,draw);
vash(g,h) = vash_dr(g,h,draw) ;
pshift(g,h) = pshift_dr(g,h,draw);
calpha(g,h) = calpha_dr(g,h,draw);
yexog(h)  =yexog_dr(h,draw);
fixfac(g,fx,h) = fixfac_dr(g,fx,h,draw) ;
hfsupel(ft,h) = %supel% ;

* Set zero values called in the equations or the data checks
fd0(g,f,h) = fd_dr(g,f,h,draw)  ;
pva0(g,h) = pva_dr(g,h,draw) ;
hfsup0(f,h) = hfsup_dr(f,h,draw) ;
vms0(g) =vms_dr(g,draw) ;
vfms0(f) =vfms_dr(f,draw);
qp0(g,h) =  qp_dr(g,h,draw)  ;
qc0(g,h)=  qc_dr(g,h,draw)     ;

* Market closure (price determination) conditions
* Fixed prices for tradable goods and factors
P.fx(gt) = p_dr(gt,draw);
W.fx(ftw) = w_dr(ftw,draw);
QP.fx("exog",h) = 0;
HFSUP.fx("purch",h) = 0;
HFSUP.fx(ftw,h) = hfsup_dr(ftw,h,draw);


display P.l, PVA.l, R.l, W.l, QP.l, FD.l, ID.l, Y.l, QC.l, HMS.l, VMS.l, VFMS.l, HFSUP.l, HFD.l, HFMS.l ;

* set iteration limit to 1 to check calibration, and increase it back to 10000 after check is done
*(if the calibration is done properly, it should be a solution to the model, no iterations needed)
option iterlim = 1;
Solve miniLEWIE using mcp ;
option iterlim = 10000;
* Aborts if model doesn't solve well in one iteration
ABORT$(miniLEWIE.modelstat ne 1) "NOT WELL CALIBRATED IN THIS DRAW - CHECK THE DATA INPUTS" ;
display P.l, PVA.l, R.l, W.l, QP.l, FD.l, ID.l, Y.l, QC.l, HMS.l, VMS.l, VFMS.l, HFSUP.l, HFD.l, HFMS.l ;

* Aborts if matrix not reproduced
loop((g,h),
ABORT$(QP.l(g,h) ne qp0(g,h)) "QP NOT WELL CALIBRATED - CHECK THE DATA INPUTS" ;
ABORT$(QC.l(g,h) ne qc0(g,h)) "QC NOT WELL CALIBRATED - CHECK THE DATA INPUTS" ;
);


* Additional parameters: Baseline values of variables to compare with experimental results
p1(g,draw)      = P.l(g) ;
pva1(g,h,draw)  = PVA.l(g,h);
r1(g,f,h,draw)  = R.l(g,f,h);
w1(f,draw)      = W.l(f) ;
qp1(g,h,draw)   = QP.l(g,h) ;
qva1(g,h,draw)  = QVA.l(g,h) ;
id1(g,gg,h,draw) = ID.l(g,gg,h) ;
fd1(g,f,h,draw)  = FD.l(g,f,h) ;
hfd1(f,h,draw)  = HFD.l(f,h) ;
y1(h,draw)      = Y.l(h) ;
cpi1(h,draw)    = CPI.l(h);
ry1(h,draw)     = RY.l(h) ;
qc1(g,h,draw)   = QC.l(g,h) ;
hms1(g,h,draw)  = HMS.l(g,h) ;
vms1(g,draw)    = VMS.l(g) ;
hfms1(f,h,draw) = HFMS.l(f,h) ;
vfms1(f,draw)   = VFMS.l(f) ;
hfsup1(f,h,draw) = HFSUP.l(f,h) ;
fixfac1(g,fx,h,draw) = fixfac(g,fx,h) ;
yexog1(h,draw) = yexog(h);
cy1(draw)     = sum(h,y1(h,draw));
cry1(draw)     = sum(h,ry1(h,draw)) ;

* ***************************************************************************************
* SHOCK(s): This is the experiment we run to produce Monte-Carlo columns in Table 3.8
* ***************************************************************************************
*Cash transfer to poor household (increases exogenous income by 1):
yexog("poor") = yexog("poor") + 1 ;

Solve miniLEWIE using mcp ;
option iterlim = 10000;
display P.l, PVA.l, R.l, W.l, QP.l, FD.l, ID.l, Y.l, QC.l, HMS.l, VMS.l, VFMS.l, HFSUP.l, HFD.l, HFMS.l ;
display p1, pva1, r1, w1, qp1, id1, fd1, hfd1, y1, qc1, hms1, vms1, hfms1, vfms1 ;

p2(g,draw)      = P.l(g) ;
pva2(g,h,draw)  = PVA.l(g,h);
r2(g,f,h,draw)  = R.l(g,f,h);
w2(f,draw)      = W.l(f) ;
qp2(g,h,draw)   = QP.l(g,h) ;
qva2(g,h,draw)  = QVA.l(g,h) ;
id2(g,gg,h,draw) = ID.l(g,gg,h) ;
fd2(g,f,h,draw)  = FD.l(g,f,h) ;
hfd2(f,h,draw)  = HFD.l(f,h) ;
y2(h,draw)      = Y.l(h) ;
cpi2(h,draw)    = CPI.l(h);
ry2(h,draw)     = RY.l(h) ;
qc2(g,h,draw)   = QC.l(g,h) ;
hms2(g,h,draw)  = HMS.l(g,h) ;
vms2(g,draw)    = VMS.l(g) ;
hfms2(f,h,draw) = HFMS.l(f,h) ;
vfms2(f,draw)   = VFMS.l(f) ;
hfsup2(f,h,draw) = HFSUP.l(f,h) ;
fixfac2(g,fx,h,draw) = fixfac(g,fx,h) ;
yexog2(h,draw) = yexog(h);
cy2(draw)     = sum(h,y2(h,draw)) ;
cry2(draw)     = sum(h,ry2(h,draw)) ;

*=========================================================================
*================= LOOP ENDS  ============================================
*=========================================================================
);

*When the simulations have ended, we take the results (stored in parameters named after variables but with '2' at the end)
*   and subtract base values (with '1' at end) to obtain changes (with 'D' at end):
pD(g,draw)     = p2(g,draw) - p1(g,draw) ;
pvaD(g,h,draw) = pva2(g,h,draw) - pva1(g,h,draw) ;
rD(g,f,h,draw) = r2(g,f,h,draw) - r1(g,f,h,draw) ;
wD(f,draw)     = w2(f,draw) - w1(f,draw) ;
qpD(g,h,draw)  = qp2(g,h,draw) - qp1(g,h,draw) ;
qvaD(g,h,draw)  = qva2(g,h,draw) - qva1(g,h,draw) ;
idD(g,gg,h,draw) = id2(g,gg,h,draw) - id1(g,gg,h,draw) ;
fdD(g,f,h,draw) = fd2(g,f,h,draw) - fd1(g,f,h,draw) ;
hfdD(f,h,draw) = hfd2(f,h,draw) - hfd1(f,h,draw) ;
yD(h,draw)     = y2(h,draw) - y1(h,draw) ;
cpiD(h,draw)   = cpi2(h,draw) - cpi1(h,draw) ;
ryD(h,draw)    = ry2(h,draw) - ry1(h,draw) ;
qcD(g,h,draw)  = qc2(g,h,draw) - qc1(g,h,draw) ;
hmsD(g,h,draw) = hms2(g,h,draw) - hms1(g,h,draw) ;
vmsD(g,draw)   = vms2(g,draw) - vms1(g,draw) ;
hfmsD(f,h,draw) = hfms2(f,h,draw) - hfms1(f,h,draw) ;
vfmsD(f,draw)  = vfms2(f,draw) - vfms1(f,draw) ;
hfsupD(f,h,draw) = hfsup2(f,h,draw)-hfsup1(f,h,draw) ;
fixfacD(g,fx,h,draw) = fixfac2(g,fx,h,draw) - fixfac1(g,fx,h,draw);
yexogD(h,draw) = yexog2(h,draw) - yexog1(h,draw);
cyD(draw)     = cy2(draw) - cy1(draw) ;
cryD(draw)    = cry2(draw) - cry1(draw) ;

*Now represent these as percentage changes from base
pPC(g,draw)$p1(g,draw) = 100*pD(g,draw) / p1(g,draw) ;
pvaPC(g,h,draw)$pva1(g,h,draw) = 100*pvaD(g,h,draw) / pva1(g,h,draw) ;
rPC(g,f,h,draw)$r1(g,f,h,draw) = 100*rD(g,f,h,draw) / r1(g,f,h,draw) ;
wPC(f,draw)$w1(f,draw) = 100*wD(f,draw) / w1(f,draw) ;
qpPC(g,h,draw)$qp1(g,h,draw) = 100*qpD(g,h,draw) / qp1(g,h,draw) ;
qvaPC(g,h,draw)$qva1(g,h,draw) = 100*qvaD(g,h,draw) / qva1(g,h,draw) ;
idPC(g,gg,h,draw)$id1(g,gg,h,draw) = 100*idD(g,gg,h,draw) / id1(g,gg,h,draw) ;
fdPC(g,f,h,draw)$fd1(g,f,h,draw) = 100*fdD(g,f,h,draw) / fd1(g,f,h,draw) ;
hfdPC(f,h,draw)$hfd1(f,h,draw) = 100*hfdD(f,h,draw) / hfd1(f,h,draw) ;
yPC(h,draw)$y1(h,draw) = 100*yD(h,draw) / y1(h,draw) ;
cpiPC(h,draw)   = cpiD(h,draw)/cpi1(h,draw) ;
ryPC(h,draw)    = ryD(h,draw)/ry1(h,draw) ;
qcPC(g,h,draw)$qc1(g,h,draw) =100* qcD(g,h,draw) / qc1(g,h,draw) ;
hmsPC(g,h,draw)$hms1(g,h,draw) = 100*hmsD(g,h,draw) / hms1(g,h,draw) ;
vmsPC(g,draw)$vms1(g,draw) = 100*vmsD(g,draw) / vms1(g,draw) ;
hfmsPC(f,h,draw)$hfms1(f,h,draw) = 100*hfmsD(f,h,draw) / hfms1(f,h,draw) ;
vfmsPC(f,draw)$vfms1(f,draw) = 100*vfmsD(f,draw) / vfms1(f,draw) ;
hfsupPC(f,h,draw)$hfsup1(f,h,draw) = 100*hfsupD(f,h,draw)/hfsup1(f,h,draw) ;
fixfacPC(g,fx,h,draw)$fixfac1(g,fx,h,draw) = 100*fixfacD(g,fx,h,draw) / fixfac1(g,fx,h,draw);
yexogPC(h,draw)$yexog1(h,draw) = 100*yexogD(h,draw) / yexog1(h,draw);
cyPC(draw)$cy1(draw) = 100*cyD(draw) / cy1(draw) ;
cryPC(draw)    = cryD(draw)/cry1(draw) ;

display p2, pva2, r2, w2, qp2, id2, fd2, hfd2, y2, ry2, cpi2, qc2, hms2, vms2, hfms2, vfms2, cy2, cry2 ;

display pD, pvaD, rD, wD, qpD, idD, fdD, hfdD, yD, ryD, cpiD, qcD, hmsD, vmsD, hfmsD, vfmsD, cyD, cryD ;

display pPC, pvaPC, rPC, wPC, qpPC, idPC, fdPC, hfdPC, yPC, ryPC, cpiPC, qcPC, hmsPC, vmsPC, hfmsPC, vfmsPC, cyPC, cryPC ;


* Output results
*=============================================


*The rest of this program simply prepares the results to create nice tables in EXCEL
*-----------------------------------------------------------------------
* Now output parameters with mean and variance
*-----------------------------------------------------------------------
set mv /mean, stdev, pct5, pct95/ ;

abort$(card(draw) le 1) "ONE REPETITION ONLY - NO MEANS OR STDEVS TO COMPUTE";

Parameters
* Base Solution Mean and Std. Dev. Across Draws
     p1_mv(g,mv)      Price of g on the village markets
     pva1_mv(g,h,mv)  Price value added for each household
     r1_mv(g,f,h,mv)  Rent for inputs fixed in production of g by h
     w1_mv(f,mv)      Wage for tradable inputs (common for the village)
     qp1_mv(g,h,mv)    Quantity of g produced by h
     qva1_mv(g,h,mv)   Quantity value added
     id1_mv(g,gg,h,mv) Intermediate demand for g in prodution of gg by h
     fd1_mv(g,f,h,mv)  Factor demand for f in production of g by h
     hfd1_mv(f,h,mv) Household total use of factors
     y1_mv(h,mv)      Nominal Income of household h
     cpi1_mv(h,mv)    Consumer price index for household h
     ry1_mv(h,mv)     Real income of household h
     qc1_mv(g,h,mv)   Quantity of g consumed by h
     hms1_mv(g,h,mv)  Marketed surplus of g in the household-economy
     vms1_mv(g,mv)    Marketed surplus of g in the village economy
     hfms1_mv(f,h,mv)  Marketed surplus of f in the household-economy
     vfms1_mv(f,mv)    Marketed surplus of f in the village economy
     hfsup1_mv(f,h,mv) Tradable factor supply
     ly1_mv(f,h,mv)    Labor income
     fxy1_mv(f,h,mv)    capital income
     fixfac1_mv(g,f,h,mv) fixed factor
     yexog1_mv(h,mv)      exogenous income
     cy1_mv(mv)      Combined Nominal Income
     cry1_mv(mv)     Combined Real income
* Experiment Outcome Mean and Std. Dev. Across Draws
     p2_mv(g,mv)      Price of g on the village markets
     pva2_mv(g,h,mv)  Price value added for each household
     r2_mv(g,f,h,mv)  Rent for inputs fixed in production of g by h
     w2_mv(f,mv)      Wage for tradable inputs (common for the village)
     qp2_mv(g,h,mv)    Quantity of g produced by h
     qva2_mv(g,h,mv)
     id2_mv(g,gg,h,mv) Intermediate demand for g in prodution of gg by h
     fd2_mv(g,f,h,mv)  Factor demand for f in production of g by h
     hfd2_mv(f,h,mv) Household total use of factors
     y2_mv(h,mv)      Nominal Income of household h
     cpi2_mv(h,mv)    Consumer price index for household h
     ry2_mv(h,mv)     Real income of household h
     qc2_mv(g,h,mv)   Quantity of g consumed by h
     hms2_mv(g,h,mv)  Marketed surplus of g in the household-economy
     vms2_mv(g,mv)    Marketed surplus of g in the village economy
     hfms2_mv(f,h,mv)  Marketed surplus of f in the household-economy
     vfms2_mv(f,mv)    Marketed surplus of f in the village economy
     hfsup2_mv(f,h,mv) Tradable factor supply
     ly2_mv(f,h,mv)    Labor income
     fxy2_mv(f,h,mv)    capital income
     fixfac2_mv(g,f,h,mv) fixed factor
     yexog2_mv(h,mv)      exogenous income
     cy2_mv(mv)      Combined Nominal Income
     cry2_mv(mv)     Combined Real income
* Experiment Outcome Mean and Std. Dev. of Change from Base Across Draws
     pD_mv(g,mv)      Price of g on the village markets
     pvaD_mv(g,h,mv)  Price value added for each household
     rD_mv(g,f,h,mv)  Rent for inputs fixed in production of g by h
     wD_mv(f,mv)      Wage for tradable inputs (common for the village)
     qpD_mv(g,h,mv)    Quantity of g produced by h
     qvaD_mv(g,h,mv)
     idD_mv(g,gg,h,mv) Intermediate demand for g in prodution of gg by h
     fdD_mv(g,f,h,mv)  Factor demand for f in production of g by h
     hfdD_mv(f,h,mv) Household total use of factors
     yD_mv(h,mv)      Nominal Income of household h
     cpiD_mv(h,mv)    Consumer price index for household h
     ryD_mv(h,mv)     Real income of household h
     qcD_mv(g,h,mv)   Quantity of g consumed by h
     hmsD_mv(g,h,mv)  Marketed surplus of g in the household-economy
     vmsD_mv(g,mv)    Marketed surplus of g in the village economy
     hfmsD_mv(f,h,mv)  Marketed surplus of f in the household-economy
     vfmsD_mv(f,mv)    Marketed surplus of f in the village economy
     hfsupD_mv(f,h,mv)
     lyD_mv(f,h,mv)    Labor income
     fxyD_mv(f,h,mv)    capital income
     fixfacD_mv(g,f,h,mv) fixed factor
     yexogD_mv(h,mv)      exogenous income
     cyD_mv(mv)      Combined Nominal Income
     cryD_mv(mv)     Combined Real income
* Experiment Outcome % Change Mean and Std. Dev. Across Draws
     pPC_mv(g,mv)      Price of g on the village markets
     pvaPC_mv(g,h,mv)  Price value added for each household
     rPC_mv(g,f,h,mv)  Rent for inputs fixed in production of g by h
     wPC_mv(f,mv)      Wage for tradable inputs (common for the village)
     qpPC_mv(g,h,mv)    Quantity of g produced by h
     qvaPC_mv(g,h,mv)
     idPC_mv(g,gg,h,mv) Intermediate demand for g in prodution of gg by h
     fdPC_mv(g,f,h,mv)  Factor demand for f in production of g by h
     hfdPC_mv(f,h,mv) Household total use of factors
     yPC_mv(h,mv)      Nominal Income of household h
     cpiPC_mv(h,mv)    Consumer price index for household h
     ryPC_mv(h,mv)     Real income of household h
     qcPC_mv(g,h,mv)   Quantity of g consumed by h
     hmsPC_mv(g,h,mv)  Marketed surplus of g in the household-economy
     vmsPC_mv(g,mv)    Marketed surplus of g in the village economy
     hfmsPC_mv(f,h,mv)  Marketed surplus of f in the household-economy
     vfmsPC_mv(f,mv)    Marketed surplus of f in the village economy
     hfsupPC_mv(f,h,mv)
     lyPC_mv(f,h,mv)     Labor income
     fxyPC_mv(f,h,mv)    capital income
     fixfacPC_mv(g,f,h,mv) fixed factor
     yexogPC_mv(h,mv)      exogenous income
     cyPC_mv(mv)      Combined Nominal Income
     cryPC_mv(mv)     Combined Real income
;

*These commands calculate means and standard deviations of desired simulation outcomes (we desired a lot of them!):
p1_mv(g,"mean") = sum(draw, p1(g,draw)) / card(draw) ;
p1_mv(g,"stdev") = sqrt(sum(draw, sqr(p1(g,draw) - p1_mv(g,"mean")))/(card(draw)-1)) ;
pva1_mv(g,h,"mean") = sum(draw, pva1(g,h,draw)) / card(draw) ;
pva1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(pva1(g,h,draw) - pva1_mv(g,h,"mean")))/(card(draw)-1)) ;
r1_mv(g,f,h,"mean") = sum(draw, r1(g,f,h,draw)) / card(draw) ;
r1_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(r1(g,f,h,draw) - r1_mv(g,f,h,"mean")))/(card(draw)-1)) ;
w1_mv(f,"mean") = sum(draw, w1(f,draw)) / card(draw) ;
w1_mv(f,"stdev") = sqrt(sum(draw, sqr(w1(f,draw) - w1_mv(f,"mean")))/(card(draw)-1)) ;
qva1_mv(g,h,"mean") = sum(draw, qva1(g,h,draw)) / card(draw) ;
qva1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qva1(g,h,draw) - qva1_mv(g,h,"mean")))/(card(draw)-1)) ;
qp1_mv(g,h,"mean") = sum(draw, qp1(g,h,draw)) / card(draw) ;
qp1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qp1(g,h,draw) - qp1_mv(g,h,"mean")))/(card(draw)-1)) ;
id1_mv(g,gg,h,"mean") = sum(draw, id1(g,gg,h,draw)) / card(draw) ;
id1_mv(g,gg,h,"stdev") = sqrt(sum(draw, sqr(id1(g,gg,h,draw) - id1_mv(g,gg,h,"mean")))/(card(draw)-1)) ;
fd1_mv(g,f,h,"mean") = sum(draw, fd1(g,f,h,draw)) / card(draw) ;
fd1_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fd1(g,f,h,draw) - fd1_mv(g,f,h,"mean")))/(card(draw)-1)) ;
hfd1_mv(f,h,"mean") = sum(draw, hfd1(f,h,draw)) / card(draw) ;
hfd1_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfd1(f,h,draw) - hfd1_mv(f,h,"mean")))/(card(draw)-1)) ;
y1_mv(h,"mean") = sum(draw, y1(h,draw)) / card(draw) ;
y1_mv(h,"stdev") = sqrt(sum(draw, sqr(y1(h,draw) - y1_mv(h,"mean")))/(card(draw)-1)) ;
cpi1_mv(h,"mean") = sum(draw, cpi1(h,draw)) / card(draw) ;
cpi1_mv(h,"stdev") = sqrt(sum(draw, sqr(cpi1(h,draw) - cpi1_mv(h,"mean")))/(card(draw)-1)) ;
ry1_mv(h,"mean") = sum(draw, ry1(h,draw)) / card(draw) ;
ry1_mv(h,"stdev") = sqrt(sum(draw, sqr(ry1(h,draw) - ry1_mv(h,"mean")))/(card(draw)-1)) ;
qc1_mv(g,h,"mean") = sum(draw, qc1(g,h,draw)) / card(draw) ;
qc1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qc1(g,h,draw) - qc1_mv(g,h,"mean")))/(card(draw)-1)) ;
hms1_mv(g,h,"mean") = sum(draw, hms1(g,h,draw)) / card(draw) ;
hms1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(hms1(g,h,draw) - hms1_mv(g,h,"mean")))/(card(draw)-1)) ;
vms1_mv(g,"mean") = sum(draw, vms1(g,draw)) / card(draw) ;
vms1_mv(g,"stdev") = sqrt(sum(draw, sqr(vms1(g,draw) - vms1_mv(g,"mean")))/(card(draw)-1)) ;
hfms1_mv(f,h,"mean") = sum(draw, hfms1(f,h,draw)) / card(draw) ;
hfms1_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfms1(f,h,draw) - hfms1_mv(f,h,"mean")))/(card(draw)-1)) ;
vfms1_mv(f,"mean") = sum(draw, vfms1(f,draw)) / card(draw) ;
vfms1_mv(f,"stdev") = sqrt(sum(draw, sqr(vfms1(f,draw) - vfms1_mv(f,"mean")))/(card(draw)-1)) ;
fixfac1_mv(g,f,h,"mean") = sum(draw, fixfac1(g,f,h,draw)) / card(draw) ;
fixfac1_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fixfac1(g,f,h,draw) - fixfac1_mv(g,f,h,"mean")))/(card(draw)-1)) ;
yexog1_mv(h,"mean") = sum(draw, yexog1(h,draw)) / card(draw) ;
yexog1_mv(h,"stdev") = sqrt(sum(draw, sqr(yexog1(h,draw) - yexog1_mv(h,"mean")))/(card(draw)-1)) ;
hfsup1_mv(f,h,"mean") = sum(draw, hfsup1(f,h,draw)) / card(draw) ;
hfsup1_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfsup1(f,h,draw) - hfsup1_mv(f,h,"mean")))/(card(draw)-1)) ;
cy1_mv("mean") = sum(draw, cy1(draw)) / card(draw) ;
cy1_mv("stdev") = sqrt(sum(draw, sqr(cy1(draw) - cy1_mv("mean")))/(card(draw)-1)) ;
cry1_mv("mean") = sum(draw, cry1(draw)) / card(draw) ;
cry1_mv("stdev") = sqrt(sum(draw, sqr(cry1(draw) - cry1_mv("mean")))/(card(draw)-1)) ;

p2_mv(g,"mean") = sum(draw, p2(g,draw)) / card(draw) ;
p2_mv(g,"stdev") = sqrt(sum(draw, sqr(p2(g,draw) - p2_mv(g,"mean")))/(card(draw)-1)) ;
pva2_mv(g,h,"mean") = sum(draw, pva2(g,h,draw)) / card(draw) ;
pva2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(pva2(g,h,draw) - pva2_mv(g,h,"mean")))/(card(draw)-1)) ;
r2_mv(g,f,h,"mean") = sum(draw, r2(g,f,h,draw)) / card(draw) ;
r2_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(r2(g,f,h,draw) - r2_mv(g,f,h,"mean")))/(card(draw)-1)) ;
w2_mv(f,"mean") = sum(draw, w2(f,draw)) / card(draw) ;
w2_mv(f,"stdev") = sqrt(sum(draw, sqr(w2(f,draw) - w2_mv(f,"mean")))/(card(draw)-1)) ;
qva2_mv(g,h,"mean") = sum(draw, qva2(g,h,draw)) / card(draw) ;
qva2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qva2(g,h,draw) - qva2_mv(g,h,"mean")))/(card(draw)-1)) ;
qp2_mv(g,h,"mean") = sum(draw, qp2(g,h,draw)) / card(draw) ;
qp2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qp2(g,h,draw) - qp2_mv(g,h,"mean")))/(card(draw)-1)) ;
id2_mv(g,gg,h,"mean") = sum(draw, id2(g,gg,h,draw)) / card(draw) ;
id2_mv(g,gg,h,"stdev") = sqrt(sum(draw, sqr(id2(g,gg,h,draw) - id2_mv(g,gg,h,"mean")))/(card(draw)-1)) ;
fd2_mv(g,f,h,"mean") = sum(draw, fd2(g,f,h,draw)) / card(draw) ;
fd2_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fd2(g,f,h,draw) - fd2_mv(g,f,h,"mean")))/(card(draw)-1)) ;
hfd2_mv(f,h,"mean") = sum(draw, hfd2(f,h,draw)) / card(draw) ;
hfd2_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfd2(f,h,draw) - hfd2_mv(f,h,"mean")))/(card(draw)-1)) ;
y2_mv(h,"mean") = sum(draw, y2(h,draw)) / card(draw) ;
y2_mv(h,"stdev") = sqrt(sum(draw, sqr(y2(h,draw) - y2_mv(h,"mean")))/(card(draw)-1)) ;
cpi2_mv(h,"mean") = sum(draw, cpi2(h,draw)) / card(draw) ;
cpi2_mv(h,"stdev") = sqrt(sum(draw, sqr(cpi2(h,draw) - cpi2_mv(h,"mean")))/(card(draw)-1)) ;
ry2_mv(h,"mean") = sum(draw, ry2(h,draw)) / card(draw) ;
ry2_mv(h,"stdev") = sqrt(sum(draw, sqr(ry2(h,draw) - ry2_mv(h,"mean")))/(card(draw)-1)) ;
qc2_mv(g,h,"mean") = sum(draw, qc2(g,h,draw)) / card(draw) ;
qc2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qc2(g,h,draw) - qc2_mv(g,h,"mean")))/(card(draw)-1)) ;
hms2_mv(g,h,"mean") = sum(draw, hms2(g,h,draw)) / card(draw) ;
hms2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(hms2(g,h,draw) - hms2_mv(g,h,"mean")))/(card(draw)-1)) ;
vms2_mv(g,"mean") = sum(draw, vms2(g,draw)) / card(draw) ;
vms2_mv(g,"stdev") = sqrt(sum(draw, sqr(vms2(g,draw) - vms2_mv(g,"mean")))/(card(draw)-1)) ;
hfms2_mv(f,h,"mean") = sum(draw, hfms2(f,h,draw)) / card(draw) ;
hfms2_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfms2(f,h,draw) - hfms2_mv(f,h,"mean")))/(card(draw)-1)) ;
vfms2_mv(f,"mean") = sum(draw, vfms2(f,draw)) / card(draw) ;
vfms2_mv(f,"stdev") = sqrt(sum(draw, sqr(vfms2(f,draw) - vfms2_mv(f,"mean")))/(card(draw)-1)) ;
fixfac2_mv(g,f,h,"mean") = sum(draw, fixfac2(g,f,h,draw)) / card(draw) ;
fixfac2_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fixfac2(g,f,h,draw) - fixfac2_mv(g,f,h,"mean")))/(card(draw)-1)) ;
yexog2_mv(h,"mean") = sum(draw, yexog2(h,draw)) / card(draw) ;
yexog2_mv(h,"stdev") = sqrt(sum(draw, sqr(yexog2(h,draw) - yexog2_mv(h,"mean")))/(card(draw)-1)) ;
hfsup2_mv(f,h,"mean") = sum(draw, hfsup2(f,h,draw)) / card(draw) ;
hfsup2_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfsup2(f,h,draw) - hfsup2_mv(f,h,"mean")))/(card(draw)-1)) ;
cy2_mv("mean") = sum(draw, cy2(draw)) / card(draw) ;
cy2_mv("stdev") = sqrt(sum(draw, sqr(cy2(draw) - cy2_mv("mean")))/(card(draw)-1)) ;
cry2_mv("mean") = sum(draw, cry2(draw)) / card(draw) ;
cry2_mv("stdev") = sqrt(sum(draw, sqr(cry2(draw) - cry2_mv("mean")))/(card(draw)-1)) ;

pD_mv(g,"mean") = sum(draw, pD(g,draw)) / card(draw) ;
pD_mv(g,"stdev") = sqrt(sum(draw, sqr(pD(g,draw) - pD_mv(g,"mean")))/(card(draw)-1)) ;
pvaD_mv(g,h,"mean") = sum(draw, pvaD(g,h,draw)) / card(draw) ;
pvaD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(pvaD(g,h,draw) - pvaD_mv(g,h,"mean")))/(card(draw)-1)) ;
rD_mv(g,f,h,"mean") = sum(draw, rD(g,f,h,draw)) / card(draw) ;
rD_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(rD(g,f,h,draw) - rD_mv(g,f,h,"mean")))/(card(draw)-1)) ;
wD_mv(f,"mean") = sum(draw, wD(f,draw)) / card(draw) ;
wD_mv(f,"stdev") = sqrt(sum(draw, sqr(wD(f,draw) - wD_mv(f,"mean")))/(card(draw)-1)) ;
qvaD_mv(g,h,"mean") = sum(draw, qvaD(g,h,draw)) / card(draw) ;
qvaD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qvaD(g,h,draw) - qvaD_mv(g,h,"mean")))/(card(draw)-1)) ;
qpD_mv(g,h,"mean") = sum(draw, qpD(g,h,draw)) / card(draw) ;
qpD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qpD(g,h,draw) - qpD_mv(g,h,"mean")))/(card(draw)-1)) ;
idD_mv(g,gg,h,"mean") = sum(draw, idD(g,gg,h,draw)) / card(draw) ;
idD_mv(g,gg,h,"stdev") = sqrt(sum(draw, sqr(idD(g,gg,h,draw) - idD_mv(g,gg,h,"mean")))/(card(draw)-1)) ;
fdD_mv(g,f,h,"mean") = sum(draw, fdD(g,f,h,draw)) / card(draw) ;
fdD_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fdD(g,f,h,draw) - fdD_mv(g,f,h,"mean")))/(card(draw)-1)) ;
hfdD_mv(f,h,"mean") = sum(draw, hfdD(f,h,draw)) / card(draw) ;
hfdD_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfdD(f,h,draw) - hfdD_mv(f,h,"mean")))/(card(draw)-1)) ;
yD_mv(h,"mean") = sum(draw, yD(h,draw)) / card(draw) ;
yD_mv(h,"stdev") = sqrt(sum(draw, sqr(yD(h,draw) - yD_mv(h,"mean")))/(card(draw)-1)) ;
cpiD_mv(h,"mean") = sum(draw, cpiD(h,draw)) / card(draw) ;
cpiD_mv(h,"stdev") = sqrt(sum(draw, sqr(cpiD(h,draw) - cpiD_mv(h,"mean")))/(card(draw)-1)) ;
ryD_mv(h,"mean") = sum(draw, ryD(h,draw)) / card(draw) ;
ryD_mv(h,"stdev") = sqrt(sum(draw, sqr(ryD(h,draw) - ryD_mv(h,"mean")))/(card(draw)-1)) ;
qcD_mv(g,h,"mean") = sum(draw, qcD(g,h,draw)) / card(draw) ;
qcD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qcD(g,h,draw) - qcD_mv(g,h,"mean")))/(card(draw)-1)) ;
hmsD_mv(g,h,"mean") = sum(draw, hmsD(g,h,draw)) / card(draw) ;
hmsD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(hmsD(g,h,draw) - hmsD_mv(g,h,"mean")))/(card(draw)-1)) ;
vmsD_mv(g,"mean") = sum(draw, vmsD(g,draw)) / card(draw) ;
vmsD_mv(g,"stdev") = sqrt(sum(draw, sqr(vmsD(g,draw) - vmsD_mv(g,"mean")))/(card(draw)-1)) ;
hfmsD_mv(f,h,"mean") = sum(draw, hfmsD(f,h,draw)) / card(draw) ;
hfmsD_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfmsD(f,h,draw) - hfmsD_mv(f,h,"mean")))/(card(draw)-1)) ;
vfmsD_mv(f,"mean") = sum(draw, vfmsD(f,draw)) / card(draw) ;
vfmsD_mv(f,"stdev") = sqrt(sum(draw, sqr(vfmsD(f,draw) - vfmsD_mv(f,"mean")))/(card(draw)-1)) ;
fixfacD_mv(g,f,h,"mean") = sum(draw, fixfacD(g,f,h,draw)) / card(draw) ;
fixfacD_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fixfacD(g,f,h,draw) - fixfacD_mv(g,f,h,"mean")))/(card(draw)-1)) ;
yexogD_mv(h,"mean") = sum(draw, yexogD(h,draw)) / card(draw) ;
yexogD_mv(h,"stdev") = sqrt(sum(draw, sqr(yexogD(h,draw) - yexogD_mv(h,"mean")))/(card(draw)-1)) ;
hfsupD_mv(f,h,"mean") = sum(draw, hfsupD(f,h,draw)) / card(draw) ;
hfsupD_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfsupD(f,h,draw) - hfsupD_mv(f,h,"mean")))/(card(draw)-1)) ;
cyD_mv("mean") = sum(draw, cyD(draw)) / card(draw) ;
cyD_mv("stdev") = sqrt(sum(draw, sqr(cyD(draw) - cyD_mv("mean")))/(card(draw)-1)) ;
cryD_mv("mean") = sum(draw, cryD(draw)) / card(draw) ;
cryD_mv("stdev") = sqrt(sum(draw, sqr(cryD(draw) - cryD_mv("mean")))/(card(draw)-1)) ;

pPC_mv(g,"mean") = sum(draw, pPC(g,draw)) / card(draw) ;
pPC_mv(g,"stdev") = sqrt(sum(draw, sqr(pPC(g,draw) - pPC_mv(g,"mean")))/(card(draw)-1)) ;
pvaPC_mv(g,h,"mean") = sum(draw, pvaPC(g,h,draw)) / card(draw) ;
pvaPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(pvaPC(g,h,draw) - pvaPC_mv(g,h,"mean")))/(card(draw)-1)) ;
rPC_mv(g,f,h,"mean") = sum(draw, rPC(g,f,h,draw)) / card(draw) ;
rPC_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(rPC(g,f,h,draw) - rPC_mv(g,f,h,"mean")))/(card(draw)-1)) ;
wPC_mv(f,"mean") = sum(draw, wPC(f,draw)) / card(draw) ;
wPC_mv(f,"stdev") = sqrt(sum(draw, sqr(wPC(f,draw) - wPC_mv(f,"mean")))/(card(draw)-1)) ;
qvaPC_mv(g,h,"mean") = sum(draw, qvaPC(g,h,draw)) / card(draw) ;
qvaPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qvaPC(g,h,draw) - qvaPC_mv(g,h,"mean")))/(card(draw)-1)) ;
qpPC_mv(g,h,"mean") = sum(draw, qpPC(g,h,draw)) / card(draw) ;
qpPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qpPC(g,h,draw) - qpPC_mv(g,h,"mean")))/(card(draw)-1)) ;
idPC_mv(g,gg,h,"mean") = sum(draw, idPC(g,gg,h,draw)) / card(draw) ;
idPC_mv(g,gg,h,"stdev") = sqrt(sum(draw, sqr(idPC(g,gg,h,draw) - idPC_mv(g,gg,h,"mean")))/(card(draw)-1)) ;
fdPC_mv(g,f,h,"mean") = sum(draw, fdPC(g,f,h,draw)) / card(draw) ;
fdPC_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fdPC(g,f,h,draw) - fdPC_mv(g,f,h,"mean")))/(card(draw)-1)) ;
hfdPC_mv(f,h,"mean") = sum(draw, hfdPC(f,h,draw)) / card(draw) ;
hfdPC_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfdPC(f,h,draw) - hfdPC_mv(f,h,"mean")))/(card(draw)-1)) ;
yPC_mv(h,"mean") = sum(draw, yPC(h,draw)) / card(draw) ;
yPC_mv(h,"stdev") = sqrt(sum(draw, sqr(yPC(h,draw) - yPC_mv(h,"mean")))/(card(draw)-1)) ;
cpiPC_mv(h,"mean") = sum(draw, cpiPC(h,draw)) / card(draw) ;
cpiPC_mv(h,"stdev") = sqrt(sum(draw, sqr(cpiPC(h,draw) - cpiPC_mv(h,"mean")))/(card(draw)-1)) ;
ryPC_mv(h,"mean") = sum(draw, ryPC(h,draw)) / card(draw) ;
ryPC_mv(h,"stdev") = sqrt(sum(draw, sqr(ryPC(h,draw) - ryPC_mv(h,"mean")))/(card(draw)-1)) ;
qcPC_mv(g,h,"mean") = sum(draw, qcPC(g,h,draw)) / card(draw) ;
qcPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qcPC(g,h,draw) - qcPC_mv(g,h,"mean")))/(card(draw)-1)) ;
hmsPC_mv(g,h,"mean") = sum(draw, hmsPC(g,h,draw)) / card(draw) ;
hmsPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(hmsPC(g,h,draw) - hmsPC_mv(g,h,"mean")))/(card(draw)-1)) ;
vmsPC_mv(g,"mean") = sum(draw, vmsPC(g,draw)) / card(draw) ;
vmsPC_mv(g,"stdev") = sqrt(sum(draw, sqr(vmsPC(g,draw) - vmsPC_mv(g,"mean")))/(card(draw)-1)) ;
hfmsPC_mv(f,h,"mean") = sum(draw, hfmsPC(f,h,draw)) / card(draw) ;
hfmsPC_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfmsPC(f,h,draw) - hfmsPC_mv(f,h,"mean")))/(card(draw)-1)) ;
vfmsPC_mv(f,"mean") = sum(draw, vfmsPC(f,draw)) / card(draw) ;
vfmsPC_mv(f,"stdev") = sqrt(sum(draw, sqr(vfmsPC(f,draw) - vfmsPC_mv(f,"mean")))/(card(draw)-1)) ;
fixfacPC_mv(g,f,h,"mean") = sum(draw, fixfacPC(g,f,h,draw)) / card(draw) ;
fixfacPC_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fixfacPC(g,f,h,draw) - fixfacPC_mv(g,f,h,"mean")))/(card(draw)-1)) ;
yexogPC_mv(h,"mean") = sum(draw, yexogPC(h,draw)) / card(draw) ;
yexogPC_mv(h,"stdev") = sqrt(sum(draw, sqr(yexogPC(h,draw) - yexogPC_mv(h,"mean")))/(card(draw)-1)) ;
hfsupPC_mv(f,h,"mean") = sum(draw, hfsupPC(f,h,draw)) / card(draw) ;
hfsupPC_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfsupPC(f,h,draw) - hfsupPC_mv(f,h,"mean")))/(card(draw)-1)) ;
cyPC_mv("mean") = sum(draw, cyPC(draw)) / card(draw) ;
cyPC_mv("stdev") = sqrt(sum(draw, sqr(cyPC(draw) - cyPC_mv("mean")))/(card(draw)-1)) ;
cryPC_mv("mean") = sum(draw, cryPC(draw)) / card(draw) ;
cryPC_mv("stdev") = sqrt(sum(draw, sqr(cryPC(draw) - cryPC_mv("mean")))/(card(draw)-1)) ;

* Display the mean and std. dev. of base, experiment, change, and % change for outcomes of interest
display p1_mv, pva1_mv, qva1_mv, qp1_mv, fd1_mv, id1_mv, r1_mv, w1_mv,
        fixfac1_mv, yexog1_mv, hfsup1_mv, qc1_mv, y1_mv, cpi1_mv, ry1_mv,
        hfd1_mv, hms1_mv, vms1_mv, hfms1_mv, vfms1_mv, cy1_mv, cry1_mv;
display p2_mv, pva2_mv, qva2_mv, qp2_mv, fd2_mv, id2_mv, r2_mv, w2_mv,
        fixfac2_mv, yexog2_mv, hfsup2_mv, qc2_mv, y2_mv, cpi2_mv, ry2_mv,
        hfd2_mv, hms2_mv, vms2_mv, hfms2_mv, vfms2_mv, cy2_mv, cry2_mv;
display pD_mv, pvaD_mv, qvaD_mv, qpD_mv, fdD_mv, idD_mv, rD_mv, wD_mv,
        fixfacD_mv, yexogD_mv, hfsupD_mv, qcD_mv, yD_mv, cpiD_mv, ryD_mv,
        hfdD_mv, hmsD_mv, vmsD_mv, hfmsD_mv, vfmsD_mv, cyD_mv, cryD_mv;
display pPC_mv, pvaPC_mv, qvaPC_mv, qpPC_mv, fdPC_mv, idPC_mv, rPC_mv, wPC_mv,
        fixfacPC_mv, yexogPC_mv, hfsupPC_mv, qcPC_mv, yPC_mv, cpiPC_mv, ryPC_mv,
        hfdPC_mv, hmsPC_mv, vmsPC_mv, hfmsPC_mv, vfmsPC_mv, cyPC_mv, cryPC_mv;


* Next we set up the table--a text file easily imported into EXCEL
* We need additional output for the table:
* Factor incomes by type of factor (fixed, labor)
fxy1(fx,h,draw)= sum(gp, r1(gp,fx,h,draw)*fd1(gp,fx,h,draw)) ;
ly1(ft,h,draw)= w1(ft,draw)*hfsup1(ft,h,draw);
fxy2(fx,h,draw)= sum(gp, r2(gp,fx,h,draw)*fd2(gp,fx,h,draw)) ;
ly2(ft,h,draw)= w2(ft,draw)*hfsup2(ft,h,draw);
fxyD(fx,h,draw)=  fxy2(fx,h,draw)-fxy1(fx,h,draw);
lyD(ft,h,draw)= ly2(ft,h,draw)-ly1(ft,h,draw);
fxyPC(fx,h,draw)=  100*fxyD(fx,h,draw)/fxy1(fx,h,draw);
lyPC(ft,h,draw)$ly1(ft,h,draw)= 100*lyD(ft,h,draw)/ly1(ft,h,draw);
display fxy1, ly1, fxy2,ly2, fxyD, lyD, fxyPC, lyPC;

* And we compute their mean and stdev for output in the table:
ly1_mv(ft,h,"mean") = sum(draw, ly1(ft,h,draw)) / card(draw) ;
ly1_mv(ft,h,"stdev") = sqrt(sum(draw, sqr(ly1(ft,h,draw) - ly1_mv(ft,h,"mean")))/(card(draw)-1)) ;
ly2_mv(ft,h,"mean") = sum(draw, ly2(ft,h,draw)) / card(draw) ;
ly2_mv(ft,h,"stdev") = sqrt(sum(draw, sqr(ly2(ft,h,draw) - ly2_mv(ft,h,"mean")))/(card(draw)-1)) ;
lyD_mv(ft,h,"mean") = sum(draw, lyD(ft,h,draw)) / card(draw) ;
lyD_mv(ft,h,"stdev") = sqrt(sum(draw, sqr(lyD(ft,h,draw) - lyD_mv(ft,h,"mean")))/(card(draw)-1)) ;
lyPC_mv(ft,h,"mean") = sum(draw, lyPC(ft,h,draw)) / card(draw) ;
lyPC_mv(ft,h,"stdev") = sqrt(sum(draw, sqr(lyPC(ft,h,draw) - lyPC_mv(ft,h,"mean")))/(card(draw)-1)) ;

fxy1_mv(fx,h,"mean") = sum(draw, fxy1(fx,h,draw)) / card(draw) ;
fxy1_mv(fx,h,"stdev") = sqrt(sum(draw, sqr(fxy1(fx,h,draw) - fxy1_mv(fx,h,"mean")))/(card(draw)-1)) ;
fxy2_mv(fx,h,"mean") = sum(draw, fxy2(fx,h,draw)) / card(draw) ;
fxy2_mv(fx,h,"stdev") = sqrt(sum(draw, sqr(fxy2(fx,h,draw) - fxy2_mv(fx,h,"mean")))/(card(draw)-1)) ;
fxyD_mv(fx,h,"mean") = sum(draw, fxyD(fx,h,draw)) / card(draw) ;
fxyD_mv(fx,h,"stdev") = sqrt(sum(draw, sqr(fxyD(fx,h,draw) - fxyD_mv(fx,h,"mean")))/(card(draw)-1)) ;
fxyPC_mv(fx,h,"mean") = sum(draw, fxyPC(fx,h,draw)) / card(draw) ;
fxyPC_mv(fx,h,"stdev") = sqrt(sum(draw, sqr(fxyPC(fx,h,draw) - fxyPC_mv(fx,h,"mean")))/(card(draw)-1)) ;
display fxy1_mv, ly1_mv, fxy2_mv,ly2_mv, fxyD_mv, lyD_mv, fxyPC_mv, lyPC_mv ;


* Now we make some aggregate parameters to present in the tables
* such as total increase in output, total increase in labor supply, etc.
parameter tsup1(g,draw)  initial total supply of g
          tlsup1(f,draw) initial total tradable factor supply in the economy
          tsup2(g,draw)  final total supply of g
          tlsup2(f,draw) final total tradable factor supply in the economy
          tsupD(g,draw)  delta total supply of g
          tlsupD(f,draw) delta initial total trade with rest of world
;

* total supply is total production/endowment + imports (if any)
tsup1(g,draw) = sum(h,qp1(g,h,draw)) - min(0,vms1(g,draw)) ;
tlsup1(ft,draw) = sum(h,hfsup1(ft,h,draw)) - min(0,vfms1(ft,draw)) ;
* same after the shock:
tsup2(g,draw) = sum(h,qp2(g,h,draw)) - min(0,vms2(g,draw)) ;
tlsup2(ft,draw) = sum(h,hfsup2(ft,h,draw)) - min(0,vfms2(ft,draw)) ;
* And the diffs:
tsupD(g,draw) = tsup2(g,draw)-tsup1(g,draw) ;
tlsupD(ft,draw) = tlsup2(ft,draw)-tlsup1(ft,draw) ;
display tsup1, tsup2, tsupD, tlsup1, tlsup2, tlsupD;


* If we want to reproduce the SAM multiplier results we need to compute those a bit differently
* because the SAM model assumes Intermediate Demand never reaches markets
parameter tsupsam1(g,draw) total supply like in the SAM multiplier
          tlsupsam1(f,draw) labor supply outside the hh + purchased on market
          rowsupsam1(draw) total trade with rest of world
          tsupsam2(g,draw)
          tlsupsam2(f,draw)
          rowsupsam2(draw) total trade with rest of world
          tsupsamD(g,draw)
          tlsupsamD(f,draw)
          rowsupsamD(draw) total trade with rest of world  ;

* total supply is quantity produced net of intermediate inputs, plus imports:
tsupsam1(g,draw) = sum(h,qp1(g,h,draw) - sum(gg,id1(gg,g,h,draw)) )- min(0,vms1(g,draw)) ;
tlsupsam1(ft,draw) = sum(h,max(0,hfms1(ft,h,draw))) - min(0,vfms1(ft,draw)) ;
rowsupsam1(draw) = -sum(g,min(0,vms1(g,draw))) - sum(f, min(0,vfms1(f,draw)))  ;
* same after the shock:
tsupsam2(g,draw) = sum(h,qp2(g,h,draw) - sum(gg,id2(gg,g,h,draw)) )- min(0,vms2(g,draw)) ;
tlsupsam2(ft,draw) = sum(h,max(0,hfms2(ft,h,draw))) - min(0,vfms2(ft,draw)) ;
rowsupsam2(draw) = -sum(g,min(0,vms2(g,draw))) - sum(f, min(0,vfms2(f,draw))) ;
* and the deltas:
tsupsamD(g,draw) = tsupsam2(g,draw)-tsupsam1(g,draw) ;
tlsupsamD(ft,draw) = tlsupsam2(ft,draw)-tlsupsam1(ft,draw) ;
rowsupsamD(draw) = rowsupsam2(draw)-rowsupsam1(draw) ;
display tsupsam1, tsupsam2, tsupsamD, tlsupsam1, tlsupsam2, tlsupsamD,
        rowsupsam1, rowsupsam2, rowsupsamD ;


* And now compute the means and variables for those parameters:
parameter tsupsamD_mv(g,mv)
          tlsupsamD_mv(f,mv)
          rowsupsamD_mv(mv) ;
tsupsamD_mv(g,"mean")  = sum(draw,tsupsamD(g,draw))/(card(draw));
tsupsamD_mv(g,"stdev") = sqrt(sum(draw, sqr(tsupsamD(g,draw) - tsupsamD_mv(g,"mean")))/(card(draw)-1)) ;
tlsupsamD_mv(f,"mean") = sum(draw,tlsupsamD(f,draw))/(card(draw));
tlsupsamD_mv(f,"stdev") = sqrt(sum(draw, sqr(tlsupsamD(f,draw) - tlsupsamD_mv(f,"mean")))/(card(draw)-1)) ;
rowsupsamD_mv("mean")  = sum(draw,rowsupsamD(draw))/(card(draw));
rowsupsamD_mv("stdev") = sqrt(sum(draw, sqr(rowsupsamD(draw) - rowsupsamD_mv("mean")))/(card(draw)-1)) ;


* Sets to output which simulation was made:
set kchange(g,fx,h) indicator set of capital having changed ;
kchange(g,fx,h)$fdD_mv(g,fx,h,"mean") = yes ;
display kchange ;
display rPC ;

* Compute the lower and higher confidence bounds 5 and 95:
*------------------------------------------------------------
set lh(mv) lower higher quantiles /pct5, pct95 /
parameter Torank(draw)
          Ranks(draw)
* add percentiles to "ci" if you want to know more percentile values,
* for instance adding ", med 50" will compute 50th percentile and call it "med"
* (note: in that example you must also add "med" to the mv and lh sets)
          ci(lh) confidence interval definition /pct5 5, pct95 95/
          ci2(lh) confidence intervals (values) ;

* this initialises the use of the "rank" procedure, which we need to compute percentiles
$libinclude rank

* This loops over all the households and, for each one, ranks the values of changes
* in outcomes then computes the percentiles we chose in the "ci" parameter.
* This is looped because the "rank" procedure only works for one-dimentional parameters,
* so we make a one-dimentional parameter and overwrite it for each household in turn.

* Syntax for rank routine is:
* $libinclude rank Torank draw Ranks ci2

* The arguments are defined as following:
* Input:
*         Torank(draw) Outcomes to rank (across draws)
*         draw         draw in Monte-Carlo; the domain of Torank
* Output:
*         Ranks(draw)  Rank order of element Torank(draw), an integer between 1
*                      and card(draw), ranking from smallest to largest across
*                      all the draws.
*         ci2(lh)      On input this vector specifies percentile levels to be
*                      computed. On output, it returns the linearly interpolated
*                      percentiles.

* Loop through household groups:
loop(h,
* Assign that hh group's outcome change in each draw to parameter Torank(draw)
* (Here, the outcome is change in nominal income):
     Torank(draw) = yD(h,draw) ;
* The rank routine requires an input of percentile levels to be computed, which
* are pct5, pct95:
     ci2(lh) = ci(lh);
* Perform the ranking, saving the rank of each draw in Ranks and the high/low
* percentile levels in ci2:
$libinclude rank Torank draw Ranks ci2
* Display to make sure it worked:
     display Torank, Ranks, ci ;
* Now save the high/low perentile levels of the outcome (the endpoints of the
* 90% confidence interval) in yD_mv(h,lh) (remember the domain of yD_mv is h,mv,
* and lh is a subset of mv=(mean, stdev, pct5, pct95)
     yD_mv(h,lh) = ci2(lh) ;
* To begin the hh loop for the next outcome of interest, we will have to reset
* ci2(lh) to equal ci(lh)
);
display yD_mv;

*Now do the same for all the other outcomes of interest
loop(h,
     Torank(draw) = ryD(h,draw) ;
     ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
     display Torank, Ranks, ci ;
     ryD_mv(h,lh) = ci2(lh) ;
);
display ryD_mv;

loop(h,
     loop(g,
          Torank(draw) = qpD(g,h,draw) ;
          ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
          display Torank, Ranks, ci ;
          qpD_mv(g,h,lh) = ci2(lh) ;
     );
);
display qpD_mv;

loop(h,
     loop(f,
          Torank(draw) = lyD(f,h,draw) ;
          ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
          display Torank, Ranks, ci ;
          lyD_mv(f,h,lh) = ci2(lh) ;
     );
);
display lyD_mv;

loop(h,
     loop(f,
          Torank(draw) = fxyD(f,h,draw) ;
          ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
          display Torank, Ranks, ci ;
          fxyD_mv(f,h,lh) = ci2(lh) ;
     );
);
display fxyD_mv;

loop(g,
     Torank(draw) = tsupsamD(g,draw) ;
     ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
     display Torank, Ranks, ci ;
     tsupsamD_mv(g,lh) = ci2(lh) ;
);
display tsupsamD_mv;

loop(f,
     Torank(draw) = tlsupsamD(f,draw) ;
     ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
     display Torank, Ranks, ci ;
     tlsupsamD_mv(f,lh) = ci2(lh) ;
);
display tlsupsamD_mv;

Torank(draw) = rowsupsamD(draw) ;
ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
display Torank, Ranks, ci ;
rowsupsamD_mv(lh) = ci2(lh) ;
display rowsupsamD_mv;

Torank(draw) = cyD(draw) ;
ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
display Torank, Ranks, ci ;
cyD_mv(lh) = ci2(lh) ;
display cyD_mv;

Torank(draw) = cryD(draw) ;
ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
display Torank, Ranks, ci ;
cryD_mv(lh) = ci2(lh) ;
display cryD_mv;


* The following uses the "put" command to produce a text file that is easily imported
* into EXCEL to make nice tables for our chapter. The text file is called
* 'Chap3Tab8_.txt'. Just open it up in EXCEL as a semi-colon delimited file,
* or cut+paste it and hit the "text-to-columns" button defining semi-colons as separators.

file tab_miniMonteL /Chap3Tab8c.txt/;
put tab_miniMonteL ;

put 'Assumptions' @33 ';' /;
if (card(kchange), put @45 ';' 'K change' ;);
put /;

put 'Elasticity of lab supply'   @40'; ' %supel%:<6 /;

put 'Endogenous goods and factors'  @40 '; '
loop (gnt, put gnt.tl:<7 ',' );

loop(ftv,
     put ftv.tl:<7 ','
);
put /;

put 'Traded outside the village'   @40 '; '
loop(gt,
     put gt.tl:<7 ','
);
loop(ftw,
     put ftw.tl:<7 ','
);
put /;


put 'Income shock to Poor HH'  @40'; '  yexogD_mv("poor","mean"):<6:2 /;

put 'Household and outcome' @40'; ' /;
put 'Poor Household' @40'; ' /;
put 'Activities' @40'; '  /;
loop(g$(not sameas(g,"exog")),
     put g.tl  @40'; ' qpD_mv(g,"poor","mean"):6.2
     @60';' '(' qpD_mv(g,"poor","pct5"):6:2 ',' qpD_mv(g,"poor","pct95"):6:2 ')'/ ;
);
put 'Factor incomes' @40'; '  /;
put 'Labor' @40'; ' lyD_mv("labo","poor","mean")
@60';' '(' lyD_mv("labo","poor","pct5"):6:2 ',' lyD_mv("labo","poor","pct95"):6:2 ')'/ ;
put 'Capital' @40'; ' fxyD_mv("capi","poor","mean")
@60';' '(' fxyD_mv("capi","poor","pct5"):6:2 ',' fxyD_mv("capi","poor","pct95"):6:2 ')'/ ;
put 'Nominal Income' @40'; ' yD_mv("poor","mean")
@60';' '(' yD_mv("poor","pct5"):6:2 ',' yD_mv("poor","pct95"):6:2 ')'/ ;
put 'Real Income' @40'; ' ryD_mv("poor","mean")
@60';' '(' ryD_mv("poor","pct5"):6:2 ',' ryD_mv("poor","pct95"):6:2 ')'/ ;

put 'Non-poor Household' @40'; ' /;
put 'Activities' @40'; '  /;
loop(g$(not sameas(g,"exog")),
     put g.tl  @40'; ' qpD_mv(g,"nonpoor","mean"):6.2
     @60';' '(' qpD_mv(g,"nonpoor","pct5"):6:2 ',' qpD_mv(g,"nonpoor","pct95"):6:2 ')'/ ;
);
put 'Factor incomes' @40'; '  /;
put 'Labor' @40'; ' lyD_mv("labo","nonpoor","mean")
@60';' '(' lyD_mv("labo","nonpoor","pct5"):6:2 ',' lyD_mv("labo","nonpoor","pct95"):6:2 ')'/
put 'Capital' @40'; ' fxyD_mv("capi","nonpoor","mean")
@60';' '(' fxyD_mv("capi","nonpoor","pct5"):6:2 ',' fxyD_mv("capi","nonpoor","pct95"):6:2 ')'/ ;
put 'Nominal Income' @40'; ' yD_mv("nonpoor","mean")
@60';' '(' yD_mv("nonpoor","pct5"):6:2 ',' yD_mv("nonpoor","pct95"):6:2 ')'/ ;
put 'Real Income' @40'; ' ryD_mv("nonpoor","mean")
@60';' '(' ryD_mv("nonpoor","pct5"):6:2 ',' ryD_mv("nonpoor","pct95"):6:2 ')'/ ;

put 'Markets' @40 '; ' /;
loop(g$(not sameas(g,"exog")),
     put g.tl @40 '; ' tsupsamD_mv(g,"mean")
     @60';' '(' tsupsamD_mv(g,"pct5"):6:2 ',' tsupsamD_mv(g,"pct95"):6:2 ')'/ ;
);
put 'labor' @40 '; ' tlsupsamD_mv("labo","mean")
     @60';' '(' tlsupsamD_mv("labo","pct5"):6:2 ',' tlsupsamD_mv("labo","pct95"):6:2 ')' / ;
put 'row' @40 '; ' rowsupsamD_mv("mean")
     @60';' '(' rowsupsamD_mv("pct5"):6:2 ',' rowsupsamD_mv("pct95"):6:2 ')'/ ;


