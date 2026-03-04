/*
 * stubs.prg - Compatibility layer for SCH_REQM Harbour migration
 * Based on PDC-clean/PDC/stubs.prg
 * Maps Clipper AX_* functions to Harbour rddads Ads* equivalents
 * Provides stubs for missing externals
 */

#include "avxdefs.ch"

// ============================================
// ALL STATIC declarations must be at file top in Harbour
// ============================================

// Screen push/pop stack
STATIC aScrnStack := {}

// PrnFace state (from PRNFACE.PRG)
STATIC aSort_pf, aCut_pf, aCutDefault_pf
STATIC aCutIndicators_pf
STATIC cSortType_pf
STATIC cDeviceType_pf
STATIC aCheckBlocks_pf
STATIC cUserMsg_pf
STATIC nDevices_pf := 1

// Criteria buffers (from PRNCRIT.PRG)
STATIC cProductType_pf
STATIC cProductLine_pf
STATIC cSize_pf
STATIC cValue_pf
STATIC cPurpose_pf
STATIC cBstat_pf
STATIC cESNXX_pf
STATIC cBuffer_pf
STATIC aRecNos_pf
STATIC oBro_pf

// ============================================

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
RETURN "ADS"

// GetMyDriver (real: BMS/BMSBAR.PRG line 2372)
// Must return "ADS" — production uses rddsetdefault("ADS") + SET FILETYPE TO CDX
FUNCTION GetMyDriver()
RETURN "ADS"

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

// --- dbsetindex wrapper for ADS compatibility ---
// ADS requires table and index files to be on the same server.
// d_stocktmp.cdx is a temp index that may not exist (created by external modules).
// This wrapper: 1) checks file exists, 2) catches ADS error 5020 gracefully.
FUNCTION SafeDbSetIndex( cIndex )
LOCAL lOk := .T.
LOCAL cFile := cIndex
LOCAL bOldErr

   // sch_reqm.prg ищет cTempDir+"d_stocktmp", а оригинал строит
   // G:\USERS\TAPI_SCH\d_stockt. Подменяем полный путь.
   IF "d_stocktmp" $ cIndex
      cIndex := "G:\USERS\TAPI_SCH\d_stockt"
      cFile := cIndex
      LogWrite("SafeDbSetIndex: подмена d_stocktmp -> " + cIndex)
   ENDIF

   // Ensure .cdx extension for file check
   IF !( ".cdx" $ Lower( Right( cFile, 4 ) ) ) .AND. !( ".CDX" $ Right( cFile, 4 ) )
      cFile := cFile + ".cdx"
   ENDIF

   IF !FILE( cFile )
      LogWrite( "SafeDbSetIndex: file not found: " + cFile + " - skipping" )
      RETURN .F.
   ENDIF

   // Try to set the index, catch ADS errors (e.g., 5020 cross-server)
   // Use ordListAdd() directly since dbsetindex is #xtranslated to this function
   bOldErr := ErrorBlock( {|e| Break(e) } )
   BEGIN SEQUENCE
      ordListAdd( cIndex )
   RECOVER
      LogWrite( "SafeDbSetIndex: error setting index: " + cFile + " on workarea " + Alias() + " - skipping" )
      lOk := .F.
   END SEQUENCE
   ErrorBlock( bOldErr )

RETURN lOk

// --- Network / Locking (real: BMS/LOCKS.PRG) ---

FUNCTION NetUse( cDataBase, nSeconds, cDriver, lOpenMode, lNewWorkArea, cDir, cAlias, lDirectory, cTag )
   // Real implementation based on PDC-clean/BMS/LOCKS.PRG
   LOCAL lForever, lRestart := .T., nWaitTime
   LOCAL cDbfDir
   LOCAL nAlert
   LOCAL cLockingUser, aLockingUser := {"", NIL}, nLock
   LOCAL bOldErr, lOpenErr, oErr

   // Get base directory: from cDir parameter, or from GetUserInfo():cDbfDir
   IF cDir == NIL
      cDbfDir := GetUserInfo():cDbfDir
   ELSE
      cDbfDir := cDir
   ENDIF

   // Select RDD driver: DBFCDX for local (C:), ADS for network
   cDriver := IIF( Left(cDbfDir, 2) $ "C:", "DBFCDX", GetMyDriver() )

   DEFAULT lNewWorkArea TO .T.
   DEFAULT lOpenMode    TO .T.      // .T. = SHARED
   DEFAULT nSeconds     TO 5

   IF cDriver == NIL
      cDriver := GetMyDriver()
   ENDIF

   lForever := ( nSeconds == 0 )

   LogWrite( "NetUse: " + cDataBase + " driver=" + cDriver + " dir=" + cDbfDir + ;
             " shared=" + IIF( lOpenMode, "T", "F" ) + " newWA=" + IIF( lNewWorkArea, "T", "F" ) )

   WHILE lRestart
      nWaitTime := nSeconds

      WHILE ( lForever .OR. nWaitTime > 0 )

         IF ( Select(cDataBase) == 0 ) .OR. ;
            ( Select(cDataBase) != 0 .AND. cAlias != NIL .AND. Select(cAlias) == 0 )

            // Wrap DBUSEAREA in error trap to handle errors gracefully
            lOpenErr := .F.
            bOldErr := ErrorBlock( {|e| Break(e) } )
            BEGIN SEQUENCE
               IF Empty(lDirectory)
                  DBUSEAREA( lNewWorkArea, cDriver, (cDbfDir + cDataBase), cAlias, lOpenMode, .F. )
               ELSE
                  DBUSEAREA( lNewWorkArea, cDriver, (cDataBase), cAlias, lOpenMode, .F. )
               ENDIF
            RECOVER USING oErr
               lOpenErr := .T.
            END SEQUENCE
            ErrorBlock( bOldErr )

            IF lOpenErr
               LogWrite( "NetUse: DBUSEAREA error for " + cDataBase + ;
                  " desc=" + iif( oErr != NIL, oErr:description, "?" ) + ;
                  " oper=" + iif( oErr != NIL .AND. ! Empty(oErr:operation), oErr:operation, "" ) + ;
                  " file=" + iif( oErr != NIL .AND. oErr:filename != NIL, oErr:filename, "" ) + ;
                  " os=" + iif( oErr != NIL, LTrim(Str(oErr:osCode)), "?" ) + ;
                  " sub=" + iif( oErr != NIL, LTrim(Str(oErr:subCode)), "?" ) )
               RETURN .F.
            ENDIF
         ELSE
            SELECT Select(cDataBase)
         ENDIF

         IF ! NetErr()
            IF ! Empty(cTag)
               OrdSetFocus( cTag )
            ENDIF
            RETURN .T.
         ENDIF
         INKEY(1)
         nWaitTime--
      ENDDO

      // Lock diagnostics
      LogWrite( "NetUse RETRY: " + cDataBase + " AXS lock=" + ;
                IIF( AX_AXSLocking(), "T", "F" ) + ;
                " locked=" + IIF( AX_IsFlocked(cDataBase), "T", "F" ) + ;
                " userid=" + LTrim(Str(AX_UserLockId(cDataBase))) )

      aLockingUser := AX_LockOwner( cDataBase + ".dbf", , @nLock )

      IF nLock > 1
         cLockingUser := aLockingUser[1]
         IF Empty(cLockingUser)
            LogWrite( "NetUse: error retrieving lock owner, AX_Error=" + LTrim(Str(AX_Error())) )
         ENDIF
      ENDIF

      DEFAULT cLockingUser TO ""

      nAlert := Alert( "Cannot open: " + cDataBase + ";" + ;
                        cLockingUser + " may be locking this file;;" + ;
                        "Retry?", ;
                        { "Retry", "Quit" } )

      DO CASE
      CASE nAlert == 1
         lRestart := .T.
      CASE nAlert == 2 .OR. nAlert == 0
         lRestart := .F.
      ENDCASE
   END

   LogWrite( "NetUse FAILED: " + cDataBase )
RETURN .F.

FUNCTION RecLock( nSeconds, cProc, lUpdate )
   // Real implementation based on PDC-clean/BMS/LOCKS.PRG
   LOCAL lForever, lRestart := .T., nWaitTime
   LOCAL cAlias := Alias()
   LOCAL cLockingUser := ""

   DEFAULT cProc    TO ProcName(1)
   DEFAULT lUpdate  TO .T.
   DEFAULT nSeconds TO 0

   lForever := ( nSeconds == 0 )

   WHILE lRestart
      nWaitTime := nSeconds
      DO WHILE ( lForever .OR. nWaitTime > 0 )
         IF (cAlias)->(RLock())
            // Update audit fields if present
            IF lUpdate .AND. (cAlias)->(FieldPos("plu_rec")) > 0
               GetUserInfo():updateUserInRec( cAlias, cProc, .F. )
            ENDIF
            RETURN .T.
         ENDIF
         INKEY(1)
         nWaitTime--
      ENDDO
      DEFAULT cLockingUser TO ""
      LogWrite( "RecLock RETRY: " + cAlias + " AXS lock=" + ;
                IIF( AX_AXSLocking(), "T", "F" ) + ;
                " locked=" + IIF( AX_IsFlocked(cAlias), "T", "F" ) )
      cLockingUser := fn_WhoAmI()
      lRestart := Alert( "Record locked in " + cAlias + ";" + ;
                          cLockingUser + " may be using this record;;" + ;
                          "Retry?", ;
                          { "Retry", "Cancel" } ) == 1
   END
RETURN .F.

FUNCTION AddRec( nWaitSeconds, cCallingProc )
   // Real implementation based on PDC-clean/BMS/LOCKS.PRG
   LOCAL cAlias := Alias()
   LOCAL lForever, lRestart := .T., nWaitTime
   LOCAL cLockingUser := ""

   DEFAULT nWaitSeconds  TO 5
   DEFAULT cCallingProc  TO ProcName(1)

   dbAppend()

   IF ! NetErr()
      // Update audit fields if table has them
      IF (cAlias)->(FieldPos("dlu_rec")) > 0
         GetUserInfo():updateUserInRec( cAlias, cCallingProc, .T. )
      ENDIF
      RETURN .T.
   ENDIF

   lForever := ( nWaitSeconds == 0 )

   WHILE lRestart
      nWaitTime := nWaitSeconds
      WHILE ( lForever .OR. nWaitTime > 0 )
         dbAppend()
         IF ! NetErr()
            RETURN .T.
         ENDIF
         INKEY(1)
         nWaitTime--
      ENDDO
      DEFAULT cLockingUser TO ""
      lRestart := Alert( "Cannot append to " + cAlias + ";" + ;
                          "Table may be locked;;" + ;
                          "Retry?", ;
                          { "Retry", "Cancel" } ) == 1
   END
RETURN .F.

FUNCTION FilLock( nSeconds )
   // Real implementation based on PDC-clean/BMS/LOCKS.PRG
   LOCAL lForever, lRestart := .T., nWaitTime
   LOCAL cLockingUser := ""

   IF FLock()
      RETURN .T.
   ENDIF

   lForever := ( nSeconds == 0 )

   WHILE lRestart
      nWaitTime := nSeconds
      DO WHILE ( lForever .OR. nWaitTime > 0 )
         INKEY(1)
         nWaitTime--
         IF FLock()
            RETURN .T.
         ENDIF
      ENDDO
      DEFAULT cLockingUser TO ""
      lRestart := Alert( "File lock failed;" + ;
                          "Table may be in use;;" + ;
                          "Retry?", ;
                          { "Retry", "Cancel" } ) == 1
   END
RETURN .F.

// --- File Management (real: BMS/AVXUTI.PRG) ---

FUNCTION GenOpenFiles( aFileList, lMode )
   // Real implementation based on PDC-clean/BMS/AVXUTI.PRG
   // lMode: .T. = SHARED (default), .F. = EXCLUSIVE
   // In original, uses TableTranslate():new():xopen() which calls NetUse
   LOCAL i
   LOCAL aoOpenedList := {}
   DEFAULT lMode TO .T.    // Default SHARED — original uses TabBase:xopen default
   IF aFileList != NIL
      FOR i := 1 TO Len( aFileList )
         IF Select( aFileList[i] ) == 0
            IF NetUse( aFileList[i], 5, , lMode )
               AAdd( aoOpenedList, aFileList[i] )
            ELSE
               AAdd( aoOpenedList, NIL )
            ENDIF
         ENDIF
      NEXT
   ENDIF
RETURN aoOpenedList

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

// --- Screen Push/Pop Stack (from LIB/SCRNPP.PRG) ---

PROCEDURE scrnPush( t, l, b, r, lScroll )
   DEFAULT t TO 0, l TO 0, b TO 24, r TO 79, lScroll TO .F.
   AAdd(aScrnStack, { t, l, b, r, SaveScreen(t, l, b, r) })
   IF lScroll
      Scroll(t, l, b, r)
   ENDIF
RETURN

PROCEDURE scrnPop()
LOCAL aScreenData
   IF Empty(aScrnStack)
      RETURN
   ENDIF
   aScreenData := ATail(aScrnStack)
   ASize(aScrnStack, Len(aScrnStack) - 1)
   RestScreen(aScreenData[1], aScreenData[2], aScreenData[3], aScreenData[4], aScreenData[5])
RETURN

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
   // Sort and criteria
   VAR aSortName         // Sort names
   VAR aSortList         // Sort list with index expression
   VAR aSortExpr         // Sort list index expression
   VAR aCritList         // Criteria list
   VAR aGetBuffer        // Buffer names for criteria
   VAR aCheckBlocks      // Code blocks for check screens
   VAR aTstBlocks        // Code blocks for query testing
   VAR aMyBuffer         // User-selected criteria results
   VAR aDBs              // Array of DBF files
   VAR aFldList          // Field list for spreadsheet
   VAR aTitles           // Titles for spreadsheet
   VAR aShortShow        // Short representation
   VAR aSuperCriteria    // Which criteria have indexes
   VAR aSuperIndexes     // Indexes for super criteria
   VAR aHandyArray       // Extra data
   VAR aReports          // Multiple report files
   VAR aXTabCargo        // Cross-tab info
   // String vars
   VAR cReportName       // Report name
   VAR cRepTitle         // Report title
   VAR cSubTitle         // Sub title
   VAR aSubtiltle        // Sub titles array
   VAR cRepDbf           // Name used in report design
   VAR cPrepDbf          // Name of prep DB
   VAR cPrepShort        // Short prep
   VAR cRepFileName      // TVR file name
   VAR cBaseIndex        // Base index
   VAR cTempFileDir      // Temp directory
   VAR cTypeOfReport     // "REPORT" or "QUERY"
   VAR cDevType          // Device type
   VAR cSortType         // Selected sort type
   VAR cRemark           // Remark
   VAR cRepBotTitle      // Bottom title
   VAR cTop
   VAR cBottom
   // Code blocks
   VAR cbExtraCond       // Extra hard-coded condition
   VAR cbPrepDbf         // Code block that prepares filtered DB
   VAR cbPrepShort       // Short prep block
   VAR cbPreQuery        // Pre-query block
   VAR cbSetRelation     // Set relations block
   VAR cbBuildRep        // Build report on the fly
   // Logical
   VAR lBuildDBF         // Build report on the fly
   VAR lCreateOrp        // Create ORP from definition
   VAR lCustFile         // Customer file
   VAR lDoIndex          // Do index
   VAR lMultiIndex       // Multiple index
   VAR lPrepDbf          // Should build filtered DB
   VAR lRelIndex         // Related index
   VAR lUseScope         // Use scope instead of temp file
   VAR lWeWantDiffMenu   // Pre-menu
   VAR lSuperSmart       // Multiple indexes
   VAR lDest             // Destination flag
   // Numeric
   VAR nDest             // Destination numeric
   VAR nOldPrinter       // Old printer number
   VAR nSmartCriteria    // Smart criteria index
   // Objects
   VAR oScrl             // ScrollBox
   VAR aOrp              // ORP array
   // Methods
   METHOD New( cName, cDesc )
   METHOD SetSort( a )        INLINE ( ::aSortName := a, ::aSortList := a )
   METHOD SetExprSort( a )    INLINE ::aSortExpr := a
   METHOD SetFields( a )      INLINE ::aFldList := a
   METHOD SetTitles( a )      INLINE ::aTitles := a
   METHOD SetCrit( a )        INLINE ( ::aCritList := a, ::aGetBuffer := a )
   METHOD SetBuffer( a )      INLINE ::aGetBuffer := a
   METHOD SetCheck( a )       INLINE ::aCheckBlocks := a
   METHOD SetQueryBlocks( a ) INLINE ::aTstBlocks := a
   METHOD SetDB( a )          INLINE ::aDBs := a
   METHOD SetDest( l )        INLINE ::lDest := l
   METHOD SetSubTitles( a )   INLINE ::aSubtiltle := a
   METHOD Exec( lSeeMessage )
END CLASS

METHOD New( cName, cDesc ) CLASS TheReport
   ::cReportName     := cName
   ::cRepTitle       := cDesc
   ::cSubTitle       := ""
   ::cTypeOfReport   := "REPORT"
   ::lSuperSmart     := .F.
   ::lBuildDBF       := .F.
   ::lPrepDbf        := .T.
   ::lCreateOrp      := .F.
   ::lWeWantDiffMenu := .F.
   ::lUseScope       := .F.
   ::lDest           := .T.    // default TRUE in original THEREPO.PRG
   ::aMyBuffer       := {}
   ::aReports        := {}
   ::aHandyArray     := {}
   ::aSubtiltle      := {}
   ::aXTabCargo      := {}
   ::cTempFileDir    := GetUserInfo():cTempDir
   ::nSmartCriteria  := 0
   LogWrite( "TheReport:New(" + cName + ")" )
RETURN Self

METHOD Exec( lSeeMessage ) CLASS TheReport
   // Real Exec from PDC-clean/BMS/THEREPO.PRG line 219
   // Shows prnFace criteria selection UI, then calls cbPrepDbf (DoSched)
   LOCAL i, xKey
   PRIVATE aTestBlocks, aBuffer  // MUST be PRIVATE - used by DoSched via GetBuffer/ShaiCond

   LogWrite( "TheReport:Exec() - starting with prnFace UI" )

   scrnPush()
   SetColor("W+/B")
   CLS

   // Set check blocks for prnFace checkboxes (from THEREPO.PRG line 228)
   SetCheckBlocks( ::aCheckBlocks )

   // Set devices based on report type (from THEREPO.PRG line 236-245)
   IF ::cTypeOfReport == "REPORT"
      SetTheDevices(2)
   ELSE
      SetTheDevices(3)
   ENDIF

   // Show criteria selection screen (from THEREPO.PRG line 249)
   prnFace( ::aSortList, ::aCritList, {::cReportName, ::cRepTitle}, 1, ::cSubTitle, ::aSuperCriteria, ::lDest )

   LogWrite( "TheReport:Exec() - prnFace returned, LastKey()=" + LTrim(Str(LastKey())) )

   // Check if user pressed ESC (from THEREPO.PRG line 264-271)
   IF LastKey() == K_ESC
      xKey := Alert( "You pressed ESC.;Do you want to stop?", {"No", "Yes"}, ALERT_WAR )
      IF xKey == 2
         SetTheDevices(1)
         scrnPop()
         RETURN .F.
      ENDIF
   ENDIF

   // Populate aMyBuffer from GetBuffer (from THEREPO.PRG line 276-280)
   ::aMyBuffer := {}
   IF ::aGetBuffer != NIL
      FOR i := 1 TO Len( ::aGetBuffer )
         AAdd( ::aMyBuffer, GetBuffer( ::aGetBuffer[i] ) )
      NEXT
   ENDIF

   // Get device type (from THEREPO.PRG line 291)
   ::cDevType := GetDevType()

   // Set PRIVATE variables that sch_reqm.prg functions expect
   aTestBlocks := ::aTstBlocks
   aBuffer     := ::aMyBuffer

   LogWrite( "TheReport:Exec() - User selected criteria, calling cbPrepDbf (DoSched)" )
   LogWrite( "TheReport:Exec() - Sort: " + IIF(GetSortType() != NIL, GetSortType(), "(nil)") )
   LogWrite( "TheReport:Exec() - DevType: " + IIF(::cDevType != NIL, ::cDevType, "(nil)") )
   FOR i := 1 TO Len(::aMyBuffer)
      IF ValType(::aMyBuffer[i]) == "C"
         LogWrite( "  Buffer[" + LTrim(Str(i)) + "]: " + IIF(Empty(::aMyBuffer[i]), "(all)", Left(::aMyBuffer[i], 60)) )
      ENDIF
   NEXT

   // Open the main database(s) before calling prep callback
   // In original flow, CreateCondDb does GenOpenFiles({::aDbs[1]}) at THEREPO line 742
   // Since we call DoSched directly (skipping CreateCondDb), we must open d_ord here
   IF ::aDBs != NIL .AND. Len(::aDBs) > 0
      GenOpenFiles(::aDBs)
   ENDIF

   // CreateCondDb - create filtered t_ordPre (from THEREPO.PRG line 726)
   // Original flow:
   //   1. GenOpenFiles opens d_ord (line 742)
   //   2. COPY TO t_ordPre FOR ShaiCond() .AND. cbExtraCond (lines 958-965)
   //   3. Close d_ord (line 973 in CreateCondDb)
   //   4. PrepareGenDb opens t_ordPre with alias "d_ord" (sch_reqm line 4574)
   // We must close d_ord AFTER CreateCondDb so PrepareGenDb can reopen
   // t_ordPre with alias "d_ord" — otherwise alias conflict prevents opening.
   IF ::cPrepDbf != NIL .AND. ::aDBs != NIL .AND. Len(::aDBs) > 0
      CreateCondDb( Self, ::aDBs[1], aTestBlocks, aBuffer )
      // Close d_ord after copying — exactly as THEREPO.PRG line 973:
      //   (cDbf)->(DBCLOSEAREA())
      IF Select(::aDBs[1]) > 0
         LogWrite("TheReport:Exec() - closing " + ::aDBs[1] + " after CreateCondDb (THEREPO line 973)")
         (::aDBs[1])->(dbCloseArea())
      ENDIF
   ENDIF

   // Call the prep callback (DoSched for scheduling)
   IF ::cbPrepDbf != NIL
      LogWrite( "TheReport:Exec() - calling cbPrepDbf (DoSched)..." )
      Eval( ::cbPrepDbf, Self )
      LogWrite( "TheReport:Exec() - cbPrepDbf (DoSched) completed successfully" )
   ENDIF

   // Cleanup (from THEREPO.PRG line 329-332)
   LogWrite( "TheReport:Exec() - cleanup: SetTheDevices, prnKillCrit, scrnPop" )
   SetTheDevices(1)
   prnKillCrit()
   scrnPop()

   LogWrite( "TheReport:Exec() - returning .T." )
RETURN .T.

// GetUserInfo (real: BMS/USERINFO.PRG)
CREATE CLASS GetUserInfoClass
   VAR cDbfDir
   VAR cTempDir
   VAR cUserId
   VAR cGroupId
   VAR cWIPCardNo
   VAR cMapDir
   VAR cPrnDir
   METHOD New()
   METHOD updateUserInRec( cFileName, cProgName, lNewRec )
END CLASS

METHOD New() CLASS GetUserInfoClass
   // cDbfDir = base path for all DBF files on ADS server
   // This matches SET DEFAULT in main.prg — must end with backslash
   LOCAL cDefPath := SET( _SET_DEFAULT )
   IF ! Empty( cDefPath )
      IF !( Right( cDefPath, 1 ) $ "/\" )
         cDefPath += "\"
      ENDIF
      ::cDbfDir := cDefPath
   ELSE
      ::cDbfDir := "G:\AVXBMS\"
   ENDIF
   ::cTempDir    := hb_DirTemp() + "\"
   ::cUserId     := fn_WhoAmI()
   ::cGroupId    := ""
   ::cWIPCardNo  := "000000000000"
   ::cMapDir     := ""
   ::cPrnDir     := ""
   LogWrite( "GetUserInfo:New() cDbfDir=" + ::cDbfDir + " cUserId=" + ::cUserId )
RETURN Self

METHOD updateUserInRec( cFileName, cProgName, lNewRec ) CLASS GetUserInfoClass
   DEFAULT lNewRec TO .F.
   IF lNewRec
      IF (cFileName)->(FieldPos("dadd_rec")) > 0
         (cFileName)->dadd_rec := Date()
      ENDIF
      IF (cFileName)->(FieldPos("tadd_rec")) > 0
         (cFileName)->tadd_rec := Left( Time(), 5 )
      ENDIF
   ENDIF
   IF (cFileName)->(FieldPos("dlu_rec")) > 0
      (cFileName)->dlu_rec := Date()
   ENDIF
   IF (cFileName)->(FieldPos("tlu_rec")) > 0
      (cFileName)->tlu_rec := Time()
   ENDIF
   IF (cFileName)->(FieldPos("ulu_rec")) > 0
      (cFileName)->ulu_rec := ::cUserId
   ENDIF
   IF (cFileName)->(FieldPos("wlu_rec")) > 0
      (cFileName)->wlu_rec := ::cWIPCardNo
   ENDIF
   IF (cFileName)->(FieldPos("plu_rec")) > 0
      (cFileName)->plu_rec := Upper( cProgName )
   ENDIF
RETURN NIL

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

// ============================================
// PrnFace GUI - Criteria Selection Screen
// Based on PDC-clean/BMS/PRNFACE.PRG + CHECKS.PRG + RADIOS.PRG + PRNCRIT.PRG
// ============================================

// ============================================
// prnFace - Main criteria selection screen (from PRNFACE.PRG line 71)
// ============================================
PROCEDURE PrnFace( aSortParams, aCutParams, aRepInfo, nSortDefault, cSubTitle, aSuperCrits, lDest )
LOCAL i, nLen, j, nHowMany
LOCAL lHasDefault := .F.
LOCAL lSuperColor := .F.

DEFAULT nSortDefault TO 0
DEFAULT lDest TO .T.
DEFAULT aSuperCrits TO {}

cUserMsg_pf := IIF( cSubTitle == NIL, Space(35), PadR(cSubTitle,35) )

aSort_pf := aSortParams
IF !Empty(aSort_pf)
   IF !Empty(nSortDefault)
      cSortType_pf := aSort_pf[nSortDefault]
   ENDIF
ENDIF

aCut_pf := aCutParams

SetKey( K_F7, {|| prnShowCrits() } )
SetKey( K_TAB, {|| TabGet() } )

@ 0,0 SAY PadC( aRepInfo[2] + " (" + aRepInfo[1] + ")", 80 ) COLOR "GR+/RB"
@ 24,0 SAY PadR( "Help[F1] Load print[F5] Save print[Shift][F5] View print[F7] Run[PgDn] Exit[Esc]", 80 ) COLOR "GR+/RB"

nLen := Len(aCutParams)
aCutIndicators_pf := Array(nLen)
aCutDefault_pf := Array(nLen)
AFill(aCutIndicators_pf, .F.)
AFill(aCutDefault_pf, .F.)

IF nDevices_pf == 1
   // For scheduling: Printer, Screen, SpreadSheet
ELSEIF nDevices_pf == 2
   // Report mode
ELSEIF nDevices_pf == 3
   // Query mode
ENDIF

@ 2, 2 SAY "Optional subtitle:" COLOR "W+/B"
@ 3, 2 GET cUserMsg_pf COLOR GETCOLORS ;
                        SEND preBlock := {|o| SetCursor(1), .T. } ;
                        SEND postBlock := {|o| SetCursor(0), .T. }

IF !Empty(aSort_pf)
   @ 4, 2 SAY "Select sort rule:" COLOR "W+/B"
   @ 5, 4 GET cSortType_pf RADIO aSort_pf
ENDIF

IF lDest
   @ 18, 2 SAY "Select destination:" COLOR "W+/B"
   IF nDevices_pf == 1 .OR. nDevices_pf == 2
      cDeviceType_pf := "Printer"
   ELSEIF nDevices_pf == 3
      cDeviceType_pf := "Screen"
   ENDIF
   @ 19, 4 GET cDeviceType_pf RADIO {"Printer", "Screen", "SpreadSheet"}
ENDIF

IF !Empty(nLen)
   @ 2, 45 SAY "Select criteria:" COLOR "W+/B"
ENDIF

FOR i := 1 TO nLen
   SetPos(2 + i, 45)
   nHowMany := ALen(GetList)
   j := 1
   lSuperColor := .F.
   WHILE j <= ALen(aSuperCrits)
      IF i == aSuperCrits[j]
         lSuperColor := .T.
      ENDIF
      j++
   END
   AAdd(GetList, ;
      CheckGetNew(MakeBlock(aCutIndicators_pf, i), "aCutIndicators_pf[i]", aCut_pf[i], lSuperColor))
   IF ValType(aCheckBlocks_pf) == "A"
      ATail(GetList):postBlock := aCheckBlocks_pf[i]
   ENDIF
NEXT

READ
IF Empty(cDeviceType_pf)
   cDeviceType_pf := "Printer"
ENDIF

SetKey( K_F7, NIL )
SetKey( K_TAB, NIL )
SetKey( K_F2, NIL )
SetKey( K_F1, NIL )

IF LastKey() == K_ESC
   SetCursor(0)
ENDIF

RETURN

// ============================================
// prnFace helper functions (from PRNFACE.PRG)
// ============================================
FUNCTION MakeBlock( aCutInd, i )
RETURN {|x| IIF(x == NIL, aCutInd[i], aCutInd[i] := x) }

PROCEDURE SetCheckBlocks( aCb )
   aCheckBlocks_pf := aCb
RETURN

FUNCTION GetSortType()
RETURN cSortType_pf

FUNCTION SetSortType( cSrtType )
RETURN cSortType_pf := cSrtType

FUNCTION GetIndicators()
RETURN aCutIndicators_pf

FUNCTION GetDevType()
RETURN cDeviceType_pf

PROCEDURE SetTheDevices( nDev )
   nDevices_pf := nDev
RETURN

FUNCTION GetPrintFile()
RETURN ""

FUNCTION GetSpreadFile()
RETURN ""

FUNCTION GetPrinter()
RETURN ""

FUNCTION prnGetUserMsg()
RETURN AllTrim(cUserMsg_pf)

// prnShowCrits - View selected criteria (F7 key)
FUNCTION prnShowCrits()
LOCAL cScr := SaveScreen()
LOCAL cMemo := ""
LOCAL i

IF aCutIndicators_pf != NIL .AND. aCut_pf != NIL
   FOR i := 1 TO Len(aCutIndicators_pf)
      IF aCutIndicators_pf[i]
         cMemo += aCut_pf[i] + ": selected" + Chr(13) + Chr(10)
      ELSE
         cMemo += aCut_pf[i] + ": -" + Chr(13) + Chr(10)
      ENDIF
   NEXT
ENDIF

@ 2, 0 CLEAR TO 23, 79
@ 24, 0 SAY PadC("Arrow keys to scroll, ESC to exit", 80) COLOR "W+/R"
MemoEdit(cMemo, 2, 0, 23, 79, .F., NIL, 80)
RestScreen(0, 0, 24, 79, cScr)

RETURN NIL

// TabGet - Tab to next GET group (from PRNFACE.PRG line 803)
PROCEDURE TabGet()
LOCAL nLen := Len(GetList), nGetPos, i
LOCAL cGetName
LOCAL nDowns := 0

nGetPos := AScan(GetList, {|o| o:hasFocus})
IF nGetPos == 0
   RETURN
ENDIF
cGetName := GetList[nGetPos]:name
i := nGetPos

WHILE .T.
   i++
   DO CASE
      CASE i > nLen
         KEYBOARD Chr(K_CTRL_HOME)
         GetList[nGetPos]:exitState := GE_TOP
         EXIT
      CASE GetList[i]:name == cGetName
         nDowns++
      CASE GetList[i]:name != cGetName
         KEYBOARD Replicate(Chr(K_DOWN), nDowns)
         GetList[nGetPos]:exitState := GE_DOWN
         EXIT
   ENDCASE
ENDDO
RETURN

// ============================================
// Check box GET (from CHECKS.PRG)
// ============================================
FUNCTION CheckGetNew( bVar, cVar, cStr, lSuperColor )
LOCAL oGet
LOCAL nRow := Row(), nCol := Col()

DEFAULT lSuperColor TO .F.

DevPos(nRow, nCol)
IF lSuperColor
   DevOut("[ ]", IIF(IsColor(), "R+/B", "W/N"))
ELSE
   DevOut("[ ]", IIF(IsColor(), "GR+/B", "W/N"))
ENDIF

oGet := GetNew()
oGet:col := nCol + 4
oGet:row := nRow
oGet:name := cVar
oGet:cargo := Array(CHECK_NUM_IVARS)
oGet:checkGsb := bVar
oGet:block := {|| cStr}
oGet:reader := {|o| CheckReader(o)}
oGet:colorSpec := "G+/B,G+/R"
DrawCheck(oGet)
oGet:display()

RETURN oGet

PROCEDURE CheckReader( oGet )
   IF GetPreValidate(oGet)
      oGet:SetFocus()
      DO WHILE oGet:exitState == GE_NOEXIT
         IF oGet:typeOut
            oGet:exitState := GE_ENTER
         ENDIF
         DO WHILE oGet:exitState == GE_NOEXIT
            CheckApplyKey(oGet, InKey(0))
         ENDDO
         IF !GetPostValidate(oGet)
            oGet:exitState := GE_NOEXIT
         ENDIF
      ENDDO
      oGet:KillFocus()
   ENDIF
RETURN

PROCEDURE CheckApplyKey( oGet, nKey )
LOCAL bKeyBlock

IF (bKeyBlock := SetKey(nKey)) != NIL
   GetDoSetKey(bKeyBlock, oGet)
   RETURN
ENDIF

DO CASE
   CASE nKey == K_UP
      oGet:exitState := GE_UP
   CASE nKey == K_SH_TAB
      oGet:exitState := GE_UP
   CASE nKey == K_DOWN
      oGet:exitState := GE_DOWN
   CASE nKey == K_TAB
      oGet:exitState := GE_DOWN
   CASE nKey == K_ENTER
      oGet:exitState := GE_ENTER
   CASE nKey == K_SPACE
      Eval(oGet:checkGsb, !Eval(oGet:checkGsb))
      IF ValType(oGet:postBlock) == "B"
         Eval(oGet:postBlock, oGet)
      ENDIF
      oGet:changed := .T.
      DrawCheck(oGet)
   CASE nKey == K_ESC
      IF Set(_SET_ESCAPE)
         oGet:undo()
         oGet:exitState := GE_ESCAPE
      ENDIF
   CASE nKey == K_PGUP
      oGet:exitState := GE_WRITE
   CASE nKey == K_PGDN
      oGet:exitState := GE_WRITE
   CASE nKey == K_CTRL_HOME
      oGet:exitState := GE_TOP
   CASE nKey == K_CTRL_W
      oGet:exitState := GE_WRITE
   CASE nKey == K_INS
      Set(_SET_INSERT, !Set(_SET_INSERT))
ENDCASE
RETURN

PROCEDURE DrawCheck( oGet )
LOCAL lSelected
LOCAL nSaveRow := Row()
LOCAL nSaveCol := Col()

IF ValType(oGet:cargo) == "A" .AND. Len(oGet:cargo) == 1
   lSelected := Eval(oGet:checkGsb)
ELSE
   RETURN
ENDIF

DevPos(oGet:row, oGet:col - 3)
IF lSelected
   DevOut(CHECK_BOX, IIF(IsColor(), "G+/B", "N/W"))
ELSE
   DevOut(" ", IIF(IsColor(), "GR+/B", "W/N"))
ENDIF

DevPos(nSaveRow, nSaveCol)
RETURN

// ============================================
// Radio button GET (from RADIOS.PRG)
// ============================================
FUNCTION RadioGets( bVar, cVar, aChoices, aGetList, aBlocks )
LOCAL oGet
LOCAL nRow := Row(), nCol := Col()
LOCAL nGets := Len(aChoices)
LOCAL nGet
LOCAL nStartGet := Len(aGetList) + 1

DEFAULT aBlocks TO {}

FOR nGet := 1 TO nGets
   DevPos(nRow, nCol)
   DevOut("( ) ", IIF(IsColor(), "GR+/B", "W/N"))

   oGet := GetNew()
   AAdd(aGetList, oGet)

   oGet:col := nCol + 4
   oGet:row := nRow++
   oGet:name := cVar
   oGet:block := radioT(aChoices[nGet])
   oGet:cargo := Array(RADIO_NUM_IVARS)
   oGet:radioGsb := bVar
   oGet:radioGets := Array(nGets)
   AEval(oGet:radioGets, {|x, n| oGet:radioGets[n] := nStartGet + n - 1})
   oGet:reader := {|o| RadioReader(o, aGetList)}
   oGet:colorSpec := GETCOLORS
   IF !Empty(aBlocks) .AND. nGet <= Len(aBlocks)
      oGet:postBlock := aBlocks[nGet]
   ENDIF
   oGet:display()
NEXT

RETURN oGet

// Return a detached local block (from RADIOS.PRG)
FUNCTION radioT( c )
RETURN {|x| c}

PROCEDURE RadioReader( oGet, aGetList )
   IF GetPreValidate(oGet)
      oGet:SetFocus()
      DO WHILE oGet:exitState == GE_NOEXIT
         IF oGet:typeOut
            oGet:exitState := GE_ENTER
         ENDIF
         DO WHILE oGet:exitState == GE_NOEXIT
            RadioApplyKey(oGet, InKey(1), aGetList)
         ENDDO
         IF !GetPostValidate(oGet)
            oGet:exitState := GE_NOEXIT
         ENDIF
      ENDDO
      oGet:KillFocus()
   ENDIF
RETURN

PROCEDURE RadioApplyKey( oGet, nKey, aGetList )
LOCAL bKeyBlock

IF (bKeyBlock := SetKey(nKey)) != NIL
   GetDoSetKey(bKeyBlock, oGet)
   RETURN
ENDIF

DO CASE
   CASE nKey == K_UP
      oGet:exitState := GE_UP
   CASE nKey == K_SH_TAB
      oGet:exitState := GE_UP
   CASE nKey == K_DOWN
      oGet:exitState := GE_DOWN
   CASE nKey == K_TAB
      oGet:exitState := GE_DOWN
   CASE nKey == K_ENTER
      oGet:exitState := GE_ENTER
   CASE nKey == K_SPACE
      IF Eval(oGet:radioGsb) == Eval(oGet:block)
         Eval(oGet:radioGsb, "")
      ELSE
         Eval(oGet:radioGsb, Eval(oGet:block))
      ENDIF
      oGet:changed := .T.
      DrawRadios(aGetList, oGet)
   CASE nKey == K_ESC
      IF Set(_SET_ESCAPE)
         oGet:undo()
         oGet:exitState := GE_ESCAPE
      ENDIF
   CASE nKey == K_PGUP
      oGet:exitState := GE_WRITE
   CASE nKey == K_PGDN
      oGet:exitState := GE_WRITE
   CASE nKey == K_CTRL_HOME
      oGet:exitState := GE_TOP
   CASE nKey == K_CTRL_W
      oGet:exitState := GE_WRITE
   CASE nKey == K_INS
      Set(_SET_INSERT, !Set(_SET_INSERT))
ENDCASE
RETURN

PROCEDURE DrawRadios( aGetList, oGet )
LOCAL nRadios := Len(oGet:radioGets)
LOCAL oGet1, oMarkGet
LOCAL nSaveRow := Row()
LOCAL nSaveCol := Col()
LOCAL nGet

FOR nGet := 1 TO nRadios
   oGet1 := aGetList[oGet:radioGets[nGet]]
   DevPos(oGet1:row, oGet1:col - 3)
   IF Eval(oGet1:radioGsb) == Eval(oGet1:block)
      DevOut(RADIO_BUTTON, IIF(IsColor(), "G+/B", "N/W"))
      IF ValType(oGet1:postBlock) == "B"
         oMarkGet := oGet1
      ELSE
         oMarkGet := NIL
      ENDIF
   ELSE
      DevOut(" ", IIF(IsColor(), "GR+/B", "W/N"))
   ENDIF
NEXT

IF ValType(oMarkGet) == "O"
   Eval(oMarkGet:postBlock, oMarkGet)
ENDIF

DevPos(nSaveRow, nSaveCol)
RETURN

// ============================================
// critBrowse - Criteria selection browse dialog (from PRNCRIT.PRG line 2877)
// Opens a code table, shows TBrowse with [X]/[ ] checkboxes, user selects entries
// ============================================
FUNCTION critBrowse( o, aParamList, cFile, cIndex, bKeyCol, bNameCol, bFilter )
LOCAL aGetList_save
LOCAL nRow := Row()
LOCAL nCol := Col()
LOCAL nKey, ii

DEFAULT bFilter TO ""

IF o:ExitState != GE_NOEXIT
   RETURN .T.
ENDIF

IF !Eval(o:checkGsb)
   LogWrite("critBrowse: checkbox OFF for " + cFile + " - setting (all)")
   prnSetCritBuffer(cFile, .T., o:VarGet())
   RETURN .T.
ENDIF
LogWrite("critBrowse: checkbox ON for " + cFile + " - opening browse")

IF ValType(aParamList) != "A"
   Alert("No params in criterion", {" OK "})
   RETURN .F.
ENDIF

scrnPush()

IF NetUse(cFile, 5)
   IF cIndex != NIL .AND. !Empty(cIndex)
      (cFile)->(ordSetFocus(cIndex))
   ENDIF
ELSE
   scrnPop()
   RETURN .F.
ENDIF

IF !Empty(bFilter)
   (cFile)->(dbSetFilter(bFilter))
   (cFile)->(dbGoTop())
ENDIF

IF (cFile)->(Eof()) .AND. (cFile)->(Bof())
   prnSetCritBuffer(cFile, .T., o:VarGet())
   Eval(o:checkGsb, .F.)
   NETCLOSE(cFile)
   Tone(400, 1)
   scrnPop()
   RETURN .F.
ELSE
   aRecNos_pf := Array((cFile)->(LastRec()))
ENDIF

IF aParamList[1] == "all"
   AFill(aRecNos_pf, "[X]")
ELSE
   AFill(aRecNos_pf, "[ ]")
ENDIF

oBro_pf := (cFile)->(TBrowseDB(2, 2, 15, 78))

DispBox(1, 1, 19, 79, B_SINGLE + " ")

oBro_pf:addColumn(TBColumnNew("*", {|| aRecNos_pf[(cFile)->(RecNo())]}))
oBro_pf:addColumn(TBColumnNew("   ", bKeyCol))
oBro_pf:addColumn(TBColumnNew("Description                                                 ", bNameCol))

@ 17, 3 SAY PadR("Select/Unselect:[Space] Select All:[F7]  Unselect All:[Shift]+[F7] ", 75) COLOR "GR+/RB"
@ 18, 3 SAY PadR("Invert Selection:[Alt]+[F7]  Up/Down:Arrows  Exit:[Enter]", 75) COLOR "GR+/RB"

// Browse loop (from prnShow in PRNCRIT.PRG)
WHILE .T.
   WHILE !oBro_pf:stabilize() ; ENDDO

   nKey := InKey(0)

   IF nKey == K_ESC
      AFill(aRecNos_pf, "[ ]")
      EXIT
   ELSEIF StdKeys(nKey, oBro_pf)
      // handled
   ELSEIF nKey == K_ENTER
      EXIT
   ELSEIF nKey == K_F7   // mark all
      AFill(aRecNos_pf, "[X]")
      oBro_pf:refreshAll()
   ELSEIF nKey == K_SH_F7  // unmark all
      AFill(aRecNos_pf, "[ ]")
      oBro_pf:refreshAll()
   ELSEIF nKey == K_ALT_F7  // invert
      FOR ii := 1 TO Len(aRecNos_pf)
         IF aRecNos_pf[ii] == "[X]"
            aRecNos_pf[ii] := "[ ]"
         ELSE
            aRecNos_pf[ii] := "[X]"
         ENDIF
      NEXT
      oBro_pf:refreshAll()
   ELSEIF nKey == K_SPACE
      IF aRecNos_pf[(cFile)->(RecNo())] == "[X]"
         aRecNos_pf[(cFile)->(RecNo())] := "[ ]"
      ELSE
         aRecNos_pf[(cFile)->(RecNo())] := "[X]"
      ENDIF
      oBro_pf:refreshCurrent()
   ENDIF
ENDDO

IF LastKey() == K_ENTER
   cBuffer_pf := ""
   (cFile)->(DbGoTop())
   WHILE !(cFile)->(Eof())
      IF aRecNos_pf[(cFile)->(RecNo())] == "[X]"
         cBuffer_pf += Eval(bKeyCol) + "_"
      ENDIF
      (cFile)->(DbSkip())
   ENDDO
   LogWrite("critBrowse: " + cFile + " Enter pressed, cBuffer_pf=" + Left(cBuffer_pf, 80))
   prnSetCritBuffer(cFile, .F., o:VarGet())
ELSE
   cBuffer_pf := ""
   LogWrite("critBrowse: " + cFile + " ESC pressed, setting (all)")
   prnSetCritBuffer(cFile, .T., o:VarGet())
   Eval(o:checkGsb, .F.)
ENDIF

NETCLOSE(cFile)
scrnPop()
SetPos(nRow, nCol)
RETURN .T.

// ============================================
// prnSetCritBuffer - Store criteria buffer into static vars (from PRNCRIT.PRG line 2978)
// Only handles the criteria types used by SCH_REQM
// ============================================
PROCEDURE prnSetCritBuffer( cFile, lCode, cBUFF )
LOCAL cAllBuf
LogWrite("prnSetCritBuffer: file=" + cFile + " lCode=" + IIF(lCode, "T", "F") + ;
         " cBuffer_pf=" + Left(IIF(cBuffer_pf != NIL, cBuffer_pf, "(nil)"), 60))
DO CASE
   CASE cFile == "c_ptype" .OR. cFile == "Product type"
      IF lCode
         cProductType_pf := ""
      ELSE
         cProductType_pf := cBuffer_pf
      ENDIF
   CASE cFile == "c_pline" .OR. cFile == "Product line"
      IF lCode
         cProductLine_pf := ""
      ELSE
         cProductLine_pf := cBuffer_pf
      ENDIF
   CASE cFile == "c_size" .OR. cFile == "Size"
      IF lCode
         cSize_pf := ""
      ELSE
         cSize_pf := cBuffer_pf
      ENDIF
   CASE cFile == "c_value" .OR. cFile == "Value"
      IF lCode
         cValue_pf := ""
      ELSE
         cValue_pf := cBuffer_pf
      ENDIF
   CASE cFile == "c_bpurp" .OR. cFile == "Purpose"
      IF lCode
         cPurpose_pf := ""
      ELSE
         cPurpose_pf := cBuffer_pf
      ENDIF
   CASE cFile == "c_bstat" .OR. cFile == "Status"
      IF lCode
         cBstat_pf := ""
      ELSE
         cBstat_pf := cBuffer_pf
      ENDIF
   CASE cFile == "c_esnxx" .OR. cFile == "ESN(XX)"
      IF lCode
         cESNXX_pf := ""
      ELSE
         cESNXX_pf := cBuffer_pf
      ENDIF
ENDCASE

// When lCode=.T. (all selected / ESC), build the all-codes buffer now
// while the lookup table is still open (critBrowse hasn't closed it yet).
// This avoids GetBuffer_BuildAll having to open the table later.
IF lCode .AND. Select(cFile) > 0
   LogWrite("prnSetCritBuffer: pre-building all-codes buffer for " + cFile)
   // Reuse GetBuffer_BuildAll which handles the table scanning
   cAllBuf := GetBuffer_BuildAll( cFile )
   IF !Empty(cAllBuf)
      DO CASE
         CASE cFile == "c_ptype" ; cProductType_pf := cAllBuf
         CASE cFile == "c_pline" ; cProductLine_pf := cAllBuf
         CASE cFile == "c_size"  ; cSize_pf := cAllBuf
         CASE cFile == "c_value" ; cValue_pf := cAllBuf
         CASE cFile == "c_bpurp" ; cPurpose_pf := cAllBuf
         CASE cFile == "c_bstat" ; cBstat_pf := cAllBuf
         CASE cFile == "c_esnxx" ; cESNXX_pf := cAllBuf
      ENDCASE
   ENDIF
ENDIF

RETURN

// ============================================
// prnKillCrit - Reset all criteria static vars (from PRNCRIT.PRG line 226)
// ============================================
PROCEDURE prnKillCrit()
cProductType_pf := NIL
cProductLine_pf := NIL
cSize_pf := NIL
cValue_pf := NIL
cPurpose_pf := NIL
cBstat_pf := NIL
cESNXX_pf := NIL
cBuffer_pf := NIL
aRecNos_pf := NIL
oBro_pf := NIL
RETURN

// ============================================
// GetBuffer - Return criteria value by code name (from PRNCRIT.PRG line 4453)
// Only handles the criteria types used by SCH_REQM
//
// When a checkbox is OFF (all selected), the STATIC value is "" or NIL.
// The caller uses  code $ GetBuffer("xxx")  to test membership.
// Since  "XX" $ ""  = .F., we must build a buffer containing ALL codes
// from the lookup table so the $ operator returns .T. for every valid code.
// ============================================
FUNCTION GetBuffer( cCode )
LOCAL aSource := { "c_ptype", "c_pline", "c_size", "c_value", "c_bpurp", "c_bstat", "c_esnxx" }
LOCAL aTitle  := { "Product type", "Product line", "Size", "Value", "Purpose", "Status", "ESN(XX)" }
LOCAL aRet    := { cProductType_pf, cProductLine_pf, cSize_pf, cValue_pf, cPurpose_pf, cBstat_pf, cESNXX_pf }
LOCAL n, uRet := ""

DO CASE
   CASE (n := AScan(aSource, cCode)) > 0
      uRet := aRet[n]
   CASE (n := AScan(aTitle, cCode)) > 0
      uRet := aRet[n]
   OTHERWISE
      LogWrite("GetBuffer: criterion not found: " + cCode)
      uRet := ""
END

IF uRet == NIL
   uRet := ""
ENDIF

// When buffer is empty (checkbox OFF = "all"), build buffer with ALL codes
// from the lookup table so that  code $ buffer  always returns .T.
// Cache the result in the STATIC so we don't rebuild on every call.
IF Empty(uRet)
   LogWrite("GetBuffer: empty buffer for " + cCode + " (n=" + LTrim(Str(n)) + "), calling BuildAll")
   uRet := GetBuffer_BuildAll( cCode )
   // Cache the built buffer back into the STATIC var
   IF !Empty(uRet)
      DO CASE
         CASE n == 1 ; cProductType_pf := uRet
         CASE n == 2 ; cProductLine_pf := uRet
         CASE n == 3 ; cSize_pf := uRet
         CASE n == 4 ; cValue_pf := uRet
         CASE n == 5 ; cPurpose_pf := uRet
         CASE n == 6 ; cBstat_pf := uRet
         CASE n == 7 ; cESNXX_pf := uRet
      ENDCASE
   ENDIF
ENDIF

RETURN uRet

// ============================================
// GetBuffer_BuildAll - Build a buffer string containing ALL codes from a lookup table
// Called when checkbox is OFF (all selected) so the $ operator matches everything.
// Opens the table itself if not already open.
// ============================================
STATIC FUNCTION GetBuffer_BuildAll( cCode )
LOCAL cFile, cKeyField, cResult := "", nOldArea, nOldRec
LOCAL lOpened := .F.
LOCAL bOldErr, lErr := .F., nFPos

LogWrite("GetBuffer_BuildAll: ENTER cCode=" + cCode)

// Map criterion name to table name and key field
DO CASE
   CASE cCode == "c_ptype" .OR. cCode == "Product type"
      cFile := "c_ptype"
      cKeyField := "ptype_id"
   CASE cCode == "c_pline" .OR. cCode == "Product line"
      cFile := "c_pline"
      cKeyField := "pline_id"
   CASE cCode == "c_size"  .OR. cCode == "Size"
      cFile := "c_size"
      cKeyField := "size_id"
   CASE cCode == "c_value" .OR. cCode == "Value"
      cFile := "c_value"
      cKeyField := "value_id"
   CASE cCode == "c_bpurp" .OR. cCode == "Purpose"
      cFile := "c_bpurp"
      cKeyField := "b_purp"
   CASE cCode == "c_bstat" .OR. cCode == "Status"
      cFile := "c_bstat"
      cKeyField := "b_stat"
   CASE cCode == "c_esnxx" .OR. cCode == "ESN(XX)"
      cFile := "c_esnxx"
      cKeyField := "esnxx_id"
   OTHERWISE
      RETURN ""
ENDCASE

nOldArea := Select()

LogWrite("GetBuffer_BuildAll: file=" + cFile + " keyField=" + cKeyField + " Select()=" + LTrim(Str(Select(cFile))))

// Open the table if not already open
IF Select(cFile) == 0
   bOldErr := ErrorBlock( {|e| Break(e) } )
   BEGIN SEQUENCE
      NetUse(cFile, 5)
      lOpened := .T.
      LogWrite("GetBuffer_BuildAll: opened " + cFile + " for all-codes scan")
   RECOVER
      lErr := .T.
   END SEQUENCE
   ErrorBlock( bOldErr )
   IF lErr
      LogWrite("GetBuffer_BuildAll: WARNING - cannot open " + cFile + ", returning empty")
      dbSelectArea(nOldArea)
      RETURN ""
   ENDIF
ELSE
   dbSelectArea(cFile)
   LogWrite("GetBuffer_BuildAll: " + cFile + " already open in area " + LTrim(Str(Select())))
ENDIF

nFPos := FieldPos(cKeyField)
LogWrite("GetBuffer_BuildAll: FieldPos(" + cKeyField + ")=" + LTrim(Str(nFPos)) + " RecCount=" + LTrim(Str(RecCount())))

IF nFPos == 0
   LogWrite("GetBuffer_BuildAll: ERROR - field " + cKeyField + " not found in " + cFile)
   IF lOpened
      dbCloseArea()
   ENDIF
   dbSelectArea(nOldArea)
   RETURN ""
ENDIF

nOldRec := RecNo()
dbGoTop()
DO WHILE !EOF()
   IF cKeyField == "value_id"
      // Match critBrowse format: Str(value_id, 9, 3)
      cResult += Str(FieldGet(nFPos), 9, 3) + "_"
   ELSE
      // Match critBrowse format: raw field value (no trim, same as Eval(bKeyCol))
      cResult += FieldGet(nFPos) + "_"
   ENDIF
   dbSkip()
ENDDO
dbGoto(nOldRec)

// Close the table if we opened it (don't close if it was already open)
IF lOpened
   dbCloseArea()
ENDIF

dbSelectArea(nOldArea)
LogWrite("GetBuffer_BuildAll: " + cFile + " -> built all-codes buffer (" + LTrim(Str(Len(cResult))) + " chars): " + Left(cResult, 80))

RETURN cResult

// ============================================
// CreateCondDb - Create filtered t_ordPre file (from THEREPO.PRG line 726)
//
// Exact replica of original flow:
//   1. Select the leading DBF (d_ord)
//   2. COPY TO t_ordPre FOR ShaiCond() .AND. cbExtraCond
//   3. PrepareGenDb in DoSched later opens t_ordPre as alias "d_ord"
//      and copies from the already-filtered records into t_ord
// ============================================
FUNCTION CreateCondDb( oRep, cDbf, aTstBlks, aBuf )
LOCAL nOldArea := Select()
LOCAL cTmpFile := GetUserInfo():cTempDir + oRep:cPrepDbf

LogWrite("CreateCondDb: cDbf=" + cDbf + " cPrepDbf=" + oRep:cPrepDbf + ;
         " tmpFile=" + cTmpFile)

// Select the leading file (d_ord)
SELECT (Select(cDbf))

// Delete old t_ordPre if exists
IF FILE(cTmpFile + ".dbf")
   IF Select(oRep:cPrepDbf) != 0
      (oRep:cPrepDbf)->(dbCloseArea())
   ENDIF
   FERASE(cTmpFile + ".dbf")
   FERASE(cTmpFile + ".cdx")
ENDIF

// Go to top of d_ord
dbGoTop()

@ 2,0 SAY PadR("Creating Query file...", 80) COLOR "W+/R"

// COPY TO t_ordPre FOR ShaiCond() .AND. cbExtraCond
// This is the exact same logic as THEREPO.PRG lines 958-965 (no-smartindex path):
//   COPY TO (::cTempFileDir+::cPrepDbf)
//     FOR ShaiCond(::aTstBlocks,::oScrl,recno(),::cTypeOfReport == "REPORT")
//     .AND. IF(VALTYPE(::cbExtraCond)=="B", Eval(::cbExtraCond), .T.)
COPY TO (cTmpFile) ;
   FOR ShaiCond(aTstBlks, NIL, RecNo(), .T.) ;
   .AND. IIF(ValType(oRep:cbExtraCond) == "B", Eval(oRep:cbExtraCond), .T.)

@ 2,0 SAY PadR(" ", 80) COLOR "W+/B"

LogWrite("CreateCondDb: COPY TO completed, file exists=" + IIF(FILE(cTmpFile + ".dbf"), "T", "F"))

dbSelectArea(nOldArea)
RETURN NIL

// ============================================
// SchedIndex - Построение временных индексов d_stock (из schedindex.prg)
// Вызывается перед ordsetfocus(1) в DoSched (sch_reqm строка 580)
// Обновляет seq_no из c_hierar, потом создаёт 6 условных тегов
// в d_stockt.cdx для поиска по локации (CZ/IL/06).
//
// Индексный файл создаётся в G:\USERS\TAPI_SCH\ — как в оригинале.
// Это сетевой путь видимый ADS серверу, поэтому ADS Error 5020 не будет.
// ============================================
FUNCTION SchedIndex()
LOCAL nOldArea := Select()
LOCAL cIdxFile := "G:\USERS\TAPI_SCH\d_stockt"

LogWrite("SchedIndex: starting, idxFile=" + cIdxFile)

// Удалить старый индексный файл
IF FILE(cIdxFile + ".cdx")
   FERASE(cIdxFile + ".cdx")
   LogWrite("SchedIndex: удалён старый " + cIdxFile + ".cdx")
ENDIF

// === Фаза 1: Обновить seq_no из c_hierar ===
DbSelectArea("d_stock")
d_stock->(dbSetFilter({|| d_stock->wh1 + d_stock->wh2 + d_stock->wh3 + d_stock->wh4 + d_stock->wh6 > 0}))
d_stock->(dbGoTop())

LogWrite("SchedIndex: обновляю seq_no из c_hierar...")
DO WHILE !d_stock->(Eof())
   IF d_stock->(RLock())
      d_stock->seq_no := GetHie_2(d_stock->tol_id, d_stock->volt_id, d_stock->tc_id)
      d_stock->(dbUnlock())
   ENDIF
   @ 10, 1 SAY d_stock->(RecNo())
   d_stock->(dbSkip())
ENDDO
CLS

// Снять фильтр после обновления seq_no
d_stock->(dbClearFilter())
d_stock->(dbGoTop())

// === Фаза 2: Создать 6 условных тегов (как в schedindex.prg) ===
LogWrite("SchedIndex: создаю теги в " + cIdxFile)

INDEX ON ptype_id+pline_id+size_id+Str(value_id,9,3)+Descend(seq_no)+DtoS(dadd_rec) ;
   TAG viva_CZ TO (cIdxFile) FOR &(LOC == 'CZ' .AND. wh3+wh4 > 0)
@ 10, 1 SAY "viva_CZ"
LogWrite("SchedIndex: тег viva_CZ создан")

INDEX ON ptype_id+pline_id+size_id+Str(value_id,9,3)+Descend(seq_no)+DtoS(dadd_rec) ;
   TAG viva_IL TO (cIdxFile) FOR &(LOC == 'IL' .AND. wh3+wh4 > 0)
@ 10, 1 SAY "viva_IL"
LogWrite("SchedIndex: тег viva_IL создан")

INDEX ON ptype_id+pline_id+size_id+Descend(seq_no)+DtoS(dadd_rec) ;
   TAG U_viva_CZ TO (cIdxFile) FOR &(LOC == 'CZ' .AND. wh3+wh4 > 0)
@ 10, 1 SAY "U_viva_CZ"
LogWrite("SchedIndex: тег U_viva_CZ создан")

INDEX ON ptype_id+pline_id+size_id+Descend(seq_no)+DtoS(dadd_rec) ;
   TAG U_viva_IL TO (cIdxFile) FOR &(LOC == 'IL' .AND. wh3+wh4 > 0)
@ 10, 1 SAY "U_viva_IL"
LogWrite("SchedIndex: тег U_viva_IL создан")

INDEX ON ptype_id+pline_id+size_id+Str(value_id,9,3)+Descend(seq_no)+DtoS(dadd_rec) ;
   TAG viva_06 TO (cIdxFile) FOR &(LOC $ 'IL_CZ' .AND. wh6 > 0)
@ 10, 1 SAY "viva_06"
LogWrite("SchedIndex: тег viva_06 создан")

INDEX ON ptype_id+pline_id+size_id+Descend(seq_no)+DtoS(dadd_rec) ;
   TAG U_viva_06 TO (cIdxFile) FOR &(LOC $ 'IL_CZ' .AND. wh6 > 0)
@ 10, 1 SAY "U_viva_06"
LogWrite("SchedIndex: тег U_viva_06 создан")

LogWrite("SchedIndex: завершён, d_stockt exists=" + IIF(FILE(cIdxFile + ".cdx"), "T", "F"))

dbSelectArea(nOldArea)
RETURN NIL

// GetHie_2 - Get hierarchy priority for stock record (from schedindex.prg)
// Looks up c_hierar by tol_id+volt_id+tc_id, returns 2-char priority level
FUNCTION GetHie_2(tol_id, volt_id, tc_id)
LOCAL nOldSel := Select()
LOCAL cRetVal := "  "

DbSelectArea("c_hierar")
c_hierar->(ordSetFocus("hierar"))
c_hierar->(dbSeek(tol_id + volt_id + tc_id))
IIF(Found(), cRetVal := SubStr(c_hierar->priorlevel, 1, 2), NIL)

dbSelectArea(nOldSel)
RETURN HB_AnsiToOem(cRetVal)

// ============================================
// ShaiCond - Test record against criteria (from PRNCRIT.PRG line 4568)
// ============================================
FUNCTION ShaiCond( aTestBlks, oScrl, cField, lReport )
LOCAL aIndic
LOCAL nLen, nTrues := 0, i

DEFAULT lReport TO .T.

aIndic := GetIndicators()
IF aIndic == NIL
   RETURN .T.
ENDIF
nLen := Len(aIndic)

FOR i := 1 TO nLen
   IF aIndic[i]
      IF Eval(aTestBlks[i])
         nTrues++
      ENDIF
   ELSE
      nTrues++
   ENDIF
NEXT

RETURN (nTrues == nLen)

// SchedBr (real: BMS/SCH_FORM.PRG)
CREATE CLASS SchedBr
   VAR oBro
   METHOD New()
END CLASS

METHOD New() CLASS SchedBr
RETURN Self

// CheckIndex (real: BMS/AVXUTI.PRG line 197 - CheckIndexes)
// In Clipper, 10-char function name truncation mapped CheckIndex -> CheckIndexes
FUNCTION CheckIndex( cAlias, cIndex, cKey, lReIndex, cFor, lUni )
LOCAL nOldArea := SELECT()

   // DBF field names are limited to 10 chars. The original Clipper code uses long
   // names in index key expressions (strings). #xtranslate only fixes source-level
   // identifiers, not runtime strings. Fix the macro-compiled key expression here.
   cKey := StrTran( cKey, "Sched_Group_Seq", "Sched_Grou" )
   cKey := StrTran( cKey, "Sched_source",    "Sched_sour" )

   LogWrite( "CheckIndex: tag=" + cAlias + " idx=" + cIndex + " key=" + cKey + ;
             " reindex=" + IIF( lReIndex, "T", "F" ) )

   IF !( FILE( cIndex + ".cdx" ) ) .OR. ( lReIndex )
      IF !Empty( lUni )
         IF !Empty( cFor )
            IF ValType( cFor ) == "B"
               INDEX ON &cKey TAG ( cAlias ) TO ( cIndex ) FOR Eval( cFor ) UNIQUE
            ELSE
               INDEX ON &cKey TAG ( cAlias ) TO ( cIndex ) FOR &cFor UNIQUE
            ENDIF
         ELSE
            INDEX ON &cKey TAG ( cAlias ) TO ( cIndex ) UNIQUE
         ENDIF
      ELSE
         IF !Empty( cFor )
            IF ValType( cFor ) == "B"
               INDEX ON &cKey TAG ( cAlias ) TO ( cIndex ) FOR Eval( cFor )
            ELSE
               INDEX ON &cKey TAG ( cAlias ) TO ( cIndex ) FOR &cFor
            ENDIF
         ELSE
            INDEX ON &cKey TAG ( cAlias ) TO ( cIndex )
         ENDIF
      ENDIF
   ENDIF

   Select( nOldArea )
RETURN NIL

// --- Business logic stubs ---

// GetSeqBstat / GetSeqPurp - return sort sequence for business status/purpose
// Used in INDEX ON key at PreAvail(817). Original functions likely seek in c_bstat/c_bpurp
// and return a seq_no field. Returning the code itself gives alphabetical ordering.
FUNCTION GetSeqBstat( cBstat )
RETURN IIF( cBstat == NIL, "", cBstat )

FUNCTION GetSeqPurp( cPurp )
RETURN IIF( cPurp == NIL, "", cPurp )

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

// GetHie_2 - now implemented as real function above (in SchedIndex section)
// Old stub that returned "1" has been replaced.

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

// TableTranslate (real: BMS/LIB/TABTRANS.PRG - inherits TabBase)
CREATE CLASS TableTranslate FROM TabBase
   METHOD Translate( cValue ) INLINE cValue
END CLASS

// FilLock already defined above

// MrkOrdDue (real: BMS/AVXFUNCS.PRG line 3048)
FUNCTION MrkOrdDue( lUseAlias, cDbf )
   HB_SYMBOL_UNUSED( lUseAlias )
   HB_SYMBOL_UNUSED( cDbf )
RETURN Date() + 30

// TabBase (real: BMS/LIB/TABBASE.PRG - class)
CREATE CLASS TabBase
   VAR lWasOpened
   VAR cFileName
   VAR cFileStructure
   VAR aIndexList
   VAR aIndexCaptions
   VAR nLastOrder
   VAR nPresentOrder
   VAR cAlias
   VAR nIndexPointer
   METHOD init( cFileName )
   METHOD New( cFileName )
   METHOD setIndexList()
   METHOD SetOrder( nOrder )
   METHOD ResetOrder()
   METHOD xopen( cDirectory, lMode, cRdd )
   METHOD xopenTemp( cDirectory, lMode, cRdd )
   METHOD close()
END CLASS

METHOD init( cFileName ) CLASS TabBase
   ::cFileName      := cFileName
   ::cAlias         := cFileName
   ::lWasOpened     := .F.
   ::aIndexList     := {}
   ::aIndexCaptions := {}
   ::nPresentOrder  := 0
   ::nLastOrder     := 0
   ::nIndexPointer  := 0
RETURN Self

METHOD New( cFileName ) CLASS TabBase
RETURN ::init( cFileName )

METHOD setIndexList() CLASS TabBase
   // Real implementation reads SysKeys.dbf via GetFileIndexInfo()
   // For now, build index list from currently open tags
   LOCAL i, nCount
   ::aIndexList     := {}
   ::aIndexCaptions := {}
   IF ! Empty( Select( ::cFileName ) )
      nCount := (::cFileName)->( OrdCount() )
      FOR i := 1 TO nCount
         AAdd( ::aIndexList, (::cFileName)->( OrdName( i ) ) )
         AAdd( ::aIndexCaptions, (::cFileName)->( OrdName( i ) ) + ;
               " KEY: " + (::cFileName)->( OrdKey( i ) ) )
      NEXT
   ENDIF
   ::nPresentOrder := IIF( ! Empty( ::aIndexList ), 1, 0 )
RETURN Self

METHOD SetOrder( nOrder ) CLASS TabBase
   ::nLastOrder := ::nPresentOrder
   ::nPresentOrder := nOrder
   IF ! Empty( Select( ::cFileName ) )
      (::cFileName)->( OrdSetFocus( nOrder ) )
   ENDIF
RETURN Self

METHOD ResetOrder() CLASS TabBase
   ::nPresentOrder := ::nLastOrder
   IF ! Empty( Select( ::cFileName ) )
      (::cFileName)->( OrdSetFocus( ::nPresentOrder ) )
   ENDIF
RETURN Self

METHOD xopen( cDirectory, lMode, cRdd ) CLASS TabBase
   LOCAL cDbfDir, lOpened
   DEFAULT lMode TO .T.
   IF cDirectory == NIL
      IF GetUserInfo() == NIL
         cDbfDir := ""
      ELSEIF "\" $ ::cFileName
         cDbfDir := SubStr( ::cFileName, 1, RAt( "\", ::cFileName ) )
         ::cFileName := SubStr( ::cFileName, RAt( "\", ::cFileName ) + 1 )
      ELSE
         cDbfDir := GetUserInfo():cDbfDir
      ENDIF
   ELSE
      cDbfDir := cDirectory
   ENDIF
   ::lWasOpened := lOpened := ! Empty( Select( ::cFileName ) )
   IF ! lOpened
      lOpened := NetUse( ::cFileName, 5, cRdd, lMode, , cDbfDir )
      ::lWasOpened := .F.
   ENDIF
   IF lOpened
      ::cFileStructure := (::cFileName)->( DbStruct() )
   ENDIF
RETURN lOpened

METHOD xopenTemp( cDirectory, lMode, cRdd ) CLASS TabBase
   // Like xopen but uses temp directory by default
   LOCAL cDbfDir, lOpened
   DEFAULT lMode TO .T.
   IF cDirectory == NIL
      cDbfDir := GetUserInfo():cTempDir
   ELSE
      cDbfDir := cDirectory
   ENDIF
   ::lWasOpened := lOpened := ! Empty( Select( ::cFileName ) )
   IF ! lOpened
      // Force DBFCDX for local temp files
      IF Left( cDbfDir, 1 ) $ "CD"
         cRdd := "DBFCDX"
      ENDIF
      lOpened := NetUse( ::cFileName, 5, cRdd, lMode, , cDbfDir )
      ::lWasOpened := .F.
   ENDIF
   IF lOpened
      ::cFileStructure := (::cFileName)->( DbStruct() )
      IF ! Empty( ::aIndexList )
         (::cFileName)->( DbClearIndex() )
         AEval( ::aIndexList, {| element | (::cFileName)->( OrdSetFocus( element ) ) } )
      ENDIF
   ENDIF
RETURN lOpened

METHOD close() CLASS TabBase
   IF ! ::lWasOpened .AND. ! Empty( Select( ::cFileName ) )
      (::cFileName)->( DbCloseArea() )
   ENDIF
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
// Tries to lock the current record and shows progress at aPos. Returns .T. on success.
FUNCTION GetRec( aPos )
   HB_SYMBOL_UNUSED( aPos )
RETURN .T.

// TestAvail (real: BMS/SCH_ORDM.PRG line 1700)
// TestAvail (real: BMS/SCH_ORDM.PRG) - tests c_expqty for errors
// Returns { {tol_ids}, {seq_nos} } array pair
FUNCTION TestAvail()
RETURN { {}, {} }
