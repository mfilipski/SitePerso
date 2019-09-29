$TITLE Tanzania LEWIE MODEL
* Mateusz Filipski, July 2012

* ##############################################################################
* RUNNING THIS CODE:
* 1) NEED THE PATH SOLVER
* 2) GO TO LINE 180 IF YOU WANT TO CHANGE ELASTICITY ASSUMPTIONS
* 3) RESULTS AUTOMATICALLY COME OUT IN A TEXT FILE CALLED tablput_NewTan.txt
* ##############################################################################

* A few useful gams options
option limrow=30 ;
option limcol=30 ;
$onsymlist
$onsymxref

* "null" will be our phantom set throughout the model - avoids getting "empty set" errors from GAMS.
$phantom null


* #################################################################################################
* Understanding the code:

* = Parameters with a "i" suffix are the initial values from the matrix.

* = Parameters with a "1" suffix are the values generated from the calibration run of the model. In theory
* they should be identical to the _i parameters, because the SAM is at equilibrium.

* = Parameters with a "2" suffix are the values generated from the simulation.
* = Parameters with a "D" suffix are the level changes between the "1" and "2" parameter of the same name. ex: yD(h) = y2(h)-y1(h)
* = Parameters with a "PC" suffix are the % changes from "1" level.  ex: tqpPC(g) = tqpD(g)/tqp1(g)
* = Multipliers are computed after runs ex: ymult_h(h) is the change in nominal income of a household / the transfer it received

* #################################################################################################
*

* ================================================================================================
* ================================================================================================
* ==================== STEP 1 - READ IN FROM EXCEL ===============================================
* ================================================================================================
* ================================================================================================

* Name the sets that will be used in the data that is read:
* This is taken from the IFPRI model - though only a few of their sets are used here.
SETS
* These sets are the ones LEWIE will use.
 AC                      global set for model accounts - aggregated microsam accounts
 AA(AC)                  aggregate activities
 A(AC)                   activities
 G(AC)                   commodities
 F(AC)                   factors
 H(AC)                   households
 Reg                     regions
 Z                       zones
* mappings
* from the ifpri model.  Their definitions of "households", "regions" and "zones" dont apply to our village model
*, but the structure is useful to read in the data.
 MAC(A,G)                mapping between activities and commodities
 MAR(A,Reg)              mapping between disaggregate activities and "regions"
 MHR(H,Reg)              mapping between households and "regions"
 MRZ(Reg,Z)              mapping between "regions" and zones
 MAZ(A,Z)                mapping between activities and zones
;

alias (ac, aca) ;
alias (g,gg) ;
alias (f,fa) ;
alias (h,hh) ;
parameter sam(ac, aca) ;

* Read in the data from LEWIE sam (based on the IFPRI sam, disaggregated then re-aggregated and rased)
$call "gdxxrw i=Ch11B_Tanza_Lewie_input_rev1.xlsx o=Ch11D_tanza_newLEWIE_data_rev1.gdx index=index_nlewie!a16"
$gdxin Ch11D_tanza_newLEWIE_data_rev1.gdx
$load ac a g f h z
$load reg mac mar mhr mrz maz
$load sam
$gdxin
display ac, a, g, f, h, z, reg, mac, mar, mhr, mrz, maz, sam ;

* ================================================================================================
* ============================= shrink the SAM to avoid zeros and bang-bang solutions ============
* ================================================================================================
parameter shrunksam(ac,aca);

* Commodity and activty shrinking
* Note: coliv is not olivs, it's livextock.
set  cshrinkmap(g,ac) how to shrink the commodities /
     (ccass, ccoco, cocrp, coils, csorg, cwhea, cmill, csisl).c-oag
     (csugr,ccash,ctoba, ccott, ccoff,cltea,crubb ).c-eag
     (coliv).c-live
     (ctext,comil,cmmil,cmeat,csugp, ctobp, cbeve, cfood).c-proc
     (cpetl,cchem, cfert, cfore, cmine,cfish, cwood).c-res
     (cosrv, cadmn, cfsrv, cheal, ceduc).c-ser
     (celec, cwatr, chotl, ctran, cnmet, cmetl, ccomm, cbsrv, ccons, cmach, coman).cother /

      cshrink(g) commodities to shrink ;

loop(ac,
     cshrink(g)$cshrinkmap(g,ac) = yes ;
);
display cshrink;

set  ashrink(a) activities to shrink (will be those of the cshrink)
     shrinkmap(ac,aca) mapping of commodities to shrink to cother;


* and determine which activities to shrink consequently
loop(cshrink,
     ashrink(a)$(mac(a,cshrink)) = yes ;
);
display cshrink, ashrink ;

* Make it in excel
shrinkmap(cshrink,ac) = cshrinkmap(cshrink,ac) ;

loop((cshrink,g,h,reg)$(cshrinkmap(cshrink,g)*mhr(h,reg)),
     shrinkmap(ashrink,a)$(mar(ashrink,reg)*mar(a,reg)*mac(ashrink,cshrink)*mac(a,g)) = yes ;
);

display shrinkmap ;

* And shrink the factors we want:

set
     fshrinkmap(f,ac) how to shrink the factors /
     (fn-sm,fn-lg).fn_a
     (fv-sm,fv-lg).fv_a
*     (fk-ag-sm,fk-ag-lg).fk_ag
     (fk-mn,fk-nag).fk_o
     (fk_ag_kta_sm,fk_ag_kta_lg).fk_ag_kta
     (fk_ag_kna_sm,fk_ag_kna_lg).fk_ag_kna
     (fk_ag_mta_sm,fk_ag_mta_lg).fk_ag_mta
     (fk_ag_mna_sm,fk_ag_mna_lg).fk_ag_mna
     (fk_ag_oa_sm,fk_ag_oa_lg).fk_ag_oa
     (fn-kta-sm,fn-kta-lg).fn_kta
     (fn-kna-sm,fn-kna-lg).fn_kna
     (fn-mta-sm,fn-mta-lg).fn_mta
     (fn-mna-sm,fn-mna-lg).fn_mna
     (fn-oa-sm,fn-oa-lg).fn_oa
    /
display fshrinkmap ;
shrinkmap(f,ac) = fshrinkmap(f,ac) ;
display shrinkmap

set fshrink(f) factors to shrink ;
loop(ac,
     fshrink(f)$fshrinkmap(f,ac) = yes ;
);
display fshrink ;

* ok, the shrinking map is made for those accounts that should stay.

* These three lines make sure that each account is matched to itself,
* except for those numbered accounts which must be shrunk and then disappear from the matrix
set disap(ac) must disappear from matrix ;
disap(cshrink) = yes ;
disap(ashrink) = yes ;
disap(fshrink) = yes ;
display disap ;

* now we can finalise the shrinkmap, keeping only those we want
shrinkmap(ac,ac)$(not disap(ac)) = yes ;
display shrinkmap ;

* Finally merge according to shrinkmap, to get the shrunk SAM
alias (ac,acag) ;
alias (ac,acagp) ;
parameter shrunksam(ac,aca) ;
shrunksam(acag,acagp) = sum((ac,aca)$(shrinkmap(ac,acag)*shrinkmap(aca,acagp)), sam(ac,aca)) ;
display shrunksam ;

display sam, shrunksam ;


* ================================================================================================
* ============================= CHOOSE ASSUMPTIONS ===============================================
* ================================================================================================
* Wheather or not there is a liquidity constraint on input purchases
* Keep this at zero - haven't set it up yet.
$setlocal liquidityconst 0
* Note: the model treats goods and factors differently.
* Goods used in production function are leontieff, factors are cobb-douglas.

* Choose the elasticity of supply of all the different factors
* Capital
$setlocal fkse 1
* Livestock
$setlocal fvse 1
* Labor - low and hi skill respectively
$setlocal flse_hi 3
$setlocal flse_low 100
*export demand
$setlocal xelast -20

* Assumptions used to make the tables in the book - change the above parameters accordingly:
*-------------------------------------------------------------------------------
* (Refers to p. 248 table 11.9 in the book):
* Simulation 1:  fkse 1 ;  fvse 1 ;   flse_hi 3 ; flse_low 100 ;   elast -20
* Simulation 2:  fkse 0 ;  fvse 0 ;   flse_hi 0 ; flse_low 0 ;   elast -20
* Simulation 3:  fkse 10 ;  fvse 10 ;   flse_hi 100 ; flse_low 100 ;   elast -20
*-------------------------------------------------------------------------------

sets
* factor subsets
     fx(f)     fixed factors /
* land is fixed
fn_kta,fn_kna,fn_mta,fn_mna,fn_oa
fk_o
/

     ft(f)     tradable inputs /null,
* livestock
fv-sm, fv-lg,
fv_a
* labor
fl-no, fl-pr, fl-se, fl-ps
* capital
fk-ag-sm, fk-ag-lg, fk-mn, fk-nag,
*fk_ag
fk_ag_kta, fk_ag_kna,fk_ag_mta,fk_ag_mna,fk_ag_oa

/

     fl(f)     factors that are labor /fl-no , fl-pr, fl-se, fl-ps /
     fl_low(f) factors that are low-skilled labor /fl-no /
     fl_hi(f)  factors that are hi-skilled labor / fl-pr, fl-se, fl-ps /
     fv(f)     factors that are livestock / fv-sm,    fv-lg , fv_a/
     fk(f)     factors that are capital /
fk-ag-sm, fk-ag-lg,
fk_ag_kta, fk_ag_kna,fk_ag_mta,fk_ag_mna,fk_ag_oa
fk_ag,
fk_o, fk-mn, fk-nag
/
     fn(f)     factors that are land /fn-sm , fn-lg , fn_a,
fn_kta,fn_kna,fn_mta,fn_mna,fn_oa    /


* The three subsets ftd, ftz and ftw are where one can change assumptions on factor markets
* =========================================================================================
     ftd(f)    factors tradable in the district /null
* labor with less then secondary schooling
, fl-no , fl-pr,
* livestock by farm size
fv_a
* Capital (ag and others)
fk_ag_kta, fk_ag_kna,fk_ag_mta,fk_ag_mna,fk_ag_oa
/

     ftz(f)    factors tradable in the whole zoi  /
* labor with more than secondary schooling
fl-se,fl-ps,
null /

     ftw(f)    factors tradables in the rest of the world / null /
     fpurch(f) purchased factors that can be limited by liquidity constraint /null/

* The three subsets gtd, gtz and gtw are where one can change assumptions on commodity markets
* ============================================================================================
     gtd(g)    goods tradable in the district / null
* all food crops (non-cash)
cmaiz, croot, cpuls, cplan, cfrui, cvege,
* meat products and fish
ccatt, cpoul,
* services
ctrad,
c-ser
c-oag
/

* goods that were dropped and put into coman: cmill, cfish,ccomm , cbsrv
     gtz(g)    goods tradable in the zoi   /null,
crmil, crice
/
* goods that were dropped and put into coman: csisl,
     gtw(g)    goods tradable with the rest of the world / null,
* ressource extraction
cfore, cmine ,
c-eag
c-live
c-proc
cother
c-res
/

     gcet(g) goods subject to a cet function on exports (gtz goods)
/crmil /
     gag(g)    ag goods /null,
cmaiz, csorg, cmill, crice, cwhea, ccass, croot, cpuls, ccoco, coils, cplan, cfrui, cvege
ccoff, ccash, ccott, csisl, csugr, cltea , ctoba, cocrp, crubb
/
     gnag(g)   non ag goods /null /

     gt(g) targeted goods (ie rice) / crice /
     gpr(g) rice processing /crmil/
     gntc(g) non-target local crops /cmaiz, croot, cpuls, cplan, cvege, cfrui, c-oag /
     gec(g) export crops / c-eag /
     gl(g) livestock and fish /cpoul,ccatt,c-live/
     gres(g) resource extraction /c-res/
     gproc(g) processed or transformed goods /c-proc/
     gtser(g) trade  services / ctrad/
     gser(g) health ed admn services /c-ser/
     goth(g) all other goods or services / cother /

     ggc(g) grain crops /cmaiz, csorg, crice /
     goc(g) all other crops /ccass, croot, cpuls, ccoco, coils, cplan
cfrui, cvege, ccoff, ccash, ccott, csisl, csugr, cltea, ctoba, cocrp,coliv, c-oag, c-eag /

* set of group names
     gnames /gt  target goods (rice)
             gpr rice processing
             gntc other crops
             gec  export crops
             gl  livestock
             gres natural resources
             gproc processed goods
             gtser trade services
             gser other services
             goth all other act. and com. /

* household subsets
     ht(h)     target households  /null, hkta, hktr, hmta, hmtr /


     ha(h)     ag households /null, hkta, hkna, hmta, hmna /


* accounts not in the matrix
     d        districts / KILO Kilombero
                         MVOM Mvomero
                         OTHV other district in morogoro /

* village subsets
     dt   treated district /null, KILO, MVOM/

     maphd mapping housheold to their village / (hkta,hktr,hkna,hknr,hknu).KILO
                                                (hmta,hmtr,hmna,hmnr,hmnu).MVOM
                                                (hoa,hor,hou).OTHV /
;

display g, f, h, fk, fx, ft, ftd, ftz, ftw, gtd, gtz, gtw, d, maphd ;

* remove all the useless accounts from the subsets - if possible (assigned sets can't be used to define things):
fx(f)$fshrink(f) = no ;
fk(f)$fshrink(f) = no ;
fv(f)$fshrink(f) = no ;
ftd(f)$fshrink(f) = no ;
ftz(f)$fshrink(f) = no ;
ftw(f)$fshrink(f) = no ;

gtd(g)$cshrink(g) = no ;
gtz(g)$cshrink(g) = no ;
gtw(g)$cshrink(g) = no ;
gt(g)$cshrink(g) = no ;
gntc(g)$cshrink(g) = no ;
gres(g)$cshrink(g) = no ;
gproc(g)$cshrink(g) = no ;
gser(g)$cshrink(g) = no ;
goth(g)$cshrink(g) = no ;



* ============================= COMPUTE INITIAL VALUES ===========================================
* ================================================================================================

parameter
pd_i(g,d)       sam price at district level
pz_i(g)         sam price at zoi level
ph_i(g,h)       sam price as seen from household
pva_i(g,h)      sam price of value added
qva_i(g,h)      sam quantity of value added
qp_i(g,h)       sam quantity produced
tqp_i(g)        sam total qty produced in the zoi
fd_i(g,f,h)     sam factor demand
id_i(g,gg,h)    sam intermediate demand
acobb_i(g,h)    sam cobb-douglas shifter
shcobb_i(g,f,h) sam cobb-douglas shares
r_i(g,f,h)      sam rent for fixed factors
wv_i(f,d)       sam district-wide wage for tradable factors
wz_i(f)         sam zoi-wide wage for tradable factors
vash_i(g,h)     sam value-added share
idsh_i(gg,g,h)  sam intermediate demand share
tidsh_i(gg,h)   sam total intermediate input share (1-vash)
fixfac_i(g,f,h) sam fixed factor demand
unemp_i(f,h)    sam unemployment
unempsh_i(f,h)  sam hh share of total unemployment
dfmsfix_i(f,d)  sam factors fixed at the district level
zfmsfix_i(f)    sam factors fixed at the zoi level
vmsfix_i(g,d)   sam goods fixed at the district level
zmsfix_i(g)     sam goods fixed at the zoi level

exinc_i(h)      sam exogenous income
endow_i(f,h)    sam endowment
endowsh_i(f,h)  share of a factor value that goes to each household
qc_i(g,h)       sam level of consumption
tqc_i(g)        sam total qc
alpha_i(g,h)    sam consumption shares
y_i(h)          sam nominal hh income
cpi_i(h)        sam consumer price index of hh
ry_i(h)         sam real hh income
cmin_i(g,h)     sam incompressible demand
trin_i(h)       sam transfers in - received
trout_i(h)      sam transfers out - given
trinsh_i(h)     sam share of all transfers in the eco going to h
troutsh_i(h)    sam share of yousehold h's income being given as transfers
hfd_i(f,h)      sam factor demand of household h for factor f
vfd_i(f,d)      sam district demand for factor f
zfd_i(f)        sam zoi demand for factor f
hms_i(g,h)      sam household marketed surplus of good g
vms_i(g,d)      sam district marketed surplus of good g
zms_i(g)        sam household marketed surplus of good g
hfms_i(f,h)     sam household factor marketed surplus
dfms_i(f,d)     sam district factor marketed surplus
zfms_i(f)       sam zoi factor marketed surplus

savsh_i(h)      sam savings rate
sav_i(h)        sam savings level
exprocsh_i(h)   sam outside-of-zoi expenditures rate
exproc_i(h)     sam outside-of-zoi expenditures level
expzoish_i(h)   sam outside-of-zoi expenditures level
;


* prices :
pd_i(g,d) = 1 ;
pz_i(g) = 1 ;
ph_i(g,h) = [pz_i(g)$(gtz(g)+gtw(g)) + sum(d$maphd(h,d),pd_i(g,d))$gtd(g)] ;
r_i(g,f,h) = 1 ;
wv_i(f,d)  = 1 ;
wz_i(f)    = 1 ;

* Production:
fd_i(g,f,h) =  sum((a,reg)$(MAC(a,g)*MAR(a,reg)*MHR(h,reg)), shrunksam(f,a));
id_i(gg,g,h) =  sum((a,reg)$(MAC(a,g)*MAR(a,reg)*MHR(h,reg)), shrunksam(gg,a)) ;


shcobb_i(g,f,h)$sum(fa,fd_i(g,fa,h)) = fd_i(g,f,h)/sum(fa,fd_i(g,fa,h)) ;
acobb_i(g,h)  = sum(f,fd_i(g,f,h)) / prod(f,fd_i(g,f,h)**shcobb_i(g,f,h));

qp_i(g,h) = sum(f, fd_i(g,f,h)) + sum(gg, id_i(gg,g,h));

parameter checkqp(g,h) ;
checkqp(g,h) = acobb_i(g,h)*prod(f,fd_i(g,f,h)**shcobb_i(g,f,h)) + sum(gg, id_i(gg,g,h)) ;

* check the factor shares by "category" for better legibility:
parameter facsh(g,*,h) factor share by category;
facsh(g,"fixed",h) = sum(fx,shcobb_i(g,fx,h));
facsh(g,"labor",h) = sum(fl,shcobb_i(g,fl,h));
facsh(g,"livestock",h) = sum(fv,shcobb_i(g,fv,h));
facsh(g,"capital",h) = sum(fk,shcobb_i(g,fk,h));
display facsh ;
display fd_i, id_i, shcobb_i, acobb_i, qp_i, checkqp ;


* value added and shares :
qva_i(g,h)   = sum(f, fd_i(g,f,h)) ;
vash_i(g,h)$qp_i(g,h) = (qp_i(g,h)-sum(gg, id_i(gg,g,h))) / qp_i(g,h) ;

idsh_i(gg,g,h)$qp_i(g,h) = id_i(gg,g,h) / qp_i(g,h) ;
tidsh_i(g,h) = sum(gg,idsh_i(gg,g,h));
pva_i(g,h) = ph_i(g,h)
                - sum(gg,idsh_i(gg,g,h)*ph_i(gg,h)) ;

display qva_i, vash_i, idsh_i, tidsh_i, pva_i ;


* Consumption
qc_i(g,h) = shrunksam(g,h) ;
* the "total" account is still part of ac.  Just removing it by hand is easier.
y_i(h) = sum(ac, shrunksam(ac,h)) - shrunksam("total",h) ;

sav_i(h) = shrunksam("zoi",h) ;
savsh_i(h) = sav_i(h) / y_i(h) ;
exproc_i(h) = shrunksam("row",h) ;
exprocsh_i(h) = exproc_i(h) / y_i(h) ;

alpha_i(g,h) = qc_i(g,h)/(y_i(h)-sav_i(h)-exproc_i(h)) ;
parameter checkalph(h) should all be 1 ;
checkalph(h) = sum(g, alpha_i(g,h)) ;
display checkalph ;

display qc_i, y_i, sav_i, exproc_i, savsh_i, exproc_i ;


* FACTOR ENDOWMENTS :
* --------------------------
* are in the SAM
endow_i(f,h) = shrunksam(h,f) ;
endowsh_i(f,h)$endow_i(f,h) = endow_i(f,h)/(sum(hh,endow_i(f,hh))+shrunksam("RoW",f)-shrunksam(f,"row")) ;
parameter checkrof(f) ;
checkrof(f) = shrunksam("row",f);
display checkrof ;
display endow_i, endowsh_i ;
fixfac_i(g,fx,h) = fd_i(g,fx,h) ;


* MARKETS AGGREGATES
* ================================================================================================
* factor demand aggregates
hfd_i(f,h)= sum(g,fd_i(g,f,h)) ;
vfd_i(f,d)= sum(h$maphd(h,d), hfd_i(f,h)) ;
zfd_i(f)  = sum(d, vfd_i(f,d)) ;

* marketed surpluses for goods
hms_i(g,h) = qp_i(g,h) - qc_i(g,h) - sum(gg,id_i(g,gg,h)) ;
vms_i(g,d) = sum(h$maphd(h,d),hms_i(g,h));
zms_i(g) = sum(d, vms_i(g,d));

* marketed surpluses for factors
hfms_i(f,h) = endow_i(f,h) - sum(g, fd_i(g,f,h));
dfms_i(f,d) = sum(h$maphd(h,d), hfms_i(f,h));
zfms_i(f) = sum(d, dfms_i(f,d))  ;

* fixed factor demands at district/zoi level
dfmsfix_i(ftd,d) = dfms_i(ftd,d) ;
zfmsfix_i(ftz) = zfms_i(ftz) ;

* fixed goods trade levels at district/zoi level
vmsfix_i(gtd,d) = vms_i(gtd,d) ;
zmsfix_i(gtz) = zms_i(gtz) ;

cmin_i(g,h) = 0 ;
exinc_i(h) = shrunksam(h,"row") + shrunksam(h,"zoi") ;
cpi_i(h) = 1 ;
ry_i(h) = y_i(h)/cpi_i(h) ;

trin_i(h) = 0 ;
trout_i(h) = 0 ;
trinsh_i(h) = 0 ;
troutsh_i(h) = 0 ;



display acobb_i, shcobb_i, pd_i, pz_i, ph_i, pva_i, qva_i, fd_i, id_i, r_i, wz_i, qp_i, fixfac_i, pva_i,
        exinc_i, endow_i, y_i, trinsh_i, qc_i, alpha_i, troutsh_i, hfd_i, vfd_i, zfd_i,
        hms_i, vms_i, zms_i, hfms_i, dfms_i, zfms_i ;
display vmsfix_i, zmsfix_i, dfmsfix_i, zfmsfix_i ;


alias (g,ggg)
      (h,hh) ;

* TOGETHER, THE "_i" PARAMETERS CONTAIN INITIAL VALUES FOR ALL THE ECONOMIC VARIABLES IN LEWIE
* THEY FORM AN ECONOMY THAT IS AT EQUILIBRIUM.


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
     HFSUP(f,h)     labor supply from the household (elastic endowment)
     VFD(f,d)       initial factor demand in the district
     ZFD(f)         initial factor demand in the economy

     R(g,f,h)       rent for fixed factors
     WV(f,d)        wage at the district level
     WZ(f)          wage at the zoi level

* consumption
     QC(g,h)        quantity consumed of g by h
     Y(h)           nominal household income
     RY(h)          real household income
     CPI(h)         consumer price index

* values
     PD(g,d)        price of a good at the district level
     PZ(g)          price of a good at the zoi level
     PH(g,h)        price as seen by household h (zoi or district price depending on good)
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
     VMS(g,d)  district marketed surplus of good g
     ZMS(g)    ZOI marketed surplus of a good

     HFMS(f,h) factor marketed surplus from the household
     dfms(f,d) factor marketed surplus out of the district
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
     vmsfix(g,d) fixed marketed surplus at the district level
     zmsfix(g)  fixed marketed surplus at the zoi level

     exdemelast(g)    elasticity of exogenous demand (export) of rice

* factor endowments for fixed factors
     fixfac(g,f,h) fixed factors
     unempsh(f,h)  household's share of total unemployment
     dfmsfix(f,d)  factors fixed at the district level (family labor)
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
     EQ_VMKT(g,d)        market clearing in the district
     EQ_ZMKT(g)          market clearing in the zoi
     EQ_VMKTfix(g,d)     price definition in the district
     EQ_ZMKTfix(g)       price definition in the zoi

* factor market clearing
     EQ_HFD(f,h)         total household demand for a given factor
     EQ_FCSTR(g,f,h)     fixed factors constraint
     EQ_HFSUP(f,h)       household elastic supply
     EQ_HFMKT(f,h)       tradable factor clearing in the household
     EQ_VFMKT(f,d)       tradable factors clearing in the district
     EQ_ZFMKT(f)         tradable factor clearing in the zoi
     EQ_VFMKTfix(f,d)    wage determination for tradable factors clearing in the district
     EQ_ZFMKTfix(f)      wage determination for tradable factors clearing in the zoi

     EQ_EXDEM(g)         Demand for export in rice (elastic)

;

*=============================================================================================
*==================== MODEL STATEMENT ========================================================
*=============================================================================================

* PRICE BLOCK
EQ_PH(g,h)..
     PH(g,h) =E= PZ(g)$(gtz(g)+gtw(g)) + sum(d$maphd(h,d),PD(g,d))$gtd(g) ;

EQ_PVA(g,h)$qp_i(g,h)..
     PVA(g,h) =E= PH(g,h)- sum(gg,idsh(gg,g,h)*PH(gg,h)) ;

* PRODUCTION BLOCK
EQ_QVACOBB(g,h)$qva_i(g,h)..
     QVA(g,h) =E= acobb(g,h)*prod(f,FD(g,f,h)**(shcobb(g,f,h)))
;

EQ_FDCOBB(g,f,h)$(not fpurch(f))..
     FD(g,f,h)*(R(g,f,h)$fx(f) + WZ(f)$(ftz(f)+ftw(f)) + sum(d$maphd(h,d),WV(f,d))$ftd(f) )
      =E= PVA(g,h)*QP(g,h)*shcobb(g,f,h)
;

* If the dummy is 0 the FD of purchased inputs is of the same form as all other factors
* If the dummy is 1 then the FD is limited by the budget constraint
* Note - this only works for "factors" - model needs to accomodate for that. cfert is not a factor in this version.
EQ_FDPURCH(g,f,h)$fpurch(f)..
     FD(g,f,h)*(R(g,f,h)$fx(f) + WZ(f)$(ftz(f)+ftw(f)) + sum(d$maphd(h,d),WV(f,d))$ftd(f))
      =E= (PVA(g,h)*QP(g,h)*shcobb(g,f,h))$(%liquidityconst% = 0)
         +(pibudget(g,h))$(%liquidityconst% = 1)
;


EQ_QP(g,h)$vash(g,h)..
     QP(g,h) =E= QVA(g,h)/vash(g,h) ;

EQ_ID(gg,g,h)..
     ID(gg,g,h) =E= QP(g,h)*idsh(gg,g,h)
;

* CONSUMPTION AND INCOME
EQ_QC(g,h)$alpha_i(g,h)..
     QC(g,h) =E= alpha(g,h)/PH(g,h)*[(Y(h)-TROUT(h)-SAV(h)-EXPROC(h))-sum(gg, PH(gg,h)*cmin(gg,h))] + cmin(g,h)
;

* Full income (value of factor endowments)
EQ_Y(h)..
     Y(h) =E= sum((g,fn)$fd_i(g,fn,h),R.l(g,fn,h)*FD.l(g,fn,h))
* they get only part of the value of capital, because it's traded/rented
            + sum(fk, sum((g,hh),R.l(g,fk,hh)*FD.l(g,fk,hh))*endowsh_i(fk,h))
            + sum(ftz$hfsupzero(ftz,h), WZ(ftz)*HFSUP(ftz,h))
            + sum(ftd, sum(d$maphd(h,d), WV(ftd,d))*HFSUP(ftd,h))
            + sum(ftw$hfsupzero(ftw,h), WZ(ftw)*HFSUP(ftw,h))
            + exinc(h)
;

EQ_CPI(h)..
* This measure of cpi is computed on disposable income
*     CPI(h) =e= sum(g,PH(g,h)*alpha(g,h))
* Change to this measure to account for exogenous expenses, savings and transfers:
     CPI(h) =e= sum(g$qc_i(g,h),PH(g,h)*[PH(g,h)*QC(g,h)/Y(h)])
                    +1*troutsh(h)+savsh(h)+exprocsh(h)
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
     HMS(g,h) =E= QP(g,h)$qp_i(g,h) - QC(g,h)$qc_i(g,h) - sum(gg,ID(g,gg,h)) ;

EQ_VMKT(g,d)..
     VMS(g,d) =E= sum(h$maphd(h,d),HMS(g,h))
;

EQ_ZMKT(g)..
     ZMS(g) =E= sum(d, VMS(g,d))
;

EQ_VMKTfix(gtd,d)..
     VMS(gtd,d) =E= vmsfix(gtd,d)
;

EQ_ZMKTfix(gtz)$(not gcet(gtz))..
     ZMS(gtz) =E= zmsfix(gtz)
;

EQ_EXDEM(gtz)$gcet(gtz)..
         ZMS(gtz)/zmsfix(gtz) =e= (PZ(gtz)/1)**exdemelast(gtz)
;


* FACTOR MARKET CLEARING
EQ_HFD(f,h)..
     HFD(f,h) =e= sum(g, FD(g,f,h))
;

EQ_FCSTR(g,fx,h)$fd_i(g,fx,h)..
     FD(g,fx,h) =E= fixfac(g,fx,h)
;

EQ_HFMKT(f,h)..
     HFMS(f,h) =E= HFSUP(f,h) - sum(g, FD(g,f,h))
;

EQ_HFSUP(f,h)..
     HFSUP(f,h)$(not hfsupzero(f,h))
     +
     (HFSUP(f,h)/hfsupzero(f,h) - [sum(d$maphd(h,d),WV(f,d)**hfsupel(f,h))$ftd(f)
                                    + (WZ(f)**hfsupel(f,h))$(ftz(f)+ftw(f))] )$hfsupzero(f,h)
     =e= 0
;

EQ_VFMKT(f,d)..
     dfms(f,d) =E= sum(h$maphd(h,d), HFMS(f,h))
;

EQ_ZFMKT(f)..
     sum(d, dfms(f,d)) =E= ZFMS(f)
;

* FACTOR WAGE DETERMINATION
EQ_VFMKTFIX(ftd,d)..
     dfms(ftd,d) =E= dfmsfix(ftd,d)
;

EQ_ZFMKTFIX(ftz)..
     ZFMS(ftz) =E= zfmsfix(ftz)
;



*-------------------------------------------------------------------------------------------------
*--------------------------------------- ALTERNATIVE MODELS --------------------------------------
*-------------------------------------------------------------------------------------------------

model genCD Model with Cobb Douglas production for MCP solver /
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
EQ_VMKTfix.PD
EQ_ZMKTfix.PZ

EQ_EXDEM.PZ

EQ_HFD.HFD
EQ_FCSTR.R
EQ_HFMKT.HFMS
EQ_VFMKT.dfms
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
* calibration values
pd1(g,d)       calibrated price at district level
pz1(g)         calibrated price at zoi level
ph1(g,h)       calibrated price as seen by household
pva1(g,h)      calibrated price of value added
qva1(g,h)      calibrated quantity of value added
hqva1(h)       calibrated quantity of total value added by household
gqva1(g)       calibrated quantity of total value added by good
tqva1          calibrated quantity of total value added
qp1(g,h)       calibrated quantity produced
tqp1(g)        calibrated total quantity produced
fd1(g,f,h)     calibrated factor demand
id1(g,gg,h)    calibrated intermediate demand
acobb1(g,h)    calibrated cobb-douglas shifter
shcobb1(g,f,h) calibrated cobb-douglas shares
r1(g,f,h)      calibrated rent for fixed factors
wv1(f,d)       calibrated district-wide wage for tradable factors
wz1(f)         calibrated zoi-wide wage for tradable factors
vash1(g,h)     calibrated value-added share
idsh1(gg,g,h)  calibrated intermediate demand share
tidsh1(gg,h)   calibrated total intermediate input share (1-vash)
fixfac1(g,f,h) calibrated fixed factor demand
exinc1(h)      calibrated exogenous income
endow1(f,h)    calibrated endowment
qc1(g,h)       calibrated level of consumption
alpha1(g,h)    calibrated consumption shares
y1(h)          calibrated income of household
cpi1(h)        calibrated cpi
vcpi1(d)       calibrated district cpi
cri1(f,d)           calibrated rent weighted index

ry1(h)         calibrated real income
ty1           calibrated income total
try1          calibrated real income total
cmin1(g,h)     calibrated incompressible demand
trin1(h)       calibrated transfers in - received
trout1(h)      calibrated transfers out - given
trinsh1(h)     calibrated share of all transfers in the eco going to h
troutsh1(h)    calibrated share of yousehold h's income being given as transfers
hfd1(f,h)      calibrated factor demand of household h for factor f
vfd1(f,d)      calibrated district demand for factor f
zfd1(f)        calibrated zoi demand for factor f
hms1(g,h)      calibrated household marketed surplus of good g
vms1(g,d)      calibrated district marketed surplus of good g
zms1(g)        calibrated household marketed surplus of good g
hfms1(f,h)     calibrated household factor marketed surplus
dfms1(f,d)     calibrated district factor marketed surplus
zfms1(f)       calibrated zoi factor marketed surplus
dfmsfix1(f,d)    calibrated factors fixed at the district level (family labor)
zfmsfix1(f)      calibrated factors fixed at the zoi level (hired labor)
hfsup1(f,h)    calibrated factor supply by the household


* after a simulation
pd2(g,d)       simulated price at district level
pz2(g)         simulated price at zoi level
ph2(g,h)       simulated price as seen by household
pva2(g,h)      simulated price of value added
qva2(g,h)      simulated quantity of value added
hqva2(h)       calibrated quantity of total value added by household
gqva2(g)       calibrated quantity of total value added by good
tqva2
qp2(g,h)       simulated quantity produced
tqp2(g)        simulated total quantity produced in the economy
fd2(g,f,h)     simulated factor demand
id2(g,gg,h)    simulated intermediate demand
acobb2(g,h)    simulated cobb-douglas shifter
shcobb2(g,f,h) simulated cobb-douglas shares
r2(g,f,h)      simulated rent for fixed factors
wv2(f,d)       simulated district-wide wage for tradable factors
wz2(f)         simulated zoi-wide wage for tradable factors
vash2(g,h)     simulated value-added share
idsh2(gg,g,h)  simulated intermediate demand share
tidsh2(gg,h)   simulated total intermediate input share (2-vash)
fixfac2(g,f,h) simulated fixed factor demand
exinc2(h)      simulated exogenous income
endow2(f,h)    simulated endowment
qc2(g,h)       simulated level of consumption
alpha2(g,h)    simulated consumption shares
y2(h)          simulated income of household
cpi2(h)        simulated cpi
cri2(f,d)      simulated capital rent index (cap rent in activity*weight of activity)

vcpi2(d)       simulated district cpi
ry2(h)         simulated real income
ty2            simulated income total
try2           simulated real income total
cmin2(g,h)     simulated incompressible demand
trin2(h)       simulated transfers in - received
trout2(h)      simulated transfers out - given
trinsh2(h)     simulated share of all transfers in the eco going to h
troutsh2(h)    simulated share of yousehold h's income being given as transfers
hfd2(f,h)      simulated factor demand of household h for factor f
vfd2(f,d)      simulated district demand for factor f
zfd2(f)        simulated zoi demand for factor f
hms2(g,h)      simulated household marketed surplus of good g
vms2(g,d)      simulated district marketed surplus of good g
zms2(g)        simulated household marketed surplus of good g
hfms2(f,h)     simulated household factor marketed surplus
dfms2(f,d)     simulated district factor marketed surplus
zfms2(f)       simulated zoi factor marketed surplus
hfsup2(f,h)    simulated factor supply by the household

* delta calibration /simulation
pdD(g,d)       delta price at district level
pzD(g)         delta price at zoi level
phD(g,h)       delta price as seen by household

pvaD(g,h)      delta price of value added
qvaD(g,h)      delta quantity of value added
hqvaD(h)       calibrated quantity of total value added by household
gqvaD(g)       calibrated quantity of total value added by good
tqvaD
qpD(g,h)       delta quantity produced
tqpD(g)        delta total qp
dqpD(g,d)      delta qp in the district
fdD(g,f,h)     delta factor demand
idD(g,gg,h)    delta intermediate demand
acobbD(g,h)    delta cobb-douglas shifter
shcobbD(g,f,h) delta cobb-douglas shares
rD(g,f,h)      delta rent for fixed factors
wvD(f,d)       delta district-wide wage for tradable factors
wzD(f)         delta zoi-wide wage for tradable factors
vashD(g,h)     delta value-added share
idshD(gg,g,h)  delta intermediate demand share
tidshD(gg,h)   delta total intermediate input share (1-vash)
fixfacD(g,f,h) delta fixed factor demand
exincD(h)      delta exogenous income
endowD(f,h)    delta endowment
qcD(g,h)       delta level of consumption
alphaD(g,h)    delta consumption shares
yD(h)          delta income of household
cpiD(h)        delta cpi
vcpiD(d)       delta district cpi
criD(f,d)        delta capital rent index (cap rent in activity*weight of activity)

ryD(h)         delta real income
tyD           delta income total
tryD          delta real income total
cminD(g,h)     delta incompressible demand
trinD(h)       delta transfers in - received
troutD(h)      delta transfers out - given
trinshD(h)     delta share of all transfers in the eco going to h
troutshD(h)    delta share of yousehold h's income being given as transfers
hfdD(f,h)      delta factor demand of household h for factor f
vfdD(f,d)      delta district demand for factor f
zfdD(f)        delta zoi demand for factor f
hmsD(g,h)      delta household marketed surplus of good g
vmsD(g,d)      delta district marketed surplus of good g
zmsD(g)        delta household marketed surplus of good g
hfmsD(f,h)     delta household factor marketed surplus
dfmsD(f,d)     delta district factor marketed surplus
zfmsD(f)       delta zoi factor marketed surplus
hfsupD(f,h)    delta factor supply by the household

* percent change calibration/simulation
pdPC(g,d)        % change price at district level
pzPC(g)          % chage price at zoi level
phPC(g,h)        % change price as seen by household

pvaPC(g,h)      % change price of value added
qvaPC(g,h)      % change quantity of value added
hqvaPC(h)       calibrated quantity of total value added by household
gqvaPC(g)       calibrated quantity of total value added by good
tqvaPC
qpPC(g,h)       % change quantity produced
tqpPC(g)        % change in total qp
fdPC(g,f,h)     % change factor demand
idPC(g,gg,h)    % change intermediate demand
acobbPC(g,h)    % change cobb-douglas shifter
shcobbPC(g,f,h) % change cobb-douglas shares
rPC(g,f,h)      % change rent for fixed factors
wvPC(f,d)       % change district-wide wage for tradable factors
wzPC(f)         % change zoi-wide wage for tradable factors
vashPC(g,h)     % change value-added share
idshPC(gg,g,h)  % change intermediate demand share
tidshPC(gg,h)   % change total intermediate input share (1-vash)
fixfacPC(g,f,h) % change fixed factor demand
exincPC(h)      % change exogenous income
endowPC(f,h)    % change endowment
qcPC(g,h)       % change level of consumption
alphaPC(g,h)    % change consumption shares
yPC(h)          % change income of household
cpiPC(h)        % change in cpi
vcpiPC(d)       % change district cpi
criPC(f,d)      % change capital rent index (cap rent in activity*weight of activity)
ryPC(h)         % change in real income
tyPC            % change income total
tryPC           % change real income total
cminPC(g,h)     % change incompressible demand
trinPC(h)       % change transfers in - received
troutPC(h)      % change transfers out - given
trinshPC(h)     % change share of all transfers in the eco going to h
troutshPC(h)    % change share of yousehold h's income being given as transfers
hfdPC(f,h)      % change factor demand of household h for factor f
vfdPC(f,d)      % change district demand for factor f
zfdPC(f)        % change zoi demand for factor f
hmsPC(g,h)      % change household marketed surplus of good g
vmsPC(g,d)      % change district marketed surplus of good g
zmsPC(g)        % change household marketed surplus of good g
hfmsPC(f,h)     % change household factor marketed surplus
dfmsPC(f,d)     % change district factor marketed surplus
zfmsPC(f)       % change zoi factor marketed surplus
hfsupPC(f,h)    % change factor supply by the household
;


* ================================================================================================
* ================================================================================================
* ===================== STEP 4 - SOLVE THE MODEL  ================================================
* ================================================================================================
* ================================================================================================

* Initialize values
* re-initialise all the variables in the matrix
* but this time not at the I levels - rather, at the _i levels
cmin(g,h)      = cmin_i(g,h) ;
acobb(g,h)     = acobb_i(g,h) ;
shcobb(g,f,h)  = shcobb_i(g,f,h) ;
PZ.l(g)        = pz_i(g) ;
PD.l(g,d)      = pd_i(g,d) ;
PH.l(g,h)      = ph_i(g,h) ;
QVA.l(g,h)     = qva_i(g,h) ;
FD.l(g,f,h)    = fd_i(g,f,h) ;
ID.l(gg,g,h)   = id_i(gg,g,h) ;
R.l(g,fx,h)    = r_i(g,fx,h);
WV.l(f,d)      = wv_i(f,d) ;
WZ.l(f)        = wz_i(f);
QP.l(g,h)      = qp_i(g,h) ;
fixfac(g,fx,h) = fixfac_i(g,fx,h) ;
dfmsfix(ftd,d) = dfmsfix_i(ftd,d) ;
zfmsfix(ftz)   = zfmsfix_i(ftz) ;
PVA.l(g,h)     = pva_i(g,h) ;
vash(g,h)      = vash_i(g,h) ;
idsh(gg,g,h)   = idsh_i(gg,g,h) ;
tidsh(g,h)     = tidsh_i(g,h) ;
exinc(h)       = exinc_i(h) ;
endow(f,h)     = endow_i(f,h) ;
Y.l(h)         = y_i(h) ;
CPI.l(h)       = cpi_i(h) ;
RY.l(h)        = ry_i(h) ;
TRIN.l(h)      = trin_i(h) ;
trinsh(h)      = trinsh_i(h) ;
QC.l(g,h)      = qc_i(g,h) ;
alpha(g,h)     = alpha_i(g,h) ;
troutsh(h)     = troutsh_i(h) ;
TROUT.l(h)     = trout_i(h) ;
HFD.l(f,h)     = hfd_i(f,h);
VFD.l(f,d)     = vfd_i(f,d);
ZFD.l(f)       = zfd_i(f);
HMS.l(g,h)     = hms_i(g,h);
VMS.l(g,d)     = vms_i(g,d);
ZMS.l(g)       = zms_i(g);
vmsfix(gtd,d)  = vmsfix_i(gtd,d);
zmsfix(gtz)    = zmsfix_i(gtz);
HFMS.l(ft,h)   = hfms_i(ft,h);
dfms.l(ft,d)   = dfms_i(ft,d);
ZFMS.l(ft)     = zfms_i(ft);
savsh(h)       = savsh_i(h) ;
exprocsh(h)    = exprocsh_i(h) ;
SAV.l(h)       = sav_i(h) ;
EXPROC.l(h)    = exproc_i(h) ;
hfsupzero(ft,h) = endow_i(ft,h) ;

* Purchsed inputs budget isn't set up for Tanzania - maybe in future versions.
pibudget(g,h)  = 0;
pibsh(g,h)$sum(gg,pibudget(gg,h))  = pibudget(g,h)/sum(gg,pibudget(gg,h)) ;
display pibudget, pibsh, hfsupzero ;

* read the supply elasticities from the locals defined at the top of the program
hfsupel(fl_low,h) = %flse_low% ;
hfsupel(fl_low,h) = %flse_hi% ;
hfsupel(fk,h) = %fkse% ;
hfsupel(fv,h) = %fvse% ;
HFSUP.l(f,h)    = hfsupzero(f,h) ;
exdemelast(g)  = %xelast%;

* closures: fixed wages and prices on world-market-integrated factors and goods (ftw & gtw)
WZ.fx(ftw) = WZ.l(ftw);
PZ.fx(gtw) = PZ.l(gtw) ;

* fix QP if it doesn't exist in the base
QP.fx(g,h)$(not qp_i(g,h)) = 0 ;

* fix non-existing vars:
FD.fx(g,f,h)$(not fd_i(g,f,h)) = 0 ;
ID.fx(gg,g,h)$(not id_i(gg,g,h)) = 0 ;
R.fx(g,fx,h)$(not fd_i(g,fx,h)) = r_i(g,fx,h);

display PD.l, PZ.l, PH.l, PVA.l, QVA.l, FD.l, QP.l, ID.l, QC.l, Y.l, CPI.l, RY.l, SAV.l, EXPROC.l,
HMS.l, VMS.l, ZMS.l, R.l, WZ.l, HFMS.l, dfms.l, ZFMS.l, HFSUP.l ;




parameter testy1(h), testy11(h), testy2(h), testy3(h), testy4(h), testall(h), fdx(g,f,h) ;
fdx(g,fx,h) = FD.l(g,fx,h);
* they get all the value of their land, because they own it
testy1(h)= sum((g,fn)$fd_i(g,fn,h),R.l(g,fn,h)*FD.l(g,fn,h)) ;
* they get part of the value of capital, because it's traded/rented
testy11(h)= sum(fk, sum((g,hh),R.l(g,fk,hh)*FD.l(g,fk,hh))*endowsh_i(fk,h)) ;

testy2(h)= sum(ftz$hfsupzero(ftz,h), WZ.l(ftz)*HFSUP.l(ftz,h)) ;
testy3(h)= sum(ftd, sum(d$maphd(h,d), WV.l(ftd,d))*HFSUP.l(ftd,h)) ;
testy4(h) = sum(ftw$hfsupzero(ftw,h), WZ.l(ftw)*HFSUP.l(ftw,h)) ;
;
testall(h) = testy1(h) + testy11(h) + testy2(h)+testy3(h)+testy4(h)+exinc(h) ;
display fdx, testy1, testy11, testy2, testy3, testy4, testall, exinc;


*---------------------------------
* RE-CALIBRATION
*---------------------------------
option iterlim = 1 ;
solve genCD using mcp ;
option iterlim=100000;
ABORT$(genCD.modelstat ne 1) "NOT WELL CALIBRATED - CHECK THE DATA INPUTS" ;
display PD.l, PZ.l, PH.l, PVA.l, QVA.l, FD.l, QP.l, ID.l, QC.l, Y.l, Y.l, CPI.l, RY.l,
     TROUT.l, TRIN.l, SAV.l, EXPROC.l, HMS.l, VMS.l, ZMS.l, R.l, WZ.l, HFMS.l, dfms.l, ZFMS.l;
display CPI.l ;

acobb1(g,h)    = acobb(g,h) ;
shcobb1(g,f,h) = shcobb(g,f,h) ;

pd1(g,d)       = PD.l(g,d) ;
pz1(g)         = PZ.l(g) ;
ph1(g,h)       = PH.l(g,h) ;
qva1(g,h)      = QVA.l(g,h) ;
fd1(g,f,h)     = FD.l(g,f,h) ;
id1(gg,g,h)    = ID.l(gg,g,h) ;
r1(g,fx,h)     = R.l(g,fx,h) ;
wv1(f,d)       = WV.l(f,d) ;
wz1(f)         = WZ.l(f) ;
qp1(g,h)       = QP.l(g,h) ;
fixfac1(g,fx,h) = fixfac(g,fx,h) ;
pva1(g,h)      = PVA.l(g,h) ;
vash1(g,h)     = vash(g,h) ;
idsh1(g,gg,h)  = idsh(g,gg,h) ;
tidsh1(g,h)    = tidsh(g,h) ;
exinc1(h)      = exinc(h) ;
endow1(f,h)    = endow(f,h) ;
y1(h)          = Y.l(h) ;
qc1(g,h)       = QC.l(g,h) ;
cpi1(h)        = CPI.l(h) ;
* district cpi is weighted sum of prices
vcpi1(d)       = sum((h,g)$maphd(h,d), (ph1(g,h)**2)*qc1(g,h)) / sum((h,g)$maphd(h,d),ph1(g,h)*qc1(g,h)) ;
cri1(fx,d)$sum((gg,hh)$maphd(hh,d),fd1(gg,fx,hh))     = sum((g,h)$maphd(h,d), r1(g,fx,h)*fd1(g,fx,h)/sum((gg,hh)$maphd(hh,d),fd1(gg,fx,hh)) ) ;
*cri1(d)          = 1;
ry1(h)         = RY.l(h) ;
ty1           = sum(h,y1(h));
try1          = sum(h,ry1(h));
trin1(h)       = TRIN.l(h) ;
trout1(h)      = TROUT.l(h) ;
trinsh1(h)     = trinsh(h) ;
alpha1(g,h)    = alpha(g,h) ;
cmin1(g,h)     = cmin(g,h) ;
troutsh1(h)    = troutsh(h) ;
hfd1(f,h)      = HFD.l(f,h) ;
vfd1(f,d)      = VFD.l(f,d) ;
zfd1(f)        = ZFD.l(f) ;
hms1(g,h)      = HMS.l(g,h) ;
vms1(g,d)      = VMS.l(g,d) ;
zms1(g)        = ZMS.l(g) ;
hfms1(ft,h)    = HFMS.l(ft,h) ;
dfms1(ft,d)    = dfms.l(ft,d) ;
zfms1(ft)      = ZFMS.l(ft) ;
hfsup1(ft,h)   = HFSUP.l(ft,h) ;

dfmsfix1(ft,d) = dfmsfix_i(ft,d) ;
zfmsfix1(ft)   = zfmsfix_i(ft) ;

* more params
tqp1(g)        = sum(h,qp1(g,h)) ;

hqva1(h)   = sum(g,qva1(g,h));
gqva1(g)   = sum(h,qva1(g,h));
tqva1      = sum((g,h),qva1(g,h));

*------------------------------------
* SIMULATION
*------------------------------------
* 1) no cash transfer
transfer(h) = 0 ;
exinc("hkta") = exinc("hkta") + transfer("hkta")  ;

* 2) 18% productivity increase in shift parameter (technology) for the treated households
* in this case = all households of the treated district * ag households
* 18% is yearly yield increase
* because yields are projected to double over 5 years, on 46% of the land 0.18=2*0.46/5
* see p.238 of beyond experiments book
scalar shock ;
shock = 0.18 ;
display acobb ;
loop(dt,
     acobb(gt,h)$(maphd(h,dt)*ht(h)*ha(h)*qp_i(gt,h)) = acobb(gt,h)*(1+shock) ;
);
display acobb ;

solve genCD using mcp ;
ABORT$(genCD.modelstat ne 1) "NO OPTIMAL SOLUTION REACHED" ;

display PD.l, PZ.l, PH.l, PVA.l, QVA.l, FD.l, QP.l, ID.l, QC.l, Y.l, HMS.l, VMS.l, ZMS.l, R.l, WZ.l, HFMS.l, dfms.l, ZFMS.l, fd.l;
display CPI.l ;

acobb2(g,h)    = acobb(g,h) ;
shcobb2(g,f,h) = shcobb(g,f,h) ;
pd2(g,d)       = PD.l(g,d) ;
pz2(g)         = PZ.l(g) ;
ph2(g,h)       = PH.l(g,h) ;
qva2(g,h)      = QVA.l(g,h) ;
fd2(g,f,h)     = FD.l(g,f,h) ;
id2(gg,g,h)    = ID.l(gg,g,h) ;
r2(g,fx,h)     = R.l(g,fx,h) ;
wv2(f,d)       = WV.l(f,d) ;
wz2(f)         = WZ.l(f) ;
qp2(g,h)       = QP.l(g,h) ;
tqp2(g)        = sum(h,qp2(g,h)) ;
fixfac2(g,fx,h) = fixfac(g,fx,h) ;
pva2(g,h)      = PVA.l(g,h) ;
vash2(g,h)      = vash(g,h) ;
exinc2(h)      = exinc(h) ;
endow2(f,h)    = endow(f,h) ;
y2(h)          = Y.l(h) ;
qc2(g,h)       = QC.l(g,h) ;
cpi2(h)        = CPI.l(h) ;
* district cpi is weighted sum of prices
vcpi2(d)       = sum((h,g)$maphd(h,d), (ph2(g,h)**2)*qc2(g,h)) / sum((h,g)$maphd(h,d),ph2(g,h)*qc2(g,h)) ;
* wieghted capital rent in the district
cri2(fx,d)$sum((gg,hh)$maphd(hh,d),fd2(gg,fx,hh)) = sum((g,h)$maphd(h,d), r2(g,fx,h)*fd2(g,fx,h)/sum((gg,hh)$maphd(hh,d),fd2(gg,fx,hh)) ) ;

hqva2(h)   = sum(g,qva2(g,h));
gqva2(g)   = sum(h,qva2(g,h));
tqva2      = sum((g,h),qva2(g,h));


ry2(h)         = RY.l(h) ;
ty2           = sum(h,y2(h));
try2          = sum(h,ry2(h));
trinsh2(h)     = trinsh(h) ;
alpha2(g,h)    = alpha(g,h) ;
troutsh2(h)    = troutsh(h) ;
hfd2(f,h)      = HFD.l(f,h) ;
vfd2(f,d)      = VFD.l(f,d) ;
zfd2(f)        = ZFD.l(f) ;
hms2(g,h)      = HMS.l(g,h) ;
vms2(g,d)      = VMS.l(g,d) ;
zms2(g)        = ZMS.l(g) ;
hfms2(ft,h)    = HFMS.l(ft,h) ;
dfms2(ft,d)    = dfms.l(ft,d) ;
zfms2(ft)      = ZFMS.l(ft) ;
trin2(h)       = TRIN.l(h) ;
trout2(h)      = TROUT.l(h) ;
hfsup2(ft,h)   = HFSUP.l(ft,h) ;

display y2 ;
* ================================================================================================
* ======================= RUNS END HERE ==========================================================
* ================================================================================================



* ================================================================================================
* ================================================================================================
* ===================== STEP 5 - OUTPUT ==========================================================
* ================================================================================================
* ================================================================================================

* now compute and display all the values, differences in values, standard errors, etc...
display pd1, pz1, ph1, qva1, fd1, id1, r1, wv1, wz1, qp1, tqp1, fixfac1, pva1, exinc1, endow1, y1, cpi1, vcpi1, ry1,
        trinsh1, qc1, alpha1, troutsh1, hfsup1, hfd1, vfd1, zfd1, hms1, vms1, zms1, hfms1, dfms1, zfms1 ;
display qva1, hqva1, gqva1, tqva1;

display pd2, pz2, ph2, qva2, fd2, id2, r2, wv2, wz2, qp2, tqp2, fixfac2, pva2, exinc2, endow2, y2, cpi2, vcpi2, ry2,
        trinsh2, qc2, alpha2, troutsh2, hfsup2, hfd2, vfd2, zfd2, hms2, vms2, zms2, hfms2, dfms2, zfms2 ;
display qva2, hqva2, gqva2, tqva2;

* DELTA between each calibration and the corresponding simulation
acobbD(g,h)    = acobb2(g,h) - acobb1(g,h);
shcobbD(g,f,h) = shcobb2(g,f,h) - shcobb1(g,f,h) ;
pdD(g,d)       = pd2(g,d) - pd1(g,d) ;
pzD(g)         = pz2(g) - pz1(g) ;
phD(g,h)       = ph2(g,h) - ph1(g,h) ;
qvaD(g,h)      = qva2(g,h) - qva1(g,h) ;
hqvaD(h)       = hqva2(h) - hqva1(h) ;
gqvaD(g)       = gqva2(g) - gqva1(g) ;
tqvaD          = tqva2 - tqva1 ;
fdD(g,f,h)     = fd2(g,f,h) - fd1(g,f,h) ;
idD(gg,g,h)    = id2(gg,g,h) - id1(gg,g,h) ;
rD(g,fx,h)     = r2(g,fx,h) - r1(g,fx,h) ;
wvD(f,d)       = wv2(f,d) - wv1(f,d) ;
wzD(f)         = wz2(f) - wz1(f) ;
qpD(g,h)       = qp2(g,h) - qp1(g,h) ;
tqpD(g)        = tqp2(g) - tqp1(g) ;
dqpD(g,d)      = sum(h$maphd(h,d), qpD(g,h)) ;
fixfacD(g,fx,h)= fixfac2(g,fx,h) - fixfac1(g,fx,h) ;
pvaD(g,h)      = pva2(g,h) - pva1(g,h) ;
exincD(h)      = exinc2(h) - exinc1(h) ;
endowD(f,h)    = endow2(f,h) - endow1(f,h) ;
yD(h)          = y2(h) - y1(h) ;
cpiD(h)          = cpi2(h) - cpi1(h) ;
* district cpi is weighted sum of prices
vcpiD(d)       = vcpi2(d) - vcpi1(d);
criD(fx,d)     = cri2(fx,d) - cri1(fx,d);
ryD(h)         = ry2(h) - ry1(h) ;
tyD            = ty2 - ty1 ;
tryD           = try2 - try1 ;
trinshD(h)     = trinsh2(h) - trinsh1(h) ;
qcD(g,h)       = qc2(g,h) - qc1(g,h) ;
alphaD(g,h)    = alpha2(g,h) - alpha1(g,h) ;
troutshD(h)    = troutsh2(h) - troutsh1(h) ;
hfdD(f,h)      = hfd2(f,h) - hfd1(f,h) ;
vfdD(f,d)      = vfd2(f,d) - vfd1(f,d) ;
zfdD(f)        = zfd2(f) - zfd1(f) ;
hmsD(g,h)      = hms2(g,h) - hms1(g,h) ;
vmsD(g,d)      = vms2(g,d) - vms1(g,d) ;
zmsD(g)        = zms2(g) - zms1(g) ;
hfmsD(ft,h)    = hfms2(ft,h) - hfms1(ft,h) ;
dfmsD(ft,d)    = dfms2(ft,d) - dfms1(ft,d) ;
zfmsD(ft)      = zfms2(ft) - zfms1(ft) ;
vashD(g,h)     = vash2(g,h) -vash1(g,h) ;
trinD(h)       = trin2(h) - trin1(h) ;
troutD(h)      = trout2(h) - trout1(h) ;
hfsupD(f,h)    = hfsup2(f,h) - hfsup1(f,h) ;

* PERCENT CHANGE between each calibration and the corresponding simulation
acobbPC(g,h)$acobb1(g,h)    = 100*acobbD(g,h)/ acobb1(g,h);
shcobbPC(g,f,h)$shcobb1(g,f,h) = 100*shcobbD(g,f,h) / shcobb1(g,f,h) ;
pdPC(g,d)$pd1(g,d)        = 100*pdD(g,d) / pd1(g,d) ;
pzPC(g)$pz1(g)            = 100*pzD(g) / pz1(g) ;
phPC(g,h)$ph1(g,h)        = 100*phD(g,h) / ph1(g,h) ;
qvaPC(g,h)$qva1(g,h)      = 100*qvaD(g,h) / qva1(g,h) ;
hqvaPC(h)$hqva1(h)        = 100*hqvaD(h) / hqva1(h) ;
gqvaPC(g)$gqva1(g)        = 100*gqvaD(g) / gqva1(g) ;
tqvaPC$tqva1              = 100*tqvaD / tqva1 ;
fdPC(g,f,h)$fd1(g,f,h)    = 100*fdD(g,f,h) / fd1(g,f,h) ;
idPC(gg,g,h)$id1(gg,g,h)  = 100*idD(gg,g,h) / id1(gg,g,h) ;
rPC(g,fx,h)$r1(g,fx,h)    = 100*rD(g,fx,h) / r1(g,fx,h) ;
wvPC(f,d)$wv1(f,d)        = 100*wvD(f,d) / wv1(f,d) ;
wzPC(f)$wz1(f)            = 100*wzD(f) / wz1(f) ;
qpPC(g,h)$qp1(g,h)        = 100*qpD(g,h) / qp1(g,h) ;
tqpPC(g)$tqp1(g)          = 100*tqpD(g) / tqp1(g) ;

fixfacPC(g,fx,h)$fixfac1(g,fx,h)  = 100*fixfacD(g,fx,h) / fixfac1(g,fx,h) ;
pvaPC(g,h)$pva1(g,h)      = 100*pvaD(g,h) / pva1(g,h) ;
exincPC(h)$exinc1(h)      = 100*exincD(h) / exinc1(h) ;
endowPC(f,h)$endow1(f,h)  = 100*endowD(f,h) / endow1(f,h) ;
yPC(h)$y1(h)              = 100*yD(h) / y1(h) ;
cpiPC(h)$cpi1(h)          = 100*cpiD(h) / cpi1(h) ;
vcpiPC(d)$vcpi1(d)        = 100*vcpiD(d) / vcpi1(d) ;
criPC(fx,d)$cri1(fx,d)        = 100*criD(fx,d) / cri1(fx,d) ;

ryPC(h)$ry1(h)            = 100*ryD(h) / ry1(h) ;
tyPC$ty1                  = 100*tyD / ty1 ;
tryPC$try1                = 100*tryD / try1 ;
trinshPC(h)$trinsh1(h)    = 100*trinshD(h) / trinsh1(h) ;
qcPC(g,h)$qc1(g,h)        = 100*qcD(g,h) / qc1(g,h) ;
alphaPC(g,h)$alpha1(g,h)  = 100*alphaD(g,h) / alpha1(g,h) ;
troutshPC(h)$troutsh1(h)  = 100*troutshD(h) / troutsh1(h) ;
hfdPC(f,h)$hfd1(f,h)      = 100*hfdD(f,h) / hfd1(f,h) ;
vfdPC(f,d)$vfd1(f,d)      = 100*vfdD(f,d) / vfd1(f,d) ;
zfdPC(f)$zfd1(f)          = 100*zfdD(f) / zfd1(f) ;
hmsPC(g,h)$hms1(g,h)      = 100*hmsD(g,h) / hms1(g,h) ;
vmsPC(g,d)$vms1(g,d)      = 100*vmsD(g,d) / vms1(g,d) ;
zmsPC(g)$zms1(g)          = 100*zmsD(g) / zms1(g) ;
hfmsPC(ft,h)$hfms1(ft,h)  = 100*hfmsD(ft,h) / hfms1(ft,h) ;
dfmsPC(ft,d)$dfms1(ft,d)  = 100*dfmsD(ft,d) / dfms1(ft,d) ;
zfmsPC(ft)$zfms1(ft)      = 100*zfmsD(ft) / zfms1(ft) ;
vashPC(g,h)$vash1(g,h)    = 100*vashD(g,h) / vash1(g,h) ;
trinPC(h)$trin1(h)        = 100*trinD(h) / trin1(h) ;
troutPC(h)$trout1(h)      = 100*troutD(h) / trout1(h) ;
hfsupPC(f,h)$hfsup1(f,h)  = 100*hfsupD(f,h) / hfsup1(f,h) ;


display pdD, pzD, phD, qvaD, fdD, idD, rD, wvD, wzD, qpD, tqpD, dqpD, fixfacD, pvaD, exincD, endowD, yD, cpiD, vcpiD, criD, ryD, tyD, tryD,
        trinshD, qcD, alphaD, troutshD, hfsupD, hfdD, vfdD, zfdD, hmsD, vmsD, zmsD, hfmsD, dfmsD, zfmsD ,
        vashD, trinD, troutD, acobbD, shcobbD;
display qvaD, gqvaD, hqvaD, tqvaD ;

display pdPC, pzPC, phPC, qvaPC, fdPC, idPC, rPC, wvPC, wzPC, qpPC, tqpPC, fixfacPC, pvaPC, exincPC, endowPC, yPC, cpiPC, vcpiPC, criPC, ryPC, tyPC, tryPC,
        trinshPC, qcPC, alphaPC, troutshPC, hfsupPC, hfdPC, vfdPC, zfdPC, hmsPC, vmsPC, zmsPC, hfmsPC, dfmsPC, zfmsPC ,
        vashPC, trinPC, troutPC, acobbPC, shcobbPC ;
display qvaPC, gqvaPC, hqvaPC, tqvaPC ;


parameter w_qpPC(gnames) weighted increase in quantity produced by group of commodities
          g_qpD(gnames) group totals of production value increases
          g_dqpD(gnames,d) group totals by village;

*     gnames /ggc, goc, gl, gres, gproc, gser, goth/
alias (ggc,ggca)
      (gl,gla)
      (gres,gresa)
      (gpr,gpra)
      (gproc,gproca)
      (gser,gsera)
      (gtser,gtsera)
      (goth,gotha)
      (gt, gta)
      (gntc,gntca)
      (gec,geca)
;

g_qpD("gt") = sum(gt(g), tqpD(g)) ;
g_qpD("gntc") = sum(gntc(g), tqpD(g)) ;
g_qpD("gec") = sum(gec(g), tqpD(g)) ;
g_qpD("gl") = sum(gl(g), tqpD(g)) ;
g_qpD("gres") = sum(gres(g), tqpD(g)) ;
g_qpD("gproc") = sum(gproc(g), tqpD(g)) ;
g_qpD("gpr") = sum(gpr(g), tqpD(g)) ;
g_qpD("gser") = sum(gser(g), tqpD(g)) ;
g_qpD("gtser") = sum(gtser(g), tqpD(g)) ;
g_qpD("goth") = sum(goth(g), tqpD(g)) ;
display g_qpD ;

g_dqpD("gt",d) = sum(gt(g), dqpD(g,d)) ;
g_dqpD("gntc",d) = sum(gntc(g), dqpD(g,d)) ;
g_dqpD("gec",d) = sum(gec(g), dqpD(g,d)) ;
g_dqpD("gl",d) = sum(gl(g), dqpD(g,d)) ;
g_dqpD("gres",d) = sum(gres(g), dqpD(g,d)) ;
g_dqpD("gproc",d) = sum(gproc(g), dqpD(g,d)) ;
g_dqpD("gpr",d) = sum(gpr(g), dqpD(g,d)) ;
g_dqpD("gser",d) = sum(gser(g), dqpD(g,d)) ;
g_dqpD("gtser",d) = sum(gtser(g), dqpD(g,d)) ;
g_dqpD("goth",d) = sum(goth(g), dqpD(g,d)) ;
display g_dqpD ;

parameter g_pPC(gnames) weighted price of a commodity in the region ;
g_pPC("gt") = sum(gt(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
g_pPC("gntc") = sum(gntc(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
g_pPC("gec") = sum(gec(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
g_pPC("gl") = sum(gl(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
g_pPC("gres") = sum(gres(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
g_pPC("gproc") = sum(gproc(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
g_pPC("gpr") = sum(gpr(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
g_pPC("gser") = sum(gser(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
g_pPC("gtser") = sum(gtser(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
g_pPC("goth") = sum(goth(g), sum(h,qp1(g,h)*phPC(g,h))/sum(h,qp1(g,h)));
display phPC, qp1, g_pPC ;


parameter ttqpD    total increase in qp in all activites
          htqpD(h) increase in qpD by household
          bhtqpD   increase in qpD in all beneficiary households
          nbhtqpD  increase in qpD in all non-benef hosueholds
;
htqpD(h) = sum(g, qpD(g,h)) ;
ttqpD = sum((g,h),qpD(g,h)) ;
display ttqpD, htqpD ;
* beneficiaries are the ag households in target regions:
bhtqpD = sum(h$(ht(h)*ha(h)), htqpD(h)) ;
nbhtqpD = sum(h$(not (ht(h)*ha(h))), htqpD(h)) ;
display tqpD, bhtqpD , nbhtqpD ;


parameter bhryD   increase in ry in all beneficiary households
          nbhryD  increase in ry in all non-benef hosueholds    ;

* beneficiaries are the ag households in target regions:
bhryD = sum(h$(ht(h)*ha(h)), ryD(h)) ;
nbhryD = sum(h$(not (ht(h)*ha(h))), ryD(h)) ;
display ryD, bhryD , nbhryD ;


* -----------------------------------------------------------------------------------------------
*    output  - in automatically created file "tableput_NewTan.txt"
* -----------------------------------------------------------------------------------------------
* for best legibility cut and paste into excel, text-to-columns with ; as delimiter
file tablput_NewTan/tablput_NewTan.txt/;
put tablput_NewTan ;


* Table 11.4
put '################ TABLE 11.4 ################' /;
put "Overview of Simulation Assumptions and Impacts on Regional Total Income" /;
put '------------------------------------------------------------' /;
put 'TREATMENT' /;
put 'Productivity increase of' @40';' shock:<5.2 /;
scalar count  ;
count = 0 ;
put 'Treated Goods'   @40 '; '
loop(gt$(not cshrink(gt)),
     count = count + 1
     put gt.tl:<7 ','
     if (count/8 = 1 or count/8 = 2 or count/8 = 3 or count/8 =4,  put / @40 ';' ; );
);
count= 0;
put //;
put 'ASSUMPTIONS ABOUT FACTOR SUPPLY ELASTICITY' /;
put 'Elasticity of land supply' @40'; '  0:<6  /;
put 'Elasticity of ag capital  supply'   @40'; ' %fkse%:<6  /;
put 'Elasticity of livestock cap. supply'   @40'; ' %fvse%:<6  /;
put 'Elasticity of high skill lab supply'   @40'; ' %flse_hi%:<6 /;
put 'Elasticity of low skill lab supply'   @40'; ' %flse_low%:<6 /;
put //;
put 'ASSUMPTIONS ABOUT EXOGENOUS DEMAND FOR PROCESSED RICE' /;
put 'Price elasticity of export demand'   @40'; ' '%xelast%'   /;
put //;
put 'INCOME EFFECT OF IRRIGATION TREATMENT (billion TZS)' /;
put 'Total income Effect' /;
put 'Nominal level' @40 '; ' tyD:<6:2 /;
put '        real'  @40'; ' tryD:<6:2 /;
put '----------------------------------------------------------------'/;
put ////;

put '################ TABLE 11.5 ################' /;
put 'EFFECTS ON PRODUCTION AND PRICE BY CROP GROUP' /;
put '----------------------------------------------------------------' /;
put @35 ';' "Prod " @55 ';' "Price" /;
put @35 ';' "bil TZS" @55 ';' "%" /;
loop(gnames,
     put gnames.te(gnames)  @35'; ' g_qpD(gnames):<6.2  @55 '; ' g_pPC(gnames):<6.2'%' ';' /;
);
put '----------------------------------------------------------------' /;
put ////;


put '################ TABLE 11.6 ################'  /;
* make a set to avoid zeros

PUT "Weighted Average Effect on Nominal Land and Capital Rents"   /;
put '----------------------------------------------------------------' /;
PUT @35 '; ' "Target hh" @55 '; ' "Other hh" /;
put "LAND" /;
put "  Kilombero"  @35 '; ' criPC("fn_kta","kilo"):<6:2'%':<1 @55 ';' criPC("fn_kna","kilo"):<6:2'%':<1  /;
put "  Mvomero"  @35 '; ' criPC("fn_mta","mvom"):<6:2'%':<1 @55 ';' criPC("fn_mna","mvom"):<6:2'%':<1    /;
put "  Others"  @35 '; ' "na" @55 ';' criPC("fn_oa","othv"):<6:2'%':<1 /;
put /;
put "AGRICULTURAL CAPITAL" /;
put "  Kilombero"  @35 '; ' wvPC("fk_ag_kta","kilo"):<6:2'%':<1 @55 ';' wvPC("fk_ag_kna","kilo"):<6:2'%':<1  /;
put "  Mvomero"  @35 '; ' wvPC("fk_ag_mta","mvom"):<6:2'%':<1 @55 ';' wvPC("fk_ag_mna","mvom"):<6:2'%':<1    /;
put "  Others"  @35 '; ' "na" @55 ';' wvPC("fk_ag_oa","othv"):<6:2'%':<1 /;
put /;
put "NON-AGRICULTURAL CAPITAL" /;
put "  Kilombero"  @35 '; ' criPC("fk_o","kilo"):<6:2'%':<1 @55 ';' criPC("fk_o","kilo"):<6:2'%':<1  /;
put "  Mvomero"  @35 '; ' criPC("fk_o","mvom"):<6:2'%':<1 @55 ';' criPC("fk_o","mvom"):<6:2'%':<1    /;
put "  Others"  @35 '; ' criPC("fk_o","othv"):<6:2'%':<1 @55 ';' criPC("fk_o","othv"):<6:2'%':<1 /;

put "LIVESTOCK"   /;
put "  Kilombero"  @35 '; ' wvPC("fv_a","kilo"):<6:2'%':<1 @55 ';' wvPC("fv_a","kilo"):<6:2'%':<1  /;
put "  Mvomero"  @35 '; ' wvPC("fv_a","mvom"):<6:2'%':<1 @55 ';' wvPC("fv_a","mvom"):<6:2'%':<1    /;
put "  Others"  @35 '; ' wvPC("fv_a","othv"):<6:2'%':<1 @55 ';' wvPC("fv_a","othv"):<6:2'%':<1 /;
put '----------------------------------------------------------------' /;
put ////;


put '################ TABLE 11.7 ################'  /;
put "Wage effects at all levels" /;
put '----------------------------------------------------------------' /;
loop(ftd$fl(ftd),
     loop(d,
          put ftd.tl "in " d.tl;
          put @45 ';' wvPC(ftd,d):<6:2 '%':<1 /;
     );
);
loop(ftz$fl(ftz),
     put ftz.tl "at the regional level";
     put @45 ';' wzPC(ftz):<6:2 '%':<1 /;
);
loop(ftw$fl(ftw),
     put ftw.tl "exogenously determined wage";
     put @45 ';' wzPC(ftw):<6:2 '%':<1 /;
);
put /;
put '----------------------------------------------------------------' /;
put ////;

put '################ TABLE 11.8 ################'  /;
put 'Impact of the Irrigation Projects on Nomincal and Real Incomes' /;
put '----------------------------------------------------------------' /;
put "Nominal income change (in billion TZS)" /;
loop(h,
     put h.tl 'nominal' ;
     put @45';' yD(h):<6:2 /;
);
put/;
put "CPI" /;
put "Note: book table only reports one CPI for per district"   /;
loop(h,
     put h.tl ;
     put @14 'cpi increase in %'  @45';' cpiPC(h):6:2 '%':<1 /;
);
put/;
put "Real income change (in Billion TZS):" /;
loop(h,
     put h.tl ;
     put @14 'real'  @45';' ryD(h):<6:2/;
);
put '----------------------------------------------------------------' /;
put ////;

put '################ TABLE 11.9 (one column) ################'  /;
put '----------------------------------------------------------------' /;
put 'ASSUMPTIONS ABOUT FACTOR SUPPLY ELASTICITY' /;
put 'Elasticity of ag capital  supply'   @40'; ' %fkse%:<6  /;
put 'Elasticity of livestock cap. supply'   @40'; ' %fvse%:<6  /;
put 'Elasticity of high skill lab supply'   @40'; ' %flse_hi%:<6 /;
put 'Elasticity of low skill lab supply'   @40'; ' %flse_low%:<6 /;
put //;
put 'TOTAL PRODUCTION EFFECT (billion TZS)' /;
put 'In all of Morogoro, of which:' @40'; '       ttqpD:<6:2    /;
put '     All Beneficiary households' @40'; '     bhtqpD:<6:2   /;
put '     All Non-Beneficiary households' @40'; ' nbhtqpD:<6:2  /;
put //;
put 'TOTAL INCOME EFFECT (billion TZS)' /;
put 'Nominal income in all of Morogoro:' @40'; '      tyD:<6:2 /;
put 'Real Income in all of Morogoro, of which:' @40'; ' tryD:<6:2 /;
put '     All Beneficiary households' @40'; '     bhryD:<6:2   /;
put '     All Non-Beneficiary households' @40'; ' nbhryD:<6:2  /;
put '----------------------------------------------------------------' /;
put ////;


