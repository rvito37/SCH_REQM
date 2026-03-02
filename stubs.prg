/*
 * stubs.prg - Compatibility layer for SCH_REQM Harbour migration
 * Based on PDC-clean/PDC/stubs.prg
 * Maps Clipper AX_* functions to Harbour rddads Ads* equivalents
 * Provides stubs for missing externals
 */

#include "common.ch"
#include "fileio.ch"

// Set Hebrew CP862 BEFORE Harbour GT initializes
INIT PROCEDURE SetHebCP862()
   SetConsoleCP862()
RETURN

// ============================================
// Advantage Database Server (AX_*) compatibility layer
// Maps old Clipper AX_* functions to Harbour rddads Ads* functions
// ============================================

#include "ads.ch"
#include "dbinfo.ch"
#include "ord.ch"

FUNCTION AX_ChooseOrdBagExt( cExt )
   HB_SYMBOL_UNUSED( cExt )
   AdsSetFileType( ADS_CDX )
RETURN .T.

FUNCTION AX_AutoOpen( lMode )
   HB_SYMBOL_UNUSED( lMode )
RETURN .T.

FUNCTION AX_RightsCheck( lMode )
RETURN AdsRightsCheck( hb_defaultValue( lMode, .T. ) )

FUNCTION AX_AppendFrom( cFile, cType )
   HB_SYMBOL_UNUSED( cType )
   __dbApp( cFile )
RETURN .T.

FUNCTION AX_TagName( nOrder )
RETURN OrdName( nOrder )

FUNCTION AX_TagNo()
RETURN OrdNumber()

FUNCTION AX_TagCount()
RETURN OrdCount()

FUNCTION AX_IndexCount()
RETURN OrdCount()

FUNCTION AX_IndexName( nOrder )
RETURN OrdName( nOrder )

FUNCTION AX_SetTag( cTag )
RETURN OrdSetFocus( cTag )

FUNCTION AX_Tags()
   LOCAL aResult := {}
   LOCAL i
   FOR i := 1 TO OrdCount()
      AAdd( aResult, OrdName( i ) )
   NEXT
RETURN aResult

FUNCTION AX_TagInfo()
   LOCAL aResult := {}
   LOCAL i
   FOR i := 1 TO OrdCount()
      AAdd( aResult, { OrdName( i ), OrdKey( i ), OrdFor( i ) } )
   NEXT
RETURN aResult

FUNCTION AX_Unlock()
RETURN DbUnlock()

FUNCTION AX_CopyTo( cFile )
RETURN AdsCopyTable( cFile )

FUNCTION AX_IsShared()
RETURN DbInfo( DBI_SHARED )

FUNCTION AX_KillTag( xTag, cBag )
   LOCAL i
   IF ValType( xTag ) == "L" .AND. xTag
      FOR i := OrdCount() TO 1 STEP -1
         OrdDestroy( OrdName( i ), cBag )
      NEXT
      RETURN .T.
   ENDIF
RETURN OrdDestroy( xTag, cBag )

FUNCTION AX_UserLockId( cAlias )
   HB_SYMBOL_UNUSED( cAlias )
RETURN 0

FUNCTION AX_AXSLocking( lMode )
RETURN AdsLocking( hb_defaultValue( lMode, .F. ) )

FUNCTION AX_IsFlocked( cAlias )
RETURN AdsIsTableLocked( cAlias )

FUNCTION AX_LockOwner( cFile, nType, nLock )
RETURN AdsMgGetLockOwner( cFile, nType, @nLock )

FUNCTION AX_Error()
   LOCAL nErr := 0
   AdsGetLastError( @nErr )
RETURN nErr

FUNCTION AX_CacheRecords( n )
RETURN AdsCacheRecords( n )

FUNCTION AX_SetServerAOF( cFilter, lResolve )
RETURN AdsSetAOF( cFilter, iif( hb_defaultValue( lResolve, .T. ), ADS_RESOLVE_IMMEDIATE, ADS_RESOLVE_DYNAMIC ) )

FUNCTION AX_ClearServerAOF()
RETURN AdsClearAOF()

FUNCTION AX_Loaded( cDrive )
RETURN ( AdsIsServerLoaded( hb_defaultValue( cDrive, "" ) ) > 0 )

FUNCTION AX_GetDrive( cPath )
RETURN Left( cPath, 2 )

FUNCTION AX_SetPass( cPassword )
   HB_SYMBOL_UNUSED( cPassword )
RETURN .T.

FUNCTION AX_Transaction( nAction )
   DO CASE
   CASE nAction == 1
      AdsBeginTransaction()
   CASE nAction == 2
      AdsCommitTransaction()
   CASE nAction == 3
      AdsRollback()
   ENDCASE
RETURN .T.

FUNCTION AX_SortOption( lUseCurrent )
   HB_SYMBOL_UNUSED( lUseCurrent )
RETURN .T.

FUNCTION AX_ExprEngine( lMode )
   HB_SYMBOL_UNUSED( lMode )
RETURN .T.

FUNCTION AX_SetScope( nScope, xValue )
   IF nScope == 0
      OrdScope( TOPSCOPE, xValue )
   ELSE
      OrdScope( BOTTOMSCOPE, xValue )
   ENDIF
RETURN .T.

FUNCTION AX_ClrScope( nScope )
   IF nScope == 0
      OrdScope( TOPSCOPE, NIL )
   ELSE
      OrdScope( BOTTOMSCOPE, NIL )
   ENDIF
RETURN .T.

FUNCTION AX_SetMemoBlock( nSize )
   HB_SYMBOL_UNUSED( nSize )
RETURN .T.

FUNCTION AX_SetExactKeyPos()
RETURN AdsSetExact( .T. )

// ============================================
// DBFCDXAX RDD - map to Harbour ADSCDX
// ============================================

FUNCTION DBFCDXAX()
RETURN "ADSCDX"

// ============================================
// Novell NetWare (fn_*) stubs
// ============================================

FUNCTION fn_eLptCap()
RETURN .T.

FUNCTION fn_fLptCap()
RETURN .T.

FUNCTION fn_IsNet()
RETURN 0

FUNCTION fn_StaAddr()
RETURN "000000000000"

FUNCTION fn_WhoAmI()
   LOCAL cUser := Upper( Alltrim( hb_CmdLine() ) )
   IF Empty( cUser )
      IF File( "c:\bmsname.txt" )
         cUser := Upper( Alltrim( MemoRead( "c:\bmsname.txt" ) ) )
      ENDIF
   ENDIF
   IF Empty( cUser )
      cUser := "USER"
   ENDIF
RETURN cUser

FUNCTION fn_RdProva()
RETURN ""

FUNCTION fn_ConnId()
RETURN 1

// ============================================
// LFN (Long File Names) stubs - native in Windows
// ============================================

FUNCTION LF_ChDir( cDir )
RETURN DirChange( cDir )

FUNCTION LF_ToLong( cFile )
RETURN cFile

FUNCTION LF_MemoRead( cFile )
RETURN MemoRead( cFile )

FUNCTION LF_GetFTime( cFile )
   HB_SYMBOL_UNUSED( cFile )
RETURN ""

FUNCTION LF_FCopy( cSrc, cDst )
RETURN hb_FCopy( cSrc, cDst )

FUNCTION LF_FErase( cFile )
RETURN FErase( cFile )

FUNCTION LF_RmDir( cDir )
RETURN DirRemove( cDir )

// ============================================
// Hebrew / display stubs
// ============================================

FUNCTION Heb_ChrC( n )
RETURN Chr( n )

FUNCTION MHeb_Toggle()
RETURN NIL

FUNCTION RDb_Inkey( nTimeout )
RETURN Inkey( nTimeout )

FUNCTION DispGet( o )
   HB_SYMBOL_UNUSED( o )
RETURN NIL

FUNCTION Relat_Pos()
RETURN 0

// ============================================
// R&R Reports stubs
// ============================================

FUNCTION rpNew()
RETURN NIL

FUNCTION rpCurDir()
RETURN hb_cwd()

FUNCTION rpDataPath()
RETURN ""

FUNCTION rpIndexPath()
RETURN ""

FUNCTION rpSwapPath()
RETURN ""

FUNCTION rpQuickLoad()
RETURN NIL

FUNCTION rpUseFonts()
RETURN NIL

FUNCTION rpQuerytBlock()
RETURN NIL

FUNCTION rpGetRDO()
RETURN NIL

FUNCTION rpDBTable()
RETURN NIL

FUNCTION rpMyDBOpen()
RETURN NIL

FUNCTION rpDBIndex()
RETURN NIL

FUNCTION rpDBKeyTBlock()
RETURN NIL

FUNCTION rpDestination()
RETURN NIL

FUNCTION rpPrinter()
RETURN NIL

FUNCTION rpOutFile()
RETURN ""

FUNCTION rpInitPCodes()
RETURN NIL

FUNCTION rpGenReport()
RETURN NIL

FUNCTION rpKillSorts()
RETURN NIL

FUNCTION rpCloseData()
RETURN NIL

FUNCTION rpLinePlace()
RETURN NIL

FUNCTION rpRFldNew()
RETURN NIL

FUNCTION rpLFieldNew()
RETURN NIL

FUNCTION rpRebuildDisp()
RETURN NIL

// ============================================
// Misc stubs
// ============================================

FUNCTION SwpRunCmd( cCmd )
RETURN hb_run( cCmd )

FUNCTION PaintRow( o )
   IF o != NIL
      o:refreshCurrent()
   ENDIF
RETURN NIL

FUNCTION Setcap()
RETURN NIL

FUNCTION NotCommas( n )
   LOCAL nReturn, cNewStr
   LOCAL nPoint := AT( ".", STR( n ) )
   cNewStr := SUBSTR( STR( n ), nPoint )
   IF VAL( "0" + cNewStr ) > 0
      nReturn := VAL( STR( INT( n ) + 1 ) + ".00" )
   ELSE
      nReturn := n
   ENDIF
RETURN nReturn

FUNCTION NLen( n )
   IF n == NIL ; RETURN 0 ; ENDIF
   IF ValType( n ) != "N" ; RETURN Len( hb_ValToStr( n ) ) ; ENDIF
RETURN Len( Str( n ) )

FUNCTION Win_Save( t, l, b, r )
RETURN SaveScreen( t, l, b, r )

FUNCTION Win_Rest( t, l, b, r, cScr )
   RestScreen( t, l, b, r, cScr )
RETURN NIL

FUNCTION aLen( a )
RETURN Len( a )

// HelpMe - F1 help stub
FUNCTION HelpMe()
RETURN NIL

// batchCalc3 - real implementation from BMS/DELIVSCH.PRG
FUNCTION batchCalc3( cName )
   LOCAL dRetVal := CToD( "  /  /  " )
   IF cName == NIL ; cName := "d_line" ; ENDIF
   dRetVal := Date() + LTime_NoRoute( cName ) + ;
      IIF( (cName)->esnxx_id $ "_0B_", 14 - GetIhur( cName ), ;
           IIF( (cName)->esnxx_id $ "_77_0G_", 7, 0 ) )
   IF (cName)->b_stat == "T"
      dRetVal := dRetVal + 1
   ENDIF
RETURN dRetVal

// LTime_NoRoute - real implementation from BMS/DELIVSCH.PRG
FUNCTION LTime_NoRoute( cAliasName )
   LOCAL nOldSelect, nOrder
   LOCAL nTempBID
   LOCAL nRetCount := 0.00
   LOCAL lWasOpened
   LOCAL lOpen_leadt := .F.
   LOCAL nMRecNo
   LOCAL nMorder
   IF cAliasName == NIL ; cAliasName := "d_line" ; ENDIF
   nOldSelect := SELECT()
   nOrder := INDEXORD()

   IF Select( "c_leadt" ) == 0
      GenOpenFiles( { "c_leadt" } )
      lOpen_leadt := .T.
   ENDIF

   IF Select( "m_linemv" ) == 0
      NetUse( "m_linemv", 5 )
      lWasOpened := .T.
   ELSE
      lWasOpened := .F.
      nMorder := m_linemv->( ordsetfocus( "ilnmvbn" ) )
      nMRecNo := m_linemv->( RecNo() )
   ENDIF

   c_leadt->( ORDSETFOCUS( "itcppr" ) )
   m_linemv->( ORDSETFOCUS( "ilnmvbn" ) )

   m_linemv->( DBSEEK( (cAliasName)->B_ID + (cAliasName)->CPPROC_ID ) )
   nTempBID := m_linemv->B_ID
   DBSELECTAREA( "m_linemv" )
   m_linemv->( ORDSETFOCUS( "ilnmvbs" ) )
   WHILE ! EOF() .AND. m_linemv->B_ID == nTempBID .AND. m_linemv->FIN
      m_linemv->( dbskip( 1 ) )
   END

   WHILE ! EOF() .AND. m_linemv->B_ID == nTempBID
      IF m_linemv->PTYPE_ID $ "U_K"
         c_leadt->( DBSEEK( m_linemv->PTYPE_ID + m_linemv->CPPROC_ID ) )
      ELSE
         c_leadt->( DBSEEK( m_linemv->PTYPE_ID + m_linemv->CPPROC_ID + m_linemv->PLINE_ID ) )
      ENDIF

      IF C_LEADT->( FOUND() )
         nRetCount := nRetCount + c_leadt->LEADT_DAYS
      ENDIF
      m_linemv->( DBSKIP() )
   END

   IF ! lWasOpened
      m_linemv->( ordsetfocus( nMorder ) )
      m_linemv->( dbgoto( nMRecNo ) )
   ELSE
      m_linemv->( dbclosearea() )
   ENDIF

   IF lOpen_leadt
      c_leadt->( dbclosearea() )
   ENDIF
   SELECT( nOldSelect )

RETURN NotCommas( nRetCount )

// GetIhur - helper for batchCalc3 (from BMS/DELIVSCH.PRG)
FUNCTION GetIhur( cName )
   LOCAL nMRecNo, nMorder, lWasOpened, nRet := 0

   IF Select( "m_linemv" ) == 0
      NetUse( "m_linemv", 5 )
      lWasOpened := .T.
   ELSE
      lWasOpened := .F.
   ENDIF
   nMRecNo := m_linemv->( RecNo() )
   nMorder := m_linemv->( ordsetfocus( "ilnmvbn" ) )
   IF ( m_linemv->( DBSEEK( (cName)->B_ID + "190.0" ) ) .OR. ;
        m_linemv->( DBSEEK( (cName)->B_ID + "190.5" ) ) ) .AND. ;
      m_linemv->ARR
      nRet := Date() - m_linemv->cp_darr
   ENDIF

   IF ! lWasOpened
      m_linemv->( ordsetfocus( nMorder ) )
      m_linemv->( dbgoto( nMRecNo ) )
   ELSE
      m_linemv->( dbclosearea() )
   ENDIF
RETURN nRet

FUNCTION MybatchCalc3( cName )
   LOCAL dRetVal
RETURN ( dRetVal := batchCalc3( cName ) )

// ScrollBox stub
FUNCTION ScrollBox()
RETURN NIL

// CanNotProcess stub
PROCEDURE CanNotProcess()
   Alert( "You do not have access to this program" )
RETURN

// HideAll stub
PROCEDURE HideAll()
RETURN

// ============================================
// BMS Framework function stubs
// These are placeholder implementations for functions from BMS/*.PRG and LIB/*.PRG
// Real implementations are in the source files listed in comments.
// Include the real .PRG files in sch_reqm.hbp as they become available.
// ============================================

// --- Network / Locking (real: BMS/LOCKS.PRG) ---

FUNCTION NetUse( cDataBase, nSeconds, cDriver, lOpenMode, lNewWorkArea, cDir, cAlias, lDirectory, cTag )
   LOCAL cFile, lResult
   DEFAULT nSeconds TO 5
   DEFAULT lOpenMode TO .F.     // .F. = shared
   DEFAULT lNewWorkArea TO .T.
   DEFAULT cDir TO ""
   DEFAULT cAlias TO cDataBase
   IF ! Empty( cDir )
      cFile := cDir + "/" + cDataBase
   ELSE
      cFile := cDataBase
   ENDIF
   BEGIN SEQUENCE
      IF lNewWorkArea
         dbUseArea( .T., , cFile, cAlias, lOpenMode )
      ELSE
         dbUseArea( .F., , cFile, cAlias, lOpenMode )
      ENDIF
      lResult := .T.
   RECOVER
      lResult := .F.
      LogWrite( "NetUse FAILED: " + cFile + " alias=" + cAlias )
   END SEQUENCE
RETURN lResult

FUNCTION RecLock( nSeconds, cProc, lUpdate )
   LOCAL lResult, i
   DEFAULT nSeconds TO 5
   DEFAULT cProc TO ""
   FOR i := 1 TO nSeconds * 2
      IF RLock()
         RETURN .T.
      ENDIF
      Inkey( 0.5 )
   NEXT
   LogWrite( "RecLock FAILED after " + LTrim( Str( nSeconds ) ) + "s, caller=" + cProc )
RETURN .F.

FUNCTION AddRec( nWaitSeconds, cCallingProc )
   LOCAL lResult, i
   DEFAULT nWaitSeconds TO 5
   DEFAULT cCallingProc TO ""
   FOR i := 1 TO nWaitSeconds * 2
      dbAppend()
      IF ! NetErr()
         RETURN .T.
      ENDIF
      Inkey( 0.5 )
   NEXT
   LogWrite( "AddRec FAILED after " + LTrim( Str( nWaitSeconds ) ) + "s, caller=" + cCallingProc )
RETURN .F.

FUNCTION FilLock( nSeconds )
   LOCAL i
   DEFAULT nSeconds TO 5
   FOR i := 1 TO nSeconds * 2
      IF FLock()
         RETURN .T.
      ENDIF
      Inkey( 0.5 )
   NEXT
RETURN .F.

// --- File Management (real: BMS/AVXUTI.PRG) ---

FUNCTION GenOpenFiles( aFileList, lMode )
   LOCAL i
   DEFAULT lMode TO .F.
   IF aFileList != NIL
      FOR i := 1 TO Len( aFileList )
         IF Select( aFileList[i] ) == 0
            NetUse( aFileList[i], 5, , lMode )
         ENDIF
      NEXT
   ENDIF
RETURN NIL

FUNCTION GenCloseFiles( aFileList )
   LOCAL i
   IF aFileList != NIL
      FOR i := 1 TO Len( aFileList )
         IF Select( aFileList[i] ) != 0
            ( aFileList[i] )->( dbCloseArea() )
         ENDIF
      NEXT
   ENDIF
RETURN NIL

// --- xDbUnLock (real: BMS/AVXFUNCS.PRG line 4270) ---

FUNCTION xDbUnLock( cDbf )
   IF cDbf != NIL .AND. Select( cDbf ) != 0
      ( cDbf )->( dbUnlock() )
   ELSE
      dbUnlock()
   ENDIF
RETURN NIL

// --- UI Functions ---

// Msg24 (real: BMS/LIB/MSGKEYS.PRG)
PROCEDURE Msg24( aMsg, nTime, lTone )
   LOCAL cScreen, cMsg
   DEFAULT nTime TO 0, lTone TO .F., aMsg TO ""
   IF ValType( aMsg ) == "A"
      cMsg := aMsg[1]
   ELSE
      cMsg := aMsg
   ENDIF
   IF nTime == 0
      cMsg := AllTrim( cMsg ) + " (Press any key...)"
   ENDIF
   cScreen := SaveScreen( 24, 0, 24, 79 )
   @ 24, 0 SAY PadC( cMsg, 80 ) COLOR "w+/r"
   IF lTone
      Tone( 300, 1 )
   ENDIF
   Inkey( nTime )
   RestScreen( 24, 0, 24, 79, cScreen )
RETURN

// MsgBox (real: BMS/AVXFUNCS.PRG line 1886)
FUNCTION MsgBox( cMsg )
   LOCAL cScr
   DEFAULT cMsg TO ""
   cScr := SaveScreen( 10, 20, 14, 60 )
   @ 10, 20, 14, 60 BOX "+-+|+-+| "
   @ 12, 22 SAY PadC( AllTrim( cMsg ), 36 )
   Inkey( 0 )
   RestScreen( 10, 20, 14, 60, cScr )
RETURN NIL

// SetHlpKeys (real: BMS/LIB/HLPKEYS.PRG)
FUNCTION SetHlpKeys( aKeyList )
   HB_SYMBOL_UNUSED( aKeyList )
RETURN {}

// TimeOutInKey (real: BMS/LIB/TOINKEY.PRG)
FUNCTION TimeOutInKey( nTimeOut )
   DEFAULT nTimeOut TO 0
RETURN Inkey( nTimeOut )

// SwitchTag (real: BMS/AVXFUNCS.PRG line 3981)
FUNCTION SwitchTag( cFileName, aCoord )
   HB_SYMBOL_UNUSED( cFileName )
   HB_SYMBOL_UNUSED( aCoord )
RETURN NIL

// StdKeys (real: BMS/LIB/STDKEYS.PRG)
FUNCTION StdKeys( nKey, oBjct )
   LOCAL lHandled := .F.
   DO CASE
   CASE nKey == 5   // K_UP
      oBjct:up()
      lHandled := .T.
   CASE nKey == 24  // K_DOWN
      oBjct:down()
      lHandled := .T.
   CASE nKey == 18  // K_PGUP
      oBjct:pageUp()
      lHandled := .T.
   CASE nKey == 3   // K_PGDN
      oBjct:pageDown()
      lHandled := .T.
   CASE nKey == 1   // K_HOME
      oBjct:goTop()
      lHandled := .T.
   CASE nKey == 6   // K_END
      oBjct:goBottom()
      lHandled := .T.
   CASE nKey == 4   // K_RIGHT
      oBjct:right()
      lHandled := .T.
   CASE nKey == 19  // K_LEFT
      oBjct:left()
      lHandled := .T.
   ENDCASE
RETURN lHandled

// Negative (real: BMS/AVXFUNCS.PRG line 1028)
FUNCTION Negative( o )
   IF o:varGet() < 0
      Msg24( "Negative value not allowed", 3, .T. )
      RETURN .T.
   ENDIF
RETURN .F.

// --- Classes ---

// TheReport (real: BMS/THEREPO.PRG)
#include "hbclass.ch"

CREATE CLASS TheReport
   VAR cName
   VAR cDesc
   VAR aSort
   VAR aExprSort
   VAR aFields
   VAR aTitles
   VAR aCrit
   VAR aBuffer
   VAR aCheck
   VAR aQueryBlocks
   VAR aDB
   VAR lSuperSmart
   VAR aSuperCriteria
   VAR aSuperIndexes
   VAR cRepDbf
   VAR cPrepDbf
   VAR cRepFileName
   VAR cbExtraCond
   VAR cbPrepDbf
   METHOD New( cName, cDesc )
   METHOD SetSort( a )      INLINE ::aSort := a
   METHOD SetExprSort( a )  INLINE ::aExprSort := a
   METHOD SetFields( a )    INLINE ::aFields := a
   METHOD SetTitles( a )    INLINE ::aTitles := a
   METHOD SetCrit( a )      INLINE ::aCrit := a
   METHOD SetBuffer( a )    INLINE ::aBuffer := a
   METHOD SetCheck( a )     INLINE ::aCheck := a
   METHOD SetQueryBlocks( a ) INLINE ::aQueryBlocks := a
   METHOD SetDB( a )        INLINE ::aDB := a
   METHOD Exec( lFlag )
END CLASS

METHOD New( cName, cDesc ) CLASS TheReport
   ::cName := cName
   ::cDesc := cDesc
   ::lSuperSmart := .F.
   LogWrite( "TheReport:New(" + cName + ")" )
RETURN Self

METHOD Exec( lFlag ) CLASS TheReport
   LOCAL lResult := .T.
   HB_SYMBOL_UNUSED( lFlag )
   LogWrite( "TheReport:Exec() - running PrepareDbf callback" )
   IF ::cbPrepDbf != NIL
      Eval( ::cbPrepDbf, Self )
   ENDIF
RETURN lResult

// GetUserInfo (real: BMS/AVXBMS.PRG line 406)
CREATE CLASS GetUserInfoClass
   VAR cTempDir
   VAR cUser
   METHOD New()
END CLASS

METHOD New() CLASS GetUserInfoClass
   ::cTempDir := hb_DirTemp() + "/"
   ::cUser := fn_WhoAmI()
RETURN Self

FUNCTION GetUserInfo()
   STATIC s_oInfo
   IF s_oInfo == NIL
      s_oInfo := GetUserInfoClass():New()
   ENDIF
RETURN s_oInfo

// Form (real: BMS/LIB/FORM.PRG)
CREATE CLASS Form
   VAR nTop
   VAR nLeft
   VAR nBottom
   VAR nRight
   VAR cTitle
   VAR cScr
   METHOD New( nTop, nLeft, nBottom, nRight, cTitle )
   METHOD Show()
   METHOD Hide()
END CLASS

METHOD New( nTop, nLeft, nBottom, nRight, cTitle ) CLASS Form
   DEFAULT nTop TO 5, nLeft TO 10, nBottom TO 20, nRight TO 70
   ::nTop := nTop
   ::nLeft := nLeft
   ::nBottom := nBottom
   ::nRight := nRight
   ::cTitle := cTitle
RETURN Self

METHOD Show() CLASS Form
   ::cScr := SaveScreen( ::nTop, ::nLeft, ::nBottom, ::nRight )
   @ ::nTop, ::nLeft, ::nBottom, ::nRight BOX "+-+|+-+| "
   IF ::cTitle != NIL
      @ ::nTop, ::nLeft + 2 SAY " " + ::cTitle + " "
   ENDIF
RETURN Self

METHOD Hide() CLASS Form
   IF ::cScr != NIL
      RestScreen( ::nTop, ::nLeft, ::nBottom, ::nRight, ::cScr )
   ENDIF
RETURN Self

// GetBuffer (real: BMS/PRNCRIT.PRG line 4453)
FUNCTION GetBuffer( cCode )
   HB_SYMBOL_UNUSED( cCode )
RETURN "all"

// critBrowse (real: BMS/PRNCRIT.PRG line 2877)
FUNCTION critBrowse( o, aParamList, cFile, cIndex, bKeyCol, bNameCol, bFilter )
   HB_SYMBOL_UNUSED( o )
   HB_SYMBOL_UNUSED( aParamList )
   HB_SYMBOL_UNUSED( cFile )
   HB_SYMBOL_UNUSED( cIndex )
   HB_SYMBOL_UNUSED( bKeyCol )
   HB_SYMBOL_UNUSED( bNameCol )
   HB_SYMBOL_UNUSED( bFilter )
RETURN "all"

// SchedBr (real: BMS/SCH_FORM.PRG)
CREATE CLASS SchedBr
   VAR oBro
   METHOD New()
END CLASS

METHOD New() CLASS SchedBr
RETURN Self

// CheckIndex (real: BMS/AVXUTI.PRG line 197)
FUNCTION CheckIndex( cAlias, cIndex, cKey, lReIndex, cFor, lUni )
   HB_SYMBOL_UNUSED( cAlias )
   HB_SYMBOL_UNUSED( cIndex )
   HB_SYMBOL_UNUSED( cKey )
   HB_SYMBOL_UNUSED( lReIndex )
   HB_SYMBOL_UNUSED( cFor )
   HB_SYMBOL_UNUSED( lUni )
RETURN .T.

// --- Business logic stubs ---

// StkValSub (real: BMS/RACC03V2.PRG line 1626 - complex class)
FUNCTION StkValSub()
RETURN 0

// GetDTValues (real: BMS/DELIVERY.PRG line 1192)
FUNCTION GetDTValues( cFam, cAlias )
   HB_SYMBOL_UNUSED( cFam )
   HB_SYMBOL_UNUSED( cAlias )
RETURN { 0, 0, 0 }

// IfInDTRange (real: BMS/DELIVERY.PRG line 1223)
FUNCTION IfInDTRange( aValues, nValue )
   HB_SYMBOL_UNUSED( aValues )
   HB_SYMBOL_UNUSED( nValue )
RETURN .T.

// GetHie_2 (real: BMS/SCH_ORDM.PRG line 953)
FUNCTION GetHie_2( tol_id, volt_id, tc_id )
   HB_SYMBOL_UNUSED( tol_id )
   HB_SYMBOL_UNUSED( volt_id )
   HB_SYMBOL_UNUSED( tc_id )
RETURN 0

// XSoftCopy (real: BMS/AVXUTI.PRG line 222)
FUNCTION XSoftCopy( cFields, cTargName, cWhileExp, cForExp, lSDF )
   HB_SYMBOL_UNUSED( cFields )
   HB_SYMBOL_UNUSED( cTargName )
   HB_SYMBOL_UNUSED( cWhileExp )
   HB_SYMBOL_UNUSED( cForExp )
   HB_SYMBOL_UNUSED( lSDF )
RETURN NIL

// SetWh (real: BMS/DELALLOC.PRG line 341)
FUNCTION SetWh( xWH )
   HB_SYMBOL_UNUSED( xWH )
RETURN NIL

// IfInside (real: BMS/SCH_ORDM.PRG line 1430)
FUNCTION IfInside()
RETURN .T.

// QtyConvert (real: BMS/QTYCON.PRG)
FUNCTION QtyConvert( nOrigQty, pBtype, pLineId, pSizeId, pOrigUom, pConvUom, lFromYieldrep, pPurp, cRoute, nValue )
   HB_SYMBOL_UNUSED( pBtype )
   HB_SYMBOL_UNUSED( pLineId )
   HB_SYMBOL_UNUSED( pSizeId )
   HB_SYMBOL_UNUSED( pOrigUom )
   HB_SYMBOL_UNUSED( pConvUom )
   HB_SYMBOL_UNUSED( lFromYieldrep )
   HB_SYMBOL_UNUSED( pPurp )
   HB_SYMBOL_UNUSED( cRoute )
   HB_SYMBOL_UNUSED( nValue )
RETURN nOrigQty

// AvailbleForAnyone (real: BMS/BTCHVIEW.PRG line 361)
FUNCTION AvailbleForAnyone( cDbf, cTol )
   HB_SYMBOL_UNUSED( cDbf )
   HB_SYMBOL_UNUSED( cTol )
RETURN .T.

// TestQty (real: BMS/SCH_ORDM.PRG line 1987)
FUNCTION TestQty( nQty )
   HB_SYMBOL_UNUSED( nQty )
RETURN .T.

// OrdReqPending (stub - no source found)
FUNCTION OrdReqPending()
RETURN 0

// OrdPending (stub - no source found)
FUNCTION OrdPending()
RETURN 0

// GetLimits (real: BMS/SCH_ORDM.PRG line 4267)
FUNCTION GetLimits( nQty )
   HB_SYMBOL_UNUSED( nQty )
RETURN { 0, 999999999 }

// TableTranslate (real: BMS/LIB/TABTRANS.PRG - class)
CREATE CLASS TableTranslate
   VAR cAlias
   METHOD New( cAlias )
   METHOD Translate( cValue ) INLINE cValue
END CLASS

METHOD New( cAlias ) CLASS TableTranslate
   ::cAlias := cAlias
RETURN Self

// FilLock already defined above

// MrkOrdDue (real: BMS/AVXFUNCS.PRG line 3048)
FUNCTION MrkOrdDue( lUseAlias, cDbf )
   HB_SYMBOL_UNUSED( lUseAlias )
   HB_SYMBOL_UNUSED( cDbf )
RETURN Date() + 30

// TabBase (real: BMS/LIB/TABBASE.PRG - class)
CREATE CLASS TabBase
   VAR cAlias
   METHOD New( cAlias )
END CLASS

METHOD New( cAlias ) CLASS TabBase
   ::cAlias := cAlias
RETURN Self

// SetRefCounter (real: BMS/DELALLOC.PRG line 749)
FUNCTION SetRefCounter( nCounter )
   HB_SYMBOL_UNUSED( nCounter )
RETURN NIL

// DelAlloc (real: BMS/DELALLOC.PRG line 74)
PROCEDURE DelAlloc( aPromiseLine, bWrite, lAllFromStock, xDbf, lFromTbProm, lStockOrder, cDir, cWhatFrom )
   HB_SYMBOL_UNUSED( aPromiseLine )
   HB_SYMBOL_UNUSED( bWrite )
   HB_SYMBOL_UNUSED( lAllFromStock )
   HB_SYMBOL_UNUSED( xDbf )
   HB_SYMBOL_UNUSED( lFromTbProm )
   HB_SYMBOL_UNUSED( lStockOrder )
   HB_SYMBOL_UNUSED( cDir )
   HB_SYMBOL_UNUSED( cWhatFrom )
   LogWrite( "STUB: DelAlloc called" )
RETURN

// OrdReqAllocate (real: BMS/DELALLOC.PRG line 128)
FUNCTION OrdReqAllocate()
   LogWrite( "STUB: OrdReqAllocate called" )
RETURN NIL

// DelNipuk (real: BMS/DELNIPUK.PRG)
PROCEDURE DelNipuk( cRefNo, cDbf, whereicamefrom )
   HB_SYMBOL_UNUSED( cRefNo )
   HB_SYMBOL_UNUSED( cDbf )
   HB_SYMBOL_UNUSED( whereicamefrom )
   LogWrite( "STUB: DelNipuk called" )
RETURN

// OpenState (stub - manages list of opened files)
FUNCTION OpenState( aoList )
   HB_SYMBOL_UNUSED( aoList )
RETURN .T.

// AvxCloseFiles (stub)
FUNCTION AvxCloseFiles()
   CLOSE ALL
RETURN NIL

// NextBNNo (real: BMS/OPENBTCH.PRG line 385)
FUNCTION NextBNNo()
   LogWrite( "STUB: NextBNNo called" )
RETURN "000000"

// PartBase (real: BMS/LIB/PARTBAS1.PRG - class)
CREATE CLASS PartBase
   VAR cPtype
   VAR cPline
   VAR cSize
   VAR cValue
   METHOD New()
END CLASS

METHOD New() CLASS PartBase
RETURN Self

// TestSubst (real: BMS/ORDGET.PRG line 3003)
FUNCTION TestSubst( cVoltSource, cVoltTarget )
   HB_SYMBOL_UNUSED( cVoltSource )
   HB_SYMBOL_UNUSED( cVoltTarget )
RETURN .T.

// GetBtype (real: BMS/AVXFUNCS.PRG line 1429)
// NOTE: there are multiple versions; this is a stub
FUNCTION GetBtype( pPLINE_ID, pESNXX_ID )
   HB_SYMBOL_UNUSED( pPLINE_ID )
   HB_SYMBOL_UNUSED( pESNXX_ID )
RETURN "1"

// SetWeekNo (real: BMS/OPENBTCH.PRG line 1741)
FUNCTION SetWeekNo( dDate, lReturnYearAndWeek, lReturnCentury )
   LOCAL cWeek
   DEFAULT dDate TO Date()
   HB_SYMBOL_UNUSED( lReturnYearAndWeek )
   HB_SYMBOL_UNUSED( lReturnCentury )
   cWeek := PadL( LTrim( Str( hb_Week( dDate ) ) ), 2, "0" )
RETURN cWeek

// xDbUnLock already defined above - remove duplicate if present

// UpStChange (real: BMS/BTCHVIEW.PRG line 1009)
PROCEDURE UpStChange( cPrevStat, cCurStat, cProg_id, cPrevRemark )
   HB_SYMBOL_UNUSED( cPrevStat )
   HB_SYMBOL_UNUSED( cCurStat )
   HB_SYMBOL_UNUSED( cProg_id )
   HB_SYMBOL_UNUSED( cPrevRemark )
   LogWrite( "STUB: UpStChange called" )
RETURN

// CanMakeFaseTwo (real: BMS/TBPACK.PRG line 244)
FUNCTION CanMakeFaseTwo( aValues, cOrdFile )
   HB_SYMBOL_UNUSED( aValues )
   HB_SYMBOL_UNUSED( cOrdFile )
RETURN .T.

// GetPackValues (real: BMS/TBPACK.PRG line 344)
FUNCTION GetPackValues( cTempFile )
   HB_SYMBOL_UNUSED( cTempFile )
RETURN {}

// GetValues (real: BMS/TBPACK.PRG line 380)
FUNCTION GetValues( cTempFile, cOrdFile )
   HB_SYMBOL_UNUSED( cTempFile )
   HB_SYMBOL_UNUSED( cOrdFile )
RETURN {}

// RoundDown (real: BMS/AVXFUNCS.PRG line 2406)
FUNCTION RoundDown( nSource, cEsnY )
   HB_SYMBOL_UNUSED( cEsnY )
RETURN Int( nSource )

// PrintRouteCard (real: BMS/ROUTE2PR.PRG)
PROCEDURE PrintRouteCard( cBNparam )
   HB_SYMBOL_UNUSED( cBNparam )
   LogWrite( "STUB: PrintRouteCard called" )
RETURN

// SetALineValue (stub - no source found)
FUNCTION SetALineValue()
   LogWrite( "STUB: SetALineValue called" )
RETURN NIL

// AddRecToStock (real: BMS/DELALLOC.PRG line 378)
PROCEDURE AddRecToStock( cEsn, cMyDBF )
   HB_SYMBOL_UNUSED( cEsn )
   HB_SYMBOL_UNUSED( cMyDBF )
   LogWrite( "STUB: AddRecToStock called" )
RETURN

// UnitCost (real: BMS/UNITCOST.PRG - class, inherits TabBase)
CREATE CLASS UnitCost FROM TabBase
   VAR nCost
   VAR cEsn
   METHOD New( cEsn )
   METHOD GetCost() INLINE ::nCost
END CLASS

METHOD New( cEsn ) CLASS UnitCost
   ::Super:New( "c_value" )
   ::cEsn := cEsn
   ::nCost := 0
RETURN Self

// IncSerNo (real: BMS/AVXFUNCS.PRG line 918)
FUNCTION IncSerNo()
   LogWrite( "STUB: IncSerNo called" )
RETURN ""

// prnSetup / prnReset (real: BMS/AVXBMS.PRG)
FUNCTION prnSetup()
RETURN ""

FUNCTION prnReset()
RETURN ""

// UpdatePrnFile (real: BMS/AVXFUNCS.PRG line 4254)
PROCEDURE UpdatePrnFile( cPrnFile, cMoveType )
   HB_SYMBOL_UNUSED( cPrnFile )
   HB_SYMBOL_UNUSED( cMoveType )
RETURN

// RecElement (real: BMS/AVXFUNCS.PRG line 1301)
FUNCTION RecElement( uCode, bRetBlock, cAlias, cIndex )
   HB_SYMBOL_UNUSED( uCode )
   HB_SYMBOL_UNUSED( bRetBlock )
   HB_SYMBOL_UNUSED( cAlias )
   HB_SYMBOL_UNUSED( cIndex )
RETURN ""

// GetDefPrn (real: BMS/AVXBMS.PRG line 643)
FUNCTION GetDefPrn()
RETURN "LPT1"

// GetRec (real: BMS/SCH_ORDM.PRG line 584)
FUNCTION GetRec( aPos )
   HB_SYMBOL_UNUSED( aPos )
RETURN NIL

// TestAvail (real: BMS/SCH_ORDM.PRG line 1700)
FUNCTION TestAvail()
RETURN .T.
