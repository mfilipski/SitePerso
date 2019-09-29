$TITLE DISAGGREGATED RURAL ECONOMYWIDE MODEL (DREM), GUATEMALA
*USED IN TAYLOR AND FILIPSKI (2014), BEYOND EXPERIMENTS IN DEVELOPMENT
*ECONOMICS: LOCAL ECONOMY-WIDE IMPACT EVALUATION, CHAPTER 8

$OFFUPPER

*#######################AUTORES#############################
*COORDINADORES:
*             J. EDWARD TAYLOR, UC DAVIS
*             ANTONIO YUNEZ-NAUDE, EL COLEGIO DE MEXICO
*EQUIPO DEL BID:
*             NANCY JESURUN CLEMENTS
*ASESOR ESPECIAL:
*             EDUARDO BAUMAISTER, ASDI
*EQUIPO DE EL SALVADOR
*             EDGAR LARA, ENRIQUE MERLOS, FUNDE
*             GABRIEL EFRAIN RIOS, MINISTERIO DE AGRICULTURA
*EQUIPO DE GUATEMALA
*             ANDRES HUARD Y MARCO ANTONIO SANCHEZ, LANDIVAR
*             VICTOR ALVAREZ, UNIVERSIDAD DE SAN CARLOS
*EQUIPO DE HONDURAS
*             ARIE SANDERS Y JULIO BRAN, EL ZAMORANO
*EQUIPO DE NICARAGUA
*             MIGUEL ALEMAN Y GUY DELMELLE, NITLAPAN, UCA
*             RAMON CANALES Y ANA LISSETTE, ESECA, UNAN
*###########################################################

*THIS PROGRAM TAKES A SERIES OF HOUSEHOLD SOCIAL ACCOUNTING MATRICES (SAMS)
*AND TURNS THEM INTO A DISAGGREGATED RURAL ECONOMYWIDE MODEL RICH
*IN COMMODITY AND ACTIVITY DETAIL.

*NO INFORMATION OTHER THAN WHAT IS CONTAINED IN THE SAM IS
*REQUIRED EXCEPT FOR REMITTANCE ELASTICITIES WITH RESPECT TO LABOR ALLOCATED
*TO MIGRATION TO EACH MIGRANT DESTINATION, WHICH WERE ESTIMATED ECONOMETRICALLY.

*TO ESTIMATE THE MODEL DIRECTLY FROM THE SAMS, THIS PROGRAM ASSUMES THAT
*PREFERENCES FOR EACH HOUSEHOLD GROUP CAN BE DESCRIBED BY A COBB-DOUGLAS
*UTILITY FUNCTION DEFINED ON COMMODITIES AND SAVINGS. PRODUCTION IN ALL
*SECTORS IS ALSO ASSUMED TO BE A COBB-DOUGLAS FUNCTION OF FACTOR INPUTS,
*WITH PARAMETERS VARYING ACROSS PRODUCTION ACTIVITIES AND HOUSEHOLDS. AT
*LEAST ONE FACTOR INPUT (E.G., CAPITAL, LAND) MUST BE FIXED FOR EACH
*PRODUCTION ACTIVITY (I.E., THERE MUST BE DECREASING MARGINAL RETURNS
*TO VARIABLE FACTOR INPUTS) IN ORDER FOR THE MODEL TO SOLVE.

*COMMODITIES AND (VARIABLE) FACTORS MAY BE TREATED EITHER AS TRADABLE
*(PRICE DETERMINED EXOGENOUSLY, IN OUTSIDE (E.G., REGIONAL) MARKETS,
*WITH HOUSEHOLD "MARKETED SURPLUS" ENDOGENOUS, AS IN SINGH, SQUIRE AND
*STRAUSS, 1986); OR AS NONTRADABLE (ENDOGENOUS HOUSEHOLD PRICES, WITH
*HOUSEHOLD MARKETED SURPLUS EQUAL TO ZERO, AS IN DEJANVRY, FAFCHAMPS
*AND SADOULET, 1991)

*IN THIS VERSION, RURAL HOUSEHOLDS FACE A BINDING CAPITAL CONSTRAINT;
*THAT IS, THERE IS A MISSING CAPITAL MARKET FORCING RURAL HOUSEHOLDS
*TO SELF-FINANCE INVESTMENTS.

*######################## SET DEFINITION #############################
 SETS
 i   SAM ACCOUNTS            / MAIZ        Maize
                               FRIJ        Frijol
                               ARRO        Arroz
                               SORG        Sorgo
                               GMAY        Ganado Mayor
                               GMEN        Ganado Menor
                               PAST        Pastos
                               APIC        Apicultura
                               BANA        Banano
                               PLAT        Platano
                               CAFE        Cafe
                               AZUC        Azucar
                               CARD        Cardamomo
                               TABA        Tabaco
                               SORI        Sorgo Industrial
                               OTRA        Otros Cultivos Tradicionales
                               PINA        Pina
                               PITA        Pitaya
                               MALA        Malanga
                               CACO        Cacao
                               TUBE        Tuberculos
                               YUCA        Yuca
                               CAMO        Camote
                               CEBO        Cebolla
                               TOMA        Tomate
                               PIMI        Pimiento
                               LECH        Lechuga
                               ZANA        Zanahoria
                               OKRA        Okra
                               REMO        Remolacha
                               MANI        Mani
                               AJON        Ajonjoli
                               SOYA        Soya
                               FLOR        Flores
                               CITR        Citricos
                               PAPA        Papaya
                               MANG        Mango
                               AGUA        Aguacate
                               OPER        Otros Cultivos Permanentes
                               MELO        Melon y sandia
                               CHAY        Chayote
                               AYOT        Ayote
                               PIPI        Pipian
                               OFRU        Otros cultivos de fruta
                               OCUL        Otros cultivos
                               MINE        Mineria
                               MADE        Corte de lena y madera
                               PART        Pesca artesanal
                               PIND        Pesca industrial
                               PCUL        Cultivo de peces
                               PROC        Procesamiento de alimentos
                               PROL        Productos lacteos
                               PANA        Panaderias
                               PROM        Productos de maiz
                               OPRO        Otros productos procesados
                               ARTE        Artesania
                               OMAC        Otras manufacturas en casa
                               MAQU        Maquiladoras
                               OMAN        Otras manufacturas
                               AGRO        Agroindustria
                               CONS        Construccion
                               COME        Comercio
                               HOTE        Hoteles y restaurantes
                               TRAN        Transporte almacenaje comunicacion
                               FINA        Servicios financieros y seguros
                               EDUC        Educacion rural
                               SALU        Salud rural
                               PERS        Servicios personales
                               DOME        Servicios domesticos
                               FAMI        Factores familiares
                               LAHP        Trabajo agricola por hombres poco calificados
                               LAHC        Trajabo agricola por hombres calificados
                               LAMP        Trabajo agricola por mujeres poco calificadas
                               LAMC        Trabajo agricola por mujeres calificadas
                               LNHP        Trabajo no agricola por hombres poco calificados
                               LNHC        Trajabo no agricola por hombres calificados
                               LNMP        Trabajo no agricola por mujeres poco calificadas
                               LNMC        Trabajo no agricola por mujeres calificadas
                               KTIE        Capital tierra
                               KMAQ        Capital fisico
                               KANI        Capital animal
                               HACO        Consumo de produccion propia
                               HCON        Consumo
                               GMUN        Gobierno Municipal
                               GFED        Gobierno Federal
                               AHFI        Ahorro Financiero
                               AHAN        Ahorro Animal
                               AHTI        Ahorro Tierra
                               AHPL        Ahorro Plantacion
                               AHIN        Ahorro Infraestructura
                               AHVI        Ahorro Vivienda
                               AHOT        Ahorro Otros Activos
                               AHED        Ahorro Educacion
                               AHSA        Ahorro Salud
                               RRUR        Resto del Sector Rural
                               MNAC        Migracion Nacional
                               MEXT        Migracion al Exterior
                               RPAI        Resto del Pais
                               RMUN        Resto del Mundo
                               CHDP        Columna de calibracion
                             /
 ip(i)   PRODUCTION ACTIVITIES
                             / MAIZ        Maize
                               FRIJ        Frijol
                               ARRO        Arroz
                               SORG        Sorgo
                               GMAY        Ganado Mayor
                               GMEN        Ganado Menor
                               PAST        Pastos
                               APIC        Apicultura
                               BANA        Banano
                               PLAT        Platano
                               CAFE        Cafe
                               AZUC        Azucar
                               CARD        Cardamomo
                               TABA        Tabaco
                               SORI        Sorgo Industrial
                               OTRA        Otros Cultivos Tradicionales
                               PINA        Pina
                               PITA        Pitaya
                               CACO        Cacao
                               TUBE        Tuberculos
                               YUCA        Yuca
                               CAMO        Camote
                               CEBO        Cebolla
                               TOMA        Tomate
                               PIMI        Pimiento
                               LECH        Lechuga
                               ZANA        Zanahoria
                               OKRA        Okra
                               MANI        Mani
                               AJON        Ajonjoli
                               SOYA        Soya
                               FLOR        Flores
                               CITR        Citricos
                               PAPA        Papaya
                               MANG        Mango
                               AGUA        Aguacate
                               OPER        Otros Cultivos Permanentes
                               MELO        Melon y sandia
                               CHAY        Chayote
                               AYOT        Ayote
                               PIPI        Pipian
                               OFRU        Otros cultivos de fruta
                               OCUL        Otros cultivos
                               MINE        Mineria
                               MADE        Corte de lena y madera
                               PART        Pesca artesanal
                               PIND        Pesca industrial
                               PCUL        Cultivo de peces
                               PROC        Procesamiento de alimentos
                               PROL        Productos lacteos
                               PANA        Panaderias
                               PROM        Productos de maiz
                               OPRO        Otros productos procesados
                               ARTE        Artesania
                               OMAC        Otras manufacturas en casa
                               MAQU        Maquiladoras
                               OMAN        Otras manufacturas
                               AGRO        Agroindustria
                               CONS        Construccion
                               COME        Comercio
                               HOTE        Hoteles y restaurantes
                               TRAN        Transporte almacenaje comunicacion
                               FINA        Servicios financieros y seguros
                               EDUC        Educacion rural
                               SALU        Salud rural
                               PERS        Servicios personales
                               DOME        Servicios domesticos /
 icrop(i)   CROP PRODUCTION ACTIVITIES
                             / MAIZ        Maize
                               FRIJ        Frijol
                               ARRO        Arroz
                               SORG        Sorgo
                               GMAY        Ganado Mayor
                               GMEN        Ganado Menor
                               PAST        Pastos
                               APIC        Apicultura
                               BANA        Banano
                               PLAT        Platano
                               CAFE        Cafe
                               AZUC        Azucar
                               CARD        Cardamomo
                               TABA        Tabaco
                               SORI        Sorgo Industrial
                               OTRA        Otros Cultivos Tradicionales
                               PINA        Pina
                               PITA        Pitaya
                               CACO        Cacao
                               TUBE        Tuberculos
                               YUCA        Yuca
                               CAMO        Camote
                               CEBO        Cebolla
                               TOMA        Tomate
                               PIMI        Pimiento
                               LECH        Lechuga
                               ZANA        Zanahoria
                               OKRA        Okra
                               MANI        Mani
                               AJON        Ajonjoli
                               SOYA        Soya
                               FLOR        Flores
                               CITR        Citricos
                               PAPA        Papaya
                               MANG        Mango
                               AGUA        Aguacate
                               OPER        Otros Cultivos Permanentes
                               MELO        Melon y sandia
                               CHAY        Chayote
                               AYOT        Ayote
                               PIPI        Pipian
                               OFRU        Otros cultivos de fruta
                               OCUL        Otros cultivos
                               /
 ips(ip)  STAPLE PRODUCTION ACTIVITIES
                             / MAIZ        Maize
                               FRIJ        Frijol
                               ARRO        Arroz
                               SORG        Sorgo
                               /
 ipns(ip)   NONSTAPLE PRODUCTION ACTIVITIES
                             / GMAY        Ganado Mayor
                               GMEN        Ganado Menor
                               PAST        Pastos
                               APIC        Apicultura
                               BANA        Banano
                               PLAT        Platano
                               CAFE        Cafe
                               AZUC        Azucar
                               CARD        Cardamomo
                               TABA        Tabaco
                               SORI        Sorgo Industrial
                               OTRA        Otros Cultivos Tradicionales
                               PINA        Pina
                               PITA        Pitaya
                               CACO        Cacao
                               TUBE        Tuberculos
                               YUCA        Yuca
                               CAMO        Camote
                               CEBO        Cebolla
                               TOMA        Tomate
                               PIMI        Pimiento
                               LECH        Lechuga
                               ZANA        Zanahoria
                               OKRA        Okra
                               MANI        Mani
                               AJON        Ajonjoli
                               SOYA        Soya
                               FLOR        Flores
                               CITR        Citricos
                               PAPA        Papaya
                               MANG        Mango
                               AGUA        Aguacate
                               OPER        Otros Cultivos Permanentes
                               MELO        Melon y sandia
                               CHAY        Chayote
                               AYOT        Ayote
                               PIPI        Pipian
                               OFRU        Otros cultivos de fruta
                               OCUL        Otros cultivos
                               MINE        Mineria
                               MADE        Corte de lena y madera
                               PART        Pesca artesanal
                               PIND        Pesca industrial
                               PCUL        Cultivo de peces
                               PROC        Procesamiento de alimentos
                               PROL        Productos lacteos
                               PANA        Panaderias
                               PROM        Productos de maiz
                               OPRO        Otros productos procesados
                               ARTE        Artesania
                               OMAC        Otras manufacturas en casa
                               MAQU        Maquiladoras
                               OMAN        Otras manufacturas
                               AGRO        Agroindustria
                               CONS        Construccion
                               COME        Comercio
                               HOTE        Hoteles y restaurantes
                               TRAN        Transporte almacenaje comunicacion
                               FINA        Servicios financieros y seguros
                               EDUC        Educacion rural
                               SALU        Salud rural
                               PERS        Servicios personales
                               DOME        Servicios domesticos /
 iliv(ip)   LIVESTOCK PRODUCTION ACTIVITIES
                             / GMAY        Ganado Mayor
                               GMEN        Ganado Menor
                               APIC        Apicultura
                               /
 itrad(ip)   TRADITIONAL PRODUCTION ACTIVITIES
                             / PAST        Pastos
                               BANA        Banano
                               PLAT        Platano
                               CAFE        Cafe
                               AZUC        Azucar
                               CARD        Cardamomo
                               TABA        Tabaco
                               SORI        Sorgo Industrial
                               OTRA        Otros Cultivos Tradicionales
                                /
 intrad(ip)   NONTRADITIONAL PRODUCTION ACTIVITIES
                             / PINA        Pina
                               PITA        Pitaya
                               CACO        Cacao
                               TUBE        Tuberculos
                               YUCA        Yuca
                               CAMO        Camote
                               CEBO        Cebolla
                               TOMA        Tomate
                               PIMI        Pimiento
                               LECH        Lechuga
                               ZANA        Zanahoria
                               OKRA        Okra
                               MANI        Mani
                               AJON        Ajonjoli
                               SOYA        Soya
                               FLOR        Flores
                               CITR        Citricos
                               PAPA        Papaya
                               MANG        Mango
                               AGUA        Aguacate
                               OPER        Otros Cultivos Permanentes
                               MELO        Melon y sandia
                               CHAY        Chayote
                               AYOT        Ayote
                               PIPI        Pipian
                               OFRU        Otros cultivos de fruta
                               OCUL        Otros cultivos
                             /
 inonag(ip)  NONAGRICULTURAL PRODUCTION ACTIVITIES
                             / MINE        Mineria
                               MADE        Corte de lena y madera
                               PART        Pesca artesanal
                               PIND        Pesca industrial
                               PCUL        Cultivo de peces
                               PROC        Procesamiento de alimentos
                               PROL        Productos lacteos
                               PANA        Panaderias
                               PROM        Productos de maiz
                               OPRO        Otros productos procesados
                               ARTE        Artesania
                               OMAC        Otras manufacturas en casa
                               MAQU        Maquiladoras
                               OMAN        Otras manufacturas
                               AGRO        Agroindustria
                               CONS        Construccion
                               COME        Comercio
                               HOTE        Hoteles y restaurantes
                               TRAN        Transporte almacenaje comunicacion
                               FINA        Servicios financieros y seguros
                               EDUC        Educacion rural
                               SALU        Salud rural
                               PERS        Servicios personales
                               DOME        Servicios domesticos /
 iserv(ip)  SERVICE ACTIVITIES
                             / CONS        Construccion
                               COME        Comercio
                               HOTE        Hoteles y restaurantes
                               TRAN        Transporte almacenaje comunicacion
                               FINA        Servicios financieros y seguros
                               EDUC        Educacion rural
                               SALU        Salud rural
                               PERS        Servicios personales
                               DOME        Servicios domesticos /
 iman(ip)  MANUFACTURING ACTIVITIES
                             / MINE        Mineria
                               MADE        Corte de lena y madera
                               PART        Pesca artesanal
                               PIND        Pesca industrial
                               PCUL        Cultivo de peces
                               PROC        Procesamiento de alimentos
                               PROL        Productos lacteos
                               PANA        Panaderias
                               PROM        Productos de maiz
                               OPRO        Otros productos procesados
                               ARTE        Artesania
                               OMAC        Otras manufacturas en casa
                               MAQU        Maquiladoras
                               OMAN        Otras manufacturas
                               AGRO        Agroindustria
                             /
 ipnz(i)   NON-SUGAR PRODUCTION ACTIVITIES
                             / MAIZ        Maize
                               FRIJ        Frijol
                               ARRO        Arroz
                               SORG        Sorgo
                               GMAY        Ganado Mayor
                               GMEN        Ganado Menor
                               PAST        Pastos
                               APIC        Apicultura
                               BANA        Banano
                               PLAT        Platano
                               CAFE        Cafe
                               CARD        Cardamomo
                               TABA        Tabaco
                               SORI        Sorgo Industrial
                               OTRA        Otros Cultivos Tradicionales
                               PINA        Pina
                               PITA        Pitaya
                               CACO        Cacao
                               TUBE        Tuberculos
                               YUCA        Yuca
                               CAMO        Camote
                               CEBO        Cebolla
                               TOMA        Tomate
                               PIMI        Pimiento
                               LECH        Lechuga
                               ZANA        Zanahoria
                               OKRA        Okra
                               MANI        Mani
                               AJON        Ajonjoli
                               SOYA        Soya
                               FLOR        Flores
                               CITR        Citricos
                               PAPA        Papaya
                               MANG        Mango
                               AGUA        Aguacate
                               OPER        Otros Cultivos Permanentes
                               MELO        Melon y sandia
                               CHAY        Chayote
                               AYOT        Ayote
                               PIPI        Pipian
                               OFRU        Otros cultivos de fruta
                               OCUL        Otros cultivos
                               MINE        Mineria
                               MADE        Corte de lena y madera
                               PART        Pesca artesanal
                               PIND        Pesca industrial
                               PCUL        Cultivo de peces
                               PROC        Procesamiento de alimentos
                               PROL        Productos lacteos
                               PANA        Panaderias
                               PROM        Productos de maiz
                               OPRO        Otros productos procesados
                               ARTE        Artesania
                               OMAC        Otras manufacturas en casa
                               MAQU        Maquiladoras
                               OMAN        Otras manufacturas
                               AGRO        Agroindustria
                               CONS        Construccion
                               COME        Comercio
                               HOTE        Hoteles y restaurantes
                               TRAN        Transporte almacenaje comunicacion
                               FINA        Servicios financieros y seguros
                               EDUC        Educacion rural
                               SALU        Salud rural
                               PERS        Servicios personales
                               DOME        Servicios domesticos
                                /


 f(i)  FACTORES              / FAMI        Factores familiares
                               LAHP        Trabajo agricola por hombres poco calificados
                               LAHC        Trajabo agricola por hombres calificados
                               LAMP        Trabajo agricola por mujeres poco calificadas
                               LAMC        Trabajo agricola por mujeres calificadas
                               LNHP        Trabajo no agricola por hombres poco calificados
                               LNHC        Trajabo no agricola por hombres calificados
                               LNMP        Trabajo no agricola por mujeres poco calificadas
                               LNMC        Trabajo no agricola por mujeres calificadas
                               KTIE        Capital tierra
                               KMAQ        Capital fisico
                               KANI        Capital animal
                             /
 ft(f)    TRADED FACTORS     / LAHP        Trabajo agricola por hombres poco calificados
                               LAHC        Trajabo agricola por hombres calificados
                               LAMP        Trabajo agricola por mujeres poco calificadas
                               LAMC        Trabajo agricola por mujeres calificadas
                               LNHP        Trabajo no agricola por hombres poco calificados
                               LNHC        Trajabo no agricola por hombres calificados
                               LNMP        Trabajo no agricola por mujeres poco calificadas
                               LNMC        Trabajo no agricola por mujeres calificadas
                             /
 fvar(f)    VARIABLE FACTORS / FAMI        Factores familiares
                               LAHP        Trabajo agricola por hombres poco calificados
                               LAHC        Trajabo agricola por hombres calificados
                               LAMP        Trabajo agricola por mujeres poco calificadas
                               LAMC        Trabajo agricola por mujeres calificadas
                               LNHP        Trabajo no agricola por hombres poco calificados
                               LNHC        Trajabo no agricola por hombres calificados
                               LNMP        Trabajo no agricola por mujeres poco calificadas
                               LNMC        Trabajo no agricola por mujeres calificadas
                             /
 fat(f) TRADED AG FACTORS    / LAHP        Trabajo agricola por hombres poco calificados
                             /
 fnat(f) TRADED NON AG FACTORS
                             / LNHP        Trabajo no agricola por hombres poco calificados
                               LNHC        Trajabo no agricola por hombres calificados
                               LNMP        Trabajo no agricola por mujeres poco calificadas
                               LNMC        Trabajo no agricola por mujeres calificadas
                             /
 fun(f) UNUSED AG FACTORS    / LAHC        Trajabo agricola por hombres calificados
                               LAMP        Trabajo agricola por mujeres poco calificadas
                               LAMC        Trabajo agricola por mujeres calificadas
                             /
 fxf(f)   FIXED FACTORS      / KTIE        Capital tierra
                               KMAQ        Capital fisico
                               KANI        Capital animal
                             /

 h    HOUSEHOLDS             / H1          Hogares cap baja
                               H2          Hogares sin tierra cap alta
                               H3          Hogares productores pequenos de granos basicos
                               H4          Hogares comerciales pequenos
                               H5          Hogares comerciales medianos
                               H6          Hogares comerciales grandes
                             /
 hp(h) PRODUCER HOUSEHOLDS   / H1          Hogares cap baja
                               H2          Hogares sin tierra cap alta
                               H3          Hogares productores pequenos de granos basicos
                               H4          Hogares comerciales pequenos
                               H5          Hogares comerciales medianos
                               H6          Hogares comerciales grandes
                             /

 hsub(h) SUBSISTENCE HOUSEHOLDS
                             /  H3          Hogares productores pequenos de granos basicos
                             /

 hnsub(h) NONSUBSISTENCE HOUSEHOLDS
                             / H1          Hogares cap baja
                               H2          Hogares sin tierra cap alta
                               H4          Hogares comerciales pequenos
                               H5          Hogares comerciales medianos
                               H6          Hogares comerciales grandes
                             /
 c(i)  CAPITAL ACCOUNTS      / AHFI        Ahorro Financiero
                               AHAN        Ahorro Animal
                               AHTI        Ahorro Tierra
                               AHPL        Ahorro Plantacion
                               AHIN        Ahorro Infraestructura
                               AHVI        Ahorro Vivienda
                               AHOT        Ahorro Otros Activos
                               AHED        Ahorro Educacion
                               AHSA        Ahorro Salud /

 g(i)  GOVERNMENT ACCOUNTS   / GMUN        Gobierno Municipal
                               GFED        Gobierno Federal /

 d(i) REST OF WORLD          / RRUR        Resto del Sector Rural
                               RPAI        Resto del Pais
                               RMUN        Resto del Mundo  /

 im(i) MIGRATION ACTIVITIES  / MNAC        Migracion Nacional
                               MEXT        Migracion al Exterior /

  ALIAS(i,j) ;
  ALIAS(ip,jp) ;
  ALIAS(h,hh) ;
  ALIAS(icrop,jcrop) ;
  ALIAS(ips,jps) ;
  ALIAS(itrad,jtrad) ;
  ALIAS(intrad,jntrad) ;
  ALIAS(iliv,jliv) ;
  ALIAS(iman,jman) ;
  ALIAS(iserv,jserv) ;
  ALIAS(inonag,jnonag) ;


*######################################################################################
*###                   ENTER SAMS, ONE FOR EACH HOUSEHOLD GROUP                     ###
*######################################################################################

*$INCLUDE E:\All Work\BID\CAFTA 2004\Models\Guatemala\GUATEMALADATA.txt
$INCLUDE GUATEMALADATA.txt

*######################## PARAMETER DECLARATION ######################

 PARAMETERS
 alpha(f,jp,h)    FACTOR SHARE PARAMETER-COBB DOUGLAS PRODUCTION FUNCTION
 al(jp,h)         PRODUCTION FUNCTION SHIFT PARAMETER
 beta(i,h)        HOUSEHOLD BUDGET SHARES
 output(jp,h)     HOUSEHOLD OUTPUT FROM ACTIVITY j
 va(jp,h)         TOTAL VALUE ADDED OF ACTIVITY jp
 vash(jp,h)       VALUE ADDED SHARE OF ACTIVITY jp OUTPUT
 totexp(h)        HOUSEHOLD h TOTAL EXPENDITURE
 io(ip,jp,h)      INPUT-OUTPUT (LEONTIEF) COEFFICIENTS
 gamma0(im,f,h)   REMITTANCE SHIFT PARAMETERS
 hfd(f,h)         household factor demand
 sumalf(jp,h)     sum of alphas
 nualph(f,jp,h)   new alpha (temp)
 ;
*############ SPECIFY PARAMETERS FROM TABLE VALUES ###################

*CONSUMPTION BUDGET SHARES
 totexp(h)                  = SUM(i,SAM(i,"HCON",h)+SAM(i,"HACO",h))
                              +SUM(c,SAM(c,"HCON",h))+SUM(d,SAM(d,"HCON",h)) ;
 beta(i,h)                  = (SAM(i,"HCON",h)+SAM(i,"HACO",h))/totexp(h) ;

*OUTPUT (FOR USE BELOW)
 output(ip,h)               = SUM(j,SAM(ip,j,h)) ;

*PARAMETERS OF COBB-DOUGLAS PRODUCTION FUNCTIONS
 va(jp,h)        = SUM(f,SAM(f,jp,h)) ;
 DISPLAY va ;
 alpha(f,jp,h)$va(jp,h)       = SAM(f,jp,h)/va(jp,h) ;

*ADJUST FAMILY AND CAPITAL V-A BASED ON ECONOMETRIC ESTIMATES OF SHARES
 alpha("KTIE",jps,h)$va(jps,h)  = (SAM("KTIE",jps,h)+factadj("STAP",h)
                                      *SAM("FAMI",jps,h))/va(jps,h) ;
 alpha("KTIE",jliv,h)$va(jliv,h)  = (SAM("KTIE",jliv,h)+factadj("GANA",h)
                                      *SAM("FAMI",jliv,h))/va(jliv,h) ;
 alpha("KTIE",jtrad,h)$va(jtrad,h)  = (SAM("KTIE",jtrad,h)+factadj("TRAD",h)
                                      *SAM("FAMI",jtrad,h))/va(jtrad,h) ;
 alpha("KTIE",jntrad,h)$va(jntrad,h)  = (SAM("KTIE",jntrad,h)+factadj("NTRA",h)
                                      *SAM("FAMI",jntrad,h))/va(jntrad,h) ;
 alpha("KTIE","AZUC",h)$va("AZUC",h)  = (SAM("KMAQ","AZUC",h)+factadj("SUGA",h)
                                        *SAM("FAMI","AZUC",h))/va("AZUC",h) ;
 alpha("KMAQ",jserv,h)$va(jserv,h)  = (SAM("KMAQ",jserv,h)+factadj("SERV",h)
                                        *SAM("FAMI",jserv,h))/va(jserv,h) ;
 alpha("KMAQ",jman,h)$va(jman,h)  = (SAM("KMAQ",jman,h)+factadj("NOAG",h)
                                        *SAM("FAMI",jman,h))/va(jman,h) ;
 alpha("FAMI",jp,h)$va(jp,h)  = ((1-factadj(jp,h))*SAM("FAMI",jp,h))/va(jp,h) ;

*CHECK TO MAKE SURE ALPHAS SUM TO 1.0 IN EACH C-D PRODUCTION FUNCTION
 sumalf(jp,h) = sum(f,alpha(f,jp,h)) ;
 display sumalf ;
 nualph(f,jp,h)$sumalf(jp,h) = alpha(f,jp,h)/sumalf(jp,h) ;
 alpha(f,jp,h) = nualph(f,jp,h) ;

*SHARE OF FACTOR VALUE ADDED IN OUTPUT VALUE
 vash(jp,h)$output(jp,h) = SUM(f,SAM(f,jp,h))/output(jp,h) ;

*I-O COEFFICIENTS
 io(ip,jp,h)$output(jp,h)  = SAM(ip,jp,h)/output(jp,h) ;

 DISPLAY output, totexp, alpha, beta, output, io, vash, va ;

*#####################################################################

 VARIABLES

*#################### VARIABLE DECLARATION ##########################

 Q(ip,h)          OUTPUT
 INTER(ip,jp,h)   INTERMEDIATE INPUT DEMAND
 FD(f,jp,h)       FACTOR DEMAND
 RW(f)            RURAL FACTOR PRICES
 W(f,h)           FACTOR PRICES
 WDIFF(f,jp,h)    SECTORAL FACTOR-PRICE DIFFERENTIALS
 P(ip,h)          COMMODITY PRICES
 PVA(ip,h)        COMMODITY VALUE-ADDED PRICES
 PROFIT(h)        HOUSEHOLD PROFIT
 FY(h)            HOUSEHOLD FULL INCOME
 X(ip,h)          HOUSEHOLD CONSUMPTION DEMANDS
 MS(ip,h)         GOODS MARKET SURPLUS
 T(f,h)           HOUSEHOLD FACTOR ENDOWMENTS
 RY               TOTAL RURAL INCOME
 YBAR(h)          EXOGENOUS INCOME
 HFMS(f,h)        HOUSEHOLD FACTOR MARKETED SURPLUS
 FMS(f)           RURAL FACTOR MARKETED SURPLUS
 REM(im,f,h)      HOUSEHOLD REMITTANCES FROM MIGRANT DESTINATION d
 MIG(im,f,h)      HOUSEHOLD MIGRATION TO DESTINATION d
 EXFD(f,h)        EXOGENOUS FACTOR DEMAND
 U(h)             HOUSEHOLD UTILITY
 CV(h)            COMPENSATING VARIATION
 ;

*################## VARIABLE INITIALIZATION #########################

*FACTOR AND OUTPUT PRICES
 W.L(f,h)  = 1.0 ; P.L(jp,h)  = 1.0 ; WDIFF.L(f,jp,h) = 1.0 ;
 RW.L(f)   = 1.0 ;

*VALUE-ADDED PRICE
 PVA.L(jp,h)      = P.L(jp,h)*vash(jp,h) ;

*PRODUCTION
 Q.L(jp,h)        = output(jp,h) ;
 INTER.L(ip,jp,h) = io(ip,jp,h)*Q.L(jp,h) ;

*FACTOR DEMANDS
 FD.L(f,jp,h)     =  alpha(f,jp,h)*Q.L(jp,h) ;

DISPLAY Q.L, FD.L, alpha ;

*COBB-DOUGLASS SHIFT PARAMETER
 al(jp,h)$va(jp,h) =  Q.L(jp,h)/PROD(f,FD.L(f,jp,h)**alpha(f,jp,h)) ;

*CHECK FACTOR DEMANDS USING ESTIMATED PRODUCTION FUNCTION
 DISPLAY FD.L ;
 FD.L(f,ip,h)= PVA.L(ip,h)*Q.L(ip,h)*alpha(f,ip,h)/(W.L(f,h)*WDIFF.L(f,ip,h)) ;
 DISPLAY FD.L ;

*CHECK OUTPUT USING PRODUCTION FUNCTION
 DISPLAY Q.L ;
 Q.L(ip,h)= al(ip,h)*PROD(f$alpha(f,ip,h),FD.L(f,ip,h)**alpha(f,ip,h)) ;
 DISPLAY Q.L ;

*EXOGENOUS FACTOR DEMAND
 EXFD.L(f,h)   =  SAM(f,"GFED",h)+SUM(d,SAM(f,d,h)) ;

*REMITTANCE INCOME AND MIGRATION
 REM.L(im,f,h) = SAM(f,im,h) ;
 MIG.L(im,f,h) = gamma1(im,f,h)*REM.L(im,f,h) ;
 display rem.l, mig.l, gamma1 ;
 gamma0(im,f,h)$gamma1(im,f,h) = REM.L(im,f,h)/MIG.L(im,f,h)**gamma1(im,f,h) ;

*FACTOR ENDOWMENTS
 T.L(f,h)     = SUM(jp,FD.L(f,jp,h))+EXFD.L(f,h)+SUM(im,MIG.L(im,f,h))   ;

*HOUSEHOLD FACTOR MARKETED SURPLUS
 HFMS.L(f,h)  =  T.L(f,h) - SUM(jp,FD.L(f,jp,h))-EXFD.L(f,h)-SUM(im,MIG.L(im,f,h)) ;

*HOUSEHOLD FACTOR MARKET SUPPLY EQUALS HOUSEHOLD FACTOR ENDOWMENT MINUS DEMAND
 FMS.L(f)     = SUM(h,HFMS.L(f,h)) ;

*HOUSEHOLD PROFIT FROM PRODUCTION ACTIVITIES
 PROFIT.L(h)  = SUM(ip,Q.L(ip,h)*PVA.L(ip,h)-sum(fvar,FD.L(fvar,ip,h)*RW.L(fvar)
                 *W.L(fvar,h)*WDIFF.L(fvar,ip,h)))
*sum(jp,SAM("FAMI",jp,h)) ;
 DISPLAY PROFIT.L ;

*FULL INCOME
 FY.L(h)      =  PROFIT.L(h)+SUM(ft,T.L(ft,h)*RW.L(ft)*W.L(ft,h))
               +SUM(im,SUM(f,REM.L(im,f,h))) ;
 YBAR.L(h)    = 0.0 ;

*RURAL INCOME
 RY.L         = sum(h,FY.L(h)) ;
  
*CONSUMPTION DEMAND
 X.L(ip,h)    = beta(ip,h)*FY.L(h)/P.L(ip,h) ;

*HOUSEHOLD UTILITY AND COMPENSATING VARIATION (INITIALIZED AT ZERO)
 U.L(h)       = PROD(ip$beta(ip,h),X.L(ip,h)**beta(ip,h)) ;
 CV.L(h)      = 0.0  ;

*MARKETED SURPLUS
 MS.L(ip,h)   = Q.L(ip,h)-X.L(ip,h)-SUM(jp,INTER.L(ip,jp,h)) ;

 DISPLAY W.L, P.L, PVA.L, FD.L, PROFIT.L, FY.L, Q.L, X.L, MS.L, RY.L, MIG.L,
         gamma0, REM.L, EXFD.L, T.L, FMS.L, RY.L, U.L ;

*###################### END VARIABLE SPECIFICATION ###################


*#####################################################################
   EQUATIONS
*#################### EQUATION DECLARATION ###########################

   PVAEQ(ip,h)       VALUE-ADDED PRICE EQUATION
   QEQ(ip,h)         PRODUCTION FUNCTIONS
   INTEREQ(ip,jp,h)  INTERMEDIATE INPUT DEMAND
   FDEQ(f,ip,h)      FACTOR DEMAND EQUATIONS
   PROFITEQ(h)       HOUSEHOLD TOTAL PROFIT EQUATION
   FINCEQ(h)         HOUSEHOLD FULL INCOME EQUATION
   RYEQ              TOTAL RURAL INCOME
   CDEQ(ip,h)        HOUSEHOLD CONSUMPTION DEMAND EQUATIONS
   MSEQ(ip,h)        MARKETED GOODS SURPLUS EQUATIONS
   HFMSEQ(f,h)       HOUSEHOLD FACTOR MARKETED SURPLUS
   REMEQ(im,f,h)     MIGRATION REMITTANCE EQUATIONS
   FMSEQ(f)          HOUSEHOLD FACTOR MARKETED SURPLUS
   MIGEQ(im,f,h)     MIGRATION
   UTILEQ(h)         HOUSEHOLD UTILITY
   CVEQ(h)           COMPENSATING VARIATION EQUATION
  ;
*######################## EQUATION ASSIGNMENT  #######################

*VALUE-ADDED PRICES
 PVAEQ(ip,h)$OUTPUT(ip,h)..    PVA(ip,h)     =E=  P(ip,h)*vash(ip,h) ;

*PRODUCTION FUNCTIONS
 QEQ(ip,h)$OUTPUT(ip,h)..      Q(ip,h)       =E= al(ip,h)*PROD(f$alpha(f,ip,h),
                                                   FD(f,ip,h)**alpha(f,ip,h)) ;

*INTERMEDIATE INPUT DEMANDS
 INTEREQ(ip,jp,h)..            INTER(ip,jp,h) =E= io(ip,jp,h)*Q(jp,h) ;

*FACTOR DEMANDS FROM COBB DOUGLAS FOCS FOR PROFIT MAXIMIZATION
 FDEQ(f,ip,h)$alpha(f,ip,h)..  FD(f,ip,h)*RW(f)*W(f,h)*WDIFF(f,ip,h)
                                             =E= PVA(ip,h)*Q(ip,h)*alpha(f,ip,h)
                                            ;

 PROFITEQ(h)..                 PROFIT(h)     =E= SUM(ip,Q(ip,h)*PVA(ip,h)-
                                                 sum(fvar,FD(fvar,ip,h)*RW(fvar)
                                                 *W(fvar,h)*WDIFF(fvar,ip,h))) ;

*INCOME AND FULL INCOME
 FINCEQ(h)..                   FY(h)         =E= PROFIT(h)+SUM(im,SUM(f,REM(im,f,h)))
                                                 +SUM(ft,T(ft,h)*
                                                 RW(ft)*W(ft,h))+YBAR(h)
                                                  ;

 RYEQ..                        RY            =E= SUM(h, FY(h)) ;

 CDEQ(ip,h)..                  X(ip,h)       =E= beta(ip,h)*FY(h)/P(ip,h) ;

*MARKETED GOODS SURPLUS
 MSEQ(ip,h)..                  MS(ip,h)      =E= Q(ip,h)-SUM(jp,INTER(ip,jp,h))
                                                   -X(ip,h) ;

*HOUSEHOLD FACTOR MARKETED SURPLUS
 HFMSEQ(f,h)..                 HFMS(f,h)     =E= T(f,h)-SUM(jp,FD(f,jp,h))
                                                 -EXFD(f,h)-SUM(im,MIG(im,f,h)) ;

*TOTAL FACTOR MARKETED SURPLUS
 FMSEQ(f)..                  FMS(f)          =E= SUM(h,HFMS(f,h)) ;

*INTERNAL MIGRATION
 MIGEQ("MNAC",f,h)$gamma1("MNAC",f,h)..
                         MIG("MNAC",f,h)     =E= gamma1("MNAC",f,h)*REM("MNAC",f,h)
                                             /(RW(f)*W(f,h)) ;

*REMITTANCE FUNCTIONS
 REMEQ(im,f,h)$gamma1(im,f,h)..
                          REM(im,f,h)        =E= gamma0(im,f,h)*MIG(im,f,h)
                                                 **gamma1(im,f,h) ;

* HOUSEHOLD UTILITY
 UTILEQ(h)..              U(h) =E= PROD(ip$beta(ip,h),X(ip,h)**beta(ip,h)) ;

*COMPENSATING VARIATION CALCULATION
 CVEQ(h)..                   FY(h)           =E= PROFIT(h)+SUM(im,SUM(f,REM(im,f,h)))
                                                 +SUM(ft,T(ft,h)*
                                                 RW(ft)*W(ft,h))+YBAR(h)+CV(h)
                                                  ;

*#### ADDITIONAL RESTRICTIONS CORRESPONDING TO EQUATIONS

*#### VARIABLE BOUNDS, ACTIVITY NON-PARTICIPATION, FIXED INCOME
 Q.LO(ip,h) = 0.00;  FD.LO(f,jp,h) = 0.00;
 X.LO(ip,h) = 0.00;
 FD.FX(f,jp,h)$(alpha(f,jp,h) EQ 0) = 0.00;
 Q.FX(ip,h)$(OUTPUT(ip,h) EQ 0) = 0.0;
 MIG.FX(im,f,h)$(gamma1(im,f,h) EQ 0) = 0.0;
 REM.FX(im,f,h)$(gamma1(im,f,h) EQ 0) = 0.0;
 MIG.FX("MEXT",f,h) = MIG.L("MEXT",f,h);
 EXFD.FX(f,h) = EXFD.L(f,h) ;
 YBAR.FX(h) = YBAR.L(h) ;

*########### G O O D S ##############

*PERFECT GOODS MARKETS:  PRICES OF ALL TRADABLES ARE FIXED
 P.FX(ipns,h)    = P.L(ipns,h) ;
 P.FX(ips,hnsub) = P.L(ips,hnsub) ;
 MS.FX(ips,hsub) = MS.L(ips,hsub) ;

*########### F A C T O R S ##############
*SECTORAL WAGE DIFFERENTIALS FIXED FOR ALL TRADABLE AND FAMILY FACTORS,
*FREE FOR ALL FIXED FACTORS

*HOUSEHOLD FACTOR PRICES PEGGED TO RURAL PRICES FOR ALL TRADABLE FACTORS
*ENDOGENOUS "SHADOW WAGE" FOR FAMILY FACTORS


*FIXED FACTORS (LAND AND CAPITAL)
 RW.FX(fxf)      = RW.L(fxf) ;
 W.FX(fxf,h)     = W.L(fxf,h) ;
 FD.FX(fxf,jp,h) = FD.L(fxf,jp,h);

*FAMILY FACTORS (HOUSEHOLD SHADOW WAGES BUT FREE ALLOCATION ACROSS ACTIVITIES)
 RW.FX("FAMI")         = RW.L("FAMI") ;
 HFMS.FX("FAMI",h)     = HFMS.L("FAMI",h) ;
 WDIFF.FX("FAMI",jp,h) = WDIFF.L("FAMI",jp,h) ;

*NONAGRICULTURAL LABOR (ALL WAGES FIXED, FREE ALLOCATION ACROSS ACTIVITIES)
 RW.FX(fnat)           = RW.L(fnat) ;
 W.FX(fnat,h)          = W.L(fnat,h) ;
 WDIFF.FX(fnat,jp,h)   = WDIFF.L(fnat,jp,h) ;

*UNUSED AGRICULTURAL LABOR (ALL WAGES FIXED, FREE ALLOCATION ACROSS ACTIVITIES)
 RW.FX(fun)            = RW.L(fun) ;
 W.FX(fun,h)           = W.L(fun,h) ;
 WDIFF.FX(fun,jp,h)    = WDIFF.L(fun,jp,h) ;

*AGRICULTURAL LABOR, MALE (RURAL WAGE ENDOGENOUS, TRADABLE ACROSS HOUSEHOLDS)
 FMS.FX(fat)           = FMS.L(fat) ;
 W.FX(fat,h)           = W.L(fat,h) ;
 WDIFF.FX(fat,jp,h)    = WDIFF.L(fat,jp,h) ;

* FIXED HOUSEHOLD FACTOR ENDOWMENTS
 T.FX(f,h)             = T.L(f,h) ;
*########################### END OF BASE MODEL ############################

*###########################################################################
*#### BASE MODEL SOLVE STATEMENTS
*###########################################################################

 OPTIONS ITERLIM=1000,LIMROW=3,LIMCOL=0, SOLPRINT=On;

 MODEL DREM / PVAEQ,QEQ,INTEREQ,FDEQ,PROFITEQ,FINCEQ,RYEQ,CDEQ,MSEQ,HFMSEQ,
              REMEQ,FMSEQ,MIGEQ,UTILEQ / ;

 DREM.OPTFILE = 1 ;

 SOLVE DREM MAXIMIZING RY USING NLP;

 OPTION DECIMALS=2 ;

*###########################################################################
*#### SET UP TABLES TO REPORT OUTPUT FROM BASE MODEL
*###########################################################################

*$ontext ;
 PARAMETER FY0(h)           BASE FULL INCOME ;             FY0(h) = FY.L(h) ;
 PARAMETER PROFIT0(h)       BASE PROFIT ;                  PROFIT0(h) = PROFIT.L(h) ;
 PARAMETER Q0(ip,h)         BASE SECTORAL OUTPUT ;         Q0(ip,h) = Q.L(ip,h) ;
 PARAMETER QTOT0(ip)        BASE TOTAL OUTPUT ;            QTOT0(ip) = SUM(h,Q.L(ip,h)) ;
 PARAMETER STAPLES0(h)      BASE STAPLE OUTPUT ;           STAPLES0(h) = SUM(ips,Q.L(ips,h)) ;
 PARAMETER LIVE0(h)         BASE LIVESTOCK OUTPUT ;        LIVE0(h) = SUM(iliv,Q.L(iliv,h)) ;
 PARAMETER TRADS0(h)        BASE TRADITIONAL OUTPUT ;      TRADS0(h) = SUM(itrad,Q.L(itrad,h)) ;
 PARAMETER NOTRADS0(h)      BASE NONTRADITIONAL OUTPUT ;   NOTRADS0(h) = SUM(intrad,Q.L(intrad,h)) ;
 PARAMETER NONAG0(h)        BASE NONAGRICULTURAL OUTPUT ;  NONAG0(h) = SUM(inonag,Q.L(inonag,h)) ;
 PARAMETER XSTAPLES0(h)     BASE STAPLE DEMAND ;           XSTAPLES0(h) = SUM(ips,X.L(ips,h)) ;
 PARAMETER XLIVE0(h)        BASE LIVESTOCK DEMAND ;        XLIVE0(h) = SUM(iliv,X.L(iliv,h)) ;
 PARAMETER XTRADS0(h)       BASE TRADITIONAL DEMAND ;      XTRADS0(h) = SUM(itrad,X.L(itrad,h)) ;
 PARAMETER XNOTRADS0(h)     BASE NONTRADITIONAL DEMAND ;   XNOTRADS0(h) = SUM(intrad,X.L(intrad,h)) ;
 PARAMETER FD0(f,ip,h)      BASE FACTOR DEMANDS ;          FD0(f,ip,h) = FD.L(f,ip,h) ;
 PARAMETER W0(f,h)          BASE FACTOR WAGES ;            W0(f,h) = W.L(f,h) ;
 PARAMETER RW0(f)           BASE RURAL WAGES ;             RW0(f) = RW.L(f) ;
 PARAMETER FMS0(f)          BASE FACTOR MARKETED SURPLUS ; FMS0(f) = FMS.L(f) ;
 PARAMETER WDIFF0(f,ip,h)   BASE SECTORAL F-PRICE DIFFS ;  WDIFF0(f,ip,h) = WDIFF.L(f,ip,h) ;
 PARAMETER X0(ip,h)         BASE HH CONSUMPTION DEMANDS ;  X0(ip,h) = X.L(ip,h) ;
 PARAMETER MS0(ip,h)        BASE GOODS MARKETED SURPLUS ;  MS0(ip,h) = MS.L(ip,h) ;
 PARAMETER P0(ip,h)         BASE PRICES  ;                 P0(ip,h) = P.L(ip,h) ;
 PARAMETER T0(f,h)          BASE ENDOWMENTS ;              T0(f,h) = T.L(f,h) ;
 PARAMETER REM0(im,f,h)     BASE REMITTANCES ;             REM0(im,f,h) = REM.L(im,f,h) ;
 PARAMETER MIG0(im,f,h)     BASE MIGRATION ;               MIG0(im,f,h) = MIG.L(im,f,h) ;
 PARAMETER TOTMIG0(im)      BASE MIGRATION BY DEST ;       TOTMIG0(im) = SUM(h,sum(f,MIG.L(im,f,h))) ;
 PARAMETER TMIG0            BASE TOTAL MIGRATION ;         TMIG0 = SUM(h,sum(f,sum(im,MIG.L(im,f,h)))) ;
 PARAMETER CPI0(h)          BASE HOUSEHOLD CPI;            CPI0(h) = SUM(ip,beta(ip,h)*P0(ip,h)) ;
 PARAMETER RFY0(h)          BASE REAL FULL INCOME ;        RFY0(h)$CPI0(h) = FY0(h)/CPI0(h) ;
 PARAMETER INV0(h)          BASE INVESTMENTS ;             INV0(h) = SUM(c,beta(c,h)*FY.L(h)) ;
 PARAMETER RY0              BASE TOTAL RURAL INCOME ;      RY0 = RY.L ;
 PARAMETER U0(h)            BASE HOUSEHOLD WELFARE ;       U0(h) = U.L(h) ;
*$ontext ;
*###########################################################################
*## HOUSEHOLD-FARM EXPERIMENTS
*###########################################################################
*### Simulated 13.1% increase in maize price for households in market
 P.FX("MAIZ",hnsub) = P.L("MAIZ",hnsub)*1.131 ;

*######################### END OF MODIFICATIONS ############################

*###########################################################################
*#### EXPERIMENT MODEL SOLVE STATEMENTS
*###########################################################################

 OPTIONS ITERLIM=1000,LIMROW=1,LIMCOL=1, SOLPRINT=On;

 SOLVE DREM MAXIMIZING RY USING NLP;

 OPTION DECIMALS=2 ;

*###########################################################################
*## SET UP TABLES TO REPORT EXPERIMENT OUTPUT AS PERCENTAGE CHANGES FROM
*## BASE MODEL
*###########################################################################

 PARAMETER FY1(h)           NEW FULL INCOME ;             FY1(h) = FY.L(h) ;
 PARAMETER PROFIT1(h)       NEW PROFIT ;                  PROFIT1(h) = PROFIT.L(h) ;
 PARAMETER Q1(ip,h)         NEW SECTORAL OUTPUT ;         Q1(ip,h) = Q.L(ip,h) ;
 PARAMETER QTOT1(ip)        NEW TOTAL OUTPUT ;            QTOT1(ip) = SUM(h,Q.L(ip,h)) ;
 PARAMETER STAPLES1(h)      NEW STAPLE OUTPUT ;           STAPLES1(h) = SUM(ips,Q.L(ips,h)) ;
 PARAMETER LIVE1(h)         NEW LIVESTOCK OUTPUT ;        LIVE1(h) = SUM(iliv,Q.L(iliv,h)) ;
 PARAMETER TRADS1(h)        NEW TRADITIONAL OUTPUT ;      TRADS1(h) = SUM(itrad,Q.L(itrad,h)) ;
 PARAMETER NOTRADS1(h)      NEW NONTRADITIONAL OUTPUT ;   NOTRADS1(h) = SUM(intrad,Q.L(intrad,h)) ;
 PARAMETER NONAG1(h)        NEW NONAGRICULTURAL OUTPUT ;  NONAG1(h) = SUM(inonag,Q.L(inonag,h)) ;
 PARAMETER XSTAPLES1(h)     NEW STAPLE DEMAND ;           XSTAPLES1(h) = SUM(ips,X.L(ips,h)) ;
 PARAMETER XLIVE1(h)        NEW LIVESTOCK DEMAND ;        XLIVE1(h) = SUM(iliv,X.L(iliv,h)) ;
 PARAMETER XTRADS1(h)       NEW TRADITIONAL DEMAND ;      XTRADS1(h) = SUM(itrad,X.L(itrad,h)) ;
 PARAMETER XNOTRADS1(h)     NEW NONTRADITIONAL DEMAND ;   XNOTRADS1(h) = SUM(intrad,X.L(intrad,h)) ;
 PARAMETER FD1(f,ip,h)      NEW FACTOR DEMANDS ;          FD1(f,ip,h) = FD.L(f,ip,h) ;
 PARAMETER W1(f,h)          NEW FACTOR WAGES ;            W1(f,h) = W.L(f,h) ;
 PARAMETER RW1(f)           NEW RURAL WAGES ;             RW1(f) = RW.L(f) ;
 PARAMETER FMS1(f)          NEW FACTOR MARKETED SURPLUS ; FMS1(f) = FMS.L(f) ;
 PARAMETER WDIFF1(f,ip,h)   NEW SECTORAL F-PRICE DIFFS ;  WDIFF1(f,ip,h) = WDIFF.L(f,ip,h) ;
 PARAMETER X1(ip,h)         NEW HH CONSUMPTION DEMANDS ;  X1(ip,h) = X.L(ip,h) ;
 PARAMETER MS1(ip,h)        NEW GOODS MARKETED SURPLUS ;  MS1(ip,h) = MS.L(ip,h) ;
 PARAMETER P1(ip,h)         NEW PRICES  ;                 P1(ip,h) = P.L(ip,h) ;
 PARAMETER T1(f,h)          NEW ENDOWMENTS ;              T1(f,h) = T.L(f,h) ;
 PARAMETER RY1              NEW RURAL INCOME ;            RY1 = RY.L ;
 PARAMETER MIG1(im,f,h)     NEW MIGRATION ;               MIG1(im,f,h) = MIG.L(im,f,h) ;
 PARAMETER TOTMIG1(im)      NEW MIGRATION BY DEST;        TOTMIG1(im) = SUM(h,sum(f,MIG.L(im,f,h))) ;
 PARAMETER TMIG1            NEW TOTAL MIGRATION ;         TMIG1 = SUM(h,sum(f,sum(im,MIG.L(im,f,h)))) ;
 PARAMETER REM1(im,f,h)     NEW REMITTANCES ;             REM1(im,f,h) = REM.L(im,f,h) ;
 PARAMETER CPI1(h)          NEW HOUSEHOLD CPI;            CPI1(h) = SUM(ip,beta(ip,h)*P1(ip,h)) ;
 PARAMETER RFY1(h)          NEW REAL FULL INCOME ;        RFY1(h)$CPI1(h) = FY1(h)/CPI1(h) ;
 PARAMETER INV1(h)          NEW INVESTMENTS ;             INV1(h) = SUM(c,beta(c,h)*FY.L(h)) ;
 PARAMETER RY1              NEW TOTAL RURAL INCOME ;      RY1 = RY.L ;

*#### PERCENTAGE CHANGES FROM BASE IN EXPERIMENT

 PARAMETER FY2(h)          PERCENTAGE CHANGE IN FULL INCOME ;
 PARAMETER PROFIT2(h)      PERCENTAGE CHANGE IN PROFIT ;
 PARAMETER Q2(ip,h)        PERCENTAGE CHANGE IN SECTORAL OUTPUT ;
 PARAMETER QTOT2(ip)       PERCENTAGE CHANGE IN TOTAL OUTPUT ;
 PARAMETER STAPLES2(h)     PERCENTAGE CHANGE IN STAPLE OUTPUT ;
 PARAMETER LIVE2(h)        PERCENTAGE CHANGE IN LIVESTOCK OUTPUT ;
 PARAMETER TRADS2(h)       PERCENTAGE CHANGE IN TRADITIONAL OUTPUT ;
 PARAMETER NOTRADS2(h)     PERCENTAGE CHANGE IN NONTRADITIONAL OUTPUT ;
 PARAMETER NONAG2(h)       PERCENTAGE CHANGE IN NONAGRICULTURAL OUTPUT ;
 PARAMETER XSTAPLES2(h)    PERCENTAGE CHANGE IN STAPLE DEMAND ;
 PARAMETER XLIVE2(h)       PERCENTAGE CHANGE IN LIVESTOCK DEMAND ;
 PARAMETER XTRADS2(h)      PERCENTAGE CHANGE IN TRADITIONAL DEMAND ;
 PARAMETER XNOTRADS2(h)    PERCENTAGE CHANGE IN NONTRADITIONAL DEMAND ;
 PARAMETER FD2(f,ip,h)     PERCENTAGE CHANGE IN FACTOR DEMANDS ;
 PARAMETER W2(f,h)         PERCENTAGE CHANGE IN FACTOR WAGES ;
 PARAMETER RW2(f)          PERCENTAGE CHANGE IN RURAL FACTOR PRICES ;
 PARAMETER FMS2(f)         PERCENTAGE CHANGE IN FACTOR MARKETED SURPLUS ;
 PARAMETER WDIFF2(f,ip,h)  PERCENTAGE CHANGE IN SECTORAL FACTOR-PRICE DIFFERENTIALS ;
 PARAMETER X2(ip,h)        PERCENTAGE CHANGE IN HOUSEHOLD CONSUMPTION DEMANDS ;
 PARAMETER MS2(ip,h)       PERCENTAGE CHANGE IN COMMODITY MARKETED SURPLUS (TRADABLES) ;
 PARAMETER P2(ip,h)        PERCENTAGE CHANGE IN COMMODITY PRICES ;
 PARAMETER MIG2(im,f,h)    PERCENTAGE CHANGE IN MIGRATION ;
 PARAMETER TOTMIG2(im)     PERCENTAGE CHANGE IN MIGRATION BY DEST ;
 PARAMETER TMIG2           PERCENTAGE CHANGE IN TOTAL MIGRATION ;
 PARAMETER REM2(im,f,h)    PERCENTAGE CHANGE IN REMITTANCES ;
 PARAMETER RFY2(h)         PERCENTAGE CHANGE IN REAL FULL INCOME ;
 PARAMETER CPI2(h)         PERCENTAGE CHANGE IN HOUSEHOLD CPI ;
 PARAMETER INV2(h)         PERCENTAGE CHANGE IN INVESTMENTS ;
 PARAMETER RY2             PERCENTAGE CHANGE IN TOTAL RURAL INCOME ;

 FY2(h)$FY0(h)             = 100*(FY1(h)/FY0(h)-1) ;
 PROFIT2(h)$PROFIT0(h)     = 100*(PROFIT.L(h)/PROFIT0(h)-1) ;
 Q2(ip,h)$Q0(ip,h)         = 100*(Q.L(ip,h)/Q0(ip,h)-1) ;
 QTOT2(ip)$QTOT0(ip)       = 100*(SUM(h,Q.L(ip,h))/QTOT0(ip)-1) ;
 STAPLES2(h)$STAPLES0(h)   = 100*(STAPLES1(h)/STAPLES0(h)-1) ;
 LIVE2(h)$LIVE0(h)         = 100*(LIVE1(h)/LIVE0(h)-1) ;
 TRADS2(h)$TRADS0(h)       = 100*(TRADS1(h)/TRADS0(h)-1) ;
 NOTRADS2(h)$NOTRADS0(h)   = 100*(NOTRADS1(h)/NOTRADS0(h)-1) ;
 NONAG2(h)$NONAG0(h)       = 100*(NONAG1(h)/NONAG0(h)-1) ;
 XSTAPLES2(h)$XSTAPLES0(h) = 100*(XSTAPLES1(h)/XSTAPLES0(h)-1) ;
 XLIVE2(h)$XLIVE0(h)       = 100*(XLIVE1(h)/XLIVE0(h)-1) ;
 XTRADS2(h)$XTRADS0(h)     = 100*(XTRADS1(h)/XTRADS0(h)-1) ;
 XNOTRADS2(h)$XNOTRADS0(h) = 100*(XNOTRADS1(h)/XNOTRADS0(h)-1) ;
 FD2(f,ip,h)$FD0(f,ip,h)   = 100*(FD.L(f,ip,h)/FD0(f,ip,h)-1) ;
 W2(f,h)                   = 100*(W.L(f,h)/W0(f,h)-1) ;
 RW2(f)                    = 100*(RW.L(f)/RW0(f)-1) ;
 FMS2(f)$FMS0(f)           = 100*(FMS.L(f)/FMS0(f)-1) ;
 MIG2(im,f,h)$MIG0(im,f,h) = 100*(MIG.L(im,f,h)/MIG0(im,f,h)-1) ;
 TOTMIG2(im)$TOTMIG0(im)
                           = 100*(TOTMIG1(im)/TOTMIG0(im)-1) ;
 TMIG2$TMIG0               = 100*(TMIG1/TMIG0-1) ;
 REM2(im,f,h)$REM0(im,f,h) = 100*(REM.L(im,f,h)/REM0(im,f,h)-1) ;
 WDIFF2(f,ip,h)$WDIFF0(f,ip,h)
                           = 100*(WDIFF.L(f,ip,h)/WDIFF0(f,ip,h)-1) ;
 X2(ip,h)$X0(ip,h)         = 100*(X.L(ip,h)/X0(ip,h)-1) ;
 MS2(ip,h)$MS0(ip,h)       = 100*(MS.L(ip,h)/MS0(ip,h)-1) ;
 P2(ip,h)                  = 100*(P.L(ip,h)/P0(ip,h)-1) ;
 P2(ip,h)$P0(ip,h)         = 100*(P.L(ip,h)/P0(ip,h)-1) ;
 RFY2(h)$RFY0(h)           = 100*(RFY1(h)/RFY0(h)-1) ;
 CPI2(h)$CPI0(h)           = 100*(CPI1(h)/CPI0(h)-1) ;
 INV2(h)$INV0(h)           = 100*(INV1(h)/INV0(h)-1) ;
 RY2                       = 100*(RY1/RY0-1) ;


*###########################################################################
*#### CV CALCULATION MODEL
*###########################################################################

*THIS SUBROUTINE CALCULATES THE TRANSFER TO EACH HOUSEHOLD GROUP REQUIRED
*TO MAINTAIN CONSTANT UTILITY BEFORE AND AFTER THE SIMULATION--THAT IS, THE
*RURAL ECONOMY-WIDE COMPENSATING VARIATIONS. THESE ARE POSITIVE FOR HOUSEHOLDS
*THAT LOSE AS A RESULT OF THE SIMULATED SHOCK AND NEGATIVE FOR HOUSEHOLDS
*THAT BENEFIT FORM THE SHOCK.

 DISPLAY U0 ;
 U.FX(h) = U0(h) ;

 OPTIONS ITERLIM=1000,LIMROW=3,LIMCOL=0, SOLPRINT=On;

 MODEL CVCALC / PVAEQ,QEQ,INTEREQ,FDEQ,PROFITEQ,CVEQ,RYEQ,CDEQ,MSEQ,HFMSEQ,
              REMEQ,FMSEQ,MIGEQ,UTILEQ / ;

 CVCALC.OPTFILE = 1 ;

 SOLVE CVCALC MAXIMIZING RY USING NLP;

 OPTION DECIMALS=2 ;

 PARAMETER CV1(h)          COMPENSATING VARIATION ;   CV1(h)  = CV.L(h) ;
 PARAMETER CV2(h)          CV PCT BASE INCOME ;       CV2(h)  = 100*CV.L(h)/FY0(h) ;
 PARAMETER CVTOT1          TOTAL CV ;                 CVTOT1  = SUM(h,CV.L(h)) ;
 PARAMETER CVTOT2          TOTAL CV PCT RURAL INCOME; CVTOT2  = 100*CVTOT1/SUM(h,FY0(h)) ;

*############################################################################
*#### RESULTS:  PERCENTAGE CHANGES FROM BASE IN EXPERIMENT
*############################################################################

 DISPLAY STAPLES2, Q2, LIVE2, TRADS2, NOTRADS2, NONAG2, W2, RW2, P2,
         TMIG2, TOTMIG2, FY2, RY2, XSTAPLES2, XLIVE2, XTRADS2 ;
 DISPLAY CV1, CV2, CVTOT1, CVTOT2 ;
