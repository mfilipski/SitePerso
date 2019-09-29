$TITLE MEXICO LEWIE MODEL - CORRUPTION
* Mateusz Filipski, July 2013

* The model reads in data from excel spreadsheet in the form of parameter distributions
* Then it draws from those distributions and constructs a SAM from the values drawn
* The it uses those same values to calibrate a village economywide model

* A few useful gams options
option limrow=30 ;
option limcol=30 ;
*$onsymlist
*$onsymxref

* ##############################################################################################
* REPRODUCING THE TABLE 14.3 in the book:
* ##############################################################################################
* Need to run the program twice, once for each column. Results are written to Ch14_table14.3.txt
* Easy to read or to cut and paste into excel (text-to-columns, using ";" delimiter)
* ##############################################################################################
* 1) Choose the elasticity of labor supply with the lse local.
* Inelastic inputs simulation = 1, Elastic Inputs = 100
$setlocal lse 1
* 2) Choose whether or not to have a budget constraint on agricultural input purchases using the $setglobal
* Inelastic inputs simulation = 1, Elastic Inputs = 0
$setglobal budgetconstraint 1
* 3) Choose the number of draws (change the second number, must be 10 minimum).
set draw /dr0*dr10/ ;
* We use 500 in the book tables, but that solves slowly and doesn't dramatically change the results
* ##############################################################################################




* #################################################################################################
* Understanding the GAMS output:
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
* the $call reads XL data and makes a .gdx file with it, which can then be read directly
* (unstar the "call" statement to read from the excel spreadsheet)
$call "gdxxrw input=Ch14_Mex_Corruption_LEWIE_data.xlsx output=MexCorruptData.gdx index=Index!A2"
* The "Index" tab of the XL spreadsheet tells the gdxxrw procedure where things are.

* the $gdxin opens the data loading procedure and calls the .gdx file we just made
$gdxin MexCorruptData.gdx
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
     ftv(f)    factors tradable in the village /FL,  null /
     ftz(f)    factors tradable in the whole zoi  / null /
     ftw(f)    factors tradables in the rest of the world / HL,  PURCH /
     fpurch(f) purchased factors /PURCH/
     fe(f)     factors potentially unemployed /FL/

* goods subsets
     gtv(g)    goods tradable in the village / ret, ser, crop, live,  null  /
     gtz(g)    goods tradable in the zoi   /null /
     gtw(g)    goods tradable with the rest of the world /prod, outside /
     gp(g)     goods that are produces / crop, ret, ser, live, prod /
     gag(g)    ag goods /crop, live/
     gnag(g)   non ag goods /ret, ser, prod /

* household subsets
     ht(h)     recipients in this simulation (can be a or b or both) / p, null/

* accounts not in the matrix
sets
     v        villages / T treated
/

     maphv mapping housheold to their village / (p,np).T
/
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
     xlalphase(g,h)          consumption share of income
     xlcmin(g,h)           incompressible consumption
     xlendow(f,h)          endowment of factors in the economy
     xlROCendow(f,h)       endowment of factors outside the economy
     xlROWendow(f,h)       endowment of factors outside the country
     xlTRINsh(h)           cash transfers given to other households (share of income)
     xlTROUTsh(h)          cash transfers received from other households  (share of expenditures)
     xlTRINshse(h)         standard error of cash transfers given to other households (share of income)
     xlTROUTshse(h)        standard error of cash transfers received from other households  (share of expenditures)
     xlSAVsh(h)            share of income going to informal savings
     xlSAVshse(h)            standard error of share of income going to informal savings
     xllabexp(h)           not sure what this is and why there's a negative value
     xlexpoutsh(h)         share of expenditures on outside goods
     xlremit(h)            level of remittances
     xlothertransfers(h)   level of exogenous transfers
     xlprocampo(h)        level of procampo transfers
     xlnhh(h)              number of households represented by this
     xlhhinc(h)            mean household income
     xlhhexp(h)            mean household expenditures
     xlhhsize(h)           mean household size
     xlrevsh_vil(g,h)        share of business in the village
     xlrevsh_zoi(g,h)        share of business in the zoi
     xlrevsh_roc(g,h)        share of business in the rest of lesotho
     xlrevsh_row(g,h)        share of business in the row
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
xlSAVshse(h) = alldata("savse","","","",h) ;

xlexpoutsh(h) = alldata("exproles","","","",h) ;

xlremit(h)  =  alldata("remits","","","",h) ;
xlothertransfers(h)  =  alldata("NONPROtransfers","","","",h) ;
xlprocampo(h)  = alldata("PROCAMPO","","","",h);

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
     xlexpoutsh, xlremit, xlothertransfers, xlprocampo, xlnhh, xlhhinc, xlhhexp, xlhhsize, xlrevsh_vil, xlrevsh_zoi,
     xlrevsh_roc, xlrevsh_row, xlVA2IDsh ;


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
     ID(g,gg,h)     intermediate demand for production of g  **** not in this version yet!
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
;

variables
* trade
     HMS(g,h)  household marketed surplus of good g
     VMS(g,v)  village marketed surplus of good g
     ZMS(g)     ZOI marketed surplus of a good

     HFMS(f,h) factor marketed surplus from the household
     VFMS(f,v) factor marketed surplus out of the village
     ZFMS(f)   factor marketed surplus out of the zoi
     USELESS   trick variable to make gams think it's maximising in the nlp
;
USELESS.l = 1 ;

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
     procampo(h) values of procampo received (true or theoretical)

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

* If the dummy is 0 the FD of purchased inputs is of the same form as all other factors
* If the dummy is 1 then the FD is limited by the budget constraint
EQ_FDPURCH(g,f,h)$fpurch(f)..
     FD(g,f,h)*(R(g,f,h)$fk(f) + WZ(f)$(ftz(f)+ftw(f)) + sum(v$maphv(h,v),WV(f,v))$ftv(f))
      =E= (PVA(g,h)*QP(g,h)*shcobb(g,f,h))$(%budgetconstraint% = 0)
         +(pibudget(g,h))$(%budgetconstraint% = 1)
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
            + procampo(h)
            + exinc(h)
;

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
     HFMS(ft,h) =E= HFSUP(ft,h) - sum(g, FD(g,ft,h))
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
ttqp_dr(draw)
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
procampo_dr(h,draw)   procampo value at beginning


* calibration values in each draw
pv1(g,v,draw)       calibrated price at village level
pz1(g,draw)         calibrated price at zoi level
ph1(g,h,draw)       calibrated price as seen by household
pva1(g,h,draw)      calibrated price of value added
qva1(g,h,draw)      calibrated quantity of value added
qp1(g,h,draw)       calibrated quantity produced
tqp1(g,draw)        calibrated total quantity produced
ttqp1(draw)
hqp1(h,draw)         calibrated total qty produced by a household

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
cri1(v,f,draw)        calibrated rent weighted index

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
vfmsfix1(f,v,draw)    calibrated factors fixed at the Village level (family labor)
zfmsfix1(f,draw)      calibrated factors fixed at the zoi level (hired labor)
hfsup1(f,h,draw)    calibrated factor supply by the household


* after a simulation for each draw
pv2(g,v,draw)       simulated price at village level
pz2(g,draw)         simulated price at zoi level
ph2(g,h,draw)       simulated price as seen by household
pva2(g,h,draw)      simulated price of value added
qva2(g,h,draw)      simulated quantity of value added
qp2(g,h,draw)       simulated quantity produced
tqp2(g,draw)        simulated total quantity produced in the economy
ttqp2(draw)
hqp2(h,draw)         calibrated total qty produced by a household

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

* delta calibration /simulation
pvD(g,v,draw)       delta price at village level
pzD(g,draw)         delta price at zoi level
phD(g,h,draw)       delta price as seen by household

pvaD(g,h,draw)      delta price of value added
qvaD(g,h,draw)      delta quantity of value added
qpD(g,h,draw)       delta quantity produced
tqpD(g,draw)        delta total qp
ttqpD(draw)
hqpD(h,draw)         calibrated total qty produced by a household

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
criD(v,f,draw)        delta capital rent index (cap rent in activity*weight of activity)
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

* percent change calibration/simulation
pvPC(g,v,draw)        % change price at village level
pzPC(g,draw)          % chage price at zoi level
phPC(g,h,draw)        % change price as seen by household

pvaPC(g,h,draw)      % change price of value added
qvaPC(g,h,draw)      % change quantity of value added
qpPC(g,h,draw)       % change quantity produced
tqpPC(g,draw)        % change in total qp
ttqpPC(draw)
hqpPC(h,draw)        % calibrated total qty produced by a household

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

* START FROM INCOME:
y_dr(h,draw) = xlhhinc(h)*xlnhh(h) ;
* all prices are 1 so cpi is 1
cpi_dr(h,draw) = 1 ;
ry_dr(h,draw) = y_dr(h,draw) ;

* figure out THEORETICAL procampo income - which will have procampo consumption
* it is 1.3 times larger than what is reported (so that the leakage is 75% of that)
procampo(h) = xlprocampo(h)*1.3 ;
procampo_dr(h,draw) = procampo(h) ;



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
*netexpsh(g)$gnag(g) = 0;
display netexpsh ;

* intermediate demand requirements
alias(g,ggg);
*idsh_dr(gg,g,h,draw) = xlVA2IDsh(gg,g,h)/(1+sum(ggg,xlVA2IDsh(ggg,g,h)));
display xlID, xlFD;

parameter d                                ;
d(g,h)=sum(ggg,xlID(ggg,g,h))+sum(f,xlFD(g,f,h));
display d;

idsh_dr(gg,g,h,draw)$xlID(gg,g,h) = xlID(gg,g,h)/(sum(ggg,xlID(ggg,g,h))+sum(f,xlFD(g,f,h)));
tidsh_dr(g,h,draw) = sum(gg,idsh_dr(gg,g,h,draw));
display idsh_dr, tidsh_dr;
*$exit

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
ttqp_dr(draw)= sum(g,tqp_dr(g,draw));

display tqp_dr, ttqp_dr ;

* split qp in each household according to their capital shares:
parameter qpshare(h,g) share of household h in production of g ;
qpshare(h,g)$gnag(g) = xlFD(g,"K",h) / sum(hh,xlFD(g,"K",hh)) ;
*qpshare(h,g)$gag(g) = xlFD(g,"LAND",h) / sum(hh,xlFD(g,"LAND",hh)) ;   -- makes huge exinc
display qpshare ;
qp_dr(g,h,draw) = tqp_dr(g,draw) * qpshare(h,g) ;
display qp_dr ;

* several possibilities for crop/livestock closures.
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
endow_dr("HL",h,draw) = shfl(h) * sum((hh,g), fd_dr(g,"HL",hh,draw)) ;
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
hfms_dr(ft,h,draw) = endow_dr(ft,h,draw) - sum(g, fd_dr(g,ft,h,draw));
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
parameter exinc_dr2(h,draw) exogenous income computation
          exincsh2(h,draw)  share of income being exogenous using exinc2
          feinc_dr(h,draw) income from factor endowments in the household
          fecomp_dr(f,h,draw) income components ;
* this is if we make exogenous income the residual from Y-FD
feinc_dr(h,draw) = sum((g,fk),r_dr(g,fk,h,draw)*fd_dr(g,fk,h,draw)) + sum(ft, wz_dr(ft,draw)*endow_dr(ft,h,draw)) ;
exinc_dr2(h,draw) = y_dr(h,draw) - feinc_dr(h,draw) ;
exincsh2(h,draw) = exinc_dr2(h,draw) / y_dr(h,draw) ;
display feinc_dr, exinc_dr2, exincsh2 ;
* net out procampo payments:
exinc_dr(h,draw) = exinc_dr2(h,draw)-procampo(h) ;

display acobb_dr, shcobb_dr, pv_dr, pz_dr, ph_dr, pva_dr, qva_dr, fd_dr, id_dr, r_dr, wz_dr, qp_dr, fixfac_dr, pva_dr,
        exinc_dr, endow_dr, y_dr, trinsh_dr, qc_dr, alpha_dr, troutsh_dr, hfd_dr, vfd_dr, zfd_dr,
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
outmat("FACT","",f,"ROW","","")$(signzfms(f) =  1)  =   zfms_dr(f,"dr0") / 1000000;
* commodity imports or exports
outmat("ROW","","","COMM","",g)$(signzms(g) = -1)  = -zms_dr(g,"dr0")   / 1000000;
outmat("COMM","",g,"ROW","","")$(signzms(g) = 1)   = zms_dr(g,"dr0")     / 1000000;
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
loop(draw,
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
hfsupzero(ft,h)= endow_dr(ft,h, draw) ;
pibudget(g,h)  = FD.l(g,"PURCH",h)*WZ.l("PURCH") ;
pibsh(g,h)     = pibudget(g,h)/sum(gg,pibudget(gg,h)) ;
procampo(h)    = procampo_dr(h,draw);


* read the supply elasticities from the locals defined at the top of the program
hfsupel("HL",h) = %lse% ;
hfsupel("FL",h) = %lse% ;
HFSUP.l(f,h)    = hfsupzero(f,h) ;

* closures: fixed wages and prices on world-market-integrated factors and goods (ftw & gtw)
WZ.fx(ftw) = WZ.l(ftw);
PZ.fx(gtw) = PZ.l(gtw) ;

display PV.l, PZ.l, PH.l, PVA.l, QVA.l, FD.l, QP.l, ID.l, QC.l, Y.l, CPI.l, RY.l, SAV.l, EXPROC.l, HMS.l, VMS.l, ZMS.l, R.l, WZ.l, HFMS.l, VFMS.l, ZFMS.l;

*---------------------------------
* RE-CALIBRATION
*---------------------------------
* set iterlim to 2 when using nlp, to 1 when using mcp. It's all about a difference between CONPT and PATH solvers.
option iterlim = 1 ;
solve genCD using mcp ;
option iterlim=1000;
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

* more params
tqp1(g,draw)        = sum(h,qp1(g,h,draw)) ;
ttqp1(draw)        = sum(g,tqp1(g,draw)) ;
hqp1(h,draw)        = sum(g, qp1(g,h,draw)) ;


*------------------------------------
* SIMULATION FOR EACH CALIBRATED DRAW
*------------------------------------
* This simulates the procampo payments reaching what they should be, rather than what they are
transfer(h) = 0 ;
transfer(h) = procampo(h)*0.25;
procampo(h) = procampo(h)-transfer(h) ;

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
ttqp2(draw)        = sum(g,tqp2(g,draw)) ;
hqp2(h,draw)        = sum(g, qp2(g,h,draw)) ;

fixfac2(g,fk,h,draw) = fixfac(g,fk,h) ;
pva2(g,h,draw)      = PVA.l(g,h) ;
vash2(g,h,draw)      = vash(g,h) ;
exinc2(h,draw)      = exinc(h) ;
endow2(f,h,draw)    = endow(f,h) ;
y2(h,draw)          = Y.l(h) ;
qc2(g,h,draw)       = QC.l(g,h) ;
cpi2(h,draw)        = CPI.l(h) ;
vqc2(v,g,draw)      = sum(h$maphv(h,v), qc2(g,h,draw));
* village cpi is weighted sum of prices
vcpi2(v,draw)       = sum((h,g)$maphv(h,v), (ph2(g,h,draw)**2)*qc2(g,h,draw)) / sum((h,g)$maphv(h,v),ph2(g,h,draw)*qc2(g,h,draw)) ;
* wieghted capital rent in the village
cri2(v,f,draw)          = sum((g,h)$maphv(h,v), r2(g,f,h,draw)*fd2(g,f,h,draw)/sum((gg,hh)$maphv(hh,v),fd2(gg,f,hh,draw)) ) ;

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
        trinsh1, qc1, alpha1, troutsh1, hfsup1, hfd1, vfd1, zfd1, hms1, vms1, zms1, hfms1, vfms1, zfms1 ;

display pv2, pz2, ph2, qva2, fd2, id2, r2, wv2, wz2, qp2, tqp2, fixfac2, pva2, exinc2, endow2, y2, cpi2, vcpi2, ry2,
        trinsh2, qc2, alpha2, troutsh2, hfsup2, hfd2, vfd2, zfd2, hms2, vms2, zms2, hfms2, vfms2, zfms2 ;

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
ttqpD(draw)         = ttqp2(draw) - ttqp1(draw) ;
hqpD(h,draw)        = hqp2(h,draw) - hqp1(h,draw) ;

fixfacD(g,fk,h,draw) = fixfac2(g,fk,h,draw) - fixfac1(g,fk,h,draw) ;
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
ttqpPC(draw)$ttqp1(draw)            = 100*ttqpD(draw) / ttqp1(draw) ;

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


display pvD, pzD, phD, qvaD, fdD, idD, rD, wvD, wzD, qpD, tqpD, fixfacD, pvaD, exincD, endowD, yD, cpiD, vcpiD, ryD, tyD, tryD,
        trinshD, qcD, alphaD, troutshD, hfsupD, hfdD, vfdD, zfdD, hmsD, vmsD, zmsD, hfmsD, vfmsD, zfmsD ,
        vashD, trinD, troutD;

display pvPC, pzPC, phPC, qvaPC, fdPC, idPC, rPC, wvPC, wzPC, qpPC, tqpPC, fixfacPC, pvaPC, exincPC, endowPC, yPC, cpiPC, vcpiPC, ryPC, tyPC, tryPC,
        trinshPC, qcPC, alphaPC, troutshPC, hfsupPC, hfdPC, vfdPC, zfdPC, hmsPC, vmsPC, zmsPC, hfmsPC, vfmsPC, zfmsPC ,
        vashPC, trinPC, troutPC ;

* Multipliers we need for output
parameter
          ymult_all(draw) nominal income muliplier on hh A B C amd D
          rymult_all(draw) real income muliplier on hh A B C amd D
          ytotmult_h(h,draw) nominal income muliplier divided by total transfer
          rytotmult_h(h,draw) real income muliplier divided by total transfer
          ttprodmult(draw)         total multiplier on ttqp
          hprodmult(h,draw)        total household production multiplier
          prodmult_all(g,draw)     total production multiplier;

ytotmult_h(h,draw) = yD(h,draw) /sum(hh, transfer(hh)) ;
ymult_all(draw)$sum(h,transfer(h))  = sum(h,yD(h,draw)) / sum(h,transfer(h)) ;
rytotmult_h(h,draw) = ryD(h,draw) /sum(hh, transfer(hh)) ;
rymult_all(draw)$sum(h,transfer(h))  = sum(h,ryD(h,draw)) / sum(h,transfer(h)) ;
ttprodmult(draw)$sum(h,transfer(h))  = ttqpD(draw) / sum(h,transfer(h)) ;
hprodmult(h,draw)$sum(hh,transfer(hh))  = hqpD(h,draw) / sum(hh,transfer(hh)) ;
prodmult_all(g,draw)$sum(h,transfer(h))  = sum(h,qpD(g,h,draw)) / sum(h,transfer(h)) ;

display ymult_all, cpiPC, rymult_all, rytotmult_h, ytotmult_h,
         ttprodmult, hprodmult, prodmult_all ;


*-----------------------------------------------------------------------
* Now output parameters with mean and variance
*-----------------------------------------------------------------------
set mv /mean, stdev, pct5, pct95/ ;

abort$(card(draw) le 1) "ONE REPETITION ONLY - NO MEANS OR STDEVS TO COMPUTE";

parameter
* mean and stdev of starting matrix
pv1_mv(g,v,mv)       mean and stdev of calibrated village price
pz1_mv(g,mv)         mean and stdev of calibrated zoi price
ph1_mv(g,h,mv)       mean and stdev of calibrated market price as seen by household

pva1_mv(g,h,mv)      mean and stdev of calibrated price of value added
qva1_mv(g,h,mv)      mean and stdev of calibrated quantity of value added
qp1_mv(g,h,mv)       mean and stdev of calibrated quantity produced
fd1_mv(g,f,h,mv)     mean and stdev of calibrated factor demand
id1_mv(g,gg,h,mv)    mean and stdev of calibrated intermediate demand
acobb1_mv(g,h,mv)    mean and stdev of calibrated cobb-douglas shifter
shcobb1_mv(g,f,h,mv) mean and stdev of calibrated cobb-douglas shares
r1_mv(g,f,h,mv)      mean and stdev of calibrated rent for fixed factors
wv1_mv(f,v,mv)       mean and stdev of calibrated village-wide wage for tradable factors
wz1_mv(f,mv)         mean and stdev of calibrated zoi-wide wage for tradable factors
vash1_mv(g,h,mv)     mean and stdev of calibrated value-added share
idsh1_mv(gg,g,h,mv)  mean and stdev of calibrated intermediate demand share
tidsh1_mv(gg,h,mv)   mean and stdev of calibrated total intermediate input share (1_mv-vash)
fixfac1_mv(g,f,h,mv) mean and stdev of calibrated fixed factor demand
exinc1_mv(h,mv)      mean and stdev of calibrated exogenous income
endow1_mv(f,h,mv)    mean and stdev of calibrated endowment
qc1_mv(g,h,mv)       mean and stdev of calibrated level of consumption
alpha1_mv(g,h,mv)    mean and stdev of calibrated consumption shares
y1_mv(h,mv)          mean and stdev of calibrated nominal income of household
cpi1_mv(h,mv)        mean and stdev of calibrated cpi of household
cri1_mv(v,f,mv)      mean and stdev of calibrated cpi of village
vcpi1_mv(v,mv)       mean and stdev of calibrated cpi of village
ry1_mv(h,mv)         mean and stdev of calibrated real income of household
cmin1_mv(g,h,mv)     mean and stdev of calibrated incompressible demand
trin1_mv(h,mv)       mean and stdev of calibrated transfers in - received
trout1_mv(h,mv)      mean and stdev of calibrated transfers out - given
trinsh1_mv(h,mv)     mean and stdev of calibrated share of all transfers in the eco going to h
troutsh1_mv(h,mv)    mean and stdev of calibrated share of yousehold h's income being given as transfers
hfd1_mv(f,h,mv)      mean and stdev of calibrated factor demand of household h for factor f
vfd1_mv(f,v,mv)      mean and stdev of calibrated village demand for factor f
zfd1_mv(f,mv)        mean and stdev of calibrated zoi demand for factor f
hms1_mv(g,h,mv)      mean and stdev of calibrated household marketed surplus of good g
vms1_mv(g,v,mv)      mean and stdev of calibrated village marketed surplus of good g
zms1_mv(g,mv)        mean and stdev of calibrated household marketed surplus of good g
hfms1_mv(f,h,mv)     mean and stdev of calibrated household factor marketed surplus
vfms1_mv(f,v,mv)     mean and stdev of calibrated village factor marketed surplus
zfms1_mv(f,mv)       mean and stdev of calibrated zoi factor marketed surplus
;



pv1_mv(g,v,"mean") = sum(draw, pv1(g,v,draw)) / card(draw) ;
pv1_mv(g,v,"stdev") = sqrt(sum(draw, sqr(pv1(g,v,draw) - pv1_mv(g,v,"mean")))/(card(draw)-1)) ;
pz1_mv(g,"mean") = sum(draw, pz1(g,draw)) / card(draw) ;
pz1_mv(g,"stdev") = sqrt(sum(draw, sqr(pz1(g,draw) - pz1_mv(g,"mean")))/(card(draw)-1)) ;
ph1_mv(g,h,"mean") = sum(draw, ph1(g,h,draw)) / card(draw) ;
ph1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(ph1(g,h,draw) - ph1_mv(g,h,"mean")))/(card(draw)-1)) ;

pva1_mv(g,h,"mean") = sum(draw, pva1(g,h,draw)) / card(draw) ;
pva1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(pva1(g,h,draw) - pva1_mv(g,h,"mean")))/(card(draw)-1)) ;
qva1_mv(g,h,"mean") = sum(draw, qva1(g,h,draw)) / card(draw) ;
qva1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qva1(g,h,draw) - qva1_mv(g,h,"mean")))/(card(draw)-1)) ;
qp1_mv(g,h,"mean") = sum(draw, qp1(g,h,draw)) / card(draw) ;
qp1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qp1(g,h,draw) - qp1_mv(g,h,"mean")))/(card(draw)-1)) ;
fd1_mv(g,f,h,"mean") = sum(draw, fd1(g,f,h,draw)) / card(draw) ;
fd1_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fd1(g,f,h,draw) - fd1_mv(g,f,h,"mean")))/(card(draw)-1)) ;
id1_mv(g,gg,h,"mean") = sum(draw, id1(g,gg,h,draw)) / card(draw) ;
id1_mv(g,gg,h,"stdev") = sqrt(sum(draw, sqr(id1(g,gg,h,draw) - id1_mv(g,gg,h,"mean")))/(card(draw)-1)) ;
acobb1_mv(g,h,"mean") = sum(draw, acobb1(g,h,draw)) / card(draw) ;
acobb1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(acobb1(g,h,draw) - acobb1_mv(g,h,"mean")))/(card(draw)-1)) ;
shcobb1_mv(g,f,h,"mean") = sum(draw, shcobb1(g,f,h,draw)) / card(draw) ;
shcobb1_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(shcobb1(g,f,h,draw) - shcobb1_mv(g,f,h,"mean")))/(card(draw)-1)) ;
r1_mv(g,f,h,"mean") = sum(draw, r1(g,f,h,draw)) / card(draw) ;
r1_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(r1(g,f,h,draw) - r1_mv(g,f,h,"mean")))/(card(draw)-1)) ;
wv1_mv(f,v,"mean") = sum(draw, wv1(f,v,draw)) / card(draw) ;
wv1_mv(f,v,"stdev") = sqrt(sum(draw, sqr(wv1(f,v,draw) - wv1_mv(f,v,"mean")))/(card(draw)-1)) ;
wz1_mv(f,"mean") = sum(draw, wz1(f,draw)) / card(draw) ;
wz1_mv(f,"stdev") = sqrt(sum(draw, sqr(wz1(f,draw) - wz1_mv(f,"mean")))/(card(draw)-1)) ;
vash1_mv(g,h,"mean") = sum(draw, vash1(g,h,draw)) / card(draw) ;
vash1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(vash1(g,h,draw) - vash1_mv(g,h,"mean")))/(card(draw)-1)) ;
qp1_mv(g,h,"mean") = sum(draw, qp1(g,h,draw)) / card(draw) ;
qp1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qp1(g,h,draw) - qp1_mv(g,h,"mean")))/(card(draw)-1)) ;
idsh1_mv(g,gg,h,"mean") = sum(draw, idsh1(g,gg,h,draw)) / card(draw) ;
idsh1_mv(g,gg,h,"stdev") = sqrt(sum(draw, sqr(idsh1(g,gg,h,draw) - idsh1_mv(g,gg,h,"mean")))/(card(draw)-1)) ;
tidsh1_mv(g,h,"mean") = sum(draw, tidsh1(g,h,draw)) / card(draw) ;
tidsh1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(tidsh1(g,h,draw) - tidsh1_mv(g,h,"mean")))/(card(draw)-1)) ;
fixfac1_mv(g,f,h,"mean") = sum(draw, fixfac1(g,f,h,draw)) / card(draw) ;
fixfac1_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fixfac1(g,f,h,draw) - fixfac1_mv(g,f,h,"mean")))/(card(draw)-1)) ;
exinc1_mv(h,"mean") = sum(draw, exinc1(h,draw)) / card(draw) ;
exinc1_mv(h,"stdev") = sqrt(sum(draw, sqr(exinc1(h,draw) - exinc1_mv(h,"mean")))/(card(draw)-1)) ;
endow1_mv(f,h,"mean") = sum(draw, endow1(f,h,draw)) / card(draw) ;
endow1_mv(f,h,"stdev") = sqrt(sum(draw, sqr(endow1(f,h,draw) - endow1_mv(f,h,"mean")))/(card(draw)-1)) ;
qc1_mv(g,h,"mean") = sum(draw, qc1(g,h,draw)) / card(draw) ;
qc1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qc1(g,h,draw) - qc1_mv(g,h,"mean")))/(card(draw)-1)) ;
alpha1_mv(g,h,"mean") = sum(draw, alpha1(g,h,draw)) / card(draw) ;
alpha1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(alpha1(g,h,draw) - alpha1_mv(g,h,"mean")))/(card(draw)-1)) ;
y1_mv(h,"mean") = sum(draw, y1(h,draw)) / card(draw) ;
y1_mv(h,"stdev") = sqrt(sum(draw, sqr(y1(h,draw) - y1_mv(h,"mean")))/(card(draw)-1)) ;
cpi1_mv(h,"mean") = sum(draw, cpi1(h,draw)) / card(draw) ;
cpi1_mv(h,"stdev") = sqrt(sum(draw, sqr(cpi1(h,draw) - cpi1_mv(h,"mean")))/(card(draw)-1)) ;
vcpi1_mv(v,"mean") = sum(draw, vcpi1(v,draw)) / card(draw) ;
vcpi1_mv(v,"stdev") = sqrt(sum(draw, sqr(vcpi1(v,draw) - vcpi1_mv(v,"mean")))/(card(draw)-1)) ;
cri1_mv(v,f,"mean") = sum(draw, cri1(v,f,draw)) / card(draw) ;
cri1_mv(v,f,"stdev") = sqrt(sum(draw, sqr(cri1(v,f,draw) - cri1_mv(v,f,"mean")))/(card(draw)-1)) ;


ry1_mv(h,"mean") = sum(draw, ry1(h,draw)) / card(draw) ;
ry1_mv(h,"stdev") = sqrt(sum(draw, sqr(ry1(h,draw) - ry1_mv(h,"mean")))/(card(draw)-1)) ;

cmin1_mv(g,h,"mean") = sum(draw, cmin1(g,h,draw)) / card(draw) ;
cmin1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(cmin1(g,h,draw) - cmin1_mv(g,h,"mean")))/(card(draw)-1)) ;
trin1_mv(h,"mean") = sum(draw, trin1(h,draw)) / card(draw) ;
trin1_mv(h,"stdev") = sqrt(sum(draw, sqr(trin1(h,draw) - trin1_mv(h,"mean")))/(card(draw)-1)) ;
trout1_mv(h,"mean") = sum(draw, trout1(h,draw)) / card(draw) ;
trout1_mv(h,"stdev") = sqrt(sum(draw, sqr(trout1(h,draw) - trout1_mv(h,"mean")))/(card(draw)-1)) ;
trinsh1_mv(h,"mean") = sum(draw, trinsh1(h,draw)) / card(draw) ;
trinsh1_mv(h,"stdev") = sqrt(sum(draw, sqr(trinsh1(h,draw) - trinsh1_mv(h,"mean")))/(card(draw)-1)) ;
troutsh1_mv(h,"mean") = sum(draw, troutsh1(h,draw)) / card(draw) ;
troutsh1_mv(h,"stdev") = sqrt(sum(draw, sqr(troutsh1(h,draw) - troutsh1_mv(h,"mean")))/(card(draw)-1)) ;
hfd1_mv(f,h,"mean") = sum(draw, hfd1(f,h,draw)) / card(draw) ;
hfd1_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfd1(f,h,draw) - hfd1_mv(f,h,"mean")))/(card(draw)-1)) ;
vfd1_mv(f,v,"mean") = sum(draw, vfd1(f,v,draw)) / card(draw) ;
vfd1_mv(f,v,"stdev") = sqrt(sum(draw, sqr(vfd1(f,v,draw) - vfd1_mv(f,v,"mean")))/(card(draw)-1)) ;
zfd1_mv(f,"mean") = sum(draw, zfd1(f,draw)) / card(draw) ;
zfd1_mv(f,"stdev") = sqrt(sum(draw, sqr(zfd1(f,draw) - zfd1_mv(f,"mean")))/(card(draw)-1)) ;
hms1_mv(g,h,"mean") = sum(draw, hms1(g,h,draw)) / card(draw) ;
hms1_mv(g,h,"stdev") = sqrt(sum(draw, sqr(hms1(g,h,draw) - hms1_mv(g,h,"mean")))/(card(draw)-1)) ;
vms1_mv(g,v,"mean") = sum(draw, vms1(g,v,draw)) / card(draw) ;
vms1_mv(g,v,"stdev") = sqrt(sum(draw, sqr(vms1(g,v,draw) - vms1_mv(g,v,"mean")))/(card(draw)-1)) ;
zms1_mv(g,"mean") = sum(draw, zms1(g,draw)) / card(draw) ;
zms1_mv(g,"stdev") = sqrt(sum(draw, sqr(zms1(g,draw) - zms1_mv(g,"mean")))/(card(draw)-1)) ;
hfms1_mv(f,h,"mean") = sum(draw, hfms1(f,h,draw)) / card(draw) ;
hfms1_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfms1(f,h,draw) - hfms1_mv(f,h,"mean")))/(card(draw)-1)) ;
vfms1_mv(f,v,"mean") = sum(draw, vfms1(f,v,draw)) / card(draw) ;
vfms1_mv(f,v,"stdev") = sqrt(sum(draw, sqr(vfms1(f,v,draw) - vfms1_mv(f,v,"mean")))/(card(draw)-1)) ;
zfms1_mv(f,"mean") = sum(draw, zfms1(f,draw)) / card(draw) ;
zfms1_mv(f,"stdev") = sqrt(sum(draw, sqr(zfms1(f,draw) - zfms1_mv(f,"mean")))/(card(draw)-1)) ;

display pv1_mv, pz1_mv, ph1_mv, pva1_mv, qva1_mv, qp1_mv, fd1_mv, id1_mv, acobb1_mv, shcobb1_mv, r1_mv, wv1_mv, wz1_mv, vash1_mv, idsh1_mv,
        tidsh1_mv, fixfac1_mv, exinc1_mv, endow1_mv, qc1_mv, alpha1_mv, y1_mv, cpi1_mv, vcpi1_mv,  ry1_mv, cmin1_mv, trin1_mv, trout1_mv, trinsh1_mv,
        troutsh1_mv, hfd1_mv, vfd1_mv, zfd1_mv, hms1_mv, vms1_mv, zms1_mv, hfms1_mv, vfms1_mv, zfms1_mv ;

parameter
* mean and stdev of starting matrix
pv2_mv(g,v,mv)       mean and stdev of simulated village price
pz2_mv(g,mv)         mean and stdev of simulated zoi price
ph2_mv(g,h,mv)       mean and stdev of simulated market price  as seen by household

pva2_mv(g,h,mv)      mean and stdev of simulated price of value added
qva2_mv(g,h,mv)      mean and stdev of simulated quantity of value added
qp2_mv(g,h,mv)       mean and stdev of simulated quantity produced
fd2_mv(g,f,h,mv)     mean and stdev of simulated factor demand
id2_mv(g,gg,h,mv)    mean and stdev of simulated intermediate demand
acobb2_mv(g,h,mv)    mean and stdev of simulated cobb-douglas shifter
shcobb2_mv(g,f,h,mv) mean and stdev of simulated cobb-douglas shares
r2_mv(g,f,h,mv)      mean and stdev of simulated rent for fixed factors
wv2_mv(f,v,mv)       mean and stdev of simulated village-wide wage for tradable factors
wz2_mv(f,mv)         mean and stdev of simulated zoi-wide wage for tradable factors
vash2_mv(g,h,mv)     mean and stdev of simulated value-added share
idsh2_mv(gg,g,h,mv)  mean and stdev of simulated intermediate demand share
tidsh2_mv(gg,h,mv)   mean and stdev of simulated total intermediate input share (2_mv-vash)
fixfac2_mv(g,f,h,mv) mean and stdev of simulated fixed factor demand
exinc2_mv(h,mv)      mean and stdev of simulated exogenous income
endow2_mv(f,h,mv)    mean and stdev of simulated endowment
qc2_mv(g,h,mv)       mean and stdev of simulated level of consumption
alpha2_mv(g,h,mv)    mean and stdev of simulated consumption shares
y2_mv(h,mv)          mean and stdev of simulated income of household
cpi2_mv(h,mv)        mean and stdev of simulated cpi of household
vcpi2_mv(v,mv)       mean and stdev of calibrated cpi of village
cri2_mv(v,f,mv)      mean and stdev of calibrated cpi of village
ry2_mv(h,mv)         mean and stdev of simulated real income of household
cmin2_mv(g,h,mv)     mean and stdev of simulated incompressible demand
trin2_mv(h,mv)       mean and stdev of simulated transfers in - received
trout2_mv(h,mv)      mean and stdev of simulated transfers out - given
trinsh2_mv(h,mv)     mean and stdev of simulated share of all transfers in the eco going to h
troutsh2_mv(h,mv)    mean and stdev of simulated share of yousehold h's income being given as transfers
hfd2_mv(f,h,mv)      mean and stdev of simulated factor demand of household h for factor f
vfd2_mv(f,v,mv)      mean and stdev of simulated village demand for factor f
zfd2_mv(f,mv)        mean and stdev of simulated zoi demand for factor f
hms2_mv(g,h,mv)      mean and stdev of simulated household marketed surplus of good g
vms2_mv(g,v,mv)      mean and stdev of simulated village marketed surplus of good g
zms2_mv(g,mv)        mean and stdev of simulated household marketed surplus of good g
hfms2_mv(f,h,mv)     mean and stdev of simulated household factor marketed surplus
vfms2_mv(f,v,mv)     mean and stdev of simulated village factor marketed surplus
zfms2_mv(f,mv)       mean and stdev of simulated zoi factor marketed surplus
;


pv2_mv(g,v,"mean") = sum(draw, pv2(g,v,draw)) / card(draw) ;
pv2_mv(g,v,"stdev") = sqrt(sum(draw, sqr(pv2(g,v,draw) - pv2_mv(g,v,"mean")))/(card(draw)-1)) ;
pz2_mv(g,"mean") = sum(draw, pz2(g,draw)) / card(draw) ;
pz2_mv(g,"stdev") = sqrt(sum(draw, sqr(pz2(g,draw) - pz2_mv(g,"mean")))/(card(draw)-1)) ;
ph2_mv(g,h,"mean") = sum(draw, ph2(g,h,draw)) / card(draw) ;
ph2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(ph2(g,h,draw) - ph2_mv(g,h,"mean")))/(card(draw)-1)) ;

pva2_mv(g,h,"mean") = sum(draw, pva2(g,h,draw)) / card(draw) ;
pva2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(pva2(g,h,draw) - pva2_mv(g,h,"mean")))/(card(draw)-1)) ;
qva2_mv(g,h,"mean") = sum(draw, qva2(g,h,draw)) / card(draw) ;
qva2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qva2(g,h,draw) - qva2_mv(g,h,"mean")))/(card(draw)-1)) ;
qp2_mv(g,h,"mean") = sum(draw, qp2(g,h,draw)) / card(draw) ;
qp2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qp2(g,h,draw) - qp2_mv(g,h,"mean")))/(card(draw)-1)) ;
fd2_mv(g,f,h,"mean") = sum(draw, fd2(g,f,h,draw)) / card(draw) ;
fd2_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fd2(g,f,h,draw) - fd2_mv(g,f,h,"mean")))/(card(draw)-1)) ;
id2_mv(g,gg,h,"mean") = sum(draw, id2(g,gg,h,draw)) / card(draw) ;
id2_mv(g,gg,h,"stdev") = sqrt(sum(draw, sqr(id2(g,gg,h,draw) - id2_mv(g,gg,h,"mean")))/(card(draw)-1)) ;
acobb2_mv(g,h,"mean") = sum(draw, acobb2(g,h,draw)) / card(draw) ;
acobb2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(acobb2(g,h,draw) - acobb2_mv(g,h,"mean")))/(card(draw)-1)) ;
shcobb2_mv(g,f,h,"mean") = sum(draw, shcobb2(g,f,h,draw)) / card(draw) ;
shcobb2_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(shcobb2(g,f,h,draw) - shcobb2_mv(g,f,h,"mean")))/(card(draw)-1)) ;
r2_mv(g,f,h,"mean") = sum(draw, r2(g,f,h,draw)) / card(draw) ;
r2_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(r2(g,f,h,draw) - r2_mv(g,f,h,"mean")))/(card(draw)-1)) ;
wv2_mv(f,v,"mean") = sum(draw, wv2(f,v,draw)) / card(draw) ;
wv2_mv(f,v,"stdev") = sqrt(sum(draw, sqr(wv2(f,v,draw) - wv2_mv(f,v,"mean")))/(card(draw)-1)) ;
wz2_mv(f,"mean") = sum(draw, wz2(f,draw)) / card(draw) ;
wz2_mv(f,"stdev") = sqrt(sum(draw, sqr(wz2(f,draw) - wz2_mv(f,"mean")))/(card(draw)-1)) ;
vash2_mv(g,h,"mean") = sum(draw, vash2(g,h,draw)) / card(draw) ;
vash2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(vash2(g,h,draw) - vash2_mv(g,h,"mean")))/(card(draw)-1)) ;
qp2_mv(g,h,"mean") = sum(draw, qp2(g,h,draw)) / card(draw) ;
qp2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qp2(g,h,draw) - qp2_mv(g,h,"mean")))/(card(draw)-1)) ;
fixfac2_mv(g,f,h,"mean") = sum(draw, fixfac2(g,f,h,draw)) / card(draw) ;
fixfac2_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fixfac2(g,f,h,draw) - fixfac2_mv(g,f,h,"mean")))/(card(draw)-1)) ;
exinc2_mv(h,"mean") = sum(draw, exinc2(h,draw)) / card(draw) ;
exinc2_mv(h,"stdev") = sqrt(sum(draw, sqr(exinc2(h,draw) - exinc2_mv(h,"mean")))/(card(draw)-1)) ;
endow2_mv(f,h,"mean") = sum(draw, endow2(f,h,draw)) / card(draw) ;
endow2_mv(f,h,"stdev") = sqrt(sum(draw, sqr(endow2(f,h,draw) - endow2_mv(f,h,"mean")))/(card(draw)-1)) ;
qc2_mv(g,h,"mean") = sum(draw, qc2(g,h,draw)) / card(draw) ;
qc2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qc2(g,h,draw) - qc2_mv(g,h,"mean")))/(card(draw)-1)) ;
alpha2_mv(g,h,"mean") = sum(draw, alpha2(g,h,draw)) / card(draw) ;
alpha2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(alpha2(g,h,draw) - alpha2_mv(g,h,"mean")))/(card(draw)-1)) ;
y2_mv(h,"mean") = sum(draw, y2(h,draw)) / card(draw) ;
y2_mv(h,"stdev") = sqrt(sum(draw, sqr(y2(h,draw) - y2_mv(h,"mean")))/(card(draw)-1)) ;

cpi2_mv(h,"mean") = sum(draw, cpi2(h,draw)) / card(draw) ;
cpi2_mv(h,"stdev") = sqrt(sum(draw, sqr(cpi2(h,draw) - cpi2_mv(h,"mean")))/(card(draw)-1)) ;
vcpi2_mv(v,"mean") = sum(draw, vcpi2(v,draw)) / card(draw) ;
vcpi2_mv(v,"stdev") = sqrt(sum(draw, sqr(vcpi2(v,draw) - vcpi2_mv(v,"mean")))/(card(draw)-1)) ;
cri2_mv(v,f,"mean") = sum(draw, cri2(v,f,draw)) / card(draw) ;
cri2_mv(v,f,"stdev") = sqrt(sum(draw, sqr(cri2(v,f,draw) - cri2_mv(v,f,"mean")))/(card(draw)-1)) ;


ry2_mv(h,"mean") = sum(draw, ry2(h,draw)) / card(draw) ;
ry2_mv(h,"stdev") = sqrt(sum(draw, sqr(ry2(h,draw) - ry2_mv(h,"mean")))/(card(draw)-1)) ;
trin2_mv(h,"mean") = sum(draw, trin2(h,draw)) / card(draw) ;
trin2_mv(h,"stdev") = sqrt(sum(draw, sqr(trin2(h,draw) - trin2_mv(h,"mean")))/(card(draw)-1)) ;
trout2_mv(h,"mean") = sum(draw, trout2(h,draw)) / card(draw) ;
trout2_mv(h,"stdev") = sqrt(sum(draw, sqr(trout2(h,draw) - trout2_mv(h,"mean")))/(card(draw)-1)) ;
trinsh2_mv(h,"mean") = sum(draw, trinsh2(h,draw)) / card(draw) ;
trinsh2_mv(h,"stdev") = sqrt(sum(draw, sqr(trinsh2(h,draw) - trinsh2_mv(h,"mean")))/(card(draw)-1)) ;
troutsh2_mv(h,"mean") = sum(draw, troutsh2(h,draw)) / card(draw) ;
troutsh2_mv(h,"stdev") = sqrt(sum(draw, sqr(troutsh2(h,draw) - troutsh2_mv(h,"mean")))/(card(draw)-1)) ;
hfd2_mv(f,h,"mean") = sum(draw, hfd2(f,h,draw)) / card(draw) ;
hfd2_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfd2(f,h,draw) - hfd2_mv(f,h,"mean")))/(card(draw)-1)) ;
vfd2_mv(f,v,"mean") = sum(draw, vfd2(f,v,draw)) / card(draw) ;
vfd2_mv(f,v,"stdev") = sqrt(sum(draw, sqr(vfd2(f,v,draw) - vfd2_mv(f,v,"mean")))/(card(draw)-1)) ;
zfd2_mv(f,"mean") = sum(draw, zfd2(f,draw)) / card(draw) ;
zfd2_mv(f,"stdev") = sqrt(sum(draw, sqr(zfd2(f,draw) - zfd2_mv(f,"mean")))/(card(draw)-1)) ;
hms2_mv(g,h,"mean") = sum(draw, hms2(g,h,draw)) / card(draw) ;
hms2_mv(g,h,"stdev") = sqrt(sum(draw, sqr(hms2(g,h,draw) - hms2_mv(g,h,"mean")))/(card(draw)-1)) ;
vms2_mv(g,v,"mean") = sum(draw, vms2(g,v,draw)) / card(draw) ;
vms2_mv(g,v,"stdev") = sqrt(sum(draw, sqr(vms2(g,v,draw) - vms2_mv(g,v,"mean")))/(card(draw)-1)) ;
zms2_mv(g,"mean") = sum(draw, zms2(g,draw)) / card(draw) ;
zms2_mv(g,"stdev") = sqrt(sum(draw, sqr(zms2(g,draw) - zms2_mv(g,"mean")))/(card(draw)-1)) ;
hfms2_mv(f,h,"mean") = sum(draw, hfms2(f,h,draw)) / card(draw) ;
hfms2_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfms2(f,h,draw) - hfms2_mv(f,h,"mean")))/(card(draw)-1)) ;
vfms2_mv(f,v,"mean") = sum(draw, vfms2(f,v,draw)) / card(draw) ;
vfms2_mv(f,v,"stdev") = sqrt(sum(draw, sqr(vfms2(f,v,draw) - vfms2_mv(f,v,"mean")))/(card(draw)-1)) ;
zfms2_mv(f,"mean") = sum(draw, zfms2(f,draw)) / card(draw) ;
zfms2_mv(f,"stdev") = sqrt(sum(draw, sqr(zfms2(f,draw) - zfms2_mv(f,"mean")))/(card(draw)-1)) ;

display pv2_mv, pz2_mv, ph2_mv, pva2_mv, qva2_mv, qp2_mv, fd2_mv, id2_mv, r2_mv, wv2_mv, wz2_mv, vash2_mv, fixfac2_mv,
        exinc2_mv, endow2_mv, qc2_mv, alpha2_mv, y2_mv, cpi2_mv, vcpi2_mv,  ry2_mv,  trin2_mv, trout2_mv, trinsh2_mv,
        troutsh2_mv, hfd2_mv, vfd2_mv, zfd2_mv, hms2_mv, vms2_mv, zms2_mv, hfms2_mv, vfms2_mv, zfms2_mv
, acobb2_mv, shcobb2_mv           ;

parameter
* mean and stdev of starting matrix
pvD_mv(g,v,mv)       mean and stdev of delta village price
pzD_mv(g,mv)         mean and stdev of delta zoi price
phD_mv(g,h,mv)       mean and stdev of delta market price  as seen by household

pvaD_mv(g,h,mv)      mean and stdev of delta price of value added
qvaD_mv(g,h,mv)      mean and stdev of delta quantity of value added
qpD_mv(g,h,mv)       mean and stdev of delta quantity produced
tqpD_mv(g,mv)        mean and stdev of delta total QP
ttqpD_mv(mv)

fdD_mv(g,f,h,mv)     mean and stdev of delta factor demand
idD_mv(g,gg,h,mv)    mean and stdev of delta intermediate demand
acobbD_mv(g,h,mv)    mean and stdev of delta cobb-douglas shifter
shcobbD_mv(g,f,h,mv) mean and stdev of delta cobb-douglas shares
rD_mv(g,f,h,mv)      mean and stdev of delta rent for fixed factors
wvD_mv(f,v,mv)       mean and stdev of delta village-wide wage for tradable factors
wzD_mv(f,mv)         mean and stdev of delta zoi-wide wage for tradable factors
vashD_mv(g,h,mv)     mean and stdev of delta value-added share
idshD_mv(gg,g,h,mv)  mean and stdev of delta intermediate demand share
tidshD_mv(gg,h,mv)   mean and stdev of delta total intermediate input share (D_mv-vash)
fixfacD_mv(g,f,h,mv) mean and stdev of delta fixed factor demand
exincD_mv(h,mv)      mean and stdev of delta exogenous income
endowD_mv(f,h,mv)    mean and stdev of delta endowment
qcD_mv(g,h,mv)       mean and stdev of delta level of consumption
alphaD_mv(g,h,mv)    mean and stdev of delta consumption shares
yD_mv(h,mv)          mean and stdev of delta income of household
cpiD_mv(h,mv)        mean and stdev of delta cpi of household
vcpiD_mv(v,mv)       mean and stdev of delta cpi of village
criD_mv(v,f,mv)      mean and stdev of delta cri of village
ryD_mv(h,mv)         mean and stdev of delta real income of household
tyD_mv(mv)           mean and stdev of delta total nominal income
tryD_mv(mv)          mean and stdev of delta total real income
cminD_mv(g,h,mv)     mean and stdev of delta incompressible demand
trinD_mv(h,mv)       mean and stdev of delta transfers in - received
troutD_mv(h,mv)      mean and stdev of delta transfers out - given
trinshD_mv(h,mv)     mean and stdev of delta share of all transfers in the eco going to h
troutshD_mv(h,mv)    mean and stdev of delta share of yousehold h's income being given as transfers
hfdD_mv(f,h,mv)      mean and stdev of delta factor demand of household h for factor f
vfdD_mv(f,v,mv)      mean and stdev of delta village demand for factor f
zfdD_mv(f,mv)        mean and stdev of delta zoi demand for factor f
hmsD_mv(g,h,mv)      mean and stdev of delta household marketed surplus of good g
vmsD_mv(g,v,mv)      mean and stdev of delta village marketed surplus of good g
zmsD_mv(g,mv)        mean and stdev of delta household marketed surplus of good g
hfmsD_mv(f,h,mv)     mean and stdev of delta household factor marketed surplus
vfmsD_mv(f,v,mv)     mean and stdev of delta village factor marketed surplus
zfmsD_mv(f,mv)       mean and stdev of delta zoi factor marketed surplus
;


pvD_mv(g,v,"mean") = sum(draw, pvD(g,v,draw)) / card(draw) ;
pvD_mv(g,v,"stdev") = sqrt(sum(draw, sqr(pvD(g,v,draw) - pvD_mv(g,v,"mean")))/(card(draw)-1)) ;
pzD_mv(g,"mean") = sum(draw, pzD(g,draw)) / card(draw) ;
pzD_mv(g,"stdev") = sqrt(sum(draw, sqr(pzD(g,draw) - pzD_mv(g,"mean")))/(card(draw)-1)) ;
phD_mv(g,h,"mean") = sum(draw, phD(g,h,draw)) / card(draw) ;
phD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(phD(g,h,draw) - phD_mv(g,h,"mean")))/(card(draw)-1)) ;

pvaD_mv(g,h,"mean") = sum(draw, pvaD(g,h,draw)) / card(draw) ;
pvaD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(pvaD(g,h,draw) - pvaD_mv(g,h,"mean")))/(card(draw)-1)) ;
qvaD_mv(g,h,"mean") = sum(draw, qvaD(g,h,draw)) / card(draw) ;
qvaD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qvaD(g,h,draw) - qvaD_mv(g,h,"mean")))/(card(draw)-1)) ;
qpD_mv(g,h,"mean") = sum(draw, qpD(g,h,draw)) / card(draw) ;
qpD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qpD(g,h,draw) - qpD_mv(g,h,"mean")))/(card(draw)-1)) ;
tqpD_mv(g,"mean") = sum(draw, tqpD(g,draw)) / card(draw) ;
tqpD_mv(g,"stdev") = sqrt(sum(draw, sqr(tqpD(g,draw) - tqpD_mv(g,"mean")))/(card(draw)-1)) ;
ttqpD_mv("mean") = sum(draw, ttqpD(draw)) / card(draw) ;
ttqpD_mv("stdev") = sqrt(sum(draw, sqr(ttqpD(draw) - ttqpD_mv("mean")))/(card(draw)-1)) ;


fdD_mv(g,f,h,"mean") = sum(draw, fdD(g,f,h,draw)) / card(draw) ;
fdD_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fdD(g,f,h,draw) - fdD_mv(g,f,h,"mean")))/(card(draw)-1)) ;
idD_mv(g,gg,h,"mean") = sum(draw, idD(g,gg,h,draw)) / card(draw) ;
idD_mv(g,gg,h,"stdev") = sqrt(sum(draw, sqr(idD(g,gg,h,draw) - idD_mv(g,gg,h,"mean")))/(card(draw)-1)) ;
acobbD_mv(g,h,"mean") = sum(draw, acobbD(g,h,draw)) / card(draw) ;
acobbD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(acobbD(g,h,draw) - acobbD_mv(g,h,"mean")))/(card(draw)-1)) ;
shcobbD_mv(g,f,h,"mean") = sum(draw, shcobbD(g,f,h,draw)) / card(draw) ;
shcobbD_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(shcobbD(g,f,h,draw) - shcobbD_mv(g,f,h,"mean")))/(card(draw)-1)) ;
rD_mv(g,f,h,"mean") = sum(draw, rD(g,f,h,draw)) / card(draw) ;
rD_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(rD(g,f,h,draw) - rD_mv(g,f,h,"mean")))/(card(draw)-1)) ;
wvD_mv(f,v,"mean") = sum(draw, wvD(f,v,draw)) / card(draw) ;
wvD_mv(f,v,"stdev") = sqrt(sum(draw, sqr(wvD(f,v,draw) - wvD_mv(f,v,"mean")))/(card(draw)-1)) ;
wzD_mv(f,"mean") = sum(draw, wzD(f,draw)) / card(draw) ;
wzD_mv(f,"stdev") = sqrt(sum(draw, sqr(wzD(f,draw) - wzD_mv(f,"mean")))/(card(draw)-1)) ;
vashD_mv(g,h,"mean") = sum(draw, vashD(g,h,draw)) / card(draw) ;
vashD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(vashD(g,h,draw) - vashD_mv(g,h,"mean")))/(card(draw)-1)) ;
fixfacD_mv(g,f,h,"mean") = sum(draw, fixfacD(g,f,h,draw)) / card(draw) ;
fixfacD_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fixfacD(g,f,h,draw) - fixfacD_mv(g,f,h,"mean")))/(card(draw)-1)) ;
exincD_mv(h,"mean") = sum(draw, exincD(h,draw)) / card(draw) ;
exincD_mv(h,"stdev") = sqrt(sum(draw, sqr(exincD(h,draw) - exincD_mv(h,"mean")))/(card(draw)-1)) ;
endowD_mv(f,h,"mean") = sum(draw, endowD(f,h,draw)) / card(draw) ;
endowD_mv(f,h,"stdev") = sqrt(sum(draw, sqr(endowD(f,h,draw) - endowD_mv(f,h,"mean")))/(card(draw)-1)) ;
qcD_mv(g,h,"mean") = sum(draw, qcD(g,h,draw)) / card(draw) ;
qcD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qcD(g,h,draw) - qcD_mv(g,h,"mean")))/(card(draw)-1)) ;
alphaD_mv(g,h,"mean") = sum(draw, alphaD(g,h,draw)) / card(draw) ;
alphaD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(alphaD(g,h,draw) - alphaD_mv(g,h,"mean")))/(card(draw)-1)) ;
yD_mv(h,"mean") = sum(draw, yD(h,draw)) / card(draw) ;
yD_mv(h,"stdev") = sqrt(sum(draw, sqr(yD(h,draw) - yD_mv(h,"mean")))/(card(draw)-1)) ;
tyD_mv("mean") = sum(draw, tyD(draw)) / card(draw) ;
tyD_mv("stdev") = sqrt(sum(draw, sqr(tyD(draw) - tyD_mv("mean")))/(card(draw)-1)) ;
tryD_mv("mean") = sum(draw, tryD(draw)) / card(draw) ;
tryD_mv("stdev") = sqrt(sum(draw, sqr(tryD(draw) - tryD_mv("mean")))/(card(draw)-1)) ;

cpiD_mv(h,"mean") = sum(draw, cpiD(h,draw)) / card(draw) ;
cpiD_mv(h,"stdev") = sqrt(sum(draw, sqr(cpiD(h,draw) - cpiD_mv(h,"mean")))/(card(draw)-1)) ;
vcpiD_mv(v,"mean") = sum(draw, vcpiD(v,draw)) / card(draw) ;
vcpiD_mv(v,"stdev") = sqrt(sum(draw, sqr(vcpiD(v,draw) - vcpiD_mv(v,"mean")))/(card(draw)-1)) ;
criD_mv(v,f,"mean") = sum(draw, criD(v,f,draw)) / card(draw) ;
criD_mv(v,f,"stdev") = sqrt(sum(draw, sqr(criD(v,f,draw) - criD_mv(v,f,"mean")))/(card(draw)-1)) ;


ryD_mv(h,"mean") = sum(draw, ryD(h,draw)) / card(draw) ;
ryD_mv(h,"stdev") = sqrt(sum(draw, sqr(ryD(h,draw) - ryD_mv(h,"mean")))/(card(draw)-1)) ;
trinD_mv(h,"mean") = sum(draw, trinD(h,draw)) / card(draw) ;
trinD_mv(h,"stdev") = sqrt(sum(draw, sqr(trinD(h,draw) - trinD_mv(h,"mean")))/(card(draw)-1)) ;
troutD_mv(h,"mean") = sum(draw, troutD(h,draw)) / card(draw) ;
troutD_mv(h,"stdev") = sqrt(sum(draw, sqr(troutD(h,draw) - troutD_mv(h,"mean")))/(card(draw)-1)) ;
trinshD_mv(h,"mean") = sum(draw, trinshD(h,draw)) / card(draw) ;
trinshD_mv(h,"stdev") = sqrt(sum(draw, sqr(trinshD(h,draw) - trinshD_mv(h,"mean")))/(card(draw)-1)) ;
troutshD_mv(h,"mean") = sum(draw, troutshD(h,draw)) / card(draw) ;
troutshD_mv(h,"stdev") = sqrt(sum(draw, sqr(troutshD(h,draw) - troutshD_mv(h,"mean")))/(card(draw)-1)) ;
hfdD_mv(f,h,"mean") = sum(draw, hfdD(f,h,draw)) / card(draw) ;
hfdD_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfdD(f,h,draw) - hfdD_mv(f,h,"mean")))/(card(draw)-1)) ;
vfdD_mv(f,v,"mean") = sum(draw, vfdD(f,v,draw)) / card(draw) ;
vfdD_mv(f,v,"stdev") = sqrt(sum(draw, sqr(vfdD(f,v,draw) - vfdD_mv(f,v,"mean")))/(card(draw)-1)) ;
zfdD_mv(f,"mean") = sum(draw, zfdD(f,draw)) / card(draw) ;
zfdD_mv(f,"stdev") = sqrt(sum(draw, sqr(zfdD(f,draw) - zfdD_mv(f,"mean")))/(card(draw)-1)) ;
hmsD_mv(g,h,"mean") = sum(draw, hmsD(g,h,draw)) / card(draw) ;
hmsD_mv(g,h,"stdev") = sqrt(sum(draw, sqr(hmsD(g,h,draw) - hmsD_mv(g,h,"mean")))/(card(draw)-1)) ;
vmsD_mv(g,v,"mean") = sum(draw, vmsD(g,v,draw)) / card(draw) ;
vmsD_mv(g,v,"stdev") = sqrt(sum(draw, sqr(vmsD(g,v,draw) - vmsD_mv(g,v,"mean")))/(card(draw)-1)) ;
zmsD_mv(g,"mean") = sum(draw, zmsD(g,draw)) / card(draw) ;
zmsD_mv(g,"stdev") = sqrt(sum(draw, sqr(zmsD(g,draw) - zmsD_mv(g,"mean")))/(card(draw)-1)) ;
hfmsD_mv(f,h,"mean") = sum(draw, hfmsD(f,h,draw)) / card(draw) ;
hfmsD_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfmsD(f,h,draw) - hfmsD_mv(f,h,"mean")))/(card(draw)-1)) ;
vfmsD_mv(f,v,"mean") = sum(draw, vfmsD(f,v,draw)) / card(draw) ;
vfmsD_mv(f,v,"stdev") = sqrt(sum(draw, sqr(vfmsD(f,v,draw) - vfmsD_mv(f,v,"mean")))/(card(draw)-1)) ;
zfmsD_mv(f,"mean") = sum(draw, zfmsD(f,draw)) / card(draw) ;
zfmsD_mv(f,"stdev") = sqrt(sum(draw, sqr(zfmsD(f,draw) - zfmsD_mv(f,"mean")))/(card(draw)-1)) ;

display pvD_mv, pzD_mv, phD_mv, pvaD_mv, qvaD_mv, qpD_mv, tqpD_mv, fdD_mv, idD_mv, rD_mv, wvD_mv, wzD_mv, vashD_mv, fixfacD_mv,
        exincD_mv, endowD_mv, qcD_mv, alphaD_mv, yD_mv, cpiD_mv, vcpiD_mv,  ryD_mv, tyD_mv, tryD_mv,  trinD_mv, troutD_mv, trinshD_mv,
        troutshD_mv, hfdD_mv, vfdD_mv, zfdD_mv, hmsD_mv, vmsD_mv, zmsD_mv, hfmsD_mv, vfmsD_mv, zfmsD_mv
     , acobbD_mv, shcobbD_mv ;

parameter
* mean and stdev of starting matrix
pvPC_mv(g,v,mv)       mean and stdev of % change in village price
pzPC_mv(g,mv)         mean and stdev of % change in zoi price
phPC_mv(g,h,mv)       mean and stdev of % change in market price as seen by household
pvaPC_mv(g,h,mv)      mean and stdev of % change in price of value added
qvaPC_mv(g,h,mv)      mean and stdev of % change in quantity of value added
qpPC_mv(g,h,mv)       mean and stdev of % change in quantity produced
tqpPC_mv(g,mv)        mean and stdev of % change in quantity produced total
ttqpPC_mv(mv)
fdPC_mv(g,f,h,mv)     mean and stdev of % change in factor demand
idPC_mv(g,gg,h,mv)    mean and stdev of % change in intermediate demand
acobbPC_mv(g,h,mv)    mean and stdev of % change in cobb-douglas shifter
shcobbPC_mv(g,f,h,mv) mean and stdev of % change in cobb-douglas shares
rPC_mv(g,f,h,mv)      mean and stdev of % change in rent for fixed factors
wvPC_mv(f,v,mv)       mean and stdev of % change in village-wide wage for tradable factors
wzPC_mv(f,mv)         mean and stdev of % change in zoi-wide wage for tradable factors
vashPC_mv(g,h,mv)     mean and stdev of % change in value-added share
idshPC_mv(gg,g,h,mv)  mean and stdev of % change in intermediate demand share
tidshPC_mv(gg,h,mv)   mean and stdev of % change in total intermediate input share (PC_mv-vash)
fixfacPC_mv(g,f,h,mv) mean and stdev of % change in fixed factor demand
exincPC_mv(h,mv)      mean and stdev of % change in exogenous income
endowPC_mv(f,h,mv)    mean and stdev of % change in endowment
qcPC_mv(g,h,mv)       mean and stdev of % change in level of consumption
alphaPC_mv(g,h,mv)    mean and stdev of % change in consumption shares
yPC_mv(h,mv)          mean and stdev of % change in income of household
cpiPC_mv(h,mv)        mean and stdev of % change cpi of household
vcpiPC_mv(v,mv)       mean and stdev of % change cpi of village
criPC_mv(v,f,mv)      mean and stdev of % change cri of village
ryPC_mv(h,mv)         mean and stdev of % change real income of household
cminPC_mv(g,h,mv)     mean and stdev of % change in incompressible demand
trinPC_mv(h,mv)       mean and stdev of % change in transfers in - received
troutPC_mv(h,mv)      mean and stdev of % change in transfers out - given
trinshPC_mv(h,mv)     mean and stdev of % change in share of all transfers in the eco going to h
troutshPC_mv(h,mv)    mean and stdev of % change in share of yousehold h's income being given as transfers
hfdPC_mv(f,h,mv)      mean and stdev of % change in factor demand of household h for factor f
vfdPC_mv(f,v,mv)      mean and stdev of % change in village demand for factor f
zfdPC_mv(f,mv)        mean and stdev of % change in zoi demand for factor f
hmsPC_mv(g,h,mv)      mean and stdev of % change in household marketed surplus of good g
vmsPC_mv(g,v,mv)      mean and stdev of % change in village marketed surplus of good g
zmsPC_mv(g,mv)        mean and stdev of % change in household marketed surplus of good g
hfmsPC_mv(f,h,mv)     mean and stdev of % change in household factor marketed surplus
vfmsPC_mv(f,v,mv)     mean and stdev of % change in village factor marketed surplus
zfmsPC_mv(f,mv)       mean and stdev of % change in zoi factor marketed surplus
;

pvPC_mv(g,v,"mean") = sum(draw, pvPC(g,v,draw)) / card(draw) ;
pvPC_mv(g,v,"stdev") = sqrt(sum(draw, sqr(pvPC(g,v,draw) - pvPC_mv(g,v,"mean")))/(card(draw)-1)) ;
pzPC_mv(g,"mean") = sum(draw, pzPC(g,draw)) / card(draw) ;
pzPC_mv(g,"stdev") = sqrt(sum(draw, sqr(pzPC(g,draw) - pzPC_mv(g,"mean")))/(card(draw)-1)) ;
phPC_mv(g,h,"mean") = sum(draw, phPC(g,h,draw)) / card(draw) ;
phPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(phPC(g,h,draw) - phPC_mv(g,h,"mean")))/(card(draw)-1)) ;
pvaPC_mv(g,h,"mean") = sum(draw, pvaPC(g,h,draw)) / card(draw) ;
pvaPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(pvaPC(g,h,draw) - pvaPC_mv(g,h,"mean")))/(card(draw)-1)) ;
qvaPC_mv(g,h,"mean") = sum(draw, qvaPC(g,h,draw)) / card(draw) ;
qvaPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qvaPC(g,h,draw) - qvaPC_mv(g,h,"mean")))/(card(draw)-1)) ;
qpPC_mv(g,h,"mean") = sum(draw, qpPC(g,h,draw)) / card(draw) ;
qpPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qpPC(g,h,draw) - qpPC_mv(g,h,"mean")))/(card(draw)-1)) ;
fdPC_mv(g,f,h,"mean") = sum(draw, fdPC(g,f,h,draw)) / card(draw) ;
fdPC_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fdPC(g,f,h,draw) - fdPC_mv(g,f,h,"mean")))/(card(draw)-1)) ;
idPC_mv(g,gg,h,"mean") = sum(draw, idPC(g,gg,h,draw)) / card(draw) ;
idPC_mv(g,gg,h,"stdev") = sqrt(sum(draw, sqr(idPC(g,gg,h,draw) - idPC_mv(g,gg,h,"mean")))/(card(draw)-1)) ;
acobbPC_mv(g,h,"mean") = sum(draw, acobbPC(g,h,draw)) / card(draw) ;
acobbPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(acobbPC(g,h,draw) - acobbPC_mv(g,h,"mean")))/(card(draw)-1)) ;
shcobbPC_mv(g,f,h,"mean") = sum(draw, shcobbPC(g,f,h,draw)) / card(draw) ;
shcobbPC_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(shcobbPC(g,f,h,draw) - shcobbPC_mv(g,f,h,"mean")))/(card(draw)-1)) ;
rPC_mv(g,f,h,"mean") = sum(draw, rPC(g,f,h,draw)) / card(draw) ;
rPC_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(rPC(g,f,h,draw) - rPC_mv(g,f,h,"mean")))/(card(draw)-1)) ;
wvPC_mv(f,v,"mean") = sum(draw, wvPC(f,v,draw)) / card(draw) ;
wvPC_mv(f,v,"stdev") = sqrt(sum(draw, sqr(wvPC(f,v,draw) - wvPC_mv(f,v,"mean")))/(card(draw)-1)) ;
wzPC_mv(f,"mean") = sum(draw, wzPC(f,draw)) / card(draw) ;
wzPC_mv(f,"stdev") = sqrt(sum(draw, sqr(wzPC(f,draw) - wzPC_mv(f,"mean")))/(card(draw)-1)) ;
vashPC_mv(g,h,"mean") = sum(draw, vashPC(g,h,draw)) / card(draw) ;
vashPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(vashPC(g,h,draw) - vashPC_mv(g,h,"mean")))/(card(draw)-1)) ;
qpPC_mv(g,h,"mean") = sum(draw, qpPC(g,h,draw)) / card(draw) ;
qpPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qpPC(g,h,draw) - qpPC_mv(g,h,"mean")))/(card(draw)-1)) ;
tqpPC_mv(g,"mean") = sum(draw, tqpPC(g,draw)) / card(draw) ;
tqpPC_mv(g,"stdev") = sqrt(sum(draw, sqr(tqpPC(g,draw) - tqpPC_mv(g,"mean")))/(card(draw)-1)) ;
ttqpPC_mv("mean") = sum(draw, ttqpPC(draw)) / card(draw) ;
ttqpPC_mv("stdev") = sqrt(sum(draw, sqr(ttqpPC(draw) - ttqpPC_mv("mean")))/(card(draw)-1)) ;

fixfacPC_mv(g,f,h,"mean") = sum(draw, fixfacPC(g,f,h,draw)) / card(draw) ;
fixfacPC_mv(g,f,h,"stdev") = sqrt(sum(draw, sqr(fixfacPC(g,f,h,draw) - fixfacPC_mv(g,f,h,"mean")))/(card(draw)-1)) ;
exincPC_mv(h,"mean") = sum(draw, exincPC(h,draw)) / card(draw) ;
exincPC_mv(h,"stdev") = sqrt(sum(draw, sqr(exincPC(h,draw) - exincPC_mv(h,"mean")))/(card(draw)-1)) ;
endowPC_mv(f,h,"mean") = sum(draw, endowPC(f,h,draw)) / card(draw) ;
endowPC_mv(f,h,"stdev") = sqrt(sum(draw, sqr(endowPC(f,h,draw) - endowPC_mv(f,h,"mean")))/(card(draw)-1)) ;
qcPC_mv(g,h,"mean") = sum(draw, qcPC(g,h,draw)) / card(draw) ;
qcPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(qcPC(g,h,draw) - qcPC_mv(g,h,"mean")))/(card(draw)-1)) ;
alphaPC_mv(g,h,"mean") = sum(draw, alphaPC(g,h,draw)) / card(draw) ;
alphaPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(alphaPC(g,h,draw) - alphaPC_mv(g,h,"mean")))/(card(draw)-1)) ;
yPC_mv(h,"mean") = sum(draw, yPC(h,draw)) / card(draw) ;
yPC_mv(h,"stdev") = sqrt(sum(draw, sqr(yPC(h,draw) - yPC_mv(h,"mean")))/(card(draw)-1)) ;
cpiPC_mv(h,"mean") = sum(draw, cpiPC(h,draw)) / card(draw) ;
cpiPC_mv(h,"stdev") = sqrt(sum(draw, sqr(cpiPC(h,draw) - cpiPC_mv(h,"mean")))/(card(draw)-1)) ;
vcpiPC_mv(v,"mean") = sum(draw, vcpiPC(v,draw)) / card(draw) ;
vcpiPC_mv(v,"stdev") = sqrt(sum(draw, sqr(vcpiPC(v,draw) - vcpiPC_mv(v,"mean")))/(card(draw)-1)) ;
criPC_mv(v,f,"mean") = sum(draw, criPC(v,f,draw)) / card(draw) ;
criPC_mv(v,f,"stdev") = sqrt(sum(draw, sqr(criPC(v,f,draw) - criPC_mv(v,f,"mean")))/(card(draw)-1)) ;

ryPC_mv(h,"mean") = sum(draw, ryPC(h,draw)) / card(draw) ;
ryPC_mv(h,"stdev") = sqrt(sum(draw, sqr(ryPC(h,draw) - ryPC_mv(h,"mean")))/(card(draw)-1)) ;
trinPC_mv(h,"mean") = sum(draw, trinPC(h,draw)) / card(draw) ;
trinPC_mv(h,"stdev") = sqrt(sum(draw, sqr(trinPC(h,draw) - trinPC_mv(h,"mean")))/(card(draw)-1)) ;
troutPC_mv(h,"mean") = sum(draw, troutPC(h,draw)) / card(draw) ;
troutPC_mv(h,"stdev") = sqrt(sum(draw, sqr(troutPC(h,draw) - troutPC_mv(h,"mean")))/(card(draw)-1)) ;
trinshPC_mv(h,"mean") = sum(draw, trinshPC(h,draw)) / card(draw) ;
trinshPC_mv(h,"stdev") = sqrt(sum(draw, sqr(trinshPC(h,draw) - trinshPC_mv(h,"mean")))/(card(draw)-1)) ;
troutshPC_mv(h,"mean") = sum(draw, troutshPC(h,draw)) / card(draw) ;
troutshPC_mv(h,"stdev") = sqrt(sum(draw, sqr(troutshPC(h,draw) - troutshPC_mv(h,"mean")))/(card(draw)-1)) ;
hfdPC_mv(f,h,"mean") = sum(draw, hfdPC(f,h,draw)) / card(draw) ;
hfdPC_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfdPC(f,h,draw) - hfdPC_mv(f,h,"mean")))/(card(draw)-1)) ;
vfdPC_mv(f,v,"mean") = sum(draw, vfdPC(f,v,draw)) / card(draw) ;
vfdPC_mv(f,v,"stdev") = sqrt(sum(draw, sqr(vfdPC(f,v,draw) - vfdPC_mv(f,v,"mean")))/(card(draw)-1)) ;
zfdPC_mv(f,"mean") = sum(draw, zfdPC(f,draw)) / card(draw) ;
zfdPC_mv(f,"stdev") = sqrt(sum(draw, sqr(zfdPC(f,draw) - zfdPC_mv(f,"mean")))/(card(draw)-1)) ;
hmsPC_mv(g,h,"mean") = sum(draw, hmsPC(g,h,draw)) / card(draw) ;
hmsPC_mv(g,h,"stdev") = sqrt(sum(draw, sqr(hmsPC(g,h,draw) - hmsPC_mv(g,h,"mean")))/(card(draw)-1)) ;
vmsPC_mv(g,v,"mean") = sum(draw, vmsPC(g,v,draw)) / card(draw) ;
vmsPC_mv(g,v,"stdev") = sqrt(sum(draw, sqr(vmsPC(g,v,draw) - vmsPC_mv(g,v,"mean")))/(card(draw)-1)) ;
zmsPC_mv(g,"mean") = sum(draw, zmsPC(g,draw)) / card(draw) ;
zmsPC_mv(g,"stdev") = sqrt(sum(draw, sqr(zmsPC(g,draw) - zmsPC_mv(g,"mean")))/(card(draw)-1)) ;
hfmsPC_mv(f,h,"mean") = sum(draw, hfmsPC(f,h,draw)) / card(draw) ;
hfmsPC_mv(f,h,"stdev") = sqrt(sum(draw, sqr(hfmsPC(f,h,draw) - hfmsPC_mv(f,h,"mean")))/(card(draw)-1)) ;
vfmsPC_mv(f,v,"mean") = sum(draw, vfmsPC(f,v,draw)) / card(draw) ;
vfmsPC_mv(f,v,"stdev") = sqrt(sum(draw, sqr(vfmsPC(f,v,draw) - vfmsPC_mv(f,v,"mean")))/(card(draw)-1)) ;
zfmsPC_mv(f,"mean") = sum(draw, zfmsPC(f,draw)) / card(draw) ;
zfmsPC_mv(f,"stdev") = sqrt(sum(draw, sqr(zfmsPC(f,draw) - zfmsPC_mv(f,"mean")))/(card(draw)-1)) ;


display pvPC_mv, pzPC_mv, phPC_mv, pvaPC_mv, qvaPC_mv, qpPC_mv, fdPC_mv, idPC_mv, rPC_mv, wvPC_mv, wzPC_mv, vashPC_mv, fixfacPC_mv,
        exincPC_mv, endowPC_mv, qcPC_mv, alphaPC_mv, yPC_mv,  cpiPC_mv, criPC_mv, ryPC_mv, trinPC_mv, troutPC_mv, trinshPC_mv,
        troutshPC_mv, hfdPC_mv, vfdPC_mv, zfdPC_mv, hmsPC_mv, vmsPC_mv, zmsPC_mv, hfmsPC_mv, vfmsPC_mv, zfmsPC_mv
       ,acobbPC_mv, shcobbPC_mv;


* Multiplier parameters:
parameter ymult_all_mv(mv)         nominal income multiplier for all
          rymult_all_mv(mv)        nominal income multiplier for all
          ytotmult_h_mv(h,mv)      nominal income multiplier by treatment household
          rytotmult_h_mv(h,mv)      nominal income multiplier by treatment household
          ttprodmult_mv(mv)        production multiplier for ttqp
          hprodmult_mv(h,mv)       production mutiplier for hqp
          prodmult_all_mv(g,mv)    production multiplier for all

;
ymult_all_mv("mean") = sum(draw, ymult_all(draw)) / card(draw) ;
ymult_all_mv("stdev") = sqrt(sum(draw, sqr(ymult_all(draw) - ymult_all_mv("mean")))/(card(draw)-1)) ;
rymult_all_mv("mean") = sum(draw, rymult_all(draw)) / card(draw) ;
rymult_all_mv("stdev") = sqrt(sum(draw, sqr(rymult_all(draw) - rymult_all_mv("mean")))/(card(draw)-1)) ;
ytotmult_h_mv(h,"mean") = sum(draw, ytotmult_h(h,draw)) / card(draw) ;
ytotmult_h_mv(h,"stdev") = sqrt(sum(draw, sqr(ytotmult_h(h,draw) - ytotmult_h_mv(h,"mean")))/(card(draw)-1)) ;
rytotmult_h_mv(h,"mean") = sum(draw, rytotmult_h(h,draw)) / card(draw) ;
rytotmult_h_mv(h,"stdev") = sqrt(sum(draw, sqr(rytotmult_h(h,draw) - rytotmult_h_mv(h,"mean")))/(card(draw)-1)) ;
prodmult_all_mv(g,"mean") = sum(draw, prodmult_all(g,draw)) / card(draw) ;
prodmult_all_mv(g,"stdev") = sqrt(sum(draw, sqr(prodmult_all(g,draw) - prodmult_all_mv(g,"mean")))/(card(draw)-1)) ;
ttprodmult_mv("mean") = sum(draw, ttprodmult(draw)) / card(draw) ;
ttprodmult_mv("stdev") = sqrt(sum(draw, sqr(ttprodmult(draw) - ttprodmult_mv("mean")))/(card(draw)-1)) ;
hprodmult_mv(h,"mean") = sum(draw, hprodmult(h,draw)) / card(draw) ;
hprodmult_mv(h,"stdev") = sqrt(sum(draw, sqr(hprodmult(h,draw) - hprodmult_mv(h,"mean")))/(card(draw)-1)) ;


display ymult_all_mv, cpiPC_mv, rymult_all_mv, rytotmult_h_mv, ytotmult_h_mv,
     ttprodmult_mv, hprodmult_mv, prodmult_all_mv ;



* Figure out the lower and higher confidence bounds:
set lh(mv) /pct5, pct95 /
parameter Torank(draw)
          Ranks(draw)
* add percentiles to "ci" if you want to know more percentile values,
* for instance adding ", med 50" will compute 50th percentile and call it "med"
* (note: in that example you must also add "med" to the mv and lh sets)
          ci(lh) confidence interval definition /pct5 5, pct95 95/
          ci2(lh) confidence intervals (values) ;

* this initialises the use of the "rank" procedure
$libinclude rank

* ymult_all is already 1-dimentional, so no need to loop here
ci2(lh) = ci(lh);
$libinclude rank ymult_all draw Ranks ci2
ymult_all_mv(lh) = ci2(lh) ;
display ymult_all_mv ;

* REAL ymult_all
ci2(lh) = ci(lh);
$libinclude rank rymult_all draw Ranks ci2
rymult_all_mv(lh) = ci2(lh) ;
display rymult_all_mv ;

* CPI
loop(h,
     Torank(draw) = cpiPC(h,draw) ;
     ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
     display Torank, Ranks, ci ;
     cpiPC_mv(h,lh) = ci2(lh) ;
);
display cpiPC_mv;

loop(h,
     Torank(draw) = ytotmult_h(h,draw) ;
     ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
     ytotmult_h_mv(h,lh) = ci2(lh) ;
);
display ytotmult_h_mv;
loop(h,
     Torank(draw) = rytotmult_h(h,draw) ;
     ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
     rytotmult_h_mv(h,lh) = ci2(lh) ;
);
display rytotmult_h_mv;

loop(g,
     Torank(draw) = prodmult_all(g,draw) ;
     ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
     prodmult_all_mv(g,lh) = ci2(lh) ;
);
display prodmult_all_mv;

loop(h,
     Torank(draw) = hprodmult(h,draw) ;
     ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
     hprodmult_mv(h,lh) = ci2(lh) ;
);
display hprodmult_mv;

Torank(draw) = ttprodmult(draw) ;
ci2(lh) = ci(lh);
$libinclude rank Torank draw Ranks ci2
ttprodmult_mv(lh) = ci2(lh) ;
display ttprodmult_mv ;



* -------------------------------------------------------------------------------------------
* ------------ OUTPUT CONTROL WITH A PUT STATEMENT ------------------------------------------
* -------------------------------------------------------------------------------------------
* (This is useful to automate certain kinds of output and avoid repetitive excel manipulations
* It makes a text file (tablput.txt) which can be relatively easily cut and pasted into excel.
* Tweak it for your preferred purpose and chosen output table format.

* Use put statement to make a nice text file which can be cut+pasted into excel
file tablput_pro /Ch14_table14pt3.txt/;
put tablput_pro ;

put 'Assumptions' @33 ';' /;

put 'Elasticity of  lab supply'   @40'; ' %lse%:<6 /;
put 'Purchased inputs fixed (1) or free (0)'  @40'; '  %budgetconstraint%:<2:0 /;
scalar leak ;
leak = transfer("p")/1000000;
put 'Leakage (bil. pesos)' /; put 'P'  @40'; '  leak:<6:2 /;
put 'iterations'  @40'; ' card(draw):< /;
put //;

put 'INCOME MULTIPLIERS' /;
put 'A.Total income multiplier' /;
     put 'Nominal  ' @40';'  ymult_all_mv("mean"):6:2 @55';' '(' ymult_all_mv("pct5"):6:2 ',' ymult_all_mv("pct95"):6:2 ')' /;

     put '   Real  '  @40';' rymult_all_mv("mean"):6:2 @55';' '(' rymult_all_mv("pct5"):6:2 ',' rymult_all_mv("pct95"):6:2 ')' ;
put //;

put "B. By households" /;
loop(h,
     put @5 h.tl @18'Nominal';
     put  @40';' ytotmult_h_mv(h,"mean"):6:2 @55';' '(' ytotmult_h_mv(h,"pct5"):5:2 ',' ytotmult_h_mv(h,"pct95"):5:2 ')' /;
     put  @10 'cpi increase in %'  @40';' cpiPC_mv(h,"mean"):6:2 '%':<1 @55';' '(' cpiPC_mv(h,"pct5"):5:2 '%,' cpiPC_mv(h,"pct95"):5:2 '%)' /;
     put  @22 'real' @40';' rytotmult_h_mv(h,"mean"):5:2 @55';' '(' rytotmult_h_mv(h,"pct5"):5:2 ',' rytotmult_h_mv(h,"pct95"):5:2 ')' //;
);
put // ;


put 'PRODUCTION MULTIPLIERS (per dollar of transfer)' //;
put 'A. Total' @40';' ttprodmult_mv("mean"):<6.2 @55 ';' '(' ttprodmult_mv("pct5"):6:2 ',' ttprodmult_mv("pct95"):6.2  ')'/ ;
put //;
put "B. By Household" /;
loop(h,
     put h.tl ;
     put  @40';' hprodmult_mv(h,"mean"):<6.2 @55 ';' '(' hprodmult_mv(h,"pct5"):6:2 ',' hprodmult_mv(h,"pct95"):6:2 ')'/ ;
);
put // ;
put "C. By Activity" /;
loop(g$(not sameas(g,"outside")),
     put g.tl ;
     put  @40';' prodmult_all_mv(g,"mean"):<6.2 @55 ';' '(' prodmult_all_mv(g,"pct5"):6:2 ',' prodmult_all_mv(g,"pct95"):6:2 ')'/ ;
);
put / ;








