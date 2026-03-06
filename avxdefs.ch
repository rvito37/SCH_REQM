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

// DBCREATE RDD mapping: Clipper "DBFCDXAX" не существует в Harbour.
// Temp файлы на G:\USERS\TAPI_SCH\ — ADS обслуживает этот путь.
// Маппим на вызов без 3-го параметра → default RDD (ADS).
#xtranslate DBCREATE( <file>, <struct>, "DBFCDXAX" ) => DBCREATE( <file>, <struct> )

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

// DBF field name truncation fix for PrepareGenDb custom fields.
// DBF limits field names to 10 chars. The original Clipper code uses long names
// like Sched_source (12ch) and Sched_Group_Seq (15ch) which get truncated to
// Sched_sour and Sched_Grou in the DBF. Clipper silently truncated field lookups;
// Harbour does not, causing "Variable does not exist" errors.
// Map the long identifier forms to truncated DBF field names via preprocessor.
#xtranslate Sched_source    => Sched_sour
#xtranslate Sched_Group_Seq => Sched_Grou

// Also fix the FIELD declaration to use truncated names
FIELD Sched_sour, Sched_Grou

// COPY TO: temp файлы на G:\ — ADS обслуживает, override не нужен.
// Стандартный std.ch COPY TO использует RDD текущей workarea (ADS).

// dbsetindex wrapper: ADS requires table and index on same server.
// Temp indexes (d_stocktmp.cdx) may be local while table is on ADS.
// Route through SafeDbSetIndex() which checks file existence and catches errors.
#xtranslate dbsetindex( <x> ) => SafeDbSetIndex( <x> )

// SchedIndex hook: sch_reqm.prg line 577 displays this unique message right before
// the stock index setup (lines 579-581). Intercept it to call SchedIndex() which
// builds d_stocktmp.cdx (seq_no update + 6 conditional tags). This replaces the
// commented-out MYRUN("G:\SOURCE\test.exe") at line 578.
// Use DevPos+DevOut to avoid circularity with @ SAY #command pattern.
#command @ 9, 11 SAY "Preparing tempery files : Stock files index" =>;
   DevPos(9, 11) ;; DevOut("Preparing tempery files : Stock files index") ;; SchedIndex()

// Main loop progress bar: intercept @ 8,11 SAY to draw a visual progress bar
// when the text contains a percentage (lines 614, 733 in sch_reqm.prg).
// SchedIndex uses DevPos/DevOut to bypass this hook.
#command @ 8, 11 SAY <x> => SchedMainSay(<x>)

// FrzLn optimization: FrzLn() (sch_reqm.prg:1733) opens and closes D_Frzln
// via ADS for EVERY record in the scheduling loop — extremely slow.
// Prevent closing so NetUse reuses the already-open handle on subsequent calls.
#xtranslate DbCloseArea( "D_frzln" ) =>

// REQUEST for ADS, codepage, and CT3 functions used in macro-compiled index keys
REQUEST DBFCDX
REQUEST ADS
REQUEST HB_CODEPAGE_HE862
REQUEST DESCEND
