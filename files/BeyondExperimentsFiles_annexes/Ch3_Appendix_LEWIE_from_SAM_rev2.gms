$title Mini GE-LEWIE model
* This program creates the LEWIE Results of chapter 3, table 6
* Go to line 78 to see how each column of the table is obtained.

Option limrow=10, limcol=50
OPTION DECIMALS=2 ;


* name all the set elements that will be used (all those in the SAM, and a few more)
set i all accounts in the economy
/A_AG1      Agriculture
  A_NAG1   Non-Agricultural Activities
  C_AG1      Agriculture
  C_NAG1   Non-Agricultural Activities
  LABO1    Labor
  CAPI1    Capital
  INC1     Income
  A_AG2      Agriculture
  A_NAG2   Non-Agricultural Activities
  C_AG2      Agriculture
  C_NAG2   Non-Agricultural Activities
  LABO2    Labor
  CAPI2    Capital
  INC2     Income
  AGC     ag commodity market
  NONAGC    non-ag commodity market
  LABOM   labor factor market
  ROW     Rest of the World
  TOT      Column total

* And the accounts not in the sam:
ag, nonag, poor, nonpoor, labo, capi , exog, purch

/

* Define your elasticity
* (100 for all columns of Table 3.6, can be changed to produce alternative scenarios)
$setlocal supel 100

* Read the SAM:
alias (i,j);
parameter sam(i,j) the sam read from excel
* The "call gdxxrw" command reads the excel sheet in the range "LEWIE_FromSAM!A1:S19"
* and makes a gdx file out of it
$call "gdxxrw input=Ch3_LEWIE_Inputs.xlsx output=Ch3_data_fromSAM.gdx par=sam rng=LEWIE_FromSAM!A1:S19"
* We then load the gdx file and read the "sam" parameter
$gdxin Ch3_data_fromSAM.gdx
$load sam
$gdxin
display sam ;
* We compute the row and column totals, which come in handy in calculations
sam("TOT",i) = sum(j,sam(j,i));
sam(i, "TOT") = sum(j,sam(i,j));
display sam ;

* We define subsets of the generic "i" (all accounts), to define some as goods, some as factors, etc.
* And we make subsets of those subsets, to define some as tradable, some as non-tradable, etc.
* "null" is a name we give to the "phantom" element = to put in empty sets (which GAMS does not like)
* The "null" element does nothing in terms of the model
$phantom null
* calibrating off of the SAM:
sets g(i)      goods /ag, nonag, exog /
     f(i)      factors /labo, capi, purch/
     h(i)      households /poor, nonpoor/

* subsets
     gp(g)     produced goods /ag, nonag/
     gnt(g)    non-tradable goods /null, ag /
     gt(g)     tradable goods / exog,  nonag/
     fx(f)     fixed factors /capi/
     ft(f)     tradable factors /labo, purch/
     ftv(ft)    factors tradable in the village /null, labo/
     ftw(ft)    factors with the world /purch/
;
alias (g,gg);
alias (f,ff) ;

* For simulations: changing the contents of the subsets changes the assumptions
* about what is tradable and what isn't.
* These are the choices we make for each of hte columns in Table 3.6:
* Column A:  gnt:/null/  gt:/exog, ag, nonag/  ftv:/null/ ftw:/labo, purch/
* Column B:  gnt:/ag/   gt:/exog, nonag/     ftv:/null/ ftw:/labo,purch/
* Column C:  gnt:/ag/  gt:/exog, nonag/     ftv:/labo/ ftw:/purch/
* Column D:  gnt:/ag, nonag/  gt:/exog/    ftv:/labo/ ftw:/purch/
* Column E:  gnt:/ag, nonag/  gt:/exog/  ftv:/labo/ ftw:/purch/
* [for column E you also need to change the simulation by exogenously adding caputal
* ,around line 550 of the code]


PARAMETERS
* Production
     pbeta(g,f,h)   Factor share of f in production of g by h
     pshift(g,h)    Shift parameter in production of g by h
     idsh(g,gg,h)   share of intermediate demand for gg to produce g
     vash(g,h)      share of value added
* Consumption
     calpha(g,h)    Expenditure share consumption of g by h

* Market assumptions
     se(f)          Supply elasticity of factor f in the economy
* endowments
     yexog(h)       exogenous income
     hfsupel(f,h)   factor supply elasticity for each household
     fixfac(g,f,h)  fixed factor demand
;

* Parameters with a "0" suffix indicate base values, before running the model
* Those values should be reproduced by the model without any shock
* (if not, then we have an unbalanced calibration)
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

* Market clearing
     hms0(g,h)  Marketed surplus of g in the household-economy
     vms0(g)    Marketed surplus of g in the village economy
     hfms0(f,h)  Marketed surplus of f in the household-economy
     vfms0(f)    Marketed surplus of f in the village economy
;


* We use the SAM to calibrate all the variables:
*------------------------------------------------

* First we map the names of sam accounts to names of model accounts
* (for example "a_ag1" is the ag activity of household 1 in the matrix,
*      so we map it to the "ag" commodity account and the "poor" household account)
set
mapgg(i,g) maps SAM activities to the goods they produce in the model/
     (a_ag1,a_ag2).ag
     (a_nag1,a_nag2).nonag/
mapcg(i,g) maps hh-specific commodity accounts to model goods /
     (c_ag1,c_ag2).ag
     (c_nag1,c_nag2).nonag/
mapmg(i,g) maps SAM market account to model goods /agc.ag, nonagc.nonag/
mapff(i,f) maps SAM factor names to model factor name/
     (labo1,labo2,labom).labo
     (capi1,capi2).capi/
mapgh(i,h) maps activities to the household that performs them/
     (A_AG1,A_NAG1).poor
     (A_AG2,A_NAG2).nonpoor/
mapfh(i,h) maps factors to the household that owns them/
     (LABO1,CAPI1).poor
     (LABO2,CAPI2).nonpoor/
maphh(i,h) maps SAM household names to model household names /inc1.poor, inc2.nonpoor/
;


* Read total production from the SAM:
* (this line says: "the quantity of g produced by h is the amount in the "TOT" row
*        of the SAM and column "i" such that "i" is mapped to good g and household h)
qp0(g,h) = sum(i$(mapgg(i,g)*mapgh(i,h)),sam("TOT",i)) ;
* The following lines have a similar interpretation,
* they rely on name mappings to point to specific cells of the SAM.

* Read the factors off the act rows and the market rows:
fd0(g,f,h) = sum((i,j)$(mapff(i,f)*mapgg(j,g)*mapgh(j,h)),sam(i,j));
* Purchased inputs are read off the ROW row:
fd0(g,"purch",h) = sum(i$(mapgg(i,g)*mapgh(i,h)),sam("ROW",i));
* Intermediate inputs off the activity rows:
id0(gg,g,h) = sum((i,j)$(mapcg(i,g)*mapgg(j,gg)*mapgh(j,h)),sam(i,j)) ;
* Household income is read in the Totals row
y0(h) = sum(i$maphh(i,h),sam("TOT",i)) ;
* Factor supply of tradable factors:
hfsup0(ft,h) = sum((i,j)$(mapff(i,ft)*maphh(j,h)), sam(j,i)) ;
* Consumption
qc0(g,h) = sum((i,j)$(mapmg(i,g)*maphh(j,h)), sam(i,j)) ;
qc0("exog",h) = sum(j$maphh(j,h), sam("ROW",j)) ;
display qp0, fd0, id0, y0, hfsup0, qc0 ;

* Then we compute market surpluses at all market levels:
* Goods markets (commodity accounts need to be integrated with market accounts):
hms0(g,h) = qp0(g,h)-qc0(g,h)-sum(gg,id0(gg,g,h)) ;
vms0(g) = sum(h,hms0(g,h)) ;
qva0(g,h) = sum(f,fd0(g,f,h));
* Factor markets:
hfd0(f,h) = sum(g,fd0(g,f,h));
hfms0(ft,h) = hfsup0(ft,h) - hfd0(ft,h) ;
vfms0(f) = sum(h,hfms0(f,h));

* Prices, wages, and rents all initialized to 1
p0(g)=1;
w0(ft)=1 ;
r0(g,fx,h)$fd0(g,fx,h) = 1;

* We initialise model parameters:
* Itermediate input shares (idsh), value added shares (vash), factor shares in production (pbeta)
* production shift parameter (pshift), consumption expenditure shares (calpha), fixed factor supplies (fixfac)
idsh(g,gg,h)$id0(g,gg,h) = id0(g,gg,h) / qp0(g,h) ;
vash(g,h) = 1- sum(gg,idsh(g,gg,h)) ;
pbeta(g,f,h)$fd0(g,f,h) = fd0(g,f,h) / sum(ff,fd0(g,ff,h)) ;
pshift(g,h)$qp0(g,h) = qva0(g,h)/(prod(ff,fd0(g,ff,h)**pbeta(g,ff,h))) ;
calpha(g,h) = qc0(g,h)*p0(g)/ y0(h) ;
fixfac(g,fx,h) = fd0(g,fx,h) ;
* exogenous incomes are zero in the base, we will use this parameter to simulate transfers later
yexog(h)=0;
* supply elasticity is set by the local supel (see line 37 of the code)
hfsupel(ft,h) = %supel% ;


* A few additional initial values (computed from model parameters)
* CPI, real income, and price value added (unit price net of the value of intermediate inputs)
cpi0(h) = sum(g,p0(g)*calpha(g,h));
ry0(h)  = y0(h) / cpi0(h);
pva0(g,h) = 1-sum(gg,idsh(g,gg,h)) ;


display qp0, qva0, id0, p0, pva0, r0, w0, fd0,
        hfd0, y0, cpi0, ry0, qc0, hms0, hfms0, vms0, vfms0;
display pbeta, pshift, idsh, vash, calpha, yexog ;



* We define four sets of parameters, recognizable by their suffixes:
* before simulation (1), after simulation (2), difference ("D"), and percent difference ("PC")
parameters
* Base model solution (without shock) suffixed with "1"
     p1(g)      Price of g on the village markets
     pva1(g,h)  Price value added for each household
     r1(g,f,h)  Rent for inputs fixed in production of g by h
     w1(f)      Wage for tradable inputs (common for the village)
     qp1(g,h)    Quantity of g produced by h
     id1(g,gg,h) Intermediate demand for g in prodution of gg by h
     fd1(g,f,h)  Factor demand for f in production of g by h
     hfd1(f,h) Household total use of factors
     y1(h)      Nominal Income of household h
     cpi1(h)    Consumer price index for household h
     ry1(h)     Real income of household h
     qc1(g,h)   Quantity of g consumed by h
     hms1(g,h)  Marketed surplus of g in the household-economy
     vms1(g)    Marketed surplus of g in the village economy
     hfms1(f,h)  Marketed surplus of f in the household-economy
     vfms1(f)    Marketed surplus of f in the village economy
     hfsup1(f,h) Tradable factor supply
     ly1(f,h)    Labor income
     fxy1(f,h)    capital income
     fixfac1(g,f,h) fixed factor
     yexog1(h)      exogenous income

* Simulation model solution (after shock) suffixed with "2"
     p2(g)      Price of g on the village markets
     pva2(g,h)  Price value added for each household
     r2(g,f,h)  Rent for inputs fixed in production of g by h
     w2(f)      Wage for tradable inputs (common for the village)
     qp2(g,h)    Quantity of g produced by h
     id2(g,gg,h) Intermediate demand for g in prodution of gg by h
     fd2(g,f,h)  Factor demand for f in production of g by h
     hfd2(f,h) Household total use of factors
     y2(h)      Nominal Income of household h
     cpi2(h)    Consumer price index for household h
     ry2(h)     Real income of household h
     qc2(g,h)   Quantity of g consumed by h
     hms2(g,h)  Marketed surplus of g in the household-economy
     vms2(g)    Marketed surplus of g in the village economy
     hfms2(f,h)  Marketed surplus of f in the household-economy
     vfms2(f)    Marketed surplus of f in the village economy
     hfsup2(f,h) Tradable factor supply
     ly2(f,h)    Labor income
     fxy2(f,h)    capital income
     fixfac2(g,f,h) fixed factor
     yexog2(h)      exogenous income

* Difference between pre and post simulation suffixed with "D"
     pD(g)      Price of g on the village markets
     pvaD(g,h)  Price value added for each household
     rD(g,f,h)  Rent for inputs fixed in production of g by h
     wD(f)      Wage for tradable inputs (common for the village)
     qpD(g,h)    Quantity of g produced by h
     idD(g,gg,h) Intermediate demand for g in prodution of gg by h
     fdD(g,f,h)  Factor demand for f in production of g by h
     hfdD(f,h) Household total use of factors
     yD(h)      Nominal Income of household h
     cpiD(h)    Consumer price index for household h
     ryD(h)     Real income of household h
     qcD(g,h)   Quantity of g consumed by h
     hmsD(g,h)  Marketed surplus of g in the household-economy
     vmsD(g)    Marketed surplus of g in the village economy
     hfmsD(f,h)  Marketed surplus of f in the household-economy
     vfmsD(f)    Marketed surplus of f in the village economy
     lyD(f,h)    Labor income
     fxyD(f,h)    capital income
     fixfacD(g,f,h) fixed factor
     yexogD(h)      exogenous income

* Percent Change from base suffixed with "PC"
     pPC(g)      Price of g on the village markets
     pvaPC(g,h)  Price value added for each household
     rPC(g,f,h)  Rent for inputs fixed in production of g by h
     wPC(f)      Wage for tradable inputs (common for the village)
     qpPC(g,h)    Quantity of g produced by h
     idPC(g,gg,h) Intermediate demand for g in prodution of gg by h
     fdPC(g,f,h)  Factor demand for f in production of g by h
     hfdPC(f,h) Household total use of factors
     yPC(h)      Nominal Income of household h
     cpiPC(h)    Consumer price index for household h
     ryPC(h)     Real income of household h
     qcPC(g,h)   Quantity of g consumed by h
     hmsPC(g,h)  Marketed surplus of g in the household-economy
     vmsPC(g)    Marketed surplus of g in the village economy
     hfmsPC(f,h)  Marketed surplus of f in the household-economy
     vfmsPC(f)    Marketed surplus of f in the village economy
     lyPC(f,h)     Labor income
     fxyPC(f,h)    capital income
     fixfacPC(g,f,h) fixed factor
     yexogPC(h)      exogenous income
;


* MODEL STARTS HERE:
* --------------------

VARIABLES
* Prices/values
     P(g)      Price of g on the village markets
     PVA(g,h)  Price value added
     R(g,f,h)  Rent for inputs fixed in production of g by h
     W(f)      Wage for tradable inputs (common for the village)
* Production
     QP(g,h)    Quantity of g produced by h
     QVA(g,h)   Quantity of value added created
     ID(g,gg,h) Intermediate demand for g in prodution of gg by h
     FD(g,f,h)  Factor demand for f in production of g by h
     HFD(f,h)   Household total use of factors
     HFSUP(f,h) Household factor supply

* Income and consumption
     Y(h)      Nominal Income of household h
     CPI(h)    Consumer price index for household h
     RY(h)     Real income of household h
     QC(g,h)   Quantity of g consumed by h

* Market clearing
     HMS(g,h)   Marketed surplus of g in the household-economy
     VMS(g)     Marketed surplus of g in the village economy
     HFMS(f,h)  Marketed surplus of f in the household-economy
     VFMS(f)    Marketed surplus of f in the village economy
;


* Set initial values to the "0" calibration values
QP.l(g,h) =  qp0(g,h)  ;
ID.l(g,gg,h)=  id0(g,gg,h);
FD.l(g,f,h)= fd0(g,f,h)  ;
QVA.l(g,h) =  qva0(g,h)  ;
HFD.l(f,h)=  hfd0(f,h)   ;
Y.l(h)=     y0(h)        ;
QC.l(g,h)=  qc0(g,h)     ;
HMS.l(g,h)= hms0(g,h)    ;
HFMS.l(f,h)= hfms0(f,h)  ;
VMS.l(g) =vms0(g) ;
VFMS.l(f) =vfms0(f);
P.l(g) = p0(g) ;
PVA.l(g,h) = pva0(g,h) ;
R.l(g,f,h) = r0(g,f,h);
W.l(f)   = w0(f) ;
CPI.l(h) = cpi0(h) ;
HFSUP.l(f,h) = hfsup0(f,h) ;

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
     EQ_VMS(g)      Defines marketed surplus for the economy
     EQ_FIXMS(g)    Clears market for non-tradable goods

     EQ_HFMS(f,h)   Defines household factore marted surplus
     EQ_VFMS(f)     Defines factor marketed surplus in the village
     EQ_FIXF(g,f,h) Fixed factor constraint
     EQ_FIXVF(ftv)  Factors tradable in the village only
     EQ_HFSUP(f,h)  Tradable factor supply elasticity

* Useful output
* (those are definitional equations, not essential to the model itself):
     EQ_CPI(h)      Defines cpi
     EQ_RY(h)       Defines hh income in real terms

;


* Prices at the household level
     EQ_PVA(g,h)..
          PVA(g,h) =E= P(g)- sum(gg,idsh(g,gg,h)*P(gg)) ;

* Production block
*----------------------
* Cobb Douglas output:
     EQ_QP(g,h)..
          QP(g,h)*vash(g,h) =E= pshift(g,h)*prod(f,FD(g,f,h)**pbeta(g,f,h)) ;
* Factor demands (resulting of a standard profimax)
* (value is rent or wage, depending whether it is a tradable factor or not)
     EQ_FD(g,f,h)$fd0(g,f,h)..
          FD(g,f,h)*[R(g,f,h)$fx(f) + W(f)$ft(f)]
                     =E= QP(g,h)*PVA(g,h)*pbeta(g,f,h) ;
* Intermediate input demand (Leontieff):
     EQ_ID(g,gg,h)..
          ID(g,gg,h) =E= QP(g,h)*idsh(g,gg,h) ;


* Income and consumption
*-------------------------
* Income is the value of all factor endowments + exogenous incomes
* factor values are evaluated at rent if fixed, at wage if tradable
     EQ_Y(h)..
          Y(h) =E=    sum((fx,gp), R(gp,fx,h)*FD(gp,fx,h))
                    + sum(ft$hfsup0(ft,h), W(ft)*hfsup(ft,h))
                    + yexog(h) ;

* Consumption expenditure demand (result from solving a standard utility maximization problem)
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
*-------------------
     EQ_CPI(h)..
          CPI(h) =e= sum(g,P(g)*calpha(g,h));

     EQ_RY(h)..
          RY(h) =e= Y(h) / CPI(h);

* Model defined in MCP form. Each equation is paired with its complementary slack variable.
MODEL miniLEWIE /
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


* Fix prices for tradable goods and factors:
P.fx(gt) = p0(gt);
W.fx(ftw) = w0(ftw);
* Prevent the production/supply of exogenous goods/factors:
QP.fx("exog",h) = 0;
HFSUP.fx(ftw,h) = hfsup0(ftw,h);

* initialize rents and wages (to 1)
R.l(g,f,h)=r0(g,f,h) ;
W.l(f) = w0(f) ;
display P.l, PVA.l, R.l, W.l, QP.l, FD.l, ID.l, Y.l, QC.l, HMS.l, VMS.l, VFMS.l, HFSUP.l, HFD.l, HFMS.l ;


* set iteration limit to 1 to check calibration, and increase it back to 10000 after check is done
*(if the calibration is done properly, it should be a solution to the model, no iterations needed)
option iterlim = 1;
Solve miniLEWIE using mcp ;
option iterlim = 10000;
* Aborts if model doesn't solve well
ABORT$(miniLEWIE.modelstat ne 1) "NOT WELL CALIBRATED IN THIS DRAW - CHECK THE DATA INPUTS" ;
display P.l, PVA.l, R.l, W.l, QP.l, FD.l, ID.l, Y.l, QC.l, HMS.l, VMS.l, VFMS.l, HFSUP.l, HFD.l, HFMS.l ;
* Aborts if matrix not reproduced
loop((g,h),
ABORT$(QP.l(g,h) ne qp0(g,h)) "QP NOT WELL CALIBRATED - CHECK THE DATA INPUTS" ;
ABORT$(QC.l(g,h) ne qc0(g,h)) "QC NOT WELL CALIBRATED - CHECK THE DATA INPUTS" ;
);


* Base Parameters defined after the first run (no-shock)
* (these should all be obtained after 1 iteration only,
* and should not differ from the "0" parameters)
p1(g)      = P.l(g) ;
pva1(g,h)  = PVA.l(g,h);
r1(g,f,h)  = R.l(g,f,h);
w1(f)      = W.l(f) ;
qp1(g,h)   = QP.l(g,h) ;
id1(g,gg,h) = ID.l(g,gg,h) ;
fd1(g,f,h)  = FD.l(g,f,h) ;
hfd1(f,h)  = HFD.l(f,h) ;
y1(h)      = Y.l(h) ;
cpi1(h)    = CPI.l(h);
ry1(h)     = RY.l(h) ;
qc1(g,h)   = QC.l(g,h) ;
hms1(g,h)  = HMS.l(g,h) ;
vms1(g)    = VMS.l(g) ;
hfms1(f,h) = HFMS.l(f,h) ;
vfms1(f)   = VFMS.l(f) ;
hfsup1(f,h) = HFSUP.l(f,h) ;
fixfac1(g,fx,h) = fixfac(g,fx,h) ;
yexog1(h) = yexog(h);



* ************************************
* SHOCK(s)
* ************************************
* This increases exogenous income of the poor by 1 dollar:
yexog("poor") = 1 ;

* In addition, to make the simulation of column E (with market assumptions as defined at line 84 of code)
* , you need to increase capital by the exact amount that leaves rent inflation at zero
* Unstar the following four lines to simulate the appropriate increase in capital
*fixfac("ag","capi","poor") = fixfac("ag","capi","poor")*1.0053 ;
*fixfac("ag","capi","nonpoor") = fixfac("ag","capi","nonpoor")*1.0053 ;
*fixfac("nonag","capi","poor") = fixfac("nonag","capi","poor")*1.0016 ;
*fixfac("nonag","capi","nonpoor") = fixfac("nonag","capi","nonpoor")*1.0016 ;
* Note: the values 1.0053 and 1.0016 were found by trial and error.  They incease
* capital just enough to keep rent at initial levels.



* This is the SOLVE statement for the simulation
* ------------------------------------------------
Solve miniLEWIE using mcp ;
display P.l, PVA.l, R.l, W.l, QP.l, FD.l, ID.l, Y.l, QC.l, HMS.l, VMS.l, VFMS.l, HFSUP.l, HFD.l, HFMS.l ;
display p1, pva1, r1, w1, qp1, id1, fd1, hfd1, y1, qc1, hms1, vms1, hfms1, vfms1 ;

* Record values after simulation ("2" suffix)
p2(g)      = P.l(g) ;
pva2(g,h)  = PVA.l(g,h);
r2(g,f,h)  = R.l(g,f,h);
w2(f)      = W.l(f) ;
qp2(g,h)   = QP.l(g,h) ;
id2(g,gg,h) = ID.l(g,gg,h) ;
fd2(g,f,h)  = FD.l(g,f,h) ;
hfd2(f,h)  = HFD.l(f,h) ;
y2(h)      = Y.l(h) ;
cpi2(h)    = CPI.l(h);
ry2(h)     = RY.l(h) ;
qc2(g,h)   = QC.l(g,h) ;
hms2(g,h)  = HMS.l(g,h) ;
vms2(g)    = VMS.l(g) ;
hfms2(f,h) = HFMS.l(f,h) ;
vfms2(f)   = VFMS.l(f) ;
hfsup2(f,h) = HFSUP.l(f,h) ;
fixfac2(g,fx,h) = fixfac(g,fx,h) ;
yexog2(h) = yexog(h);

* Record differences from base
pD(g)     = p2(g) - p1(g) ;
pvaD(g,h) = pva2(g,h) - pva1(g,h) ;
rD(g,f,h) = r2(g,f,h) - r1(g,f,h) ;
wD(f)     = w2(f) - w1(f) ;
qpD(g,h)  = qp2(g,h) - qp1(g,h) ;
idD(g,gg,h) = id2(g,gg,h) - id1(g,gg,h) ;
fdD(g,f,h) = fd2(g,f,h) - fd1(g,f,h) ;
hfdD(f,h) = hfd2(f,h) - hfd1(f,h) ;
yD(h)     = y2(h) - y1(h) ;
cpiD(h)   = cpi2(h) - cpi1(h) ;
ryD(h)    = ry2(h) - ry1(h) ;
qcD(g,h)  = qc2(g,h) - qc1(g,h) ;
hmsD(g,h) = hms2(g,h) - hms1(g,h) ;
vmsD(g)   = vms2(g) - vms1(g) ;
hfmsD(f,h) = hfms2(f,h) - hfms1(f,h) ;
vfmsD(f)  = vfms2(f) - vfms1(f) ;
fixfacD(g,fx,h) = fixfac2(g,fx,h) - fixfac1(g,fx,h);
yexogD(h) = yexog2(h) - yexog1(h);

* Record Percent difference from base
pPC(g)$p1(g) = 100*pD(g) / p1(g) ;
pvaPC(g,h)$pva1(g,h) = 100*pvaD(g,h) / pva1(g,h) ;
rPC(g,f,h)$r1(g,f,h) = 100*rD(g,f,h) / r1(g,f,h) ;
wPC(f)$w1(f) = 100*wD(f) / w1(f) ;
qpPC(g,h)$qp1(g,h) = 100*qpD(g,h) / qp1(g,h) ;
idPC(g,gg,h)$id1(g,gg,h) = 100*idD(g,gg,h) / id1(g,gg,h) ;
fdPC(g,f,h)$fd1(g,f,h) = 100*fdD(g,f,h) / fd1(g,f,h) ;
hfdPC(f,h)$hfd1(f,h) = 100*hfdD(f,h) / hfd1(f,h) ;
yPC(h)$y1(h) = 100*yD(h) / y1(h) ;
cpiPC(h)   = cpiD(h)/cpi1(h) ;
ryPC(h)    = ryD(h)/ry1(h) ;
qcPC(g,h)$qc1(g,h) =100* qcD(g,h) / qc1(g,h) ;
hmsPC(g,h)$hms1(g,h) = 100*hmsD(g,h) / hms1(g,h) ;
vmsPC(g)$vms1(g) = 100*vmsD(g) / vms1(g) ;
hfmsPC(f,h)$hfms1(f,h) = 100*hfmsD(f,h) / hfms1(f,h) ;
vfmsPC(f)$vfms1(f) = 100*vfmsD(f) / vfms1(f) ;
fixfacPC(g,fx,h)$fixfac1(g,fx,h) = fixfacD(g,fx,h) / fixfac1(g,fx,h);
yexogPC(h)$yexog1(h) = yexogD(h) / yexog1(h);

display p2, pva2, r2, w2, qp2, id2, fd2, hfd2, y2, ry2, cpi2, qc2, hms2, vms2, hfms2, vfms2 ;

display pD, pvaD, rD, wD, qpD, idD, fdD, hfdD, yD, ryD, cpiD, qcD, hmsD, vmsD, hfmsD, vfmsD ;

display pPC, pvaPC, rPC, wPC, qpPC, idPC, fdPC, hfdPC, yPC, ryPC, cpiPC, qcPC, hmsPC, vmsPC, hfmsPC, vfmsPC ;


* Compute a few parameters for the table:
* factor incomes:
fxy1(fx,h)= sum(gp, r1(gp,fx,h)*fd1(gp,fx,h)) ;
ly1(ft,h)= w1(ft)*hfsup1(ft,h);
fxy2(fx,h)= sum(gp, r2(gp,fx,h)*fd2(gp,fx,h)) ;
ly2(ft,h)= w2(ft)*hfsup2(ft,h);
fxyD(fx,h)=  fxy2(fx,h)-fxy1(fx,h);
lyD(ft,h)= ly2(ft,h)-ly1(ft,h);
fxyPC(fx,h)=  100*fxyD(fx,h)/fxy1(fx,h);
lyPC(ft,h)$ly1(ft,h)= 100*lyD(ft,h)/ly1(ft,h);

display fxy1, ly1, fxy2,ly2, fxyD, lyD, fxyPC, lyPC;



* Now we make some aggregate parameters to present in the tables
* such as total increase in output, total increase in labor supply, etc.
parameter tsup1(g)  initial total supply of g
          tlsup1(f) initial total tradable factor supply in the economy
          tsup2(g)  final total supply of g
          tlsup2(f) final total tradable factor supply in the economy
          tsupD(g)  delta total supply of g
          tlsupD(f) delta initial total trade with rest of world
;

* total supply is total production/endowment + imports (if any)
tsup1(g) = sum(h,qp1(g,h)) - min(0,vms1(g)) ;
tlsup1(ft) = sum(h,hfsup1(ft,h)) - min(0,vfms1(ft)) ;
* same after the shock:
tsup2(g) = sum(h,qp2(g,h)) - min(0,vms2(g)) ;
tlsup2(ft) = sum(h,hfsup2(ft,h)) - min(0,vfms2(ft)) ;
* And the diffs:
tsupD(g) = tsup2(g)-tsup1(g) ;
tlsupD(ft) = tlsup2(ft)-tlsup1(ft) ;
display tsup1, tsup2, tsupD, tlsup1, tlsup2, tlsupD;


* If we want to reproduce the SAM multiplier results we need to compute those a bit differently
* because the SAM model assumes Intermediate Demand never reaches markets
parameter tsupsam1(g) total supply like in the SAM multiplier
          tlsupsam1(f) labor supply outside the hh + purchased on market
          rowsupsam1 total trade with rest of world
          tsupsam2(g)
          tlsupsam2(f)
          rowsupsam2 total trade with rest of world
          tsupsamD(g)
          tlsupsamD(f)
          rowsupsamD total trade with rest of world  ;

* total supply is quantity produced net of intermediate inputs, plus imports:
tsupsam1(g) = sum(h,qp1(g,h) - sum(gg,id1(gg,g,h)) )- min(0,vms1(g)) ;
tlsupsam1(ft) = sum(h,max(0,hfms1(ft,h))) - min(0,vfms1(ft)) ;
rowsupsam1 = -sum(g,min(0,vms1(g))) - sum(f, min(0,vfms1(f)))  ;
* same after the shock:
tsupsam2(g) = sum(h,qp2(g,h) - sum(gg,id2(gg,g,h)) )- min(0,vms2(g)) ;
tlsupsam2(ft) = sum(h,max(0,hfms2(ft,h))) - min(0,vfms2(ft)) ;
rowsupsam2 = -sum(g,min(0,vms2(g))) - sum(f, min(0,vfms2(f))) ;
* and the deltas:
tsupsamD(g) = tsupsam2(g)-tsupsam1(g) ;
tlsupsamD(ft) = tlsupsam2(ft)-tlsupsam1(ft) ;
rowsupsamD = rowsupsam2-rowsupsam1 ;
display tsupsam1, tsupsam2, tsupsamD, tlsupsam1, tlsupsam2, tlsupsamD,
        rowsupsam1, rowsupsam2, rowsupsamD ;


* Sets to output which simulation was made:
set kchange(g,fx,h) indicator set of capital having changed ;
kchange(g,fx,h)$fdD(g,fx,h) = yes ;
display kchange ;
display rPC ;

* The following uses the "put" command to produce a text file that is easily imported
* into EXCEL to make nice tables for our chapter. The text file is called
* 'Chap3Tab6.txt'. Each run of the model makes one column of the table,
* which are then easy to merge in excel.
* Just open it up in EXCEL as a semi-colon delimited file,
* or cut+paste it and hit the "text-to-columns" button defining semi-colons as separators.
file tab_miniL /Chap3Tab6.txt/;
put tab_miniL ;

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


put 'Income shock to Poor HH'  @40'; '  yexogD("poor"):<6:2 /;

put 'Household and outcome' @40'; ' /;
put 'Poor Household' @40'; ' /;
put 'Activities' @40'; '  /;
loop(g$(not sameas(g,"exog")),
     put g.tl  @45'; ' qpD(g,"poor"):<6.2 /;
);
put 'Factor incomes' @40'; '  /;
put 'Labor' @40'; ' lyD("labo","poor") /;
put 'Capital' @40'; ' fxyD("capi","poor") /;
put 'Nominal Income' @40'; ' yD("poor") /;
put 'Real Income' @40'; ' ryD("poor") /;

put 'Non-poor Household' @40'; ' /;
put 'Activities' @40'; '  /;
loop(g$(not sameas(g,"exog")),
     put g.tl  @45'; ' qpD(g,"nonpoor"):<6.2 /;
);
put 'Factor incomes' @40'; '  /;
put 'Labor' @40'; ' lyD("labo","nonpoor") /;
put 'Capital' @40'; ' fxyD("capi","nonpoor") /;
put 'Nominal Income' @40'; ' yD("nonpoor") /;
put 'Real Income' @40'; ' ryD("nonpoor") /;

put 'Combined income' @40 ';' /;
put /;
put 'Markets' @40 '; ' /;
loop(g$(not sameas(g,"exog")),
     put g.tl @40 '; ' tsupsamD(g) /;
);
put 'labor' @40 '; ' tlsupsamD("labo") /;
put 'row' @40 '; ' rowsupsamD /;


