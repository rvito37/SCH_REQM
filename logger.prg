/*
 * logger.prg - Logging system for SCH_REQM
 * Writes to sch_reqm.log for remote debugging
 * Based on PDC-clean/PDC/BMSBAR.PRG LogWrite()/BmsErrorHandler()
 */

#include "fileio.ch"

STATIC s_cLogFile := "sch_reqm.log"

// ============================================
// LogWrite - Write a message to the log file
// ============================================
FUNCTION LogWrite( cMsg )
   LOCAL hFile
   LOCAL cLine

   IF cMsg == NIL
      cMsg := ""
   ENDIF

   cLine := DToC( Date() ) + " " + Time() + " " + cMsg + Chr(13) + Chr(10)

   hFile := FOpen( s_cLogFile, FO_READWRITE + FO_SHARED )
   IF hFile == -1
      hFile := FCreate( s_cLogFile )
   ENDIF

   IF hFile != -1
      FSeek( hFile, 0, FS_END )
      FWrite( hFile, cLine )
      FClose( hFile )
   ENDIF

RETURN NIL

// ============================================
// LogSetFile - Change the log file path
// ============================================
FUNCTION LogSetFile( cFile )
   IF cFile != NIL
      s_cLogFile := cFile
   ENDIF
RETURN s_cLogFile

// ============================================
// SchReqmErrorHandler - Error handler with call stack logging
// ============================================
FUNCTION SchReqmErrorHandler( e )
   LOCAL cMsg
   LOCAL i, cProc

   cMsg := "Error: " + e:description
   IF ! Empty( e:operation )
      cMsg += " / " + e:operation
   ENDIF

   LogWrite( "*** ERROR: " + cMsg )
   LogWrite( "    SubSystem: " + e:subSystem )
   LogWrite( "    SubCode:   " + LTrim( Str( e:subCode ) ) )
   LogWrite( "    OsCode:    " + LTrim( Str( e:osCode ) ) )
   LogWrite( "    FileName:  " + iif( e:filename != NIL, e:filename, "" ) )

   // Log call stack
   FOR i := 1 TO 30
      cProc := ProcName( i )
      IF Empty( cProc )
         EXIT
      ENDIF
      LogWrite( "    Call stack[" + LTrim( Str( i ) ) + "]: " + ;
                cProc + "(" + LTrim( Str( ProcLine( i ) ) ) + ")" )
   NEXT

   Alert( cMsg )
   BREAK( e )

RETURN NIL
