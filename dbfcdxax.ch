/*
 * Source     : DBFCDXAX.CH - Harbour compatibility wrapper
 * Description: Maps old Clipper Advantage DBFCDXAX RDD commands
 *              to Harbour's rddads (ADSCDX) equivalents.
 *
 * Original Copyright 1994-1998 - Extended Systems, Inc.
 * Harbour adaptation for AVX BMS project
 */

#include "ads.ch"

REQUEST ADSCDX
REQUEST DBFCDX

#command SET TAGORDER TO <order>                                           ;
      => ordSetFocus( <order> )

#command SET TAGORDER TO                                                   ;
      => ordSetFocus( 0 )

#command SET ORDER TO TAG <(tag)>                                          ;
         [OF <(bag)>]                                                      ;
         [IN <(bag)>]                                                      ;
      => ordSetFocus( <(tag)> [, <(bag)>] )

#command SET TAG TO <(tag)>                                                ;
         [OF <(bag)>]                                                      ;
         [IN <(bag)>]                                                      ;
      => ordSetFocus( <(tag)> [, <(bag)>] )

#command SET TAG TO                                                        ;
      => ordSetFocus( 0 )

#command SET PASSWORD TO <(password)>                                      ;
      => AX_SetPass( <(password)> )

#command SET PASSWORD TO                                                   ;
      => AX_SetPass( "" )

#command SET EXPRESSION ENGINE <x:ON,OFF>                                  ;
      => AX_ExprEngine( Upper( <(x)> ) == "ON" )

#command SET MEMOBLOCK TO <value>                                          ;
      => AX_SetMemoBlock( <value> )

#command DELETE TAG ALL                                                    ;
         [OF <(bag)>]                                                      ;
         [IN <(bag)>]                                                      ;
      => AX_KillTag( .T., <(bag)> )

#command CLEAR SCOPE                                                       ;
      => AX_ClrScope( 0 )                                                  ;
       ; AX_ClrScope( 1 )

#xcommand SET SCOPETOP TO <value>                                          ;
      => AX_SetScope( 0, <value> )

#xcommand SET SCOPETOP TO                                                  ;
      => AX_ClrScope( 0 )

#xcommand SET SCOPEBOTTOM TO <value>                                       ;
      => AX_SetScope( 1, <value> )

#xcommand SET SCOPEBOTTOM TO                                               ;
      => AX_ClrScope( 1 )

#command SET SCOPE TO                                                      ;
      => AX_ClrScope( 0 )                                                  ;
       ; AX_ClrScope( 1 )

#command SET SCOPE TO <value>                                              ;
      => AX_SetScope( 0, <value> )                                         ;
       ; AX_SetScope( 1, <value> )

/*
 * Constants for AX_GetServerType() - Clipper compatibility
 */
#ifndef ADS_MGMT_NETWARE_SERVER
#define ADS_MGMT_NETWARE_SERVER        1
#endif
#ifndef ADS_MGMT_NT_SERVER
#define ADS_MGMT_NT_SERVER             2
#endif
#ifndef ADS_MGMT_LOCAL_SERVER
#define ADS_MGMT_LOCAL_SERVER          3
#endif

/*
 * Constants for AX_LockOwner()
 */
#define ADS_MGMT_NO_LOCK               1
#define ADS_MGMT_RECORD_LOCK           2
#define ADS_MGMT_FILE_LOCK             3

/*
 * Constants for AX_OpenTables()
 */
#define ADS_MGMT_PROPRIETARY_LOCKING   1
#define ADS_MGMT_CDX_LOCKING           2
#define ADS_MGMT_NTX_LOCKING           3
