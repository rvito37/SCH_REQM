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

// DBCREATE RDD mapping for local/temp files
// In Clipper, DBFCDXAX was a real RDD and NIL used the default (DBFCDX).
// In Harbour, default RDD is ADS (for network), but temp files are local.
// Map both "DBFCDXAX" and NIL to "DBFCDX" so DBCREATE uses local driver.
#xtranslate DBCREATE( <file>, <struct>, "DBFCDXAX" ) => DBCREATE( <file>, <struct>, "DBFCDX" )
#xtranslate DBCREATE( <file>, <struct>, NIL )         => DBCREATE( <file>, <struct>, "DBFCDX" )

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

// NETCLOSE - close a database alias
#command NETCLOSE <alias> => <alias>->( dbCloseArea() )

// ============================================
// Check box GET (from CHECKS.CH / CHECKDEF.CH)
// ============================================
#define CHECK_BOX "X"
#define CHECK_NUM_IVARS 1
#translate :checkGsb => :cargo\[1\]

#command @ <row>, <col> GET <var> CHECKBOX <cStr>                    ;
      =>                                                             ;
         SetPos(<row>, <col>)                                        ;
         ; Aadd(GetList,                                             ;
                CheckGetNew({|x| iif(x == NIL, <var>, <var> := x) }, ;
                     <(var)>, <cStr>))

// ============================================
// Radio button GET (from RADIOS.CH / RADIODEF.CH)
// ============================================
#define RADIO_BUTTON Chr(4)
#define RADIO_NUM_IVARS 2
#translate :radioGsb  => :cargo\[1\]
#translate :radioGets => :cargo\[2\]

#command @ <row>, <col> GET <var>                                ;
                        RADIO <radios,...>                        ;
                        [BLOCKS <blk>]                           ;
      =>                                                         ;
         SetPos(<row>, <col>)                                    ;
         ; RadioGets({|x| iif(x == NIL, <var>, <var> := x) },   ;
                     <(var)>, <radios>, GetList , <blk>)         ;
         ; DrawRadios(GetList, Atail(GetList))

// ============================================
// Misc BMS defines
// ============================================
#define FRAMECAPTION  Chr(201)+Chr(205)+Chr(187)+Chr(186)+Chr(188)+Chr(205)+Chr(200)+Chr(186)
#define ALERT_WARN    "W+/R, W+/B"

// Field declarations for custom fields added by PrepareGenDb
// These are needed so Harbour resolves (alias)->Sched_source as field access
// not memvar access. DBF truncates to 10 chars: Sched_sour, Sched_Grou
FIELD Sched_source, Sched_Group_Seq

// REQUEST for ADS and codepage
REQUEST DBFCDX
REQUEST ADS
REQUEST HB_CODEPAGE_HE862
