/*
 * main.prg - Entry point for SCH_REQM Harbour module
 * Initializes ADS, GTWVG, logging, error handler
 * Then calls Sched_R3() from sch_reqm.prg
 */

#include "ads.ch"
#include "hbgtinfo.ch"

REQUEST DBFCDX
REQUEST ADS
REQUEST HB_CODEPAGE_HE862

PROCEDURE Main()

   LOCAL bOldError

   // Set up error handler with logging
   bOldError := ErrorBlock( {|e| SchReqmErrorHandler( e ) } )

   // Initialize ADS RDD
   rddRegister( "ADS", 1 )
   rddSetDefault( "ADS" )
   SET SERVER REMOTE
   SET FILETYPE TO CDX
   SET DEFAULT TO G:\TEST

   // Hebrew codepage
   HB_CDPSELECT( "HE862" )
   hb_setTermCP( "CP862" )

   // GTWVG window title
   hb_gtInfo( HB_GTI_WINTITLE, "SCH_REQM - Auto Scheduling" )

   // Start logging
   LogWrite( "=== SCH_REQM started " + DToC( Date() ) + " " + Time() + " ===" )
   LogWrite( "User: " + fn_WhoAmI() )
   LogWrite( "Default path: " + SET( _SET_DEFAULT ) )

   // Run the scheduler
   Sched_R3()

   // Cleanup
   LogWrite( "=== SCH_REQM finished " + DToC( Date() ) + " " + Time() + " ===" )
   CLOSE ALL

   ErrorBlock( bOldError )

RETURN
