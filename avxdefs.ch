/*
 * avxdefs.ch - Master include file for AVX BMS (Harbour)
 * Reconstructed for SCH_REQM module migration
 * Includes all standard Harbour headers + AVX-specific defines
 */

// Standard Harbour headers
#include "common.ch"
#include "inkey.ch"
#include "setcurs.ch"
#include "set.ch"
#include "dbstruct.ch"
#include "directry.ch"
#include "fileio.ch"
#include "getexit.ch"
#include "box.ch"
#include "hbclass.ch"

// ADS CDX compatibility (maps DBFCDXAX commands to Harbour ADS)
#include "dbfcdxax.ch"

// DBFCDXAX RDD name mapping for DBCREATE/DBUSEAREA calls
// In Clipper, DBFCDXAX was a real RDD. In Harbour, local files use DBFCDX.
// Temp files are always local, so DBFCDXAX -> DBFCDX for DBCREATE.
#xtranslate DBCREATE( <file>, <struct>, "DBFCDXAX" ) => DBCREATE( <file>, <struct>, "DBFCDX" )

// LFNLIB stub (not needed in Harbour - native LFN support)
// #include "LFNLIB.ch"

// COMPILE() macro - maps Clipper COMPILE() to Harbour macro
#define COMPILE(c) &("{||" + c + "}")

// ============================================
// AVX BMS Framework defines
// ============================================

// Alert box styles
#define ALERT_STD    "W+/R, W+/B"
#define ALERT_ERR    "W+/R, W+/B"
#define ALERT_WAR    "W+/R, W+/B"

// Box drawing characters
#define B_DOUBLE     Chr(201) + Chr(205) + Chr(187) + Chr(186) + Chr(188) + Chr(205) + Chr(200) + Chr(186)
#define B_SINGLE     Chr(218) + Chr(196) + Chr(191) + Chr(179) + Chr(217) + Chr(196) + Chr(192) + Chr(179)

// GET colors
#define GETCOLORS    "W+/B, W+/R"

// F1 help key handler
#translate F1 PRESSED => SetKey(K_F1, {|| HelpMe()})

// Network file open modes
#define USE_EXCLUSIVE   .F.
#define USE_NEW         .T.

// Standard retry count for network operations
#define STD_RETRY    5

// XREAD - extended READ with keyboard handling
#translate XREAD => READ

// REQUEST for ADS and codepage
REQUEST DBFCDX
REQUEST ADS
REQUEST HB_CODEPAGE_HE862
