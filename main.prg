#include "ads.ch"
#include "DbInfo.ch"
//#include "hbgtinfo.ch"

REQUEST HB_LANG_HE862
REQUEST DBFCDX
REQUEST ADS

PROCEDURE Main

SETMODE( 25, 80 )
rddRegister( "ADS", 1 )
rddsetdefault( "ADS" )

AdsSetServerType( ADS_REMOTE_SERVER + ADS_AIS_SERVER )
SET FILETYPE TO CDX
SET EPOCH TO 1990
SET DATE BRITISH
SET DELETED ON

USE d_prom SHARED NEW
ALERT( "d_prom opened SHARED. RecCount=" + LTrim(Str(RecCount())) + ". Check parallel access now." )
d_prom->( dbCloseArea() )

CLOSE ALL

RETURN