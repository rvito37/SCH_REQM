// schedidx2.prg - Creates d_stockt.cdx index tags for scheduling
// Runs as a SEPARATE PROCESS (like original schedindex via MYRUN)
// because ADS ORDCREATE fails in the same process that already has d_stock open.
// Called from SchedIndex() in stubs.prg after Phase 1 (seq_no update).

#include "ads.ch"

REQUEST ADS
REQUEST DESCEND

PROCEDURE Main

rddRegister("ADS", 1)
rddSetDefault("ADS")

SET SERVER REMOTE
SET FILETYPE TO CDX
SET EPOCH TO 1990
SET DATE BRITISH
SET DELETED ON

IF FILE("G:\USERS\TAPI_SCH\d_stockt.cdx")
   FErase("G:\USERS\TAPI_SCH\d_stockt.cdx")
ENDIF

USE d_stock SHARED NEW

INDEX ON ptype_id+pline_id+size_id+str(value_id,9,3)+Descend(seq_no)+DtoS(dadd_rec) TAG viva_CZ TO G:\USERS\TAPI_SCH\d_stockt FOR &(LOC == 'CZ' .AND. wh3+wh4 > 0)
INDEX ON ptype_id+pline_id+size_id+str(value_id,9,3)+Descend(seq_no)+DtoS(dadd_rec) TAG viva_IL TO G:\USERS\TAPI_SCH\d_stockt FOR &(LOC == 'IL' .AND. wh3+wh4 > 0)
INDEX ON ptype_id+pline_id+size_id+Descend(seq_no)+DtoS(dadd_rec) TAG U_viva_CZ TO G:\USERS\TAPI_SCH\d_stockt FOR &(LOC == 'CZ' .AND. wh3+wh4 > 0)
INDEX ON ptype_id+pline_id+size_id+descend(seq_no)+DTOS(dadd_rec) TAG U_viva_IL TO G:\USERS\TAPI_SCH\d_stockt FOR &(LOC == 'IL' .AND. wh3+wh4 > 0)
INDEX ON ptype_id+pline_id+size_id+str(value_id,9,3)+descend(seq_no)+DTOS(dadd_rec) TAG viva_06 TO G:\USERS\TAPI_SCH\d_stockt FOR &(LOC $ 'IL_CZ' .AND. wh6 > 0)
INDEX ON ptype_id+pline_id+size_id+descend(seq_no)+DTOS(dadd_rec) TAG U_viva_06 TO G:\USERS\TAPI_SCH\d_stockt FOR &(LOC $ 'IL_CZ' .AND. wh6 > 0)

CLOSE ALL

RETURN
