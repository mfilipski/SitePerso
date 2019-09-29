*        LEWIE MODEL FOR THE GALAPAGOS ISLANDS

*        The increase in tourist demand from 1999-2010 is simulated (look for EXPERIMENT
*        below) assuming migration of (skilled and unskilled) labor is
*        not constrained and, thus, wages are fixed at the domestic wage
*        for the rest of Ecuador.

*        To simulate the same increase assuming migration is
*        constrained and, thus, local wages vary, look for
*        FIXED WAGE below and follow the instructions.



$TITLE SAM MULTIPLIER MODEL
$OFFUPPER
*option nlp = minos5
*option nlp = conopt2
*######################## SET DEFINITION #############################
SETS

  i ENDOGENOUS ACCOUNTS /

* Santa Cruz Accounts:

                                        AGZ       Agriculture & Livestock
                                        PEZ       Fishing
                                        LAZ         Lobster
                                        BAZ         Bacalao (Seco-Salado)
                                        PBZ         Pescado Blanco
                                        COZ       Fishing Coop
                                        AAZ       Environemntal Activities
                                        CAZ         Hunting (goats & pigs)
                                        MAZ         Wood
                                        ALZ       Rain Water (homes & "fincas")
                                        APZ       Drinking Water
                                        OAZ       Other Productive Activities
                                        STZ       Tourist Services
                                        RBZ       Bars & Restaurants
                                        HOZ       Hotels
                                        CMZ       Comerce
                                        AEZ         Bottled Water
                                        OSZ         Others
                                        ATZ         Daily Tours and Equipment Rental
                                        AVZ         Travel Agencies
                                        TRZ       Transport
                                        OOZ       Other services
                                        SVZ       Various Service
                                        FFZ       Family Factors
                                        MCZ       Skilled Wage Labor
                                        MNZ       Unskilled Wage Labor
                                        CFZ       Physical Capital
                                        CTZ       Land
                                        HAZ       Households in Dispersed Areas (Ag.)
                                        HPZ       Fishing Households
                                        HEZ       Entrepreneureal Households
                                        HRZ       Working Households (Private Business)
                                        HUZ       Working Households (Bureaucrats)



* San Cristobal Accounts:

                                        AGR       Agriculture & Livestock
                                        PER       Fishing
                                        LAR         Lobster
                                        BAR         Bacalao (Seco-Salado)
                                        PBR         Pescado Blanco
                                        COR       Fishing Coop
                                        AAR       Environemntal Activities
                                        CAR         Hunting (goats & pigs)
                                        MAR         Wood
                                        ALR       Rain Water (homes & "fincas")
                                        APR       Drinking Water
                                        OAR       Other Productive Activities
                                        STR       Tourist Services
                                        RBR       Bars & Restaurants
                                        HOR       Hotels
                                        CMR       Comerce
                                        AER         Bottled Water
                                        OSR         Others
                                        ATR         Daily Tours and Equipment Rental
                                        AVR         Travel Agencies
                                        TRR       Transport
                                        OOR       Other services
                                        SVR       Various Service
                                        FFR       Family Factors
                                        MCR       Skilled Wage Labor
                                        MNR       Unskilled Wage Labor
                                        CFR       Physical Capital
                                        CTR       Land
                                        HAR       Households in Dispersed Areas (Ag.)
                                        HPR       Fishing Households
                                        HER       Entrepreneureal Households
                                        HRR       Working Households (Private Business)
                                        HUR       Working Households (Bureaucrats)

* Isla Isabella Accounts:

                                        AGI       Agriculture & Livestock
                                        PEI       Fishing
                                        LAI         Lobster
                                        BAI         Bacalao (Seco-Salado)
                                        PBI         Pescado Blanco
                                        POI         Other
                                        COI       Fishing Coop
                                        AAI       Environemntal Activities
                                        CAI         Hunting (goats & pigs)
                                        MAI         Wood
                                        ALI       Rain Water (homes & "fincas")
                                        OAI       Other Productive Activities
                                        STI       Tourist Services
                                        RBI       Bars & Restaurants
                                        HOI       Hotels
                                        CMI       Comerce
                                        AEI         Bottled Water
                                        OSI         Others
                                        ATI         Daily Tours and Equipment Rental
                                        AVI         Travel Agencies
                                        TRI       Transport
                                        OOI       Other services
                                        SVI       Various Service
                                        FFI       Family Factors
                                        MCI       Skilled Wage Labor
                                        MNI       Unskilled Wage Labor
                                        CFI       Physical Capital
                                        CTI       Land
                                        HAI       Households in Dispersed Areas (Ag.)
                                        HPI       Fishing Households
                                        HEI       Entrepreneureal Households
                                        HRI       Working Households (Private Business)
                                        HUI       Working Households (Bureaucrats)

*Archipelago-wide Accounts

                                        CL        Locally Based Cruises
                                        CC        Continental Based Cruises
                                        ET        Domestic Tourists
                                        RT        Foreign Tourists
                                        ES        Tourist Services in  Ecuador
                                        RS        Tourist Services in Rest of World /


 it(i) TOURISM ACTIVITIES /
                                        CL        Locally Based Cruises
                                        CC        Continental Based Cruises
                                        ET        Domestic Tourists
                                        RT        Foreign Tourists
                                        ES        Tourist Services in  Ecuador
                                        RS        Tourist Services in Rest of World /


 ip(i) PRODUCTION ACTIVITIES / AGZ,PEZ,STZ,CMZ,OAZ,AAZ,OOZ,AGR,PER,STR,CMR,OAR,AAR,OOR,
                               AGI,PEI,STI,CMI,OAI,AAI,OOI /


 f(i) FACTORS    /  FFZ,MCZ,MNZ,CFZ,CTZ,FFR,MCR,MNR,CFR,CTR,FFI,MCI,MNI,CFI,CTI /

 fz(f)  SANTA CRUZ FACTORS      / FFZ,MCZ,MNZ,CFZ,CTZ /

 fr(f)  SAN CRISTOBAL FACTORS      / FFR,MCR,MNR,CFR,CTR /

 fi(f)  ISABELA FACTORS      / FFI,MCI,MNI,CFI,CTI /

 flab(f) LABOR FACTORS / MCZ,MNZ,MCR,MNR,MCI,MNI /

 h(i) HOUSEHOLDS /  HAZ,HPZ,HEZ,HRZ,HUZ,HAR,HPR,HER,HRR,HUR,HAI,HPI,HEI,HRI,HUI /


 m   EXOGENOUS ACCOUNTS   /
                                        ASZ       Water Treatment SANTA CRUZ
                                        OMZ       Other services SANTA CRUZ
                                        ASR       Water Treatment SAN CRISTOBAL
                                        OMR       Other services SAN CRISTOBAL
                                        ASI       Water Treatment ISABELA
                                        OMI       Other services ISABELA
                                        PN        Galapagos National Park
                                        AD        Water (desalinized)
                                        OI        Other services
                                        GP        Provintial Government
                                        GN        National Government
                                        IN        INECEL
                                        CD        Charles Darwin Station
                                        OO        Other Organizations
                                        AF        Physical Investment
                                        AH        Human Investment
                                        EA        Air Transportaion Ecuador
                                        EO        Other Expenses Ecudaor
                                        EC        Rest of Ecuador - Other Comerce
                                        RA        Air Transportation Rest of World
                                        RC        Other Comerce Rest of World   /

  ALIAS(i,j)
  ALIAS(m,n)
  ALIAS(ip,jp)
  ALIAS(it,jt)
  ALIAS(h,hh)
  ;


$INCLUDE samga.txt

display sam ;
display ex, exr, exex ;

PARAMETERS

 alpha(f,jp)    FACTOR SHARE PARAMETER-PRODUCTION FUNCTION
 al(ip)         PRODUCTION FUNCTION SHIFT PARAMETER
 coltot(j)      SAM COLUMN TOTALS
 exrtot(j)      EXR COLUMN TOTALS
 samio(i,j)     INPUT-OUTPUT COEFFICIENTS, RELATIVE TO ENDOG. COL. TOTALS
 exrio(m,j)     EXOGENOUS ROW SHARES
 qtot           TOTAL PRODUCTION
 pwt(ip)        PRODUCER PRICE DEFLATER WEIGHTS
 tc(ip)         TOTAL CONSUMPTION DEMAND
 ybar(h)        EXOGENOUS HOUSEHOLD INCOME
 sa(jp)         SUM OF ALPHAS
 ;

*######################### PARAMETER ASSIGNMENT ######################


ybar(h) = 0

 ;
*############ SPECIFY PARAMETERS FROM TABLE VALUES ###################


*#####################################################################

 VARIABLES

*#################### VARIABLE DECLARATION ##########################

 Q(jp)         DOMESTIC OUTPUT
 FD(f,jp)      FACTOR DEMAND
 TFD(f)        TOTAL FACTOR DEMAND
 EFD(f)        EXOGENOUS FACTOR DEMAND
 FVA(f)        TOTAL FACTOR VALUE ADDED
 TFY(f)        TOTAL FACTOR INCOME
 RGDP          REAL GDP
 RGDPZ         REAL SANTA CRUZ GDP
 RGDPR         REAL SAN CRISTOBAL GDP
 RGDPI         REAL ISABELA GDP
 W(f)          FACTOR WAGES
 P(ip)         ACTIVITY PRICES
 PVA(ip)       VALUE-ADDED PRICE
 FS(f)         FACTOR SUPPLY
 WFDIST(f,jp)  SECTORAL FACTOR PRICE PROPORTIONALITY RATIO
 Y(h)          HOUSEHOLD TOTAL INCOME
 CD(ip,h)      HOUSEHOLD CONSUMPTION DEMANDS
 CI(n,h)       HOUSEHOLD IMPORT DEMANDS
 CIZ           HOUSEHOLD IMPORT DEMANDS SANTA CRUZ
 CIR           HOUSEHOLD IMPORT DEMANDS SAN CRISTOBAL
 CII           HOUSEHOLD IMPORT DEMANDS ISABELA
 TD(ip,it)     TOURIST DEMAND
 DD(ip)        DOMESTIC DEMAND
 ID(n)         IMPORT DEMAND
 MS(ip)        COMMODITY MARKETED SURPLUS
 INTER(ip)     INTERMEDIATE DEMANDS BY ACTIVITIES
 II(n)         INTERMEDIATE IMPORTS BY ACTIVITIES
 IIZ           INTERMEDIATE IMPORTS SANTA CRUZ
 IIR           INTERMEDIATE IMPORTS SAN CRISTOBAL
 III           INTERMEDIATE IMPORTS ISABEL

 ;


*################## VARIABLE INITIALIZATION #########################

*USE INITIAL VALUES OF VARIABLES (FROM PARAMETER SPECIFICATION)
*FOLLOWING ASSUMES ACTIVITY ACCTS. FEED ONLY INTO COMMODITY ACCOUNTS, AND
*  COMMODITY ACCOUNTS DO THE EXPORTING AND IMPORTING OF FINAL GOODS

*SAM INPUT-OUTPUT COEFFICIENTS
 coltot(j)                = sum(i, SAM(i,j)) ;
 samio(i,j)$coltot(j)     = sam(i,j)/coltot(j) ;
 exrtot(j)                = sum(n, EXR(n,j)) ;
 exrio(n,h)$exrtot(h)     = EXR(n,h)/exrtot(h) ;

*OUTPUT BY SECTOR AND INTERMEDIATE DEMANDS
 Q.L(jp)        = SUM(ip,SAM(ip,jp))+SUM(f,SAM(f,jp))+SUM(it,SAM(it,jp))+SUM(n,EXR(n,jp)) ;
 qtot           = SUM(jp,SUM(ip,SAM(ip,jp))+SUM(f,SAM(f,jp))) ;
 INTER.L(ip)    = SUM(jp,SAM(ip,jp)) ;
 II.L(n)        = SUM(jp,EXR(n,jp)) ;
 IIZ.L          = SUM(n,EXR(n,"agz"))+SUM(n,EXR(n,"pez"))+SUM(n,EXR(n,"stz"))
                  +SUM(n,EXR(n,"cmz"))+SUM(n,EXR(n,"oaz"))+SUM(n,EXR(n,"aaz"))+SUM(n,EXR(n,"ooz")) ;
 IIR.L          = SUM(n,EXR(n,"agr"))+SUM(n,EXR(n,"per"))+SUM(n,EXR(n,"str"))
                  +SUM(n,EXR(n,"cmr"))+SUM(n,EXR(n,"oar"))+SUM(n,EXR(n,"aar"))+SUM(n,EXR(n,"oor")) ;
 III.L          = SUM(n,EXR(n,"agi"))+SUM(n,EXR(n,"pei"))+SUM(n,EXR(n,"sti"))
                  +SUM(n,EXR(n,"cmi"))+SUM(n,EXR(n,"oai"))+SUM(n,EXR(n,"aai"))+SUM(n,EXR(n,"ooi")) ;

 display Q.L,INTER.L,II.L ;

*ADJUST I-O COEFFICIENTS FROM samio (cambio: $q.l(jp))
 samio(ip,jp)   = SAM(ip,jp)/Q.L(jp) ;
 samio(it,jp)   = SAM(it,jp)/Q.L(jp) ;
 exrio(n,jp)    = EXR(n,jp)/Q.L(jp) ;

*PRICES
 W.L(f)         = 1.0 ;
 P.L(ip)        = 1.0 ;
 WFDIST.L(f,jp) = 1.0 ;
 PVA.L(ip)      = P.L(ip) - SUM(jp, samio(jp,ip)*P.L(jp)) - SUM(jt,samio(jt,ip))
                                                       - SUM(n,exrio(n,ip)) ;
*## SPECIFY WEIGHTS FOR PRODUCER PRICE INDEX
 pwt(jp)    = SUM(ip,SAM(ip,jp))+SUM(f,SAM(f,jp))/qtot ;
 DISPLAY pwt,pva.l ;

*FACTOR DEMAND, SUPPLY, AND VALUE-ADDED IN GOODS PRODUCTION
 FD.L(f,jp)     = SAM(f,jp) ;
 FVA.L(f)       = sum(jp,SAM(f,jp)) ;
 TFY.L(f)       = FVA.L(f) + SUM(n,EX(f,n)) ;

*PARAMETERS OF COBB-DOUGLAS PRODUCTION FUNCTIONS (cambio: $q.l(j,p))
 alpha(f,jp)$Q.L(jp)   = SAM(f,jp)/(Q.L(jp)*PVA.L(jp)) ;
 al(jp)  = Q.L(jp)/PROD(f,FD.L(f,jp)**alpha(f,jp)) ;
 sa(jp)  = SUM(f,alpha(f,jp)) ;

 DISPLAY alpha,al,sa ;

 FD.L(f,jp)  =  PVA.L(jp)*Q.L(jp)*alpha(f,jp)/(W.L(f)*WFDIST.L(f,jp)) ;
 DISPLAY FD.L ;

*TOTAL FACTOR DEMAND
 TFD.L(f)       = SUM(jp,SAM(f,jp))+SUM(n,EX(f,n)) ;
 FS.L(f)        = TFD.L(f) ;
 EFD.L(f)       = SUM(n,EX(f,n)) ;

*HOUSEHOLD INCOMES AND CONSUMPTION DEMAND
 Y.L(h)         = SUM(j, SAM(h,j))+SUM(n,EX(h,n))+ybar(h) ;
 CD.L(ip,h)     = SAM(ip,h) ;
 CI.L(n,h)      = EXR(n,h) ;
 CIZ.L          = SUM(n,EXR(n,"haz")+EXR(n,"hpz")+EXR(n,"hez")
                  +EXR(n,"hrz")+EXR(n,"huz")) ;
 CIR.L          = SUM(n,EXR(n,"har")+EXR(n,"hpr")+EXR(n,"her")
                  +EXR(n,"hrr")+EXR(n,"hur")) ;
 CII.L          = SUM(n,EXR(n,"hai")+EXR(n,"hpi")+EXR(n,"hei")
                  +EXR(n,"hri")+EXR(n,"hui")) ;
 TD.L(ip,it)    = SAM(ip,it);
 TC(ip)         = SUM(h,SAM(ip,h)) ;
 display y.l, tfd.l, td.l ;
 Y.L(h)         =  SUM(f,(TFY.L(f)*samio(h,f)))+SUM(n,EX(h,n))
                     +SUM(hh,SAM(h,hh)) ;
 DISPLAY Y.L ;

*ADJUST samio FOR HOUSEHOLD CONSUMPTION AND SAVING SHARES
 samio(i,h)    = SAM(i,h)/Y.L(h) ;
 DISPLAY SAMIO ;

*TOTAL SUPPLY FROM ISLANDS, TOTAL ISLAND DEMAND, AND MARKETED SURPLUS
 DD.L(ip)       = SUM(jp,SAM(ip,jp))+SUM(h,SAM(ip,h))+SUM(jt,SAM(ip,jt)) ;
 ID.L(n)        = SUM(jp,EXR(n,jp))+SUM(h,EXR(n,h))  ;
 MS.L(ip)       = Q.L(ip)-DD.L(ip) ;
 display dd.l ;

*ISLAND GDP (OBJECTIVE VARIABLE)
 RGDP.L         = SUM(f,FVA.L(f)) ;
 RGDPZ.L        = SUM(fz,FVA.L(fz)) ;
 RGDPR.L        = SUM(fr,FVA.L(fr)) ;
 RGDPI.L        = SUM(fi,FVA.L(fi)) ;

*CHECK TO REPLICATE SAM FROM INITIALIZED VARIABLES
 PARAMETER SAM2(i,j)     RECONSTRUCTED SAM MATRIX ;
 SAM2(ip,jp)       = Q.L(jp)*samio(ip,jp) ;
 SAM2(f,jp)        = FD.L(f,jp)*W.L(f)*WFDIST.L(f,jp) ;
 SAM2(h,f)         = TFY.L(f)*samio(h,f) ;
 SAM2(ip,h)        = P.L(ip)*CD.L(ip,h) ;
 SAM2(h,hh)        = SAM(h,hh) ;

 DISPLAY SAM2 ;

*###################### END VARIABLE SPECIFICATION ###################

*#####################################################################
 EQUATIONS
*#################### EQUATION DECLARATION ###########################
   PVAEQ(jp)        VALUE-ADDED PRICE EQUATION
   QEQ(jp)          PRODUCTION FUNCTIONS
   INTEREQ(ip)      INTERMEDIATE DEMAND
   IIEQ(n)          INTERMEDIATE IMPORTS
   IIZEQ            INTERMEDIATE IMPORTS SANTA CRUZ
   IIREQ            INTERMEDIATE IMPORTS SAN CRISTOBAL
   IIIEQ            INTERMEDIATE IMPORTS ISABEL
   FDEQ(f,ip)       FACTOR DEMAND EQUATIONS
   NOFDEQ(f,ip)     ZERO FACTOR DEMAND EQUATIONS
   TFDEQ(f)         TOTAL (NONFAMILY) FACTOR DEMAND EQUATION
   VAEQ(f)          FACTOR VALUE-ADDED EQUATION
   TFYEQ(f)         TOTAL FACTOR INCOME EQUATION
   INCEQ(h)         HOUSEHOLD INCOME EQUATION
   CDEQ(ip,h)       HOUSEHOLD CONSUMPTION DEMAND EQUATIONS
   CIEQ(n,h)        HOUSEHOLD IMPORT DEMAND EQUATIONS
   CIZEQ            HOUSEHOLD IMPORT DEMAND SANTA CRUZ EQUATIONS
   CIREQ            HOUSEHOLD IMPORT DEMAND SAN CRISTOBAL EQUATIONS
   CIIEQ            HOUSEHOLD IMPORT DEMAND ISABEL EQUATIONS
   DDEQ(ip)         DOMESTIC DEMAND EQUATION
   IDEQ(n)          IMPORT DEMAND EQUATION
   EQUILIB(ip)      PRODUCT MARKET EQUILIBRIUM
   FMEQUIL(f)       FACTOR MARKET EQUILIBRIUM
   RGDPEQ           REAL GDP EQUATION
   RGDPZEQ          REAL SANTA CRUZ GDP EQUATION
   RGDPREQ          REAL SAN CRISTOBAL GDP EQUATION
   RGDPIEQ          REAL ISABELA GDP EQUATION
   ;
*######################## EQUATION ASSIGNMENT  #######################

*##PRICES

 PVAEQ(jp)..     PVA(jp)      =E= P(jp) - SUM(ip, samio(ip,jp)*P(ip)) -SUM(jt,samio(jt,jp))
                                    -SUM(n,exrio(n,jp));

*PRODUCTION AND INTERMEDIATE AND FACTOR DEMANDS
 QEQ(jp)..      Q(jp)  =E= al(jp)*PROD(f$alpha(f,jp),FD(f,jp)**alpha(f,jp)) ;

 INTEREQ(ip)..  INTER(ip) =E= SUM(jp,Q(jp)*samio(ip,jp)) ;

 IIEQ(n)..   II(n) =E= SUM(jp,Q(jp)*exrio(n,jp)) ;

 IIZEQ..     IIZ   =E= SUM(n,Q("agz")*exrio(n,"agz"))+SUM(n,Q("pez")*exrio(n,"pez"))
                        +SUM(n,Q("stz")*exrio(n,"stz"))+SUM(n,Q("cmz")*exrio(n,"cmz"))
                        +SUM(n,Q("oaz")*exrio(n,"oaz"))+SUM(n,Q("aaz")*exrio(n,"aaz"))
                        +SUM(n,Q("ooz")*exrio(n,"ooz")) ;

 IIREQ..     IIR   =E= SUM(n,Q("agr")*exrio(n,"agr"))+SUM(n,Q("per")*exrio(n,"per"))
                        +SUM(n,Q("str")*exrio(n,"str"))+SUM(n,Q("cmr")*exrio(n,"cmr"))
                        +SUM(n,Q("oar")*exrio(n,"oar"))+SUM(n,Q("aar")*exrio(n,"aar"))
                        +SUM(n,Q("oor")*exrio(n,"oor")) ;

 IIIEQ..     III   =E= SUM(n,Q("agi")*exrio(n,"agi"))+SUM(n,Q("pei")*exrio(n,"pei"))
                        +SUM(n,Q("sti")*exrio(n,"sti"))+SUM(n,Q("cmi")*exrio(n,"cmi"))
                        +SUM(n,Q("oai")*exrio(n,"oai"))+SUM(n,Q("aai")*exrio(n,"aai"))
                        +SUM(n,Q("ooi")*exrio(n,"ooi")) ;

*OBTAIN FACTOR DEMANDS FROM COBB DOUGLAS FOCS FOR PROFIT MAXIMIZATION
 FDEQ(f,jp)$SAM(f,jp)..  FD(f,jp)*W(f)*WFDIST(f,jp) =E=  PVA(jp)*Q(jp)*alpha(f,jp) ;
 NOFDEQ(f,jp)$(SAM(f,jp) EQ 0)..   FD(f,jp) =E= 0 ;

*TOTAL FACTOR DEMAND
 TFDEQ(f)..     TFD(f)   =E= SUM(jp,FD(f,jp)) + EFD(f) ;

*TOTAL FACTOR VALUE ADDED
 VAEQ(f)..      FVA(f)   =E= W(f)*SUM(ip,FD(f,ip)*WFDIST(f,ip)) ;

*TOTAL FACTOR INCOME (INCL. FACTOR EXPORTS)
 TFYEQ(f)..     TFY(f)   =E=  FVA(f) + SUM(n,EX(f,n)) ;

*HOUSEHOLD INCOMES AND CONSUMPTION DEMANDS
 INCEQ(h)..     Y(h)     =E=  SUM(f,(TFY(f)*samio(h,f)))
                              +SUM(n,EX(h,n))
                              +SUM(hh,SAM(h,hh))+ybar(h) ;

 CDEQ(ip,h)..   P(ip)*CD(ip,h)  =E=  samio(ip,h)*Y(h) ;

 CIEQ(n,h)..          CI(n,h)   =E=  exrio(n,h)*Y(h) ;

 CIZEQ..              CIZ       =E= SUM(n,exrio(n,"haz")*Y("haz")+exrio(n,"hpz")*Y("hpz")
                                    +exrio(n,"hez")*Y("hez")+exrio(n,"hrz")*Y("hrz")
                                    +exrio(n,"huz")*Y("huz")) ;

 CIREQ..              CIR       =E= SUM(n,exrio(n,"har")*Y("har")+exrio(n,"hpr")*Y("hpr")
                                    +exrio(n,"her")*Y("her")+exrio(n,"hrr")*Y("hrr")
                                    +exrio(n,"hur")*Y("hur")) ;

 CIIEQ..              CII       =E= SUM(n,exrio(n,"hai")*Y("hai")+exrio(n,"hpi")*Y("hpi")
                                    +exrio(n,"hei")*Y("hei")+exrio(n,"hri")*Y("hri")
                                    +exrio(n,"hui")*Y("hui")) ;


*TOTAL ISLAND DEMAND
 DDEQ(ip)..     DD(ip)    =E=  INTER(ip)+SUM(h,CD(ip,h))+SUM(it,TD(ip,it)) ;

*TOTAL ISLAND DIRECT IMPORTS
 IDEQ(n)..      ID(n)     =E=  II(n)+SUM(h,CI(n,h)) ;

*MARKET EQUILIBRIUM DETS. MKTD. SURPLUS (TRADABLES) OR PRICE (NONTRADABLES)
 EQUILIB(ip)..  MS(ip)    =E=  Q(ip) - DD(ip) ;

*FACTOR MARKET EQUILIB. DETS. WAGE OR UNEMPLOYMENT LEVEL
 FMEQUIL(f)..   TFD(f)    =E=  FS(f) ;

*REAL VILLAGE GDP IS "OBJECTIVE VARIABLE" REQD. BY GAMS
 RGDPEQ..       RGDP      =E=  SUM(f,FVA(f)) ;
 RGDPZEQ..      RGDPZ     =E=  SUM(fz,FVA(fz)) ;
 RGDPREQ..      RGDPR     =E=  SUM(fr,FVA(fr)) ;
 RGDPIEQ..      RGDPI     =E=  SUM(fr,FVA(fr)) ;

*#### ADDITIONAL RESTRICTIONS CORRESPONDING TO EQUATIONS

*VARIABLE BOUNDS
 P.LO(ip)   = 0.01 ;  Q.LO(ip)   = 0.01 ;
 W.LO(f)    = 0.01 ;   FD.LO(f,ip)$(SAM(f,ip) NE 0) = 0.01 ;
 FD.LO(f,ip)$(FD.L(f,ip) EQ 0) = 0.00 ;
 PVA.LO(ip) = 0.01 ;

*FIX PRICES OF TRADABLE GOODS, FIX MS OF NONTRADABLES
  P.LO("agz")      = 0.01 ;  P.UP("agz") = INF ;
  MS.FX("agz")     = MS.L("agz") ;
  P.LO("pez")      = 0.01 ;  P.UP("pez") = INF ;
  MS.FX("pez")     = MS.L("pez") ;
  P.LO("stz")      = 0.01 ;  P.UP("stz") = INF ;
  MS.FX("stz")     = MS.L("stz") ;
  P.LO("aaz")      = 0.01 ;  P.UP("aaz") = INF ;
  MS.FX("aaz")     = MS.L("aaz") ;
  P.LO("ooz")      = 0.01 ;  P.UP("ooz") = INF ;
  MS.FX("ooz")     = MS.L("ooz") ;
  MS.FX("cmz")     = MS.L("cmz") ;
  MS.FX("oaz")     = MS.L("oaz") ;

  P.LO("agr")      = 0.01 ;  P.UP("agr") = INF ;
  MS.FX("agr")     = MS.L("agr") ;
  P.LO("per")      = 0.01 ;  P.UP("per") = INF ;
  MS.FX("per")     = MS.L("per") ;
 P.LO("str")       = 0.01 ;  P.UP("str") = INF ;
 MS.FX("str")      = MS.L("str") ;
 P.LO("aar")       = 0.01 ;  P.UP("aar") = INF ;
 MS.FX("aar")      = MS.L("aar") ;
 P.LO("oor")       = 0.01 ;  P.UP("oor") = INF ;
 MS.FX("oor")      = MS.L("oor") ;
  MS.FX("cmr")     = MS.L("cmr") ;
  MS.FX("oar")     = MS.L("oar") ;

  P.LO("agi")      = 0.01 ;  P.UP("agi") = INF ;
  MS.FX("agi")     = MS.L("agi") ;
  P.LO("pei")      = 0.01 ;  P.UP("pei") = INF ;
  MS.FX("pei")     = MS.L("pei") ;
 P.LO("sti")       = 0.01 ;  P.UP("sti") = INF ;
 MS.FX("sti")      = MS.L("sti") ;
 P.LO("aai")       = 0.01 ;  P.UP("aai") = INF ;
 MS.FX("aai")      = MS.L("aai") ;
 P.LO("ooi")       = 0.01 ;  P.UP("ooi") = INF ;
 MS.FX("ooi")      = MS.L("ooi") ;
  MS.FX("cmi")     = MS.L("cmi") ;
  MS.FX("oai")     = MS.L("oai") ;

  TD.FX(ip,it)     = TD.L(ip,it) ;


*FIXED WAGE (ENDOGENOUS UNEMPLOYMENT)

* To simulate the same increase assuming migration is
* constrained and, thus, local wages vary:
* star (*) the W.FX("mcz"), W.FX("mcr"), W.FX("mci"), W.FX("mnz"),
* W.FX("mnr") and W.FX("mni") rows below and
* unstar the FS.FX("mcz"), FS.FX("mcr"), FS.FX("mci"), FS.FX("mnz"),
* FS.FX("mnr") and FS.FX("mni").

* This will effectively set local wages free to adjust to labor demand
* and fix the factor supply of skill and unskilled labor in all three
* islands.

 EFD.FX(f)         = EFD.L(f)    ;

 W.FX("ffz")       = W.L("ffz")  ;
 W.FX("ffr")       = W.L("ffr")  ;
 W.FX("ffi")       = W.L("ffi")  ;
 W.FX("mcz")       = W.L("mcz")  ;
 W.FX("mnz")       = W.L("mnz")  ;
 W.FX("mcr")       = W.L("mcr")  ;
 W.FX("mnr")       = W.L("mnr")  ;
 W.FX("mci")       = W.L("mci")  ;
 W.FX("mni")       = W.L("mni")  ;
* FS.FX("ffz")       = FS.L("ffz") ;
* FS.FX("ffr")       = FS.L("ffr") ;
* FS.FX("ffi")       = FS.L("ffi") ;
* FS.FX("mcz")       = FS.L("mcz") ;
* FS.FX("mcr")       = FS.L("mcr") ;
* FS.FX("mci")       = FS.L("mci") ;
* FS.FX("mnz")       = FS.L("mnz") ;
* FS.FX("mnr")       = FS.L("mnr") ;
* FS.FX("mni")       = FS.L("mni") ;
* FD.FX("mni",jp)    = FD.L("mni",jp) ;


 WFDIST.FX("ffz",jp) = WFDIST.L("ffz",jp) ;
 WFDIST.FX("ffr",jp) = WFDIST.L("ffr",jp) ;
 WFDIST.FX("ffi",jp) = WFDIST.L("ffi",jp) ;
 WFDIST.FX("mcz",jp) = WFDIST.L("mcz",jp) ;
 WFDIST.FX("mnz",jp) = WFDIST.L("mnz",jp) ;
 WFDIST.FX("mcr",jp) = WFDIST.L("mcr",jp) ;
 WFDIST.FX("mnr",jp) = WFDIST.L("mnr",jp) ;
 WFDIST.FX("mci",jp) = WFDIST.L("mci",jp) ;
 WFDIST.FX("mni",jp) = WFDIST.L("mni",jp) ;

*FIXED INPUTS
 FD.FX("cfz",jp)  =  FD.L("cfz",jp) ;
 FD.FX("cfr",jp)  =  FD.L("cfr",jp) ;
 FD.FX("cfi",jp)  =  FD.L("cfi",jp) ;
 FD.FX("ctz",jp)  =  FD.L("ctz",jp) ;
 FD.FX("ctr",jp)  =  FD.L("ctr",jp) ;
 FD.FX("cti",jp)  =  FD.L("cti",jp) ;
 FS.FX("ctz")     = FS.L("ctz") ;
 FS.FX("ctr")     = FS.L("ctr") ;
 FS.FX("cti")     = FS.L("cti") ;

*########################### END OF MODEL ############################

*#### MODEL SOLVE STATEMENTS

 OPTIONS ITERLIM=1000,LIMROW=1,LIMCOL=1, SOLPRINT=Off;

*USE SOLPRINT=OFF TO TURN OFF STANDARD SOLUTION PRINTOUT

 MODEL cge /ALL/ ;

 cge.OPTFILE = 1 ;

 SOLVE cge MAXIMIZING RGDP USING NLP;

 OPTION DECIMALS=2 ;

*#### SET UP TABLES TO REPORT OUTPUT

 PARAMETER P1(ip)         BASE ACTIVITY PRICES ;
 PARAMETER RGDP1          BASE REAL GDP ;
 PARAMETER RGDPZ1         BASE REAL SANTA CRUZ GDP ;
 PARAMETER RGDPR1         BASE REAL SAN CRISTOBAL GDP ;
 PARAMETER RGDPI1         BASE REAL ISABELA GDP ;
 PARAMETER Q1(ip)         BASE SECTORAL OUTPUT ;
 PARAMETER FD1(f,ip)      BASE FACTOR DEMAND ;
 PARAMETER TFD1(f)        BASE TOTAL FACTOR DEMAND ;
 PARAMETER TLAB1          BASE TOTAL LABOR DEMAND ;
 PARAMETER SLDZ1          BASE SALARY LABOR DEMAND SCRUZ  ;
 PARAMETER SLDR1          BASE SALARY LABOR DEMAND SCRISTOBAL  ;
 PARAMETER SLDI1          BASE SALARY LABOR DEMAND ISABEL  ;
 PARAMETER TMIGZ1         BASE TOTAL LABOR DEMAND  SCRUZ ;
 PARAMETER TMIGR1         BASE TOTAL LABOR DEMAND  SCRISTOBAL;
 PARAMETER TMIGI1         BASE TOTAL LABOR DEMAND  ISABEL ;
 PARAMETER PVA1(ip)       BASE VALUE-ADDED PRICE ;
 PARAMETER W1(f)          BASE FACTOR WAGES ;
 PARAMETER WFDIST1(f,ip)  BASE FACTOR PRICE PROPORTIONS ;
 PARAMETER Y1(h)          BASE HOUSEHOLD INCOME ;
 PARAMETER CPI1(h)        BASE HOUSEHOLD CPI ;
 PARAMETER RY1(h)         BASE HOUSEHOLD REAL INCOME ;
 PARAMETER TYZ1           BASE TOTAL SANTA CRUZ HOUSEHOLD INCOME ;
 PARAMETER TYR1           BASE TOTAL SAN CRISTOBAL HOUSEHOLD INCOME ;
 PARAMETER TYI1           BASE TOTAL ISABELA HOUSEHOLD INCOME ;
 PARAMETER TRYZ1          BASE TOTAL REAL SANTA CRUZ HOUSEHOLD INCOME ;
 PARAMETER TRYR1          BASE TOTAL REAL SAN CRISTOBAL HOUSEHOLD INCOME ;
 PARAMETER TRYI1          BASE TOTAL REAL ISABELA HOUSEHOLD INCOME ;
 PARAMETER TRY1           BASE TOTAL HOUSEHOLD INCOME ;
 PARAMETER TRYPW1         BASE TOTAL HOUSEHOLD INCOME PER WORKER ;
 PARAMETER CD1(ip,h)      BASE HOUSEHOLD CONSUMPTION DEMANDS ;
 PARAMETER CI1(n,h)       BASE HOUSEHOLD INCOME DEMANDS ;
 PARAMETER CIZ1           BASE HOUSEHOLD INCOME DEMANDS SANTA CRUZ  ;
 PARAMETER CIR1           BASE HOUSEHOLD INCOME DEMANDS SAN CRISTOBAL ;
 PARAMETER CII1           BASE HOUSEHOLD INCOME DEMANDS ISABELA ;
 PARAMETER DD1(ip)        BASE DOMESTIC DEMAND ;
 PARAMETER ID1(n)         BASE IMPORT DEMAND ;
 PARAMETER IDZ1           BASE IMPORT DEMAND SANTA CRUZ ;
 PARAMETER IDR1           BASE IMPORT DEMAND SAN CRISTOBAL;
 PARAMETER IDI1           BASE IMPORT DEMAND ISABELA;
 PARAMETER IMPZ1          BASE IMPORT DEMAND SANTA CRUZ ;
 PARAMETER IMPR1          BASE IMPORT DEMAND SAN CRISTOBAL ;
 PARAMETER IMPI1          BASE IMPORT DEMAND ISABELA ;
 PARAMETER INTER1(ip)     BASE INTERMEDIATE DEMAND BY COMMODITY ;
 PARAMETER II1(n)         BASE INTERMEDIATE IMPORTS BY COMMODITY ;
 PARAMETER IIZ1           BASE INTERMEDIATE IMPORTS SANTA CRUZ ;
 PARAMETER IIR1           BASE INTERMEDIATE IMPORTS SAN CRISTOBAL ;
 PARAMETER III1           BASE INTERMEDIATE IMPORTS ISABEL ;
 PARAMETER MS1(ip)        BASE COMMODITY MARKETED SURPLUS ;
 PARAMETER EFD1(f)        BASE EXOGENOUS FACTOR DEMAND ;

 P1(ip)             = P.L(ip) ;
 RGDP1              = RGDP.L ;
 RGDPZ1             = RGDPZ.L ;
 RGDPR1             = RGDPR.L ;
 RGDPI1             = RGDPI.L ;
 Q1(ip)             = Q.L(ip) ;
 FD1(f,ip)          = FD.L(f,ip) ;
 TFD1(f)            = TFD.L(f) ;
 TLAB1              = SUM(flab,TFD.L(flab)) ;
 SLDZ1              = SUM(ip,FD.L("mcz",ip)+FD.L("mnz",ip)) ;
 SLDR1              = SUM(ip,FD.L("mcr",ip)+FD.L("mnr",ip)) ;
 SLDI1              = SUM(ip,FD.L("mci",ip)+FD.L("mni",ip)) ;
 TMIGZ1             = SUM(ip,FD.L("mcz",ip)+FD.L("mnz",ip)+FD.L("ffz",ip)) ;
 TMIGR1             = SUM(ip,FD.L("mcr",ip)+FD.L("mnr",ip)+FD.L("ffr",ip)) ;
 TMIGI1             = SUM(ip,FD.L("mci",ip)+FD.L("mni",ip)+FD.L("ffi",ip)) ;
 PVA1(ip)           = PVA.L(ip) ;
 W1(f)              = W.L(f) ;
 WFDIST1(f,ip)      = WFDIST.L(f,ip) ;
 Y1(h)              = Y.L(h) ;
 CPI1(h)            = SUM(ip,samio(ip,h)*P1(ip))/sum(ip,samio(ip,h)) ;
 TYZ1               = Y.L("haz")+Y.L("hpz")+Y.L("hez")+Y.L("hrz")+Y.L("huz");
 TYR1               = Y.L("har")+Y.L("hpr")+Y.L("her")+Y.L("hrr")+Y.L("hur");
 TYI1               = Y.L("hai")+Y.L("hpi")+Y.L("hei")+Y.L("hri")+Y.L("hui");
 RY1(h)             = Y.L(h)/CPI1(h) ;
 TRYZ1              = Y.L("haz")/CPI1("haz")+
                      Y.L("hpz")/CPI1("hpz")+
                      Y.L("hez")/CPI1("hez")+
                      Y.L("hrz")/CPI1("hrz")+
                      Y.L("huz")/CPI1("huz");
 TRYR1              = Y.L("har")/CPI1("har")+
                      Y.L("hpr")/CPI1("hpr")+
                      Y.L("her")/CPI1("her")+
                      Y.L("hrr")/CPI1("hrr")+
                      Y.L("hur")/CPI1("hur");
 TRYI1              = Y.L("hai")/CPI1("hai")+
                      Y.L("hpi")/CPI1("hpi")+
                      Y.L("hei")/CPI1("hei")+
                      Y.L("hri")/CPI1("hri")+
                      Y.L("hui")/CPI1("hui");
 TRY1               = TRYZ1+TRYR1+TRYI1 ;
 TRYPW1             = TRY1/TLAB1 ;
 CD1(ip,h)          = CD.L(ip,h) ;
 CI1(n,h)           = CI.L(n,h) ;
 CIZ1               = CIZ.L ;
 CIR1               = CIR.L ;
 CII1               = CII.L ;
 DD1(ip)            = DD.L(ip) ;
 ID1(n)             = ID.L(n) ;
 IDZ1               = IIZ.L+CIZ.L ;
 IDR1               = IIR.L+CIR.L ;
 IDI1               = III.L+CII.L ;
 INTER1(ip)         = INTER.L(ip) ;
 II1(n)             = II.L(n) ;
 IIZ1               = IIZ.L ;
 IIR1               = IIR.L ;
 III1               = III.L ;
 MS1(ip)            = MS.L(ip) ;
 EFD1(f)            = EFD.L(f) ;

*#### DISPLAY OUTPUT
 DISPLAY P1 ;
 DISPLAY RGDP1 ;
 DISPLAY Q1 ;
 DISPLAY FD1 ;
 DISPLAY TFD1 ;
 DISPLAY TLAB1 ;
 DISPLAY SLDZ1 ;
 DISPLAY SLDR1 ;
 DISPLAY SLDI1 ;
 DISPLAY TMIGZ1 ;
 DISPLAY TMIGR1 ;
 DISPLAY TMIGI1 ;
 DISPLAY PVA1 ;
 DISPLAY W1 ;
 DISPLAY WFDIST1 ;
 DISPLAY Y1 ;
 DISPLAY CPI1 ;
 DISPLAY RY1 ;
 DISPLAY TYZ1 ;
 DISPLAY TYR1 ;
 DISPLAY TYI1 ;
 DISPLAY TRYZ1 ;
 DISPLAY TRYR1 ;
 DISPLAY TRYI1 ;
 DISPLAY CD1 ;
 DISPLAY CI1 ;
 DISPLAY CIZ1 ;
 DISPLAY CIR1 ;
 DISPLAY CII1 ;
 DISPLAY DD1 ;
 DISPLAY ID1 ;
 DISPLAY IDZ1 ;
 DISPLAY IDR1 ;
 DISPLAY IDI1 ;
 DISPLAY INTER1 ;
 DISPLAY II1 ;
 DISPLAY IIZ1 ;
 DISPLAY IIR1 ;
 DISPLAY III1 ;
 DISPLAY MS1 ;
 DISPLAY EFD1 ;

 PARAMETER SAM3(i,j)     RECONSTRUCTED SAM MATRIX ;
 SAM3(ip,jp)       = Q.L(jp)*samio(ip,jp) ;
 SAM3(f,jp)        = FD.L(f,jp)*W.L(f)*WFDIST.L(f,jp) ;
 SAM3(h,f)         = TFY.L(f)*samio(h,f) ;
 SAM3(ip,h)        = P.L(ip)*CD.L(ip,h) ;
 SAM3(h,hh)        = SAM(h,hh) ;
 DISPLAY SAM3 ;

*#############################################
*EXPERIMENTS
*#############################################

$OFFSYMXREF OFFSYMLIST
*This experiment increases ecotourism (both domestic and foreign) by 162%,
*the actual increase between 1999 and 2010

 TD.FX(ip,"et") = TD.L(ip,"et")*2.62 ;
 TD.FX(ip,"rt") = TD.L(ip,"rt")*2.62 ;

 OPTIONS ITERLIM=1000,LIMROW=0,LIMCOL=0, SOLPRINT=Off;
 SOLVE cge MAXIMIZING RGDP USING NLP;

 OPTION DECIMALS=2 ;

*#### SET UP TABLES TO REPORT OUTPUT AS % CHANGE FROM BASE

 PARAMETER P2(ip)         NEW ACTIVITY PRICES ;
 PARAMETER RGDP2          NEW REAL GDP ;
 PARAMETER RGDPV2         NEW REAL VILLAGE GDP ;
 PARAMETER RGDPT2         NEW REAL TOWN GDP ;
 PARAMETER Q2(ip)         NEW SECTORAL OUTPUT ;
 PARAMETER FD2(f,ip)      NEW FACTOR DEMAND ;
 PARAMETER TFD2(f)        NEW TOTAL FACTOR DEMAND ;
 PARAMETER TLAB2          NEW TOTAL LABOR DEMAND ;
 PARAMETER SLDZ2          NEW SALARY LABOR DEMAND SCRUZ ;
 PARAMETER SLDR2          NEW SALARY LABOR DEMAND SCRISTOBAL ;
 PARAMETER SLDI2          NEW SALARY LABOR DEMAND ISABEL ;
 PARAMETER TMIGZ2         NEW TOTAL LABOR DEMAND SCRUZ ;
 PARAMETER TMIGR2         NEW TOTAL LABOR DEMAND SCRISTOBAL ;
 PARAMETER TMIGI2         NEW TOTAL LABOR DEMAND ISABEL ;
 PARAMETER PVA2(ip)       NEW VALUE-ADDED PRICE ;
 PARAMETER W2(f)          NEW FACTOR WAGES ;
 PARAMETER WFDIST2(f,ip)  NEW FACTOR PRICE PROPORTIONS ;
 PARAMETER Y2(h)          NEW HOUSEHOLD INCOME ;
 PARAMETER CPI2(h)        NEW CPI ;
 PARAMETER RY2(h)         NEW HOUSEHOLD REAL INCOME ;
 PARAMETER TRYZ2          NEW TOTAL REAL SANTA CRUZ HOUSEHOLD INCOME ;
 PARAMETER TRYR2          NEW TOTAL REAL SAN CRISTOBAL HOUSEHOLD INCOME ;
 PARAMETER TRYI2          NEW TOTAL REAL ISABELA HOUSEHOLD INCOME ;

 PARAMETER TRY2           NEW TOTAL HOUSEHOLD REAL INCOME ;
 PARAMETER TRYPW2         NEW TOTAL HOUSEHOLD REAL INCOME PER WORKER ;
 PARAMETER TYT2           NEW TOTAL TOWN HOUSEHOLD INCOME ;
 PARAMETER TRYV2          NEW REAL VILLAGE TOTAL HOUSEHOLD INCOME ;
 PARAMETER TRYT2          NEW REAL TOWN TOTAL HOUSEHOLD INCOME ;

 PARAMETER CD2(ip,h)      NEW HOUSEHOLD CONSUMPTION DEMANDS ;
 PARAMETER CI2(n,h)       NEW HOUSEHOLD IMPORT DEMANDS ;
 PARAMETER SAVINGS2       NEW SAVINGS ;
 PARAMETER SAVINGSVK2     NEW VILLAGE SAVINGS ON CAPITAL ;
 PARAMETER SAVINGSVH2     NEW VILLAGE SAVINGS ON HUMAN CAPITAL;
 PARAMETER SAVINGSTK2     NEW TOWN SAVINGS ON CAPITAL ;
 PARAMETER SAVINGSTH2     NEW TOWN SAVINGS ON HUMAN CAPITAL ;
 PARAMETER INVEST2        NEW INVESTMENT ;
 PARAMETER DD2(ip)        NEW VILLAGE DEMAND ;
 PARAMETER ID2(n)         NEW IMPORT DEMAND ;
 PARAMETER IDZ2           NEW IMPORT DEMAND SANTA CRUZ ;
 PARAMETER IDR2           NEW IMPORT DEMAND SAN CRISTOBAL ;
 PARAMETER IDI2           NEW IMPORT DEMAND ISABELA ;
 PARAMETER INTER2(ip)     NEW INTERMEDIATE DEMAND BY COMMODITY ;
 PARAMETER II2(n)         NEW INTERMEDIATE DEMAND BY COMMODITY ;
 PARAMETER MS2(ip)        NEW COMMODITY MARKETED SURPLUS ;
 PARAMETER EFD2(f)        NEW EXOGENOUS FACTOR DEMAND ;


 PARAMETER DP2(ip)         % CHANGE IN ACTIVITY PRICES ;
 PARAMETER DRGDP2          % ANNUAL RATE OF CHANGE IN REAL PER-CAPITA GDP ;
 PARAMETER DRPCGDP2        % ANNUAL RATE OF CHANGE IN REAL PER-CAPITA GDP ;
 PARAMETER DRGDPV2         % CHANGE IN REAL VILLAGE GDP ;
 PARAMETER DRGDPT2         % CHANGE IN REAL TOWN GDP ;
 PARAMETER DQ2(ip)         % CHANGE IN SECTORAL OUTPUT ;
 PARAMETER DFD2(f,ip)      % CHANGE IN FACTOR DEMAND ;
 PARAMETER DTFD2(f)        % CHANGE IN TOTAL FACTOR DEMAND ;
 PARAMETER DLAB2           % CHANGE IN TOTAL LABOR DEMAND ;
 PARAMETER DSLDZ2          % CHANGE SALARY LABOR DEMAND SCRUZ ;
 PARAMETER DSLDR2          % CHANGE SALARY LABOR DEMAND SCRISTOBAL ;
 PARAMETER DSLDI2          % CHANGE SALARY LABOR DEMAND ISABEL ;

* DTMIG VARIABLES MAY BE INTERPRETED AS MIGRATION REQUIRED TO FILL NEW
* LABOR DEMAND GIVEN ISLAND LABOR SUPPLY AND WAGES.  THIS MIGRATION IS
* EXPRESSED HERE RELATIVE TO SIZE OF TOTAL ISLAND LABOR FORCES.

 PARAMETER DTMIGZ2         % CHANGE TOTAL LABOR DEMAND SCRUZ ;
 PARAMETER DTMIGR2         % CHANGE TOTAL LABOR DEMAND SCRISTOBAL ;
 PARAMETER DTMIGI2         % CHANGE TOTAL LABOR DEMAND ISABEL ;
 PARAMETER DPVA2(ip)       % CHANGE IN VALUE-ADDED PRICE ;
 PARAMETER DW2(f)          % CHANGE IN FACTOR WAGES ;
 PARAMETER DWFDIST2(f,ip)  % CHANGE IN FACTOR PRICE PROPORTIONS ;
 PARAMETER DY2(h)          % CHANGE IN HOUSEHOLD INCOME ;
 PARAMETER DCPI2(h)        % CHANGE IN CPI ;
 PARAMETER DRY2(h)         % CHANGE IN HOUSEHOLD REAL INCOME ;
 PARAMETER DTRYZ2          % CHANGE IN TOTAL REAL SANTA CRUZ HOUSEHOLD INCOME ;
 PARAMETER DTRYR2          % CHANGE IN TOTAL REAL SAN CRISTOBAL HOUSEHOLD INCOME ;
 PARAMETER DTRYI2          % CHANGE IN TOTAL REAL ISABELA HOUSEHOLD INCOME ;
 PARAMETER DTRY2           % CHANGE IN TOTAL REAL HOUSEHOLD INCOME ;
 PARAMETER DTRY2           % CHANGE IN TOTAL HOUSEHOLD REAL INCOME ;

 PARAMETER DTYV2           % CHANGE IN TOTAL VILLAGE HOUSEHOLD INCOME ;
 PARAMETER DTYT2           % CHANGE IN TOTAL TOWN HOUSEHOLD INCOME ;
 PARAMETER DTRYV2          % CHANGE IN REAL TOTAL VILLAGE HOUSEHOLD INCOME;
 PARAMETER DTRYT2          % CHANGE IN REAL TOTAL TOWN HOUSEHOLD INCOME ;

 PARAMETER DCD2(ip,h)      % CHANGE IN HOUSEHOLD CONSUMPTION DEMANDS ;
 PARAMETER DCI2(n,h)       % CHANGE IN HOUSEHOLD IMPORT DEMANDS ;
 PARAMETER DSAVINGS2       % CHANGE IN SAVINGS ;
 PARAMETER DSAVNGSVK2      % CHANGE IN VILLAGE SAVINGS ON CAPITAL ;
 PARAMETER DSAVNGSVH2      % CHANGE IN VILLAGE SAVINGS ON HUMAN CAPITAL ;
 PARAMETER DSAVNGSTK2      % CHANGE IN TOWN SAVINGS ON CAPITAL ;
 PARAMETER DSAVNGSTH2      % CHANGE IN TOWN SAVINGS ON HUMAN CAPITAL ;
 PARAMETER DINVEST2        % CHANGE IN INVESTMENT ;
 PARAMETER DDD2(ip)        % CHANGE IN VILLAGE DEMAND ;
 PARAMETER DID2(n)         % CHANGE IN IMPORT DEMAND ;
 PARAMETER DIDZ2           % CHANGE IN IMPORT DEMAND SANTA CRUZ;
 PARAMETER DIDR2           % CHANGE IN IMPORT DEMAND SAN CRISTOBAL ;
 PARAMETER DIDI2           % CHANGE IN IMPORT DEMAND ISABELA ;
 PARAMETER DINTER2(ip)     % CHANGE IN INTERMEDIATE DEMAND BY COMMODITY ;
 PARAMETER DII2(n)         % CHANGE IN INTERMEDIATE IMPORTS BY COMMODITY ;
 PARAMETER DMS2(ip)        % CHANGE IN COMMODITY MARKETED SURPLUS ;
 PARAMETER DEFD2(f)        % CHANGE IN EXOGENOUS FACTOR DEMAND ;

 P2(ip)                       = P.L(ip) ;
 RGDP2                        = RGDP.L ;
 Q2(ip)$Q1(ip)                = Q.L(ip) ;
 FD2(f,ip)$FD1(f,ip)          = FD.L(f,ip) ;
 TFD2(f)$TFD1(f)              = TFD.L(f) ;
 TLAB2                        = SUM(flab,TFD.L(flab)) ;
 SLDZ2                        = SUM(ip,FD.L("mcz",ip)+FD.L("mnz",ip)) ;
 SLDR2                        = SUM(ip,FD.L("mcr",ip)+FD.L("mnr",ip)) ;
 SLDI2                        = SUM(ip,FD.L("mci",ip)+FD.L("mni",ip)) ;
 TMIGZ2                       = SUM(ip,FD.L("mcz",ip)+FD.L("mnz",ip)+FD.L("ffz",ip)) ;
 TMIGR2                       = SUM(ip,FD.L("mcr",ip)+FD.L("mnr",ip)+FD.L("ffr",ip)) ;
 TMIGI2                       = SUM(ip,FD.L("mci",ip)+FD.L("mni",ip)+FD.L("ffi",ip)) ;
 PVA2(ip)$PVA1(ip)            = PVA.L(ip) ;
 W2(f)$W1(f)                  = W.L(f) ;
 WFDIST2(f,ip)$WFDIST1(f,ip)  = WFDIST.L(f,ip) ;
 Y2(h)$Y1(h)                  = Y.L(h) ;
 CPI2(h)                      = SUM(ip,samio(ip,h)*P2(ip))/sum(ip,samio(ip,h)) ;
 RY2(h)$RY1(h)                = Y.L(h)/CPI2(h) ;
 TRYZ2              = Y.L("haz")/CPI2("haz")+
                      Y.L("hpz")/CPI2("hpz")+
                      Y.L("hez")/CPI2("hez")+
                      Y.L("hrz")/CPI2("hrz")+
                      Y.L("huz")/CPI2("huz");
 TRYR2              = Y.L("har")/CPI2("har")+
                      Y.L("hpr")/CPI2("hpr")+
                      Y.L("her")/CPI2("her")+
                      Y.L("hrr")/CPI2("hrr")+
                      Y.L("hur")/CPI2("hur");
 TRYI2              = Y.L("hai")/CPI2("hai")+
                      Y.L("hpi")/CPI2("hpi")+
                      Y.L("hei")/CPI2("hei")+
                      Y.L("hri")/CPI2("hri")+
                      Y.L("hui")/CPI2("hui");
 TRY2               = TRYZ2+TRYR2+TRYI2 ;
 CD2(ip,h)$CD1(ip,h)             = CD.L(ip,h) ;
 CI2(n,h)$CI1(n,h)               = CI.L(n,h) ;
 DD2(ip)$DD1(ip)                 = DD.L(ip) ;
 ID2(n)$ID1(n)                   = ID.L(n) ;
 IDZ2$IDZ1                       = IIZ.L + CIZ.L ;
 IDR2$IDR1                       = IIR.L + CIR.L ;
 IDI2$IDI1                       = III.L + CII.L ;
 INTER2(ip)$INTER1(ip)           = INTER.L(ip) ;
 II2(n)$II1(n)                   = II.L(n) ;
 MS2(ip)$MS1(ip)                 = MS.L(ip) ;
 EFD2(f)$EFD1(f)                 = EFD.L(f) ;
 DP2(ip)                         = (P2(ip)-P1(ip))/P1(ip)*100 ;
 DRGDP2                          = (RGDP2-RGDP1)/RGDP1*100 ;
 DQ2(ip)$Q1(ip)                  = (Q2(ip)-Q1(ip))/Q1(ip)*100 ;
 DFD2(f,ip)$FD1(f,ip)            = (FD2(f,ip)-FD1(f,ip))/FD1(f,ip)*100 ;
 DTFD2(f)$TFD1(f)                = (TFD2(f)-TFD1(f))/TFD1(f)*100 ;
 DLAB2$TLAB1                     = (TLAB2-TLAB1)/TLAB1*100 ;
 DSLDZ2$SLDZ1                    = (SLDZ2-SLDZ1)/SLDZ1*100 ;
 DSLDR2$SLDR1                    = (SLDR2-SLDR1)/SLDR1*100 ;
 DSLDI2$SLDI1                    = (SLDI2-SLDI1)/SLDI1*100 ;
 DTMIGZ2$TMIGZ1                  = (TMIGZ2-TMIGZ1)/TMIGZ1*100 ;
 DTMIGR2$TMIGR1                  = (TMIGR2-TMIGR1)/TMIGR1*100 ;
 DTMIGI2$TMIGI1                  = (TMIGI2-TMIGI1)/TMIGI1*100 ;
 DPVA2(ip)$PVA1(ip)              = (PVA2(ip)-PVA1(ip))/PVA1(ip)*100 ;
 DW2(f)$W1(f)                    = (W2(f)-W1(f))/W1(f)*100 ;
 DWFDIST2(f,ip)$WFDIST1(f,ip)    = (WFDIST2(f,ip)-WFDIST1(f,ip))
                                   /WFDIST1(f,ip)*100 ;
 DY2(h)$Y1(h)                    = (Y2(h)-Y1(h))/Y1(h)*100 ;
 DRY2(h)$RY1(h)                  = (RY2(h)-RY1(h))/RY1(h)*100 ;
 DTRYZ2                          = (TRYZ2-TRYZ1)/TRYZ1*100 ;
 DTRYR2                          = (TRYR2-TRYR1)/TRYR1*100 ;
 DTRYI2                          = (TRYI2-TRYI1)/TRYI1*100 ;
 DTRY2                           = (TRY2-TRY1)/TRY1*100 ;
 DRGDP2                          = (LOG(RGDP2)-LOG(RGDP1))/10*100 ;
 DRPCGDP2                        = (LOG(RGDP2/TLAB2)-LOG(RGDP1/TLAB1))/10*100 ;
 DCPI2(h)                        = (CPI2(h)-CPI1(h))/CPI1(h)*100 ;
 DCD2(ip,h)$CD1(ip,h)            = (CD2(ip,h)-CD1(ip,h))/CD1(ip,h)*100 ;
 DCI2(n,h)$CI1(n,h)              = (CI2(n,h)-CI1(n,h))/CI1(n,h)*100 ;
 DDD2(ip)$DD1(ip)                = (DD2(ip)-DD1(ip))/DD1(ip)*100 ;
 DID2(n)$ID1(n)                  = (ID2(n)-ID1(n))/ID1(n)*100 ;
 DIDZ2$IDZ1                      = (IDZ2-IDZ1)/IDZ1*100 ;
 DIDR2$IDR1                      = (IDR2-IDR1)/IDR1*100 ;
 DIDI2$IDI1                      = (IDI2-IDI1)/IDI1*100 ;
 DINTER2(ip)$INTER1(ip)          = (INTER2(ip)-INTER1(ip))/INTER1(ip)*100 ;
 DII2(n)$II1(n)                  = (II2(n)-II1(n))/II1(n)*100 ;
 DMS2(ip)$MS1(ip)                = (MS2(ip)-MS1(ip))/MS1(ip)*100 ;
 DEFD2(f)$EFD1(f)                = (EFD2(f)-EFD1(f))/EFD1(f)*100 ;


*#### DISPLAY OUTPUT
 DISPLAY RY2 ;
 DISPLAY DRY2 ;
 DISPLAY DRGDP2 ;
 DISPLAY DRPCGDP2 ;
 DISPLAY DQ2 ;
 DISPLAY DTFD2 ;
 DISPLAY DLAB2 ;
 DISPLAY DSLDZ2 ;
 DISPLAY DSLDR2 ;
 DISPLAY DSLDI2 ;
 DISPLAY DTMIGZ2 ;
 DISPLAY DTMIGR2 ;
 DISPLAY DTMIGI2 ;
 DISPLAY DW2 ;
 DISPLAY DFD2 ;
 DISPLAY DWFDIST2 ;
 DISPLAY DY2 ;
 DISPLAY DCPI2 ;
 DISPLAY DRY2 ;
 DISPLAY DTRYZ2 ;
 DISPLAY DTRYR2 ;
 DISPLAY DTRYI2 ;
 DISPLAY DTRY2 ;
 DISPLAY DCI2 ;
 DISPLAY DID2 ;
 DISPLAY DIDZ2 ;
 DISPLAY DIDR2 ;
 DISPLAY DIDI2 ;
 DISPLAY DII2 ;
 DISPLAY DMS2 ;
 DISPLAY EFD1,EFD2,DEFD2 ;






























