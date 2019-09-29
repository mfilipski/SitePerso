*### Chapter 12 Model - Saffron and gendered labor markets
*### Goto line 588 to change the simulation (makes tables 12.3, 12.4, 12.5, 12.6 in the book)

option limrow =40 ;
option limcol =40;
option decimals = 2 ;
* declare the phantom set "null" (for empty sets - alternative to $onempty)
$phantom null


* Unlike most models, the data for this one was all managed in Stata, not excel.
* The STATA "levelsof" command helps us cut+paste the element names easily as sets:
set ac all accounts
/cap      capital
 inp      inputs
 land     land
 ffl      family female labor
 fml      family male labor
 hfl      hired female labor
 hml      hired male labor
 flphs    female labor in pre-harvest season
 mlphs    female labor in pre-harvest season
 flhs     female labor in harvest season
 mlhs     female labor in harvest season
 none     for empty indices
 flw      crocus flowers (pre-harvest saffron)
 saf      saffron (harvested stigmas)
 ag       agriculture
 lvst     livestock
 nag      non-ag activities
 carephs  care in pre-harvest season
 leisphs  leisure in pre-harvest season
 carehs   care in harvest season
 leishs   leisure in harvest season
 imp      imports (for the village)
 phs      pre-harvest season
 hs       harvest season
 hh1      household 1 - hires saffron labor in
 hh2      household 2 - self-sufficient in saffron labor
 hh3      household 3 - provides saffron hired labor
/
tempf(ac)  temporary factos split into hired and family /ffl,fml,hfl,hml/
tempwf(ac) temporare wage labor factors /hfl, hml /
tempff(ac) temporare family labor factors /ffl, fml /
f(ac)      factors /cap,inp,land,flphs,mlphs,flhs,mlhs/
g(ac)      goods /ag,carehs,carephs,flw,imp,leishs,leisphs,lvst,nag,saf/
s(ac)      seasons /phs,hs/
h(ac)      households /hh1, hh2, hh3/;

* and the useful subsets:
set
* factors
     lf(f) labor factors /flphs,mlphs,flhs,mlhs/
     lfphs(f) labor factors in preharvest season /mlphs, flphs/
     lfhs(f) labor factors in the harvest season /mlhs, flhs /
     fixf(f) fixed factors /land, cap/
     tf(f) tradable inputs /flphs,mlphs,flhs,mlhs,inp/
     tfe(f)  tradable in the economy /flphs,mlphs,flhs,mlhs/
     tfw(f)  tradable with the world /inp/
     mlf(f) male labor factors /mlhs, mlphs/
     flf(f) female labor factors /flhs, flphs/
* goods
     tg(g)   tradable goods with fixed prices /ag, nag, saf, lvst, imp /
     ntg(g)  non-tradable goods /flw, leisphs, leishs, carephs, carehs /
     lcg(g) leisure and care goods  /leisphs, leishs, carephs, carehs/
     cg(g) just care goods /carephs, carehs/
;

set mapfs(f,s) mapping of factors to seasons /
     (land, cap, inp, mlphs, flphs).phs
     (land, cap, inp, mlhs, flhs).hs
/

alias (h,hh,ha) ;
alias (s,sa,ss) ;
alias (g,gg,ga) ;
alias (f,ff,fa) ;

set varn the variable names
/beta,fwagesh,hlrevfem,hlrevmal,idsh,mwagesh,qc,qcalph,qp,revremit/

alias (ac, aca)
      (h,hh)
      (g,gg)
      (f,ff);

table statatab(varn,ac,ac,ac,ac,ac) gamstable
$ondelim
$include CH12B_safdata_care.txt
$offdelim
;

display statatab ;


Parameters
* price
     vash(g,h)      share of value added in total production value
     idsh(g,gg,h,s)   share of intermediate demand of one good in prod of another good
* production
     shcobb(f,g,h,s)  cobb-douglas coeff for a household in a season
     acobb(g,h)     cobb-douglas shifter for a household in a season

* consumption
     alpha(g,h)   coeff in the consumption func
     cmin(g,h)    incompressible consumption for the LES
     endow(f,h,s) factor endowments
     exinc(h)     exogenous incomes
;
Parameters
* production
     qp0(g,hh)      household-specific quantity produced in a season
     qva0(g,hh)     quantity of value added created in a household
     fd0(f,g,hh,s)  factor demand for production by a hh in a season
     hfd0(f,h,s)    total houseld factor demand
     tfd0(f,s)      total factor demand in each season
     id0(g,gg,hh,s)   intermediate demand
     tid0(g,hh)   total value from intermediate demands

* factor supplies
     hfms0(f,h,s)    factor marketed surplus in a household by season
     fms0(f,s)      factor marketed surplus in the economy
     fi0(f)         factor imports for tradable inputs

* consumption
     qc0(g,hh)      household-specific quantity consumed in a season
     y0(h)          household income

* trade
     hms0(g,h)      household marketed surplus
     ms0(g)         marketed surplus of a good (not seasonal)

* prices
     p0(g)          commodity prices in a season
     pe0(g,h)       endogenous price at the household level (for flowers)
     pva0(g,h)      commodity value-added prices as seen by each household
     r0(f,g,hh,s)     factor wage in a household-good-season (determined at various levels)
     wm0(f,s)       market wage for a tradable factor
;

*  Initialisation
*=========================

*### production side

* Use the matrix values
* -------------------------------------------
* production
qp0(g,h)       = statatab("qp","none",g,"none","none",h);
display qp0 ;

* and flower production
idsh(g,gg,h,s) = statatab("idsh","none",g,s,gg,h) ;
display idsh ;

* and intermediate demand is a share of total qp
id0(g,gg,h,s)  = idsh(g,gg,h,s)*qp0(gg,h);
display id0 ;
tid0(g,hh) = sum((gg,s),id0(gg,g,hh,s)) ;
display tid0;

* F needs to be mapped between those distinguished by hired/family and those that are not:
set mapacf(ac,f) maps stata factors to factors used in the model/
land.land
cap.cap
inp.inp
(hml,fml).(mlphs,mlhs)
(hfl,ffl).(flphs,flhs)
/;

shcobb(f,g,h,s) = sum(ac$(mapacf(ac,f)*mapfs(f,s)), statatab("beta",ac,g,s,"none",h));
display shcobb ;

parameter chekshcd(g,h) must equal to 1 in the sum of factors and seasons ;
chekshcd(g,h) = sum((f,s),shcobb(f,g,h,s)) ;
display chekshcd ;

fd0(f,g,h,s)  = shcobb(f,g,h,s)*(qp0(g,h)-tid0(g,h)) ;
display fd0 ;

qva0(g,h)      =  sum((f,s),fd0(f,g,h,s)) ;
display id0, tid0, qp0, qva0 ;

parameter checkid(g,h) must be equal to qp0;
checkid(g,h) = tid0(g,h) + qva0(g,h) ;
display checkid, qp0;

vash(g,h)$qp0(g,h) = qva0(g,h)/qp0(g,h) ;
acobb(g,h)     = qva0(g,h)/prod((f,s),fd0(f,g,h,s)**shcobb(f,g,h,s)) ;
display vash, acobb ;

hfd0(f,h,s)    = sum(g, fd0(f,g,h,s)) ;
tfd0(f,s)      = sum(h,hfd0(f,h,s));
display hfd0, tfd0 ;

* Computing endowments is straightforward for land and capital, but tricky for labor
endow(fixf,h,s) = sum(g, fd0(fixf,g,h,s)) ;
display endow ;
* for labor, the endowment is the share of total hired labor for that season that goes to a given household
parameter mwagesh(h) share of total hired labor coming from each household
          fwagesh(h) share of total hired labor coming from each household
          wagelab(g,ac,s,h) wage labor used in production of g by h in s
          wagetot(lf,s) total hired labor employed in the season
          wagetotch(lf,s) other way of obtaining wagetot - check;
mwagesh(h)=statatab("mwagesh","none","none","none","none",h) ;
fwagesh(h)=statatab("fwagesh","none","none","none","none",h) ;
display mwagesh, fwagesh ;
* total wage labor used = sum over all produced goods and all households
* of the VA given household hh produces of good g times the share of hired labor from the stata sheet
* -- all matched over the male/female mapping of hired labor
wagelab(g,tempwf,s,h) = statatab("beta",tempwf,g,s,"none",h)*qva0(g,h) ;
display wagelab ;
wagetot(lf,s) = sum((g,hh,ac)$(mapacf(ac,lf)*mapfs(lf,s)*tempwf(ac)),statatab("beta",ac,g,s,"none",hh)*qva0(g,hh)) ;
display wagetot ;
wagetotch(lf,s) = sum((g,tempwf,h)$(mapacf(tempwf,lf)*mapfs(lf,s)),wagelab(g,tempwf,s,h));
display wagetotch ;

* And split the wage labor according to male and female shares
endow("mlphs",h,s) =  mwagesh(h)*wagetot("mlphs",s) ;
endow("flphs",h,s) =  fwagesh(h)*wagetot("flphs",s) ;
endow("mlhs",h,s) =  mwagesh(h)*wagetot("mlhs",s) ;
endow("flhs",h,s) =  fwagesh(h)*wagetot("flhs",s) ;

display endow ;


* -- and also add family labor now:
parameter gfamlab(g,lf,s,h) family labor inputs by activity hh and season
          famlab(lf,s,h) family labor inputs by hh and season;
gfamlab(g,lf,s,h) = sum(ac$(mapacf(ac,lf)*mapfs(lf,s)*tempff(ac)), statatab("beta",ac,g,s,"none",h)*qva0(g,h)) ;
famlab(lf,s,h) = sum(g, gfamlab(g,lf,s,h)) ;
display gfamlab, famlab ;

* and update the endow to reflect family labor:
display endow ;
endow(lf,h,s) = endow(lf,h,s) + famlab(lf,s,h) ;
display endow;

hfms0(f,h,s)   = endow(f,h,s) - hfd0(f,h,s) ;
fms0(f,s)   = sum(h,hfms0(f,h,s));
fi0(f)$tf(f)  = - sum((h,s),hfms0(f,h,s));

display hfms0, fms0, fi0 ;


* prices:
p0(tg)         = 1 ;
pe0(ntg,h)     = 1 ;
pva0(g,h)      = 1-sum((gg,s),idsh(gg,g,h,s)) ;
display p0, pe0, pva0 ;

* consumption and income:
wm0(tf,s)      = 1 ;
r0(fixf,g,h,s) = 1 ;
exinc(h)       = statatab("revremit","none","none","none","none",h) ;

y0(h)          =  sum((tf,s)$mapfs(tf,s), endow(tf,h,s)* wm0(tf,s))
                 +sum((fixf,g,s)$mapfs(fixf,s), fd0(fixf,g,h,s)*r0(fixf,g,h,s))
                 +exinc(h);

* QC is determined by shares of Y for produced goods, and by levels from the data for care economy
qc0(lcg,h)       = statatab("qc","none",lcg,"none","none",h);
display qc0;
qc0(g,h)$(not lcg(g))       = statatab("qcalph","none",g,"none","none",h) * (y0(h)-sum(lcg,qc0(lcg,h))) ;
display qc0 ;

* everything has zero cmin, except for care.
cmin(g,h)      = 0 ;
* We assume it's a different share of their current levels for the different households
*
parameter cminsh(h);
cminsh("hh1") = 0.4 ;
cminsh("hh2") = 0.6 ;
cminsh("hh3") = 0.8 ;
* recall "cg" stands for care goods.
cmin(cg,h) = qc0(cg,h)*cminsh(h) ;

* And alphas are computed accordingly (not the same as the qcalph, which had no leisure or reprod):
alpha(g,h)     = (qc0(g,h)-cmin(g,h))/(y0(h)-sum(gg,cmin(gg,h))) ;

* marketed surplus:
hms0(g,h)      =  qp0(g,h) - qc0(g,h) - sum((gg,s), id0(g,gg,h,s)) ;
ms0(g)         =  sum(h,hms0(g,h)) ;

display wm0, r0, cmin, exinc, qc0, y0, alpha, hms0, ms0 ;

* checks:
parameter idshcheck(g,gg,h,s) must be equal to idsh
          shcobbch(g,h) must be equal to 1-idsh
           ycheck(h) must sum to y0
          alphach(h) must sum to 1;

idshcheck(g,gg,h,s)$qp0(gg,h) = id0(g,gg,h,s)/qp0(gg,h) ;
shcobbch(g,h) = sum((f,s),shcobb(f,g,h,s)) ;
ycheck(h) = sum(g, statatab("qc","none",g,"none","none",h)) ;
alphach(h) = sum(g,alpha(g,h)) ;

display qp0, idsh, idshcheck, hfd0, hfms0, fi0, shcobb, acobb, shcobbch ;
display y0, ycheck, alpha, alphach, qc0;


nonnegative variables
* production
     QP(g,hh)       household-specific quantity produced in a season
     QVA(g,hh)      quantity of value added created in an activity
     FD(f,g,hh,s)   factor demand for production by a hh in a season
     HFD(f,h,s)     total factor demand for a factor by a household
     FI(f)          factor imports for purchased inputs
     ID(g,gg,hh,s)  intermediate demand of g season s for production of gg season ss

* consumption
     QC(g,hh)       household-specific quantity consumed in a season

* incomes
     Y(hh)          household specific income in a season
     TY             total yearly income in the economy

* trade
     QX(g)          quantity exported of a good in a season
     QM(g)          quantity imported of a good in a season

* prices
     P(g)           commodity prices in a season
     PE(g,h)        endogenous price at the household level (for flowers and leisure)
     PVA(g,h)       price value added in a season
     R(f,g,hh,s)    factor rent for fixed factors
     WE(f,hh,s)     endogenous wage for movable factors within household
     WM(f,s)        wage on the market for tradable factors seasonnally
;

variables
* factor marketed surplus from the household
     HFMS(f,h,s)     marketed surplus of a factor in a season from each household
     MS(g)          good marketed surplus
     HMS(g,h)       houshold-level marketed surplus
     TRICK          trick variable for nlp program
;


Equations
* prices
     PVA_EQ(g,h)         price value added equation

* production
     FD_EQ(f,g,h,s)        factor demands
     HFD_EQ(f,h,s)         total factor demand
     QP_EQ(g,h)          production function
     QVA_EQ(g,h)         QVA equation
     ID_EQ(g,gg,h,s)       interseasonal demand between saffrons

* consumption
     QC_EQ(g,h)          quantities consumed (should it be seasonal?)
     Y_EQ(h)             full income constraint (should it be seasonal?)

* market clearing
     FFCLR_EQ(f,g,h,s)    fixed factor clearing (defines the rent)
     TFCLR_EQ1(f,s)       tradable factor clearing at the market level in the economy
     TFCLR_EQ2(f)         tradable factor clearing at the market level with the world
     TFCLR_EQHH(f,h,s)     tradable factor clearing at the household level

     HHCLR_EQ(g,h)       household-level quantity clearing
     MKCLRG_EQ(g)        market clearing for goods at the economywide level
     MKTCLRG2_EQ(g,h)      market "clearing" condition for non-tradable goods in the household

     ZEROPROF(g,h)       zero profit condition to link P with P of intermediate inputs

* Trick equation to pretend there is something to maximize in the nlp
     TRICK_EQ            trick equation for nlp
;


* Model Specifications:
*=========================
* prices
PVA_EQ(g,h)$qva0(g,h)..
     PVA(g,h) =E= (P(g)$tg(g)+PE(g,h)$ntg(g))
                  - sum((gg,s)$id0(gg,g,h,s),(P(gg)$tg(gg)+PE(gg,h)$ntg(gg))*idsh(gg,g,h,s)) ;

* Zero profit condition links Ps together
ZEROPROF(g,h)..
     QP(g,h)*PVA(g,h) + sum((gg,s),ID(gg,g,h,s)*(P(gg)$tg(gg)+PE(gg,h)$ntg(gg))) =e= QP(g,h)*(P(g)$tg(g)+PE(g,h)$ntg(g)) ;

* production: lets make two growing seasons because factors are available seasonally
FD_EQ(f,g,h,s)$fd0(f,g,h,s)..
     FD(f,g,h,s)*[R(f,g,h,s)$fixf(f)+ WM(f,s)$tf(f)] - QP(g,h)*PVA(g,h)*shcobb(f,g,h,s)
          =E= 0
;

HFD_EQ(f,h,s)..
     HFD(f,h,s) =E= sum(g,FD(f,g,h,s));

ID_EQ(g,gg,h,s)..
     ID(g,gg,h,s) =E= idsh(g,gg,h,s)*QP(gg,h)   ;

QVA_EQ(g,h)..
     QVA(g,h) =E= acobb(g,h)*prod((f,s)$mapfs(f,s),FD(f,g,h,s)**shcobb(f,g,h,s))
;

QP_EQ(g,h)$qp0(g,h)..
     QVA(g,h) =E= QP(g,h)*vash(g,h);
;

* consumption: how about just year-round consumption
QC_EQ(g,h)..
     QC(g,h)*(P(g)$tg(g)+PE(g,h)$ntg(g)) =E= alpha(g,h)*[Y(h)-sum(gg, (P(g)$tg(g)+PE(g,h)$ntg(g))*cmin(gg,h))] + cmin(g,h)
;

* income = sum of all endowments
Y_EQ(h)..
     Y(h) =E= sum((tf,s)$mapfs(tf,s), endow(tf,h,s)* WM(tf,s))
             +sum((fixf,g,s)$mapfs(fixf,s), FD(fixf,g,h,s)* R(fixf,g,h,s))
             +exinc(h) ;
;

* factor markets:
* fixed factors - stay fixed
FFCLR_EQ(f,g,h,s)$fixf(f)..
     fd0(f,g,h,s) =E= FD(f,g,h,s) ;

* factors clear in the two different seasons.
TFCLR_EQHH(f,h,s)$(tf(f)*mapfs(f,s))..
     sum(g, FD(f,g,h,s)) - endow(f,h,s) + HFMS(f,h,s) =E= 0  ;

*
TFCLR_EQ1(f,s)$(tfe(f)*mapfs(f,s))..
     sum(h,HFMS(f,h,s)) =e= - FI(f) ;

TFCLR_EQ2(f)$tfw(f)..
       FI(f) + sum((h,s),HFMS(f,h,s)) =E= 0 ;

* household-level quantity clearing (not seasonal)
HHCLR_EQ(g,h)..
     HMS(g,h) =E= QP(g,h) - QC(g,h) - sum((gg,s), ID(g,gg,h,s) ) ;

* market clearing for goods in the economy - not seasonal
MKCLRG_EQ(g)..
     MS(g) =E=  sum(h, HMS(g,h));

* fixed price for non-tradable goods
MKTCLRG2_EQ(g,h)$ntg(g)..
     HMS(g,h) =E= 0;

* trick for nlp specification
TRICK_EQ..
     TRICK =E= 1 ;


model saffronnlp /
     ZEROPROF
     PVA_EQ
     FD_EQ
     HFD_EQ
     ID_EQ
     QVA_EQ
     QP_EQ
     QC_EQ
     Y_EQ
     FFCLR_EQ
     TFCLR_EQ1
     TFCLR_EQ2
     TFCLR_EQHH
     HHCLR_EQ
     MKCLRG_EQ
     MKTCLRG2_EQ
     TRICK_EQ
/
;


* closure rules
* ================
* fixed factors are fixed
FD.fx(fixf,g,h,s) = fd0(fixf,g,h,s) ;
FD.fx(f,g,h,s)$(not fd0(f,g,h,s)) = 0;
* flowers must be used for saffron harvest - should even be in the same household...
HMS.fx("flw",h) = 0;
HMS.fx(lcg,h) = 0;

* "imports" cannot be produced:
QP.fx(g,h)$(not qp0(g,h)) = 0;

* "market" prices are fixed for tradable goods, but not really for flowers and leisure (theres PE)
P.fx(g) = p0(g);

*factor imports are either free or fixed
FI.fx(lf) = fi0(lf) ;
WM.fx("inp",s) = wm0("inp",s);


* initialisation
QC.l(g,h) = qc0(g,h) ;
QVA.l(g,h) = qva0(g,h) ;
QP.l(g,h) = qp0(g,h) ;
FD.l(f,g,h,s) = fd0(f,g,h,s) ;
HFD.l(f,h,s) = hfd0(f,h,s);
HFMS.l(f,h,s) = hfms0(f,h,s) ;
FI.l(f) = fi0(f);
HMS.l(g,h) = hms0(g,h) ;
MS.l(g) = ms0(g);
PVA.l(g,h) = pva0(g,h);
P.l(g) = p0(g);
PE.l(g,h) = pe0(g,h);
ID.l(g,gg,h,s) = id0(g,gg,h,s);
Y.l(h) = y0(h) ;
R.l(f,g,h,s) = r0(f,g,h,s) ;
WM.l(f,s) = wm0(f,s) ;
WE.l(f,h,s) = 1 ;
TRICK.l = 1 ;

display Y.l, QC.l, QP.l, FD.l, HFD.l, HFMS.l, FI.l, MS.l, HMS.l, PVA.l, P.l, ID.l, R.l, WM.l, WE.l ;

* check of fms0
parameter fch ;
fch(f,h,s)$(mapfs(f,s)*tf(f)) = sum(g, FD.l(f,g,h,s)) - endow(f,h,s) ;
display fch ;
display endow, hfms0 ;

option iterlim = 2 ;
solve saffronnlp maximising TRICK using nlp ;
option iterlim = 1000;
display Y.l, QC.l, QP.l, FD.l, HFD.l, HFMS.l, FI.l, MS.l, HMS.l, PVA.l, P.l, ID.l, R.l, WM.l, WE.l ;

* make sure everything is reproduced
set bady(h) set of badly reproduced y
    badqp(g,h) set of badly reproduced qp
    badfd(f,g,h,s) set of badly reproduced fd
;
bady(h) = yes$(abs(Y.l(h)-y0(h)) > 0.0001);
badqp(g,h) = yes$((QP.l(g,h) - qp0(g,h)) > 0.0001);
badfd(f,g,h,s) = yes$((FD.l(f,g,h,s) - fd0(f,g,h,s)) > 0.0001) ;

ABORT$card(bady) "Y not reproduced", bady ;
ABORT$card(badqp) "QP not reproduced", badqp ;
ABORT$card(badfd) "FD not reproduced", badfd  ;

parameters
     qc1(g,h)    qc after calibration
     qp1(g,h)    qp after calibration
     fd1(f,g,h,s)  fd after calibration
     hfd1(f,h,s)   hfd after calibration
     hfms1(f,h,s)   fms  after calibration
     fi1(f)      fi after calibration
     ms1(g)      ms after calibration
     hms1(g,h)   hms after simulation
     pva1(g,h)   value added prices  after calibration
     p1(g)       prices after calibration
     pe1(g,h)   endogenous price after calibration
     id1(g,gg,h,s) intermediate demand after calibration
     y1(h)       y  after calibration
     r1(f,g,h,s)   rents after calibration
     we1(f,h,s)    endogenous wages after calibration
     wm1(f,s)      exogenous wages after calibration
;
qc1(g,h)       = QC.l(g,h);
qp1(g,h)       = QP.l(g,h);
fd1(f,g,h,s)   = FD.l(f,g,h,s);
hfd1(f,h,s)    = HFD.l(f,h,s) ;
hfms1(f,h,s)    = HFMS.l(f,h,s);
fi1(f)         = FI.l(f) ;
ms1(g)         = MS.l(g);
hms1(g,h)      = HMS.l(g,h);
pva1(g,h)      = PVA.l(g,h);
p1(g)          = P.l(g);
pe1(g,h)       = PE.l(g,h);
id1(g,gg,h,s)    = ID.l(g,gg,h,s) ;
y1(h)          = Y.l(h) ;
r1(f,g,h,s)    = R.l(f,g,h,s);
we1(f,h,s)     = WE.l(f,h,s) ;
wm1(f,s)       = WM.l(f,s) ;

display qc1, qp1, fd1, hfd1, hfms1, fi1, hms1, ms1, pva1, p1, pe1, id1, y1, r1, we1, wm1;


* Simulation runs: (unstar one of them at a time)
*==============================================================
* SIMULATION 1 (Tables 12.3 and 12.4 in the book)
* - unstar the following line to run sim 1:
P.fx("saf") = P.l("saf")*1.1;

* SIMULATION 2 (Tables 12.5 and 12.6 in the book: Technolgical change in cultivation period)
* - unstar the following line to run sim 2 (while starring out sim 1):
*acobb("flw",h) = acobb("flw",h)*1.1 ;
*==============================================================


solve saffronnlp maximising TRICK using nlp ;
display Y.l, QC.l, QP.l, FD.l, HFD.l, HFMS.l, MS.l, HMS.l, PVA.l, P.l, PE.l, ID.l, R.l, WM.l, WE.l ;

parameters
     qc2(g,h)    qc after simulation
     qp2(g,h)    qp after simulation
     fd2(f,g,h,s)  fd after simulation
     hfd2(f,h,s)   hfd after simulation
     hfms2(f,h,s)   fms  after simulation
     fi2(f)      fi after simulation
     ms2(g)      ms after simulation
     hms2(g,h)   hms after simulation
     pva2(g,h)   value added prices  after simulation
     p2(g)       prices after simulation
     pe2(g,h)   endogenous price after simulation
     id2(g,gg,h,s) intermediate demand after simulation
     y2(h)       y  after simulation
     r2(f,g,h,s)   rents after simulation
     we2(f,h,s)    endogenous wages after simulation
     wm2(f,s)      exogenous wages after simulation
;
qc2(g,h) = QC.l(g,h);
qp2(g,h) = QP.l(g,h);
fd2(f,g,h,s) = FD.l(f,g,h,s);
hfd2(f,h,s) = HFD.l(f,h,s) ;
hfms2(f,h,s) = HFMS.l(f,h,s);
fi2(f)   = FI.l(f) ;
ms2(g) = MS.l(g);
hms2(g,h) = HMS.l(g,h);
pva2(g,h) = PVA.l(g,h);
p2(g) = P.l(g);
pe2(g,h) = PE.l(g,h);
id2(g,gg,h,s) = ID.l(g,gg,h,s) ;
y2(h) = Y.l(h) ;
r2(f,g,h,s) = R.l(f,g,h,s);
we2(f,h,s) = WE.l(f,h,s) ;
wm2(f,s) = WM.l(f,s) ;

display qc2, qp2, fd2, hfd2, hfms2, fi2, hms2, ms2, pva2, p2, pe2, id2, y2, r2, we2, wm2;



* Now deltas and percent changes
* ===============================
parameters
     qcD(g,h)    delta level of qc
     qpD(g,h)    delta level of qp
     fdD(f,g,h,s)  delta level of fd
     hfdD(f,h,s)   delta level of hfd
     hfmsD(f,h,s)   delta level of fms
     fiD(f)      delta level of fi
     msD(g)      delta level of ms
     hmsD(g,h)      delta level of ms
     pvaD(g,h)   delta level of value added prices
     pD(g)       delta level of prices
     peD(g,h)    delta level of endogenous prices
     idD(g,gg,h,s) delta level of intermediate demand
     yD(h)       delta level of y
     rD(f,g,h,s)   delta level of rents
     weD(f,h,s)    delta level of endogenous wages
     wmD(f,s)      delta level of exogenous wages
;
qcD(g,h) = qc2(g,h)- qc1(g,h);
qpD(g,h) = qp2(g,h)-qp1(g,h);
fdD(f,g,h,s) = fd2(f,g,h,s)-fd1(f,g,h,s);
hfdD(f,h,s) = hfd2(f,h,s)-hfd1(f,h,s);
hfmsD(f,h,s) = hfms2(f,h,s)-hfms1(f,h,s);
fiD(f)   = fi2(f) -fi1(f);
msD(g) = ms2(g)-ms1(g);
hmsD(g,h) = hms2(g,h)-hms1(g,h);
pvaD(g,h) = pva2(g,h)-pva1(g,h);
pD(g) = p2(g)- p1(g);
peD(g,h) = pe2(g,h)- pe1(g,h);
idD(g,gg,h,s) = id2(g,gg,h,s) -id1(g,gg,h,s);
yD(h) = y2(h)- y1(h);
rD(f,g,h,s) = r2(f,g,h,s)- r1(f,g,h,s);
weD(f,h,s) = we2(f,h,s)- we1(f,h,s);
wmD(f,s) = wm2(f,s)- wm1(f,s);

display qcD, qpD, fdD, hfdD, hfmsD, fiD, hmsD, msD, pvaD, pD, peD, idD, yD, rD, weD, wmD;



parameters
     qcPC(g,h)    percent change in qc
     qpPC(g,h)    percent change in qp
     fdPC(f,g,h,s)  percent change in fd
     hfdPC(f,h,s)   percent change in hfd
     hfmsPC(f,h,s)   percent change in fms
     fiPC(f)      percent change in fi
     msPC(g)      percent change in ms
     hmsPC(g,h)      percent change in hms
     pvaPC(g,h)   percent change in value added prices
     pPC(g)       percent change in prices
     pePC(g,h)    percent change in endogenous prices
     idPC(g,gg,h,s) percent change in intermediate demand
     yPC(h)       percent change in y
     rPC(f,g,h,s)   percent change in rents
     wePC(f,h,s)    percent change in endogenous wages
     wmPC(f,s)      percent change in exogenous wages
;
qcPC(g,h)$qc1(g,h) = 100* qcD(g,h)/ qc1(g,h);
qpPC(g,h)$qp1(g,h) = 100* qpD(g,h)/qp1(g,h);
fdPC(f,g,h,s)$fd1(f,g,h,s) = 100* fdD(f,g,h,s)/fd1(f,g,h,s);
hfdPC(f,h,s)$hfd1(f,h,s) = 100* hfdD(f,h,s)/hfd1(f,h,s);
hfmsPC(f,h,s)$hfms1(f,h,s) = 100* hfmsD(f,h,s)/hfms1(f,h,s);
fiPC(f)$fi1(f)   = 100* fiD(f) /fi1(f);
msPC(g)$ms1(g) = 100* msD(g)/ms1(g);
hmsPC(g,h)$hms1(g,h) = 100* hmsD(g,h)/hms1(g,h);
pvaPC(g,h)$pva1(g,h) = 100* pvaD(g,h)/pva1(g,h);
pPC(g)$p1(g) = 100* pD(g)/ p1(g);
pePC(g,h)$pe1(g,h) = 100* peD(g,h)/ pe1(g,h);
idPC(g,gg,h,s)$id1(g,gg,h,s) = 100* idD(g,gg,h,s) /id1(g,gg,h,s);
yPC(h)$y1(h) = 100* yD(h)/ y1(h);
rPC(f,g,h,s)$r1(f,g,h,s) = 100* rD(f,g,h,s)/ r1(f,g,h,s);
wePC(f,h,s)$we1(f,h,s) = 100* weD(f,h,s)/ we1(f,h,s);
wmPC(f,s)$wm1(f,s) = 100* wmD(f,s)/ wm1(f,s);

display qcPC, qpPC, fdPC, hfdPC, hfmsPC, fiPC, hmsPC, msPC, pvaPC, pPC, pePC, idPC, yPC, rPC, wePC, wmPC;


* =============================================================
* Creating the output
* =============================================================

* order the paramter indices as convenient:
parameter fdDout(g,h,f,s)
          afdDout(g,f,s) fdout by activity (all hh together)
          lfdDout(g,*,s)
          fdDfortab(*,*,s) fd for table - where care and leis are together
* factor demands by household
          hldDout(h,*,s) household factor demand changes
;

fdDout(g,h,f,s) = fdD(f,g,h,s) ;
afdDout(g,f,s) = sum(h,fdD(f,g,h,s)) ;
* just output the totals in labor factors:
lfdDout(g,"labor",s) = sum(h, sum(lf,fdD(lf,g,h,s))) ;

* make the one that directly feeds our table:
fdDfortab(g,"labor",s)$(not lcg(g)) = lfdDout(g,"labor",s);
fdDfortab("care","labor",s) = lfdDout("carehs","labor",s) + lfdDout("carephs","labor",s) ;
fdDfortab("leis","labor",s) = lfdDout("leishs","labor",s) + lfdDout("leisphs","labor",s) ;

* now by household:
hldDout(h,"males",s) = sum(g,sum(mlf, fdD(mlf,g,h,s)))   ;
hldDout(h,"females",s) = sum(g,sum(flf, fdD(flf,g,h,s))) ;
display fdDout, afdDout, lfdDout, fdDfortab, hldDout ;


execute_unload "outresults.gdx" fdDout afdDout lfdDout  fdDfortab hldDout
execute 'xlstalk -s  "Ch12C_Saffron_Tables_rev1.xlsx"'
execute 'gdxxrw.exe outresults.gdx O=Ch12C_Saffron_Tables_rev1.xlsx Index=index!a1'
execute 'xlstalk -o  "Ch12C_Saffron_Tables_rev1.xlsx"'


