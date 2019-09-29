$TITLE MEXICO LEWIE MODEL - MIGRATION
* Mateusz Filipski, July 2013

* * This model makes table 13.2 and figures 13.1 to 13.4 in Beyond Experiments.

* The model reads in data from an excel spreadsheet in the form of parameter distributions
* Then it draws from those distributions and constructs a SAM from the values drawn
* Then it uses those same values to calibrate a village economywide model
* Then it runs long-run simulations with recursive updates of capital stock.
* We use the PATH solver (requires a PATH license in GAMS)


* ##############################################################################################
* REPRODUCING THE TABLE 13.2 and figures 13.1 to 13.4 in the book:
* ##############################################################################################
* Run the program: output files in excel format will pop up, in these files:
$setlocal outLRexcel_table  "Ch13_Table_13-2_rev5.xlsx"
$setlocal outLRexcel "Ch13_LongRunCharts_rev5.xlsx"
* ##############################################################################################

* Results displayed in the book were obtained with these parameters:
* 1) Number of draws in the LEWIE loops (the second number, 10 minimum if you want percentiles computed)
set draw /dr0*dr10/ ;
* 2) The elasticity of supply of labor - hired and family
$setlocal hlse 10
$setlocal flse 10
* 3) Elasticity of remittances
* We estimated 0.961*** using a FE estimate as in described in the chapter  (***=1%)
* (household Fixed Effects.  Using first 2 rounds.)
$setlocal remel 0.961
* ##############################################################################################

* A few useful gams options
option limrow=30 ;
option limcol=30 ;




* #################################################################################################
* Understanding the output:
* = Parameters with a "_dr" suffix are the inputs to each round of simulation. They were either
* drawn from a distribution, or are computed so that the economy is at equilibrium (given the drawn parameters)
* The first draw is "dr0" and corresponds to the mean values of the parameter distributions.
* ex: shcobb_dr(g,f,h,draw) is the cobb douglas factor share drawn from the known distributions of factor shares
*     shcobb_dr(g,f,h,"dr0") is the mean of that cobb douglas factor share known distribution
*     endow_dr(f,h,draw) is the household endowment of factor that is consistent with the draws of shcobb_dr

* = Parameters with a "1" suffix are the values generated from the calibration run of each drawns model. In theory
* they should be identical to the _dr parameters, because those were chosen to satisfy the model equations.

* = Parameters with a "2" suffix are the values generated from the simulation performed on each draw.
* = Parameters with a "D" suffix are the level changes between the "2" and "1" parameter of the same name. ex: yD(h,draw) = y2(h,draw)-y1(h,draw)
* = Parameters with a "PC" suffix are the % changes from "1" level.  ex: tqpPC(g,draw) = tqpD(g,draw)/tqp1(g,draw)
* = Multipliers are computed for each draw. ex: ymult_h(h,draw) is the change in nominal income of a household / the transfer it received

* The above parameters are all indexed by draw. IE, if we do 1000 iterations, there will be 1000 observations of those parameters.
* = Parameters with a "_mv" suffix contain MEANS, STDEV, and for some PERCENTILES of the parameters that are indexed by draw.
* ex: yD_mv(h,"mean") = sum(draw, yD(h,draw)) / card(draw) ;
*     yD_mv(h,"stdev") = sqrt(sum(draw, sqr(yD(h,draw) - yD_mv(h,"mean")))/(card(draw)-1)) ;

* = Multipliers also have "_mv" versions. ex: ymult_all_mv(mv) holds the means, stdev, and percentiles of the overall nominal income multiplier.
* #################################################################################################


* ================================================================================================
* ================================================================================================
* ==================== STEP 1 - READ IN FROM EXCEL ===============================================
* ================================================================================================
* ================================================================================================

* Name the sets that will be used:
sets
ac all accounts
g(ac) goods
f(ac) factors
h(ac) households
var  variable names
;
parameter Alldata(*,*,*,*,h);

* Read in the data from LEWIE spreadsheet:
* the $call reads XL data and makes a .gdx file with it
* (unstar the "call" statement to re-read from the excel spreadsheet)
$call "gdxxrw input=Mexico_Recession_LEWIE_data.xlsx output=MexMigData10.gdx index=Index!A2"
* The "Index" tab of the XL spreadsheet tells the gdxxrw procedure where things are.

* the $gdxin opens the data loading procedure and calls the .gdx file we just made
$gdxin MexMigData10.gdx
$load AC G F H VAR ALLDATA
display ac, g, f, h, var, ALLDATA ;

* This option controls the decimals and display format
option alldata:2:4:1;
display alldata;

* the phantom element "null" can be put in a set to avoid leaving the set empty in some simulations
* (GAMS can't handle empty sets)
$phantom null

* subsets and aliases
*=====================
sets
* factor subsets
     fk(f)     fixed factors / K, LAND /
     ft(f)     tradable inputs / HL, FL, PURCH /
     ftv(f)    factors tradable in the village /FL, HL,  null /
     ftz(f)    factors tradable in the whole zoi  / null /
     ftw(f)    factors tradables in the rest of the world /  PURCH /
     fpurch(f) purchased factors /PURCH/
     fe(f)     factors potentially unemployed /FL/

* goods subsets
     gtv(g)    goods tradable in the village / crop, live, ret,   ser,  null  /
     gtz(g)    goods tradable in the zoi   /null /
     gtw(g)    goods tradable with the rest of the world / prod ,outside/
     gp(g)     goods that are produces / crop, ret, ser, live, prod /
     gag(g)    ag goods /crop, live/
     gnag(g)   non ag goods /ret, ser, prod /

* household subsets
     ht(h)     recipients in this simulation (can be n or m or both) / m, null/


* accounts not in the matrix (only one representative village in this model)
sets
     v        villages / T treated /
     maphv mapping housheold to their village / (m,n).T /
;


* ##############################################################################################
* ##############################################################################################
* ##############################################################################################


display g, f, h, fk, ft, ftv, ftz, ftw, gtv, gtz, gtw, gp, v, mapHv ;

* Read in the matrix:
*======================================================
alias (ac, aca) ;
alias (g,gg)
      (h,hh)
      (f,fa) ;

* Get raw values for input variables and some parameter values
parameter
     xlID(gg,g,h)          intermediate demand for of gg for production of g by h
     xlFD(g,f,h)           factor demand in g production by h
     xlbeta(g,f,h)         exponent on factor f in produciton of g
     xlbetase(g,f,h)       standard error on beta(gfh)
     xlacobb(g,h)          shift parameter on production of g
     xlacobbse(g,h)        standard error on acobb
     xlalpha(g,h)          consumption share of income
     xlalphase(g,h)        consumption share of income
     xlcmin(g,h)           incompressible consumption
     xlendow(f,h)          endowment of factors in the economy
     xlROCendow(f,h)       endowment of factors outside the economy
     xlROWendow(f,h)       endowment of factors outside the country
     xlTRINsh(h)           cash transfers given to other households (share of income)
     xlTROUTsh(h)          cash transfers received from other households  (share of expenditures)
     xlTRINshse(h)         standard error of cash transfers given to other households (share of income)
     xlTROUTshse(h)        standard error of cash transfers received from other households  (share of expenditures)
     xlSAVsh(h)            share of income going to informal savings
     xlSAVshse(h)          standard error of share of income going to informal savings
     xllabexp(h)           not sure what this is and why there's a negative value
     xlexpoutsh(h)         share of expenditures on outside goods
     xlremus(f,h)          level of remittances
     xlremmx(f,h)          level of national remittances
     xlothertransfers(h)   level of exogenous transfers
     xlnhh(h)              number of households represented by this
     xlhhinc(h)            mean household income
     xlhhexp(h)            mean household expenditures
     xlhhsize(h)           mean household size
     xlrevsh_vil(g,h)      share of business in the village
     xlrevsh_zoi(g,h)      share of business in the zoi
     xlrevsh_roc(g,h)      share of business in the rest of lesotho
     xlrevsh_row(g,h)      share of business in the row
     xlVA2IDsh(g,gg,h)     for each dollar of VA how much ID was consumed
;

xlID(gg,g,h) = alldata("INTD",g,gg,"",h) ;
xlFD(g,f,h) = alldata("FD",g,"",f,h) ;
xlbeta(g,f,h) = alldata("beta",g,"",f,h) ;
xlbetase(g,f,h) = alldata("se",g,"",f,h) ;

xlacobb(g,h) = (alldata("acobb",g,"","",h)) ;
xlacobbse(g,h) = (alldata("acobbse",g,"","",h)) ;

xlalpha(g,h) = alldata("alpha",g,"","",h) ;
xlalphase(g,h) = alldata("alphase",g,"","",h) ;
xlcmin(g,h) = alldata("cmin",g,"","",h) ;

xlendow(f,h) = alldata("endow","","",f,h) + alldata("zoiendow","","",f,h) ;
xlendow("FL",h) = sum(g, xlFD(g,"FL",h));
xlendow("LAND",h) = sum(g, xlFD(g,"LAND",h));
xlendow("K",h) = sum(g, xlFD(g,"K",h));
xlROCendow(f,h) = alldata("ROCendow","","",f,h) ;
xlROWendow(f,h) = alldata("ROWendow","","",f,h) ;

xlTROUTsh(h) = alldata("TRANSFOUT","","","",h) ;
xlTRINsh(h) = alldata("TRANSFIN","","","",h) ;
xlTROUTshse(h) = alldata("TRANSFOUTse","","","",h) ;
xlTRINshse(h) = alldata("TRANSFINse","","","",h) ;

xlSAVsh(h) = alldata("sav","","","",h) ;
* Data added later (provided by J.K. - thanks!):
xlSAVsh("N") = 0.02 ;
xlSAVsh("M") = 0.03 ;

xlSAVshse(h) = alldata("savse","","","",h) ;
xlexpoutsh(h) = alldata("exproles","","","",h) ;

* assuming remittances come from laborers that would have been hirable HL
xlremus("HL",h)  =  alldata("remitsUS","","","",h);
xlremmx("HL",h)  =  alldata("remitsMX","","","",h) ;

xlothertransfers(h)  =  alldata("NONSCtransfers","","","",h) ;

xlnhh(h) = alldata("NumberHH","","","",h) ;
xlhhinc(h) = alldata("HHinc","","","",h) ;
xlhhexp(h) = alldata("HHexp","","","",h) ;
xlhhsize(h) = alldata("HHsize","","","",h) ;

xlrevsh_vil(g,h) = alldata("revsh_vil",g,"","",h) ;
xlrevsh_zoi(g,h) = alldata("revsh_zoi",g,"","",h) ;
xlrevsh_roc(g,h) = alldata("revsh_rok",g,"","",h) ;
xlrevsh_row(g,h) = alldata("revsh_row",g,"","",h) ;

xlVA2IDsh(gg,g,h) = alldata("VA2IDsh",g,gg,"",h) ;


display xlID, xlFD, xlbeta, xlbetase, xlacobb, xlacobbse, xlalpha, xlcmin, xlendow, xlROCendow, xlROWendow,
     xlTROUTsh, xlTRINsh, xlTROUTshse, xlTRINshse, xlSAVsh, xlSAVshse,
     xlexpoutsh,  xlothertransfers, xlnhh, xlhhinc, xlhhexp, xlhhsize, xlrevsh_vil, xlrevsh_zoi,
     xlrevsh_roc, xlrevsh_row, xlVA2IDsh , xlremmx, xlremus;


* ================================================================================================
* ================================================================================================
* ========================= STEP 2 - WRITE THE CORE MODEL ========================================
* ================================================================================================
* ================================================================================================


* MODEL STARTS HERE
* ======================================================
* Now variables and parameters
* ---------------------------------
nonnegative variables
* production
     QP(g,h)        quantity produced of a good by a household
     FD(g,f,h)      factor demand of f in production of g
     ID(g,gg,h)     intermediate demand for production of g
     QVA(g,h)       quantity of value added created in the production process

     HFD(f,h)       factor demand in the household
     UNEMP(f,h)     unemployment in the household
     HFSUP(f,h)    labor supply from the household (elastic endowment)
     VFD(f,v)       initial factor demand in the village
     ZFD(f)         initial factor demand in the economy

     R(g,f,h)       rent for fixed factors
     WV(f,v)        wage at the village level
     WZ(f)          wage at the zoi level

* consumption
     QC(g,h)        quantity consumed of g by h
     Y(h)           nominal household income
     RY(h)          real household income
     CPI(h)         consumer price index

* values
     PV(g,v)        price of a good at the village level
     PZ(g)          price of a good at the zoi level
     PH(g,h)        price as seen by household h (zoi or village price depending on good)
     PVA(g,h)       price of value added net of intermediate inputs as seen by the household


* transfers
     TRIN(h)        tranfered in - received by a household
     TROUT(h)       transfers out - given by a household
     SAV(h)         household savings
     EXPROC(h)      household expenditures out of the zoi
* Remittances
     REMIT(f,h)     remittances in the households coming from f
     TREMIT(h)      total remittances from f
     MIG(f,h)        Migration (labor abroad)
;

variables
* trade
     HMS(g,h)  household marketed surplus of good g
     VMS(g,v)  village marketed surplus of good g
     ZMS(g)     ZOI marketed surplus of a good

     HFMS(f,h) factor marketed surplus from the household
     VFMS(f,v) factor marketed surplus out of the village
     ZFMS(f)   factor marketed surplus out of the zoi
;


parameters
*Production - Cobb-douglas
     acobb(g,h) production shift parameter for the CD
     shcobb(g,f,h) factor share parameter for the CD
     vash(g,h) share of value added
     idsh(gg,g,h) intermediate input share
     tidsh(g,h) total intermediate input share (1-vash)

*Consumption
     alpha(g,h) consumption share parameters in the LES
     cmin(g,h)  minimal consumption in the LES
     exinc(h)   exogenous income of household
     vmsfix(g,v) fixed marketed surplus at the village level
     zmsfix(g)  fixed marketed surplus at the zoi level

* factor endowments for fixed factors
     fixfac(g,f,h) fixed factors
     unempsh(f,h)  household's share of total unemployment
     vfmsfix(f,v)  factors fixed at the Village level (family labor)
     zfmsfix(f)    factors fixed at the zoi level (hired labor)
     endow(f,h)    endowment of factors
     hfsupzero(f,h) initial labor supply

* Factor supply
     hfsupel(f,h) factor supply elasticity from household

* Budget for purchased inputs - if we want to have a constraint
     pibudget(g,h) budget available for input purchases
     pibsh(g,h)    share of total pibudget going to good g

* Transfers
     troutsh(h) share of transfers in the households expenditures
     exprocsh(h)  share of expenditures outside of the zoi
     savsh(h)  share of income saved
     trinsh(h) share of total transfers received by a given household

* Experiment
     transfer(h) transfer given to a household through CT

* Remittance elasticity
     remshift(f,h)    shifter on the remittance funtion
     remelast(f,h)  remittance elasticity wrt local wage
;

Equations
* prices
     EQ_PVA(g,h)         prive value added equation
     EQ_PH(g,h)          market price as seen from household h

* production
     EQ_FDCOBB(g,f,h)    factor demands cobb douglas
     EQ_FDPURCH(g,f,h)   factor demands for purchased inputs - constrained or not
     EQ_QVACOBB(g,h)     quantity VA produced cobb douglas
     EQ_QP(g,h)          quantity produced from QVA and ID
     EQ_ID(gg,g,h)       quantity of ID needed for QP

* consumption
     EQ_QC(g,h)          quantity consumed

* income
     EQ_Y(h)             full income constraint for the household
     EQ_CPI(h)           consumer price index equation
     EQ_RY(h)            real household income equation

* transfers
     EQ_TRIN(h)          inter household transfers in (received)
     EQ_TROUT(h)         interhousehold transfers out (given)

* exogenous expenditures
     EQ_SAV(h)           savings (exogenous rate)
     EQ_EXPROC(h)        expenditures outside of the zoi (exogenous rate)

* goods market clearing
     EQ_HMKT(g,h)        qty clearing in each household
     EQ_VMKT(g,v)        market clearing in the village
     EQ_ZMKT(g)          market clearing in the zoi
     EQ_VMKTfix(g,v)     price definition in the village
     EQ_ZMKTfix(g)       price definition in the zoi

* factor market clearing
     EQ_HFD(f,h)         total household demand for a given factor
     EQ_FCSTR(g,f,h)     fixed factors constraint
     EQ_HFSUP(f,h)       household elastic supply
     EQ_HFMKT(f,h)       tradable factor clearing in the household
     EQ_VFMKT(f,v)       tradable factors clearing in the village
     EQ_ZFMKT(f)         tradable factor clearing in the zoi
     EQ_VFMKTfix(f,v)    wage determination for tradable factors clearing in the village
     EQ_ZFMKTfix(f)      wage determination for tradable factors clearing in the zoi

* Endogenous Remittances
     EQ_REM(f,h)         Remittances as a function of migration from the hh
     EQ_TREM(h)          Total remittances received from different migrant types
     EQ_MIG(f,h)         Optimal migration given wage rate of labor

;

*=============================================================================================
*==================== MODEL STATEMENT ========================================================
*=============================================================================================

* PRICE BLOCK
EQ_PH(g,h)..
     PH(g,h) =E= PZ(g)$(gtz(g)+gtw(g)) + sum(v$maphv(h,v),PV(g,v))$gtv(g) ;

EQ_PVA(g,h)..
     PVA(g,h) =E= PH(g,h)- sum(gg,idsh(gg,g,h)*PH(gg,h)) ;

* PRODUCTION BLOCK
EQ_QVACOBB(g,h)..
     QVA(g,h) =E= acobb(g,h)*prod(f,FD(g,f,h)**(shcobb(g,f,h)))
;

EQ_FDCOBB(g,f,h)$(not fpurch(f))..
     FD(g,f,h)*(R(g,f,h)$fk(f) + WZ(f)$(ftz(f)+ftw(f)) + sum(v$maphv(h,v),WV(f,v))$ftv(f) )
      =E= PVA(g,h)*QP(g,h)*shcobb(g,f,h)
;

* Purchased inputs are fixed for these simulations:
EQ_FDPURCH(g,f,h)$fpurch(f)..
     FD(g,f,h)*(R(g,f,h)$fk(f) + WZ(f)$(ftz(f)+ftw(f)) + sum(v$maphv(h,v),WV(f,v))$ftv(f))
      =E= pibudget(g,h)
;

EQ_QP(g,h)$vash(g,h)..
     QP(g,h) =E= QVA(g,h)/vash(g,h) ;

EQ_ID(gg,g,h)..
     ID(gg,g,h) =E= QP(g,h)*idsh(gg,g,h)
;

* CONSUMPTION AND INCOME
EQ_QC(g,h)..
     QC(g,h) =E= alpha(g,h)/PH(g,h)*[(Y(h)-TROUT(h)-SAV(h)-EXPROC(h))-sum(gg, PH(gg,h)*cmin(gg,h))] + cmin(g,h)
;

* Full income (value of factor endowments)
EQ_Y(h)..
     Y(h) =E= sum((g,fk),R(g,fk,h)*FD(g,fk,h))
            + sum(ftz, WZ(ftz)*HFSUP(ftz,h))
            + sum(ftv, sum(v$maphv(h,v), WV(ftv,v))*HFSUP(ftv,h))
            + sum(ftw, WZ(ftw)*HFSUP(ftw,h))
            + sum(f,REMIT(f,h))
            + exinc(h)
;

* CPI needs to include the value of exogenous expenditures.
* Their price stays 1 and income shares stay constant.
EQ_CPI(h)..
     CPI(h) =e= sum(g,PH(g,h)*[PH(g,h)*QC(g,h)/Y(h)])
                    +1*troutsh(h)+savsh(h)+exprocsh(h) ;
;

EQ_RY(h)..
     RY(h) =e= Y(h) / CPI(h)
;

* Transfers given away - exogenous in this version of the model
EQ_TROUT(h)..
     TROUT(h) =E= troutsh(h)*Y(h) ;
;

EQ_SAV(h)..
     SAV(h) =E= savsh(h)*Y(h) ;
;
EQ_EXPROC(h)..
     EXPROC(h) =E= exprocsh(h)*Y(h) ;
;

* MARKET CLEARING FOR GOODS
EQ_HMKT(g,h)..
     HMS(g,h) =E= QP(g,h)$gp(g) - QC(g,h) - sum(gg,ID(g,gg,h)) ;

EQ_VMKT(g,v)..
     VMS(g,v) =E= sum(h$maphv(h,v),HMS(g,h))
;

EQ_ZMKT(g)..
     ZMS(g) =E= sum(v, VMS(g,v))
;

EQ_VMKTfix(gtv,v)..
     VMS(gtv,v) =E= vmsfix(gtv,v)
;

EQ_ZMKTfix(gtz)..
     ZMS(gtz) =E= zmsfix(gtz)
;

* FACTOR MARKET CLEARING
EQ_HFD(f,h)..
     HFD(f,h) =e= sum(g, FD(g,f,h))
;

EQ_FCSTR(g,fk,h)..
     FD(g,fk,h) =E= fixfac(g,fk,h)
;

EQ_HFMKT(ft,h)..
     HFMS(ft,h) =E= HFSUP(ft,h) - sum(g, FD(g,ft,h)) - MIG(ft,h)$remelast(ft,h)
;

EQ_HFSUP(ft,h)..
     HFSUP(ft,h)$(not hfsupzero(ft,h))
     +
     (HFSUP(ft,h)/hfsupzero(ft,h) - [sum(v$maphv(h,v),WV(ft,v)**hfsupel(ft,h))$ftv(ft)
                                    + (WZ(ft)**hfsupel(ft,h))$(ftz(ft)+ftw(ft))] )$hfsupzero(ft,h)
     =e= 0
;

EQ_VFMKT(ft,v)..
     VFMS(ft,v) =E= sum(h$maphv(h,v), HFMS(ft,h))
;

EQ_ZFMKT(ft)..
     sum(v, VFMS(ft,v)) =E= ZFMS(ft)
;

* FACTOR WAGE DETERMINATION
EQ_VFMKTFIX(ftv,v)..
     VFMS(ftv,v) =E= vfmsfix(ftv,v)
;

EQ_ZFMKTFIX(ftz)..
     ZFMS(ftz) =E= zfmsfix(ftz)
;

* Migration
EQ_REM(f,h)..
     REMIT(f,h) =e= remshift(f,h)*(MIG(f,h)**remelast(f,h));
;

EQ_TREM(h)..
     TREMIT(h) =e= sum(f, REMIT(f,h))
;


*-------------------------------------------------------------------------------------------------
*--------------------------------------- ALTERNATIVE MODELS --------------------------------------
*-------------------------------------------------------------------------------------------------

model genCD Model with Cobb Douglas production /
EQ_PVA.PVA
EQ_PH.PH
EQ_QVACOBB.QVA
EQ_FDCOBB.FD
EQ_FDPURCH.FD
EQ_QP.QP
EQ_ID.ID
EQ_QC.QC
EQ_Y.Y
EQ_HMKT.HMS
EQ_VMKT.VMS
EQ_ZMKT.ZMS
EQ_VMKTfix.PV
EQ_ZMKTfix.PZ
EQ_HFD.HFD
EQ_FCSTR.R
EQ_HFMKT.HFMS
EQ_VFMKT.VFMS
EQ_ZFMKT.ZFMS
EQ_VFMKTfix.WV
EQ_ZFMKTfix.WZ
EQ_TROUT.TROUT
EQ_SAV.SAV
EQ_EXPROC.EXPROC

* elastic factor supply from the household
EQ_HFSUP.HFSUP
EQ_CPI.CPI
EQ_RY.RY

*Remittances:
EQ_REM.REMIT
EQ_TREM.TREMIT
/;


* ================================================================================================
* ================================================================================================
* ====================== STEP 3 - CALIBRATE THE MODEL  ===========================================
* ================================================================================================
* ================================================================================================

parameter
* meta-parameters with parameter draws
shcobb_t(g,f,h,draw)  unscaled draw the cobb-douglas prod shares
alpha_t(g,h,draw)     unscaled draw of consumption shares
pv_dr(g,v,draw)       drawn or computed from draw price at village level
pz_dr(g,draw)         drawn or computed from draw price at zoi level
ph_dr(g,h,draw)       drawn or computed from draw price as seen from household
pva_dr(g,h,draw)      drawn or computed from draw price of value added
qva_dr(g,h,draw)      drawn or computed from draw quantity of value added
qp_dr(g,h,draw)       drawn or computed from draw quantity produced
tqp_dr(g,draw)        drawn or computed total qty produced in the zoi
fd_dr(g,f,h,draw)     drawn or computed from draw factor demand
id_dr(g,gg,h,draw)    drawn or computed from draw intermediate demand
acobb_dr(g,h,draw)    drawn or computed from draw cobb-douglas shifter
shcobb_dr(g,f,h,draw) drawn or computed from draw cobb-douglas shares
r_dr(g,f,h,draw)      drawn or computed from draw rent for fixed factors
wv_dr(f,v,draw)       drawn or computed from draw village-wide wage for tradable factors
wz_dr(f,draw)         drawn or computed from draw zoi-wide wage for tradable factors
vash_dr(g,h,draw)     drawn or computed from draw value-added share
idsh_dr(gg,g,h,draw)  drawn or computed from draw intermediate demand share
tidsh_dr(gg,h,draw)   drawn or computed from draw total intermediate input share (1-vash)
fixfac_dr(g,f,h,draw) drawn or computed from draw fixed factor demand
unemp_dr(f,h,draw)    drawn or computed from draw unemployment
unempsh_dr(f,h,draw)  drawn or computed from draw hh share of total unemployment
vfmsfix_dr(f,v,draw)  drawn or computed from draw factors fixed at the Village level
zfmsfix_dr(f,draw)    drawn or computed from draw factors fixed at the zoi level
vmsfix_dr(g,v,draw)   drawn or computed from draw goods fixed at the Village level
zmsfix_dr(g,draw)     drawn or computed from draw goods fixed at the zoi level

exinc_dr(h,draw)      drawn or computed from draw exogenous income
remit_dr(f,h,draw)    drawn or computed from draw remittances
remshift_dr(f,h,draw) drawn or computed from draw remittance shift parameter
mig_dr(f,h,draw)      drawn or computed from draw migration
endow_dr(f,h,draw)    drawn or computed from draw endowment
qc_dr(g,h,draw)       drawn or computed from draw level of consumption
tqc_dr(g,draw)        drawn or computed from draw total qc
alpha_dr(g,h,draw)    drawn or computed from draw consumption shares
y_dr(h,draw)          drawn or computed from draw nominal hh income
cpi_dr(h,draw)        drawn or computed from draw consumer price index of hh
ry_dr(h,draw)         drawn or computed from draw real hh income
cmin_dr(g,h,draw)     drawn or computed from draw incompressible demand
trin_dr(h,draw)       drawn or computed from draw transfers in - received
trout_dr(h,draw)      drawn or computed from draw transfers out - given
trinsh_dr(h,draw)     drawn or computed from draw share of all transfers in the eco going to h
troutsh_dr(h,draw)    drawn or computed from draw share of yousehold h's income being given as transfers
hfd_dr(f,h,draw)      drawn or computed from draw factor demand of household h for factor f
vfd_dr(f,v,draw)      drawn or computed from draw village demand for factor f
zfd_dr(f,draw)        drawn or computed from draw zoi demand for factor f
hms_dr(g,h,draw)      drawn or computed from draw household marketed surplus of good g
vms_dr(g,v,draw)      drawn or computed from draw village marketed surplus of good g
zms_dr(g,draw)        drawn or computed from draw household marketed surplus of good g
hfms_dr(f,h,draw)     drawn or computed from draw household factor marketed surplus
vfms_dr(f,v,draw)     drawn or computed from draw village factor marketed surplus
zfms_dr(f,draw)       drawn or computed from draw zoi factor marketed surplus

savsh_dr(h,draw)      drawn or computed savings rate
sav_dr(h,draw)        drawn or computed savings level
exprocsh_dr(h,draw)   drawn or computed outside-of-zoi expenditures rate
exproc_dr(h,draw)     drawn or computed outside-of-zoi expenditures level
expzoish_dr(h,draw)   drawn or computed outside-of-zoi expenditures level




* calibration values in each draw
pv1(g,v,draw)       calibrated price at village level
pz1(g,draw)         calibrated price at zoi level
ph1(g,h,draw)       calibrated price as seen by household
pva1(g,h,draw)      calibrated price of value added
qva1(g,h,draw)      calibrated quantity of value added
qp1(g,h,draw)       calibrated quantity produced
tqp1(g,draw)        calibrated total quantity produced
fd1(g,f,h,draw)     calibrated factor demand
id1(g,gg,h,draw)    calibrated intermediate demand
acobb1(g,h,draw)    calibrated cobb-douglas shifter
shcobb1(g,f,h,draw) calibrated cobb-douglas shares
r1(g,f,h,draw)      calibrated rent for fixed factors
wv1(f,v,draw)       calibrated village-wide wage for tradable factors
wz1(f,draw)         calibrated zoi-wide wage for tradable factors
vash1(g,h,draw)     calibrated value-added share
idsh1(gg,g,h,draw)  calibrated intermediate demand share
tidsh1(gg,h,draw)   calibrated total intermediate input share (1-vash)
fixfac1(g,f,h,draw) calibrated fixed factor demand
exinc1(h,draw)      calibrated exogenous income
endow1(f,h,draw)    calibrated endowment
qc1(g,h,draw)       calibrated level of consumption
alpha1(g,h,draw)    calibrated consumption shares
y1(h,draw)          calibrated income of household
cpi1(h,draw)        calibrated cpi
vqc1(v,g,draw)      calibrated village consumption
vcpi1(v,draw)       calibrated village cpi
cri1(v,f,draw)      calibrated rent weighted index

ry1(h,draw)         calibrated real income
ty1(draw)           calibrated income total
try1(draw)          calibrated real income total
cmin1(g,h,draw)     calibrated incompressible demand
trin1(h,draw)       calibrated transfers in - received
trout1(h,draw)      calibrated transfers out - given
trinsh1(h,draw)     calibrated share of all transfers in the eco going to h
troutsh1(h,draw)    calibrated share of yousehold h's income being given as transfers
hfd1(f,h,draw)      calibrated factor demand of household h for factor f
vfd1(f,v,draw)      calibrated village demand for factor f
zfd1(f,draw)        calibrated zoi demand for factor f
hms1(g,h,draw)      calibrated household marketed surplus of good g
vms1(g,v,draw)      calibrated village marketed surplus of good g
zms1(g,draw)        calibrated household marketed surplus of good g
hfms1(f,h,draw)     calibrated household factor marketed surplus
vfms1(f,v,draw)     calibrated village factor marketed surplus
zfms1(f,draw)       calibrated zoi factor marketed surplus
vfmsfix1(f,v,draw)  calibrated factors fixed at the Village level (family labor)
zfmsfix1(f,draw)    calibrated factors fixed at the zoi level (hired labor)
hfsup1(f,h,draw)    calibrated factor supply by the household

remit1(f,h,draw)    calibrated remittances
tremit1(h,draw)     calibrated remittances for h
mig1(f,h,draw)      calibrated migration
sav1(h,draw)        calibrated savings this round



* after a simulation for each draw

pv2(g,v,draw)       simulated price at village level
pz2(g,draw)         simulated price at zoi level
ph2(g,h,draw)       simulated price as seen by household
pva2(g,h,draw)      simulated price of value added
qva2(g,h,draw)      simulated quantity of value added
qp2(g,h,draw)       simulated quantity produced
tqp2(g,draw)        simulated total quantity produced in the economy
fd2(g,f,h,draw)     simulated factor demand
id2(g,gg,h,draw)    simulated intermediate demand
acobb2(g,h,draw)    simulated cobb-douglas shifter
shcobb2(g,f,h,draw) simulated cobb-douglas shares
r2(g,f,h,draw)      simulated rent for fixed factors
wv2(f,v,draw)       simulated village-wide wage for tradable factors
wz2(f,draw)         simulated zoi-wide wage for tradable factors
vash2(g,h,draw)     simulated value-added share
idsh2(gg,g,h,draw)  simulated intermediate demand share
tidsh2(gg,h,draw)   simulated total intermediate input share (2-vash)
fixfac2(g,f,h,draw) simulated fixed factor demand
exinc2(h,draw)      simulated exogenous income
endow2(f,h,draw)    simulated endowment
qc2(g,h,draw)       simulated level of consumption
alpha2(g,h,draw)    simulated consumption shares
y2(h,draw)          simulated income of household
cpi2(h,draw)        simulated cpi
cri2(v,f,draw)      simulated capital rent index (cap rent in activity*weight of activity)
vqc2(v,g,draw)      simulated village consumption
vcpi2(v,draw)       simulated village cpi


ry2(h,draw)         simulated real income
ty2(draw)           simulated income total
try2(draw)          simulated real income total
cmin2(g,h,draw)     simulated incompressible demand
trin2(h,draw)       simulated transfers in - received
trout2(h,draw)      simulated transfers out - given
trinsh2(h,draw)     simulated share of all transfers in the eco going to h
troutsh2(h,draw)    simulated share of yousehold h's income being given as transfers
hfd2(f,h,draw)      simulated factor demand of household h for factor f
vfd2(f,v,draw)      simulated village demand for factor f
zfd2(f,draw)        simulated zoi demand for factor f
hms2(g,h,draw)      simulated household marketed surplus of good g
vms2(g,v,draw)      simulated village marketed surplus of good g
zms2(g,draw)        simulated household marketed surplus of good g
hfms2(f,h,draw)     simulated household factor marketed surplus
vfms2(f,v,draw)     simulated village factor marketed surplus
zfms2(f,draw)       simulated zoi factor marketed surplus
hfsup2(f,h,draw)    simulated factor supply by the household
remit2(f,h,draw)    simulated remittances
tremit2(h,draw)     simulated remittances for h
mig2(f,h,draw)      simulated migration
sav2(h,draw)        simulated savings this round

* delta calibration /simulation
pvD(g,v,draw)       delta price at village level
pzD(g,draw)         delta price at zoi level
phD(g,h,draw)       delta price as seen by household

pvaD(g,h,draw)      delta price of value added
qvaD(g,h,draw)      delta quantity of value added
qpD(g,h,draw)       delta quantity produced
tqpD(g,draw)        delta total qp
fdD(g,f,h,draw)     delta factor demand
idD(g,gg,h,draw)    delta intermediate demand
acobbD(g,h,draw)    delta cobb-douglas shifter
shcobbD(g,f,h,draw) delta cobb-douglas shares
rD(g,f,h,draw)      delta rent for fixed factors
wvD(f,v,draw)       delta village-wide wage for tradable factors
wzD(f,draw)         delta zoi-wide wage for tradable factors
vashD(g,h,draw)     delta value-added share
idshD(gg,g,h,draw)  delta intermediate demand share
tidshD(gg,h,draw)   delta total intermediate input share (1-vash)
fixfacD(g,f,h,draw) delta fixed factor demand
exincD(h,draw)      delta exogenous income
endowD(f,h,draw)    delta endowment
qcD(g,h,draw)       delta level of consumption
alphaD(g,h,draw)    delta consumption shares
yD(h,draw)          delta income of household
cpiD(h,draw)        delta cpi
criD(v,f,draw)      delta capital rent index (cap rent in activity*weight of activity)
vqcD(v,g,draw)      delta village consumption
vcpiD(v,draw)       delta village cpi

ryD(h,draw)         delta real income
tyD(draw)           delta income total
tryD(draw)          delta real income total
cminD(g,h,draw)     delta incompressible demand
trinD(h,draw)       delta transfers in - received
troutD(h,draw)      delta transfers out - given
trinshD(h,draw)     delta share of all transfers in the eco going to h
troutshD(h,draw)    delta share of yousehold h's income being given as transfers
hfdD(f,h,draw)      delta factor demand of household h for factor f
vfdD(f,v,draw)      delta village demand for factor f
zfdD(f,draw)        delta zoi demand for factor f
hmsD(g,h,draw)      delta household marketed surplus of good g
vmsD(g,v,draw)      delta village marketed surplus of good g
zmsD(g,draw)        delta household marketed surplus of good g
hfmsD(f,h,draw)     delta household factor marketed surplus
vfmsD(f,v,draw)     delta village factor marketed surplus
zfmsD(f,draw)       delta zoi factor marketed surplus
hfsupD(f,h,draw)    delta factor supply by the household
remitD(f,h,draw)    delta remittances
migD(f,h,draw)      delta migration
savD(h,draw)        delta savings this round
tremitD(h,draw)     delta remittances

* percent change calibration/simulation
pvPC(g,v,draw)        % change price at village level
pzPC(g,draw)          % chage price at zoi level
phPC(g,h,draw)        % change price as seen by household

pvaPC(g,h,draw)      % change price of value added
qvaPC(g,h,draw)      % change quantity of value added
qpPC(g,h,draw)       % change quantity produced
tqpPC(g,draw)        % change in total qp
fdPC(g,f,h,draw)     % change factor demand
idPC(g,gg,h,draw)    % change intermediate demand
acobbPC(g,h,draw)    % change cobb-douglas shifter
shcobbPC(g,f,h,draw) % change cobb-douglas shares
rPC(g,f,h,draw)      % change rent for fixed factors
wvPC(f,v,draw)       % change village-wide wage for tradable factors
wzPC(f,draw)         % change zoi-wide wage for tradable factors
vashPC(g,h,draw)     % change value-added share
idshPC(gg,g,h,draw)  % change intermediate demand share
tidshPC(gg,h,draw)   % change total intermediate input share (1-vash)
fixfacPC(g,f,h,draw) % change fixed factor demand
exincPC(h,draw)      % change exogenous income
endowPC(f,h,draw)    % change endowment
qcPC(g,h,draw)       % change level of consumption
alphaPC(g,h,draw)    % change consumption shares
yPC(h,draw)          % change income of household
cpiPC(h,draw)        % change in cpi
criPC(v,f,draw)      % change capital rent index (cap rent in activity*weight of activity)
vqcPC(v,g,draw)      % change village consumption
vcpiPC(v,draw)       % change village cpi


ryPC(h,draw)         % change in real income
tyPC(draw)           % change income total
tryPC(draw)          % change real income total
cminPC(g,h,draw)     % change incompressible demand
trinPC(h,draw)       % change transfers in - received
troutPC(h,draw)      % change transfers out - given
trinshPC(h,draw)     % change share of all transfers in the eco going to h
troutshPC(h,draw)    % change share of yousehold h's income being given as transfers
hfdPC(f,h,draw)      % change factor demand of household h for factor f
vfdPC(f,v,draw)      % change village demand for factor f
zfdPC(f,draw)        % change zoi demand for factor f
hmsPC(g,h,draw)      % change household marketed surplus of good g
vmsPC(g,v,draw)      % change village marketed surplus of good g
zmsPC(g,draw)        % change household marketed surplus of good g
hfmsPC(f,h,draw)     % change household factor marketed surplus
vfmsPC(f,v,draw)     % change village factor marketed surplus
zfmsPC(f,draw)       % change zoi factor marketed surplus
hfsupPC(f,h,draw)    % change factor supply by the household
remitPC(f,h,draw)    % change remittances
tremitPC(h,draw)     % change remittances
migPC(f,h,draw)      % change migration
savPC(h,draw)        % change savings this round
;


* PARAMETERS THAT ARE DRAWN
* =================================================================================
* default at initial values
shcobb_t(g,f,h,draw) = xlbeta(g,f,h);
acobb_dr(g,h,draw)   = xlacobb(g,h) ;
alpha_t(g,h,draw)    = xlalpha(g,h) ;
troutsh_dr(h,draw)   = xltroutsh(h) ;
savsh_dr(h,draw)     = xlSAVsh(h)   ;
exprocsh_dr(h,draw)  = xlexpoutsh(h) ;

* draw all values once - except for dr0 wich will be the xl base
shcobb_t(g,f,h,"dr0") = xlbeta(g,f,h);
alpha_t(g,h,"dr0")    = xlalpha(g,h) ;
troutsh_dr(h,"dr0")   = xltroutsh(h) ;
savsh_dr(h,"dr0")     = xlSAVsh(h)   ;
exprocsh_dr(h,"dr0")  = xlexpoutsh(h) ;

shcobb_t(g,f,h,draw)$(not sameas(draw,"dr0")) = normal(xlbeta(g,f,h),xlbetase(g,f,h));
alpha_t(g,h,draw)$(not sameas(draw,"dr0"))    = normal(xlalpha(g,h),xlalphase(g,h));
troutsh_dr(h,draw)$(not sameas(draw,"dr0"))   = normal(xltroutsh(h),xltroutshse(h));
savsh_dr(h,draw)$(not sameas(draw,"dr0"))     = normal(xlSAVsh(h),xlSAVshse(h));

display shcobb_t, alpha_t, troutsh_dr, savsh_dr, exprocsh_dr;


* ### DATA CHECKPOINT: avoid negative values
* correct the factor shares that were drawn negative
* -------------------------------------------------------------

* just for info, display the negatives:
parameter negshcobb_t(g,f,h,draw) ;
negshcobb_t(g,f,h,draw)$((shcobb_t(g,f,h,draw) le 0) or (shcobb_t(g,f,h,draw) ge 1)) = shcobb_t(g,f,h,draw);
display negshcobb_t;

* and correct with a while structure
loop((g,f,h,draw)$(xlFD(g,f,h)*((shcobb_t(g,f,h,draw) le 0) or (shcobb_t(g,f,h,draw) ge 1))),
     while((shcobb_t(g,f,h,draw) le 0) or (shcobb_t(g,f,h,draw) ge 1),
            shcobb_t(g,f,h,draw) = normal(xlbeta(g,f,h),xlbetase(g,f,h));
     );
);
display shcobb_t;
* finally, we can use that as our parameter draw:
shcobb_dr(g,f,h,draw)$shcobb_t(g,f,h,draw) = shcobb_t(g,f,h,draw)/sum(fa,shcobb_t(g,fa,h,draw)) ;
display shcobb_t, shcobb_dr ;


* now correct the expenditure shares that were drawn negative
* ------------------------------------------------------------
* just for info, display the negatives
parameter negalpha_t(g,h,draw) ;
negalpha_t(g,h,draw)$((alpha_t(g,h,draw) le 0) or (alpha_t(g,h,draw) ge 1)) = alpha_t(g,h,draw) ;
display negalpha_t;

* and correct with a while
loop((g,h,draw)$(xlalpha(g,h)*((alpha_t(g,h,draw) le 0) or (alpha_t(g,h,draw) ge 1))) ,
     while( (alpha_t(g,h,draw) le 0) or (alpha_t(g,h,draw) ge 1),
           alpha_t(g,h,draw) = normal(xlalpha(g,h),xlalphase(g,h));
     );
);
display alpha_t;
* finally we can use that as our parameter draw
alpha_dr(g,h,draw)  = alpha_t(g,h,draw)/sum(gg,alpha_t(gg,h,draw)) ;
parameter alch(h,draw) ;
alch(h,draw) = sum(gg,alpha_dr(gg,h,draw))
display alpha_dr, alch ;

* now correct the rest-of world expenditure shares.  They cannot be negative, and they cannot add up to more than 1
* (really, maybe they shouldn't add up to more than 0.3 or something)

*now correct the exogenous expenditures that were drawn negative OR that add up to a larger number than 1 ;
* so we make a loop in the loop:
expzoish_dr(h,draw) = 1-(troutsh_dr(h,draw)+savsh_dr(h,draw)+exprocsh_dr(h,draw)) ;
loop((h,draw),
     while( ((troutsh_dr(h,draw) < 0) or (troutsh_dr(h,draw) > 1))
            or ((savsh_dr(h,draw) < 0) or (savsh_dr(h,draw) > 1))
            or (expzoish_dr(h,draw) < 0),
               troutsh_dr(h,draw)$(not sameas(draw,"dr0")) = normal(xltroutsh(h),xltroutshse(h));
               savsh_dr(h,draw)$(not sameas(draw,"dr0")) = normal(xlSAVsh(h),xlSAVshse(h));
               expzoish_dr(h,draw) = 1-(troutsh_dr(h,draw)+savsh_dr(h,draw)+exprocsh_dr(h,draw)) ;
     );
);
display troutsh_dr, savsh_dr, exprocsh_dr, expzoish_dr;


* THOSE WERE THE PARAMETERS THAT ARE ACTUALLY DRAWN FROM A DISTRIBUTION
* ALL OTHER PARAMETERS EITHER FOLLOW FROM THOSE DRAWS (RATHER THAN DRAWN DIRECTLY)
* OR RESULT FROM ASSUMPTIONS OR CLOSURE RULES

* set wages and prices to 1:
pv_dr(gtv,v,draw) = 1 ;
pz_dr(g,draw) = 1 ;
ph_dr(g,h,draw) = [pz_dr(g,draw)$(gtz(g)+gtw(g)) + sum(v$maphv(h,v),pv_dr(g,v,draw))$gtv(g)] ;
display pv_dr, pz_dr, ph_dr ;
r_dr(g,fk,h,draw)     = 1 ;
wv_dr(ftv,v,draw)     = 1 ;
wz_dr(ft,draw)        = 1 ;

* remittances are fixed
remit_dr(f,h,draw)    = xlremus(f,h) ;
remelast("HL",h)    = %remel% ;
display remit_dr, remelast ;

* they define migration (wage being 1 in the base)
mig_dr(f,h,draw) = remelast(f,h)*remit_dr(f,h,draw)/1;
remshift_dr(f,h,draw)$mig_dr(f,h,draw) = remit_dr(f,h,draw) / mig_dr(f,h,draw)**remelast(f,h) ;

display mig_dr, remshift_dr;


* START FROM INCOME - TWO PORRIBILITIES:
y_dr(h,draw) = xlhhinc(h)*xlnhh(h) ;
* all prices are 1 so cpi is 1
cpi_dr(h,draw) = 1 ;
ry_dr(h,draw) = y_dr(h,draw) ;
display y_dr, ry_dr, cpi_dr;

* levels of expenditures on everything outside of the economy:
trout_dr(h,draw) = y_dr(h,draw)*troutsh_dr(h,draw) ;
sav_dr(h,draw) = y_dr(h,draw)*savsh_dr(h,draw) ;
exproc_dr(h,draw) = y_dr(h,draw)*exprocsh_dr(h,draw) ;
display troutsh_dr, savsh_dr, exprocsh_dr, trout_dr, sav_dr, exproc_dr ;

* ## DATA CHECKPOINT
* an abort statement if tansfers represent too much of income - means something is wrong with the data
set bigtr_dr(h,draw);
bigtr_dr(h,draw)$(troutsh_dr(h,draw) > 0.1) = yes ;
ABORT$(card(bigtr_dr)) "These household spend over 10% of income on transfers", bigtr_dr ;
set smallzoi_dr(h,draw);
smallzoi_dr(h,draw)$(expzoish_dr(h,draw) < 0.2) = yes ;
ABORT$(card(smallzoi_dr)) "These household spend less than 20% of income in zoi", smallzoi_dr ;

* LEVELS OF CONSUMPTION:
qc_dr(g,h,draw) = (y_dr(h,draw)-sav_dr(h,draw)-trout_dr(h,draw)-exproc_dr(h,draw))*alpha_dr(g,h,draw)/ph_dr(g,h,draw) ;

display qc_dr ;
parameter qcshare(h,g) share of household h in total consumption of g ;
qcshare(h,g)$qc_dr(g,h,"dr0") = qc_dr(g,h,"dr0") / sum(hh,qc_dr(g,hh,"dr0")) ;
display qcshare;

* PRODUCTION: we can compute the output to equal local demand + net exports
* total qp must equal qc + net exports + use as intermediate demands:
* NB: We initialise QP and ID at plausible values, but then we use an NLP solve
* to refine them.

parameter netexpsh(g) net export share of a good out of the zoi;
netexpsh(g)$gnag(g) = 1-(1/card(h)*(sum(h,xlrevsh_vil(g,h)+xlrevsh_zoi(g,h)))) ;
display netexpsh ;

* intermediate demand requirements
alias(g,ggg);
display xlID, xlFD;

parameter d                                ;
d(g,h)=sum(ggg,xlID(ggg,g,h))+sum(f,xlFD(g,f,h));
display d;

idsh_dr(gg,g,h,draw)$xlID(gg,g,h) = xlID(gg,g,h)/(sum(ggg,xlID(ggg,g,h))+sum(f,xlFD(g,f,h)));
tidsh_dr(g,h,draw) = sum(gg,idsh_dr(gg,g,h,draw));
display idsh_dr, tidsh_dr;


tqc_dr(g,draw) = sum(h,qc_dr(g,h,draw)) ;
display tqc_dr ;
parameter tempid_dr(g,draw) temporary total intermediate demand;
*  id = qc*s/(1-s)
tempid_dr(g,draw) = sum((gg,h),
                     qc_dr(gg,h,draw)*(idsh_dr(g,gg,h,draw)/(1-idsh_dr(g,gg,h,draw)))) ;
display tempid_dr ;

* now determine total QP
tqp_dr(g,draw) = [sum(h, qc_dr(g,h,draw)) + tempid_dr(g,draw) ]
                         /(1-netexpsh(g)) ;

display tqp_dr ;

* split qp in each household according to their capital shares:
parameter qpshare(h,g) share of household h in production of g ;
qpshare(h,g)$gnag(g) = xlFD(g,"K",h) / sum(hh,xlFD(g,"K",hh)) ;
*qpshare(h,g)$gag(g) = xlFD(g,"LAND",h) / sum(hh,xlFD(g,"LAND",hh)) ;   -- makes huge exinc
display qpshare ;
qp_dr(g,h,draw) = tqp_dr(g,draw) * qpshare(h,g) ;
display qp_dr ;

* several possibilities for crop/livestock closures.  Pick the one that makes a nice matrix:
* Self - reliant on food in the base
qp_dr(g,h,draw)$gag(g) = qc_dr(g,h,draw) ;
qpshare(h,g)$gag(g) = qp_dr(g,h,"dr0")/sum(hh,qp_dr(g,hh,"dr0")) ;

* And that determines all factor demands and intermediate demands:
id_dr(gg,g,h,draw) = qp_dr(g,h,draw) * idsh_dr(gg,g,h,draw) ;

* MINI-SOLVE STATEMENT TO FIGURE OUT THE PRODUCTION SIDE
* minisolve is just for the QP/ID balance:
variables
         NETEXPTEMP(g,draw)
         QPTEMP(g,h,draw)
         TQPTEMP(g,draw)
         IDTEMP(g,gg,h,draw)
         FAKE;

QPTEMP.l(g,h,draw) = qp_dr(g,h,draw) ;
TQPTEMP.l(g,draw) = sum(hh,qp_dr(g,hh,draw)) ;
IDTEMP.l(gg, g,h,draw) = id_dr(gg,g,h,draw) ;
NETEXPTEMP.l(g,draw) = netexpsh(g) * TQPTEMP.l(g,draw) ;
FAKE.l = 1 ;

equations
     NETEXPTEMP_eq(g,draw)
     TQPTEMP_eq(g,draw)
     QPTEMP_eq(g,h,draw)
     IDTEMP_eq(g,gg,h,draw)
     MKTCLR_mini(g,draw)
     FAKEQ ;

IDTEMP_eq(g,gg,h,draw)..
     IDTEMP(g,gg,h,draw) =e= idsh_dr(g,gg,h,draw)*QPTEMP(gg,h,draw) ;

QPTEMP_eq(g,h,draw)..
     QPTEMP(g,h,draw) =e= TQPTEMP(g,draw) * qpshare(h,g) ;

NETEXPTEMP_eq(g,draw)..
     NETEXPTEMP(g,draw) =e= TQPTEMP(g,draw) * netexpsh(g);

MKTCLR_mini(g,draw)..
     TQPTEMP(g,draw) =e= sum(h,qc_dr(g,h,draw)) + sum((h,gg), IDTEMP(g,gg,h,draw)) + NETEXPTEMP(g,draw) ;

FAKEQ..
     FAKE =e= 1 ;

model miniQPIDsolve /MKTCLR_mini, IDTEMP_eq, QPTEMP_eq, NETEXPTEMP_eq, FAKEQ/
solve miniQPIDsolve using nlp maximizing FAKE;
display IDTEMP.l, QPTEMP.l, TQPTEMP.l, NETEXPTEMP.l ;


* The model should have solved for a balanced system of production, consumption and intermediate demands:
qp_dr(g,h,draw) = QPTEMP.l(g,h,draw) ;
id_dr(gg,g,h,draw) = IDTEMP.l(gg,g,h,draw) ;
display qp_dr, id_dr, shcobb_dr ;

* We can figure out the rest from there:
* Factor demands derived from factor shares
fd_dr(g,f,h,draw)  = (qp_dr(g,h,draw) - sum(gg,id_dr(gg,g,h,draw))) * shcobb_dr(g,f,h,draw)  ;
display fd_dr ;
qva_dr(g,h,draw)   = sum(f, fd_dr(g,f,h,draw)) ;
acobb_dr(g,h,draw)$(qva_dr(g,h,draw))    = qva_dr(g,h,draw)/prod(f,fd_dr(g,f,h,draw)**shcobb_dr(g,f,h,draw)) ;

* and compute value added share for all activities
vash_dr(g,h,draw)$qp_dr(g,h,draw) = (qp_dr(g,h,draw)-sum(gg, id_dr(gg,g,h,draw))) / qp_dr(g,h,draw) ;
display id_dr, idsh_dr, tidsh_dr, vash_dr ;

parameter tid_dr(g,draw) check of total id
          tqcid_dr(g,draw)  check of qc+id ;
tid_dr(g,draw)= sum((gg,h),id_dr(g,gg,h,draw)) ;
tqcid_dr(g,draw) = tid_dr(g,draw) + tqc_dr(g,draw) ;
display tqc_dr, tid_dr, tqcid_dr, tqp_dr ;


* FACTOR ENDOWMENTS :
* --------------------------
* for fixed factors, endowment is just factor use:
endow_dr(fk,h,draw) = sum(g,fd_dr(g,fk,h,draw)) ;
fixfac_dr(g,fk,h,draw) = fd_dr(g,fk,h,draw) ;

* for family labor, split the labor use among households in the same village
* for hired labor, split endowment among all households
parameter shfl(h) share of village family labor coming from a household
          shhl(h) share of zoi hired labor coming from a household ;
shfl(h) = xlendow("FL",h)/sum((hh,v)$(maphv(hh,v)*maphv(h,v)),xlendow("FL",hh)) ;
shhl(h) = xlendow("HL",h)/sum(hh,xlendow("HL",hh)) ;
display shfl, shhl ;

endow_dr("FL",h,draw) = shfl(h) * sum((hh,g,v)$(maphv(hh,v)*maphv(h,v)), fd_dr(g,"FL",hh,draw)) ;
endow_dr("HL",h,draw) = shfl(h) * sum((hh,g), fd_dr(g,"HL",hh,draw)) + mig_dr("HL",h,draw);
display endow_dr ;


* MARKETS AGGREGATES
* ================================================================================================
* factor demand aggregates
hfd_dr(f,h,draw)= sum(g,fd_dr(g,f,h,draw)) ;
vfd_dr(f,v,draw)= sum(h$maphv(h,v), hfd_dr(f,h,draw)) ;
zfd_dr(f,draw)  = sum(v, vfd_dr(f,v,draw)) ;

* marketed surpluses for goods
hms_dr(g,h,draw) = qp_dr(g,h,draw) - qc_dr(g,h,draw) - sum(gg,id_dr(g,gg,h,draw)) ;
vms_dr(g,v,draw) = sum(h$maphv(h,v),hms_dr(g,h,draw));
zms_dr(g,draw) = sum(v, vms_dr(g,v,draw));

* marketed surpluses for factors
hfms_dr(ft,h,draw) = endow_dr(ft,h,draw) - sum(g, fd_dr(g,ft,h,draw)) - mig_dr(ft,h,draw);
vfms_dr(ft,v,draw) = sum(h$maphv(h,v), hfms_dr(ft,h,draw));
zfms_dr(ft,draw) = sum(v, vfms_dr(ft,v,draw))  ;

* fixed factor demands at village/zoi level
vfmsfix_dr(ftv,v,draw) = vfms_dr(ftv,v,draw) ;
zfmsfix_dr(ftz,draw) = zfms_dr(ftz,draw) ;

* fixed goods trade levels at village/zoi level
vmsfix_dr(gtv,v,draw) = vms_dr(gtv,v,draw) ;
zmsfix_dr(gtz,draw) = zms_dr(gtz,draw) ;

* minimum consumption: zero for now.
cmin_dr(g,h,draw) = 0 ;

pva_dr(g,h,draw) = ph_dr(g,h,draw)
                - sum(gg,idsh_dr(gg,g,h,draw)*ph_dr(gg,h,draw)) ;
trinsh_dr(h,draw) = y_dr(h,draw)*xltrinsh(h)/sum(hh,y_dr(hh,draw)*xltrinsh(hh))  ;
trin_dr(h,draw) = trinsh_dr(h,draw)*sum(hh,trout_dr(hh,draw)) ;

* last missing: exinc_dr THAT'S WHAT HAS TO CLEAR THE MATRIX
parameter exinc_dr1(h,draw) temp exogenous income computation
          exincsh(h,draw)  share of income being exogenous using exinc1
          feinc_dr(h,draw) income from factor endowments in the household
          fecomp_dr(f,h,draw) income components ;
* this is if we make exogenous income the residual from Y-FD
feinc_dr(h,draw) = sum((g,fk),r_dr(g,fk,h,draw)*fd_dr(g,fk,h,draw)) + sum(ft, wz_dr(ft,draw)*endow_dr(ft,h,draw)) ;
exinc_dr1(h,draw) = y_dr(h,draw) - feinc_dr(h,draw) ;
display feinc_dr,  exinc_dr1;
exinc_dr(h,draw) = exinc_dr1(h,draw) - sum(f,xlremus(f,h)) ;

display acobb_dr, shcobb_dr, pv_dr, pz_dr, ph_dr, pva_dr, qva_dr, fd_dr, id_dr, r_dr, wz_dr, qp_dr, fixfac_dr, pva_dr,
        exinc_dr, endow_dr, y_dr, trinsh_dr, qc_dr, alpha_dr, sav_dr, savsh_dr, troutsh_dr, hfd_dr, vfd_dr, zfd_dr,
        hms_dr, vms_dr, zms_dr, hfms_dr, vfms_dr, zfms_dr ;


* TOGETHER, THE "_DR" PARAMETERS CONTAIN INITIAL VALUES FOR ALL THE ECONOMIC VARIABLES IN LEWIE
* THEY FORM AN ECONOMY THAT IS AT EQUILIBRIUM. WE CAN THUS REPRESENT THEM IN SAM FORM.
* THE SAM IS NOW A BY-PRODUCT OF THE MODEL RATHER THAN AN INPUT TO IT

* OUTPUT A MATRIX
* ================================================================================================
parameter outmat(*,*,*,*,*,*) matrix to output to excel for checking purposes IN MILLIONS ;
* ACT(h,g), COMM(g), FACT(f), INST(h), REST

* ACTIVITY ROWS
outmat("ACT",h,g,"COMM","",g) = qp_dr(g,h,"dr0")   / 1000000;

* FACTOR ROW
* factor demand
outmat("FACT","",f,"ACT",h,g)   = fd_dr(g,f,h,"dr0") / 1000000 ;

* COMMODITY ROW
* intermediate demand
outmat("COMM","",g,"ACT",h,gg) = id_dr(g,gg,h,"dr0") / 1000000;
* household demand
outmat("COMM","",g,"INST","",h) = qc_dr(g,h,"dr0") / 1000000;

* INSTITUTION ROW
* income from factors
outmat("INST","",h,"FACT","",f)  = endow_dr(f,h,"dr0") / 1000000;
* income from outside
outmat("INST","",h,"ROW","","") = exinc_dr(h,"dr0")    / 1000000;

* ROW row and column
* factor imports or exports
parameter signzfms(f) sign of net factor trade
          signzms(g) sign of net commodity trade;
signzfms(f) = sign(zfms_dr(f,"dr0"));
signzms(g) = sign(zms_dr(g,"dr0"));
* net sellers or net buyers:
outmat("ROW","","","FACT","",f)$(signzfms(f) = -1)  = -zfms_dr(f,"dr0") / 1000000;
outmat("FACT","",f,"ROW","","")$(signzfms(f) =  1) =   zfms_dr(f,"dr0") / 1000000;
* commodity imports or exports
outmat("ROW","","","COMM","",g)$(signzms(g) = -1)  = -zms_dr(g,"dr0")   / 1000000;
outmat("COMM","",g,"ROW","","")$(signzms(g) = 1)  = zms_dr(g,"dr0")     / 1000000;
* exogenous expenditures
outmat("ROW","","","INST","",h)  = (sav_dr(h,"dr0")+trout_dr(h,"dr0")+exproc_dr(h,"dr0")) / 1000000 ;

option outmat:0:3:3 ;
display outmat ;

* This unloads the parameter into a .gdx data file:
execute_unload "outmat.gdx" outmat ;
* And this writes in an excel sheet called "MakeMeASam":
execute "gdxxrw.exe outmat.gdx par=outmat o=MakeMeASam.xlsx rng=a1:aa27 rdim=3 cdim=3"
* NB: the range is important here rng=a1:aa27 is the exact size of the Mexico matrix
* this is to prevent the gdxxrw procedure from overwriting everything on the entire xl spreadsheet



* ================================================================================================
* ================================================================================================
* ===================== STEP 4 - SOLVE THE MODEL IN A LOOP OVER PARAMETERS DRAWS =================
* ================================================================================================
* ================================================================================================

* The zero draw is using the mean values. Starting after dr1, those values are randomely drawn.
scalar loopcount ;
loopcount = 0;
loop(draw,
loopcount$(not sameas(draw,"dr0")) = loopcount+1 ;
display "this is round", loopcount    ;
* re-initialise all the variables in the matrix
* but this time not at the I levels - rather, at the _dr levels
cmin(g,h)      = cmin_dr(g,h,draw) ;
acobb(g,h)     = acobb_dr(g,h,draw) ;
shcobb(g,f,h)  = shcobb_dr(g,f,h,draw) ;
PZ.l(g)        = pz_dr(g,draw) ;
PV.l(g,v)      = pv_dr(g,v,draw) ;
PH.l(g,h)      = ph_dr(g,h,draw) ;
QVA.l(g,h)     = qva_dr(g,h,draw) ;
FD.l(g,f,h)    = fd_dr(g,f,h,draw) ;
ID.l(gg,g,h)   = id_dr(gg,g,h,draw) ;
R.l(g,fk,h)    = r_dr(g,fk,h,draw);
WV.l(f,v)      = wv_dr(f,v,draw) ;
WZ.l(f)        = wz_dr(f,draw);
QP.l(g,h)      = qp_dr(g,h,draw) ;
fixfac(g,fk,h) = fixfac_dr(g,fk,h,draw) ;
vfmsfix(ftv,v) = vfmsfix_dr(ftv,v,draw) ;
zfmsfix(ftz)   = zfmsfix_dr(ftz,draw) ;
PVA.l(g,h)     = pva_dr(g,h,draw) ;
vash(g,h)      = vash_dr(g,h,draw) ;
idsh(gg,g,h)   = idsh_dr(gg,g,h,draw) ;
tidsh(g,h)     = tidsh_dr(g,h,draw) ;
exinc(h)       = exinc_dr(h,draw) ;
endow(f,h)     = endow_dr(f,h,draw) ;
Y.l(h)         = y_dr(h,draw) ;
CPI.l(h)       = cpi_dr(h,draw) ;
RY.l(h)        = ry_dr(h,draw) ;
TRIN.l(h)      = trin_dr(h,draw) ;
trinsh(h)      = trinsh_dr(h,draw) ;
QC.l(g,h)      = qc_dr(g,h,draw) ;
alpha(g,h)     = alpha_dr(g,h,draw) ;
troutsh(h)     = troutsh_dr(h,draw) ;
TROUT.l(h)     = trout_dr(h,draw) ;
HFD.l(f,h)     = hfd_dr(f,h,draw);
VFD.l(f,v)     = vfd_dr(f,v,draw);
ZFD.l(f)       = zfd_dr(f,draw);
HMS.l(g,h)     = hms_dr(g,h,draw);
VMS.l(g,v)     = vms_dr(g,v,draw);
ZMS.l(g)       = zms_dr(g,draw);
vmsfix(gtv,v)  = vmsfix_dr(gtv,v,draw);
zmsfix(gtz)    = zmsfix_dr(gtz,draw);
HFMS.l(ft,h)   = hfms_dr(ft,h,draw);
VFMS.l(ft,v)   = vfms_dr(ft,v,draw);
ZFMS.l(ft)     = zfms_dr(ft,draw);
savsh(h)       = savsh_dr(h,draw) ;
exprocsh(h)    = exprocsh_dr(h,draw) ;
SAV.l(h)       = sav_dr(h,draw) ;
EXPROC.l(h)    = exproc_dr(h,draw) ;
hfsupzero(ft,h) = endow_dr(ft,h, draw) ;
pibudget(g,h)  = FD.l(g,"PURCH",h)*WZ.l("PURCH") ;
pibsh(g,h)  = pibudget(g,h)/sum(gg,pibudget(gg,h)) ;

* Migration
* FIX MIGRATION IF EXOG MIG MODEL
MIG.fx(f,h) =   mig_dr(f,h,draw) ;

REMIT.l(f,h) =   remit_dr(f,h,draw) ;
TREMIT.l(h) = sum(f, REMIT.l(f,h)) ;
remshift(f,h) = remshift_dr(f,h,draw) ;
remelast("HL",h)    = %remel% ;


* read the supply elasticities from the locals defined at the top of the program
hfsupel("HL",h) = %hlse% ;
hfsupel("FL",h) = %flse% ;
HFSUP.l(f,h)    = hfsupzero(f,h) ;

* closures: fixed wages and prices on world-market-integrated factors and goods (ftw & gtw)
WZ.fx(ftw) = WZ.l(ftw);
PZ.fx(gtw) = PZ.l(gtw) ;


display PV.l, PZ.l, PH.l, PVA.l, QVA.l, FD.l, QP.l, ID.l, QC.l, Y.l, CPI.l, RY.l, SAV.l,
      EXPROC.l, HMS.l, VMS.l, ZMS.l, R.l, WZ.l, HFMS.l, VFMS.l, ZFMS.l, MIG.l, REMIT.l ;



*---------------------------------
* RE-CALIBRATION
*---------------------------------
option iterlim = 1 ;
solve genCD using mcp ;
option iterlim=10000;
ABORT$(genCD.modelstat ne 1) "NOT WELL CALIBRATED IN THIS DRAW - CHECK THE DATA INPUTS" ;
display PV.l, PZ.l, PH.l, PVA.l, QVA.l, FD.l, QP.l, ID.l, QC.l, Y.l, Y.l, CPI.l, RY.l, SAV.l, EXPROC.l, HMS.l, VMS.l, ZMS.l, R.l, WZ.l, HFMS.l, VFMS.l, ZFMS.l;
display CPI.l ;

acobb1(g,h,draw)    = acobb(g,h) ;
shcobb1(g,f,h,draw) = shcobb(g,f,h) ;

pv1(g,v,draw)       = PV.l(g,v) ;
pz1(g,draw)         = PZ.l(g) ;
ph1(g,h,draw)       = PH.l(g,h) ;
qva1(g,h,draw)      = QVA.l(g,h) ;
fd1(g,f,h,draw)     = FD.l(g,f,h) ;
id1(gg,g,h,draw)    = ID.l(gg,g,h) ;
r1(g,fk,h,draw)     = R.l(g,fk,h) ;
wv1(f,v,draw)       = WV.l(f,v) ;
wz1(f,draw)         = WZ.l(f) ;
qp1(g,h,draw)       = QP.l(g,h) ;
fixfac1(g,fk,h,draw) = fixfac(g,fk,h) ;
display fixfac, fixfac1, FD.l ;
pva1(g,h,draw)      = PVA.l(g,h) ;
vash1(g,h,draw)     = vash(g,h) ;
idsh1(g,gg,h,draw)  = idsh(g,gg,h) ;
tidsh1(g,h,draw)    = tidsh(g,h) ;
exinc1(h,draw)      = exinc(h) ;
endow1(f,h,draw)    = endow(f,h) ;
y1(h,draw)          = Y.l(h) ;
qc1(g,h,draw)       = QC.l(g,h) ;
cpi1(h,draw)        = CPI.l(h) ;
vqc1(v,g,draw)      = sum(h$maphv(h,v), qc1(g,h,draw));
* village cpi is weighted sum of prices
vcpi1(v,draw)       = sum((h,g)$maphv(h,v), (ph1(g,h,draw)**2)*qc1(g,h,draw)) / sum((h,g)$maphv(h,v),ph1(g,h,draw)*qc1(g,h,draw)) ;
cri1(v,f,draw)      = sum((g,h)$maphv(h,v), r1(g,f,h,draw)*fd1(g,f,h,draw)/sum((gg,hh)$maphv(hh,v),fd1(gg,f,hh,draw)) ) ;

ry1(h,draw)         = RY.l(h) ;
ty1(draw)           = sum(h,y1(h,draw));
try1(draw)          = sum(h,ry1(h,draw));
trin1(h,draw)       = TRIN.l(h) ;
trout1(h,draw)      = TROUT.l(h) ;
trinsh1(h,draw)     = trinsh(h) ;
alpha1(g,h,draw)    = alpha(g,h) ;
cmin1(g,h,draw)     = cmin(g,h) ;
troutsh1(h,draw)    = troutsh(h) ;
hfd1(f,h,draw)      = HFD.l(f,h) ;
vfd1(f,v,draw)      = VFD.l(f,v) ;
zfd1(f,draw)        = ZFD.l(f) ;
hms1(g,h,draw)      = HMS.l(g,h) ;
vms1(g,v,draw)      = VMS.l(g,v) ;
zms1(g,draw)        = ZMS.l(g) ;
hfms1(ft,h,draw)    = HFMS.l(ft,h) ;
vfms1(ft,v,draw)    = VFMS.l(ft,v) ;
zfms1(ft,draw)      = ZFMS.l(ft) ;
hfsup1(ft,h,draw)   = HFSUP.l(ft,h) ;

vfmsfix1(ft,v,draw) = vfmsfix_dr(ft,v,draw) ;
zfmsfix1(ft,draw)   = zfmsfix_dr(ft,draw) ;
remit1(f,h,draw)    = REMIT.l(f,h) ;
tremit1(h,draw)     = TREMIT.l(h) ;
mig1(f,h,draw)      = MIG.l(f,h) ;
sav1(h,draw)        = SAV.l(h) ;

* more params
tqp1(g,draw)        = sum(h,qp1(g,h,draw)) ;

*------------------------------------
* SIMULATION FOR EACH CALIBRATED DRAW
*------------------------------------
* MIGRATION EXPERIMENT:
display remshift ;
* 45% decrease in remittances
remshift(f,h) = remshift(f,h)*0.55 ;
display remshift;


* help the program reach a solution by re-initializing pva
PVA.l(g,h) = PH.l(g,h) - sum(gg,idsh(gg,g,h)*PH.l(gg,h))
solve genCD using mcp ;
ABORT$(genCD.modelstat ne 1) "NO OPTIMAL SOLUTION REACHED" ;

display PV.l, PZ.l, PH.l, PVA.l, QVA.l, FD.l, QP.l, ID.l, QC.l, Y.l, HMS.l, VMS.l, ZMS.l, R.l, WZ.l, HFMS.l, VFMS.l, ZFMS.l, fd.l;
display CPI.l ;

acobb2(g,h,draw)    = acobb(g,h) ;
shcobb2(g,f,h,draw) = shcobb(g,f,h) ;

pv2(g,v,draw)       = PV.l(g,v) ;
pz2(g,draw)         = PZ.l(g) ;
ph2(g,h,draw)       = PH.l(g,h) ;
qva2(g,h,draw)      = QVA.l(g,h) ;
fd2(g,f,h,draw)     = FD.l(g,f,h) ;
id2(gg,g,h,draw)    = ID.l(gg,g,h) ;
r2(g,fk,h,draw)     = R.l(g,fk,h) ;
wv2(f,v,draw)       = WV.l(f,v) ;
wz2(f,draw)         = WZ.l(f) ;
qp2(g,h,draw)       = QP.l(g,h) ;
tqp2(g,draw)        = sum(h,qp2(g,h,draw)) ;
fixfac2(g,fk,h,draw) = fixfac(g,fk,h) ;
pva2(g,h,draw)      = PVA.l(g,h) ;
vash2(g,h,draw)     = vash(g,h) ;
exinc2(h,draw)      = exinc(h) ;
endow2(f,h,draw)    = endow(f,h) ;
y2(h,draw)          = Y.l(h) ;
qc2(g,h,draw)       = QC.l(g,h) ;
cpi2(h,draw)        = CPI.l(h) ;
vqc2(v,g,draw)      = sum(h$maphv(h,v), qc2(g,h,draw));
* village cpi is weighted sum of prices
vcpi2(v,draw)       = sum((h,g)$maphv(h,v), (ph2(g,h,draw)**2)*qc2(g,h,draw)) / sum((h,g)$maphv(h,v),ph2(g,h,draw)*qc2(g,h,draw)) ;
* weighted capital rent in the village
cri2(v,f,draw)      = sum((g,h)$maphv(h,v), r2(g,f,h,draw)*fd2(g,f,h,draw)/sum((gg,hh)$maphv(hh,v),fd2(gg,f,hh,draw)) ) ;

ry2(h,draw)         = RY.l(h) ;
ty2(draw)           = sum(h,y2(h,draw));
try2(draw)          = sum(h,ry2(h,draw));
trinsh2(h,draw)     = trinsh(h) ;
alpha2(g,h,draw)    = alpha(g,h) ;
troutsh2(h,draw)    = troutsh(h) ;
hfd2(f,h,draw)      = HFD.l(f,h) ;
vfd2(f,v,draw)      = VFD.l(f,v) ;
zfd2(f,draw)        = ZFD.l(f) ;
hms2(g,h,draw)      = HMS.l(g,h) ;
vms2(g,v,draw)      = VMS.l(g,v) ;
zms2(g,draw)        = ZMS.l(g) ;
hfms2(ft,h,draw)    = HFMS.l(ft,h) ;
vfms2(ft,v,draw)    = VFMS.l(ft,v) ;
zfms2(ft,draw)      = ZFMS.l(ft) ;
trin2(h,draw)       = TRIN.l(h) ;
trout2(h,draw)      = TROUT.l(h) ;
hfsup2(ft,h,draw)   = HFSUP.l(ft,h) ;

remit2(f,h,draw)    = REMIT.l(f,h) ;
tremit2(h,draw)     = TREMIT.l(h) ;
mig2(f,h,draw)      = MIG.l(f,h) ;
sav2(h,draw)        = SAV.l(h) ;

* ================================================================================================
* ===================== LOOP ENDS HERE    ========================================================
* ================================================================================================
);


* ================================================================================================
* ================================================================================================
* ===================== STEP 5 - OUTPUT ==========================================================
* ================================================================================================
* ================================================================================================

* now compute and display all the values, differences in values, standard errors, etc...
display pv1, pz1, ph1, qva1, fd1, id1, r1, wv1, wz1, qp1, tqp1, fixfac1, pva1, exinc1, endow1, y1, cpi1, vcpi1, ry1,
        trinsh1, qc1, alpha1, troutsh1, hfsup1, hfd1, vfd1, zfd1, hms1, vms1, zms1, hfms1, vfms1, zfms1, remit1, mig1, sav1 ;
display acobb1, shcobb1, vash1, idsh1 ;

display pv2, pz2, ph2, qva2, fd2, id2, r2, wv2, wz2, qp2, tqp2, fixfac2, pva2, exinc2, endow2, y2, cpi2, vcpi2, ry2,
        trinsh2, qc2, alpha2, troutsh2, hfsup2, hfd2, vfd2, zfd2, hms2, vms2, zms2, hfms2, vfms2, zfms2, remit2, mig2, sav2 ;

* DELTA between each calibration and the corresponding simulation
acobbD(g,h,draw)    = acobb2(g,h,draw) - acobb1(g,h,draw);
shcobbD(g,f,h,draw) = shcobb2(g,f,h,draw) - shcobb1(g,f,h,draw) ;
pvD(g,v,draw)       = pv2(g,v,draw) - pv1(g,v,draw) ;
pzD(g,draw)         = pz2(g,draw) - pz1(g,draw) ;
phD(g,h,draw)       = ph2(g,h,draw) - ph1(g,h,draw) ;
qvaD(g,h,draw)      = qva2(g,h,draw) - qva1(g,h,draw) ;
fdD(g,f,h,draw)     = fd2(g,f,h,draw) - fd1(g,f,h,draw) ;
idD(gg,g,h,draw)    = id2(gg,g,h,draw) - id1(gg,g,h,draw) ;
rD(g,fk,h,draw)     = r2(g,fk,h,draw) - r1(g,fk,h,draw) ;
wvD(f,v,draw)       = wv2(f,v,draw) - wv1(f,v,draw) ;
wzD(f,draw)         = wz2(f,draw) - wz1(f,draw) ;
qpD(g,h,draw)       = qp2(g,h,draw) - qp1(g,h,draw) ;
tqpD(g,draw)        = tqp2(g,draw) - tqp1(g,draw) ;
fixfacD(g,fk,h,draw)= fixfac2(g,fk,h,draw) - fixfac1(g,fk,h,draw) ;
pvaD(g,h,draw)      = pva2(g,h,draw) - pva1(g,h,draw) ;
exincD(h,draw)      = exinc2(h,draw) - exinc1(h,draw) ;
endowD(f,h,draw)    = endow2(f,h,draw) - endow1(f,h,draw) ;
yD(h,draw)          = y2(h,draw) - y1(h,draw) ;
cpiD(h,draw)        = cpi2(h,draw) - cpi1(h,draw) ;
vqcD(v,g,draw)      = vqc2(v,g,draw)-vqc1(v,g,draw) ;
* village cpi is weighted sum of prices
vcpiD(v,draw)       = vcpi2(v,draw) - vcpi1(v,draw);
criD(v,f,draw)      = cri2(v,f,draw) - cri1(v,f,draw);
ryD(h,draw)         = ry2(h,draw) - ry1(h,draw) ;
tyD(draw)           = ty2(draw) - ty1(draw) ;
tryD(draw)          = try2(draw) - try1(draw) ;
trinshD(h,draw)     = trinsh2(h,draw) - trinsh1(h,draw) ;
qcD(g,h,draw)       = qc2(g,h,draw) - qc1(g,h,draw) ;
alphaD(g,h,draw)    = alpha2(g,h,draw) - alpha1(g,h,draw) ;
troutshD(h,draw)    = troutsh2(h,draw) - troutsh1(h,draw) ;
hfdD(f,h,draw)      = hfd2(f,h,draw) - hfd1(f,h,draw) ;
vfdD(f,v,draw)      = vfd2(f,v,draw) - vfd1(f,v,draw) ;
zfdD(f,draw)        = zfd2(f,draw) - zfd1(f,draw) ;
hmsD(g,h,draw)      = hms2(g,h,draw) - hms1(g,h,draw) ;
vmsD(g,v,draw)      = vms2(g,v,draw) - vms1(g,v,draw) ;
zmsD(g,draw)        = zms2(g,draw) - zms1(g,draw) ;
hfmsD(ft,h,draw)    = hfms2(ft,h,draw) - hfms1(ft,h,draw) ;
vfmsD(ft,v,draw)    = vfms2(ft,v,draw) - vfms1(ft,v,draw) ;
zfmsD(ft,draw)      = zfms2(ft,draw) - zfms1(ft,draw) ;
vashD(g,h,draw)     = vash2(g,h,draw) -vash1(g,h,draw) ;
trinD(h,draw)       = trin2(h,draw) - trin1(h,draw) ;
troutD(h,draw)      = trout2(h,draw) - trout1(h,draw) ;
hfsupD(f,h,draw)    = hfsup2(f,h,draw) - hfsup1(f,h,draw) ;

remitD(f,h,draw)    = remit2(f,h,draw) - remit1(f,h,draw) ;
tremitD(h,draw)     = tremit2(h,draw) - tremit1(h,draw) ;
migD(f,h,draw)      = mig2(f,h,draw) - mig1(f,h,draw) ;
savD(h,draw)        = sav2(h,draw) - sav1(h,draw) ;

* PERCENT CHANGE between each calibration and the corresponding simulation
acobbPC(g,h,draw)$acobb1(g,h,draw)    = 100*acobbD(g,h,draw)/ acobb1(g,h,draw);
shcobbPC(g,f,h,draw)$shcobb1(g,f,h,draw) = 100*shcobbD(g,f,h,draw) / shcobb1(g,f,h,draw) ;
pvPC(g,v,draw)$pv1(g,v,draw)        = 100*pvD(g,v,draw) / pv1(g,v,draw) ;
pzPC(g,draw)$pz1(g,draw)            = 100*pzD(g,draw) / pz1(g,draw) ;
phPC(g,h,draw)$ph1(g,h,draw)        = 100*phD(g,h,draw) / ph1(g,h,draw) ;
qvaPC(g,h,draw)$qva1(g,h,draw)      = 100*qvaD(g,h,draw) / qva1(g,h,draw) ;
fdPC(g,f,h,draw)$fd1(g,f,h,draw)    = 100*fdD(g,f,h,draw) / fd1(g,f,h,draw) ;
idPC(gg,g,h,draw)$id1(gg,g,h,draw)  = 100*idD(gg,g,h,draw) / id1(gg,g,h,draw) ;
rPC(g,fk,h,draw)$r1(g,fk,h,draw)    = 100*rD(g,fk,h,draw) / r1(g,fk,h,draw) ;
wvPC(f,v,draw)$wv1(f,v,draw)        = 100*wvD(f,v,draw) / wv1(f,v,draw) ;
wzPC(f,draw)$wz1(f,draw)            = 100*wzD(f,draw) / wz1(f,draw) ;
qpPC(g,h,draw)$qp1(g,h,draw)        = 100*qpD(g,h,draw) / qp1(g,h,draw) ;
tqpPC(g,draw)$tqp1(g,draw)          = 100*tqpD(g,draw) / tqp1(g,draw) ;

fixfacPC(g,fk,h,draw)$fixfac1(g,fk,h,draw)  = 100*fixfacD(g,fk,h,draw) / fixfac1(g,fk,h,draw) ;
pvaPC(g,h,draw)$pva1(g,h,draw)      = 100*pvaD(g,h,draw) / pva1(g,h,draw) ;
exincPC(h,draw)$exinc1(h,draw)      = 100*exincD(h,draw) / exinc1(h,draw) ;
endowPC(f,h,draw)$endow1(f,h,draw)  = 100*endowD(f,h,draw) / endow1(f,h,draw) ;
yPC(h,draw)$y1(h,draw)              = 100*yD(h,draw) / y1(h,draw) ;
cpiPC(h,draw)$cpi1(h,draw)          = 100*cpiD(h,draw) / cpi1(h,draw) ;
vcpiPC(v,draw)$vcpi1(v,draw)        = 100*vcpiD(v,draw) / vcpi1(v,draw) ;
criPC(v,f,draw)$cri1(v,f,draw)      = 100*criD(v,f,draw) / cri1(v,f,draw) ;

ryPC(h,draw)$ry1(h,draw)            = 100*ryD(h,draw) / ry1(h,draw) ;
tyPC(draw)$ty1(draw)                = 100*tyD(draw) / ty1(draw) ;
tryPC(draw)$try1(draw)              = 100*tryD(draw) / try1(draw) ;
trinshPC(h,draw)$trinsh1(h,draw)    = 100*trinshD(h,draw) / trinsh1(h,draw) ;
qcPC(g,h,draw)$qc1(g,h,draw)        = 100*qcD(g,h,draw) / qc1(g,h,draw) ;
alphaPC(g,h,draw)$alpha1(g,h,draw)  = 100*alphaD(g,h,draw) / alpha1(g,h,draw) ;
troutshPC(h,draw)$troutsh1(h,draw)  = 100*troutshD(h,draw) / troutsh1(h,draw) ;
hfdPC(f,h,draw)$hfd1(f,h,draw)      = 100*hfdD(f,h,draw) / hfd1(f,h,draw) ;
vfdPC(f,v,draw)$vfd1(f,v,draw)      = 100*vfdD(f,v,draw) / vfd1(f,v,draw) ;
zfdPC(f,draw)$zfd1(f,draw)          = 100*zfdD(f,draw) / zfd1(f,draw) ;
hmsPC(g,h,draw)$hms1(g,h,draw)      = 100*hmsD(g,h,draw) / hms1(g,h,draw) ;
vmsPC(g,v,draw)$vms1(g,v,draw)      = 100*vmsD(g,v,draw) / vms1(g,v,draw) ;
zmsPC(g,draw)$zms1(g,draw)          = 100*zmsD(g,draw) / zms1(g,draw) ;
hfmsPC(ft,h,draw)$hfms1(ft,h,draw)  = 100*hfmsD(ft,h,draw) / hfms1(ft,h,draw) ;
vfmsPC(ft,v,draw)$vfms1(ft,v,draw)  = 100*vfmsD(ft,v,draw) / vfms1(ft,v,draw) ;
zfmsPC(ft,draw)$zfms1(ft,draw)      = 100*zfmsD(ft,draw) / zfms1(ft,draw) ;
vashPC(g,h,draw)$vash1(g,h,draw)    = 100*vashD(g,h,draw) / vash1(g,h,draw) ;
trinPC(h,draw)$trin1(h,draw)        = 100*trinD(h,draw) / trin1(h,draw) ;
troutPC(h,draw)$trout1(h,draw)      = 100*troutD(h,draw) / trout1(h,draw) ;
hfsupPC(f,h,draw)$hfsup1(f,h,draw)  = 100*hfsupD(f,h,draw) / hfsup1(f,h,draw) ;

remitPC(f,h,draw)$remit1(f,h,draw)      = 100*remitD(f,h,draw)/remit1(f,h,draw) ;
migPC(f,h,draw)$mig1(f,h,draw)      = 100*migD(f,h,draw)/mig1(f,h,draw) ;
savPC(h,draw)$sav1(h,draw)          = 100*savD(h,draw)/sav1(h,draw) ;


display pvD, pzD, phD, qvaD, fdD, idD, rD, wvD, wzD, qpD, tqpD, fixfacD, pvaD, exincD, endowD, yD, cpiD, vcpiD, ryD, tyD, tryD,
        trinshD, qcD, alphaD, troutshD, hfsupD, hfdD, vfdD, zfdD, hmsD, vmsD, zmsD, hfmsD, vfmsD, zfmsD ,
        vashD, trinD, troutD, remitD, migD, savD;

display pvPC, pzPC, phPC, qvaPC, fdPC, idPC, rPC, wvPC, wzPC, qpPC, tqpPC, fixfacPC, pvaPC, exincPC, endowPC, yPC, cpiPC, vcpiPC, ryPC, tyPC, tryPC,
        trinshPC, qcPC, alphaPC, troutshPC, hfsupPC, hfdPC, vfdPC, zfdPC, hmsPC, vmsPC, zmsPC, hfmsPC, vfmsPC, zfmsPC ,
        vashPC, trinPC, troutPC, remitPC, migPC, savPC ;


* ######################################################################################################
* #### NOTE: the computation of means and variances was cut out to slim down the code ##################
* ####   See other chapters in Beyond Experiments book. ################################################
* ######################################################################################################




* ###########################################################################
* ###########################################################################
* ###########################################################################
* #### LONG-RUN EXPERIMENT MODEL SOLVE STATEMENTS ###########################
* ###########################################################################
* ###########################################################################
* ###########################################################################



PARAMETER TKAP(h)            TOTAL CAPITAL by household
          KSHARE(g,fk,h)       ACTIVITY CAPITAL SHARE
          DELKAP(g,fk,h)       CHANGE IN ACTIVITY FIXED CAPITAL ;

* Use the BASE to start the recursive process
* We assume
TKAP(h)= sum(g,sum(fk,fd1(g,fk,h,"dr0")));
KSHARE(g,fk,h)= fd1(g,fk,h,"dr0")/TKAP(h) ;
DISPLAY TKAP, KSHARE ;

* #################### CAPITAL UPDATE PARAMETERS #######################################
* To update capital in every period we need an investment variable
* according to share of capital (either in first draw, or at mean of all draws)
DELKAP(g,fk,h) = KSHARE(g,fk,h)* (savD(h,"dr0")) ;
display DELKAP;

* loop capital update nN times (2 is minimum, because 0 and 1 are the two baselines):
set krounds capital rounds including the first two /n0*n10/
    kr(krounds) subset of capital rounds to loop /n2*n10/ ;

* Variable values in the long run
parameter yLR(h, krounds)          income in the long run
          ryLR(h, krounds)         real income in the long run
          qpLR(g,h,krounds)        production in the long run
          qvaLR(g,h,krounds)       quantity of value added in the long run
          qcLR(g,h,krounds)        consumption in the long run
          fdLR(g,f,h,krounds)      factor demands long run
          idLR(g,gg,h,krounds)     intermediate demands long run
          rLR(g,f,h,krounds)       rent long run
          wzLR(f,krounds)          wages long run
          migLR(f,h,krounds)       migration in the long run
          remitLR(f,h,krounds)     remittances in the long run
          savLR(h,krounds)         savings in the long run

          phLR(g,h,krounds)        price for the household in the long run
          pvLR(g,v,krounds)        price at the village level in the long run
          pzLR(g,krounds)          price in the zoi in the long run
          pvaLR(g,h,krounds)       price value added in the long run
          fixfacLR(g,f,h,krounds)  fixed factor input in the long run
          cpiLR(h,krounds)         cpi in the long run
          hfsupLR(f,h,krounds)     household factor supply in the long run


          hmsLR(g,h,krounds)       household marketed surplus in long run
          vmsLR(g,v,krounds)       village marketed surplus in long run
          zmsLR(g,krounds)         zoi marketed surplus in long run (here = village)
          hfmsLR(f,h,krounds)      household factor marketed surplus in long run
          vfmsLR(f,v,krounds)      village factor marketed surplus in the long run
          zfmsLR(f,krounds)        zoi factor marketed surplus in the long run

          yPCLR(h,krounds)         income % change from base year
          ryPCLR(h, krounds)       real income % change from base year
          qpPCLR(g,h,krounds)      production % change from base year
          qvaPCLR(g,h,krounds)      production % change from base year
          fdPCLR(g,f,h,krounds)    factor demands % change from base year
          idPCLR(g,gg,h,krounds)   intermediate demands % change long run
          qcPCLR(g,h,krounds)      consumption in the long run
          rPCLR(g,f,h,krounds)     rent long run
          wzPCLR(f,krounds)        wages long run
          migPCLR(f,h,krounds)     migration %change in the long run
          remitPCLR(f,h,krounds)   remittances %change in the long run
          savPCLR(h,krounds)       savings %change in the long run

          pzPCLR(g,krounds)        price in the zoi %change in the long run
          pvaPCLR(g,h,krounds)     price value added %change in the long run
          fixfacPCLR(g,f,h,krounds) fixed factor input %change in the long run
          cpiPCLR(h,krounds)       cpi %change in the long run
          hfsupPCLR(f,h,krounds)   household factor supply %change in the long run

          hmsPCLR(g,h,krounds)     household marketed surplus %change in long run
          vmsPCLR(g,v,krounds)     village marketed surplus %change in long run
          zmsPCLR(g,krounds)       zoi marketed surplus %change in long run
          hfmsPCLR(f,h,krounds)    household factor marketed surplus %change in long run
          vfmsPCLR(f,v,krounds)    village factor marketed surplus %change in long run
          zfmsPCLR(f,krounds)      zoi factor marketed surplus %change in long run

          mdstat(krounds)          did the model solve in this round?
;


*First two rounds already known
yLR(h,"n0") = y1(h,"dr0") ;
yLR(h,"n1") = y2(h,"dr0") ;

ryLR(h,"n0") = ry1(h,"dr0") ;
ryLR(h,"n1") = ry2(h,"dr0") ;

qpLR(g,h,"n0") = qp1(g,h,"dr0") ;
qpLR(g,h,"n1") = qp2(g,h,"dr0") ;

qvaLR(g,h,"n0") = qva1(g,h,"dr0") ;
qvaLR(g,h,"n1") = qva2(g,h,"dr0") ;

phLR(g,h,"n0") = ph1(g,h,"dr0") ;
phLR(g,h,"n1") = ph2(g,h,"dr0") ;

pvLR(g,v,"n0") = pv1(g,v,"dr0") ;
pvLR(g,v,"n1") = pv2(g,v,"dr0") ;

pvaLR(g,h,"n0") = pva1(g,h,"dr0") ;
pvaLR(g,h,"n1") = pva2(g,h,"dr0") ;

pzLR(g,"n0") = pz1(g,"dr0") ;
pzLR(g,"n1") = pz2(g,"dr0") ;

qcLR(g,h,"n0") = qc1(g,h,"dr0") ;
qcLR(g,h,"n1") = qc2(g,h,"dr0") ;

fdLR(g,f,h,"n0") = fd1(g,f,h,"dr0") ;
fdLR(g,f,h,"n1") = fd2(g,f,h,"dr0") ;

idLR(g,gg,h,"n0") = id1(g,gg,h,"dr0") ;
idLR(g,gg,h,"n1") = id2(g,gg,h,"dr0") ;

rLR(g,f,h,"n0") = r1(g,f,h,"dr0") ;
rLR(g,f,h,"n1") = r2(g,f,h,"dr0") ;

wzLR(f,"n0") = wz1(f,"dr0") ;
wzLR(f,"n1") = wz2(f,"dr0") ;

migLR(f,h,"n0") = mig1(f,h,"dr0") ;
migLR(f,h,"n1") = mig2(f,h,"dr0") ;

remitLR(f,h,"n0") = remit1(f,h,"dr0") ;
remitLR(f,h,"n1") = remit2(f,h,"dr0") ;

savLR(h,"n0") = sav1(h,"dr0") ;
savLR(h,"n1") = sav2(h,"dr0") ;

fixfacLR(g,f,h,"n0") = fixfac1(g,f,h,"dr0") ;
fixfacLR(g,f,h,"n1") = fixfac2(g,f,h,"dr0") ;

cpiLR(h,"n0") = cpi1(h,"dr0") ;
cpiLR(h,"n1") = cpi2(h,"dr0") ;

hfsupLR(f,h,"n0") = hfsup1(f,h,"dr0") ;
hfsupLR(f,h,"n0") = hfsup2(f,h,"dr0") ;

hmsLR(g,h,"n0") = hms1(g,h,"dr0") ;
hmsLR(g,h,"n1") = hms2(g,h,"dr0") ;

vmsLR(g,v,"n0") = vms1(g,v,"dr0") ;
vmsLR(g,v,"n1") = vms2(g,v,"dr0") ;

zmsLR(g,"n0") = zms1(g,"dr0") ;
zmsLR(g,"n1") = zms2(g,"dr0") ;

hfmsLR(f,h,"n0") = hfms1(f,h,"dr0") ;
hfmsLR(f,h,"n1") = hfms2(f,h,"dr0") ;

vfmsLR(f,v,"n0") = vfms1(f,v,"dr0") ;
vfmsLR(f,v,"n1") = vfms2(f,v,"dr0") ;

zfmsLR(f,"n0") = zfms1(f,"dr0") ;
zfmsLR(f,"n1") = zfms2(f,"dr0") ;

yPCLR(h,"n0") = 1 ;
ryPCLR(h,"n0") = 1;
qpPCLR(g,h,"n0") = 1;
qvaPCLR(g,h,"n0") = 1;
qcPCLR(g,h,"n0") = 1;
fdPCLR(g,f,h,"n0") = 1;
idPCLR(g,gg,h,"n0") = 1;
rPCLR(g,f,h,"n0") = 1;
wzPCLR(f,"n0") = 1;
remitPCLR(f,h,"n0") = 1 ;
migPCLR(f,h,"n0") = 1 ;
savPCLR(h,"n0") = 1 ;
hmsPCLR(g,h,"n0") =1;
vmsPCLR(g,v,"n0") =1;
zmsPCLR(g,"n0")   =1;
hfmsPCLR(f,h,"n0") =1;
vfmsPCLR(f,v,"n0") =1;
zfmsPCLR(f,"n0")   =1;
pzPCLR(g,"n0")    =1;
pvaPCLR(g,h,"n0")  =1;
fixfacPCLR(g,f,h,"n0") =1;
cpiPCLR(h,"n0")   =1;
hfsupPCLR(f,h,"n0")  =1;


* be careful: fixfac is stuck at post-last-round value, put it back to first round
fixfac(g,fk,h)=fixfac1(g,fk,h,"dr0") ;

* starting from third round we loop
scalar krcounter ;
krcounter=0
loop(kr,
     display krcounter ;
     display fixfac, FD.l, DELKAP;
*1) update capital using the share of capital (delkap)
     fixfac(g,fk,h) = fixfac(g,fk,h)+DELKAP(g,fk,h) ;
     display fixfac;
     fixfacLR(g,fk,h,kr) =  fixfac(g,fk,h) ;
* Help the program solve:
     FD.l(g,fk,h) = fixfac(g,fk,h) ;
     QVA.l(g,h) = acobb(g,h)*prod(f,FD.l(g,f,h)**(shcobb(g,f,h)));
     QP.l(g,h)$vash(g,h) = QVA.l(g,h)/vash(g,h) ;
     ID.l(gg,g,h) = QP.l(g,h)*idsh(gg,g,h);

     solve genCD using mcp ;
     ABORT$(genCD.modelstat ne 1) "BAD SOLVE IN THE LONG-RUN LOOPS" ;
* and record the values
     yLR(h,kr) = Y.l(h) ;
     ryLR(h,kr) = RY.l(h) ;
     qpLR(g,h,kr) = QP.l(g,h) ;
     phLR(g,h,kr) = PH.l(g,h) ;
     qcLR(g,h,kr) = QC.l(g,h);
     fdLR(g,f,h,kr) = FD.l(g,f,h);
     idLR(g,gg,h,kr) = ID.l(g,gg,h);
     rLR(g,f,h,kr) = R.l(g,f,h);
     wzLR(f,kr) = WZ.l(f);
     remitLR(f,h,kr) = REMIT.l(f,h);
     migLR(f,h,kr)  = MIG.l(f,h) ;
     savLR(h,kr)    = SAV.l(h) ;

     pvLR(g,v,kr) = PV.l(g,v) ;
     pzLR(g,kr) = PZ.l(g)       ;

     pvaLR(g,h,kr) =  PVA.l(g,h) ;

     cpiLR(h,kr)         = CPI.l(h) ;
     hfsupLR(f,h,kr)     = HFSUP.l(f,h) ;


     hmsLR(g,h,kr) =HMS.l(g,h);
     vmsLR(g,v,kr) =VMS.l(g,v);
     zmsLR(g,kr)   =ZMS.l(g);
     hfmsLR(f,h,kr) =HFMS.l(f,h);
     vfmsLR(f,v,kr) =VFMS.l(f,v);
     zfmsLR(f,kr)   =ZFMS.l(f);
     mdstat(kr)     =genCD.modelstat ;
     krcounter = krcounter+1 ;
*====== FILL IN WITH PARAMETERS TO PLOT =======
);

display fixfacLR ;

yPCLR(h,krounds)$yLR(h,"n0")            = (yLR(h,krounds))/yLR(h,"n0") ;
ryPCLR(h,krounds)$ryLR(h,"n0")          = (ryLR(h,krounds))/ryLR(h,"n0") ;
qpPCLR(g,h,krounds)$qpLR(g,h,"n0")      = (qpLR(g,h,krounds))/qpLR(g,h,"n0") ;
qcPCLR(g,h,krounds)$qcLR(g,h,"n0")      = (qcLR(g,h,krounds))/qcLR(g,h,"n0") ;
fdPCLR(g,f,h,krounds)$fdLR(g,f,h,"n0")  = (fdLR(g,f,h,krounds))/fdLR(g,f,h,"n0") ;
idPCLR(g,gg,h,krounds)$idLR(g,gg,h,"n0") = (idLR(g,gg,h,krounds))/idLR(g,gg,h,"n0") ;
rPCLR(g,f,h,krounds)$rLR(g,f,h,"n0")    = (rLR(g,f,h,krounds))/rLR(g,f,h,"n0") ;
wzPCLR(f,krounds)$wzLR(f,"n0")          = (wzLR(f,krounds))/wzLR(f,"n0") ;
remitPCLR(f,h,krounds)$remitLR(f,h,"n0") = (remitLR(f,h,krounds))/remitLR(f,h,"n0") ;
migPCLR(f,h,krounds)$migLR(f,h,"n0")    = (migLR(f,h,krounds))/migLR(f,h,"n0") ;
savPCLR(h,krounds)$savLR(h,"n0")        = (savLR(h,krounds))/savLR(h,"n0") ;

hmsPCLR(g,h,krounds)$hmsLR(g,h,"n0")    = (hmsLR(g,h,krounds))/hmsLR(g,h,"n0") ;
vmsPCLR(g,v,krounds)$vmsLR(g,v,"n0")    = (vmsLR(g,v,krounds))/vmsLR(g,v,"n0") ;
zmsPCLR(g,krounds)$zmsLR(g,"n0")        = (zmsLR(g,krounds))/zmsLR(g,"n0") ;
hfmsPCLR(f,h,krounds)$hfmsLR(f,h,"n0")  = (hfmsLR(f,h,krounds))/hfmsLR(f,h,"n0") ;
vfmsPCLR(f,v,krounds)$vfmsLR(f,v,"n0")  = (vfmsLR(f,v,krounds))/vfmsLR(f,v,"n0") ;
zfmsPCLR(f,krounds)$zfmsLR(f,"n0")      = (zfmsLR(f,krounds))/zfmsLR(f,"n0") ;

pzPCLR(g,krounds)$pzLR(g,"n0")          = (pzLR(g,krounds))/pzLR(g,"n0") ;
pvaPCLR(g,h,krounds)$pvaLR(g,h,"n0")    = (pvaLR(g,h,krounds))/pvaLR(g,h,"n0") ;
fixfacPCLR(g,f,h,krounds)$fixfacLR(g,f,h,"n0") = (fixfacLR(g,f,h,krounds))/fixfacLR(g,f,h,"n0") ;
cpiPCLR(h,krounds)$cpiLR(h,"n0")        = (cpiLR(h,krounds))/cpiLR(h,"n0") ;
hfsupPCLR(f,h,krounds)$hfsupLR(f,h,"n0") = (hfsupLR(f,h,krounds))/hfsupLR(f,h,"n0") ;

display yLR, remitLR, migLR, mdstat, pzPCLR, pvaPCLR ;


* ##############################################################################
* ############# Output ##########################################################
* ##############################################################################


* Parameters we want in figures  13.1 to 13.4:
*-----------------------------------------------
parameter LRresults(*,*,*,*,krounds) results from long runs ;
LRresults("fixfacPCLR","","",h,krounds) = sum((g,f),fixfacPCLR(g,f,h,krounds))/sum((g,f)$fixfacPCLR(g,f,h,krounds),1);
LRresults("qpLR","ret","",h,krounds)    = qpLR("ret",h,krounds)  ;
* prices are same for both hh in village
LRresults("phLR",g,"","",krounds)       = phLR(g,"N",krounds)  ;
LRresults("yPCLR","","",h,krounds)      = yPCLR(h,krounds)  ;
LRresults("ryPCLR","","",h,krounds)     = ryPCLR(h,krounds) ;
display LRresults ;


execute 'xlstalk -s %outLRexcel%'
execute_unload "yLR.gdx" LRresults
execute 'gdxxrw.exe yLR.gdx O=%outLRexcel% par=LRresults rng=rawout!a1'
execute 'xlstalk -o %outLRexcel%'


* Making Table 13.2:
*---------------------------------------
* Report the base levels, shock-levels, and 10-year levels in one table.
set krtab(krounds) /n0, n1, n10/ ;
parameter tabout(*,*,krounds) table out ;
tabout("Remittances",h,krtab) = sum(f,remitLR(f,h,krtab))  ;
tabout("Total income","", krtab) = sum(h, yLR(h,krtab)) ;
tabout("Y by household",h, krtab) = yLR(h,krtab) ;
tabout("Total real income","", krtab) = sum(h, ryLR(h,krtab)) ;
tabout("RY by household",h, krtab) = ryLR(h,krtab) ;
tabout("Production",g, krtab) = sum(h,qpLR(g,h,krtab)) ;
tabout("Savings",h,krtab) = savLR(h,krtab) ;
display tabout ;

execute 'xlstalk -s %outLRexcel_table%'
execute_unload "tabout.gdx" tabout
execute 'gdxxrw.exe tabout.gdx O=%outLRexcel_table% par=tabout rng=tabout!a1'
execute 'xlstalk -o %outLRexcel_table%'





