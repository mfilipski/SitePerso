* This model makes table 10.2 of Chapter 10 in Beyond Experiments
* go to line 772 to choose the experiment
* the last displays give the values in table 10.2

$ontext
May 2011
*********
This model was written by Mateusz Filipski in the spring of 2011
It was designed to evaluate impacts of cash transfers and input subsidies on the rural sector
Household groups are defined by their eligibility criteria

$offtext

***** GAMS OPTIONS TO SET ********************
* allows for end of line comments (with "!!" characters) and inline comments
$oneolcom
$oninline
$onsymlist
$onsymxref
* makes longer outputs
option limcol = 40;
option limrow = 40;
option decimals = 2;


******************************************************************************
************************ DEFINE SETS *****************************************
******************************************************************************
set ac all accounts
  /
* Households
NUH  Non-Farm Ineligible Households
SUH  Small Ineligible Households
LUH  Large Ineligible Households
ECT  Households Eligible for Cash Transfer
EIS  Households Eligible for Inpur Subsidy
EBO  Households Eligible for Both

* Activity producing ### comodity as performed by household ###:
AMAIZE-SUH   Maize activity by SUH households
AMAIZE-LUH   Maize activity by LUH households
AMAIZE-ECT   Maize activity by ECT households
AMAIZE-EIS   Maize activity by EIS households
AMAIZE-EBO   Maize activity by EBO households
ATUBR-SUH    Tuber activity by SUH households
ATUBR-LUH    Tuber activity by LUH households
ATUBR-ECT    Tuber activity by ETC households
ATUBR-EIS    Tuber activity by EIS households
ATUBR-EBO    Tuber activity by EBO households
AOTHR-SUH    Other Foods activity by SUH households
AOTHR-LUH    Other Foods activity by LUH households
AOTHR-ECT    Other Foods activity by ECT households
AOTHR-EIS    Other Foods activity by EIS households
AOTHR-EBO    Other Foods activity by NUH households
ATOBA-SUH    Tobacco activity by SUH households
ATOBA-LUH    Tobacco activity by LUH households
ATOBA-ECT    Tobacco activity by ECT households
ATOBA-EIS    Tobacco activity by EIS households
ATOBA-EBO    Tobacco activity by EBO households
ATREES-SUH   Tree-crop activity by SUH households
ATREES-LUH   Tree-crop activity by LUH households
ATREES-ECT   Tree-crop activity by ECT households
ATREES-EIS   Tree-crop activity by EIS households
ATREES-EBO   Tree-crop activity by EBO households
ALVST-SUH    Livestock activity by SUH households
ALVST-LUH    Livestock activity by LUH households
ALVST-ECT    Livestock activity by ECT households
ALVST-EIS    Livestock activity by EIS households
ALVST-EBO    Livestock activity by EBO households


* Goods
MAIZE  Maize
TUBR   Tubers
OTHR   Other foods
TOBA   TOBAcco
TREES  All sorts of permanent crops
LVST   Livestock
MKT    Market good (money-metric)


*Factors
LABO     Labor (own)
CAPI     Capital
LAND     Land
LABH     Labor (hired)
CINPUT   Crop inputs
LINPUT   Livestock inputs
TIME     Labor (own or hired person-hours)

* Rest of the world
ROW  Rest of the World

* Define activity groups - ie nodes of the CET function
* This deserves an explanation: each household type has a certain amount of land (fixed)
* that can be allocated between crops, but some reallocations are easier than others
* this is determined by the 3-level CET function, as follows:
*                             All Land (top node)
*                          /                      \
*                   medium node               permanent crops (tree crops)
*                 /            \
*        field crops           pasture
*        /      |    \
*     Maize  Other   Tubers
*

  AGTOP-SUH  top-node (all land: fieldcrops pasture or tree-crops)
  AGMED-SUH  medium-node (land in field crops or pasture)
  AGLOW-SUH  low-node  (just the 2 food crops)

  AGTOP-ECT  top-node (all land: fieldcrops pasture or tree-crops)
  AGMED-ECT  medium-node (land in field crops or pasture)
  AGLOW-ECT  low-node  (just the 2 food crops)

  AGTOP-LUH  top-node (all land: fieldcrops pasture or tree-crops)
  AGMED-LUH  medium-node (land in field crops or pasture
  AGLOW-LUH  low-node  (just the 2 food crops)

  AGTOP-EIS   top-node (all land: fieldcrops pasture or tree-crops)
  AGMED-EIS   medium-node (land in field crops or pasture
  AGLOW-EIS   low-node  (just the 2 food crops)

  AGTOP-EBO  top-node (all land: fieldcrops pasture or tree-crops)
  AGMED-EBO  medium-node (land in field crops or pasture
  AGLOW-EBO  low-node  (just the 2 food crops)
/


set
* A bunch of useful subsets:
i(ac) goods and factors
 /MAIZE, TUBR, OTHR, TOBA, TREES, LVST, MKT, TIME, CAPI, LAND, CINPUT, LINPUT /

gfnft(i) all goods and factors except land and capital (fixed ones) nor time
 /MAIZE, TUBR, OTHR, TOBA, TREES, LVST, MKT, CINPUT, LINPUT /

gfnfti(i) all goods and factors except land and capital (fixed ones) nor time nor cinput
 /MAIZE, TUBR, OTHR, TOBA, TREES, LVST, MKT /

inp(i) two types of inputs
 /CINPUT, LINPUT /

nfi(i) all goods and factors except land and capital (fixed ones)
 /MAIZE, TUBR, OTHR, TOBA, TREES, LVST, MKT, TIME, CINPUT, LINPUT /

gfnl(i) all goods and factors except land
 /MAIZE, TUBR, OTHR, TOBA, TREES, LVST, MKT, TIME, CAPI, CINPUT, LINPUT /

g(i) goods
 /MAIZE, TUBR, OTHR, TOBA, TREES, LVST, MKT /

ag(ac) activities and groups of activities (or "nodes")
/ AMAIZE-SUH, ATUBR-SUH, AOTHR-SUH
, ATOBA-SUH
, ATREES-SUH, ALVST-SUH
, AMAIZE-LUH, ATUBR-LUH, AOTHR-LUH, ATOBA-LUH, ATREES-LUH, ALVST-LUH
, AMAIZE-ECT, ATUBR-ECT, AOTHR-ECT, ATOBA-ECT ,ATREES-ECT, ALVST-ECT
, AMAIZE-EIS ,ATUBR-EIS, AOTHR-EIS, ATOBA-EIS, ATREES-EIS, ALVST-EIS
, AMAIZE-EBO, ATUBR-EBO, AOTHR-EBO, ATOBA-EBO, ATREES-EBO, ALVST-EBO

, AGTOP-SUH,  AGMED-SUH, AGLOW-SUH
, AGTOP-LUH,  AGMED-LUH, AGLOW-LUH
, AGTOP-ECT, AGMED-ECT, AGLOW-ECT
, AGTOP-EIS,  AGMED-EIS, AGLOW-EIS
, AGTOP-EBO,  AGMED-EBO, AGLOW-EBO
/

a(ag) activities that actually produce something (ie not groups)
 / AMAIZE-SUH, ATUBR-SUH, AOTHR-SUH
, ATOBA-SUH
, ATREES-SUH, ALVST-SUH
, AMAIZE-LUH, ATUBR-LUH, AOTHR-LUH, ATOBA-LUH, ATREES-LUH, ALVST-LUH
, AMAIZE-ECT, ATUBR-ECT, AOTHR-ECT, ATOBA-ECT ,ATREES-ECT, ALVST-ECT
, AMAIZE-EIS ,ATUBR-EIS, AOTHR-EIS, ATOBA-EIS, ATREES-EIS, ALVST-EIS
, AMAIZE-EBO, ATUBR-EBO, AOTHR-EBO, ATOBA-EBO, ATREES-EBO, ALVST-EBO
/

nod(ag) groups of activities  (or "nodes")
 / AGTOP-SUH,  AGMED-SUH, AGLOW-SUH
, AGTOP-LUH,  AGMED-LUH, AGLOW-LUH
, AGTOP-ECT, AGMED-ECT, AGLOW-ECT
, AGTOP-EIS,  AGMED-EIS, AGLOW-EIS
, AGTOP-EBO,  AGMED-EBO, AGLOW-EBO /

nod1(ag)
 /AGTOP-SUH, AGTOP-LUH, AGTOP-ECT, AGTOP-EIS, AGTOP-EBO/

nod2(ag)
 /AGMED-SUH, AGMED-LUH, AGMED-ECT, AGMED-EIS, AGMED-EBO/

nod3(ag)
 /AGLOW-SUH, AGLOW-LUH,  AGLOW-ECT,  AGLOW-EIS,  AGLOW-EBO/

a1(ag) activities or groups of activities in the top node
 / ATREES-SUH, AGMED-SUH
, ATREES-LUH, AGMED-LUH
, ATREES-ECT, AGMED-ECT
, ATREES-EIS, AGMED-EIS
, ATREES-EBO, AGMED-EBO/

a2(ag) activities or groups of activities in the median node
 /
* note: for Malawi, there is land in livestock.  But SUH makes no tobacco
ALVST-SUH, ALVST-LUH, ALVST-ECT
, ALVST-EIS, ALVST-EBO
, ATOBA-SUH
, AGLOW-SUH
, ATOBA-LUH
, AGLOW-LUH
, AGLOW-ECT
, ATOBA-EIS
, AGLOW-EIS
, AGLOW-EBO
/

a3(ag) activities or groups of activities in the low node
 / AMAIZE-SUH, AOTHR-SUH
, AMAIZE-LUH, AOTHR-LUH
, AMAIZE-ECT, AOTHR-ECT
, AMAIZE-EIS, AOTHR-EIS
, AMAIZE-EBO
, AOTHR-EBO
, ATUBR-SUH
, ATUBR-LUH
, ATUBR-ECT
, ATUBR-EIS
, ATUBR-EBO/

gp(i) produced goods for share equation
 /MAIZE, TUBR, OTHR, TOBA, TREES, LVST /

gc(i) consumed goods for share equation
* tobacco, TREE crops (coffee, cocoa = cash crops) are not there
 /MAIZE, TUBR, OTHR, LVST /

f(i) factors
 / TIME, CAPI, LAND, CINPUT, LINPUT /

fnf(i) factors non-fixed
 / TIME, CINPUT, LINPUT /

ff(i) fixed factors
 / CAPI, LAND /

t(i) tradeable factors
 / TIME, CINPUT, LINPUT /

tim(i) time factor
 / TIME /

l(i) the land factor
 / LAND /

h(ac) all households
 /NUH, SUH, LUH, ECT, EIS, EBO/

hp(h) households that produce stuff (farms)
 /SUH, LUH, ECT, EIS, EBO/
;

alias(g,gg)
     (i,j)
     (ac, aca)
     (a,aa)
     (ag,aga)
     (a1,a1a)
     (a2,a2a)
     (a3,a3a)
     (h,hh);

* mapping sets: used to create mappings of activities and the households that do them
sets
maf(a,i) mapping: activity a uses f as a factor
mag(a,i) mapping: activity a makes good g
mha(h,ag) mapping: household h does activity a
mna(nod,ag) mapping: activity ag is in node nod
mhgp(h,i) mapping: household h is involved in the production of good gp
;

* mhgp was only created to exclude some household from the SHSOLD equation -
mhgp(h,i)$(hp(h)*gp(i))=yes ;
mhgp("ECT","TOBA") = no;
mhgp("EBO","TOBA") = no;

* what household does what activity
mha("SUH","AMAIZE-SUH") = yes;
mha("SUH","ATUBR-SUH") = yes;
mha("SUH","AOTHR-SUH") = yes;
mha("SUH","ATOBA-SUH") = yes;
mha("SUH","aTREES-SUH") = yes;
mha("SUH","alvst-SUH") = yes;
mha("SUH","aglow-SUH") = yes;
mha("SUH","agmed-SUH") = yes;
mha("SUH","agtop-SUH") = yes;

mha("LUH","AMAIZE-LUH") = yes;
mha("LUH","ATUBR-LUH") = yes;
mha("LUH","AOTHR-LUH") = yes;
mha("LUH","ATOBA-LUH") = yes;
mha("LUH","aTREES-LUH") = yes;
mha("LUH","alvst-LUH") = yes;
mha("LUH","aglow-LUH") = yes;
mha("LUH","agmed-LUH") = yes;
mha("LUH","agtop-LUH") = yes;

mha("ECT","AMAIZE-ECT") = yes;
mha("ECT","ATUBR-ECT") = yes;
mha("ECT","AOTHR-ECT") = yes;
mha("ECT","ATOBA-ECT") = yes;
mha("ECT","aTREES-ECT") = yes;
mha("ECT","alvst-ECT") = yes;
mha("ECT","aglow-ECT") = yes;
mha("ECT","agmed-ECT") = yes;
mha("ECT","agtop-ECT") = yes;

mha("EIS","AMAIZE-EIS") = yes;
mha("EIS","ATUBR-EIS") = yes;
mha("EIS","AOTHR-EIS") = yes;
mha("EIS","ATOBA-EIS") = yes;
mha("EIS","aTREES-EIS") = yes;
mha("EIS","alvst-EIS") = yes;
mha("EIS","aglow-EIS") = yes;
mha("EIS","agmed-EIS") = yes;
mha("EIS","agtop-EIS") = yes;

mha("EBO","AMAIZE-EBO") = yes;
mha("EBO","ATUBR-EBO") = yes;
mha("EBO","AOTHR-EBO") = yes;
mha("EBO","ATOBA-EBO") = yes;
mha("EBO","aTREES-EBO") = yes;
mha("EBO","alvst-EBO") = yes;
mha("EBO","aglow-EBO") = yes;
mha("EBO","agmed-EBO") = yes;
mha("EBO","agtop-EBO") = yes;

mna("AGTOP-SUH",ag)$(a1(ag)*mha("SUH",ag))= yes;
mna("AGMED-SUH",ag)$(a2(ag)*mha("SUH",ag))= yes;
mna("AGLOW-SUH",ag)$(a3(ag)*mha("SUH",ag))= yes;

mna("AGTOP-LUH",ag)$(a1(ag)*mha("LUH",ag))= yes;
mna("AGMED-LUH",ag)$(a2(ag)*mha("LUH",ag))= yes;
mna("AGLOW-LUH",ag)$(a3(ag)*mha("LUH",ag))= yes;

mna("AGTOP-ECT",ag)$(a1(ag)*mha("ECT",ag))= yes;
mna("AGMED-ECT",ag)$(a2(ag)*mha("ECT",ag))= yes;
mna("AGLOW-ECT",ag)$(a3(ag)*mha("ECT",ag))= yes;

mna("AGTOP-EIS",ag)$(a1(ag)*mha("EIS",ag))= yes;
mna("AGMED-EIS",ag)$(a2(ag)*mha("EIS",ag))= yes;
mna("AGLOW-EIS",ag)$(a3(ag)*mha("EIS",ag))= yes;

mna("AGTOP-EBO",ag)$(a1(ag)*mha("EBO",ag))= yes;
mna("AGMED-EBO",ag)$(a2(ag)*mha("EBO",ag))= yes;
mna("AGLOW-EBO",ag)$(a3(ag)*mha("EBO",ag))= yes;


******************************************************************************
************************ READ IN DATA ****************************************
******************************************************************************
parameters
         bigsam(ac,aca) sam matrix
         sam(ac,aca) sam matrix
;
* this CALL statement should be starred out for speed, but only after the first run, once the GDX file has been made
* MUST be unstarred if any change occurs to the matrix
* MUST be unstarred the first time you run the program on a new computer, to make the gdx file
$CALL 'gdxxrw Ch10_Malawi_SAM.xlsx index=SAM_Malawi!a56:e57'    !! this is run in compilation phase


$gdxin Ch10_Malawi_SAM.gdx
$load bigsam
$gdxin
display bigsam ;

sam(ac,aca)=bigsam(ac,aca);
display bigsam, sam;

* re-scale by $1000 to make things more legible
* Malawi Kwacha in 2004 is $1= 108.9 according to Penn Tables
sam(ac,aca) = sam(ac,aca)/(108.9*1000) ;   !! convert to nominal 2004 dollars
* That was converted to 2004 dollars - now convert it to 2005 dollars
sam(ac,aca) = sam(ac,aca)*1.03;

* this assigns values to two mapping sets that were declared in the $include file
* maf is the mapping of factors used by an activity
* mag is the mapping of goods produced by an activity (for us, only once comodity per activity)
maf(a,f)$sam(f,a) = yes;
mag(a,gp)$sam(a,gp) = yes;

display maf, mag, mha, mna, a1, a2, a3;



******************************************************************************
******************************************************************************
************************ MODEL STARTS ****************************************
******************************************************************************
******************************************************************************

parameters
* production function
  bet(a) shifter in the production function of activity a
  beta(a,i) factor share production function of activity a
* consumption function - no need for a shifter, they'll all be 1 anyways
  alpha(h,g) coeff in the consumption func
  endow(h,i) endowments (capital land and time)
  yexog(h) exogenous income of households (remittances etc.)
* endowments of land need to work differently from other endowments, because of CET
  lhold(h,a) land holding the household devotes to activity a

* CET parameters
  gamma(h,ag) share parameters in CET - they differ by hh
*  rho exponent in CET - one for each node
  rho1 exponent in CET in top node
  rho2 exponent in CET in med node
  rho3 exponent in CET in low node
  sig1(hp) Sigma at node 1 of the CET function
  sig2(hp) Sigma at node 1 of the CET function
  sig3(hp) Sigma at node 1 of the CET function

* Input subsidy
  isub(h,i) input subsidy (percentage the buyer pays) for a household
  isuba(a,i) input subsidy for the activities the household makes
;

positive variables
  QB(h,i) bought quantities
  QS(h,i) sold quantities
  QM(i) imported quantities of goods
  QE(i) exported quantities of goods
  QP(a) produced quantities by an activity - one good per activity
  QC(h,i) consumed quantities by household

* prices and wages
  P(i) prices of goods in the economy
  R(ag,i) rents in the economy by activity
  WFDIST(ag,i) differentials from factor rents
  FD(ag,i) factor demand activity a for factor i
;

variables
  LD(i) land demanded for a good
  TLS total land supply
  TLD total land demand (just for checking)
  Y(h) shadow income of household
  TY  total shadow income
  MS(h,i) maketed surplus (sold-bought)
;


* Initialization of all variables
* **********************************
P.l(i) = 1 ;
R.l(ag,ff) = 1 ;
WFDIST.l(ag,ff) = 1 ;

QC.l(h,i)$g(i)=sam(i,h);
QP.l(a)=sum(i,sam(a,i));
FD.l(a,ff) = sam(ff,a);
FD.l(a,l) = sam(l,a);
FD.l(a,"TIME") = sam("LABO",a)+sam("LABH",a); !!traded factors might face TC's.
FD.l(a,"CINPUT") = sam("CINPUT",a);
FD.l(a,"LINPUT") = sam("LINPUT",a);
FD.l(nod,"land") = sum(ag$mna(nod,ag), FD.l(ag,"land"));
FD.l(nod,"land") = sum(ag$mna(nod,ag), FD.l(ag,"land"));
FD.l(nod,"land") = sum(ag$mna(nod,ag), FD.l(ag,"land"));

endow(h,i)$sam(h,i) = sam(h,i);
endow(h,"TIME")$sam(h,"LABH") = sam(h,"LABO")+sam(h,"LABH");
yexog(h) = sam(h,"ROW");
lhold(h,a)$mha(h,a) = FD.l(a,"land");
TLS.l(hp) = sum(a$mha(hp,a),lhold(hp,a));


* MS is not used in the formal model, but it's useful for setting the base level
MS.l(h,nfi) = sum(a$(mha(h,a)*mag(a,nfi)),QP.l(a))+endow(h,nfi)-QC.l(h,nfi)-sum(a$mha(h,a),FD.l(a,nfi));

QB.l(h,i) = -(min(MS.l(h,i),0));
QS.l(h,i) = max(0,MS.l(h,i));

display MS.l;
MS.l(h,nfi) = round(MS.l(h,nfi),2);
QB.l(h,nfi) = round(QB.l(h,nfi),2);
QS.l(h,nfi) = round(QS.l(h,nfi),2);
display MS.l;

QM.l(i)=sum(h,QB.l(h,i))-sum(h,QS.l(h,i));
QM.l(i)=max(QM.l(i),0);
QE.l(i)=sum(h,QS.l(h,i))-sum(h,QB.l(h,i));
QE.l(i)=max(QE.l(i),0);

Y.l(h) = endow(h,"TIME")*P.l("TIME")
       +sum(ff,sum(a$mha(h,a),FD.l(a,ff)*R.l(a,ff)*WFDIST.l(a,ff)))  !! shadow value of capital
       +yexog(h) ;

TY.l = sum(h,Y.l(h));

* Budget for inputs
parameter inpbgt(h,inp) budget for inputs
          inpbgta(a,inp) budget for input from activitites
          inpbgtsh(a,inp) share of the input budget in an activity
          ibshareY(h);
inpbgt(h,inp) = QB.l(h,inp) ;
inpbgta(a,inp) = FD.l(a,inp) ;
inpbgtsh(a,inp) = inpbgta(a,inp)/sum(h$mha(h,a),inpbgt(h,inp)) ;
ibshareY(h)=inpbgt(h,"cinput")/Y.l(h);
display inpbgta, inpbgt, inpbgtsh, ibshareY, Y.l;

parameter inpbgta0(a,inp) original budget;
display inpbgta ;
inpbgta0(a,inp) = inpbgta(a,inp);



* Set CET parameter values (No choice but to assume values).
*sig1(hp) = -0.1 ;
*sig2(hp) = -0.15 ;
*sig3(hp) = -0.20 ;

sig1(hp) = -0.05 ;
sig2(hp) = -0.1 ;
sig3(hp) = -0.15 ;


* now the rhos - that's the classic formula
rho1(hp) = (sig1(hp)-1)/sig1(hp);
rho2(hp) = (sig2(hp)-1)/sig2(hp);
rho3(hp) = (sig3(hp)-1)/sig3(hp);
display sig1, sig2, sig3, rho1, rho2, rho3;

gamma(h,ag)$(mha(h,ag)*a1(ag)) = (sum(nod$mna(nod,ag),FD.l(nod,"land")))**(rho1(h)-1)*FD.l(ag,"land")**(1-rho1(h));
gamma(h,ag)$(mha(h,ag)*a2(ag)) = (sum(nod$mna(nod,ag),FD.l(nod,"land")))**(rho2(h)-1)*FD.l(ag,"land")**(1-rho2(h));
gamma(h,ag)$(mha(h,ag)*a3(ag)) = (sum(nod$mna(nod,ag),FD.l(nod,"land")))**(rho3(h)-1)*FD.l(ag,"land")**(1-rho3(h));
display gamma;

* initialise production function parameters with all the right QPs and FDs
beta(a,fnf)$QP.l(a) = FD.l(a,fnf)*P.l(fnf)/(QP.l(a)*sum(g$mag(a,g),P.l(g)));
beta(a,l)$QP.l(a) = FD.l(a,l)*R.l(a,l)/(QP.l(a)*sum(g$mag(a,g),P.l(g)));
beta(a,ff)$QP.l(a) = FD.l(a,ff)*R.l(a,ff)/(QP.l(a)*sum(g$mag(a,g),P.l(g)));

alpha(h,g) = QC.l(h,g)*P.l(g)/Y.l(h);
bet(a) = QP.l(a)/prod(f,FD.l(a,f)**beta(a,f));


display P.l, R.l, WFDIST.l, QC.l, MS.l, QS.l, QB.l, QP.l, FD.l, Y.l, TY.l ;
display endow, yexog ;

isub(h,i) = 1;
isuba(a,i) = 1;




* Equations start here :
************************
************************

EQUATIONS
*Consumption Block
EQ_CDEM(h,g) consumption demand for goods
EQ_Y(h)   shadow income equation
EQ_TY    total shadow income of the economy - what we maximise

*Production Block
EQ_FDEM1(a,i) demand of activity a for factor f
EQ_PROD(a) production function in activity a

*Market clearing
EQ_MKTHH(h,i) market clearing for each household
EQ_MKTE(i) market clearing for the economy

* Total demands and supplies
EQ_TLD(h) computes the "linear" demand for land (will be different from CET demand for land)
EQ_TLS(h) computes the total land supply and fixes it
EQ_LDEM(gp) computes land demand by produced good

EQ_CET1(h) CET function at the top level
EQ_CET2(h) CET function at the medium level
EQ_CET3(h) CET function at the low level
EQ_CETR1(h,a1,a1a) CET function that sets the optimal rent ratio at the top level
EQ_CETR2(h,a2,a2a) CET function that sets the optimal rent ratio at the med level
EQ_CETR3(h,a3,a3a) CET function that sets the optimal rent ratio at the low level

EQ_LSHARE(ag,nod) Land share in an activity or group
EQ_LRENT1(nod) Land rent at the top node
EQ_LRENT2(nod) Land rent at the medium node
EQ_LRENT3(nod) Land rent at the lowest node

EQ_SELBUY(h,i)  household is either net seller or net buyer - not both
;


** MODEL STATEMENT
*Consumption Block
*------------------
EQ_CDEM(h,g)..   QC(h,g) =E= alpha(h,g)*Y(h)/P(g) ;

EQ_Y(h)..        Y(h) =E= endow(h,"TIME")*P("TIME")
                 +sum(ff,sum(a$mha(h,a),FD(a,ff)*R(a,ff)*WFDIST(a,ff)))  !! shadow value of capital
                 +yexog(h) ;

EQ_TY..          TY =E= sum(h,Y(h));

*Production Block
*------------------
EQ_FDEM1(a,i)$(f(i))..   FD(a,i)*((isuba(a,i)*P(i))$fnf(i) + (R(a,i)*WFDIST(a,i))$ff(i))
                             =E= sum(g$mag(a,g),P(g))*QP(a)*beta(a,i) ;

EQ_PROD(a)..     QP(a) =E= bet(a)*prod(f,FD(a,f)**beta(a,f));



*Market clearing
*------------------
EQ_MKTHH(h,i)$nfi(i)..
*produced + bought + endow =e= sold + consumed +  used as factor in the production of other goods
     sum(a$(mha(h,a)*mag(a,i)), QP(a)) + QB(h,i) + endow(h,i)
         =e= QS(h,i) + QC(h,i)$g(i) + sum(a$(mha(h,a)),FD(a,i)$f(i));

* Then, market clearing for the whole economy
EQ_MKTE(i)$nfi(i)..
* Supply ( sales + imports ) =e= Demand ( Purchases + exports )
      sum(h,QS(h,i)) + QM(i) =e= sum(h,QB(h,i)) + QE(i);


* Land holdings from the initial period (will differ from total land supply, because of CET)
EQ_TLS(hp)..  TLS(hp) =e= sum(a$mha(hp,a),lhold(hp,a));

* Demand for land by each household
EQ_TLD(hp)..  TLD(hp) =E= sum(a$mha(hp,a),FD(a,"land"));
* Demand for land for each given crop
EQ_LDEM(gp)..  LD(gp) =e= sum(a$mag(a,gp),FD(a,"land"));


* Land rents in a CET structure
** Rent is calculated using the denominator in the "demand" functions
EQ_LRENT1(nod)$nod1(nod)..
         WFDIST(nod,"land") =E= sum(h$mha(h,nod),
                         sum(ag$mna(nod,ag),
                         gamma(h,ag)**(1/(1-rho1(h)))
                         *WFDIST(ag,"land")**(rho1(h)/(rho1(h)-1)))**((1-rho1(h))/rho1(h)))
;

EQ_LRENT2(nod)$nod2(nod)..
         WFDIST(nod,"land") =E=  sum(h$mha(h,nod),sum(ag$mna(nod,ag),
                         gamma(h,ag)**(1/(1-rho2(h)))
                         *WFDIST(ag,"land")**(rho2(h)/(rho2(h)-1)))**((1-rho2(h))/rho2(h)))
;
EQ_LRENT3(nod)$nod3(nod)..
         WFDIST(nod,"land") =E=  sum(h$mha(h,nod),sum(ag$mna(nod,ag),
                         gamma(h,ag)**(1/(1-rho3(h)))
                         *WFDIST(ag,"land")**(rho3(h)/(rho3(h)-1)))**((1-rho3(h))/rho3(h)))
;

* Two Equations drive the CET supply, CET and CETR:
*EQ_CET.. is the equation that forces land to follow a CET schedule
EQ_CET1(h)$hp(h)..     TLS(h) =E= (sum(a1$mha(h,a1),gamma(h,a1)*(FD(a1,"land")**rho1(h))))**(1/rho1(h));
EQ_CET2(h)$hp(h)..      sum(nod2$mha(h,nod2),FD(nod2, "land")) =E= (sum(a2$mha(h,a2),gamma(h,a2)*(FD(a2,"land")**rho2(h))))**(1/rho2(h));
EQ_CET3(h)$hp(h)..      sum(nod3$mha(h,nod3),FD(nod3, "land")) =E= (sum(a3$mha(h,a3),gamma(h,a3)*(FD(a3,"land")**rho3(h))))**(1/rho3(h));

*EQ_CETR.. is the equation that expresses the optimal ratio of land values in different activities
* (comes from first order conditions)
EQ_CETR1(h,a1,a1a)$((not sameas(a1,a1a))*mha(h,a1)*mha(h,a1a))..
         FD(a1,"land") =E= FD(a1a,"land")*
            (gamma(h,a1)/gamma(h,a1a)*WFDIST(a1a,"land")/WFDIST(a1,"land"))**(1/(1-rho1(h)))
;
EQ_CETR2(h,a2,a2a)$((not sameas(a2,a2a))*mha(h,a2)*mha(h,a2a))..
         FD(a2,"land") =E= FD(a2a,"land")*
            (gamma(h,a2)/gamma(h,a2a)*WFDIST(a2a,"land")/WFDIST(a2,"land"))**(1/(1-rho2(h)))
;
EQ_CETR3(h,a3,a3a)$((not sameas(a3,a3a))*mha(h,a3)*mha(h,a3a))..
         FD(a3,"land") =E= FD(a3a,"land")*
            (gamma(h,a3)/gamma(h,a3a)*WFDIST(a3a,"land")/WFDIST(a3,"land"))**(1/(1-rho3(h)))
;

* Prevent simultaneous net buying and net selling by a household - not really necessary, but prevents odd solutions
EQ_SELBUY(h,i)$nfi(i).. QS(h,i)*QB(h,i) =E=0;

model base
/
EQ_CDEM
EQ_Y
EQ_TY
EQ_FDEM1
EQ_PROD
EQ_MKTHH
EQ_MKTE
EQ_TLS
EQ_TLD
EQ_LDEM
EQ_LRENT1
EQ_LRENT2
EQ_LRENT3
EQ_CET1
EQ_CET2
EQ_CET3
EQ_CETR1
EQ_CETR2
EQ_CETR3
EQ_SELBUY
/
;


* Fix some Variables
**************************
* Fix prices of goods and inputs (but not labor)
P.fx(g)=P.l(g);
P.fx(inp)=P.l(inp);
R.fx(ag,ff) = R.l(ag,ff) ;

* Fix capital:
FD.fx(a,"capi")=FD.l(a,"capi");
* No sales, purchases, imports or exports of capital:
QS.fx(hp,"capi") = 0;
QB.fx(hp,"capi") = 0;
QE.fx("capi") = 0;
QM.fx("capi") = 0;

* Fix the labor market:
QE.fx("time") = QE.l("time");
QM.fx("time") = QM.l("time");


******************************************************************************
************************ END OF MODEL SPECIFICATION **************************
******************************************************************************

**********************************************************************
*   FIRST, REPRODUCE THE MATRIX
**********************************************************************
solve base maximizing TY using nlp;
Display TY.l, Y.l, QP.l, QC.l, QB.l, QS.l, QE.l, QM.l, FD.l, LD.l, P.l ;
display R.l, WFDIST.l;

* Save calibrated values with "0" suffix
parameter y0(h) initial household income
          ty0 initial total income
          qp0(a) initial Q produced
          qc0(h,i) initial Q consumed
          qb0(h,i) initial Q bought
          qs0(h,i) initial Q sold
          ms0(h,i) initial marketed surplus
          qe0(i) inital Q exported (from rural sector)
          qm0(i) initial Q imported (to rural sector)
          fd0(ag,i) initial factor demands
          tfd0(i) initial total factor demand by factor
          ld0(i) initial land demands by crop
          p0(i) initial prices
          r0(a,i) initial rents for fixed factors
          wfdist0(a,i) initial deviations from rents of fixed factors
;
y0(h) = Y.l(h) ;
ty0 = TY.l ;
qp0(a)=QP.l(a);
qc0(h,i)=QC.l(h,i) ;
qb0(h,i)=QB.l(h,i) ;
qs0(h,i)=QS.l(h,i) ;
ms0(h,i)$hp(h)= qs0(h,i) - qb0(h,i);
qm0(i)=QM.l(i);
qe0(i)=QE.l(i);
fd0(ag,f)=FD.l(ag,f);
tfd0(i) = sum(ag,fd0(ag,i));
ld0(i)=LD.l(i);
p0(i) = P.l(i);
r0(a,i) = R.l(a,i) ;
wfdist0(a,i) = WFDIST.l(a,i) ;

display y0, ty0, qp0, qc0, qb0, qs0, ms0, qe0, qm0, fd0, tfd0, ld0, p0, r0, wfdist0 ;


* ---------------------------------------------------------------------------------------
*   SIMULATIONS FOR TABLE 10.2 IN BEYOND EXPERIMENTS BOOK
* ---------------------------------------------------------------------------------------

parameter dpayment(h) direct payment to households ;
dpayment(h) = 0 ;

** Experiment a) in Table 10.2:
* unstar the following line to run experiment a), an IS that costs $51.4
isub("EIS","CINPUT") = 0.7077 ; isub("EBO","CINPUT") = 0.7077 ;

** Experiment b) in Table 10.2:
* unstar this line to run experiment b), an MPS that costs $51.4
*P.fx("MAIZE") = 1.2315;
* note: this ignores the cost of rural purchased food (consumer cost, not taxpayer cost)

** Experiment c) in Table 10.2:
* Unstar the following line to run experiment c), a Cash Transfer of $51.4
*dpayment("ECT")= 51.4*0.175 ; dpayment("EBO")= 51.4*0.825 ;
* note: It is distributed proportionally to population: 17.5% to ECT and 82.5% to EBO

* ---------------------------------------------------------------------------------------
* ---------------------------------------------------------------------------------------


isuba(a,i) = sum(h$(mha(h,a)),isub(h,i));
display isub, isuba, dpayment, inpbgta ;
parameter chkk(h) check that input budget adds up;
chkk(h) = sum(a$mha(h,a), inpbgta0(a,"CINPUT")-inpbgta(a,"CINPUT")) ;
display chkk;
yexog(h) = yexog(h) + dpayment(h) ;


* Solve Statement:
solve base maximizing TY using nlp;
Display TY.l, Y.l, QP.l, QC.l, QB.l, QS.l, QE.l, QM.l, FD.l, LD.l, P.l ;
display R.l, WFDIST.l;


* Save simulation output values with "1" suffix
parameter y1(h) new household income
          ty1 new total income
          qp1(a) new Q produced
          qc1(h,i) new Q consumed
          qb1(h,i) new Q bought
          qs1(h,i) new Q sold
          ms1(h,i) new marketed surplus
          qe1(i) inital Q exported (from rural sector)
          qm1(i) new Q imported (to rural sector)
          fd1(ag,i) new factor demands
          tfd1(i) new total factor demand by factor
          ld1(i) new land demands by crop
          p1(i) new prices
          r1(a,i) new rents for fixed factors
          wfdist1(a,i) new deviations from rents of fixed factors

* Save differences with "D" suffix
          yD(h) new household income
          tyD new total income
          qpD(a) new Q produced
          qcD(h,i) new Q consumed
          qbD(h,i) new Q bought
          qsD(h,i) new Q sold
          msD(h,i) new marketed surplus
          qeD(i) inital Q exported (from rural sector)
          qmD(i) new Q imported (to rural sector)
          fdD(ag,i) new factor demands
          tfdD(i) new total factor demand by factor
          ldD(i) new land demands by crop
          pD(i) new prices
          rD(a,i) new rents for fixed factors
          wfdistD(a,i) new deviations from rents of fixed factors

* Save percent differences with "PC" suffix
          yPC(h) new household income
          tyPC new total income
          qpPC(a) new Q produced
          qcPC(h,i) new Q consumed
          qbPC(h,i) new Q bought
          qsPC(h,i) new Q sold
          msPC(h,i) new marketed surplus
          qePC(i) inital Q exported (from rural sector)
          qmPC(i) new Q imported (to rural sector)
          fdPC(ag,i) new factor demands
          tfdPC(i) new total factor demand by factor
          ldPC(i) new land demands by crop
          pPC(i) new prices
          rPC(a,i) new rents for fixed factors
          wfdistPC(a,i) new deviations from rents of fixed factors
;

* Levels
y1(h) = Y.l(h) ;
ty1 = TY.l ;
qp1(a)=QP.l(a);
qc1(h,i)=QC.l(h,i) ;
qb1(h,i)=QB.l(h,i) ;
qs1(h,i)=QS.l(h,i) ;
ms1(h,i)$hp(h)= qs1(h,i) - qb1(h,i);
qm1(i)=QM.l(i);
qe1(i)=QE.l(i);
fd1(ag,f)=FD.l(ag,f);
tfd1(i) = sum(ag,fd1(ag,i));
ld1(i)=LD.l(i);
p1(i) = P.l(i);
r1(a,i) = R.l(a,i) ;
wfdist1(a,i) = WFDIST.l(a,i) ;

display y1, ty1, qp1, qc1, qb1, qs1, ms1, qe1, qm1, fd1, tfd1, ld1, p1, r1, wfdist1 ;

* Level Differences
yD(h) = y1(h)-y0(h);
tyD = ty1-ty0;
qpD(a)= qp1(a)-qp0(a);
qcD(h,i) = qc1(h,i)-qc0(h,i);
qbD(h,i)= qb1(h,i)-qb0(h,i);
qsD(h,i)= qs1(h,i)-qs0(h,i);
msD(h,i) = ms1(h,i)-ms0(h,i);
qmD(i) = qm1(i)-qm0(i);
qeD(i)= qe1(i)-qe0(i);
fdD(ag,f) = fd1(ag,f)-fd0(ag,f);
tfdD(i) = tfd1(i)-tfd0(i);
ldD(i)= ld1(i)-ld0(i);
pD(i) = p1(i)-p0(i) ;
rD(a,i) = r1(a,i)-r0(a,i) ;
wfdistD(a,i) = wfdist1(a,i)-wfdist0(a,i) ;

display yD, tyD, qpD, qcD, qbD, qsD, msD, qeD, qmD, fdD, tfdD, ldD, pD, rD, wfdistD ;

* Percent differences
yPC(h)$y0(h) = 100*yD(h)/y0(h) ;
tyPC$ty0 = 100*tyD/ty0 ;
qpPC(a)$qp0(a) = 100*qpD(a)/qp0(a) ;
qcPC(h,i)$qc0(h,i) = 100*qcD(h,i)/qc0(h,i) ;
qbPC(h,i)$qb0(h,i) = 100*qbD(h,i)/qb0(h,i) ;
qsPC(h,i)$qs0(h,i) = 100*qsD(h,i)/qs0(h,i) ;
msPC(h,i)$ms0(h,i) = 100*msD(h,i)/ms0(h,i);
qmPC(i)$qm0(i) = 100*qmD(i)/qm0(i);
qePC(i)$qe0(i) = 100*qeD(i)/qe0(i);
fdPC(ag,f)$fd0(ag,f) = 100*fdD(ag,f)/fd0(ag,f) ;
tfdPC(i)$tfd0(i) = 100*tfdD(i)/tfd0(i) ;
ldPC(i)$ld0(i) = 100*ldD(i)/ld0(i);
pPC(i)$p0(i) = 100*pD(i)/p0(i);
rPC(a,i)$r0(a,i) = 100*rD(a,i)/r0(a,i);
wfdistPC(a,i)$wfdist0(a,i) = 100*wfdistD(a,i)/wfdist0(a,i) ;

display yPC, tyPC, qpPC, qcPC, qbPC, qsPC, msPC, qePC, qmPC, fdPC, tfdPC, ldPC, pPC, rPC, wfdistPC ;


* Comparative Measures for policies
parameter subinch(h,i) subsidy income only on net sales - per household
          subinc(i) subsidy income only on net sales
          subinchshare(h,i) share of the subsidy going to a given household
          transferh(h) total transfer to household
          transfer total transfer
;

subinch(h,i)$gfnft(i)  =  QS.l(h,i) * abs(p1(i)-p0(i))+(QB.l(h,i)*(1-isub(h,i)))$inp(i) ;
subinc(i)$gfnft(i) = sum(h,subinch(h,i)) ;
subinchshare(h,i)$subinch(h,i) = subinch(h,i)/sum(hh,subinch(hh,i)) ;
transferh(h) = sum(i,subinch(h,i)) + dpayment(h) ;
transfer = sum(i,subinc(i)) + sum(h,dpayment(h)) ;

* Welfare and efficiency
parameter cvh(h)   compensating variation per household
          cvh_perc(h) cv ac a percentage of initial income
          cv      compensating variation across all households
          cv_perc compensating variation as a percentage of income
          b4bh(h) bang for the buck per household
          b4b     bang for the buck
;

cvh(h) = y1(h) - prod(g, (p1(g)/p0(g))**alpha(h,g))*y0(h);
cvh_perc(h) = 100*cvh(h)/y0(h);
cv = sum(h,cvh(h));
cv_perc = 100*cv/ty0;
b4bh(h)$transferh(h) = cvh(h) / transferh(h) ;
b4b     = cv / transfer ;

display subinch, subinc, subinchshare, transferh, transfer, cvh, cv, cvh_perc, cv_perc, b4bh, b4b ;


** ========================================================
*  === TABLE 10.2 =========================================
** ========================================================
* Group share of subsidy or transfer
display subinchshare ;
* Subsidy or Transfer received (Mil. $US)
display transferh ;
* Nominal Income, % change:
display yPC ;
* Welfare, % change
display cvh_perc ;
* Household-level efficiency (bang-for-the-buck)
display b4bh ;
* Total cost of intervention
display transfer ;
* Total transfer efficiency
display b4b ;
