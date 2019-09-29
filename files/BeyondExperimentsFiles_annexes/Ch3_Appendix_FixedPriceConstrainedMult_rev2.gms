$title Mini constrained SAM multiplier model
* This model serves to fill in both tables 3.3 and 3.4 (fixed-price and constrained multipliers)

Option limrow=10, limcol=50
OPTION DECIMALS=2 ;

* The i set has all th accounts in the SAM
set i all accounts in the economy
/ A_AG1    Agriculture
  A_NAG1   Non-Agricultural Activities
  C_AG1    Agriculture
  C_NAG1   Non-Agricultural Activities
  LABO1    Labor
  CAPI1    Capital
  INC1     Income
  A_AG2    Agriculture
  A_NAG2   Non-Agricultural Activities
  C_AG2    Agriculture
  C_NAG2   Non-Agricultural Activities
  LABO2    Labor
  CAPI2    Capital
  INC2     Income
* market accounts:
  AGC      ag commodity market
  nonagc   non-ag commodity market
  LABOM    labor factor market
  ROW      Rest of the World
/
$phantom null
* The following subsets decide which accounts are endogenous, which are exogenous
* as well as constrained/unconstrained
iend(i)      endogenous accounts / A_AG1, A_NAG1, C_AG1, C_NAG1, LABO1, CAPI1, INC1,
                                   A_AG2, A_NAG2, C_AG2, C_NAG2, LABO2, CAPI2, INC2, agc, nonagc, labom /
iexo(i)      exogenous accounts / ROW /
f(iend)      factors owned /LABO1, CAPI1, LABO2, CAPI2/
* Note: to unconstrain the A_AG1 account, remove it from "icr" and put it in "iucr".
* the "null" account is only there to avoid GAMS errors.
icr(iend)    constrained accounts / A_AG1, null /
iucr(iend)   unconsrained accounts / A_NAG1, C_AG1, C_NAG1, LABO1, CAPI1, INC1,
                                     A_AG2, A_NAG2, LABO2, C_AG2, C_NAG2, CAPI2, INC2, agc, nonagc, labom /
;

alias (i,j);
alias (iend,jend) ;
alias (iexo,jexo) ;
alias (f,ff);

;
* READ the SAM FROM EXCEL:
parameter sam(i,j) the sam read from excel
$call "gdxxrw input=Ch3_LEWIE_Inputs.xlsx output=Ch3_data_fromSAM.gdx par=sam rng=LEWIE_FromSAM!A1:S19"
$gdxin Ch3_data_fromSAM.gdx
$load sam
$gdxin
display sam ;


*######################## PARAMETER DECLARATION ######################

 PARAMETERS

*## READ IN FOR INITIALIZATION OF VARIABLES
 Y0(iend)         SAM ENDOGENOUS ROW TOTALS
 EXOG0(iend)      SAM EXOGENOUS COLUMNS
 SAMIO(iend,jend) SAM COEFFICIENT MATRIX
 RGDP0              REAL GDP
 ;
*######################### PARAMETER ASSIGNMENT ######################
*############ SPECIFY PARAMETERS FROM TABLE VALUES ###################

*## CREATE SAM COEFFICIENT MATRIX
 EXOG0(iend)      = sum(jexo,SAM(iend,jexo)) ;
 Y0(iend)         = SUM(j, SAM(iend,j)) ;
 DISPLAY Y0, EXOG0 ;
 SAMIO(iend,jend)$Y0(jend) = SAM(iend,jend)/Y0(jend) ;
 RGDP0              = SUM(f, Y0(f)) ;

 DISPLAY Y0 ;
 DISPLAY RGDP0 ;
 DISPLAY SAMIO ;
*Create fixed-price multiplier by substituting marginal for average budget shares
* According to the SAMIO parameter (column input-output shares),
* the poor a/n nonpoor a/n shares are
* 52/22/40/37
* and the marginal poor and nonpoor shares are (arbitrarily):
* 55/22/42/39
* Erratum: these shares do not correspond to table 3.2 as printed in the book.
* Nevertheless, they are consistent with all other printed results and with with the SAM.
* Table 3.2 that contains outdated numbers (which were arbitrary)
* the (also arbitrary) numbers we ended up using are the following:
SAMIO("agc","INC1")=0.55 ;
SAMIO("nonagc","INC1")=0.22 ;
SAMIO("agc","INC2")=0.42 ;
SAMIO("nonagc","INC2")=0.39 ;

 parameter checkio(jend) ;
 checkio(jend) = sum(iend,samio(iend,jend));
 display checkio ;


*#####################################################################
 VARIABLES
*#################### VARIABLE DECLARATION ##########################

   Y(iend)      SAM ROW TOTALS
   EXOG(iend)   SAM EXOGENOUS ACCOUNT TOTALS
   RGDP           REAL GROSS DOMESTIC PRODUCT
   MAT(iend,jend) SAM entries in the modeling
 ;
*################## VARIABLE INITIALIZATION #########################
*## USE INITIAL VALUES OF VARIABLES (FROM PARAMETER SPECIFICATION)

 Y.L(iend)     =  Y0(iend)  ;
 EXOG.L(iend)  =  EXOG0(iend) ;
 RGDP.L          =  RGDP0 ;
 MAT.l(iend,jend) = SAM(iend,jend) ;
 DISPLAY Y.L, EXOG.L, RGDP.L , MAT.l;

*###################### END VARIABLE SPECIFICATION ###################

*#####################################################################
 EQUATIONS
*#################### EQUATION DECLARATION ###########################

   YEQ(iend)        ENDOGENOUS INCOMES
   GDPR               REAL GDP
   SAMENTRIES(iend,jend) Sam entries
         ;

*######################## EQUATION ASSIGNMENT  #######################
 YEQ(iend)..    Y(iend)  =E= SUM(jend, samio(iend,jend)*Y(jend))
                                 +EXOG(iend) ;

 GDPR..                RGDP  =E= SUM(f, Y(f)) ;

 SAMENTRIES(iend,jend)..  MAT(iend,jend) =E= samio(iend,jend)*Y(jend) ;


*#### ADDITIONAL RESTRICTIONS CORRESPONDING TO EQUATIONS

*#### FIX EXOGENOUS DEMAND BY SECTOR
 EXOG.FX(iucr) = EXOG.L(iucr) ;
 Y.FX(icr)     = Y.L(icr) ;

*########################### END OF MODEL ############################

*#### MODEL SOLVE STATEMENTS

 OPTIONS ITERLIM=1000,LIMROW=1,LIMCOL=0, SOLPRINT=ON;
*USE SOLPRINT=OFF TO TURN OFF STANDARD SOLUTION PRINTOUT


 MODEL sammult /YEQ, GDPR, SAMENTRIES/ ;

 SOLVE sammult MAXIMIZING RGDP USING NLP;

 OPTION DECIMALS=2 ;

*#### SET UP TABLES TO REPORT OUTPUT

 PARAMETER Y1(iend)      BASE ENDOGENOUS INCOME ;
 PARAMETER RGDP1           BASE REAL GDP ;
 PARAMETER EXOG1(iend)   BASE EXOGENOUS INCOME ;
 Parameter MAT1(iend,jend) Base matrix entries ;

 Y1(iend)              = Y.L(iend) ;
 RGDP1                   = RGDP.L ;
 EXOG1(iend)           = EXOG.L(iend) ;
 MAT1(iend,jend)          = MAT.l(iend,jend) ;

*#### DISPLAY OUTPUT
 DISPLAY EXOG1 ;
 DISPLAY Y1 ;
 DISPLAY RGDP1 ;
 Display MAT1;

*#############################
*## SAM MULTIPLIER EXPERIMENTS
*#############################

* SAMEXP.GMS

*## INCREASE EXOG.FX("INC1") TO RAISE POOR HOUSEHOLD EXOG INCOME
*## INCREASE Y.FX("AG1") TO LOOSEN POOR HOUSEHOLD AG PRODUCTION CONSTRAINT
*## INCREASE Y.FX("AG1") AND Y.FX("AG2") TO LOOSEN BOTH HOUSEHOLDS' AG
*##   PRODUCTION CONSTRAINTS

 EXOG.FX("INC1")   =   EXOG.L("INC1")+1 ;
* Y.FX("AG1")   =   Y.L("AG1")+1 ;

*########################## END OF MODIFICATIONS ############################

*#### MODEL SOLVE STATEMENTS

 OPTIONS ITERLIM=1000,LIMROW=1,LIMCOL=0, SOLPRINT=ON;


*USE SOLPRINT=OFF TO TURN OFF STANDARD SOLUTION PRINTOUT
*RESOLVE MODEL STARTING AT BASE
 SOLVE sammult MAXIMIZING RGDP USING NLP;

 OPTION DECIMALS=2 ;

 display MAT.l;

*#### SET UP TABLES TO REPORT OUTPUT
 PARAMETER Y2(iend)      ENDOGENOUS INCOME ABSOLUTE CHANGE ;
 PARAMETER RGDP2           REAL GDP ABSOLUTE CHANGE ;
 PARAMETER EXOG2(iend)   EXOGENOUS INCOME ABSOLUTE CHANGE ;
 Parameter MAT2(iend,jend)   Absolute change in Matrix entries ;


 Y2(iend)                   = Y.L(iend) ;
 RGDP2                      = RGDP.L ;
 EXOG2(iend)                = EXOG.L(iend) ;
 MAT2(iend,jend)            = MAT.l(iend,jend) ;
 Y2(iend)                   = Y2(iend) - Y1(iend) ;
 RGDP2                      = RGDP2 - RGDP1 ;
 EXOG2(iend)                = EXOG2(iend) - EXOG1(iend) ;
 MAT2(iend,jend)            = MAT2(iend,jend) - MAT1(iend,jend) ;

*#### DISPLAY BASE SOLUTION AND SAM MULTIPLIER EXPERIMENT SOLUTIONS

 DISPLAY EXOG1, EXOG2 ;
* The parameter Y2 (change in account income) is where we read
* values for tables 3.3 and 3.4 in the book:
 DISPLAY Y1, Y2 ;
 DISPLAY RGDP1, RGDP2 ;
 DISPLAY MAT1,MAT2 ;

* add the effect on imports from ROW account (the very last row of table 3.4, rowdem2T):
parameter rowio(i) io for demand from row account
          rowdem2(i) additional demand from row
          rowdem2T  total additional demand from row;
rowio(i)       = sam("row",i)/sum(j,sam(j,i));
rowdem2(iend)     = rowio(iend)*y2(iend) ;
rowdem2T       = sum(i,rowdem2(i));

display rowio, rowdem2, rowdem2T ;
