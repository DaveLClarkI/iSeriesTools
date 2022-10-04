000100888888**free
000200000000//==============================================================================
000300000000// Program Name:      AC29UPDR -- Job Control Defaults Update
000400000000// Programmer:        Dave L Clark I
000500000000// Date:              November 8, 2018
000600000000// Project/Request #: IN-58 Create Commands to Maintain Job Control Defaults
000700000000// Purpose:           This command processing program performs maintenance on
000800000000//                    the Job Control Defaults (AC29) file by job name.
000900000000//------------------------------------------------------------------------------
001000000000//         Special Programming Logic / Considerations
001100000000//
001200000000// NONE
001300000000//
001400000000//------------------------------------------------------------------------------
001500000000//         Modification Log
001600000000//
001700000000// Mod#    Date       User       Description
001800000000// ---- ---------- ---------- --------------------------------------------------
001900000000// M000 11/08/2018 DLCLARK    Initial design.
002000000000//==============================================================================
002100000000
002200000000ctl-opt MAIN(AC29UPDR) AlwNull(*UsrCtl) Debug Option(*SrcStmt:*NoDebugIo)
002300000000        DatFmt(*ISO) TimFmt(*ISO) DftActGrp(*No) ActGrp(*Caller) BndDir('WSBNDDIR');
002400000000
002500000000/include *libl/qrpglesrc,ut010SV                 // general utilities service program
002600000000
002700000000//==============================================================================
002800000000// Begin main procedure definition
002900000000//==============================================================================
003000000000dcl-proc AC29UPDR;
003100000000  dcl-pi *n             extpgm;
003200000000    pJobName            char(6);
003300000000    pAction             char(10);
003400000000    pTitle              char(25);
003500000000    pProc               char(7);
003600000000    pDate1              char(7);
003700000000    pDate2              char(7);
003800000000    pSelOpt             char(6);
003900000000    pOption1            char(1);
004000000000    pOption2            char(1);
004100000000    pOption3            char(1);
004200000000    pOption4            char(1);
004300000000    pOption5            char(1);
004400000000    pLocOpt             char(3);
004500000000    pIssueTo            char(10);
004600000000    pUseOpt1            char(1);
004700000000    pUseOpt2            char(1);
004800000000    pUseOpt3            char(1);
004900000000    pUseOpt4            char(1);
005000000000    pUseNbr             packed(5:0);
005100000000    pUsrPwds            char(48);
005200000000  end-pi;
005300000000
005400000000  dcl-s iFileName       char(21) inz('REV460/AC29');
005500000000  dcl-f AC29            disk extdesc('REV460/AC29') extfile(iFileName)
005600000000                        keyed usage(*update:*output:*delete) usropn;
005700000000  dcl-ds AC29ds         likerec(AC29rf:*all);
005800000000  dcl-s  iCaller        char(10);
005900000000  dcl-s  msgdata        varchar(100);
006000000000
006100000000  GenUtl_CSTKE = GenUtl_FindCallStackEntry('*PRV': PROC_NAME);
006200000000  iCaller = GenUtl_CSTKE.QWVPGMN;      // save caller program name
006300000000
006400000000  if not %open(AC29);                  // if file not open, yet
006500000000    open AC29;                         // open it
006600000000  endif;
006700000000
006800000000  chain (pJobName) AC29 AC29ds;        // check for job name
006900000000
007000000000  select;
007100000000  when not %found(AC29)                // none found for change/copy/delete
007200000000  and GenUtl_inList(pAction: '*CHG,*CPY,*DLT');
007300000000    msgdata = '0000' + pJobName + iFileName;
007400000000    GenUtl_Escape( 'ACJ0001': msgdata: 'WSMSGF': '*LIBL': iCaller );
007500000000
007600000000  when %found(AC29)                    // already there for add
007700000000  and pAction = '*ADD';
007800000000    msgdata = '0000' + pJobName + iFileName;
007900000000    GenUtl_Escape( 'ACJ0002': msgdata: 'WSMSGF': '*LIBL': iCaller );
008000000000
008100000000  other;                               // ready to maintain...
008200000000    select;
008300000000    when pAction = '*DLT';             // for delete
008400000000      if AC29ds.CESTAT = '1';          // if record active
008500000000        AC29ds.CESTAT = '0';           // inactivate it
008600000000        AC29ds.CEWSID = JOB_NAME;
008700000000        AC29ds.CEUSER = USERNAME;
008800000000        AC29ds.CEDT3  = %int(%char(%date():*iso0));
008900000000        update(e) AC29rf AC29ds;
009000000000      else;                            // else, delete it
009100000000        delete(e) AC29rf;
009200000000      endif;
009300000000      if %error;                       // handle file errors
009400000000        msgdata = '0000' + pJobName + iFileName + %editc(%status:'X') + 'delete    ';
009500000000        GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': iCaller );
009600000000      endif;
009700000000
009800000000    when pAction = '*CPY';             // for copy
009900000000      AC29ds.CESTAT = '1';             // activate record
010000000000      AC29ds.CEID   = pTitle;          // new job name
010100000000      AC29ds.CEWSID = JOB_NAME;
010200000000      AC29ds.CEUSER = USERNAME;
010300000000      AC29ds.CEDT3  = %int(%char(%date():*iso0));
010400000000      write(e) AC29rf AC29ds;
010500000000      if %error;                       // handle file errors
010600000000        msgdata = '0000' + pJobName + iFileName + %editc(%status:'X') + 'copy      ';
010700000000        GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': iCaller );
010800000000      endif;
010900000000
011000000000    other;                             // for add/change/create
011100000000      AC29ds.CESTAT = '1';             // activate record
011200000000      AC29ds.CEID   = pJobName;        // save field data
011300000000      AC29ds.CEPROC = pProc;
011400000000      if pDate1 > '0000000';
011500000000        AC29ds.CEDT1  = %int(%char(%date(pDate1:*cymd0):*iso0));
011600000000      else;
011700000000        AC29ds.CEDT1  = *zero;
011800000000      endif;
011900000000      if pDate2 > '0000000';
012000000000        AC29ds.CEDT2  = %int(%char(%date(pDate2:*cymd0):*iso0));
012100000000      else;
012200000000        AC29ds.CEDT2  = *zero;
012300000000      endif;
012400000000      AC29ds.CEDTLR = pSelOpt;
012500000000      AC29ds.CEP    = pOption1 + pOption2 + pOption3 + pOption4 + pOption5;
012600000000      AC29ds.CELOC  = pLocOpt;
012700000000      AC29ds.CEISS  = pIssueTo;
012800000000      AC29ds.CEUSE1 = pUseOpt1;
012900000000      AC29ds.CEUSE2 = pUseOpt2;
013000000000      AC29ds.CEUSE3 = pUseOpt3;
013100000000      AC29ds.CEUSE4 = pUseOpt4;
013200000000      AC29ds.CEUSE# = pUseNbr;
013300000000      AC29ds.CEU    = pUsrPwds;
013400000000
013500000000      AC29ds.CEWSID = JOB_NAME;
013600000000      AC29ds.CEUSER = USERNAME;
013700000000      AC29ds.CEDT3  = %int(%char(%date():*iso0));
013800000000
013900000000      if %found(AC29);                 // if job name was found
014000000000        update(e) AC29rf AC29ds;       // replace existing job name
014100000000        if %error;                     // handle file errors
014200000000          msgdata = '0000' + pJobName + iFileName + %editc(%status:'X') + 'update    ';
014300000000          GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': iCaller );
014400000000        endif;
014500000000      else;                            // else
014600000000        write(e) AC29rf AC29ds;        // write the new job name
014700000000        if %error;                     // handle file errors
014800000000          msgdata = '0000' + pJobName + iFileName + %editc(%status:'X') + 'write     ';
014900000000          GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': iCaller );
015000000000        endif;
015100000000      endif;
015200000000
015300000000    endsl;
015400000000
015500000000  endsl;
015600000000
015700000000  if %open(AC29);                      // if file is open
015800000000    close AC29;                        // close it
015900000000  endif;
016000000000
016100000000  select;
016200000000    when pAction = '*ADD';
016300000000      GenUtl_Complete( 'WSE9897': 'Defaults added.'
016400000000                     : 'WSMSGF': '*LIBL': iCaller );
016500000000    when pAction = '*CHG';
016600000000      GenUtl_Complete( 'WSE9897': 'Defaults changed.'
016700000000                     : 'WSMSGF': '*LIBL': iCaller );
016800000000    when pAction = '*CPY';
016900000000      GenUtl_Complete( 'WSE9897': 'Defaults copied.'
017000000000                     : 'WSMSGF': '*LIBL': iCaller );
017100000000    when pAction = '*CRT';
017200000000      GenUtl_Complete( 'WSE9897': 'Defaults created.'
017300000000                     : 'WSMSGF': '*LIBL': iCaller );
017400000000    when pAction = '*DLT';
017500000000      GenUtl_Complete( 'WSE9897': 'Defaults deleted.'
017600000000                     : 'WSMSGF': '*LIBL': iCaller );
017700000000    other;
017800000000  endsl;
017900000000
018000000000  return;                              // return to caller
018100000000end-proc;
018200000000
