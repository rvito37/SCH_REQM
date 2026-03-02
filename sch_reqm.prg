#include "avxdefs.ch"
#translate EmptyAllocWin() => FirstAlloc()
#DEFINE EOL chr(13) + chr(10)
#define PACK_B_ID     1
#define PACK_ROUTE    2
#define PACK_PRIOR    3
#define PACK_REM      4
#define PACK_QTY      5
#define PACK_DATE     6
#define PACK_COMMENT  7
#define PACK_DIVISOR  8
#define PACK_DIEL     9
#define PACK_NCAPS    10
#define PACK_BSTAT    11
#define PACK_ESN      12

#define GET_DATE 8

MEMVAR aBuffer
STATIC oMyRep,cFileName,hUpd_qty,hUpd_route
STATIC oBrostk    ,;
     oBroln     ,;
     cWhichBro  ,;
     cKeyStk    ,;
     cKeyLn     ,;
     cDestESN   ,;
     cDestWH    ,;
     cRemark    ,;
     nDestQTY   ,;
     cDestComm  ,;
     aTempWhs   ,;
     aTempQtys  ,;
     cFlags
STATIC mPTYPE_ID  ,;
     mPLINE_ID  ,;
     mSIZE_ID   ,;
     mVALUE_ID
STATIC nB_ID       ,;
     nB_PURP     ,;
     nESN_ID     ,;
     nB_TYPE     ,;
     nSIZE_ID    ,;
     nVALUE_ID   ,;
     nTOL_ID     ,;
     nVOLT_ID    ,;
     nDIEL_ID    ,;
     nDIEL_WIDTH ,;
     nB_NCAPS    ,;
     nB_DOPEN    ,;
     nQTY_BINI   ,;
     nUOM_INI    ,;
     nROUTE_ID   ,;
     nREV        ,;
     nB_PRIOR    ,;
     nB_DPROM    ,;
     nEXPQ_FCTR  ,;
     nB_STAT     ,;
     nB_REMARK
STATIC aoOpenedList
STATIC aValues := {nil,nil,nil}
STATIC lNoRoute := .F.
STATIC lTestDbf := .F.
STATIC lTestFirst := .F.
STATIC lCont := .F.
STATIC lSubstitutable,lTestWhs
STATIC aStkAlloc,nLnAllocCounter
STATIC nProc,nProcFilter
STATIC aMyFamily := {}

static function AvailQtyStr(cWh,oBrostk)

LOCAL nInWh

DEFAULT cWh TO oBrostk:GetColumn(oBrostk:colPos):Cargo
nInWh := d_stock->( FIELDGET( d_stock->( FIELDPOS(cWh) ) ) )
RETURN Transform( nInWh,"999,999" )
///////////////////////////////////////////////////////////////////
Static Function GetFrzQty()
Local cRetVal
d_frzstk->(dbseek(d_stock->b_id+d_stock->esn_id+d_stock->LOC))
IIF(d_frzstk->(found()),str(cRetVal := d_frzstk->frz_qty),cRetVal := replicate(chr(219),7) )
Return cRetval
////////////////////////////////////////////////////////////////////
static function GetFrzRemark()
Local cRetVal
d_frzstk->(dbseek(d_stock->b_id+d_stock->esn_id+d_stock->LOC))
cRetVal := d_frzstk->frz_remark
Return cRetval
////////////////////////////////////////////////////////////////////
Function  GetFrzln()
Local cRetVal
d_frzln->(dbseek(d_line->b_id))
IIF(d_frzln->(found()),cRetVal := chr(251),cRetVal := " " )
Return cRetVal
/////////////////////////////////////////////////////////////////////
STATIC PROCEDURE Show( pcMoveMsg,cAlias )

LOCAL nKey
LOCAL cSearcher := IIF(cAlias=="d_stock",cKeyStk ,cKeyLn )
LOCAL cSaveLine
LOCAL aOldF1Keys
LOCAL nRecno
LOCAL aKeyList :={{ "Enter    - Enter Qty to freeze   ",K_ENTER  } } // ,;


AADD(aKeyList, { "Esc      - Exit           ",K_ESC    } )

cSaveLine := SaveScreen( 2,0,2,79 )
aOldF1Keys := SetHlpKeys( aKeyList )


@ 2,0 SAY cSearcher COLOR "n/w"

WHILE  .T.
     IIF(cAlias=="d_stock",oBrostk:refreshAll() ,oBroln:refreshAll() )
     WHILE NextKey() = 0 .AND. IIF(cAlias=="d_stock",!oBrostk:stabilize() ,!oBroln:stabilize() ) ; ENDDO

          nKey := TimeOutInKey()

          F1 PRESSED


          IF nKey = K_ESC
               cWhichBro := NIL
               EXIT
          ELSEIF nKey = K_TAB
               IIF(cAlias=="d_stock",cKeyStk := cSearcher,cKeyLn := cSearcher )
               IIF(cAlias == "d_stock",cWhichBro := "d_line" ,cWhichBro := "d_stock" )
               RestScreen(2,0,2,79,cSaveLine)
               EXIT
          ELSEIF nKey = K_BS
               IF !Empty(Len(cSearcher))
                    cSearcher := SubStr(cSearcher,1,Len(cSearcher)-1)
                    (cAlias)->( DbSeek(cSearcher,.T.) )
                    IIF(cAlias=="d_stock",oBrostk:refreshAll() ,oBroln:refreshAll() )
               END
               RestScreen(2,0,2,79,cSaveLine)
               @ 2,0 SAY cSearcher COLOR "n/w"
          ELSEIF nKey = K_ALT_BS
               cSearcher := ""
               IIF(cAlias=="d_stock",oBrostk:goTop() ,oBroln:goTop() )
               IIF(cAlias=="d_stock",oBrostk:refreshAll() ,oBroln:refreshAll() )
               RestScreen(2,0,2,79,cSaveLine)
               @ 2,0 SAY cSearcher COLOR "n/w"
          ELSEIF nKey = K_ALT_S   //04/10/2000 change indexes
               cSearcher := ""
               SwitchTag(cAlias,{3,30})
               IIF(cAlias=="d_stock",oBrostk:goTop() ,oBroln:goTop() )
               IIF(cAlias=="d_stock",oBrostk:refreshAll() ,oBroln:refreshAll() )
               RestScreen(2,0,2,79,cSaveLine)
          ELSEIF nKey >= 32 .AND. nKey <= 255
               cSearcher += Upper( Chr( nKey ) )
               IF (cAlias)->( DbSeek(cSearcher,.T.) )

               ELSE
                    Alert("!„€‰‚™;;!! „† …‡š š…˜…™ ‰€",{"˜…™‰€"})
                    cSearcher := SubStr(cSearcher,1,Len(cSearcher)-1)
                    (cAlias)->(DbSeek(cSearcher,.T.))
               END
               RestScreen(2,0,2,79,cSaveLine)
               @ 2,0 SAY cSearcher COLOR "n/w"
               IIF(cAlias=="d_stock",oBrostk:refreshAll() ,oBroln:refreshAll() )
          ELSEIF StdKeys( nKey , IIF(cAlias=="d_stock",oBrostk,oBroln) )
               IIF(cAlias=="d_stock",oBrostk:refreshAll() ,oBroln:refreshAll() )
               RestScreen(2,0,2,79,cSaveLine)
               @ 2,0 SAY cSearcher COLOR "n/w"
          ELSEIF IIF(cAlias=="d_stock",oBrostk:stable,oBroln:stable)
               DO CASE
                    CASE nKey == K_ENTER .AND. cAlias == "d_stock"
                         IF oBrostk:colPos > 2 .AND. oBrostk:colPos < 7
                              nRecno := D_STOCK->( RECNO() )
                              GetDestData( nKey )
                              d_stock->( DBGOTO( nRecno) )
                              oBrostk:RefreshAll()
                         ELSE
                              Msg24( {"198"} , 3 , .T. )
                         ENDIF
                    CASE nKey == K_ENTER .AND. cAlias == "d_line"
                         IF oBroln:colPos == 9
                              UpdateLn( )
                              oBroln:RefreshAll()
                         ELSE
                              Msg24( {"309"} , 3 , .T. )
                         ENDIF

                    CASE nKey = K_ALT_F9

               ENDCASE

          ENDIF

     ENDDO
     SetHlpKeys( aOldF1Keys )
RETURN
//////////////////////////////////////////////
STATIC PROCEDURE GetDestData( nKey )
LOCAL bInsSave ,;
     nCursSave
LOCAL cScr,lFlag  := .F.
cFlags := ""
cDestESN   := d_stock->esn_id
cDestWH    := SetDestWh()
nDestQTY   := Val( StrTran( Eval( oBrostk:getColumn( oBrostk:colPos ):block ),",","") )
cRemark    := GetFrzRemark()
IF cDestWh $ "WH1_WH2"
     lFlag := .T.
ENDIF

IIF(cDestWh $ "WH3_WH4" .AND. d_stock->esny_id $ "4_7_H_D_C",lFlag := .T.,lFlag := .F. )

IIF(empty(nDestQTY),lFlag := .F.  ,lFlag := .T. )

IF lFlag
     @ 17 , 2  SAY "Information:" COLOR "BG+/B"
     @ 18 , 2  SAY "ESN:" COLOR "W+/B"
     @ 19 , 2  SAY "Wh#:" COLOR "W+/B"
     @ 20 , 2  SAY "Qty.....:" COLOR "W+/B"
     @ 18 , 9  say cDestESN   COLOR GETCOLORS PICTURE "@!"
     @ 19 , 9  say cDestWH    COLOR GETCOLORS
     @ 20 , 9  GET nDestQTY   COLOR GETCOLORS PICTURE "9999999";
               SEND preBlock := {|o| preQCQTY(o)  } ;
               SEND postBlock := {|o| postQCQTY(o,cDestWh) }
	  @ 21,2 SAY "Remark:" COLOR "W+/B"
	  @ 21,9 GET cRemark
	  XREAD
ENDIF
GetList := {}
IF lFlag .AND. LASTKEY() <> K_ESC .AND. ALERT("Update now?",{"Yes","No"}, ALERT_STD) == 1
     cScr := SAVESCREEN()
     MsgBox("Updating files, please wait...")
     NowUpdate()
     RESTSCREEN(,,,,cScr)
     SELECT d_stock
END

ZeroMove()

RETURN

STATIC PROCEDURE ZeroMove
@ 17,0 CLEAR TO 21,79
cDestESN  := Space( 16 )
cDestWH   := " "
nDestQTY  := 0

RETURN

STATIC FUNCTION postQCQTY(o,cDestWh)
LOCAL nBuffer := o:varGet()
LOCAL nQty := Val( StrTran( Eval( oBrostk:getColumn( oBrostk:colPos ):block ),",","") )
LOCAL lRetVal, nIncr

IF LastKey() = K_UP
RETURN .T.
ENDIF

IF Empty( nBuffer )
     Msg24( {"308" } , 3 , .T. )
RETURN .T.
ENDIF

IF Negative( o )
RETURN .F.
ENDIF

IF nBuffer <= nQty
     lRetVal := .T.
     cFlags += "x"
ELSE
     Msg24( {"199"} , 3 , .T. )
     lRetVal := .F.
ENDIF

IF lRetVal
	c_esny->(dbseek(d_stock->esny_id))

	IF cDestWh $ "WH3_WH4" .AND. nBuffer % c_esny->esny_qty <> 0
	     ALERT("ERROR;; Quantity must be in increments of "+;
	          ALLTRIM(STR(c_esny->esny_qty)), {" OK "} )
	     lRetVal := .F.
	ELSEIF cDestWh $ "WH3_WH4" .AND. nBuffer % c_esny->esny_qty == 0
	       lRetVal := .T.
	ELSEIF cDestWh $ "WH1_WH2" .AND. nBuffer <> nQty
			 lRetVal := .F.
	ENDIF
ENDIF

RETURN lRetVal

STATIC FUNCTION preQCQTY(o)
LOCAL lRetVal := .T.
LOCAL nQty := Val( StrTran( Eval( oBrostk:getColumn( oBrostk:colPos ):block ),",","") )

IF Empty( nQty )
     Msg24( {"201" } , 3 , .T. )
     lRetVal := .F.
ENDIF

RETURN lRetVal

STATIC FUNCTION SetDestWh
LOCAL cRetVal := " "
cRetVal :=  Alltrim(StrTran( oBrostk:getColumn( oBrostk:colPos ):cargo ,"Wh #" , "" ))
RETURN cRetVal

STATIC FUNCTION NowUpdate()
D_FRZSTK->(dbseek(d_stock->b_id+d_stock->esn_id+d_stock->LOC))
IF d_frzstk->(found())
     d_frzstk->(RecLock(5,"SCHED"))
     IF (nDestQty == 0)
	  	  d_frzstk->(dbdelete())
	  ELSE
	  	  d_frzstk->frz_qty := nDestQTY
		  d_frzstk->frz_remark   := cRemark
	  ENDIF
     d_frzstk->(dbunlock())
ELSEIF  !(d_frzstk->(found())) .AND. nDestQTY <> 0
     d_frzstk->(RecLock(5,"SCHED"))
     d_frzstk->(dbappend())
     d_frzstk->b_id     := d_stock->b_id
     d_frzstk->b_type   := d_stock->b_type
     d_frzstk->esn_id   := d_stock->esn_id
     d_frzstk->esnxx_id := d_stock->esnxx_id
     d_frzstk->esny_id  := d_stock->esny_id
     d_frzstk->ptype_id := d_stock->ptype_id
     d_frzstk->pline_id := d_stock->pline_id
     d_frzstk->size_id  := d_stock->size_id
     d_frzstk->value_id := d_stock->value_id
     d_frzstk->volt_id  := d_stock->volt_id
     d_frzstk->tc_id    := d_stock->tc_id
     d_frzstk->tol_id   := d_stock->tol_id
     d_frzstk->term_id  := d_stock->term_id
     d_frzstk->dadd_rec := d_stock->dadd_rec
     d_frzstk->dlu_rec  := d_stock->dlu_rec
     d_frzstk->tlu_rec  := d_stock->tlu_rec
     d_frzstk->ulu_rec  := d_stock->ulu_rec
     d_frzstk->wlu_rec  := d_stock->wlu_rec
     d_frzstk->plu_rec  := d_stock->plu_rec
     d_frzstk->lockkey  := d_stock->lockkey
	  d_frzstk->loc      := d_stock->loc
     d_frzstk->frz_qty  := nDestQTY
     d_frzstk->frz_remark   := cRemark
     d_frzstk->(dbunlock())
ENDIF
oBrostk:refreshCurrrent()
Return nil
////////////////////////////////////////////
static function  UpdateLn()
D_FRZLN->(dbseek(d_line->b_id))
IF d_frzln->(found())
     d_frzln->(RecLock(5,"SCHED"))
     d_frzln->(dbdelete())
     d_frzln->(dbunlock())
ELSE
     d_frzln->(RecLock(5,"SCHED"))
     d_frzln->(dbappend())

     d_frzln->b_id := d_line->b_id

     d_frzln->(dbunlock())
ENDIF
oBroln:refreshCurrrent()
Return NIL


/////////////////Runnig Schedulling//////////////////////////////////


/////////////////////////////////////////////////////////////////////


Function Sched_R3()
LOCAL aCrits,n,i,nLen,cSaveLine
LOCAL oRep  := TheReport():New( "SCHEDV03","Auto Scheduling recommendations")
field sresn_id,poln_type,ptype_id,pline_id,value_id,tol_id,tc_id,esnxx_id,;
     esny_id,sarea_id,billag_id,cuco_id,cu_id,Poln_stat,d_ordrec,d_rqstdlv,;
     slack, SIZE_ID, pb_id, esn_id, dsesn_id,dadd_rec

oRep:SetSort({"main"})
oRep:SetExprSort({"ptype_id+pline_id+size_id+str(value_id,9,3)"})
oRep:SetFields( {})
oRep:SetTitles({})
aCrits := { ;
     "Product type"      ,;
     "Product line"      ,;
     "Size"              ,;
     "Value"             ,;
     "Purpose"           ,;
     "Status"            ,;
	  "ESN(XX)"            ;
     }
oRep:SetCrit(aCrits)
oRep:SetBuffer(aCrits)
oRep:SetCheck({;
     {|o| critBrowse( o ,{"all"},"c_ptype", , {|| c_ptype->ptype_id},{|| c_ptype->ptype_nm }  )},;
     {|o| critBrowse( o ,{"all"},"c_pline", , {|| c_pline->pline_id},{|| c_pline->pline_nm }  )},;
     {|o| critBrowse( o ,{"all"},"c_size" , , {||  c_size->size_id },{|| Space(60) }          )},;
     {|o| critBrowse( o ,{"all"},"c_value", , {|| Str(c_value->value_id,9,3) } ,{|| c_value->value_nm})},;
     {|o| critBrowse( o ,{"all"},"c_bpurp", , {|| c_bpurp->b_purp},{|| c_bpurp->bpurp_nme }  )},;
     {|o| critBrowse( o ,{"all"},"c_bstat", , {|| c_bstat->b_stat},{|| c_bstat->bstat_nme }  )},;
	  {|o| critBrowse( o ,{"all"},"c_esnxx", , {|| c_esnxx->esnxx_id } ,{|| c_esnxx->esnxx_nm } )}  })
oRep:SetQueryBlocks({;
     {|| ptype_id          $ aBuffer[ 1] },;
     {|| pline_id          $ aBuffer[ 2] },;
     {|| size_id           $ aBuffer[ 3] },;
     {|| STR(value_id,9,3) $ aBuffer[ 4] },;
     {|| .T.                             },;
     {|| .T.                             },;
	  {|| esnxx_id          $ aBuffer[ 7] };
     })
oRep:SetDB({"d_ord"})
oRep:lSuperSmart    :=   .T.
oRep:aSuperCriteria :=   {2}
oRep:aSuperIndexes  :=   { {"iordpic",.f.} }
oRep:cRepDbf :="t_ord"
oRep:cPrepDbf :="t_ordPre"
oRep:cRepFileName := "pendord"
oRep:cbExtraCond  := {|| !(D_ORD->POLN_STAT $ "C_D") .AND. (d_ORD->QTY_ord-d_ord->qty_canc-d_ord->qty_shipd-d_ord->qty_alloc) > 0 }
oRep:cbPrepDbf := {|o| DoSched(o) }

IF oRep:Exec(.T.)  //schedulling report 4.4 in Sched Spec


     cSaveLine := SaveScreen( 2,0,2,79 )

	  /*IF  FILE(GetUserInfo():cTempDir + "routprob.txt")
	  	   COPY FILE &(GetUserInfo():cTempDir+"routprob.txt") TO LPT1   //print all error messages
	  ENDIF
       IF  FILE(GetUserInfo():cTempDir + "qtyprob.txt")
             COPY FILE &(GetUserInfo():cTempDir+"qtyprob.txt") TO LPT1   //print all error messages
       ENDIF*/

	  oREP := nil
     oREP := rpNew(  5,   2,  22,  77,  31, 128)

     rpDataPath(  oREP, GetUserInfo():cTempDir)
     rpIndexPath( oREP, GetUserInfo():cTempDir )
     rpSwapPath(  oREP, GetUserInfo():cTempDir )


     /*oRep := rpQuickLoad(@oRep,"RPQC33V1.rh2")   //rpqc33v1

     rpDestination( oREP,1)
     rpprinter(oRep,GetDefPrn())
     rpUseFonts(oRep,.f.)
     rpGenReport( oREP )
     rpKillSorts( oREP )
     rpCloseData( oREP )

     oRep := rpQuickLoad(@oRep,"RPQC34V1.rh2")   //rpqc34v1

     rpDestination( oREP,1)
     rpprinter(oRep,GetDefPrn())
     rpUseFonts(oRep,.f.)
     rpGenReport( oREP )
     rpKillSorts( oREP )
     rpCloseData( oREP )*/

     /*NetUse("T_Ro2upd",STD_RETRY, ,USE_EXCLUSIVE,USE_NEW,GetUserInfo():cTempDir)
     IF T_Ro2upd->(lastRec()) <> 0
          oRep := rpQuickLoad(@oRep,"TRO2UP.rh2")//route's to update

          rpDestination( oREP,1)
          rpprinter(oRep,GetDefPrn())
          rpUseFonts(oRep,.f.)
          rpGenReport( oREP )
          rpKillSorts( oREP )
          rpCloseData( oREP )
	  Endif
     IIF( Select("T_Ro2upd") <> 0,T_Ro2upd->(dbclosearea()) , nil)*/

	  COPY FILE SC_LINE.cdx TO &(GetUserInfo():cTempDir+"T_line01.cdx")
	  //Alert("Call to MIS!(Vitaly-239)",{"Ok"})
	  NetUse("T_line01",STD_RETRY, ,USE_EXCLUSIVE,USE_NEW,GetUserInfo():cTempDir,"D_LINE")
	  d_line->(dbreindex())
     IF d_line->(lastRec()) <> 0
			 GenOpenfiles({"d_Irrfin","c_expqty","c_tol","d_finqc"})
			 oREP := nil
			 oREP := rpNew(  5,   2,  22,  77,  31, 128)

			 rpDataPath  ( oRep, GetUserInfo():cTempDir )
          rpIndexPath ( oRep, GetUserInfo():cTempDir )
          rpSwapPath  ( oRep, GetUserInfo():cTempDir )

          oRep := rpQuickLoad(@oRep,"RPQC01V1.rh2")//route's to update
          rpDestination( oREP,1)
          rpprinter(oRep,GetDefPrn())
          rpUseFonts(oRep,.f.)
          rpGenReport( oREP )
          rpKillSorts( oREP )
          rpCloseData( oREP )

	  Endif
     IIF( Select("D_LINE") <> 0,D_LINE->(dbclosearea()) , nil)
	  IIF( Select("d_prom") <> 0,d_prom->(dbclosearea()) , nil)


	  RestScreen( 2,0,2,79,cSaveLine)
ENDIF
CLOSE ALL
ferase(GetUserInfo():cTempDir+"*.cdx")
ferase(GetUserInfo():cTempDir+"*.tmp")
Return nil
/////////////////////////////////////////////////////////////////
Static Procedure ShowForm()
DispBox( 7, 10 , 10 ,63 , B_DOUBLE+" " )
DispBox( 11, 10 , 14 ,63 , B_DOUBLE+" " )
DispBox( 15, 10 , 22 ,63 , B_DOUBLE+" " )
Return
/////////////////////////////////////////////////////////////////

static function  DoSched(oRep)
LOCAL cTempDir := GetUserInfo():cTempDir,cFamily
LOCAL oForm := Form():new(,,,,"The Auto Scheduler" ,, ProcName() )
LOCAL I :=1,nCount := 0,nSubCount := 0
LOCAL cValue
LOCAL nSum,nSubSum
LOCAL nRecNo
LOCAL cRoute := {}
LOCAL aFamiles
local lPreAvail := .T.
LOCAL aOrdStruc := {}
LOCAL aRo2upd := { {"b_id","C",9,0},;
     {"route_id","C",4,0},;
     {"b_dprom","D",8,0},;
     {"comments","C",25,0}  }
LOCAL aComby :=  { {"tc_id","C",1,0},;
     {"b_ncaps","C",2,0}  }

LOCAL aAvail :=  { {"b_id","C",6,0}     ,;
     {"ptype_id","C",1,0} ,;
     {"pline_id","C",3,0} ,;
     {"size_id","C",4,0}  ,;
     {"value_id","N",9,3} ,;
     {"tol_id","C",1,0}   ,;
     {"volt_id","C",1,0}  ,;
     {"tc_id","C",1,0}    ,;
     {"accum_qty","N",7,0},;
     {"net_qty","N",7,0}  ,;
     {"dadd_rec","D",8,0} ,;
     {"dlu_rec","D",8,0}  ,;
     {"tlu_rec","C",5,0}  ,;
     {"ulu_rec","C",10,0} ,;
     {"wlu_rec","C",12,0} ,;
     {"plu_rec","C",8,0} }
local aDlineStruct


FIELD ptype_id,pline_id,size_id,value_id,tol_id,volt_id,tc_id,b_id
ShowForm()
aMyFamily := {GetBuffer("Product type"),GetBuffer("Product line"),GetBuffer("Size"),GetBuffer("Value")}
MakeFrzStk()  //prepare dbf for report(t_frzstk)
MakeFrzProd() //prepare dbf for report(t_frz)
ferase(GetUserInfo():cTempDir + "routprob.txt")
ferase(GetUserInfo():cTempDir + "qtyprob.txt")
GenOpenfiles({"d_line","d_prom","d_stock","c_potype","C_TOL","d_avail","c_esny","m_linemv","d_esn","c_btype","M_STKMV","D_PACK","c_proc","c_expqty","C_CURR","C_EXRATE","d_edsgn","c_hierar","d_pcaud","m_bstamv","d_irrfin","d_finqc","c_pline","c_leadt","c_bstat","c_bpurp","c_volt","c_sbstxx","d_frzstk"})
IIF(FILE(cTempDir+"T_Ro2upd.dbf"),FERASE(cTempDir+"T_Ro2upd.dbf") ,nil )
dbcreate(cTempDir+"T_Ro2upd.dbf",aRo2upd,NIL)    //print route card
IIF(FILE(cTempDir+"t_comby"),FERASE(cTempDir+"T_comby.dbf") ,nil )
dbcreate(cTempDir+"T_comby.dbf",aComby,NIL)      //testting for j & k
IIF(FILE(cTempDir+"T_avail.dbf"),FERASE(cTempDir+"T_avail.dbf") ,nil )
dbcreate(cTempDir+"T_Avail.dbf",aAvail,NIL)      //print route card
CreateTempDbf("t_prom","tprombn")
CreateTempDbf("t_pack","tpackbn")
CreateTempDbf("t_pcksav")
aDlinestruct := d_line->(dbstruct())
IIF(FILE(cTempDir+"q_line.*"),FERASE(cTempDir+"q_line.*") ,nil ) //TEST
dbcreate(cTempDir+"q_line.dbf",aDlinestruct,NIL)//test
IIF(FILE(cTempDir + oRep:cPrepDbf+".cdx"),FERASE(cTempDir + oRep:cPrepDbf+".cdx") ,nil )
IIF(FILE(cTempDir + oRep:cRepDbf+".cdx"),FERASE(cTempDir + oRep:cRepDbf+".cdx") ,nil )
aFamiles := PrepareGenDb(oRep,aMyFamily)
NetUse( oRep:cPrepDbf,5, NIL, USE_EXCLUSIVE, USE_NEW, cTempDir,"d_ord" )
@ 8,11 say "Preparing tempery files : Order files index"
CheckIndex("ipolnoid",cTempDir + oRep:cPrepDbf,"str(poln_id,9,2)",.T.)
CheckIndex(oRep:cPrepDbf+"_1",cTempDir + oRep:cPrepDbf,"ptype_id+pline_id+size_id+str(value_id,9,3)+Sched_Group_Seq+DTOS(SchOrdDue(.t.,'d_ord'))",.T.)
CheckIndex(oRep:cPrepDbf+"_2",cTempDir + oRep:cPrepDbf,"ptype_id+pline_id+size_id+Sched_Group_Seq+DTOS(SchOrdDue(.t.,'d_ord'))",.T.)
@ 9,11 say "Preparing tempery files : Stock files index"
//MYRUN("G:\SOURCE\test.exe")
DbSelectArea("d_stock")
ordsetfocus(1)
d_stock->(dbsetindex(GetUserInfo():cTempDir + "d_stocktmp.cdx"))
//4.1.3 in Sched Spec
DispBox( 7, 10 , 10 ,63 , B_DOUBLE+" " )
dbselectarea("d_ord")
d_ord->(dbgotop())
COPY TO (cTempDir+"zu_ord.dbf")                  //for elitzoor
ordsetfocus(oRep:cPrepDbf+"_1")
COPY TO (cTempDir+"zn_ord.dbf")                  //for elitzoor
d_ord->(dbclearindex())
d_ord->(dbgotop())
IIF(d_ord->ptype_id == "U" ,d_ord->(ordsetfocus("t_ord_2")) ,d_ord->(ordsetfocus("t_ord_1")) )
d_ord->(dbgotop())
cFamily := ptype_id+pline_id+size_id
cValue := str(value_id,9,3)
nSum := d_ord->(lastrec())
While !d_ord->(EOF())
   @ 12,11 say "TYPE  LINE  SIZE  VALUE          P/O"
   @ 13,11 say " " + ptype_id + "     " + pline_id + "  " + size_id + str(value_id,9,3)
   DelProm(cFamily) //erase  all old promises 4.2.2/3/4 in Sched Spec
   nSubCount := 0
   nSubSum   := 0
   nRecNo    := RecNo()

   lPreAvail := .T.
   lPreAvail := PreAvail(cFamily) //4.2.5/6 in Sched Spec
   DispBox( 15, 10 , 22 ,63 , B_DOUBLE+" ")
   While IIF(d_ord->ptype_id == "U",cFamily == ptype_id+pline_id+size_id ,cFamily + cValue == ptype_id+pline_id+size_id+str(value_id,9,3 ) )
         nSubSum++   //countinf how many records in every family
         d_ord->(DBSKIP(1))
   End

   IIF( lPreAvail,d_ord->(dbgoto(nRecNo)) ,nil )
   WHILE lPreAvail .AND. IIF(d_ord->ptype_id == "U",cFamily == ptype_id+pline_id+size_id ,cFamily + cValue == ptype_id+pline_id+size_id+str(value_id,9,3 ) )
        @ 8,11 say "Order No. " + Str(++nCount) + " from " + str(nSum) + "( " + ALLTRIM(str((nCount / nSum) * 100 )) + " %"+ " )"
        @ 13,40 say   str(d_ord->Poln_id,9,2) COLOR "gr"
        @ 13,50 SAY  padr(LTRIM(Str(++nSubCount)),3) + " From " + padr(LTRIM(Str(nSubSum)),3)
        //general 4.3.1 in Sched. Spec.

		  //IIF(d_ord->esny_id $ "_4_7_H_C_D_B_" .OR. d_ord->poln_type == "8",nil ,DoNipuk(ptype_id+pline_id+size_id,GetHie_2(tol_id,volt_id,tc_id),"WHA") )  //now do nipukim

		  IIF( (StillPending()) <> 0 .AND. !d_ord->ptype_id $ "_K_M_S_" .AND. !d_ord->esny_id $ "_4_7_Z_H_C_D_B_" ,Linking(cFamily,"After packing") ,nil )       //linking before packing process

		  //IIF(d_ord->esny_id $ "_4_7_Z_H_C_D_B_" .OR. d_ord->poln_type == "8",nil ,DoNipuk(ptype_id+pline_id+size_id,GetHie_2(tol_id,volt_id,tc_id),"WH6") )  //now do nipukim

		  //IF d_ord->sarea_id <> "4"
		     cRoute := GetRoute(d_ord->esn_id,.T.,.T.)//Czheh
           IF (!d_ord->ptype_id $ "_K_M_S_" .AND. !d_ord->esny_id $ "B_3_4_7_H_C_Z_D_" .AND. !Empty(cRoute[1]) .AND. !(d_ord->pline_id == "AP3" .AND. d_ord->size_id == "0402" .AND. d_ord->tol_id $ "BPQZ"))
               /*While StillPending() > 0  //test for pending > 0
 		               IF !Packing(ptype_id+pline_id+size_id,StillPending(),"CZ") //packing batch process
 			               EXIT
  	                  ENDIF
               End*/
           ELSEIF !d_ord->ptype_id $ "_K_M_S_" .AND. !d_ord->esny_id $ "B_3_4_7_H_Z_C_D_" .AND. Empty(cRoute[1])
               IF Empty(hUpd_route)
                  hUpd_route := fcreate(GetUserInfo():cTempDir + "routprob.txt")
                  fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
                  fwrite(hUpd_route,EOL)
                  fwrite(hUpd_route,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
                  fwrite(hUpd_route,EOL)
                  fwrite(hUpd_route,"|     Scheduling module's results : Esn's with non defined routes       |")
                  fwrite(hUpd_route,EOL)
                  fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
                  fwrite(hUpd_route,EOL)
 	            ENDIF
               fwrite(hUpd_route,"| " + PADR(str(d_ord->Poln_id,9,2) + "  " + d_ord->esn_id + "  " + cRoute[2],69) + " |")
               fwrite(hUpd_route,EOL)
           ENDIF
		  //ENDIF
		  cRoute := GetRoute(d_ord->esn_id,.T.,.F.)//Israel
        IF (!d_ord->ptype_id $ "_K_M_S_" .AND. !d_ord->esny_id $ "B_3_4_7_H_C_D_Z_" .AND. !Empty(cRoute[1]) .AND. !(d_ord->pline_id == "AP3" .AND. d_ord->size_id == "0402" .AND. d_ord->tol_id $ "BPQZ"))
             /*While StillPending() > 0  //test for pending > 0
 		       //    IF !Packing(ptype_id+pline_id+size_id,StillPending(),"IL") //packing batch process
 			    //       EXIT
  	          //    ENDIF
             End*/
        ELSEIF !d_ord->ptype_id $ "_K_M_S_" .AND. !d_ord->esny_id $ "B_3_4_7_H_C_Z_D_" .AND. Empty(cRoute[1])
             IF Empty(hUpd_route)
                hUpd_route := fcreate(GetUserInfo():cTempDir + "routprob.txt")
                  fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
                  fwrite(hUpd_route,EOL)
                  fwrite(hUpd_route,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
                  fwrite(hUpd_route,EOL)
                  fwrite(hUpd_route,"|     Scheduling module's results : Esn's with non defined routes       |")
                  fwrite(hUpd_route,EOL)
                  fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
                  fwrite(hUpd_route,EOL)
 	          ENDIF
             fwrite(hUpd_route,"| " + PADR(str(d_ord->Poln_id,9,2) + "  " + d_ord->esn_id + "  " + cRoute[2],69) + " |")
             fwrite(hUpd_route,EOL)
        ENDIF

        IIF( (StillPending()) <> 0 .AND. !d_ord->ptype_id $ "_K_M_S_" .AND. !d_ord->esny_id $ "_B_3_",Linking(cFamily,"Before packing") ,nil )//linking after packing process
        While StillPending() > 0  .AND. !d_ord->ptype_id $ "_K_M_S_" .AND. !d_ord->esny_id $ "_B_3_4_7_Z_H_C_D_"
              IF !OpenNewBatch(cFamily)//opening new batch's 4.3.5 in Sched Spec
                 EXIT
              ENDIF
        End    ///////here elitzoor
        DispBox( 15, 10 , 22 ,63 , B_DOUBLE+" ")
        IIF(d_ord->ptype_id == "U" ,d_ord->(ordsetfocus("t_ord_2")) ,d_ord->(ordsetfocus("t_ord_1")) )

        d_ord->(DBSKIP(1))
   END
        UpdateDbfs(.F.) //4.3.7 in Sched.Spec.
        cFamily := ptype_id+pline_id+size_id
        cValue :=  str(value_id,9,3)
END
//new from vitaly 16.04.2001
@ 12,11 say "TYPE  LINE  SIZE  VALUE          BID"
@ 13,50 SAY "          "
@ 13,40 SAY "         "
DispBox( 7, 10 , 10 ,63 , B_DOUBLE+" " )
@ 16,11 say "Cancelling promises of batches with no orders"
nSubCount := 0
nCount    := 0
d_prom->(ordsetfocus("iprombn"))
IF Select("q_line") == 0
   NetUse( "q_line",5, NIL, USE_EXCLUSIVE, USE_NEW,GetUserInfo():cTempDir )
ELSE
   dbselectarea("q_line")
ENDIF
ZAP
Set Relation to
dbselectarea("d_line")
d_line->(ordsetfocus("ilnesnp"))
dbgotop()
While !d_line->(eof())
      IF  IIF(!Empty(GetBuffer("Product type")),d_line->ptype_id $ GetBuffer("Product type") ,.T. ) .AND. ;
          IIF(!Empty(GetBuffer("Product line")),d_line->pline_id $ GetBuffer("Product line") ,.T. ) .AND. ;
          IIF(!Empty(GetBuffer("Size")),d_line->size_id $ GetBuffer("Size") ,.T. )                  .AND. ;
          IIF(!Empty(GetBuffer("Value")),str(d_line->value_id,9,3) $ GetBuffer("Value") ,.T. )      .AND. ;
          d_line->b_purp $ GetBuffer("Purpose")          .AND. ;
          d_line->b_stat $ GetBuffer("Status")           .AND. ;
          IIF(d_line->ptype_id == "U",aScan(aFamiles,d_line->ptype_id + d_line->pline_id + d_line->size_id) == 0 ,aScan(aFamiles,d_line->ptype_id + d_line->pline_id + d_line->size_id + str(d_line->value_id,9,3)) == 0 )
              IF !FrzLn(d_line->b_id) .AND. Check_EStat()
                 q_line->(dbappend())
                 @ 13,50 SAY  padr(LTRIM(Str(++nSubCount)),3) + " founded"
                 FOR i := 1 TO d_line->( FCOUNT() )
                     q_line->( FIELDPUT( i, d_line->( FIELDGET(i) ) ) )
                 NEXT
                 q_line->(dbcommit())
              ENDIF
              d_prom->(dbseek(d_line->b_id))
              IF d_prom->(Found())
                 While d_prom->b_id == d_line->b_id
                       if d_prom->(RecLock( 5, "SCHED" ) )
                          d_prom->(DbDelete())
                          d_prom->(DbUnlock())
                       endif
                       d_prom->(dbskip(1))
                 End
              ENDIF
      ENDIF
      @ 8,11 say  "( " + ALLTRIM(str((++nCount / d_line->(Lastrec())) * 100 )) + " %"+ " )"
      @ 13,11 say " " + d_line->ptype_id + "     " + d_line->pline_id + "  " + d_line->size_id + str(d_line->value_id,9,3)
      @ 13,40 say d_line->b_id COLOR "gr"
      d_line->(dbskip(1))
End
DispBox( 7, 10 , 10 ,63 , B_DOUBLE+" " )
@ 9,25 say padr(LTRIM(Str(++nSubCount)),3) + " records to update..." COLOR "gr+"
d_line->(ordsetfocus("ib_idln"))
dbselectarea("q_line")
Set Relation to b_id into d_line
UpdateDbfs(.T.)
dbselectarea("q_line")
Set Relation to
////////////////////////////
oForm:hide()
dbselectarea("d_ord")
d_ord->(dbclearindex())
FERASE(cTempDir+"T_ord.cdx")
d_ord->(dbgotop())
While !d_ord->(EOF())//deleting records with pending > 0 from t_ord for general report
      IF  (StillPending()) <= 0
              d_ord->(RecLock(5,"SCHED"))
              d_ord->(DBDELETE())
              d_ord->(dbunlock())
      ENDIF
      dbskip(1)
End
PACK
MakeRpqc01v1()
GenClosefiles({"d_line","d_stock","c_potype","C_TOL","D_AVAIL","c_esny","m_linemv","d_esn","c_btype","M_STKMV","D_PACK","c_proc","c_expqty","C_CURR","C_EXRATE","d_edsgn","c_hierar","d_pcaud","m_bstamv","d_irrfin","d_finqc","c_pline","c_leadt","c_bstat","c_bpurp","c_volt","c_sbstxx"})
d_ord->(dbclosearea())
t_prom->(dbclosearea())
t_pack->(dbclosearea())
t_pcksav->(dbclosearea())
IIF(Select("q_line") > 0 , q_line->(dbclosearea()) , nil )
FERASE(cTempDir+"T_ord.cdx")
fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
fwrite(hUpd_route,EOL)
fclose(hUpd_route)
fwrite(hUpd_qty,"+-----------------------------------------------------------------------+")
fwrite(hUpd_qty,EOL)
fclose(hUpd_qty)
Return nil
//////////////////////////////////////////////
//////////////////////////////////////////////
Static Function PreAvail(cFamily)   //4.2.5/6 in Sched Spec .preparing production batch & qty for link
Local nOldArea := Select()
Local lRetVal := .T.
local nLastRec
Local cMessage,aTols,i,aTempTols,cBSeqNo
Field b_id,b_purp,b_stat
Field ptype_id,pline_id,size_id,value_id
NetUse( "t_avail",5, NIL, USE_EXCLUSIVE, USE_NEW,GetUserInfo():cTempDir )
ZAP
IF Select("q_line") <> 0
  dbselectarea("q_line")
  dbclearindex()
  ZAP
ELSE
  NetUse( "q_line",5, NIL, USE_EXCLUSIVE, USE_NEW,GetUserInfo():cTempDir )
  dbclearindex()
  ZAP
ENDIF
ferase(GetUserInfo():cTempDir + "q_line.cdx")
dbselectarea("d_line")
ordsetfocus("isched")
d_line->(dbseek(IIF(d_ord->ptype_id == "U",cFamily,cFamily + str(d_ord->value_id,9,3))))
@ 17,11 say "Preparing tempory file - Batches to Promise"
IF d_line->(found())
	While IIF(d_ord->ptype_id == 'U',ptype_id+pline_id+size_id == cFamily,ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily + str(d_ord->value_id,9,3)  )
			IF GetRec({17,55}) .AND. d_line->b_purp $ GetBuffer("Purpose") .AND. d_line->b_stat $ GetBuffer("Status") .AND. !FrzLn(d_line->b_id) .AND. Check_EStat()
				q_line->(dbappend())
				FOR i := 1 TO d_line->( FCOUNT() )
					 q_line->( FIELDPUT( i, d_line->( FIELDGET(i) ) ) )
				NEXT
				q_line->ExpFinDate := batchCalc3('q_line')
				q_line->(dbcommit())
			ENDIF
			d_line->(dbskip(1))
	End
ENDIF
d_line->(ordsetfocus("ib_idln"))
dbselectarea("q_line")
Set Relation to b_id into d_line
CheckIndex("viva",GetUserInfo():cTempDir + "q_line","DTOS(ExpFinDate) + Getseqbstat(b_stat)+Getseqpurp(b_purp) + cp_pccode+ b_id",.T.)
COPY TO (GetUserInfo():cTempDir+"z_line.dbf")
DbGoTop()
@ 17,55  SAY "        "
@ 18,11 say "Refreshing Available Quantites to promise  "
aTempTols := TestAvail()//test c_expqty for double and error records
While !EOF()
     aTols := {}
     IF d_line->b_purp $ "_8_5_" .AND. !Empty(d_line->tol_id)
          c_tol->(dbseek(d_line->ptype_id + d_line->tol_id))
          cBSeqNo := c_tol->seq_no
          FOR i := 1 TO Len(aTempTols[1])
              IF Val(cBSeqNo) <= Val(aTempTols[2][i])
                 AADD(aTols,aTempTols[1][i])
              ENDIF
          NEXT
       ELSE
          aTols := aTempTols[1]
     ENDIF
	cMessage := MakeAvail(aTols,aTempTols)//fill t_avail for every batch in q_line
	if !Empty(cMessage)
		lRetVal := .F.
		EXIT
	EndIf
	@ 18,53 Say q_line->b_id
	dbskip(1)
End
MakeAv_2(cFamily) //fill field net_qty in t_avail
@ 18,53  SAY "         "
nLastRec := t_avail->(lastrec())
t_avail->(dbclosearea())
Dbselectarea(nOldArea)
IF !lRetVal .AND.  "No records" $ cMessage//put error messages about t_avail into txt file
     IF Empty(hUpd_qty)
          hUpd_qty := fcreate(GetUserInfo():cTempDir + "qtyprob.txt")
          fwrite(hUpd_qty,"+-----------------------------------------------------------------------+")
          fwrite(hUpd_qty,EOL)
          fwrite(hUpd_qty,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
          fwrite(hUpd_qty,EOL)
          fwrite(hUpd_qty,"|     Scheduling module's results : Esn's with non defined routes       |")
          fwrite(hUpd_qty,EOL)
          fwrite(hUpd_qty,"+-----------------------------------------------------------------------+")
          fwrite(hUpd_qty,EOL)
 	ENDIF
     fwrite(hUpd_qty,"| " + PADR(ptype_id + "  " + pline_id + "  " + size_id +  "  " + str(value_id,9,3) + " Exp. Qty can't be calculated ",69) + " |")
     fwrite(hUpd_qty,EOL)
ELSEIF !lRetVal .AND.  "Double" $ cMessage
     IF Empty(hUpd_qty)
          hUpd_qty := fcreate(GetUserInfo():cTempDir + "qtyprob.txt")
          fwrite(hUpd_qty,"+-----------------------------------------------------------------------+")
          fwrite(hUpd_qty,EOL)
          fwrite(hUpd_qty,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
          fwrite(hUpd_qty,EOL)
          fwrite(hUpd_qty,"|     Scheduling module's results : Esn's with non defined routes       |")
          fwrite(hUpd_qty,EOL)
          fwrite(hUpd_qty,"+-----------------------------------------------------------------------+")
          fwrite(hUpd_qty,EOL)
 	ENDIF
     fwrite(hUpd_qty,"| " + PADR(cMessage,69) + " |")
     fwrite(hUpd_qty,EOL)
ENDIF

Return lRetVal .OR. nLastrec > 0
/////////////////////////////////////////////////
Static Function Check_EStat()

local lRetVal := TRUE
IF d_line->b_stat $ "E_R"
	M_BSTAMV->(dbseek(d_line->b_id))
	While M_BSTAMV->b_id == d_line->b_id .AND. !M_BSTAMV->(eof())
			IF M_BSTAMV->NB_STAT == d_line->b_stat .AND. Date() - M_BSTAMV->dlu_rec > 7
				lRetVal := FALSE
			ENDIF
			M_BSTAMV->(dbskip(1))
	End
ENDIF
IF lRetval .AND. d_line->cpproc_id == "995.0"
	lRetVal := FALSE
ENDIF

Return lRetVal

STATIC PROCEDURE DelProm(cBituy)  //deleting record's from d_prom & d_avail for our family 4.2.2/3/4 in Sched Spec

LOCAL nOldArea := SELECT()
LOCAL cTempDir := GetUserInfo():cTempDir
LOCAL nRec := d_ord->(recNo())
LOCAL cOrd := d_ord->(ordsetfocus("IPOLNOID"))
FIELD ptype_id,pline_id,size_id,value_id,b_id

@ 16,11 say "Canceling current promises                 "
dbselectarea("d_line")
ordsetfocus("isched")
d_prom->(ordsetfocus("iprombn"))
d_line->(dbseek(IIF(d_ord->ptype_id == "U",cBituy,cBituy + str(d_ord->value_id,9,3))))
WHILE !EOF() .AND. IIF(d_ord->ptype_id == "U",d_line->ptype_id+d_line->pline_id+d_line->size_id == cBituy ,d_line->ptype_id+d_line->pline_id+d_line->size_id+str(d_line->value_id,9,3) == cBituy + str(d_ord->value_id,9,3))
     //IIF(d_prom->(dbseek(d_line->b_id)),d_ord->(dbseek(d_prom->poln_id,9,2)),nil )

     //IF (d_prom->(Found()) .AND. d_ord->(Found()) .AND. d_ord->poln_type <> "4") .OR. ;
	  //	  (d_prom->(Found()) .AND. !d_ord->(Found()))
	       d_prom->(dbseek(d_line->b_id))
          While d_prom->b_id == d_line->b_id
					IF !(d_ord->(dbseek(STR(d_prom->poln_id,9,2))) .AND. d_ord->poln_type == "4")
					if d_prom->(RecLock( 5, "SCHED" ) )
                  d_prom->(DbDelete())
                  d_prom->(DbUnlock())
               endif
					ENDIF
               d_prom->(dbskip(1))
          End
     //ENDIF
	  d_ord->(dbgoto(nRec))
     @ 16,52 Say d_line->b_id
     d_line->(dbskip(1))
END

d_ord->(ordsetfocus(cOrd))
d_prom->(ordsetfocus("IPROMPLN"))
d_ord->(dbseek(IIF(d_ord->ptype_id == "U",cBituy,cBituy + str(d_ord->value_id,9,3))))
While !EOF() .AND. IIF(d_ord->ptype_id == "U",d_ord->ptype_id+d_ord->pline_id+d_ord->size_id == cBituy ,d_ord->ptype_id+d_ord->pline_id+d_ord->size_id+str(d_ord->value_id,9,3) == cBituy + str(d_ord->value_id,9,3))
		d_prom->(dbseek(str(d_ord->poln_id,9,2)))
		While d_prom->poln_id == d_ord->poln_id .AND. d_ord->poln_type <> "4"
				if d_prom->(RecLock( 5, "SCHED" ) )
				   d_prom->(DbDelete())
				   d_prom->(DbUnlock())
				endif
				d_prom->(dbskip(1))
		End
		d_ord->(dbskip(1))
End
d_ord->(dbgoto(nRec))

DbSelectArea("d_avail")
ordsetfocus("family")
d_avail->(dbseek(IIF(d_ord->ptype_id == "U",cBituy,cBituy + str(d_ord->value_id,9,3))))
WHILE !EOF() .AND. IIF(d_ord->ptype_id == "U",d_avail->ptype_id+d_avail->pline_id+d_avail->size_id == cBituy ,d_avail->ptype_id+d_avail->pline_id+d_avail->size_id+str(d_avail->value_id,9,3) == cBituy + str(d_ord->value_id,9,3))
     d_avail->(RecLock( 5, "SCHED" ))
     d_avail->(DbDelete())
     d_avail->(DbUnlock())
     d_avail->(Dbskip(1))
END

NetUse("d_ordreq",5)//DbSelectArea("d_ordreq") //31/10/2000/erase "W" 's in d_ordreq
ordsetfocus("ipolnwit")
dbgotop()
WHILE !EOF()
	IF d_ord->ptype_id == "U"
		IF (d_ordreq->ptype_id+d_ordreq->pline_id+d_ordreq->size_id == cBituy)
               d_ordreq->(RecLock( 5, "SCHED" ))
               d_ordreq->poln_stat := "H"
			d_ordreq->(dbunlock())
		ENDIF
	ELSE
		IF (d_ordreq->ptype_id+d_ordreq->pline_id+d_ordreq->size_id+str(d_ordreq->value_id,9,3) == cBituy + str(d_ord->value_id,9,3))
               d_ordreq->(RecLock( 5, "SCHED" ))
               d_ordreq->poln_stat := "H"
			d_ordreq->(dbunlock())
		ENDIF
	ENDIF
	dbskip(1)
END
d_ordreq->(dbclosearea())
DbSelectArea(nOldArea)
@ 16,52 Say "       "
d_ord->(ordsetfocus(cOrd))
d_ord->(dbgoto(nRec))
RETURN
///////////////////////////////
static function  DoNipuk(cFamily,cLevel,cMode) //nipuk's module   4.3.2 in Sched.Spec.
Local nOldArea := Select()
Local nPromQty := 0
Local lRetVal  := .F.
Field value_id,ptype_id,pline_id,size_id,tol_id,volt_id,tc_id

IF cMode == "WHA"//ALL WH'S
   /////////////Czech Location
   IF d_ord->sarea_id <> "4"//NOT ISRAEL ORDER
      DbSelectArea("d_stock")
      IF(FILE(GetUserInfo():cTempDir + "d_stocktmp.cdx"))
        d_stock->(dbsetindex(GetUserInfo():cTempDir + "d_stocktmp"))
	     if d_ord->ptype_id == "U"
	        d_stock->(ordsetfocus("U_viva_CZ"))
	     else
	        d_stock->(ordsetfocus("viva_CZ"))
	     endif
      ENDIF
      IIF( d_ord->ptype_id == "U",d_stock->(dbseek(cFamily)) ,d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)))  )
      @ 16,11 say "Allocating:Czech Location "
      WHILE  !EOF() .AND. IIF(d_ord->ptype_id == "U" ,;
		                     ptype_id+pline_id+size_id == cFamily ,;
			   					ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily+str(d_ord->value_id,9,3) ) //.AND. !lRetVal

			    if d_ord->ptype_id == "U"
				    d_stock->(ordsetfocus("U_viva_CZ"))
			    else
				    d_stock->(ordsetfocus("viva_CZ"))
			    endif

			    IF !OneAlloc(nil,cLevel)
                exit
             Endif

			    d_stock->(dbskip(1))
             @ 16,52 SAY d_stock->b_id
      END
      IIF(t_prom->( LASTREC() ) <> 0,lRetVal := UpDateNipuk() ,Nil ) //commiting allcation.updateting of all involved files
   ENDIF//NOT ISRAEL ORDER
   /////////////Israel Location
   t_prom->( __DBZAP() )
   DbSelectArea("d_stock")
   d_stock->(dbsetindex(GetUserInfo():cTempDir + "d_stocktmp"))
   if d_ord->ptype_id == "U"
      d_stock->(ordsetfocus("U_viva_IL"))
   else
      d_stock->(ordsetfocus("viva_IL"))
   endif
   IIF( d_ord->ptype_id == "U",d_stock->(dbseek(cFamily)) ,d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)))  )
   @ 16,11 say "Allocating:Israel Location"
   WHILE  !EOF() .AND. IIF(d_ord->ptype_id == "U" ,;
	   	                  ptype_id+pline_id+size_id == cFamily ,;
		   						ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily+str(d_ord->value_id,9,3) ) //.AND. !lRetVal

	     if d_ord->ptype_id == "U"
	        d_stock->(ordsetfocus("U_viva_IL"))
	     else
	        d_stock->(ordsetfocus("viva_IL"))
	     endif

	     IF !OneAlloc(nil,cLevel)
           exit
        Endif
        d_stock->(dbskip(1))
        @ 16,52 SAY d_stock->b_id
   END
   IIF(t_prom->( LASTREC() ) <> 0,lRetVal := UpDateNipuk() ,Nil ) //commiting allcation.updateting of all involved files
   /////////////2C Location
   /*IF d_ord->sarea_id <> "4"//NOT ISRAEL ORDER
		t_prom->( __DBZAP() )
      DbSelectArea("d_stock")
      IF(FILE(GetUserInfo():cTempDir + "d_stocktmp.cdx"))
        d_stock->(dbsetindex(GetUserInfo():cTempDir + "d_stocktmp"))
	     if d_ord->ptype_id == "U"
	        d_stock->(ordsetfocus("U_viva_2C"))
	     else
	        d_stock->(ordsetfocus("viva_2C"))
	     endif
      ENDIF
      IIF( d_ord->ptype_id == "U",d_stock->(dbseek(cFamily)) ,d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)))  )
      @ 16,11 say "Allocating:2C Location "
      WHILE  !EOF() .AND. IIF(d_ord->ptype_id == "U" ,;
		                     ptype_id+pline_id+size_id == cFamily ,;
			   					ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily+str(d_ord->value_id,9,3) ) //.AND. !lRetVal

			    if d_ord->ptype_id == "U"
				    d_stock->(ordsetfocus("U_viva_2C"))
			    else
				    d_stock->(ordsetfocus("viva_2C"))
			    endif

			    IF !OneAlloc(nil,cLevel)
                exit
             Endif

			    d_stock->(dbskip(1))
             @ 16,52 SAY d_stock->b_id
      END
      IIF(t_prom->( LASTREC() ) <> 0,lRetVal := UpDateNipuk() ,Nil ) //commiting allcation.updateting of all involved files
   ENDIF//NOT ISRAEL ORDER
   /////////////2I Location
   t_prom->( __DBZAP() )
   DbSelectArea("d_stock")
   d_stock->(dbsetindex(GetUserInfo():cTempDir + "d_stocktmp"))
   if d_ord->ptype_id == "U"
      d_stock->(ordsetfocus("U_viva_2I"))
   else
      d_stock->(ordsetfocus("viva_2I"))
   endif
   IIF( d_ord->ptype_id == "U",d_stock->(dbseek(cFamily)) ,d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)))  )
   @ 16,11 say "Allocating:Israel Location"
   WHILE  !EOF() .AND. IIF(d_ord->ptype_id == "U" ,;
	   	                  ptype_id+pline_id+size_id == cFamily ,;
		   						ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily+str(d_ord->value_id,9,3) ) //.AND. !lRetVal

	     if d_ord->ptype_id == "U"
	        d_stock->(ordsetfocus("U_viva_2I"))
	     else
	        d_stock->(ordsetfocus("viva_2I"))
	     endif

	     IF !OneAlloc(nil,cLevel)
           exit
        Endif
        d_stock->(dbskip(1))
        @ 16,52 SAY d_stock->b_id
   END
   IIF(t_prom->( LASTREC() ) <> 0,lRetVal := UpDateNipuk() ,Nil ) //commiting allcation.updateting of all involved files
	*/
ELSE//Nipuk for 06//ALL WH'S
   t_prom->( __DBZAP() )
   DbSelectArea("d_stock")
   d_stock->(dbsetindex(GetUserInfo():cTempDir + "d_stocktmp"))
   if d_ord->ptype_id == "U"
      d_stock->(ordsetfocus("U_viva_06"))
   else
      d_stock->(ordsetfocus("viva_06"))
   endif
   IIF( d_ord->ptype_id == "U",d_stock->(dbseek(cFamily)) ,d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)))  )
   @ 16,11 say "Allocating:Israel Location"
   WHILE  !EOF() .AND. IIF(d_ord->ptype_id == "U" ,;
	   	                  ptype_id+pline_id+size_id == cFamily ,;
		   						ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily+str(d_ord->value_id,9,3) ) //.AND. !lRetVal

	     if d_ord->ptype_id == "U"
	        d_stock->(ordsetfocus("U_viva_06"))
	     else
	        d_stock->(ordsetfocus("viva_06"))
	     endif

	     IF !OneAlloc(nil,cLevel)
           exit
        Endif
        d_stock->(dbskip(1))
        @ 16,52 SAY d_stock->b_id
   END
   IIF(t_prom->( LASTREC() ) <> 0,lRetVal := UpDateNipuk() ,Nil ) //commiting allcation.updateting of all involved files
ENDIF//ALL WH'S
///////////////////////////
DbSelectarea(nOldArea)
Return nil
//////////////////////////////////////////////////////
static function  Pen(cDbf)
Return ( (cDbf)->qty_ord - (cDbf)->qty_shipd - (cDbf)->qty_canc - (cDbf)->qty_alloc)
/////////////////////////////////////////////////////
STATIC FUNCTION OneAlloc( cCode,cLevel )  //Searching for suitible batches for nipuk wh 3,4 /4.3.2.1 in Sched.Spec.
LOCAL nOldArea := Select()
LOCAL nCursor , nLimit
LOCAL nAvailQty := 0 , cTapiComment := Space( 60 )
LOCAL nPending , nQty := 0
LOCAL cStk := "d_stock"
LOCAL cChosenDbf := "d_stock"
LOCAL cOrd := "d_ord"
LOCAL cOrderDbf :=  "d_ord"
LOCAL aInfostk := GetIncrements(cStk)
LOCAL aInfoord := GetIncrements(cOrd)
local oProfile := StkValSub():new()
local cOrderEsn := d_ord->esn_id
local cChosenEsn := d_stock->esn_id
LOCAL lRetVal := .T.
LOCAL nHierrar
local aValues := GetDTValues((cChosenDbf)->pline_id+(cChosenDbf)->size_id,cChosenDbf)
LOCAL lDT     := IfInDTRange(aValues,(cOrderDbf )->value_id)

lTestDbf := .F.
lTestFirst := .F.
lTestWhs := .F.
lSubstitutable := .F.

IF !lCont
     t_prom->( __DBZAP() )
     nLnAllocCounter := 1
     aTempWHs  := { {},{},{},{},{},{} }
     aTempQtys := { {},{},{},{},{},{} }
ENDIF
nHierrar := val(GetHie_2(d_stock->tol_id,d_stock->volt_id,d_stock->tc_id))
/////////////////wh's////////////////////////
IF (nHierrar <= val(cLevel))
     IIF((d_stock->wh3-FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id+(cChosenDbf)->LOC) > 0 .OR. ;
	  	   d_stock->wh4-FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id+(cChosenDbf)->LOC) > 0 .OR.  ;
			d_stock->wh6-FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id+(cChosenDbf)->LOC) > 0) .AND.;
			(cChosenDbf)->LOC $ "IL_CZ",lTestwhs := .T.,lTestwhs := .F. )
ENDIF
////////////////////////////////////////MATRIX
IF  lTestwhs
     IF (cOrderDbf )->PTYPE_ID $ "_C_L"
          lSubstitutable := oProfile:GoodSubst(cOrderEsn,nil,cChosenEsn,NIL,.F.,.F.)
     else
          lSubstitutable := .T.
     ENDIF
     /////////////////////////////////////////////////FIRST TEST
     if  ((cChosenDbf)->ptype_id+(cChosenDbf)->pline_id+(cChosenDbf)->size_id+STR((cChosenDbf)->value_id,9,3)+(cChosenDbf)->esny_id == ;
          (cOrderDbf )->ptype_id+(cOrderDbf )->pline_id+(cOrderDbf )->size_id+STR((cOrderDbf )->value_id,9,3)+(cOrderDbf)->esny_id) .OR. ;
			((cChosenDbf)->ptype_id+(cChosenDbf)->pline_id+(cChosenDbf)->size_id + (cChosenDbf)->esny_id == (cOrderDbf )->ptype_id+(cOrderDbf )->pline_id+(cOrderDbf )->size_id + (cOrderDbf)->esny_id  .AND. ;
			 (cOrderDbf)->ptype_id == "U" .AND. !"DB" $ (cOrderDbf)->pline_id .AND. lDT .AND. ;
          (((cChosenDbf)->value_id >= (cOrderDbf )->value_id * 0.90 .AND. (cChosenDbf)->value_id <= (cOrderDbf )->value_id * 1.10) .OR. (cChosenDbf)->value_id == 0.00 ) )
			lTestFirst := .T.
     endif
     ///////////////////////////////////////////////////ESNXX TABLE
     IF (cOrderEsn <> cChosenEsn)
          IF ((cOrderDbf )->esnxx_id <> (cChosenDbf)->esnxx_id)
					//GenOpenFiles({"c_sbstxx"})
					IF (cOrderDbf )->ptype_id $ "_L_F_T_"
					    c_sbstxx->(ordsetfocus("IXX"))
					    c_sbstxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
					ELSEIF  (cOrderDbf )->ptype_id $ "_U_"
					    c_sbstxx->(ordsetfocus("INDXX"))
					    c_sbstxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->size_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
					ELSE
					    c_sbstxx->(ordsetfocus("INXX"))
					    c_sbstxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->pline_id+(cOrderDbf )->size_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
					ENDIF
					IIF(c_sbstxx->(found()),lTestDbf := .T.  ,lTestDbf := .F. )
          ELSE
               lTestDbf := .T.
          ENDIF
     ELSE
          lTestDbf := .T.
     ENDIF
ENDIF
/////////////////////////////////////////////////////////////////
nPending := StillPending()

IF lTestFirst .AND. ;
	(d_stock->esnxx_id $ "2F_3A" .OR. d_ord->esnxx_id $ "2F_3A") .AND. ;
	(d_stock->esnxx_id <> d_ord->esnxx_id)
	lTestFirst := !lTestFirst
ENDIF

IF  nPending > 0 .AND. lTestwhs .AND. lSubstitutable .AND. lTestDbf .AND. lTestFirst
     IF (cChosenDbf)->wh3 <> 0
          nLimit := nAvailQty := (cChosenDbf)->wh3
     ELSEIF (cChosenDbf)->wh4 <> 0
          nLimit := nAvailQty := (cChosenDbf)->wh4
     ELSE
          nLimit := nAvailQty := (cChosenDbf)->wh6
     ENDIF
	  //qty to alloc 4.3.2.2 in Sched.Spec.
     nQty := if( nPending >= nAvailQty - FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id+(cChosenDbf)->LOC) , nAvailQty - FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id+(cChosenDbf)->LOC),nPending )
     KeepPromise({nQty,nQty,MAX(d_ord->d_rqstdlv,date() + 3),cTapiComment},"nipuk")
     lCont := .T.
ELSEIF nPending == 0                             //.OR. !lGeneral
     lRetVal := .F.
     lCont := .F.
ENDIF
Dbselectarea(nOldArea)
RETURN  lRetVal
///////////////////////////////////////////
static function  FrzStkQty(cSeek)
//Local nOldArea := Select()
Local nRetVal := 0
//NetUse("d_frzstk",5)
//ordsetfocus(1)
d_frzstk->(dbseek(cSeek))
IF Found()
     nRetVal := d_frzstk->frz_qty
ENDIF
//d_frzstk->(DbCloseArea())
//DbSelectArea(nOldArea)
Return nRetVal
///////////////////////////////////////////
Static Procedure MakeFrzStk()
Local nOldArea := Select()
Field value_id,ptype_id,pline_id,size_id
NetUse("d_frzstk",5)
ordsetfocus(1)
FERASE(GetUserInfo():cTempDir + "T_frzstk.dbf")
XSoftCopy( ,GetUserInfo():cTempDir + "T_frzstk.dbf", ,{|| IIF(!EMPTY(GetBuffer("Product type")) ,ptype_id $ GetBuffer("Product type") , .T.) .AND. IIF(!EMPTY(GetBuffer("Product line")) ,pline_id $ GetBuffer("Product line") , .T.) .AND. IIF(!EMPTY(GetBuffer("Size")) ,size_id $ GetBuffer("Size") , .T.) .AND. IIF(!EMPTY(GetBuffer("Value")) ,str(value_id,9,3) $ GetBuffer("Value") , .T.)})
DbCloseArea("d_frzstk")
DbSelectArea(nOldArea)
Return
//////////////////////////////////////////
Static Procedure MakeFrzProd()

LOCAL i, lFlag := FALSE
LOCAL aStruct
LOCAL cTempDir := GetUserInfo():cTempDir
Local nOldArea := Select()
Field value_id,ptype_id,pline_id,size_id,b_id
IIF(SELECT("d_line") == 0,GenOpenFiles({"d_line"}) ,NIL )
d_line->(ordsetfocus("ib_idln"))
aStruct := D_LINE->(dbstruct())
IF SELECT("T_frprod") > 0; CLOSE T_frprod ; ENDIF
     ferase(cTempDir + "T_frprod.dbf")
     ferase(cTempDir + "T_frprod.cdx")
     DBCREATE( cTempDir + "T_frprod", aStruct, "DBFCDXAX" )
     IF SELECT("T_frprod") > 0; CLOSE T_frprod ; ENDIF
          NetUse( "T_frprod", STD_RETRY, NIL, USE_EXCLUSIVE, USE_NEW, cTempDir )
          T_frprod->( __DBZAP() )
          NetUse( "d_frzln", 5 )
          ordsetfocus(1)

          Set Relation  to  b_id into d_line
          //CheckIndex("d_frzlna", cTempDir+"d_frzlntmp","d_line->PTYPE_ID+d_line->PLINE_ID+d_line->SIZE_ID+STR(d_line->Value_ID,9,3)+d_line->B_ID",.T.)

          d_frzln->(dbgotop())
          WHILE !d_frzln->(EOF())
               IF !(d_frzln->(DELETED())) .AND. !(d_line->b_stat $ "C_D") .AND. ;
                         IIF(!EMPTY(GetBuffer("Product type")),d_line->ptype_id $ GetBuffer("Product type"),.T.) .AND. ;
                         IIF(!EMPTY(GetBuffer("Product line")),d_line->pline_id $ GetBuffer("Product line"),.T.) .AND. ;
                         IIF(!EMPTY(GetBuffer("Size")),d_line->size_id $ GetBuffer("Size"),.T.) .AND. ;
                         IIF(!EMPTY(GetBuffer("Value")), str(d_line->value_id,9,3) $ GetBuffer("Value"), .T. )
                    T_frprod->(dbappend())
                    FOR i := 1 TO T_frprod->( FCOUNT() )
                         T_frprod->( FIELDPUT( i, d_line->( FIELDGET(i) ) ) )
                    NEXT
               ENDIF

               d_frzln->(dbskip())
          END
SELECT T_frprod
T_frprod->(dbgotop())
T_frprod->(dbclosearea())
IIF(SELECT("D_LINE") > 0,D_LINE->(dbclosearea()) ,NIL )
d_frzln->(dbclearindex())
d_frzln->(DbCloseArea())
FERASE(cTempDir + "d_frzlntmp.cdx")
DbSelectArea(nOldArea)
Return
/////////////////////////////////////////////////////////////////////////
STATIC FUNCTION MakeData( cCode )
LOCAL cBN , cSource , cESN , cAvailQty
LOCAL oCol
LOCAL objTemp
cBN     := d_stock->b_id
cESN    := d_stock->esn_id
cAvailQty := "    " + IIF(d_stock->wh3 <> 0,str(d_stock->wh3),str(d_stock->wh4))+" (WH "+IIF(d_stock->wh3 <> 0,"3","4")+")"
cSource := "Stock"
RETURN { cBN , Str(d_ord->poln_id,9,2)  , cESN , d_ord->d_rqstdlv , cSource , cAvailQty }
///////////////////////
STATIC FUNCTION GetIncrements(sfile)
Local aRetVal
 c_esny->(ordsetfocus(1))
 c_esny->( DBSEEK( (sfile)->esny_id ) )
 aRetVal := IF( c_esny->lpflag == "P", {2,c_esny->esny_qty},{1, 1} )
 RETURN aRetVal
//////////////////////////////////////////////////////////////////
STATIC PROCEDURE UpdateTempQty( cWh , nQty )
LOCAL nWh := Val( SetWh( cWh ) )
LOCAL nPosition

IF Empty( aTempWhs[ nWh ] )
     nPosition := 0
ELSE
     nPosition := Ascan( aTempWhs[nWh] , {|Wh | Wh = d_stock->( RecNo() ) } )
ENDIF
IF nPosition > 0
     aTempQtys[nWh , nPosition] += nQty
ELSE
     Aadd( aTempWhs[nWh ] , d_stock->( RecNo() ) )
     Aadd( aTempQtys[nWh ] , nQty )
ENDIF
RETURN
////////////////////////////////
static function  UpDateNipuk()
Local nOldArea := Select()
LOCAL lStockOrder := (d_ord->poln_type = "8")
LOCAL nRecNo := d_ord->(RecNo())
LOCAL nOrdNo := d_ord->(ordsetfocus())
LOCAL nPoln_id := d_ord->poln_id
LOCAL nQty
LOCAL cSource := lower(alltrim(d_ord->sched_sour))
D_Stock->(DbClearIndex())
D_ORD->(DBCloseArea())
NetUse("d_ord",5)
NetUse("d_ordreq",5)
(cSource)->(ordsetfocus(iif(cSource == "d_ord","ipolnoid","ipoln_id")))
(cSource)->(dbseek(str(nPoln_id,9,2)))
PutLines_ord(,,cSource)
nQty := d_ord->qty_alloc
d_ord->(DBCloseArea())
d_ordreq->(DBCloseArea())
NetUse( "t_ord",5, NIL, USE_EXCLUSIVE, USE_NEW, GetUserInfo():cTempDir,"d_ord" )
dbsetindex("t_ord")
ordsetfocus(nOrdNo)
dbgoto(nRecNo)
IF d_ord->( RecLock( 5,"sched" ) )
     d_ord->qty_alloc := nQty
     d_ord->( DbUnLock() )
ENDIF
Dbselectarea(nOldArea)
t_prom->( __DBZAP() )
Return .T.
//////////////////////////////////////////////////////////
static function Linking(cFamily,Mode) //4.3.3 in Sched.Spec.
Local nOldArea := Select()
Local lRet
Local nRecNo_Z,nRecNo_T,dDate_Z,dDate_T
Field ptype_id,pline_id,size_id,value_id
NetUse( "t_avail",5, NIL, USE_EXCLUSIVE, USE_NEW,GetUserInfo():cTempDir )

DbSelectArea("q_line")
q_line->(ordsetfocus("viva"))
q_line->(DBGOTOP())

c_proc->(ordsetfocus("iproc_id"))
c_proc->(dbseek("160.0"))

nProcFilter := val(c_proc->pcprocno)

IIF( Mode == "After packing",q_line->(dbsetfilter({|| val(q_line->cp_pccode) >= GetnProc()})) ,nil )
lRet :=  .T.

IF q_line->ptype_id == "L" .AND. q_line->size_id == "0805"//VR 22.04.2002 TaskID: 2421579
   c_proc->(dbseek("491.0"))
ELSE
	c_proc->(dbseek("192.0"))
ENDIF

nProc := val(c_proc->pcprocno)

IF( Mode == "After packing")
   @ 17,11 say "Promising batches after packing stage"
ELSE
	@ 19,11 say "Promising batches before packing stage"
ENDIF

While !EOF() .AND. lRet //4.3.3.3.2 all while
          IF FirstTestQty() .AND. Zeut(nProc) .AND. IFInside() //4.3.3.1 in Sched.Spec.Testing of qty & substitution of batches in prod
			    IF( Mode == "After packing")
			        @ 17,52 Say d_line->b_id
			    ELSE
				     @ 19,52 Say d_line->b_id
			    ENDIF
			    lRet := PreLink()
          ELSEIF FirstTestQty() .AND. Tahlifi(nProc) .AND. IFInside()
			        nRecNo_T := RecNo()
					  dDate_T := MoveShabos(batchCalc3('d_line'))
                 While !EOF()
                       IF FirstTestQty() .AND. Zeut(nProc)  .AND. IFInside()
			                 dDate_Z := MoveShabos(batchCalc3('d_line'))
			                 nRecNo_Z := RecNo()
                          exit
                       ENDIF
			              dbskip(1)
					        IF( Mode == "After packing")
					            @ 17,52 Say d_line->b_id
					        ELSE
					 	         @ 19,52 Say d_line->b_id
					        ENDIF
			        End
                 IF nRecno_Z <> NIL .AND. (dDate_Z-dDate_T <= 3)
				        dbgoto(nRecNo_Z)
				        IF( Mode == "After packing")
				            @ 17,52 Say d_line->b_id
				        ELSE
					         @ 19,52 Say d_line->b_id
				        ENDIF
				        lRet := PreLink()
				        dbgoto(nRecNo_T)
				        dbskip(-1)
			        ELSEIF nRecno_Z == NIL .OR. (dDate_Z-dDate_T > 3)
								dbgoto(nRecNo_T)
				            IF( Mode == "After packing")
				                @ 17,52 Say d_line->b_id
				            ELSE
								    @ 19,52 Say d_line->b_id
							   ENDIF
				            lRet := PreLink()
		           ENDIF
		    ENDIF
          IF( Mode == "After packing")
         	  @ 17,52 Say d_line->b_id
          ELSE
         	  @ 19,52 Say d_line->b_id
          ENDIF
          //IIF(!BOF() ,dbskip(1) ,nil ) vr 17-06-03
			 dbskip(1)
          nRecNo_Z := nil
          nRecNo_T := nil
End
IF select("T_PROM")<>0
  T_PROM->(DBCLEARINDEX())
ENDIF
q_line->(dbclearfilter())
RealyPromise()//4.3.3.3 in Sched Spec.
DBSELECTAREA("t_avail")
DbCloseArea("t_avail")
DBSELECTAREA("t_prom")
ZAP
DbSelectArea(nOldArea)
lCont := .F.
Return Nil
//////////////////////////////////////////////////
STATIC FUNCTION NewDate()
Local dRetVal
Local nOldArea := Select()
dbselectarea("t_prom")
IIF( FILE("t_promt.cdx"),FERASE("t_promt.cdx") ,nil )
CheckIndex("date","t_promt","prom_date",.T.)
dbgobottom()
dRetVal := t_prom->prom_date
dbclearindex()
IIF( FILE("t_promt.cdx"),FERASE("t_promt.cdx") ,nil )
DbSelectArea(nOldArea)

Return dRetVal

Static Function MoveShabos(dDate)

IF Dow(dDate) == 1 .OR. Dow(dDate) == 6 .OR. Dow(dDate) == 7
	While Dow(dDate) <> 2
	      dDate := dDate + 1
	End
ELSEIF Dow(dDate) == 3 .OR. Dow(dDate) == 4
	While Dow(dDate) <> 5
	      dDate := dDate + 1
	End
ENDIF

Return dDate

//////////////////////////////////////////////////
static function  Zeut(nProc) //4.3.3.1.2 in Sched.Spec.
Local nOldArea := Select()
Local lRetVal := .F.
local aValues := GetDTValues(d_line->pline_id+d_line->size_id,"d_line")
LOCAL lDT     := IfInDTRange(aValues,d_ord->value_id)

IF VAL(d_line->cp_pccode) < nProc .AND. !d_ord->esny_id $ "_4_7_H_C_D_B_"
	IF  d_line->ptype_id+d_line->pline_id+d_line->size_id+str(d_line->value_id,9,3)+d_line->volt_id+d_line->tc_id == ;
		 d_ord->ptype_id+d_ord->pline_id+d_ord->size_id+str(d_ord->value_id,9,3)+d_ord->volt_id+d_ord->tc_id
		 lRetVal := .T.
	ELSEIF d_ord->ptype_id == "U" .AND. !"DB" $ d_ord->pline_id .AND. d_line->b_purp $ "_5_8_"  //Vitaly 31-07-02 ID:27311140
			 IF (;
			 	 ( d_line->ptype_id+d_line->pline_id+d_line->size_id == d_ord->ptype_id+d_ord->pline_id+d_ord->size_id ) .AND. ;
             ( d_line->value_id >= d_ord->value_id * 0.90 .AND. lDT .OR. (d_line->value_id == 0.00 .AND. lDT) );
				 )
             lRetVal := .T.
			 ENDIF
   ELSEIF d_ord->ptype_id == "U" .AND. !"DB" $ d_ord->pline_id  .AND. !d_line->b_purp $ "_5_8_"
			 IF (;
			    d_line->ptype_id+d_line->pline_id+d_line->size_id ==                                  ;
             d_ord->ptype_id+d_ord->pline_id+d_ord->size_id                               .AND. ;
             ( d_line->value_id >= d_ord->value_id * 0.90 .AND. lDT .OR. (d_line->value_id == 0.00 .AND. lDT) )   .AND. ;
				 Val(d_line->cp_pccode) > 6904                                                                     ;
				 )                                                                                                 .OR.  ;
				 (;
				 d_line->ptype_id+d_line->pline_id+d_line->size_id ==                                  ;
             d_ord->ptype_id+d_ord->pline_id+d_ord->size_id                               .AND. ;
				 Val(d_line->cp_pccode) <= 6904                                                                    ;
				 )
               lRetVal := .T.
			 ENDIF
	ENDIF
ELSEIF VAL(d_line->cp_pccode) >= nProc .OR. d_ord->esny_id $ "_4_7_H_C_D_B_"
	IF  d_line->ptype_id+d_line->pline_id+d_line->size_id+str(d_line->value_id,9,3)+d_line->volt_id+d_line->tc_id+d_line->esnxx_id+d_line->esny_id== ;
		 d_ord->ptype_id+d_ord->pline_id+d_ord->size_id+str(d_ord->value_id,9,3)+d_ord->volt_id+d_ord->tc_id+d_ord->esnxx_id+d_ord->esny_id
		 lRetVal := .T.
	ELSEIF d_ord->ptype_id == "U" .AND. !"DB" $ d_ord->pline_id  .AND. d_line->b_purp $ "_5_8_"  //Vitaly 31-07-02 ID:27311140
			 IF (;
			 	 ( d_line->ptype_id+d_line->pline_id+d_line->size_id + d_line->esnxx_id + d_line->esny_id== d_ord->ptype_id+d_ord->pline_id+d_ord->size_id + d_ord->esnxx_id + d_ord->esny_id) .AND. ;
             ( d_line->value_id >= d_ord->value_id * 0.90 .AND. lDT .OR. (d_line->value_id == 0.00 .AND. lDT) );
				 )
             lRetVal := .T.
			 ENDIF
   ELSEIF d_ord->ptype_id == "U" .AND. !"DB" $ d_ord->pline_id  .AND. !d_line->b_purp $ "_5_8_"
			 IF (;
			    d_line->ptype_id+d_line->pline_id+d_line->size_id + d_line->esnxx_id + d_line->esny_id==                                  ;
             d_ord->ptype_id+d_ord->pline_id+d_ord->size_id+ d_ord->esnxx_id + d_ord->esny_id                               .AND. ;
             ( d_line->value_id >= d_ord->value_id * 0.90 .AND. lDT .OR. (d_line->value_id == 0.00 .AND. lDT) )   .AND. ;
				 Val(d_line->cp_pccode) > 6904                                                                     ;
				 )                                                                                                 .OR.  ;
				 (;
				 d_line->ptype_id+d_line->pline_id+d_line->size_id + d_line->esnxx_id + d_line->esny_id==                                  ;
             d_ord->ptype_id+d_ord->pline_id+d_ord->size_id+ d_ord->esnxx_id + d_ord->esny_id                               .AND. ;
				 Val(d_line->cp_pccode) <= 6904                                                                    ;
				 )
               lRetVal := .T.
			 ENDIF
	ENDIF
ENDIF
//vr for tapi 07.10.2002
IF lRetVal .AND. ;
	((d_ord->esny_id $ "_H_" .AND. d_ord->ptype_id == "U") .OR. ;
    ("DB" $ d_ord->pline_id .AND. d_ord->ptype_id == "U"))
	lRetVal := (d_line->value_id == d_ord->value_id)
ENDIF

IF lRetVal .AND. (d_line->esnxx_id $ "2F_3A_2Y_2X_3X_4X_3J" .OR. d_ord->esnxx_id $ "2F_3A_2Y_2X_3X_4X_3J") .AND. (d_line->esnxx_id <> d_ord->esnxx_id)
   lRetVal := !lRetVal
ENDIF

/////////////////////////

DBSelectArea(nOldArea)
Return lRetVal
/////////////////////////////////////////////////
static function  Tahlifi(nProc) //4.3.3.1.2 in Sched.Spec.
Local nOldArea := Select()
Local lRetVal := .F.
Local cOrderDbf := "d_ord"
Local cChosenDbf := "d_line"
local oProfile := StkValSub():new()
Local cOrderEsn := "0805"+d_ord->volt_id +d_ord->tc_id + "0R1AAW000"   //using sust.function.Only tc & volt are
lOCAL cChosenEsn := "0805"+d_line->volt_id +d_line->tc_id +"0R1AAW000" //currently relevant
local aValues := GetDTValues((cChosenDbf)->pline_id+(cChosenDbf)->size_id,cChosenDbf)
LOCAL lDT     := IfInDTRange(aValues,(cOrderDbf )->value_id)
nProc := 6200

IF (cOrderDbf )->PTYPE_ID $ "_C"//4.3.3.1.2.1 in Sched Spec
  lRetVal := oProfile:GoodSubst(cOrderEsn,nil,cChosenEsn,NIL,.F.,.F.)
ELSE
  lRetVal := .T.
ENDIF
cOrderEsn := (cOrderDbf )->esn_id
cChosenEsn := (cChosenDbf)->esn_id
IF VAL(d_line->cp_pccode) >= nProc //XX test
	IF lRetVal
      IF (cOrderEsn <> cChosenEsn)
          IF ((cOrderDbf )->esnxx_id <> (cChosenDbf)->esnxx_id)
             //GenOpenFiles({"c_sbstxx"})
             IF (cOrderDbf )->ptype_id $ "_L_F_T_"
                 c_sbstxx->(ordsetfocus("IXX"))
                 c_sbstxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
             ELSEIF  (cOrderDbf )->ptype_id $ "_U_"
					  c_sbstxx->(ordsetfocus("INDXX"))
					  c_sbstxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->size_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
				 ELSE
                 c_sbstxx->(ordsetfocus("INXX"))
                 c_sbstxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->pline_id+(cOrderDbf )->size_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
             ENDIF
             IIF(c_sbstxx->(found()),lRetVal := .T.  ,lRetVal := .F. )
          ELSE
             lRetVal := .T.
          ENDIF
      ELSE
          lRetVal := .T.
		ENDIF
   ENDIF
   IF lRetVal
		IF d_ord->ptype_id == "U" .AND. !"DB" $ d_ord->pline_id  .AND. d_line->b_purp $ "_5_8_"  //Vitaly 31-07-02 ID:27311140
			 IF (;
			 	 ( d_line->ptype_id+d_line->pline_id+d_line->size_id == d_ord->ptype_id+d_ord->pline_id+d_ord->size_id ) .AND. ;
             ( d_line->value_id >= d_ord->value_id * 0.90 .AND. lDT .OR. (d_line->value_id == 0.00 .AND. lDT) ) ;
				 )
               lRetVal := .T.
			 ELSE
					lRetVal := .F.
			 ENDIF
      ELSEIF d_ord->ptype_id == "U" .AND. !"DB" $ d_ord->pline_id  .AND. !d_line->b_purp $ "_5_8_"
			 IF (;
			    d_line->ptype_id+d_line->pline_id+d_line->size_id ==                                  ;
             d_ord->ptype_id+d_ord->pline_id+d_ord->size_id                               .AND. ;
             ( d_line->value_id >= d_ord->value_id * 0.90 .AND. lDT .OR. (d_line->value_id == 0.00 .AND. lDT) )   .AND. ;
				 Val(d_line->cp_pccode) > 6904                                                                     ;
				 )                                                                                                 .OR.  ;
				 (;
				 d_line->ptype_id+d_line->pline_id+d_line->size_id ==                                  ;
             d_ord->ptype_id+d_ord->pline_id+d_ord->size_id                               .AND. ;
				 Val(d_line->cp_pccode) <= 6904                                                                    ;
				 )
               lRetVal := .T.
			 ELSE
					lRetVal := .F.
			 ENDIF
	   ENDIF
		IF ((cOrderDbf )->esny_id <> (cChosenDbf)->esny_id)
		   lRetVal := .F.
	   ENDIF
	ENDIF
ELSEIF lRetVal
	/*IF ((cOrderDbf )->esnxx_id <> (cChosenDbf)->esnxx_id) //.AND. (cOrderDbf )->esnxx_id $ "_0B_77_0G"
	   //GenOpenFiles({"c_sbstxx"})
	   IF (cOrderDbf )->ptype_id $ "_L_F_T_"
	       c_sbstxx->(ordsetfocus("IXX"))
	       c_sbstxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
	   ELSEIF  (cOrderDbf )->ptype_id $ "_U_"
	  	  c_sbstxx->(ordsetfocus("INDXX"))
	  	  c_sbstxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->size_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
	   ELSE
	       c_sbstxx->(ordsetfocus("INXX"))
	       c_sbstxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->pline_id+(cOrderDbf )->size_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
	   ENDIF
	   IIF(c_sbstxx->(found()),lRetVal := .T.  ,lRetVal := .F. )
	ELSE
	   lRetVal := .T.
	ENDIF*/
	IF lRetVal
	   IF d_ord->ptype_id == "U" .AND. !"DB" $ d_ord->pline_id  .AND. d_line->b_purp $ "_5_8_"  //Vitaly 31-07-02 ID:27311140
			 IF (;
			 	 ( d_line->ptype_id+d_line->pline_id+d_line->size_id == d_ord->ptype_id+d_ord->pline_id+d_ord->size_id ) .AND. ;
             ( d_line->value_id >= d_ord->value_id * 0.90 .AND. lDT .OR. (d_line->value_id == 0.00 .AND. lDT) ) ;
				 )
               lRetVal := .T.
			 ELSE
					lRetVal := .F.
			 ENDIF
      ELSEIF d_ord->ptype_id == "U" .AND. !"DB" $ d_ord->pline_id  .AND. !d_line->b_purp $ "_5_8_"
			 IF (;
			    d_line->ptype_id+d_line->pline_id+d_line->size_id ==                                  ;
             d_ord->ptype_id+d_ord->pline_id+d_ord->size_id                               .AND. ;
             ( d_line->value_id >= d_ord->value_id * 0.90 .AND. lDT .OR. (d_line->value_id == 0.00 .AND. lDT) )   .AND. ;
				 Val(d_line->cp_pccode) > 6904                                                                     ;
				 )                                                                                                 .OR.  ;
				 (;
				 d_line->ptype_id+d_line->pline_id+d_line->size_id ==                                  ;
             d_ord->ptype_id+d_ord->pline_id+d_ord->size_id                               .AND. ;
				 Val(d_line->cp_pccode) <= 6904                                                                    ;
				 )
               lRetVal := .T.
			 ELSE
					lRetVal := .F.
			 ENDIF
	   ENDIF
	ENDIF
ENDIF
//vr for tapi 07.10.2002
IF lRetVal .AND. d_ord->esny_id $ "_4_7_C_D_B_"
   lRetVal := (d_ord->esny_id == d_line->esny_id)
ENDIF

IF lRetVal .AND. "DB" $ d_ord->pline_id .AND. d_ord->ptype_id == "U"
   lRetVal := d_line->value_id == d_ord->value_id
ENDIF

IF lRetVal .AND. d_ord->esny_id $ "_H_" .AND. d_ord->ptype_id == "U"
	lRetVal := (d_ord->esny_id == d_line->esny_id) .AND. (d_line->value_id == d_ord->value_id)
ENDIF

IF lRetVal .AND. (d_line->esnxx_id $ "2F_3A_2Y_2X_3X_4X_3J" .OR. d_ord->esnxx_id $ "2F_3A_2Y_2X_3X_4X_3J") .AND. (d_line->esnxx_id <> d_ord->esnxx_id)
   lRetVal := !lRetVal
ENDIF
/////////////////////////
//GenCloseFiles({"c_sbstxx"})
DBSelectArea(nOldArea)
Return lRetVal
////////////////////////////////////////////////
static function  FrzLn(cBid)
Local nOldArea := Select()
Local lRetVal := .F.
NetUse("D_Frzln",5)
ordsetfocus(1)
d_frzln->(dbseek(cBid))
lRetVal := Found()
DbCloseArea("D_frzln")
DBSelectArea(nOldArea)
Return lRetVal
///////////////////////////////////////////////////
static function  MakeAv_2(cFamily)
Local nOldArea := Select()
Local init_bid,prev_qty
DbSelectArea("t_avail")
IIF( FILE("t_availt.cdx"),FERASE("t_availt.cdx") ,nil )
CheckIndex("bid",GetUserInfo():cTempDir + "t_availt","b_id+GetHie_2(tol_id,volt_id,tc_id)",.T.)
dbgotop()//dbseek(cFamily)
While !EOF() //.AND. t_avail->ptype_id+t_avail->pline_id+t_avail->size_id+str(t_avail->value_id,9,3) == cFamily
		init_bid := t_avail->b_id
		prev_qty := 0
		While t_avail->b_id == init_bid
        RecLock(5,"SCHED")
		  t_avail->net_qty := t_avail->accum_qty - prev_qty
		  prev_qty := t_avail->accum_qty
		  dbunlock()
		  IF t_avail->net_qty < 0
                 IF Empty(hUpd_qty)
                    hUpd_qty := fcreate(GetUserInfo():cTempDir + "qtyprob.txt")
                    fwrite(hUpd_qty,"+-----------------------------------------------------------------------+")
                    fwrite(hUpd_qty,EOL)
                    fwrite(hUpd_qty,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
                    fwrite(hUpd_qty,EOL)
                    fwrite(hUpd_qty,"|     Scheduling module's results : Esn's with non defined routes       |")
                    fwrite(hUpd_qty,EOL)
                    fwrite(hUpd_qty,"+-----------------------------------------------------------------------+")
                    fwrite(hUpd_qty,EOL)
		           ENDIF
                 fwrite(hUpd_qty,"| " + PADR(t_avail->ptype_id + "  " + t_avail->pline_id + "  " + t_avail->size_id+ "  " + t_avail->tol_id +  "  " + str(t_avail->value_id,9,3) + " Exp. Qty of wide tol. is low from the narrow ",69) + " |")
                 fwrite(hUpd_qty,EOL)
		  ENDIF
		  dbskip(1)
		End
END
dbclearindex()
IIF( FILE(GetUserInfo():cTempDir + "t_availt.cdx"),FERASE(GetUserInfo():cTempDir + "t_availt.cdx") ,nil )
CheckIndex("bid",GetUserInfo():cTempDir + "t_availt","b_id+descend(GetHie_2(tol_id,volt_id,tc_id))",.T.)
CheckIndex("ibt",GetUserInfo():cTempDir + "t_availt","b_id+tol_id",.T.)
DBselectArea(nOldArea)
Return Nil
/////////////////////////////////////////////////
static function  MakeAvail(aTestTol,aSeq)
Local nOldArea := Select()
LOCAL lExit := .F. , nRetVal := 0
LOCAL xKey
LOCAL bKey ,i
LOCAL nCurrentQty
LOCAL cUomName,aSeq_sm := {},aSeq_no := {}
LOCAL nCount := 0
LOCAL cMessage
LOCAL aTol := {},aRepQty := {}
LOCAL nQty
local nRec

IF !Empty(aSeq)
	aSeq_sm := aSeq[1];aSeq_no := aSeq[2]
ENDIF

c_proc->(ordsetfocus("iproc_id"))
c_proc->( DbSeek( d_line->cpproc_id ) )
xKey := c_proc->uom_id + d_line->b_type + d_line->size_id
c_expqty -> (ordsetfocus("iuts"))
bKey := COMPILE( c_expqty->(ordkey()))
IF c_expqty->( DbSeek( xKey ) )
     WHILE bKey:eval() == xKey
			 IF !Empty( aTestTol )   //vitaly 02.11.2000
                //THIS PART HAS NO TOL ID
                   lExit := ( d_line->value_id >= c_expqty->lval_lim       .AND. ;
                              d_line->value_id <= c_expqty->hval_lim )     .AND. ;
                              aScan(aTestTol,c_expqty->tol_id) <> 0
          ELSE
               // THIS PART HAS TOL ID so check tol. id
               lExit := ( d_line->value_id >= c_expqty->lval_lim       .AND. ;
                          d_line->value_id <= c_expqty->hval_lim )
			 ENDIF
			 IF lExit
						 IF  d_line->b_purp$"58" .AND. Val(d_line->cp_pccode) > 7105
							  nRetVal := 1.0
						 ELSEIF d_line->b_purp$"58" .AND. Val(d_line->cp_pccode) <= 7105
							  nRetVal := 0.9
						 ELSE
						     nRetVal := c_expqty->exp_yld      ///bqty_exp
						 ENDIF
                   IF c_proc->( DbSeek( d_line->cpproc_id ) )
                    DO CASE
                       CASE c_proc->uom_id = "W"
                            nCurrentQty := d_line->cp_bqtyw
									 cUomName    := "wfr"
							  CASE c_proc->uom_id = "S"
                            nCurrentQty := d_line->cp_bqtys
									 cUomName    := "str"
							  CASE c_proc->uom_id = "P"
									 nCurrentQty := d_line->cp_bqtyp
									 cUomName    := "pcs"
						  ENDCASE
                    IF c_proc->calc_exp
                       nRetVal := nCurrentQty * nRetVal * d_line->expq_fctr
                       IF  cUomName <> "pcs"
                           nRetVal := qtyconvert(nRetVal,d_line->b_type,d_line->pline_id,d_line->size_id,c_proc->uom_id,"P",,,d_line->route_id,d_line->value_id) //VR 2114110
                       ENDIF
                    ELSE
                       nRetVal := d_line->cp_bqtyp                   //  must be in pieces
                    ENDIF
                    t_avail->(dbgobottom())    //vito
					     t_avail->(dbappend())
					     IF t_avail->(RLock())
						     nCount++
						     IF aScan(aTol,c_expqty->tol_id) == 0
							     AADD(aTol,c_expqty->tol_id)
						     ELSE
                          cMessage := "Double Exp.Qty Record for UOM:[" + c_proc->uom_id + "] " + d_line->b_type + " " + d_line->size_id + " " + STR(d_line->value_id,9,3) + " " + c_expqty->tol_id
						     ENDIF
                       t_avail->b_id      := d_line->b_id
						     t_avail->ptype_id  := d_line->ptype_id
							  t_avail->pline_id  := d_line->pline_id
						     t_avail->size_id   := d_line->size_id
						     t_avail->value_id  := d_line->value_id
						     t_avail->tol_id    := c_expqty->tol_id
						     t_avail->volt_id   := d_line->volt_id
						     t_avail->tc_id     := d_line->tc_id
							  nRec := c_expqty->(recNO())

							  aRepQty := AvailbleForAnyOne(nil,c_expqty->tol_id)
							  nRetVal := 0

							  IF !empty(aSeq) .AND. !empty(t_avail->tol_id)



							  AEVAL( aRepQty, ;
							  	              {|eTol| ;
												           IIF( ;
															       aSeq_no[ ascan(aSeq_sm,eTol[1])         ] <=  ;
																	 aSeq_no[ ascan(aSeq_sm,t_avail->tol_id) ],;
																	 nRetVal += eTol[2] , NIL) ;
											  	  } ;
								    )
							  ELSE
							      AEVAL( aRepQty, {|eTol| IIF(eTol[1] == t_avail->tol_id ,nRetVal := eTol[2] , NIL) } )
							  ENDIF

							  t_avail->accum_qty := nRetVal

							  c_expqty->(dbgoto(nRec))
						     t_avail->(dbunlock())

                       IF d_line->tol_id == t_avail->tol_id
                          nQty := T_Avail->accum_qty  * d_line->expq_fctr
                       ENDIF

						  ENDIF
					     t_avail->(dbcommit())
                   ELSE
	                 nRetVal  := 0
                    cUomName := "Error!"
					    ENDIF
          ENDIF
			 c_expqty->( DbSkip() )
     END
ENDIF
DbSelectArea(nOldArea)
IF nCount == 0
	cMessage := "No records"
	Alert("No exp. QTY for this product!!!",{"Ok"})
ELSEIF nCount <> 0 .AND. d_line->b_purp $ "_8_5_"
       FOR i := 1 TO nCount
           t_avail->(rLock())
           t_avail->accum_qty := nQty
           t_avail->(dbunlock())
           t_avail->(dbskip(-1))
       NEXT
ENDIF
Return cMessage
//////////////////////////////////////////////
static function  PreLink(lNew)

Local lRetVal
Local nOldArea   := Select()
LOCAL cDbf       := "d_ord"
Local nPending
Local nAvailable
LOCAL nPromise
LOCAL nCover
LOCAL dPromise   := batchCalc3()
LOCAL cComment := space(60)


IIF(!lCont ,t_prom->( __DBZAP() ),nil )
nPending   := IIF(!Empty(lNew),INT(StillPending()),INT(StillPending()) )
nAvailable := AvailQtyVAL(nPending)
nPromise   := MIN( nAvailable, nPending)
nCover     := MIN( nAvailable, nPending)
IIF(iif(!Empty(lNew),TestQty(nPromise) > 0,nPromise > 0) ,KeepPromise({nCover,nPromise,dPromise,cComment},"link") ,nil )//vitaly 19.04.2001
IF nPending > 0
	 lCont := .T.
	 lRetVal := .T.
ELSEIF nPending <= 0 .OR. iif(!Empty(lNew),TestQty(nPromise) <= 0,.T.) //vitaly 19.04.2001
	 lCont := .F.
	 lRetVal := .F.
ENDIF

DbselectArea(nOldArea)

Return lRetVal
/////////////////////////////////////////
STATIC FUNCTION AvailQtyVAL(nPending)
Local nOldArea := Select()
RETURN GetAvailQty(d_line->b_id,nPending) - Promised()
/////////////////////////////////////////
STATIC FUNCTION Promised()

LOCAL nPromised := 0
LOCAL cKey      := d_line->b_id
LOCAL cOldOrder := d_prom->( OrdSetFocus("iprombn") )
LOCAL nSaveRec  := d_prom->( RecNo() )

nSaveRec := t_prom->( RECNO() )
t_prom->( DBGOTOP() )
WHILE !t_prom->( EOF() )
      IF !t_prom->( DELETED() )  .AND.;
         t_prom->prom_src == "P" .AND.;
         t_prom->b_id = cKey
         nPromised += t_prom->qty_prom
      END
      t_prom->( DBSKIP() )
END
t_prom->( DBGOTO( nSaveRec ) )
RETURN nPromised
///////////////////////////////////////////
STATIC FUNCTION KeepPromise(aPromise,cWhatFrom)
t_prom->( DBAPPEND() )
t_prom->PROM_ID    := 0
t_prom->PORQ_ID    := D_ord->Poln_id
// fill this field ONLY when the user ok's the entire promise
// to avoid having to renumber at that time due to deletions
t_prom->PROMLN     := 0
// this field will get it's decimal later, when PROMLN is set (see above)
t_prom->poln_id    := D_ord->poln_id
t_prom->b_id       := IIF(cWhatFrom == "link",D_line->b_id,d_stock->b_id)
t_prom->esn_id     := IIF(cWhatFrom == "link",D_line->esn_id,d_stock->esn_id)
IF cWhatFrom <> "link"
    t_prom->loc := d_stock->loc
ENDIF
t_prom->qty_prom   := aPromise[2]
t_prom->qty_needed := aPromise[2]
t_prom->prom_src   := IIF(cWhatFrom == "link","P","S")
IF cWhatFrom == "nipuk"
   IF D_STOCK->wh3 <> 0
     t_prom->prom_wh    := "WH3"
   ELSEIF D_STOCK->wh4 <> 0
     t_prom->prom_wh    := "WH4"
   ELSEIF D_STOCK->wh6 <> 0
     t_prom->prom_wh    := "WH6"
   ENDIF
ENDIF

t_prom->prom_date  := MoveShabos(aPromise[3])
t_prom->prom_stat  := "H"
t_prom->prom_com1  := aPromise[4]
t_prom->( DBUNLOCK() )
RETURN nil
////////////////////////////
STATIC FUNCTION StillPending(cGenFile)

LOCAL cDbf        := "d_ord"
LOCAL nPending
LOCAL nRec        := t_prom->( RECNO() )
LOCAL nOrdField   := (cDbf)->( FIELDPOS( "poln_id") )
LOCAL nPromField  := d_prom->( FIELDPOS( IF(cGenFile == "d_ordreq", "porq_id", "poln_id") ) )
LOCAL cOrder      := IF(cGenFile == "d_ordreq", "ipromord", "iprompln" )
LOCAL cOldOrd     := d_prom->( ORDSETFOCUS(cOrder) )
LOCAL nOldPromRec := d_prom->( RECNO() )
IF cGenFile == "d_ordreq"
     cDbf        := cGenFile
     nPending := ordreqPending()
ELSE
     nPending := ordPending()
ENDIF
d_prom->( DBSEEK( STR( (cDbf)->( FIELDGET(nOrdField) ), 9, 2 ) ) )
WHILE d_prom->( FIELDGET(nPromField) ) == (cDbf)->( FIELDGET(nOrdField) );
      .AND.  !d_prom->( EOF() )
      IF d_prom->prom_src == "P"
         nPending -= d_prom->qty_prom
      END
      d_prom->( DBSKIP() )
END
d_prom->( ORDSETFOCUS(cOldOrd) )
d_prom->( DBGOTO( nOldPromrec) )
t_prom->( DBGOTOP() )
WHILE !t_prom->( EOF() )
      IF !t_prom->( DELETED() )
         nPending -= t_prom->qty_prom
      ENDIF
      t_prom->( DBSKIP() )
END
t_prom->( DBGOTO( nRec ) )
nRec     := t_pack->( RECNO() )
t_pack->( DBGOTOP() )
WHILE !t_pack->( EOF() )
      IF !t_pack->( DELETED() )
         nPending -= t_pack->qty_prom
      END
      t_pack->( DBSKIP() )
END
t_pack->( DBGOTO( nRec ) )
nRec     := t_pcksav->( RECNO() )
RETURN nPending
////////////////////////////////
STATIC FUNCTION GetAvailQty(cBid,nPending)
Local nOldArea := Select()
Local nRetVal := 0
Local nCount := 0
Local nPrev_net := 0
Local nPrev_ac := 0
Local nRecNo
DbSelectArea("t_avail")
Dbsetindex(GetUserInfo():cTempDir + "t_availt")
ordsetfocus("bid")
dbseek(cBid)
While t_avail->b_id == cBid
     IF TestQty(t_avail->Accum_qty) > 0 .AND. GetHie_2(t_avail->tol_id,t_avail->volt_id,t_avail->tc_id) <= GetHie_2(d_ord->tol_id,d_ord->volt_id,d_ord->tc_id)
		nRetVal := MIN(TestQty(t_avail->Accum_qty),nPending)
		t_avail->Accum_qty := t_avail->Accum_qty - nRetVal
		nRecNo := RecNo()
		EXIT
	ELSE
		nRetVal := 0
		dbskip(1)
	ENDIF
End
IF nRecNo == NIL
  Return nRetVal
ENDIF
dbseek(cBid)

While t_avail->b_id == cBid //Updating all records before our tol_id
	IF GetHie_2(t_avail->tol_id,t_avail->volt_id,t_avail->tc_id) >= GetHie_2(d_ord->tol_id,d_ord->volt_id,d_ord->tc_id) .AND. RecNo() <> nRecNo
		t_avail->Accum_qty := t_avail->Accum_qty - nRetVal
	ENDIF
	dbskip(1)
End
dbgoto(nRecno)
nCount := nRetVal
While t_avail->b_id == cBid//Updating all records after our tol_id
	   t_avail->net_qty := t_avail->net_qty - nCount
		nCount := Abs(t_avail->net_qty)
		IIF(t_avail->net_qty < 0,t_avail->net_qty := 0, nCount := 0)
		dbskip(1)
End
dbgoto(nRecno)
nPrev_ac := t_avail->Accum_qty
While t_avail->b_id == cBid
		t_avail->Accum_qty := nPrev_ac - nPrev_net
		nPrev_ac  := t_avail->Accum_qty
		nPrev_net := t_avail->Net_qty
		DBskip(1)
End
DbselectArea(nOldArea)
Return nRetVal
////////////////////////////////////////////////
Static Function FirstTestQty()//4.3.3.1.1 in Sched. Spec.
Local nOldArea := Select()
Local lRetVal  := .F.
LOcal lFound   := .T.
Local cTol     := d_ord->tol_id
dbselectarea("t_avail")
Dbsetindex(GetUserInfo():cTempDir + "t_availt")
ordsetfocus("ibt")
While .T.
    dbseek(q_line->b_id+cTol)
    IF !Found()
       dbseek(q_line->b_id)
       IF Found()
          cTol := ChangeTol(cTol)
          IF !Empty(cTol)
             dbgotop()
          ELSE
             lFound := .F.
             EXIT
          ENDIF
       ELSE
          lFound := .F.
          EXIT
       ENDIF
    ELSE
       EXIT
    ENDIF
End
IIF(TestQty(t_avail->Accum_qty) > 0 .AND. lFound,lRetVal := .T. ,nil ) //- promised() for test only
Dbselectarea(nOldArea)
Return lRetVal

/////////////////////////////////////////////////
Static Function  SpecTestqty(nQty)
local nOldSelect := select()
Local lRetVal := .F.
c_esny->(ordsetfocus(1))  //vitaly did the dirty work and I took the credit
c_esny->(dbseek(d_ord->esny_id))
IF nQty >= c_esny->esny_qty + GetLimits(c_esny->esny_qty)[1]
	lRetVal := .T.
ENDIF
select (nOldSelect)
return lRetVal
//////////////////////////////////////////////
FUNCTION CreateTempDbf( cDbf, cNtx )
LOCAL oTFile
// needed to create the t_prom.dbf in the user's temp dir, if it doesn't exist
LOCAL aStruct := {;
                  { "PROM_ID"    , "N", 005, 000 },;
                  { "PORQ_ID"    , "N", 009, 002 },;
                  { "PROMLN"     , "N", 003, 000 },;
                  { "POLN_ID"    , "N", 009, 002 },;
                  { "B_ID"       , "C", 006, 000 },;
                  { "ESN_ID"     , "C", 016, 000 },;
                  { "QTY_PROM"   , "N", 007, 000 },;
                  { "QTY_NEEDED" , "N", 007, 000 },;
                  { "PROM_DATE"  , "D", 008, 000 },;
                  { "PROM_SRC"   , "C", 001, 000 },;
                  { "PROM_WH"    , "C", 003, 000 },;
                  { "PROM_STAT"  , "C", 001, 000 },;
                  { "PROM_COM1"  , "C", 060, 000 },;
                  { "FROM_PACKB" , "L", 001, 000 },;
                  { "PACK_BATCH" , "N", 001, 000 },;
                  { "PACK_ROUTE" , "C", 004, 000 },;
                  { "PACK_PRIOR" , "C", 002, 000 },;
                  { "DIEL_ID"    , "C", 001, 000 },;
                  { "B_NCAPS"    , "C", 002, 000 },;
                  { "B_PURP"     , "C", 001, 000 },;
                  { "B_STAT"     , "C", 001, 000 },;
						{ "LOC"        , "C", 002, 000 } ;
                  }
IF FILE( GetUserInfo():cTempDir+cDbf+".DBF")
   FERASE(GetUserInfo():cTempDir+cDbf+".CDX")
ELSE
   DBCREATE( GetUserInfo():cTempDir+cDbf, aStruct, "DBFCDXAX" )
ENDIF
NetUse(cDbf,5,,.F.,,GetUserInfo():cTempDir)
(cDbf)->( __DBZAP() )
IF cNtx <> NIL
   CheckIndex(cNtx,GetUserInfo():cTempDir+cDbf,"b_id+esn_id",.T.)
ENDIF
(cDbf)->( DBCLOSEAREA() )
oTFile :=  tableTranslate():New( cDbf ) // genopenfiles
oTFile:SetIndexList()
oTFile:XopenTemp( NIL, FALSE )
RETURN oTFile
//////////////////////////////////////
Static Function  RealyPromise(aInfo)//4.3.3.3//updates files of promising
LOCAL nOrder
LOCAL oOrd
LOCAL nRecNo := d_ord->(recNo())
LOCAL cPolnid := d_ord->poln_id
LOCAL cReqEsn := d_ord->esn_id
LOCAL cBID := d_line->b_id
LOCAL cChoosenEsn := d_line->Esn_id
LOCAL nSelect := SELECT()
LOCAL nLastProm
LOCAL nOrdNo := D_ORD->(ORDSETFOCUS())
IF Select("t_prom") == 0 .OR. t_prom->( LASTREC() ) == 0
   RETURN Nil
ENDIF
if d_ord->(RecLock( 5, "SCHED" ))
   d_ord->d_revdlv := CTOD("  /  /  ") //4.3.6 in Sched Spec
   d_ord->(dbunlock())
endif
IF SELECT("d_ord") == 0
   oOrd := TableTranslate():new( "d_ord" )
   oOrd:setIndexList()
   oOrd:xopen()
ENDIF
IF d_prom->( FilLock(5) )
   nOrder := d_prom->( INDEXORD() )
   d_prom->( OrdSetFocus(0) )
   d_prom->( DBGOBOTTOM() )
   nLastProm := d_prom->prom_id + 1
   d_prom->( OrdSetFocus(nOrder) )
 IF alltrim(d_ord->sched_sour) == "D_ORD" .AND. t_prom->(lastRec()) <> 0
   if d_ord->(RecLock( 5, "SCHED" ))
      d_ord->d_revdlv := NewDate()//4.3.6 in Sched Spec
      d_ord->(dbunlock())
   endif
   DBSelectArea("d_ord")//close temp file with alias d_ord
   nRecNo := RecNo()
   D_ORD->(DBCloseArea())
   NetUse("d_ord",5)    //open original file d_ord
   d_ord->(ordsetfocus("ipolnoid"))
   if (d_ord->(dbseek(str(t_prom->Poln_id,9,2)) .AND. NewDate() > mrkorddue(.T.,'d_ord'))) .AND. d_ord->(RecLock( 5, "SCHED" ))
      d_ord->d_revdlv := NewDate()
      d_ord->(dbunlock())
   elseif d_ord->(found()) .AND. d_ord->(RecLock( 5, "SCHED" ))
      d_ord->d_revdlv := CTOD("  /  /  ")
      d_ord->(dbunlock())
   endif
   D_ORD->(DBCloseArea())
   NetUse( "t_ord",5, NIL, USE_EXCLUSIVE, USE_NEW, GetUserInfo():cTempDir,"d_ord" )
   ordsetfocus(nOrdNo)
   dbgoto(nRecNo)
 ENDIF
 CreatePolnIds()
 PutLines_ord(nLastProm,aInfo,"d_ord")
 d_prom->( DbUnLock() )
 dbselectarea("t_prom")
 t_prom->( __DBZAP() )
 T_Prom->( DBCLEARINDEX() )
 IIF( File("t_prom.cdx"),Ferase("t_prom.cdx") ,nil )
ELSE
   ALERT("ERROR;;Unable to save promises.;Please try again in a moment.",{" OK "} )
ENDIF
IF oOrd <> NIL
   oOrd:Close()
END
D_ORD->(ORDSETFOCUS(nOrdNo))
d_ord->(dbgoto(nRecNo))
dbselectarea(nSelect)
RETURN nil
//////////////////////////////////////
Static Function CreatePolnIds()

LOCAL aOrders   := {}
LOCAL aProms    := {}
LOCAL cInt      := STR(INT(t_prom->poln_id))
LOCAL cOrd      := d_ord->( ORDSETFOCUS("ipolnoid"))
LOCAL cPoln1Id  := PADL( ALLTRIM( STR( INT(t_prom->poln_id) ) ) + ".01", 9 )
LOCAL cPorqId   := STR(t_prom->poln_id,9,2)
LOCAL lGotSome  := FALSE
LOCAL lFound    := FALSE
LOCAL n
LOCAL nDec      := .00
LOCAL nInt      := INT(t_prom->poln_id)
LOCAL nLastPolnID := t_prom->porq_id
LOCAL nPromLine := 1

IF alltrim(d_ord->sched_sour) == "D_ORDREQ"   //sIII
    IF !d_ord->( DBSEEK( cPorqId ) )
       IF !d_ord->( DBSEEK( cPoln1Id ) )
       ELSE
          lGotSome := TRUE
       END
    ELSE
       lGotSome := TRUE
    END
    IF lGotSome
       AADD( aOrders, {d_ord->poln_id, SchOrdDue(.T.,"d_ord")} )  //YG revdue
       d_ord->( DBSKIP() )
       WHILE INT(d_ord->poln_id) == nInt
             AADD( aOrders, {d_ord->poln_id, SchOrdDue(.T.,"d_ord")} )  //YG revdue
             d_ord->( DBSKIP() )
       END
       IF EMPTY( aOrders )
          lGotSome := FALSE
       ELSE
          nLastPolnId := ATAIL(aOrders)[1]
       END
    ELSE
        nLastPolnID := t_prom->porq_id
    ENDIF
ENDIF

t_prom->( DBGOTOP() )
WHILE !t_prom->( EOF() )
      IF !t_prom->( DELETED() )
         // we have to fill in the promln field now; it's used to create the poln_id
         t_prom->promln := nPromLine++
         IF alltrim(d_ord->sched_sour) == "D_ORDREQ"//::Owner:lIsrequest
            IF t_prom->prom_src == "S"
                        t_prom->poln_id := nLastPolnId //YG will this help???
               IF (n := ASCAN( aProms,{|x| x[2] == t_prom->prom_date} )) == 0
                  IF !lFound
                     IF !lGotSome // no preexisting orders
                        t_prom->poln_id := nLastPolnId
                        nLastPolnId += 0.01
                     ELSE
                        nLastPolnId += 0.01
                        t_prom->poln_id := nLastPolnId
                     ENDIF
                  END
                  AADD( aProms, {t_prom->poln_id, t_prom->prom_date} )
               ELSE
                  t_prom->poln_id := aProms[n][1]
               ENDIF
               lFound := FALSE
            END
         END
      ENDIF
      t_prom->( DBSKIP() )
END
RETURN Nil
/////////////////////////////////////////////////////////////////////
Static Function PutLines_ord(nLastProm,aInfo,cGenFile) //4.3.3.3 Simelery is done at manualy promissing

LOCAL aLine
LOCAL cBid
LOCAL cOldOrd        := d_prom->( ORDSETFOCUS("ipromord") )
LOCAL cPolnId
LOCAL lAllFromStock  := TRUE
LOCAL lNoMorePending := ( StillPending( cGenFile ) <= 0 )
LOCAL oTabSer
LOCAL oTabRef
LOCAL oTabAlloc

// I need to do this because the function that uses it is called from a
// codeblock when the source is stock
LOCAL nLastPromise := nLastProm
LOCAL nPackLn      := 0
LOCAL nPolnId      := (cGenFile)->POLN_ID
LOCAL cOrdType     := (cGenFile)->POLN_TYPE
LOCAL nRefCounter
LOCAL nSelect      := Select()
LOCAL nSerCounter
LOCAL nTimes       := 0
LOCAL lAnyFromStock := FALSE
t_prom->( DBGOTOP() )
WHILE !t_prom->(EOF())
      IF t_prom->prom_src == "S"
         lAnyFromStock := TRUE
         EXIT
      END
      t_prom->( DBSKIP() )
END
IF lAnyFromStock
    oTabAlloc := TableTranslate():new( "d_alloc" )
    oTabAlloc:setIndexList()
    oTabAlloc:xopen()
    oTabRef := TableTranslate():new( "n_refno" )
    IF oTabRef:xopen()
       IF n_refno->( RecLock( 5,"TBPROM" ) )
          n_refno->counter++
          nRefCounter := n_refno->counter
          n_refno->( DbUnLock() )
      ENDIF
       oTabRef:close()
    ENDIF
    oTabSer := TabBase():new( "n_serno" )
    oTabSer:xopen()
    // I'm not quite sure what this does yet...
    SetRefCounter( nRefCounter )
END
// If all the promise lines are from stock they'll be treated differently
cPolnId := (cGenFile)->poln_id
IF d_prom->( DBSEEK( STR(cPolnId,9,2) ) )
   WHILE d_prom->porq_id == cPolnId
       IF ( lAllFromStock := IF( d_prom->prom_src == "S" .AND. d_prom->prom_stat $ "RH" ,;
                        TRUE, FALSE ) )  == FALSE
          EXIT
       ENDIF
         d_prom->( DBSKIP() )
   END
ENDIF
d_prom->( ORDSETFOCUS( cOldOrd ) )
IF lAllFromStock
   t_prom->( DBGOTOP() )
   WHILE !t_prom->( EOF() )
       IF ( lAllFromStock := IF( t_prom->prom_src == "S", TRUE, FALSE ) )  == FALSE
          EXIT
       END
       t_prom->( DBSKIP() )
   END
END

t_prom->( DBGOTOP() )
WHILE !t_prom->( EOF() )
      IF t_prom->From_Packb .AND. !t_prom->( DELETED() )
         // now we finally get the new batch no for this packing batch
         cBid := UpdateAllBatches( 1 ,aInfo)
         t_prom->b_id := cbid
      ENDIF
      t_prom->( DBSKIP() )
END
t_prom->( DBGOTOP() )
WHILE !t_prom->( EOF() )
         IF t_prom->prom_src == "P"
            WriteLine(nLastPromise,nPolnId)
         ELSEIF t_prom->prom_src == "S"
            aLine := {;
                       t_prom->b_id     , STR(t_prom->poln_id,9,2),;
                       t_prom->prom_id  , t_prom->esn_id          ,;
                       t_prom->prom_date, t_prom->qty_prom        ,;
                       t_prom->prom_src , t_prom->prom_com1       ,;
                       RIGHT( t_prom->prom_wh, 1 ), t_prom->loc   ;
                     }
            delAlloc( aLine, {|a| OrdReqAllocate() },;
                      lAllFromStock, cGenFile,, if(cOrdType='8',.T.,.F.),GetUserInfo():cTempDir,"Sched"  )

            ++nTimes
         ENDIF
         t_prom->( DBSKIP() )
END
IIF(FILE(GetUserInfo():cTempDir+"error.dbf"),Ferase(GetUserInfo():cTempDir+"error.dbf") ,NIL )//vitaly
IF nTimes > 0 .AND. cOrdType <> '8'
   DelNipuk( STR( SetRefCounter(), 9 ), cGenFile ) // print document
ENDIF
SELECT ("d_ord")
IF cGenFile == "d_ordreq"
   IF (cGenFile)->( Reclock(5,"SCHED") )
      IF lAllFromStock .AND. lNoMorePending
         (cGenFile)->poln_stat := "A"
			(cGenFile)->( DBDELETE() )
      END
      (cGenFile)->( DBUNLOCK() )
   ELSE
      ALERT("ERROR!;;"+cGenFile+" status;NOT updated!", {" OK "} )
   END
END
IF oTabAlloc <> NIL
   oTabAlloc:close()
   oTabRef:close()
   oTabSer:close()
ENDIF
SELECT (nSelect)
setcap()
RETURN Nil
/////////////////////////////
Static function  WriteLine( nLastPromise, nPolnId )

LOCAL cOrd   := d_line->( ORDSETFOCUS("ib_idln"))
LOCAL cOrdMv := m_linemv->( ORDSETFOCUS("ilnmvbn"))
LOCAL nRec   := d_line->( RECNO() )
LOCAL nRecMv := m_linemv->( RECNO() )
IF !d_prom->( Addrec(5, "SCHED") )
    ALERT("ERROR;;Unable to append a new record to; DPROM.DBF",{" OK "})
END
d_prom->prom_id   := nLastPromise
d_prom->porq_id   := t_prom->porq_id
d_prom->promln    := t_prom->promln
d_prom->poln_id   := t_prom->porq_id
d_prom->b_id      := t_prom->b_id
d_prom->qty_prom  := t_prom->qty_prom
d_prom->prom_src  := t_prom->prom_src
d_prom->prom_stat := "H"
d_prom->prom_date := t_prom->prom_date
d_prom->( DBUNLOCK() )
d_line->( ORDSETFOCUS(cOrd) )
d_line->( DBGOTO( nRec ) )
m_linemv->( ORDSETFOCUS(cOrdmv) )
m_linemv->( DBGOTO( nRecmv ) )
RETURN nil
/////////////////////////////////////////
Static Function OpenNewBatch(cFamily)//4.3.5 in Sched Spec
Return DoMultiLines(cFamily)
////////////////////////////////////////
STATIC FUNCTION DoMultiLines(cFamily)

LOCAL i
LOCAL cScr      := SAVESCREEN()
LOCAL nBatches  := 1
LOCAL GetList   := {}
LOCAL nRecno    :=  d_line->( RECNO() )
LOCAL lContinue := TRUE
LOCAL lRetVal := .F.
Local nOldArea := Select()
Local nRecQline
Local nRecDline
Field b_id
@ 20,11 say "Open new batches          "
opnbtchOpenFiles()
d_line->( DBGOTO( nRecNo ) )

if VarInit() //4.3.5 in Sched Spec opening new batch
     nRecDline := Store("d_line")
     nRecQline := Store("q_line")
     CreateLine("d_ord")
     NetUse( "t_avail",5, NIL, USE_EXCLUSIVE, USE_NEW,GetUserInfo():cTempDir )
     MakeAvail()
     MakeAv_2(cFamily)
     lRetVal := PreLink(.T.)
     IF select("T_PROM")<>0
        T_PROM->(DBCLEARINDEX())
     ENDIF
     RealyPromise()
     DBSELECTAREA("t_avail")
     DbCloseArea("t_avail")
     IF select("T_PROM") <> 0
        DBSELECTAREA("t_prom")
		  dbclearindex()
        t_prom->( __DBZAP() )
     ENDIF
     dbselectarea("q_line")
     set relation to
     q_line->(dbreindex())
     Set Relation to b_id into d_line
endif
lCont := .F.
opnbtchCloseFiles()
RESTSCREEN(,,,,cScr)
nB_ID := nB_PURP := nESN_ID := nB_TYPE := nSIZE_ID := nVALUE_ID := nTOL_ID :=;
nVOLT_ID := nDIEL_ID := nDIEL_WIDTH := nB_NCAPS := nB_DOPEN := nQTY_BINI :=;
nUOM_INI := nROUTE_ID := nB_PRIOR := nB_DPROM := nEXPQ_FCTR := nB_STAT :=;
nB_REMARK := NIL
DbSelectArea(nOldArea)
RETURN lRetVal
////////////////////////////////////////////////
STATIC FUNCTION opnbtchOpenFiles
LOCAL oTab
LOCAL cTempDir    := GetUserInfo():cTempDir
aoOpenedList := {}
aoOpenedList := genOpenFiles( {"m_linemv","c_rlib","d_esn",;
                               "c_tol","c_size","c_volt","c_value","c_proc",;
                               "c_prior","c_leadt","c_bstat","c_esnlnk","d_prornd"})
SELECT c_rlib
ordSetFocus( "irlibid" )
SELECT c_esnlnk
ordSetFocus( "ilnkesn" )
SELECT d_line
RETURN OpenState( aoOpenedList )

/*
 * ÚÄ Procedure ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
 * ³         Name: opnbtchCloseFiles                                          ³
 * ³  Description:                                                            ³
 * ³       Author: Shalom LeVine         Designer:                            ³
 * ³ Date created: 08-20-96              Date updated: þ08-20-96              ³
 * ³ Time created: 09:21:16am            Time updated: þ09:21:16am            ³
 * ³    Copyright: AVX                                                        ³
 * ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
 * ³   Parameters: None                                                       ³
 * ³     See Also:                                                            ³
 * ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
 */
STATIC PROCEDURE opnbtchCloseFiles
AvxCloseFiles()
RETURN
///////////////////////////////////////////////////////
STATIC FUNCTION VarInit()
LOCAL lRetVal := .T.
LOCAL oEsn
LOCAL cParam
LOCAL nOldArea := Select()
local aValues := GetDTValues(d_ord->pline_id+d_ord->size_id,"d_ord")
LOCAL lDT     := IfInDTRange(aValues,d_ord->value_id)
nB_ID       := NextBNNo()
nB_PURP     := "1"
nDIEL_ID    := " "
nDIEL_WIDTH := 0
nB_NCAPS    := "  "
nESN_ID     := d_ord->esn_id
oEsn        := PartBase():new()
oEsn:cEsn   := nESN_ID
oEsn:scattar("esn")

IF oEsn:cPartType == "C"
	cParam:= oEsn:cPartType+oEsn:cProductline+oEsn:cSize+lTrim(Str(oEsn:nValue,9,3))
   dbselectarea("d_edsgn")
   ordsetfocus("edtopdwn")
   d_edsgn->(dbseek(cParam))
   IF found()
      dbskip(1)
      IF d_edsgn->ptype_id+d_edsgn->pline_id+d_edsgn->size_id+lTrim(str(d_edsgn->value_id,9,3)) == cParam
         IF Empty(hUpd_route)
            hUpd_route := fcreate(GetUserInfo():cTempDir + "routprob.txt")
            fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
            fwrite(hUpd_route,EOL)
            fwrite(hUpd_route,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
            fwrite(hUpd_route,EOL)
            fwrite(hUpd_route,"|  Scheduling module's results : Esn's with non defined routes\designs  |")
            fwrite(hUpd_route,EOL)
            fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
            fwrite(hUpd_route,EOL)
         ENDIF
         fwrite(hUpd_route,"| " + PADR(str(d_ord->poln_id,9,2) + "  " + nESN_ID + "  Double designs",69) + " |")
         fwrite(hUpd_route,EOL)
         return .F.
      ELSE
         DBSKIP(-1)
         IF (Alltrim(d_edsgn->tc_id) == "K" .AND. oEsn:cTemperature == "J" ) .OR. ;
             !TestSubst(oEsn:cVoltage,d_edsgn->volt_id)
             IF Empty(hUpd_route)
               hUpd_route := fcreate(GetUserInfo():cTempDir + "routprob.txt")
               fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
               fwrite(hUpd_route,EOL)
               fwrite(hUpd_route,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
               fwrite(hUpd_route,EOL)
               fwrite(hUpd_route,"|  Scheduling module's results : Esn's with non defined routes\designs  |")
               fwrite(hUpd_route,EOL)
               fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
               fwrite(hUpd_route,EOL)
             ENDIF
             fwrite(hUpd_route,"| " + PADR(str(d_ord->poln_id,9,2) + "  " + d_ord->esn_id + " ESN is not match to design table",69) + " |")
             fwrite(hUpd_route,EOL)
             return .F.
         ENDIF
         IF Alltrim(d_edsgn->tc_id) == "K"
            oEsn:cTemperature := "K"
            nEsn_id := Stuff(nEsn_id,6,1,"K")
         ELSE
            oEsn:cTemperature := "J"
            nEsn_id := Stuff(nEsn_id,6,1,"J")
         ENDIF
         oEsn:cVoltage := d_edsgn->volt_id
         nEsn_id := Stuff(nEsn_id,5,1,d_edsgn->volt_id)
         nDIEL_ID    := d_edsgn->diel_id
         nDIEL_WIDTH := d_edsgn->diel_width
         nB_NCAPS    := d_edsgn->b_ncaps
         D_ESN->(ordSetFocus("iesn_id"))
         IF !D_ESN->(dbseek(nEsn_id))
            IF Empty(hUpd_route)
               hUpd_route := fcreate(GetUserInfo():cTempDir + "routprob.txt")
               fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
               fwrite(hUpd_route,EOL)
               fwrite(hUpd_route,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
               fwrite(hUpd_route,EOL)
               fwrite(hUpd_route,"|  Scheduling module's results : Esn's with non defined routes\designs  |")
               fwrite(hUpd_route,EOL)
               fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
               fwrite(hUpd_route,EOL)
            ENDIF
            fwrite(hUpd_route,"| " + PADR(str(d_ord->poln_id,9,2) + "  " + d_ord->esn_id + " required ESN " + nESN_ID + " is not found in ESNs file",69) + " |")
            fwrite(hUpd_route,EOL)
            return .F.
         ENDIF
      ENDIF
   ELSE
      IF Empty(hUpd_route)
            hUpd_route := fcreate(GetUserInfo():cTempDir + "routprob.txt")
            fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
            fwrite(hUpd_route,EOL)
            fwrite(hUpd_route,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
            fwrite(hUpd_route,EOL)
            fwrite(hUpd_route,"|  Scheduling module's results : Esn's with non defined routes\designs  |")
            fwrite(hUpd_route,EOL)
            fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
            fwrite(hUpd_route,EOL)
         ENDIF
         fwrite(hUpd_route,"| " + PADR(str(d_ord->poln_id,9,2) + "  " + nESN_ID + "  No design was found",69) + " |")
         fwrite(hUpd_route,EOL)
         return .F.
   ENDIF
   DbSelectArea(nOldArea)
ELSEIF oEsn:cPartType == "U"
   nEsn_id := Stuff(nEsn_id,8,4,"0000")
   D_ESN->(ordSetFocus("iesn_id"))
   IF !D_ESN->(dbseek(nEsn_id)) .OR. !lDT
      nESN_ID     := d_ord->esn_id
   ENDIF
	IF "DB" $ oEsn:cProductline
		cParam:= oEsn:cPartType+oEsn:cProductline+oEsn:cSize+lTrim(Str(oEsn:nValue,9,3))
		dbselectarea("d_edsgn")
		ordsetfocus("edtopdwn")
		IF d_edsgn->(dbseek(cParam))
			nDIEL_ID    := d_edsgn->diel_id
			nDIEL_WIDTH := d_edsgn->diel_width
		endif
	ENDIF
ELSEIF oEsn:cPartType == "T"//Filters
	cParam:= oEsn:cPartType+oEsn:cSize+lTrim(Str(oEsn:nValue,9,3))
   dbselectarea("d_edsgn")
   ordsetfocus("DTFILTR")
   if d_edsgn->(dbseek(cParam))
      nDIEL_ID    := d_edsgn->diel_id
      nDIEL_WIDTH := d_edsgn->diel_width
   ENDIF
   DbSelectArea(nOldArea)
ENDIF
nB_TYPE     := GetBtype( oEsn:cProductLine , oEsn:cEsnNo )
nSIZE_ID    := oEsn:cSize
nVALUE_ID   := oEsn:nValue
nTOL_ID     := oEsn:cTolerance
nVOLT_ID    := oEsn:cVoltage
nB_DOPEN    := Date()
IF oEsn:cPartType == "F" .AND. oEsn:cProductLine == "AGG"
   nQTY_BINI   := 8//tapi 433
ELSEIF oEsn:cPartType == "F"// .OR. (oEsn:cPartType == "U" .AND.oEsn:cProductLine $ "CL9_CN9")
   nQTY_BINI   := 32//tapi 433
ELSE
	nQTY_BINI   := 16//tapi 433
ENDIF
nUOM_INI    := "W"
nROUTE_ID   := GetRoute(nESN_ID)[1]//4.3.5.2 in Sched Spec
IF nRoute_id == Nil
   IF Empty(hUpd_route)
            hUpd_route := fcreate(GetUserInfo():cTempDir + "routprob.txt")
            fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
            fwrite(hUpd_route,EOL)
            fwrite(hUpd_route,"| " + DTOC(Date()) + "                              AVX Israel             " + Time() + " |")
            fwrite(hUpd_route,EOL)
            fwrite(hUpd_route,"|  Scheduling module's results : Esn's with non defined routes\designs  |")
            fwrite(hUpd_route,EOL)
            fwrite(hUpd_route,"+-----------------------------------------------------------------------+")
            fwrite(hUpd_route,EOL)
	  ENDIF
       fwrite(hUpd_route,"| " + PADR(str(d_ord->Poln_id,9,2) + "  " + d_ord->esn_id + "  " + GetRoute(nESN_ID)[2],69) + " |")
       fwrite(hUpd_route,EOL)
       return .F.
ENDIF
//nREV        := "  "
nB_PRIOR    := "LT"
nB_DPROM    := SchOrdDue(.T.,'d_ord')
nEXPQ_FCTR  := 1.0
nB_STAT     := "T"
nB_REMARK   := Space(50)
RETURN lRetVal
//////////////////////////////////////////////
STATIC FUNCTION Store(cFile)
LOCAL oEsn := PartBase():new()

oEsn:cEsn := nESN_ID
oEsn:scattar()
IF !(cFile)->( AddRec( 5, "sched" ) )
     Msg24("Unable to save new record!",0, .T. )
     RETURN FALSE
ELSE
     (cFile)->B_ID        := nB_ID  + "1"
     (cFile)->B_PURP      := nB_PURP
     (cFile)->ESN_ID      := nESN_ID
     (cFile)->B_TYPE      := nB_TYPE
     (cFile)->SIZE_ID     := nSIZE_ID
     (cFile)->VALUE_ID    := oEsn:nValue  // mVALUE_ID    // oEsn:nValue
     (cFile)->TOL_ID      := nTOL_ID
     (cFile)->VOLT_ID     := nVOLT_ID
     (cFile)->DIEL_ID     := nDIEL_ID
     (cFile)->DIEL_WIDTH  := nDIEL_WIDTH
     (cFile)->B_NCAPS     := nB_NCAPS
     (cFile)->B_DOPEN     := nB_DOPEN
     (cFile)->QTY_BINI    := nQTY_BINI
     (cFile)->UOM_INI     := nUOM_INI
     (cFile)->ROUTE_ID    := nROUTE_ID
     (cFile)->ROUTE_REV   := nREV
     (cFile)->B_PRIOR     := nB_PRIOR
     (cFile)->B_DPROM     := nB_DPROM
     (cFile)->EXPQ_FCTR   := nEXPQ_FCTR
     (cFile)->B_STAT      := nB_STAT
     (cFile)->B_REMARK    := nB_REMARK
     (cFile)->PTYPE_ID   := oEsn:cPartType
     (cFile)->PLINE_ID   := oEsn:cProductLine
     IF oEsn:cTerminationCode  != NIL
       (cFile)->TERM_ID    := oEsn:cTerminationCode
     ENDIF
     (cFile)->ESNXX_ID   := oEsn:cEsnNo
     (cFile)->ESNY_ID    := oEsn:cEsnPacking
     (cFile)->b_wkprom := SetWeekNo(nB_DPROM,TRUE)
     IF oEsn:cTemperatureCoefficient != NIL
        (cFile)->TC_ID      := oEsn:cTemperatureCoefficient
     ENDIF
     IF nUOM_INI == "P"
        (cFile)->CP_BQTYW := qtyconvert( nQTY_BINI , nB_TYPE ,(cFile)->PLINE_ID , nSIZE_ID , "P" , "W",,,(cFile)->route_id,(cFile)->value_id ) //VR 2114110
        (cFile)->CP_BQTYS := qtyconvert( nQTY_BINI , nB_TYPE ,(cFile)->PLINE_ID , nSIZE_ID , "P" , "S",,,(cFile)->route_id,(cFile)->value_id )
     (cFile)->CP_BQTYP := nQTY_BINI
     ELSE
        (cFile)->CP_BQTYW := nQTY_BINI
        (cFile)->CP_BQTYS := qtyconvert( nQTY_BINI , nB_TYPE , (cFile)->PLINE_ID, nSIZE_ID , "W" , "S",,,(cFile)->route_id,(cFile)->value_id ) //VR 2114110
        (cFile)->CP_BQTYP := qtyconvert( nQTY_BINI , nB_TYPE , (cFile)->PLINE_ID, nSIZE_ID , "W" , "P",,,(cFile)->route_id,(cFile)->value_id )
     ENDIF
     (cFile)->PP_BQTYW := d_line->CP_BQTYW
     (cFile)->PP_BQTYS := d_line->CP_BQTYS
     (cFile)->PP_BQTYP := d_line->CP_BQTYP
	  IF cFile == "d_line"
		(cFile)->( xDbUnLock() )
	  ELSE
		(cFile)->( DbUnLock() )
	  ENDIF
ENDIF
RETURN TRUE
///////////////////////////////////////////////////////////////////////
Static Function GetRoute( cEsnId, lFromTbPack,lFromCz )
LOCAL nSelect := Select( Alias() )
LOCAL oForm
LOCAL nKey
LOCAL o , oCol
LOCAL lRouteFound := FALSE
LOCAL lFound := .F.
LOCAL i
LOCAL cTemp
LOCAL nCount := 0
LOCAL cMessage
SET CURSOR OFF

DEFAULT lFromTbPack TO FALSE
DEFAULT cEsnId TO nEsn_id
DEFAULT lFromCz TO FALSE

IF Select("c_esnlnk") == 0
	NetUse("c_esnlnk",5)
ENDIF
IF Select("c_rlib") == 0
	NetUse("c_rlib",5)
ENDIF

c_rlib->(ordSetFocus( "irlibid" ))
c_esnlnk->(ordSetFocus( "ilnkesn" ))

lRouteFound := c_esnlnk->( DBSEEK(cEsnId) )

nRoute_id:=c_esnlnk->route_id
c_rlib->( DBSEEK(nRoute_id))
WHILE ALLTRIM(c_esnlnk->esn_id) == ALLTRIM(cEsnId)
  c_rlib->(dbseek(c_esnlnk->route_id))
  cTemp := c_rlib->route_id
  While c_rlib->route_id == cTemp
   IF c_rlib->route_type == IIF(lFromTbPack,IIF(!lFromCz ,"T","Z") ,"P" ) .AND. c_rlib->route_stat <> "H" //vitaly "H" Status
     lFound := .T.
	  nRoute_id:=c_esnlnk->route_id
	  nRev := c_rlib->route_rev
	  nCount++
	ENDIF
	c_rlib->(dbskip(1))
  End
  if nCount > 1
	lFound := .F.
	cMessage := "Double " + IIF(lFromTbPack,"packing" ,"production" ) + " route"
	exit
  endif
  c_esnlnk->(dbskip(1))
End
SELECT ( nSelect )
c_rlib->(dbgotop())
c_esnlnk->(dbgotop())
IIF(Empty(cMessage) .AND. !lFound ,IIF(lFromTbPack,IIF(!lFromCz ,cMessage := "No IL packing route",cMessage := "No CZ packing route") ,cMessage := "No production route" ) ,nil )
RETURN IIF(lFound,{nRoute_id} ,{nil,cMessage} )
////////////////////////////////////
STATIC PROCEDURE CreateLine(cOrderDbf, lFromTbPack)

LOCAL cRouteFile := nRoute_id //GetList[15]:varGet()
LOCAL oTabRoute, oTabLineMv
LOCAL lFirstRecordInRoute
LOCAL mDate, mTime, mCP_WIDSTA
LOCAL cRouteDir := GetUserInfo():cRouteDir
Local nOldArea := Select()
default cOrderDbf to ""
default lFromTbPack to .F.

oTabRoute := TableTranslate():new( cRouteFile )
IF oTabRoute:xopen( cRouteDir )
ELSE
   Msg24( {"24" , cRouteFile } , 3 , .T. )
   RETURN
ENDIF

oTabLineMv := TableTranslate():new( "m_linemv" )
oTabLineMv:setIndexList()
IF oTabLineMv:xopen( )  // s.b. 19.5.97 remove exclusive // open exclusive
ELSE
   Msg24( {"25"} , 3 , .T. )
   RETURN
ENDIF

mDate := Date()
mTime := Left( Time() , 5 )
// update first proc in d_line
IF d_line->( RecLock( 5, "SCHED" ) )
   // when B/N in first proc
   d_line->cpproc_id := ( cRouteFile )->proc_id
   d_line->ppproc_id := ( cRouteFile )->proc_id
   d_line->pp_darr   := mDate
   d_line->pp_tarr   := mTime
   d_line->pp_dsta   := mDate
   d_line->pp_tsta   := mTime
   d_line->pp_dfin   := mDate
   d_line->pp_tfin   := mTime
   d_line->( DbUnLock() )
ENDIF
lFirstRecordInRoute := .T.
WHILE !( cRouteFile )->( Eof() )
      IF m_linemv->( AddRec(5, "sched") )
         m_linemv->B_ID       := d_line->B_ID
         m_linemv->ESN_ID     := d_line->ESN_ID
         m_linemv->B_TYPE     := d_line->B_TYPE
         m_linemv->PTYPE_ID   := d_line->PTYPE_ID
         m_linemv->PLINE_ID   := d_line->PLINE_ID
         m_linemv->SIZE_ID    := d_line->SIZE_ID
         m_linemv->VALUE_ID   := d_line->VALUE_ID
         m_linemv->VOLT_ID    := d_line->VOLT_ID
         m_linemv->TOL_ID     := d_line->TOL_ID
         m_linemv->TC_ID      := d_line->TC_ID
         m_linemv->TERM_ID    := d_line->TERM_ID
         m_linemv->TERM_ID    := d_line->TERM_ID
         m_linemv->ESNXX_ID   := d_line->ESNXX_ID
         m_linemv->ESNY_ID    := d_line->ESNY_ID
         m_linemv->DIEL_ID    := d_line->DIEL_ID
         m_linemv->DIEL_WIDTH := d_line->DIEL_WIDTH
         m_linemv->B_NCAPS    := d_line->B_NCAPS
         m_linemv->B_PURP     := d_line->B_PURP
         m_linemv->B_STAT     := d_line->B_STAT
         m_linemv->B_PRIOR    := d_line->B_PRIOR
         m_linemv->ROUTE_ID   := d_line->ROUTE_ID
         m_linemv->CP_STAGE   := ( cRouteFile )->STAGE
         m_linemv->CPPROC_ID  := ( cRouteFile )->PROC_ID
         m_linemv->PROC_SPEC  := ( cRouteFile )->PROC_SPEC
         m_linemv->I1         := ( cRouteFile )->I1
         m_linemv->I2         := ( cRouteFile )->I2
         m_linemv->I3         := ( cRouteFile )->I3
         IF c_proc->( DbSeek(  ( cRouteFile )->PROC_ID  ) )
            m_linemv->CP_PCCODE  := c_proc->PP_PCCODE
            m_linemv->CPWKSTN_ID := c_proc->WKSTN_ID
         ENDIF
         IF lFirstRecordInRoute
            m_linemv->arr       := .T.
            m_linemv->cp_darr   := mDate
            m_linemv->cp_tarr   := mTime
            m_linemv->CP_BQTYP  := d_line->CP_BQTYP
            m_linemv->CP_BQTYS  := d_line->CP_BQTYS
            m_linemv->CP_BQTYW  := d_line->CP_BQTYW
            IF d_line->( RecLock( 5, "SCHED" ) )
               d_line->CP_PCCODE  := c_proc->PP_PCCODE
               d_line->PP_PCCODE  := c_proc->PP_PCCODE
               d_line->CPWKSTN_ID := c_proc->WKSTN_ID
               d_line->PP_WKSTN   := c_proc->WKSTN_ID
               d_line->( xDbUnLock() )
            ENDIF
            lFirstRecordInRoute := !lFirstRecordInRoute
         ENDIF
      ENDIF
      ( cRouteFile )->( DbSkip() )
ENDDO
oTabRoute:close()
oTabLineMv:close()
IF d_line->( RecLock( 5, "SCHED" ) )
   d_line->ExpFinDate := batchCalc3("d_line")//02.07.2001 vr
	d_line->( xDbUnLock() )
ENDIF

IF q_line->( RecLock( 5, "SCHED" ) )
   q_line->ExpFinDate := d_line->ExpFinDate//02.07.2001 vr
	q_line->( DbUnLock() )
ENDIF
dbselectarea(nOldArea)
RETURN
////////////////////////////////////////////////////////////
Static Procedure UpdateDbfs(lFromBatchFile)   //4.3.7 in Sched Spec
Local nOldArea := Select()
Local aGlobalInfo := {}
Local nSlack,i,nPosDel
Local cSaveLine := SaveScreen( 2,0,2,79 )
FIELD poln_id
Local cPrevStat := " "
@ 21, 11 SAY "Updating tol. and batches' prom.date at prod.line"
dbselectarea("q_line")
d_prom->(ordsetfocus("iprombn"))
d_pcaud->(ordsetfocus("ipcaud"))
q_line->(dbgotop())
While !q_line->(EOF())
     aGlobalInfo := GetInfoArray()//{aDates,aRecNos,aGroups,aTols}
     IF !Empty(aGlobalInfo[3])
        ASORT(aGlobalInfo[1][val(aGlobalInfo[3][1])],,, { |x, y| x < y })
        if d_line->(RecLock( 5, "SCHED" ))
			  /*IF d_line->b_purp $ "_E_"
				  d_pcaud->(dbseek(d_line->b_id))
			     IF val(aGlobalInfo[3][1]) % 2 <> 0 .AND. d_pcaud->(found())//1,3,5
                 d_line->b_dprom := min(aGlobalInfo[1][val(aGlobalInfo[3][1])][1],d_line->b_dPROM)
              ELSEIF d_pcaud->(found())                                  //2,4,6
                 d_line->b_dprom := MoveShabos(min(max(aGlobalInfo[1][val(aGlobalInfo[3][1])][1],q_line->ExpFinDate),d_line->b_dPROM))
			     ELSEIF val(aGlobalInfo[3][1]) % 2 <> 0 .AND. !d_pcaud->(found())//1,3,5
                 d_line->b_dprom := aGlobalInfo[1][val(aGlobalInfo[3][1])][1]
              ELSEIF !d_pcaud->(found())                                  //2,4,6
                 d_line->b_dprom := MoveShabos(max(aGlobalInfo[1][val(aGlobalInfo[3][1])][1],q_line->ExpFinDate))
              ENDIF
			  ELSE*/
			     IF aGlobalInfo[3][1] $ "1_2_4_6_8"
                 d_line->b_dprom := aGlobalInfo[1][val(aGlobalInfo[3][1])][1]
              ELSE
                 d_line->b_dprom := MoveShabos(max(aGlobalInfo[1][val(aGlobalInfo[3][1])][1],q_line->ExpFinDate))
              ENDIF
			  //ENDIF
           D_LINE->B_WKPROM := SetWeekNo(d_line->b_dprom , TRUE )

           d_line->(xdbunlock())
		  endif//reclock


        FOR i := 1 TO Len (aGlobalInfo[2])
            d_prom->(dbgoto(aGlobalInfo[2][i][1]))
            IF d_prom->(RecLock( 5, "SCHED" ))
               IF aGlobalInfo[2][i][2] $ "1_2_4_6_8"
                  d_prom->prom_date := d_line->b_dprom
               ELSE
                  d_prom->prom_date := MoveShabos(Max(q_line->ExpFinDate,aGlobalInfo[2][i][3]))
               ENDIF
               d_prom->(dbunlock())
            ENDIF
        NEXT
        IF !d_line->b_stat $ "_T_R_C_D_M_B_E" .AND. !q_line->esny_id $ "_4_7_H_C_D_B_"//01.05.01
          if d_line->(RecLock( 5, "SCHED" ))
             IF aGlobalInfo[3][1] $ "_1_3"
					 UpStChange(d_line->b_stat," ","tapi_sch") //VR 14-10-02 ID 2931293
                d_line->b_stat  := " "
                IIF(d_line->b_prior <> "HO" ,d_line->b_prior := "LT" ,nil )
             ELSEIF aGlobalInfo[3][1] $ "_2_4"
					 UpStChange(d_line->b_stat,"F","tapi_sch")
					 d_line->b_stat  := "F"
					 iif(d_line->b_prior <> "HO",d_line->b_prior := "LT",nil) //VR 16.07.2002
             ELSEIF aGlobalInfo[3][1] $ "_5_"
					 UpStChange(d_line->b_stat,"P","tapi_sch")
					 d_line->b_stat  := "P"
					 iif(d_line->b_prior <> "HO",d_line->b_prior := "ZZ",nil) //VR 16.07.2002
             ELSEIF aGlobalInfo[3][1] $ "_6_"
					 UpStChange(d_line->b_stat,"S","tapi_sch")
					 d_line->b_stat  := "S"
					 iif(d_line->b_prior <> "HO",d_line->b_prior := "ZZ",nil) //VR 16.07.2002
             ENDIF
             d_line->(xdbunlock())
			 endif//reclock
        ELSEIF d_line->b_stat $ "_T_R_C_D_".AND. d_line->b_prior <> "HO" //23.01.01
          if d_line->(RecLock( 5, "SCHED" ))
             IF aGlobalInfo[3][1] $ "_1_3_5"
                d_line->b_prior := "LT"
             ELSEIF aGlobalInfo[3][1] $ "_2_5_6_"
					 d_line->b_prior := "ZZ"
             ENDIF
             d_line->(xdbunlock())
			 endif//reclock
        ENDIF
     ELSEIF !q_line->esny_id $ "_4_7_H_C_D_B_"
        IF !d_line->b_stat $ "_T_R_C_D_M_B_E" .AND. d_line->(RecLock( 5, "SCHED" ))//01.05.01
					UpStChange(d_line->b_stat,"O","tapi_sch")
					d_line->b_stat  := "O"
           d_line->(xdbunlock())
        ENDIF
        if d_line->(RecLock( 5, "SCHED" ))
           IIF(d_line->b_prior <> "HO" ,d_line->b_prior := "ZZ" ,NIL )
           d_line->(xdbunlock())
		  endif//reclock
		  IF d_Line->cpproc_id$"200.0_300.0_400.0" .AND. d_line->b_stat == "T" .AND. d_line->(RecLock( 5, "SCHED" ))
			  d_line->b_stat  := "C"
			  d_line->(xdbunlock())
		  ENDIF
     ENDIF
     IF Len(aGlobalInfo[4]) <> 0 .AND. d_line->ptype_id $ "C_L_" .AND. !d_line->b_purp $ "_8_5_" .AND. Empty(d_line->esn_p1)//split
        ASORT(aGlobalInfo[4],,, { |x, y| GetHie_2(x,"1","J") > GetHie_2(y,"1","J") })
		  IF D_ESN->(DBSEEK(IIF(d_line->ptype_id == "C" ,Stuff(d_line->esn_id,10,1,aGlobalInfo[4][1]) ,Stuff(d_line->esn_id,9,1,aGlobalInfo[4][1]) )))
		          if d_line->(RecLock( 5, "SCHED" ))
                   d_line->Tol_id := aGlobalInfo[4][1]
                   IIF(d_line->ptype_id == "C" ,d_line->esn_id := Stuff(d_line->esn_id,10,1,aGlobalInfo[4][1]) ,d_line->esn_id := Stuff(d_line->esn_id,9,1,aGlobalInfo[4][1]) )
	                d_line->(xdbunlock())
		          endif//reclock
                Dbselectarea("m_linemv")
                ordsetfocus("ilnmvbn")
                m_linemv->(dbseek(d_line->b_id))
                While !m_linemv->(eof()) .AND. m_linemv->b_id == d_line->b_id
                 if m_linemv->(RecLock(5,"SCHED"))
		    	   	 	   m_linemv->esn_id := d_line->esn_id
		    	   	 	   m_linemv->tol_id := d_line->tol_id
		    	   	 	   m_linemv->(dbunlock())
		    	     endif//reclock
		    	     m_linemv->(dbskip(1))
                End
		  ENDIF

	ENDIF
     q_line->(dbskip(1))
     aGlobalInfo := {}
End
NetUse( "t_avail",5, NIL, USE_EXCLUSIVE, USE_NEW,GetUserInfo():cTempDir )
While !EOF() .AND. !lFromBatchFile
	d_avail->(dbappend())
	FOR i := 1 TO FCount()
		  d_avail->(RLOCK())
		  d_avail->( FIELDPUT( i, t_avail->( FIELDGET(i) ) ) )
		  d_avail->(DBUNLOCK())
	NEXT
	t_avail->(dbskip())
End
DBSelectArea("t_avail")
DBCloseArea("t_avail")
DbSelectArea(nOldArea)
RestScreen(2,0,2,79,cSaveLine)
@ 21, 11 SAY "                                                    "
Return
///////////////////////////////////////////////////
Static Function GetInfoArray()

Local aDates := {{},{},{},{},{},{},{}}//six groups
Local aRecNos := {}//six groups
local aGroups := {}
Local aTols  := {}
Local aCust  := {}
LOCAL nRecNo := d_ord->(RecNo())
local nOrdNo := d_ord->(ordsetfocus())
d_ord->(DBCloseArea())
NetUse("d_ord",5)
d_ord->(ordsetfocus("ipolnoid"))
NetUse("d_ordreq",5)
d_ordreq->(ordsetfocus("ipoln_id"))
d_prom->(ordsetfocus("iprombn"))
d_prom->(dbseek(q_line->b_id))

While d_prom->b_id == q_line->b_id
					IF d_ordreq->(dbseek(str(d_prom->poln_id,9,2))) .AND. d_ordreq->poln_stat <> "K"
                     IF d_ordreq->poln_type $ " _4_R_"
                        aadd(aDates[3],d_ordreq->d_rqstdlv)
                        aadd(aRecNos, {d_prom->(recNo()),"3",d_ordreq->d_rqstdlv} )
                        aadd(aGroups,"3")
							ELSEIF d_ordreq->poln_type == "F"
								aadd(aDates[4],d_ordreq->d_rqstdlv)
								aadd(aRecNos, {d_prom->(recNo()),"4",d_ordreq->d_rqstdlv} )
								aadd(aGroups,"4")
                     ELSEIF d_ordreq->poln_type == "P"
                        aadd(aDates[5],d_ordreq->d_rqstdlv)
                        aadd(aRecNos, {d_prom->(recNo()),"5",d_ordreq->d_rqstdlv} )
                        aadd(aGroups,"5")
                     ELSE
                        aadd(aDates[6],d_ordreq->d_rqstdlv)
                        aadd(aRecNos, {d_prom->(recNo()),"6",d_ordreq->d_rqstdlv} )
                        aadd(aGroups,"6")
                     ENDIF
                     aadd(aTols,d_ordreq->tol_id)
                     aadd(aCust,IIF( "RO" $ d_ordreq->BILLAG_ID ,"R&S" ,IIF(d_ordreq->ENDCU_ID == " 1334" ,"TTI" ,SPACE(1)) ))
               ELSEIF d_ord->(dbseek(str(d_prom->poln_id,9,2))) .AND. d_ord->poln_stat <> "K"
                  IF d_ord->poln_type $ " _4_R_"
                     aadd(aDates[1],mrkorddue(.T.,"d_ord"))
                     aadd(aRecNos, {d_prom->(recNo()),"1",mrkorddue(.T.,"d_ord")} )
                     aadd(aGroups,"1")
                  ELSEIF d_ord->poln_type == "F"
                     aadd(aDates[2],mrkorddue(.T.,"d_ord"))
                     aadd(aRecNos, {d_prom->(recNo()),"2",mrkorddue(.T.,"d_ord")} )
                     aadd(aGroups,"2")
                  ELSEIF d_ord->poln_type == "P"
                     aadd(aDates[5],mrkorddue(.T.,"d_ord"))
                     aadd(aRecNos, {d_prom->(recNo()),"5",mrkorddue(.T.,"d_ord")} )
                     aadd(aGroups,"5")
                  ELSE
                     aadd(aDates[6],mrkorddue(.T.,"d_ord"))
                     aadd(aRecNos, {d_prom->(recNo()),"6",mrkorddue(.T.,"d_ord")} )
                     aadd(aGroups,"6")
                  ENDIF
                  aadd(aTols,d_ord->tol_id)
						aadd(aCust,IIF( "RO" $ d_ord->BILLAG_ID ,"R&S" ,IIF(d_ord->ENDCU_ID == " 1334" ,"TTI" ,SPACE(1)) ))
               ENDIF
			d_prom->(dbskip(1))
End
d_ord->(DBCloseArea())
d_ordreq->(DBCloseArea())
NetUse( "t_ord",5, NIL, USE_EXCLUSIVE, USE_NEW, GetUserInfo():cTempDir,"d_ord" )
ordsetfocus(nOrdNo)
dbgoto(nRecNo)
Return {aDates,aRecNos,ASORT(aGroups),aTols,aCust}
////////////////////////////////////////////////////
STATIC FUNCTION StoreMline(cPrevStat)

LOCAL cOldOrd, i
LOCAL nSelect := SELECT()
     IF SELECT("m_linemv") == 0
           genOpenFiles({"m_linemv"})
     ELSE
          SELECT ("m_linemv")
     ENDIF
     cOldOrd := m_linemv->( ORDSETFOCUS("ilnmvbn"))
     m_linemv->( DBSEEK(d_line->B_id+d_line->Cpproc_id))
     m_linemv->( ORDSETFOCUS("ilnmvbs"))
     m_linemv->(dbskip(-1))
     IF m_linemv->(RecLock(5,"sched"))
          m_linemv->B_stat     := cPrevStat
     ELSE
          ALERT("Unable to update previous stage")
     ENDIF
     m_linemv->(dbskip())
     WHILE m_linemv->b_id == d_line->B_id
          m_linemv->(RecLock(5,"sched"))
          m_linemv->B_purp := d_line->B_purp
          m_linemv->B_stat := d_line->B_stat
          m_linemv->( DBUNLOCK() )
          m_linemv->( DBSKIP() )
     END
     DBCOMMITALL()
     m_linemv->( ORDSETFOCUS(cOldOrd))
dbselectarea(nSelect)
RETURN NIL
///////////////////////////////////////////////////////////////////////////////
Static Function Packing(cFamily,nPending,cLoc)//4.3.4 in Sched Spec

Local nOldArea := Select()
Local aInfo := {}
Local lRetVal := .F.
Local aLimits := GetLimits(nPending)
Local lEntry := .F.
Local nCount := 0
Local nStartPos
Local cTestTol   := d_ord->tol_id
Local cNeededTol := d_ord->tol_id
Local cTc_id
Local cB_ncaps
Local aTestPack := {}
Field value_id,ptype_id,pline_id,size_id,tol_id,volt_id,tc_id,b_ncaps,b_id
NetUse("c_sbpbxx",5)
NetUse("c_value",5)
DbSelectArea("d_stock")
DBCLEARINDEX()
d_line->(ordsetfocus("ib_idln"))
Set Relation to b_id into d_line
//d_stock->(dbsetfilter({|| d_stock->LOC == cLoc .AND. !d_line->b_purp $ "8_5"}))
d_stock->(AX_SetServerAOF( 'd_stock->LOC == ['+cLoc+'] .AND. !d_line->b_purp $ [8_5]', .F. ))
@ 18,11 say "Open pack batches      " + cLoc
IF  d_ord->ptype_id $ "U_F" //packing batch for fuses and couplers 4.3.4.2/3 in Sched Spec
    IIF(d_ord->ptype_id == "U" ,d_stock->(ordsetfocus("IPCKBTCP")) ,d_stock->(ordsetfocus("IPCKBTCH")) )
	 nPending := StillPending() - AvailQty() + aLimits[1]
    IIF( d_ord->ptype_id == "U",d_stock->(dbseek(cFamily + STR(999999-nPending,7,0),.T.)) ,d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)+STR(999999-nPending,7,0),.T.) )  )
     WHILE  !EOF() .AND. IIF(d_ord->ptype_id == "U" ,ptype_id+pline_id+size_id == cFamily ,ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily+str(d_ord->value_id,9,3) ) //.AND. !lRetVal
	     nPending := StillPending() - AvailQty() + aLimits[1]
		  IIF(d_ord->ptype_id == "U" ,d_stock->(dbseek(cFamily+STR(999999-nPending,7,0),.T.) ) ,d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)+STR(999999-nPending,7,0),.T.) ) )
		  dbskip(-1)
		  IIF(BOF() .OR. IIF(d_ord->ptype_id == "U" ,ptype_id+pline_id+size_id <> cFamily ,ptype_id+pline_id+size_id+str(value_id,9,3) <> cFamily+str(d_ord->value_id,9,3) ) ,dbskip(1) ,nil ) //.OR. t_pack->b_id == d_stock->b_id

		  nStartPos := RecNo()

		  While !BOF() .AND. IIF(d_ord->ptype_id == "U" ,ptype_id+pline_id+size_id == cFamily ,ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily+str(d_ord->value_id,9,3) )
		      	IF !Substitution()
			      	DBSKIP(-1)
			      ELSE
				      lEntry := .T.
				      EXIT
			      ENDIF
		  End

		  IF !lEntry
			  dbgoto(nStartPos)

			  While !EOF() .AND. IIF(d_ord->ptype_id == "U" ,ptype_id+pline_id+size_id == cFamily ,ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily+str(d_ord->value_id,9,3) )
	         	IF !Substitution()
				      DBSKIP(1)
			      ELSE
				      lEntry := .T.
				      EXIT
			      ENDIF
		     End
		  ENDIF

		  IF lEntry .AND. !PreAriza(aLimits)  //
		    lRetVal := .T.
		    exit
	     Endif
		  lEntry := .F.
        @ 18,52 SAY d_stock->b_id
    END
///////////////////////////////////////////////////////////////////////////////////////////////////
ELSEIF  d_ord->ptype_id == "L" // packing batch for inductor 4.3.4.2/3 in Sched Spec
	 d_stock->(ordsetfocus("ipckbtlp"))
  While !Empty(cTestTol)
    WHILE !Empty(cNeededTol)
	 //nPending := StillPending() - AvailQty() + aLimits[1]
	 d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)+cNeededTol))//+STR(999999-nPending,7,0),.T.) )
	  WHILE  !EOF() .AND. ptype_id+pline_id+size_id+str(value_id,9,3) + Tol_id == cFamily+str(d_ord->value_id,9,3) + cNeededTol //.AND. !lRetVal
	     nPending := StillPending() - AvailQty() + aLimits[1]
		  d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)+cNeededTol+STR(999999-nPending,7,0),.T.) )
		  dbskip(-1)
		  IIF(BOF() .OR. ptype_id+pline_id+size_id+str(value_id,9,3) + tol_id <> cFamily+str(d_ord->value_id,9,3) + cNeededTol ,dbskip(1) ,nil ) //.OR. t_pack->b_id == d_stock->b_id

		   nStartPos := RecNo()

		  While !BOF() .AND. ptype_id+pline_id+size_id+str(value_id,9,3)+tol_id == cFamily+str(d_ord->value_id,9,3)+cNeededTol
		      	IF !Substitution()
			      	DBSKIP(-1)
			      ELSE//IF Substitution() .AND. ptype_id+pline_id+size_id+str(value_id,9,3)+tol_id == cFamily+str(d_ord->value_id,9,3)+cNeededTol
				      lEntry := .T.
				      EXIT
			      ENDIF
		  End

		  IF !lEntry
			  dbgoto(nStartPos)

			  While !EOF() .AND. ptype_id+pline_id+size_id+str(value_id,9,3)+tol_id == cFamily+str(d_ord->value_id,9,3)+cNeededTol
	         	IF !Substitution()
				      DBSKIP(1)
			      ELSE//IF Substitution() .AND. ptype_id+pline_id+size_id+str(value_id,9,3)+tol_id == cFamily+str(d_ord->value_id,9,3)+cNeededTol
				      lEntry := .T.
				      EXIT
			      ENDIF
		     End
		  ENDIF

		  IF lEntry .AND. !PreAriza(aLimits)  //
		    lRetVal := .T.
			 lEntry := .F.
			 exit
	     Endif
	   lEntry := .F.
	   @ 18,52 SAY d_stock->b_id
	  END
	  //cNeededTol := ChangeTol(cNeededTol)//move to other level
	  IF lRetVal .AND. SpecTestqty(AvailQty())
	  	  EXIT
	  ELSEIF t_pack->(lastrec()) == 3.AND. !SpecTestqty(AvailQty())
		  dbselectarea("t_pack")
		  CheckIndex("xxx",GetUserInfo():cTempDir+"fortpack","str(qty_needed)",.T.)
		  t_pack->(dbgotop())
		  d_stock->(ordsetfocus("bnesn_st"))
		  d_stock->(dbseek(t_pack->b_id+t_pack->esn_id+t_pack->loc))
		  IF d_stock->( RecLock(5,"sched") )
              d_stock->( FIELDPUT( d_stock->( FIELDPOS( t_pack->prom_wh )),FIELDGET( d_stock->( FIELDPOS( t_pack->prom_wh ) )) + t_pack->qty_needed))//d_stock->( FIELDGET( d_stock->( FIELDPOS( t_pack->prom_wh ) ) - t_pack->qty_needed ) ) ) ))
		        d_stock->( DBUNLOCK() )
	     ENDIF
		  t_pack->(dbdelete())
		  PACK
		  t_pack->(dbclearindex())
		  FERASE(GetUserInfo():cTempDir+"fortpack.cdx")
		  dbselectarea("d_stock")
		  ordsetfocus("ipckbtlp")
		  lRetVal := .F.
		  lCont := .T.
	  ENDIF
	  IF nCount == 3
	     nCount := 0
		  cNeededTol := ChangeTol(cNeededTol)//move to other level
	  ELSE
	     nCount++
	  ENDIF
	 END
   IF  !SpecTestqty(AvailQty())
    //dbselectarea("t_pack")
    DecWh()
    t_pack->(dbclearindex())
    FERASE(GetUserInfo():cTempDir+"fortpack.cdx")
    t_pack->( __DBZAP())
    dbselectarea("d_stock")
    ordsetfocus("ipckbtlp")
    lRetVal := .F.
    lCont := .F.
    cNeededTol := cTestTol := ChangeTol(cTestTol)
	 nCount := 0
	ELSE
    EXIT
   ENDIF
  END
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
ELSEIF  d_ord->ptype_id == "C"//packing batch for capacitor 4.3.4.2/3 in Sched Spec
	 d_stock->(ordsetfocus("ipckbtca"))
	 GetCombinations(cFamily+str(d_ord->value_id,9,3))
	 NetUse("T_Comby",STD_RETRY, ,USE_EXCLUSIVE,USE_NEW,GetUserInfo():cTempDir)
	 dbgotop()
	 dbselectarea("d_stock")
	 WHILE !t_comby->(EOF())//combination for tc & n_caps
	    cTc_id   := t_comby->tc_id
	    cB_ncaps := t_comby->b_ncaps

       While !Empty(cTestTol)
         WHILE !Empty(cNeededTol)
	            //nPending := StillPending() - AvailQty() + aLimits[1]
	            d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)+cNeededTol + cTc_id + cB_ncaps))//+STR(999999-nPending,7,0),.T.) )
	            WHILE  !EOF() .AND. ptype_id+pline_id+size_id+str(value_id,9,3) + Tol_id + Tc_id + UPPER(B_ncaps) == cFamily+str(d_ord->value_id,9,3) + cNeededTol + cTc_id + cB_nCaps//.AND. !lRetVal
	                   nPending := StillPending() - AvailQty() + aLimits[1]
		                d_stock->(dbseek(cFamily+str(d_ord->value_id,9,3)+cNeededTol + cTc_id + cB_ncaps + STR(999999-nPending,7,0),.T.) )
		                dbskip(-1)
		                IIF(BOF() .OR. ptype_id+pline_id+size_id+str(value_id,9,3) + Tol_id + Tc_id + UPPER(B_ncaps) <> cFamily+str(d_ord->value_id,9,3) + cNeededTol + cTc_id + cB_ncaps ,dbskip(1) ,nil ) //.OR. t_pack->b_id == d_stock->b_id

		                nStartPos := RecNo()

		                While !BOF() .AND. ptype_id+pline_id+size_id+str(value_id,9,3)+Tol_id + Tc_id + UPPER(B_ncaps) == cFamily+str(d_ord->value_id,9,3)+cNeededTol + cTc_id + cB_ncaps
		      	             IF !Substitution()
			      	             DBSKIP(-1)
			                   ELSE//IF Substitution() .AND. ptype_id+pline_id+size_id+str(value_id,9,3)+tol_id == cFamily+str(d_ord->value_id,9,3)+cNeededTol
				                   lEntry := .T.
				                   EXIT
			                   ENDIF
		                End

		                IF !lEntry
			                dbgoto(nStartPos)

			                While !EOF() .AND. ptype_id+pline_id+size_id+str(value_id,9,3)+Tol_id + Tc_id + UPPER(B_ncaps) == cFamily+str(d_ord->value_id,9,3)+cNeededTol + cTc_id + cB_ncaps
	         	                IF !Substitution()
				                      DBSKIP(1)
			                      ELSE//IF Substitution() .AND. ptype_id+pline_id+size_id+str(value_id,9,3)+tol_id == cFamily+str(d_ord->value_id,9,3)+cNeededTol
				                      lEntry := .T.
				                      EXIT
			                      ENDIF
		                   End
		                ENDIF

		                IF lEntry .AND. !PreAriza(aLimits)  //
		                   lRetVal := .T.
			                lEntry := .F.
			                exit
	                   Endif
	                   lEntry := .F.
	                   @ 18,52 SAY d_stock->b_id
	            END
	            //cNeededTol := ChangeTol(cNeededTol)//move to other level
	            IF lRetVal .AND. SpecTestqty(AvailQty())
	  	            EXIT
	            ELSEIF t_pack->(lastrec()) == 3.AND. !SpecTestqty(AvailQty())
		                dbselectarea("t_pack")
		                CheckIndex("xxx",GetUserInfo():cTempDir+"fortpack","str(qty_needed)",.T.)
		                t_pack->(dbgotop())
		                d_stock->(ordsetfocus("bnesn_st"))
		                d_stock->(dbseek(t_pack->b_id+t_pack->esn_id+t_pack->loc))
		                IF d_stock->( RecLock(5,"sched") )
                         d_stock->( FIELDPUT( d_stock->( FIELDPOS( t_pack->prom_wh )),FIELDGET( d_stock->( FIELDPOS( t_pack->prom_wh ) )) + t_pack->qty_needed))//d_stock->( FIELDGET( d_stock->( FIELDPOS( t_pack->prom_wh ) ) - t_pack->qty_needed ) ) ) ))
		                   d_stock->( DBUNLOCK() )
	                   ENDIF
		                t_pack->(dbdelete())
		                PACK
		                t_pack->(dbclearindex())
		                FERASE(GetUserInfo():cTempDir+"fortpack.cdx")
		                dbselectarea("d_stock")
		                ordsetfocus("ipckbtca")
		                lRetVal := .F.
		                lCont := .T.
	            ENDIF
					IF nCount == 3
						nCount := 0
						cNeededTol := ChangeTol(cNeededTol)//move to other level
					ELSE
						nCount++
					ENDIF
			END
         IF  !SpecTestqty(AvailQty())
             DecWh()
             t_pack->(dbclearindex())
             FERASE(GetUserInfo():cTempDir+"fortpack.cdx")
             t_pack->( __DBZAP())
             dbselectarea("d_stock")
             ordsetfocus("ipckbtca")
             lRetVal := .F.
             lCont := .F.
             cNeededTol := cTestTol := ChangeTol(cTestTol)
				 nCount := 0
	      ELSE
             EXIT
         ENDIF
       END


		 IF !SpecTestqty(AvailQty())
	       DecWh()
			 nCount := 0
		    t_pack->( __DBZAP())
		    lRetVal := .F.
		    lCont := .T.
			 d_stock->(ordsetfocus("ipckbtca"))
          cTestTol   := d_ord->tol_id
          cNeededTol := d_ord->tol_id
		 ELSE//IF lRetVal .AND. SpecTestqty(AvailQty())
	       EXIT
	    ENDIF
	    t_comby->(dbskip(1))
	 END
    t_comby->(dbclosearea())
ENDIF

IF( t_pack->(lastrec()) <> 0 .AND. SpecTestqty(AvailQty()))
//update involved files for packing batch 4.3.4.4 in Sched Spec
   IF d_ord->ptype_id $ "L_C_"
		aTestPack := CanMakeFaseTwo(GetPackValues("t_pack"),"d_ord")
	ELSEIF d_ord->ptype_id $ "_U_" .AND. d_ord->size_id == "0805"
		aTestPack := GetValues("t_pack","d_ord")
	ENDIF
   aInfo := GetPacking(aTestPack,cLoc)
   KeepP_2(aInfo)
   RealyPromise(aInfo)
ELSEIF  t_pack->(lastrec()) <> 0 .AND. TestQty(AvailQty()) == 0
	DecWh()
	lRetVal := .F.
ENDIF
lNoRoute := .F.
t_pack->( __DBZAP())
t_pcksav->( __DBZAP())
c_sbpbxx->(dbclosearea())
c_value->(dbclosearea())
DbSelectarea("d_stock")
Set Relation to
DbSelectarea(nOldArea)
//d_stock->(dbclearfilter())

AX_ClearServerAOF()

Return lRetVal
/////////////////////////////////////////////////////////////////////////////////////
Static Procedure GetCombinations(cFamily)
Local nOldArea := Select()
Field ptype_id,pline_id,size_id,value_id
NetUse("T_Comby",STD_RETRY, ,USE_EXCLUSIVE,USE_NEW,GetUserInfo():cTempDir)
FERASE(GetUserInfo():cTempDir+"t_cmb.cdx")
CheckIndex("t_comby",GetUserInfo():cTempDir+"t_cmb","tc_id+UPPER(b_ncaps)",.T.)
DbSelectArea("d_stock")
dbseek(cFamily)
While !EOF() .AND. ptype_id+pline_id+size_id+str(value_id,9,3) == cFamily
	IF !t_comby->(dbseek(d_stock->tc_id + UPPER(d_stock->b_ncaps)))
		t_comby->(dbappend())
		t_comby->tc_id   := d_stock->tc_id
		t_comby->b_ncaps := UPPER(d_stock->b_ncaps)
   ENDIF
	d_stock->(dbskip(1))
End
dbselectarea("t_comby")
dbclearindex()
dbclosearea("t_comby")
dbselectarea(nOldArea)
Return
/////////////////////////////////////////////////////////////////////////////////////
Static Function ChangeTol(cTol)
Local cRetVal
Local nOldArea := Select()
dbselectarea("c_tol")
ordsetfocus("c_ptol")
dbseek(d_ord->ptype_id+cTol)
ordsetfocus("c_pseq")
DbSkip(-1)
IF BOF() .OR. c_tol->ptype_id <> d_ord->ptype_id
	cRetVal := NIL
ELSE
	cRetVal := c_tol->tol_id
ENDIF
dbselectarea(nOldArea)
Return cRetVal
//////////////////////////////////////////////////////////////////////////////////////
Static Function CurrentLevel(cTol)
Local cRetVal
Local nOldArea := Select()
NetUse("c_tol",5)
ordsetfocus("c_ptol")
dbseek(d_ord->ptype_id+cTol)
cRetVal := c_tol->seq_no
dbclosearea("c_tol")
dbselectarea(nOldArea)
Return Val(cRetVal)
//////////////////////////////////////////////////////////////////////////////////////
Static Function Substitution()
LOCAL nOldArea := Select()
LOCAL cChosenDbf := "d_stock"
LOCAL cOrd := "d_ord"
LOCAL cOrderDbf :=  "d_ord"
local oProfile := StkValSub():new()//vitaly for matrix's
local cOrderEsn := d_ord->esn_id
local cChosenEsn := d_stock->esn_id
LOCAL lRetVal
local aValues := GetDTValues((cChosenDbf)->pline_id+(cChosenDbf)->size_id,cChosenDbf)
LOCAL lDT     := IfInDTRange(aValues,(cOrderDbf )->value_id)
lTestDbf := .F.
lTestFirst := .F.
lTestWhs := .F.
lSubstitutable := .F.
IIF(d_stock->wh1-FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id+(cChosenDbf)->LOC) > 0 .OR. d_stock->wh2-FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id) > 0,lTestwhs := .T.,lTestwhs := .F. )
////////////////////////////////////////MATRIX
IF  lTestwhs
 IF (cOrderDbf )->PTYPE_ID $ "_C_L"
     lSubstitutable := oProfile:GoodSubst(cOrderEsn,nil,cChosenEsn,NIL,.F.,.F.)
 ELSE
     lSubstitutable := .T.
 ENDIF
/////////////////////////////////////////////////FIRST TEST
if  ((cChosenDbf)->ptype_id+(cChosenDbf)->pline_id+(cChosenDbf)->size_id+STR((cChosenDbf)->value_id,9,3) == ;
    (cOrderDbf )->ptype_id+(cOrderDbf )->pline_id+(cOrderDbf )->size_id+STR((cOrderDbf )->value_id,9,3)) .OR. ;
    ((cChosenDbf)->ptype_id+(cChosenDbf)->pline_id+(cChosenDbf)->size_id == ;
    (cOrderDbf )->ptype_id+(cOrderDbf )->pline_id+(cOrderDbf )->size_id .AND. (cOrderDbf)->ptype_id == "U" .AND. !"DB" $ (cOrderDbf)->pline_id  .AND. ;
    ( ((cChosenDbf)->value_id >= (cOrderDbf )->value_id * 0.90 .AND. (cChosenDbf)->value_id <= (cOrderDbf )->value_id * 1.10) .AND. lDT  .OR. ((cChosenDbf)->value_id == 0.00 .AND. lDT) ))
    lTestFirst := .T.
endif
///////////////////////////////////////////////////ESNXX TABLE
IF (cOrderEsn <> cChosenEsn)
 IF ((cOrderDbf )->esnxx_id <> (cChosenDbf)->esnxx_id) .OR. ;
    ((cOrderDbf )->esnxx_id == (cChosenDbf)->esnxx_id .AND. (cOrderDbf )->ptype_id $ "_L_" .AND. (cOrderDbf )->esnxx_id $ "_00_22_31_")
   //NetUse("c_sbpbxx",5)
   IF (cOrderDbf )->ptype_id $ "_L_U_F"
    c_sbpbxx->(ordsetfocus("IXX"))
    c_sbpbxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
   ELSE
    c_sbpbxx->(ordsetfocus("INXX"))
    c_sbpbxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->pline_id+(cOrderDbf )->size_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
   ENDIF
   lTestDbf := c_sbpbxx->(found())
	//c_sbpbxx->(dbclosearea())
 ELSE
	 lTestDbf := .T.
 ENDIF
ELSEIF (cOrderDbf )->ptype_id $ "_L_" .AND. (cOrderDbf )->esnxx_id $ "_00_22_31_"
   //NetUse("c_sbpbxx",5)
   c_sbpbxx->(ordsetfocus("IXX"))
   c_sbpbxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
   lTestDbf := c_sbpbxx->(found())
	//c_sbpbxx->(dbclosearea())
ELSE
  lTestDbf := .T.
ENDIF

ENDIF
lRetVal := lTestwhs .AND. lSubstitutable .AND. lTestDbf .AND. lTestFirst
Dbselectarea(nOldArea)
Return lRetVal
//////////////////////////////////////////////////////////////////////////////////////
static function  PreAriza(aLimits)
LOCAL nOldArea := Select()
LOCAL nAvailQty := 0 , cTapiComment := Space( 60 )
LOCAL nPending , nQty := 0
LOCAL cStk := "d_stock"
LOCAL cChosenDbf := "d_stock"
LOCAL cOrd := "d_ord"
LOCAL cOrderDbf :=  "d_ord"
local cOrderEsn := d_ord->esn_id
local cChosenEsn := d_stock->esn_id
LOCAL lRetVal := .T.
LOCAL nHierrar,nRecNo,nOrder
LOCAL nMinimum := 0
LOCAL lNoPrint
IF !lCont
  t_pack->(  __dbzap()  )
  lNoRoute := .F.
ENDIF

 IF (cOrderEsn <> cChosenEsn)
  IF ((cOrderDbf )->esnxx_id <> (cChosenDbf)->esnxx_id) .OR. ;
	  ((cOrderDbf )->esnxx_id == (cChosenDbf)->esnxx_id .AND. (cOrderDbf )->ptype_id $ "_L_" .AND. (cOrderDbf )->esnxx_id $ "_00_22_31_")
	  //NetUse("c_sbpbxx",5)
     IF (cOrderDbf )->ptype_id $ "_L_F"
         c_sbpbxx->(ordsetfocus("IXX"))
         c_sbpbxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
     ELSEIF (cOrderDbf )->ptype_id $ "_U"
         c_sbpbxx->(ordsetfocus("indxx"))
         c_sbpbxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->size_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
	  ELSE
         c_sbpbxx->(ordsetfocus("INXX"))
         c_sbpbxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->pline_id+(cOrderDbf )->size_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
     ENDIF
     lNoPrint := c_sbpbxx->(found())
	  //c_sbpbxx->(dbclosearea())
  ELSE
	  lNoPrint := .F.
  ENDIF
 ELSEIF (cOrderDbf )->ptype_id $ "_L_" .AND. (cOrderDbf )->esnxx_id $ "_00_22_31_"
   //NetUse("c_sbpbxx",5)
   c_sbpbxx->(ordsetfocus("IXX"))
   c_sbpbxx->(dbseek((cOrderDbf )->ptype_id+(cOrderDbf )->esnxx_id+(cChosenDbf)->esnxx_id))
   lNoPrint := c_sbpbxx->(found())
   //c_sbpbxx->(dbclosearea())
 ELSE
  lNoPrint := .F.
 ENDIF
/////////////////////////////////////////////////////////////////
nPending := StillPending() - AvailQty() + aLimits[1]
IF  nPending > 0 .AND. T_PACK->(LASTREC()) < 10 //*.AND. lTestwhs .AND. lSubstitutable .AND. lTestDbf .AND. lTestFirst .AND. T_PACK->(LASTREC()) < 3
	 IF (cChosenDbf)->wh1 <> 0
        nAvailQty := (cChosenDbf)->wh1
    ELSE
        nAvailQty := (cChosenDbf)->wh2
    ENDIF
    nQty := iif( nPending>=nAvailQty - FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id+(cChosenDbf)->LOC) ,;
	 	           nAvailQty - FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id),;
					  IIF(nAvailQty - FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id) - nPending < 1000 ,nAvailQty - FrzStkQty((cChosenDbf)->b_id+(cChosenDbf)->esn_id+(cChosenDbf)->LOC) ,nPending  ))
    nRecNo := d_stock->(recno())
	 KeepP_1(nQty)//IIF(nAvailQty > nMinimum ,KeepP_1(nQty) , nil)
	 lNoRoute := lNoRoute .OR. lNoPrint
	 d_stock->(dbgoto(nRecNo))
	 lCont := .T.
ELSEIF nPending <= 0 .OR. T_PACK->(LASTREC()) == 10
	 lRetVal := .F.
      lCont := .F.
ENDIF
Dbselectarea(nOldArea)
Return lRetVal
/////////////////////////////////////////////////////////////////////
Static Function KeepP_1(nQty)

LOCAL cWh    := IIF(d_stock->wh1 <> 0 ,"WH1" ,"WH2" )
LOCAL nField := d_stock->( FIELDPOS( cWh ) )
LOCAL nBatch

IF t_pckSav->( LASTREC() ) == 0
   nBatch := 1
ELSE
  t_pcksav->( DBGOBOTTOM() )
  nBatch := t_pcksav->pack_batch + 1
ENDIF
// we've decided to actually remove promised stock from d_stock, and we'll
// return it if the user aborts the promise
IF d_stock->( RecLock(5,"sched") )
   d_stock->( FIELDPUT( nField,;
              d_stock->( FIELDGET( nField ) - nQty ) ) )
   d_stock->( DBUNLOCK() )

   IF t_pack->( AddRec(5) )
      t_pack->PORQ_ID    := d_ord->Poln_id
      // this field will get it's decimal later, when PROMLN is set (see above)
      t_pack->poln_id    := d_ord->poln_id
      t_pack->esn_id     := d_stock->esn_id
      t_pack->b_id       := d_stock->b_id
		t_pack->loc        := d_stock->loc
      t_pack->qty_needed := nQty
      t_pack->prom_src   := "S"
      t_pack->prom_wh    := cWh
      t_pack->from_packb := TRUE
      t_pack->pack_batch := nBatch
		t_pack->DIEL_ID    := d_stock->DIEL_ID
		t_pack->B_NCAPS    := d_stock->B_NCAPS
   ELSE
      ALERT("ERROR!;;Unable to store changes to;T_PACK.DBF.;Call MIS immediately.",{" OK "})
   END
ELSE
      ALERT("ERROR!;;Unable to store changes to;D_STOCK.DBF.;Try again in a moment.",{" OK "})
ENDIF

RETURN nil
////////////////////////////////
Static Function DecWh()
Local nOldArea := Select()
d_stock->(ordsetfocus("bnesn_st"))
t_pack->(dbgotop())
While !t_pack->(eof())
	IF d_stock->(dbseek(t_pack->b_id+t_pack->esn_id+t_pack->loc))
		IF d_stock->( RecLock(5,"sched") )
              d_stock->( FIELDPUT( d_stock->( FIELDPOS( t_pack->prom_wh )),FIELDGET( d_stock->( FIELDPOS( t_pack->prom_wh ) )) + t_pack->qty_needed))//d_stock->( FIELDGET( d_stock->( FIELDPOS( t_pack->prom_wh ) ) - t_pack->qty_needed ) ) ) ))
		d_stock->( DBUNLOCK() )
	   ENDIF
	ENDIF
	T_PACK->(DBSKIP(1))
End
DbSelectarea(nOldArea)
Return nil
//////////////////////////////////
Static Function KeepP_2(aPromise)

LOCAL i
LOCAL lSuccess := TRUE
LOCAL nBatchno
LOCAL nCount  := t_pack->( FCOUNT() )
LOCAL nTotal  := 0
LOCAL cPurp   := "8"

// keep track in case the user makes more than 1 packing batch in a session
t_pcksav->( DBGOBOTTOM() )
nBatchNo := t_pcksav->pack_batch + 1

// first, save the records in the sav file, for printing or restoring later
t_pack->( DBGOTOP() )
WHILE !t_pack->( EOF() )
      IF !t_pack->( DELETED() )
         t_pcksav->( DBAPPEND() )
         FOR i := 1 TO nCount
             t_pcksav->( FIELDPUT( i, t_pack->( FIELDGET(i) ) ) )
         NEXT
         t_pcksav->prom_src   := "P"
         t_pcksav->prom_stat  := "H"
         t_pcksav->prom_com1  := aPromise[PACK_COMMENT]
         t_pcksav->from_packb := TRUE
         t_pcksav->pack_batch := nBatchNo
         nTotal += t_pack->qty_needed
      END
      IF t_pack->prom_wh $ "WH3_WH4"
         cPurp := "5"
      ENDIF
      t_pack->( DBSKIP() )
END
// Now consolidate the packing batch into a promise record
t_prom->( DBAPPEND() )
t_prom->PROM_ID    := 0
t_prom->PORQ_ID    := d_ord->Poln_id

// fill this field ONLY when the user ok's the entire promise
// to avoid having to renumber at that time due to deletions
t_prom->PROMLN     := 0
// this field will get it's decimal later, when PROMLN is set (see above)
t_prom->poln_id    := d_ord->poln_id
t_prom->esn_id     := aPromise[PACK_ESN]
t_prom->b_id       := aPromise[PACK_B_ID]
t_prom->LOC        := t_pcksav->LOC
t_prom->qty_prom   := aPromise[PACK_QTY]
t_prom->qty_needed := nTotal
t_prom->prom_src   := "P"
t_prom->prom_date  := aPromise[PACK_DATE]
t_prom->prom_wh    := t_pack->prom_wh
t_prom->prom_stat  := "H"
t_prom->prom_com1  := aPromise[PACK_COMMENT]
t_prom->from_packb := TRUE  // t_pcksav->from_packb
t_prom->pack_batch := t_pcksav->pack_batch
t_prom->pack_route := aPromise[PACK_ROUTE]
t_prom->pack_prior := aPromise[PACK_PRIOR]
t_prom->Diel_id    := t_pcksav->Diel_id
t_prom->b_ncaps    := t_pcksav->b_ncaps
t_prom->b_purp     := cPurp
t_prom->b_stat     := aPromise[PACK_BSTAT]
RETURN lSuccess
///////////////////////////////////////////////////////////////////
Static Function AvailQty() //get availqty only in ariza

LOCAL nRec       := T_pack->( RECNO() )
LOCAL nAvailable := 0
t_pack->( DBGOTOP() )
WHILE !t_pack->( EOF() )
      nAvailable += t_pack->qty_needed
      t_pack->( DBSKIP() )
END
t_pack->( DBGOTO( nRec ) )
RETURN nAvailable
/////////////////////////////////////
Static function GetPacking(aTestPack,cLoc)
LOCAL NoldArea := Select()
LOCAL cDbf       := "d_ord" // needed for the OrdPending pseudofunction
LOCAL nAvailable := AvailQty()
LOCAL nPending   := OrdPending() + GetLimits(OrdPending())[1]
LOCAL cBid       := NextBNNo()
LOCAL cOrdfile   := "d_ord"
LOCAL cEsnId     := (cOrdFile)->esn_id
LOCAL aRound     := RoundDown( nAvailable, (cDbf)->esny_id )
LOCAL cComment   := (cDbf)->poln_mess1
LOCAL cPriority  := SPACE(2)
LOCAL cRoute     := SPACE(4)
LOCAL cNewRoute  := SPACE(4)
LOCAL cBstat     := "T"//IIF(lNoRoute,"T" , SPACE(1))
LOCAL cRouteRem  := SPACE(60)
LOCAL dOrdReq    := (cDbf)->d_rqstdlv
LOCAL dPromise   := SchOrdDue(.T.,'d_ord')//IF( t_pack->prom_wh == "WH3", DATE()+14, DATE()+7)
LOCAL nDivisor   := aRound[2] // needed for validation
LOCAL nPromise   := MIN( aRound[1], nPending )
// added 29-05-97
LOCAL cDiel      := SPACE(1)
LOCAL cCaps      := SPACE(2)
local aPromise := {}
IF( dOrdReq > dPromise, dPromise := dOrdReq, NIL )
IF nAvailable < GetLimits(aRound[1])[1] + aRound[1] .AND. !d_ord->esny_id $ "_4_7_H_C_D_"  //nPromise
	nPromise := nPromise - nDivisor
ELSEIF d_ord->esny_id $ "_4_7_H_C_D_"
	nPromise := d_ord->qty_ord
ENDIF
IIF(Select("c_esnlnk") == 0,NetUse("c_esnlnk",5) ,Dbselectarea("c_esnlnk") )
ordSetFocus( "ilnkesn" )
IIF( Select("c_rlib") == 0,NetUse("c_rlib",5),Dbselectarea("c_rlib") )
ordSetFocus( "irlibid" )
cRoute := GetRoute(cESNID,.T.,cLoc == "CZ")[1]

IF !Empty(aTestPack) .AND. aTestPack[1]
   cNewRoute := GetRoute(aTestPack[2],.T.,cLoc == "CZ")[1]
   IF !Empty(cNewRoute)
      cRoute := cNewRoute
      cEsnid := aTestPack[2]
   ENDIF
ENDIF

cPriority := "LT"
aPromise := { cBid, cRoute, cPriority, cRouteRem, nPromise, dPromise, cComment, nDivisor, cDiel, cCaps , cBstat,cEsnid}
dbclosearea("c_esnlnk")
dbselectarea(nOldArea)
RETURN aPromise
////////////////////////////////////////

Static Function UpdateAllBatches( nPackLn,aPromise )

LOCAL aPackData := {}
LOCAL oProm
LOCAL nOldArea := Select()
OpenBNMV(aPromise) // open batch & routeb in linemv
StockMovePack( nPackLn,aPromise[PACK_B_ID] )

PreparePackData(aPackData)
IF aPromise[PACK_BSTAT] == "T" .AND. m_stkmv->smtype_id $ "_25_"
	NetUse("T_Ro2upd",STD_RETRY, ,USE_EXCLUSIVE,USE_NEW,GetUserInfo():cTempDir)
	dbappend()
	T_Ro2upd->b_id         := Padl(aPromise[PACK_B_ID],9)
	T_Ro2upd->route_id     := aPromise[PACK_ROUTE]
	T_Ro2upd->b_dprom      := aPromise[PACK_DATE]
	T_Ro2upd->comments     := aPromise[PACK_COMMENT]
	dbclosearea("T_Ro2upd")
ELSEIF aPromise[PACK_BSTAT] <> "T"
	c_cust->(dbseek(d_ord->cu_id))
   PrintRouteCard( aPromise[PACK_B_ID],;
	             t_prom->pack_route,;
					 aPackData,;
					 TRUE ,;
					 NIL,,,,,,m_stkmv->LOC == "CZ",IIF(m_stkmv->LOC == "CZ" ,m_stkmv->smtype_id+AllTrim(m_stkmv->sm_refno) ,NIL )) //VR 12-04-02 ID:21281912
ENDIF

PackDoc()
dbselectarea(nOldArea)
RETURN aPromise[PACK_B_ID]
////////////////////////////////////////
Static procedure OpenBNMV(aPromise)

LOCAL cRouteDir := GetUserInfo():cRouteDir
LOCAL cRouting  := t_prom->pack_route
LOCAL lFirstRecordInRoute
LOCAL nSave1ST
LOCAL oTabRoute
LOCAL cBid
oTabRoute := TableTranslate():new( cRouting )
oTabRoute:xopen( cRouteDir )

cBid   := aPromise[PACK_B_ID] //NextBNNo()
// open route in m_linmv
lFirstRecordInRoute := .T.
WHILE !( cRouting )->( Eof() )
      IF m_linemv->( AddRec(5, "sched") )
         m_linemv->B_ID       := t_prom->b_id//cBid
         m_linemv->ESN_ID     := t_prom->esn_id//d_ord->esn_id
         IF d_esn->( DbSeek( t_prom->esn_id ) )
            m_linemv->PTYPE_ID   := d_esn->PTYPE_ID
            m_linemv->PLINE_ID   := d_esn->PLINE_ID
            m_linemv->SIZE_ID    := d_esn->SIZE_ID
            m_linemv->VALUE_ID   := d_esn->VALUE_ID
            m_linemv->VOLT_ID    := d_esn->VOLT_ID
            m_linemv->TOL_ID     := d_esn->TOL_ID
            m_linemv->TERM_ID    := d_esn->TERM_ID
            m_linemv->ESNXX_ID   := d_esn->ESNXX_ID
            m_linemv->ESNY_ID    := d_esn->ESNY_ID
            m_linemv->TC_ID      := d_esn->TC_ID
         ENDIF
         c_Btype->( ORDSETFOCUS("ilinesnx") )
         IF c_btype->( DbSeek( d_esn->PLINE_ID+d_esn->ESNXX_ID ) )
            m_linemv->B_TYPE := c_btype->B_TYPE
         ELSE
            m_linemv->B_TYPE := "?"
         ENDIF
         m_linemv->B_STAT     := t_prom->b_stat // New status added. Id.99080303
         m_linemv->B_PURP     := t_prom->b_purp //"8"   // for movement code "25"
         m_linemv->B_PRIOR    := t_prom->pack_prior
         m_linemv->ROUTE_ID   := cRouting
         m_linemv->CP_STAGE   := ( cRouting )->STAGE
         m_linemv->CPPROC_ID  := ( cRouting )->PROC_ID
         m_linemv->PROC_SPEC  := ( cRouting )->PROC_SPEC
         m_linemv->I1         := ( cRouting )->I1
         m_linemv->I2         := ( cRouting )->I2
         m_linemv->I3         := ( cRouting )->I3
			m_linemv->DIEL_ID    := t_prom->DIEL_ID
         IF c_proc->( DbSeek(  ( cRouting )->PROC_ID  ) )
            m_linemv->CP_PCCODE  := c_proc->PP_PCCODE
            m_linemv->CPWKSTN_ID := c_proc->WKSTN_ID
         ENDIF
         IF lFirstRecordInRoute
            nSave1ST  := m_linemv->( RecNo() )
            m_linemv->arr      := TRUE
            m_linemv->cp_darr  := Date()
            m_linemv->cp_tarr  := Left( Time() , 5 )
            // pcs
            m_linemv->CP_BQTYP := t_prom->qty_needed
            // str
            m_linemv->CP_BQTYS := qtyconvert(  m_linemv->cp_bqtyp ,;  //VR 2114110
                                               m_linemv->b_type  ,;
															  m_linemv->pline_id  ,;
                                               m_linemv->size_id,"P","S",,,m_linemv->route_id,m_linemv->value_id)
            // wfr
            m_linemv->CP_BQTYW := qtyconvert(  m_linemv->cp_bqtyp ,;
                                               m_linemv->b_type  ,;
															  m_linemv->pline_id  ,;
                                               m_linemv->size_id,"P","W",,,m_linemv->route_id,m_linemv->value_id)

            lFirstRecordInRoute := FALSE
         ENDIF
      ENDIF
      m_linemv->( DbUnLock() )
      ( cRouting )->( DbSkip() )
ENDDO
oTabRoute:close()
m_linemv->( DbGoTo( nSave1ST ) )
// open Batch
IF d_line->( AddRec( 5, "sched" ) )
   d_line->B_ID       := t_prom->b_id//cBid
   d_line->ESN_ID     := t_prom->esn_id//d_ord->esn_id
   d_line->B_TYPE     := m_linemv->B_TYPE
   d_line->PTYPE_ID   := d_esn->PTYPE_ID
   d_line->PLINE_ID   := d_esn->PLINE_ID
   d_line->SIZE_ID    := d_esn->SIZE_ID
   d_line->VALUE_ID   := d_esn->VALUE_ID
   d_line->TOL_ID     := d_esn->TOL_ID
   d_line->VOLT_ID    := d_esn->VOLT_ID
   d_line->TERM_ID    := d_esn->TERM_ID
   d_line->ESNXX_ID   := d_esn->ESNXX_ID
   d_line->ESNY_ID    := d_esn->ESNY_ID
   d_line->TC_ID      := d_esn->TC_ID
   d_line->B_DOPEN    := Date()
   d_line->QTY_BINI   := t_prom->qty_needed // actual quantity moved to line
   d_line->UOM_INI    := "P"
   d_line->ROUTE_ID   := cRouting
   d_line->B_PRIOR    := m_linemv->B_PRIOR
   d_line->B_DPROM    := t_prom->prom_date
   d_line->B_WKPROM   := SetWeekNo(t_prom->prom_date,TRUE)
   d_line->B_STAT     := m_linemv->B_STAT
   d_line->B_TYPE     := m_linemv->B_TYPE
   d_line->B_PURP     := m_linemv->B_PURP
   d_line->DIEL_ID    := t_prom->DIEL_ID
   d_line->B_NCAPS    := t_prom->B_NCAPS
   d_line->EXPQ_FCTR  := 1.0
   d_line->pp_darr    := m_linemv->cp_darr
   d_line->pp_tarr    := m_linemv->cp_tarr
   d_line->pp_dsta    := m_linemv->cp_dsta
   d_line->pp_tsta    := m_linemv->cp_tsta
   // change pp data, so report rpqc07v1 shows correct information
   // there's no previous process information at m_linemv
   // in this case pp date and time= the day and time the batch is opened.
   d_line->pp_dfin    := Date()
   d_line->pp_tfin    := Left( Time() ,5 )
   d_line->cp_dsta    := Date()
   d_line->cp_tsta    := Left( Time() , 5 )
   d_line->cp_dsta    := Date()
   d_line->cp_tsta    := Left( Time() , 5 )
   d_line->CP_BQTYP   := m_linemv->CP_BQTYP
   d_line->CP_BQTYS   := m_linemv->CP_BQTYS
   d_line->CP_BQTYW   := m_linemv->CP_BQTYW
   d_line->cpwkstn_id := m_linemv->CPWKSTN_ID
   d_line->cp_pccode  := m_linemv->CP_PCCODE
   d_line->cpproc_id  := m_linemv->CPPROC_ID
   d_line->( xDBUNLOCK() )
ENDIF

IF q_line->( AddRec( 5, "sched" ) )   //added batch to q_line also/13.11.2000
   q_line->B_ID       := t_prom->b_id//cBid
   q_line->ESN_ID     := t_prom->esn_id//d_ord->esn_id
   q_line->B_TYPE     := m_linemv->B_TYPE
   q_line->PTYPE_ID   := d_esn->PTYPE_ID
   q_line->PLINE_ID   := d_esn->PLINE_ID
   q_line->SIZE_ID    := d_esn->SIZE_ID
   q_line->VALUE_ID   := d_esn->VALUE_ID
   q_line->TOL_ID     := d_esn->TOL_ID
   q_line->VOLT_ID    := d_esn->VOLT_ID
   q_line->TERM_ID    := d_esn->TERM_ID
   q_line->ESNXX_ID   := d_esn->ESNXX_ID
   q_line->ESNY_ID    := d_esn->ESNY_ID
   q_line->TC_ID      := d_esn->TC_ID
   q_line->B_DOPEN    := Date()
   q_line->QTY_BINI   := t_prom->qty_needed // actual quantity moved to line
   q_line->UOM_INI    := "P"
   q_line->ROUTE_ID   := cRouting
   q_line->B_PRIOR    := m_linemv->B_PRIOR
   q_line->B_DPROM    := t_prom->prom_date
   q_line->B_WKPROM   := SetWeekNo(t_prom->prom_date,TRUE)
   q_line->B_STAT     := m_linemv->B_STAT
   q_line->B_TYPE     := m_linemv->B_TYPE
   q_line->B_PURP     := m_linemv->B_PURP
   q_line->DIEL_ID    := t_prom->DIEL_ID
   q_line->B_NCAPS    := t_prom->B_NCAPS
   q_line->EXPQ_FCTR  := 1.0
   q_line->pp_darr    := m_linemv->cp_darr
   q_line->pp_tarr    := m_linemv->cp_tarr
   q_line->pp_dsta    := m_linemv->cp_dsta
   q_line->pp_tsta    := m_linemv->cp_tsta
   q_line->pp_dfin    := Date()
   q_line->pp_tfin    := Left( Time() ,5 )
   q_line->cp_dsta    := Date()
   q_line->cp_tsta    := Left( Time() , 5 )
   q_line->cp_dsta    := Date()
   q_line->cp_tsta    := Left( Time() , 5 )
   q_line->CP_BQTYP   := m_linemv->CP_BQTYP
   q_line->CP_BQTYS   := m_linemv->CP_BQTYS
   q_line->CP_BQTYW   := m_linemv->CP_BQTYW
   q_line->cpwkstn_id := m_linemv->CPWKSTN_ID
   q_line->cp_pccode  := m_linemv->CP_PCCODE
   q_line->cpproc_id  := m_linemv->CPPROC_ID
   q_line->( DBUNLOCK() )
ENDIF
IF d_line->( RecLock( 5, "SCHED" ) )
   d_line->ExpFinDate := batchCalc3("d_line")//02.07.2001 vr
	d_line->( xDBUNLOCK() )
ENDIF
d_line->(dbcommit())
IF q_line->( RecLock( 5, "SCHED" ) )
   q_line->ExpFinDate := d_line->ExpFinDate//02.07.2001 vr
	q_line->( DBUNLOCK() )
ENDIF
RETURN
//////////////////////////
Static Function StockMovePack( nPackLn ,cBid)

LOCAL cOldOrd := d_stock->( ORDSETFOCUS("bnesn_st"))
LOCAL nPackBatch
LOCAL oSerNo  := TabBase():new( "n_serno" )
oSerNo:xopen()
t_pcksav->( DBGOTOP() )
IF t_pcksav->( DELETED() )
   WHILE t_pcksav->( DELETED() )
         t_pcksav->( DBSKIP() )
   END
ENDIF
nPackBatch := t_pcksav->Pack_batch
WHILE t_pcksav->pack_batch == nPackBatch .AND. ( !t_pcksav->( EOF() ) )
      IF ! d_stock->( DBSEEK( t_pcksav->b_id + t_prom->esn_id + t_prom->loc ) )
       // packing batch stock always goes to WH8 temporarily
        SetAlineValue({t_pcksav->b_id,,,,,,,,t_prom->ESN_ID,t_prom->LOC})
        AddRecToStock(t_prom->esn_id,"d_stock" )
      ENDIF
      Move2Wh8()
      m_stkmv->( AddMove(cBid) )
      d_pack->( AddPack( nPackLn++ ) )
      t_pcksav->( DBSKIP() )
END
oSerNo:close()
d_stock->(ordsetfocus(cOldOrd))
RETURN nil
//////////////////////////
Static Function Move2Wh8()

IF d_stock->( RecLock(5,"sched") )
   d_stock->wh8 += t_pcksav->qty_needed
   d_stock->( DBUNLOCK() )
END

RETURN nil

//////////////////////////////
Static Function AddMove(cBid)

LOCAL oCost , nCost

oCost := UnitCost():new( d_stock->ESN_ID )
IF oCost:nCostPerUnit = -1
   nCost := -1
ELSE
   nCost := oCost:nCostPerUnit*t_prom->qty_prom
ENDIF

UpdateMovements( IncSerNo()                  ,; // SM_SERNO
                   t_prom->prom_com1         ,; // SM_REM
                   Padl(cBid,9)              ,; // SM_REFNO
                   t_prom->porq_id           ,; // POLN_ID
                   t_pcksav->qty_needed      ,; // Source  SM_QTY
                   RIGHT(t_pcksav->Prom_wh,1),; // SRWH
                   "8"                       ,; // DSWH
                   "TBPACK"                  ,;
                   nCost                      ) // STDC

RETURN nil
//////////////////////////
Static Procedure UpdateMovements( pSM_SERNO,pSM_REM,pSM_REFNO,pPOLN_ID,pSM_QTY,;
                        pSRWH,pDSWH , cProc, nSTDC                   )

LOCAL nNonVal    := 0
LOCAL pSMTYPE_ID := "25"
LOCAL oEsn := PartBase():new()
oEsn:cEsn := t_pcksav->ESN_ID
oEsn:scattar("esn")
// need to open outside of this routine
IF m_stkmv->( AddRec( 5, "sched" ) )
   m_stkmv->SRB_ID     := t_pcksav->b_id  // source b_id
   m_stkmv->SRESN_ID   := t_pcksav->ESN_ID
   m_stkmv->SRESNXX_ID := IF( oEsn:cEsnNo                   == NIL, "", oEsn:cEsnNo                 )
   m_stkmv->SRESNY_ID  := IF( oEsn:cEsnPacking              == NIL, "", oEsn:cEsnPacking            )
   m_stkmv->SRPTYPE_ID := IF( oEsn:cPartType                == NIL, "", oEsn:cPartType              )
   m_stkmv->SRPLINE_ID := IF( oEsn:cProductLine             == NIL, "", oEsn:cProductLine           )
   m_stkmv->SRSIZE_ID  := IF( oEsn:cSize                    == NIL, "", oEsn:cSize                  )
   m_stkmv->SRVALUE_ID := IF( oEsn:nValue                   == NIL,  0, oEsn:nValue                 )
   m_stkmv->SRTOL_ID   := IF( oEsn:cTolerance               == NIL, "", oEsn:cTolerance             )
   m_stkmv->SRVOLT_ID  := IF( oEsn:cVoltage                 == NIL, "", oEsn:cVoltage               )
   m_stkmv->SRTC_ID    := IF( oEsn:cTemperatureCoefficient  == NIL, "", oEsn:cTemperatureCoefficient)
   m_stkmv->SRTERM_ID  := IF( oEsn:cTerminationCode         == NIL, "", oEsn:cTerminationCode       )
   m_stkmv->SRB_TYPE   := GetBTYPE( m_stkmv->SRPLINE_ID,m_stkmv->SRESNXX_ID )

   m_stkmv->SMTYPE_ID   := pSMTYPE_ID
   m_stkmv->SM_SERNO    := pSM_SERNO
   m_stkmv->SM_REM      := pSM_REM
   m_stkmv->SM_REFNO    := pSM_REFNO
   m_stkmv->POLN_ID     := pPOLN_ID
   m_stkmv->SM_QTY      := pSM_QTY
   m_stkmv->SRWH        := pSRWH
   m_stkmv->DSWH        := pDSWH
   m_stkmv->SM_STDC     := nSTDC
   oEsn:cEsn := t_prom->ESN_ID
   oEsn:scattar("esn")
   m_stkmv->DSESN_ID   := t_prom->ESN_ID
	m_stkmv->LOC        := t_prom->LOC
   m_stkmv->DSESNXX_ID := IF( oEsn:cEsnNo                   == NIL, "", oEsn:cEsnNo                 )
   m_stkmv->DSESNY_ID  := IF( oEsn:cEsnPacking              == NIL, "", oEsn:cEsnPacking            )
   m_stkmv->DSB_TYPE   := GetBTYPE( oEsn:cProductLine,oEsn:cEsnNo )
   m_stkmv->DSPTYPE_ID := IF( oEsn:cPartType                == NIL, "", oEsn:cPartType              )
   m_stkmv->DSPLINE_ID := IF( oEsn:cProductLine             == NIL, "", oEsn:cProductLine           )
   m_stkmv->DSSIZE_ID  := IF( oEsn:cSize                    == NIL, "", oEsn:cSize                  )
   m_stkmv->DSVALUE_ID := IF( oEsn:nValue                   == NIL,  0, oEsn:nValue                 )
   m_stkmv->DSTOL_ID   := IF( oEsn:cTolerance               == NIL, "", oEsn:cTolerance             )
   m_stkmv->DSVOLT_ID  := IF( oEsn:cVoltage                 == NIL, "", oEsn:cVoltage               )
   m_stkmv->DSTC_ID    := IF( oEsn:cTemperatureCoefficient  == NIL, "", oEsn:cTemperatureCoefficient)
   m_stkmv->DSTERM_ID  := IF( oEsn:cTerminationCode         == NIL, "", oEsn:cTerminationCode       )
   m_stkmv->TADD_REC    := Left( Time() , 5 )
   m_stkmv->( DbUnLock() )
ENDIF
RETURN
////////////////////////////
Static Function PreparePackData(aPackData)

LOCAL nBatch

t_pcksav->( DBGOTOP() )
IF t_pcksav->( DELETED() )
   WHILE t_pcksav->( DELETED() )
         t_pcksav->( DBSKIP() )
   END
ENDIF

nBatch := t_pcksav->pack_batch
WHILE t_pcksav->pack_batch == nBatch .AND. !t_pcksav->( EOF() )
      AADD( aPackData                 ,;
            {t_pcksav->b_id            ,;
             t_pcksav->esn_id          ,;
             RIGHT(t_pcksav->prom_wh,1),;
             "8"                     ,;
             t_pcksav->qty_needed      ,;
             0                       ,;
             t_pcksav->prom_com1       ,;
             0                        })
      t_pcksav->( DBSKIP() )
END

RETURN nil
/////////////////////////////////////////
Static Function PackDoc( lFrom )

LOCAL i
LOCAL aList           := {}
LOCAL aRound          := RoundDown( t_prom->qty_prom, d_ord->esny_id )
LOCAL nReels          := IF( aRound[2] > 1, t_prom->qty_prom/aRound[2], 0 )
LOCAL cBuffer
LOCAL cMsg
LOCAL cOrd            := d_esn->( ORDSETFOCUS("iesn_id") )
LOCAL nHowManyBatches := 0
LOCAL nPackBatch
LOCAL nQty2Pack       := 0
/*
ÚÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄ¿
³ ™˜”„³  “ƒ…’³  š…Ž‹³  š…Ž‹³‡ŽÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ‰˜…—Ž ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'‘Ž³
³     ³      ³„†˜€™³„‹‰™ŽŒ³‘³             ESN³ESN XX³€³     Š˜’³   „Ž³   ³
ÃÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄ´
³9,999³99,999³99,999³99,999³ 9³1234567890123456³      ³ ³        ³123456³123³
ÃÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÁÄÄÄÄÄÄÅÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄ´
³     ³      ³       99,999³  ³                ³      ³ ³        ³  ‹"„‘³   ³
ÀÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÙ
*/
// added next 2 lines 27/10/99 SS
IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
   Aadd( aList , Padr( "F-PW-05.02 :‘”…ˆ" ,80 ) )
   Aadd( aList , Padr( "        0 :…‹ƒ’" ,80 ) )
   AADD( aList , Padc( "Œ€˜™‰ ‘—€ ‰… ‰€" ,77 ) )
ELSE
   Aadd( aList , Space(5)+Padr( "Form: F-PW-05.02" ,80 ) )
   Aadd( aList , Space(5)+Padr( "Rev : 0" ,80 ) )
   AADD( aList , Padc( "AVX ISRAEL" ,77 ) )
ENDIF

AADD( aList , "" )
AADD( aList , "" )

IF  m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
  cBuffer := Left( Time(),5)+":„‘”ƒ„ š’™ "+ Dtoc( Date() )+":„‘”ƒ„ Š‰˜€š"
ELSE
  cBuffer := "Print Date: " + Dtoc(Date())+" Time: "+Left(Time(),5)
ENDIF

AADD( aList , Padl( cBuffer,77 ) )

IF  m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
  cBuffer := "y Š…šŽ x :'‘Ž —š…’"
ELSE
  cBuffer := Space(5)+"Copy x From y"
ENDIF

AADD( aList , IIF(m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I" ,Padl( cBuffer,77 ) ,Padr( cBuffer,77 ) ) )
AADD( aList , "" )
AADD( aList , "" )

IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
   cMsg    :=  "'‘Ž „†‰˜€ š€˜…„"
   cBuffer := m_stkmv->SMTYPE_ID +"/" + Alltrim(m_stkmv->sm_refno)+cMsg
ELSE
   cMsg    :=  "Packing Order No:"
   cBuffer :=  cMsg+Alltrim(m_stkmv->sm_refno)+"/"+m_stkmv->SMTYPE_ID
ENDIF
AADD( aList , Padc( cBuffer,77 ) )
AADD( aList , "" )
AADD( aList , "" )
cBuffer := TargetEsn()
AADD( aList , cBuffer )
AADD( aList , "" )
// information that can only exist in d_ord
AADD( aList , "" )
AADD( aList , "" )

IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
	AADD( aList , PADL( IF( nReels > 0, STR(nReels,4)+":‰Œ‰Œ‚ '‘Ž", SPACE(15) ) + TRANSFORM( t_prom->qty_prom, "9,999,999")+":†…˜€Œ š…Ž‹", 77 ) )
ELSE
	AADD( aList , PADR( IF( nReels > 0, Space(5)+"Quantity to Pack:" + TRANSFORM( t_prom->qty_prom, "9,999,999")+"  No. of reels:"+STR(nReels,4), SPACE(15) ), 77 ) )
ENDIF

AADD( aList , "" )
IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
	  AADD( aList,[ÚÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄ¿])
     AADD( aList,[³ ™˜”„³  “ƒ…’³  š…Ž‹³  š…Ž‹ ³‡ŽÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ‰˜…—Ž ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'‘Ž³])
     AADD( aList,[³     ³      ³„†˜€™³„‹‰™ŽŒ ³‘³             ESN³ESN XX³€³     Š˜’³   „Ž³   ³])
     AADD( aList,[ÃÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄ´])
     //           ....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,...
ELSE
	  AADD( aList,Space(5)+[ÚÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿])
     AADD( aList,Space(5)+[³ # ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄOriginalÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´WH³Withdrawn³Packed³Excess³Difference³])
     AADD( aList,Space(5)+[³   ³Batch ³ Value  ³T³ESN XX³       ESN      ³  ³Quantity ³ Qty  ³      ³          ³])
     AADD( aList,Space(5)+[ÃÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄ´])
ENDIF
//           ....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,...

t_pcksav->( DBGOTOP() )
IF t_pcksav->( DELETED() )
   WHILE t_pcksav->( DELETED() )
         t_pcksav->( DBSKIP() )
   END
END

nPackBatch := t_pcksav->Pack_batch
WHILE t_pcksav->pack_batch == nPackBatch .AND. ( !t_pcksav->( EOF() ) )
    // we need to get some info from d_esn
    d_esn->( DBSEEK( t_pcksav->esn_id ) )
    IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
	 AADD( aList , "³"+ SPACE(5) +;
                  "³"+ SPACE(6) +;
                  "³"+ SPACE(6) +;
                  "³"+ TRANSFORM(t_pcksav->qty_needed,"999,999")+;
                  "³"+ PADL(RIGHT( t_pcksav->prom_wh, 1 ), 2)  +;
                  "³"+ t_pcksav->esn_id                        +;
                  "³"+ padr(d_esn->Esnxx_id,6)                 +;
                  "³"+ d_esn->ptype_id                         +;
                  "³"+ STR(d_esn->value_id,9,3)                +;
                  "³"+ t_pcksav->b_id                          +;
                  "³"+ STR(++nHowManyBatches, 3 )              +"³" )
	 ELSE
	 AADD( aList , Space(5)+"³"+ STR(++nHowManyBatches, 3 )     +;
                  "³"+ t_pcksav->b_id                          +;
                  "³"+ STR(d_esn->value_id,9,3)                +;
                  "³"+ d_esn->ptype_id                         +;
                  "³"+ padr(d_esn->Esnxx_id,6)                 +;
                  "³"+ t_pcksav->esn_id                        +;
                  "³"+ PADL(RIGHT( t_pcksav->prom_wh, 1 ), 2)  +;
                  "³"+ "  "+TRANSFORM(t_pcksav->qty_needed,"999,999")+;
                  "³"+ SPACE(6)                                +;
                  "³"+ SPACE(6)                                +;
                  "³"+ SPACE(10)                               +"³" )
	 ENDIF
    nQty2Pack += t_pcksav->qty_needed

    // now delete this record, so if there is another batch,
    // it will get bypassed (see loop above)
    t_pcksav->( DBDELETE() )
    t_pcksav->( DBSKIP()   )
	 IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
       AADD( aList ,"ÃÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄ´" )
	 ELSE
       AADD( aList ,Space(5)+"ÃÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄ´" )
	 ENDIF
END

IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
   AADD( aList ,[³     ³      ³      ³]+TRANSFORM(nQty2Pack,"999,999")+;
                                            [³  ³                ³      ³ ³        ³  ‹"„‘³   ³] )
   AADD( aList ,"ÀÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÙ" )
ELSE
    AADD( aList ,Space(5)+[³   ³      ³        ³ ³      ³             Total:³]+"   "+TRANSFORM(nQty2Pack,"999,999")+;
                          [³      ³      ³          ³] )
    AADD( aList ,Space(5)+"ÀÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÙ" )

ENDIF
AADD( aList , "" )
AADD( aList , "" )
AADD( aList , "" )
AADD( aList , "" )
AADD( aList , "" )

IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
   AADD( aList ,  "    „Ž‰š‡      šŽš…‡/™        Š‰˜€š" )
   AADD( aList , "" )
   AADD( aList ,  "                                    :„†‰˜€ ’–Ž" )
   AADD( aList ,  "ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ" )
   AADD( aList ,  "                                    :‰ˆ˜‘ —ƒ…                     :†…‰„")
   AADD( aList ,  "ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ                ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ")
   AADD( aList ,  "                                    :....‰€‘‡Ž" )
   AADD( aList ,  "ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ" )
   AADD( aList ,  "                                    :..‰ˆ ˜—Ž" )
   AADD( aList ,  "ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ" )
ELSE
	AADD( aList ,  Space(5)+"Initiator:")
	AADD( aList ,  Space(5)+"          ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ")
	AADD( aList , "" )
	AADD( aList , "" )
	AADD( aList , "" )
   AADD( aList ,  Space(5)+"                  Date      Name/Stamp     Signature" )
   AADD( aList , "" )
   AADD( aList ,  Space(5)+"Packing Operator:                                    " )
   AADD( aList ,  Space(5)+"                 ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ" )
   AADD( aList ,  Space(5)+"Reels Inspector:                                     ")
   AADD( aList ,  Space(5)+"                 ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ")
   AADD( aList ,  Space(5)+"Storekeeper.....:                                    " )
   AADD( aList ,  Space(5)+"                 ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ" )
   AADD( aList ,  Space(5)+"Quality Control :                                    " )
   AADD( aList ,  Space(5)+"                 ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ" )
ENDIF

IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I" .AND. nHowManyBatches > 3
   AADD( aList , "" )
   AADD( aList ,  "                                    :š…Ž ™…Œ™Ž ˜š…‰ ™…Ž‰™Œ ˜…™‰€" )
   AADD( aList ,  "ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ" )
ELSEIF m_stkmv->LOC <> "IL" .AND. m_stkmv->LOC <> "2I" .AND. nHowManyBatches > 3
   AADD( aList , "" )
   AADD( aList ,  Space(5)+"Approval for using more from 3 batches:                                    " )
   AADD( aList ,  Space(5)+"                                       ÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄ   ÄÄÄÄÄÄÄÄÄÄ" )
ENDIF

SendToPrn(aList)

d_esn->( ORDSETFOCUS(cOrd) )

RETURN nil

/////////////////////////////////////
Static Function SendToPrn( aList )

LOCAL nCopiesPos , nCopyPos
LOCAL nCopies   , nCopy
LOCAL cPrnDir  := GetUserInfo():cPrnDir
LOCAL cPrnFile := m_stkmv->smtype_id+AllTrim(m_stkmv->sm_refno)


nCopiesPos := At( "y" , aList[5] )
nCopyPos   := At( "x" , aList[5] )

IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
   SET CONSOLE OFF
   SET PRINTER ON
ENDIF

nCopies := 1//InPutBox( "* No of copies ?" ,  1 , "99" , "Packing Document")

? prnSetup()
aList[5] := Stuff( aList[5] , nCopiesPos , 1 , Str( nCopies, 1 ) )

FOR nCopy := 1 TO nCopies

	 IF m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I"
	    SET PRINTER TO LPT1
	 ELSE
       SET PRINTER TO &(cPrnDir+cPrnFile+".txt")
	 ENDIF

	 aList[5] := Stuff( aList[5] , nCopyPos , 1 , Str( nCopy, 1 ) )
    Aeval( aList , {|cLine| Qout( cLine ) } )
    EJECT
NEXT

IF m_stkmv->LOC <> "IL" .AND. m_stkmv->LOC <> "2I"
   UpdatePrnFile(cPrnFile,m_stkmv->smtype_id)
ENDIF

SET PRINTER TO
SET PRINTER OFF
SET CONSOLE ON
?? prnReset()

RETURN nil
/////////////////////////////
Static Function AddPack( nPackLn )

IF d_pack->( AddRec(5) )
   d_pack->SM_SERNO   := m_stkmv->SM_SERNO
   d_pack->SM_REFNO   := m_stkmv->SM_REFNO
   d_pack->DSESN_ID   := t_prom->esn_id
   d_pack->N_REELS    := HowManyReels()
   d_pack->PACKLN     := nPackLn
   d_pack->( DbUnLock() )
ENDIF

RETURN nil

//////////////////////////////////
Static Function HowManyReels()

LOCAL nRet

c_esny->(  DBSEEK(d_ord->esny_id  ) )

IF c_esny->esny_qty == 0
   nRet := 0
ELSE
     IF t_prom->qty_needed % c_esny->esny_qty == 0
        nRet := int( t_prom->qty_needed / c_esny->esny_qty )
        ELSE
        nRet := int( t_prom->qty_needed / c_esny->esny_qty )+1
     ENDIF
END

RETURN nRet
/////////////////////////////
Static Function TargetEsn

LOCAL nSpace
LOCAL cDbf := "d_line"//problem with printing vr 15.07.2001

RETURN IIF(m_stkmv->LOC == "IL" .OR. m_stkmv->LOC == "2I",PADL( (cDbf)->esnxx_id                 + ":ESN (XX) "   +;
                                      TolNM( cDbf )                    + ":š…–‰”€ "     +;
                                      LTRIM(STR((cDbf)->value_id,9,3)) + ":Š˜’ "        +;
                                      ALLTRIM((cDbf)->esn_id)          + ":™—…Ž ESN" , 77 ),;
										  PADR(Space(5)+"Ordered ESN: " + ALLTRIM((cDbf)->esn_id) +;
                                     "  Value: "     + LTRIM(STR((cDbf)->value_id,9,3)) +;
                                     "  Tol: "       + TolNM( cDbf )                    +;
												 "  ESN (XX): "  + (cDbf)->esnxx_id               , 77 ) )

/*
 * ÚÄ Method ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
 * ³         Name: TolNM()                                                    ³
 * ³  Description:                                                            ³
 * ³       Author: Shalom LeVine                                              ³
 * ³ Date created: 05-01-97              Date updated: þ05-01-97              ³
 * ³ Time created: 10:51:54am            Time updated: þ10:51:54am            ³
 * ³    Copyright: AVX                                                        ³
 * ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
 * ³    Arguments: cTol                                                       ³
 * ³ Return Value: d_stock->tol_id+"(" + ALLTRIM( cTolNM ) + ")"              ³
 * ³     See Also:                                                            ³
 * ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
 */
Static Function TolNM( cDbf )

LOCAL cTolNM

cTolNM := ;
   RecElement( {|| c_tol->tol_id == (cDbf)->tol_id .AND.;
                   c_tol->ptype_id == (cDbf)->ptype_id .AND. ;
                   (cDbf)->value_id >= c_tol->lval_lim .AND. (cDbf)->value_id <= c_tol->hval_lim } ,;
                   {|| c_tol->tol_nm }, "c_tol", "c_tol" )

RETURN (cDbf)->tol_id+"(" + ALLTRIM( cTolNM ) + ")"
/////////////////////////////////
static function  GetnProc()
Return nProcFilter

static function  GetFamily()
Return aMyFamily
////////////////////////////////////////
static function  PenRep()

LOCAL cDbf        := "t_ord"
LOCAL nPending    := OrdPending()
LOCAL nOrdField   := (cDbf)->( FIELDPOS( "poln_id") )
LOCAL nPromField
LOCAL nOldArea := Select()
NetUse("d_prom",5)
ordsetfocus("iprompln")
nPromField  := d_prom->( FIELDPOS( "poln_id") )
   d_prom->( DBSEEK( STR( (cDbf)->( FIELDGET(nOrdField) ), 9, 2 ) ) )
   WHILE d_prom->( FIELDGET(nPromField) ) == (cDbf)->( FIELDGET(nOrdField) );
         .AND.  !d_prom->( EOF() )
         IF d_prom->prom_src == "P"
            nPending -= d_prom->qty_prom
         END
         d_prom->( DBSKIP() )
   END
d_prom->(dbclosearea())
dbselectarea(nOldArea)
RETURN nPending


Static Function PrepareGenDb(oRep,aFam)
Local nOldArea := Select()
LOCAL cDir := GetUserInfo():cTempDir
LOCAl aStruc := {}
Local i
Local aRetFam := {}
IF Select(oRep:cRepDbf) <> 0
   (oRep:cRepDbf)->(DbCloseArea())
ENDIF
NetUse( oRep:cPrepDbf,5, NIL, USE_EXCLUSIVE, USE_NEW, cDir,"d_ord" )
aStruc := d_ord->(dbstruct())
Aadd(aStruc,{"Sched_Group_Seq" ,"C",01,0})
Aadd(aStruc,{"Sched_source" ,"C",10,0})
DBCREATE( cDir + oRep:cRepDbf,aStruc, NIL )
NETUSE("D_ORDREQ",5)
NetUse( oRep:cRepDbf,5, NIL, USE_EXCLUSIVE, USE_NEW, cDir)
DbSelectArea("D_ord")
d_ordreq->(dbclearindex())
d_ord->(dbgotop())
d_ordreq->(dbgotop())
While !d_ord->(Eof()) .OR. !d_ordreq->(Eof())
      DbSelectArea("D_ord")
      IF !d_ord->(Eof())//copy d_ord to t_ord
         (oRep:cRepDbf)->(dbAppend())
         FOR i := 1 TO d_ord->( FCOUNT() )
             (oRep:cRepDbf)->( FIELDPUT( i, d_ord->( FIELDGET(i) ) ) )
         NEXT
         (oRep:cRepDbf)->Sched_source := "D_ORD"
         IF     d_ord->poln_type $ " _4_R_F"
          (oRep:cRepDbf)->Sched_Group_Seq := "A"
         ELSEIF d_ord->poln_type $ "P"
          (oRep:cRepDbf)->Sched_Group_Seq := "C"
         ELSEIF d_ord->poln_type $ "8"
          (oRep:cRepDbf)->Sched_Group_Seq := "E"
         ENDIF
         IF d_ord->ptype_id == "U" .AND. aScan(aRetFam,d_ord->ptype_id+d_ord->pline_id+d_ord->size_id) == 0
            AADD(aRetFam,d_ord->ptype_id+d_ord->pline_id+d_ord->size_id)
         ELSEIF d_ord->ptype_id <> "U" .AND. aScan(aRetFam,d_ord->ptype_id+d_ord->pline_id+d_ord->size_id+str(d_ord->value_id,9,3)) == 0
            AADD(aRetFam,d_ord->ptype_id+d_ord->pline_id+d_ord->size_id+str(d_ord->value_id,9,3))
         ENDIF
         d_ord->(dbskip(1))
      ENDIF

      d_ordreq->(dbselectarea())
      IF !d_ordreq->(Eof())//copy d_ordreq to t_ord
         IF InFam(aFam) .AND.;
            d_ordreq->poln_stat $ "_W_H_"           .AND. ;
           (d_ordreq->qty_ord-d_ordreq->qty_canc-d_ordreq->qty_shipd-d_ordreq->qty_alloc > 0)
            (oRep:cRepDbf)->(dbAppend())
            FOR i := 1 TO d_ordreq->( FCOUNT() )
             (oRep:cRepDbf)->( FIELDPUT( i, d_ordreq->( FIELDGET(i) ) ) )
            NEXT
            (oRep:cRepDbf)->Sched_source := "D_ORDREQ"
            IF     d_ordreq->poln_type $ " _4_R_F"
                  (oRep:cRepDbf)->Sched_Group_Seq := "B"
            ELSEIF d_ordreq->poln_type $ "P"
                  (oRep:cRepDbf)->Sched_Group_Seq := "D"
            ELSEIF d_ordreq->poln_type $ "8"
                  (oRep:cRepDbf)->Sched_Group_Seq := "F"
            ENDIF
            IF d_ordreq->ptype_id == "U" .AND. aScan(aRetFam,d_ordreq->ptype_id+d_ordreq->pline_id+d_ordreq->size_id) == 0
               AADD(aRetFam,d_ordreq->ptype_id+d_ordreq->pline_id+d_ordreq->size_id)
            ELSEIF d_ordreq->ptype_id <> "U" .AND. aScan(aRetFam,d_ordreq->ptype_id+d_ordreq->pline_id+d_ordreq->size_id+str(d_ordreq->value_id,9,3)) == 0
               AADD(aRetFam,d_ordreq->ptype_id+d_ordreq->pline_id+d_ordreq->size_id+str(d_ordreq->value_id,9,3))
            ENDIF
         ENDIF
         d_ordreq->(dbskip(1))
      ENDIF
End

(oRep:cRepDbf)->(DbCloseArea())
d_ordreq->(dbclosearea())
d_ord->(dbclosearea())
DbSelectArea(nOldArea)
oRep:cPrepDbf := oRep:cRepDbf
Return aRetFam

Static Function InFam(aFam)
local lRetval := IIF(!EMPTY(aFam[1]),d_ordreq->ptype_id  $ aFam[1],.T.) .AND.;
                 IIF(!EMPTY(aFam[2]),d_ordreq->pline_id  $ aFam[2],.T.) .AND.;
                 IIF(!EMPTY(aFam[3]),d_ordreq->size_id   $ aFam[3],.T.) .AND.;
                 IIF(!EMPTY(aFam[4]),str(d_ordreq->value_id,9,3)  $ aFam[4],.T.)
Return lRetVal

/////////////////////////////////////////////
FUNCTION SchOrdDue(lUseAlias,cDbf)  //VR revdue
*
*  removing poln_stat $ "Q_T" check since now d_mrkdlv only contains approved
*  mrk due date. d_mkrqdlv will contain requested mrk due date
*
LOCAL dRetVal := CTOD("  /  /  ")
FIELD d_mrkdlv, d_ackndlv ,d_rqstdlv,Sched_sour

DEFAULT lUseAlias to .F.
DEFAULT cDbf to ""

IF lUseAlias
   IF alltrim((cDbf)->Sched_sour) == "D_ORDREQ"
      dRetval := (cDbf)->d_rqstdlv
   ELSE
     dRetval  := MrkOrdDue(.T.,cDbf)
   ENDIF
ELSE
   IF alltrim(Sched_sour) == "D_ORDREQ"
      dRetval := D_rqstdlv
   ELSE
      dRetval  := MrkOrdDue(lUseAlias)
   ENDIF
ENDIF

RETURN dRetVal

Function Sched_tapi()
LOCAL aFiles
LOCAL aTitles
LOCAL aColumns
LOCAL cScr
LOCAL oWin

aFiles       := { "d_ordreq","d_line"  ,"d_stock" ,"d_prom"  ,;
                  "d_esn"   ,"c_cust"  ,"c_volt"  ,"c_thqty" ,;
                  "c_btype" ,"c_pline" ,"c_proc"  ,"c_expqty",;
                  "c_leadt" ,"c_postat","c_potype","c_esnxx" ,;
                  "c_esny"  ,"c_esnlnk","c_rlib"  ,"m_linemv",;
                  "m_stkmv" ,"d_pack"  ,"c_tol"   ,"d_ord"   ,;
                  "c_bpurp" ,"c_bstat" ,"c_curr"  ,"c_exrate",;
                  "h_finqc";
                }
aTitles  := { , , ,"Promises"}
aColumns := { , , ,{4,5,6,22,30,31}}
cScr := SAVESCREEN()
NetUse("c_cust",5)
ordsetfocus(1)
oWin := SchedBr():New( aFiles, aTitles, .T. , aColumns ,.F.)
oWin:Show()
c_cust->(dbclosearea())
RESTSCREEN(,,,,cScr)
Return nil

/////////////////////////////////////////////////////////////////////////
Procedure MakeRpqc01v1()//procedure for prepare file for rpqc01v1 report(14.03.2020)
LOCAL i, lFlag := FALSE
LOCAL aStruct
LOCAL cTempDir := GetUserInfo():cTempDir
Local nOldArea := Select()
Field value_id,ptype_id,pline_id,size_id,b_id
IIF(SELECT("d_line") == 0,GenOpenFiles({"d_line"}) ,NIL )
IIF(SELECT("d_prom") == 0,GenOpenFiles({"d_prom"}) ,NIL )
d_line->(ordsetfocus("ib_idln"))
D_prom->(ORDSETFOCUS(1))
SELECT "d_line"
SET RELATION  TO  B_id INTO D_prom
aStruct := D_LINE->(dbstruct())
ferase(cTempDir + "T_line01.dbf")
ferase(cTempDir + "T_line01.cdx")
DBCREATE( cTempDir + "T_line01", aStruct, "DBFCDXAX" )
NetUse( "T_line01", STD_RETRY, NIL, USE_EXCLUSIVE, USE_NEW, cTempDir )
d_line->(dbgotop())
WHILE !d_line->(EOF())
               IF  (d_line->b_stat $ "_T_M_B") .AND. ;
                   IIF(!EMPTY(GetBuffer("Product type")),d_line->ptype_id $ GetBuffer("Product type"),.T.) .AND. ;
                   IIF(!EMPTY(GetBuffer("Product line")),d_line->pline_id $ GetBuffer("Product line"),.T.) .AND. ;
                   IIF(!EMPTY(GetBuffer("Size")),d_line->size_id $ GetBuffer("Size"),.T.)                  .AND. ;
                   IIF(!EMPTY(GetBuffer("Value")), str(d_line->value_id,9,3) $ GetBuffer("Value"), .T. )   .AND. ;
						 D_prom->(found())
                    T_line01->(dbappend())
                    FOR i := 1 TO T_line01->( FCOUNT() )
                         T_line01->( FIELDPUT( i, d_line->( FIELDGET(i) ) ) )
                    NEXT
               ENDIF
               d_line->(dbskip())
END
SELECT T_line01
T_line01->(dbgotop())
T_line01->(dbclosearea())
DbSelectArea(nOldArea)
return
/////////////////////////////////////////////////////////////////////////