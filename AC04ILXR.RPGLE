000100888888**free
000200000000//==============================================================================
000300000000// Program Name:      AC04ILXR -- Job Control Options Incomplete List Exit Program
000400000000// Programmer:        Dave L Clark I
000500000000// Date:              November 8, 2018
000600000000// Project/Request #: IN-57 Create Commands to Maintain Job Control Options
000700000000// Purpose:           This is a UIM Incomplete List Exit program.
000800000000//------------------------------------------------------------------------------
000900000000//         Special Programming Logic / Considerations
001000000000//
001100000000// NONE
001200000000//
001300000000//------------------------------------------------------------------------------
001400000000//         Modification Log
001500000000//
001600000000// Mod#    Date       User       Description
001700000000// ---- ---------- ---------- --------------------------------------------------
001800000000// M000 11/08/2018 DLCLARK    Initial design.
001900000000//==============================================================================
002000000000
002100000000ctl-opt Main(AC04ILXR) AlwNull(*UsrCtl) Debug Option(*SrcStmt:*NoDebugIo)
002200000000        DatFmt(*ISO) TimFmt(*ISO) DftActGrp(*No) ActGrp(*Caller) BndDir('WSBNDDIR');
002300000000
002400000000/include *libl/qrpglesrc,ut010SV                 // general utilities service program
002500000000/include *libl/qrpglesrc,utuiapir                // IBM UI API Prototypes
002600000000
002700000000dcl-s iFileName         char(21) inz('REV460/AC04');
002800000000dcl-f AC04              disk extdesc('REV460/AC04') extfile(iFileName)
002900000000                        keyed usage(*input) usropn;
003000000000dcl-ds AC04ds           likerec(AC04rf:*input);
003100000000
003200000000dcl-s  iCaller          char(10);
003300000000dcl-s  iDtlRec          char(10)  inz('JOBDTL');
003400000000dcl-s  iCount           int(10:0) inz(12);
003500000000
003600000000dcl-ds detail           qualified;
003700000000  Action                int(5:0);
003800000000  JobStatus             like(AC04ds.JBSTAT);
003900000000  JobName               like(AC04ds.JBNAME);
004000000000  JobTitle              like(AC04ds.JBTITL);
004100000000  LocSel                like(AC04ds.JBLOC);
004200000000end-ds;
004300000000
004400000000//==============================================================================
004500000000// Begin mainline procedure
004600000000//==============================================================================
004700000000dcl-proc AC04ILXR;
004800000000  dcl-pi *n             extpgm;
004900000000    pCallType           int(10);
005000000000    pAppHandle          char(8);
005100000000    pListName           char(10);
005200000000    pListDir            int(10);
005300000000    pEntReq             int(10);
005400000000  end-pi;
005500000000
005600000000  dcl-s  iPosOpt        char(4);
005700000000  dcl-s  iSelCri        char(20);
005800000000  dcl-s  iSelHnd        char(4);
005900000000  dcl-s  eHandle        char(4);
006000000000  dcl-s  eOption        char(4);
006100000000
006200000000  if %parms < 1;                       // if not called as an exit program
006300000000    if %open(AC04);                    // and the file is open
006400000000      close AC04;                      // then close it
006500000000    endif;                             // and return to the caller
006600000000    return;
006700000000  endif;
006800000000
006900000000  GenUtl_CSTKE = GenUtl_FindCallStackEntry('*PRV': PROC_NAME);
007000000000  iCaller = GenUtl_CSTKE.QWVPGMN;      // save caller program name
007100000000
007200000000  if not %open(AC04);                  // if file not open, yet
007300000000    open AC04;                         // open it
007400000000  endif;
007500000000
007600000000  callp IBMUIM_RetrieveListAttributes( pAppHandle: pListName: IBMUIM_ListAttrb
007700000000                                     : %len(IBMUIM_ListAttrb): ApiErrC );
007800000000  if ApiErrC.BytAvail > *zero;         // if an error occurred
007900000000    callp CancelProgram();             // cancel the program
008000000000  endif;
008100000000
008200000000  if pListDir > *zero;                 // set up to retrieve
008300000000    iPosOpt = 'FRST';                  // the first list entry
008400000000  else;                                // or
008500000000    iPosOpt = 'LAST';                  // the last list entry
008600000000  endif;
008700000000
008800000000  callp IBMUIM_GetListEntry( pAppHandle: detail: %len(detail)
008900000000                           : iDtlRec: pListName: iPosOpt: 'Y'
009000000000                           : iSelCri: iSelHnd: 'N': eHandle: ApiErrC );
009100000000  if ApiErrC.BytAvail > *zero;         // if an error occurred
009200000000    callp CancelProgram();             // cancel the program
009300000000  endif;
009400000000
009500000000  chain (detail.JobName) AC04rf AC04ds; // read the referenced record
009600000000
009700000000  if pListDir > *zero;
009800000000    eOption = 'FRST';                  // add more previous entries
009900000000    callp AddTopListEntries( pAppHandle: iDtlRec: pListName
010000000000                           : eOption: pEntReq );
010100000000  else;
010200000000    eOption = 'LAST';                  // add more subsequent entries
010300000000    callp AddBtmListEntries( pAppHandle: iDtlRec: pListName
010400000000                           : eOption: pEntReq );
010500000000  endif;
010600000000
010700000000
010800000000  return;                              // return to the caller
010900000000end-proc;
011000000000
011100000000//******************************************************************************
011200000000// This procedure adds entries to the end of a UIM Incomplete List
011300000000//******************************************************************************
011400000000dcl-proc AddBtmListEntries;
011500000000  dcl-pi *n;
011600000000    pAppHandle          char(8);
011700000000    pRecName            char(10);
011800000000    pListName           char(10);
011900000000    pOption             char(4);
012000000000    pRecMax             int(10);
012100000000  end-pi;
012200000000
012300000000  dcl-s  eCount         like(pRecMax);
012400000000  dcl-s  eHandle        like(pOption);
012500000000
012600000000  dou %eof(AC04)                       // loop on file records
012700000000  or eCount >= pRecMax;                // or recmax reached
012800000000    read AC04rf AC04ds;                   // read next record
012900000000    if not %eof(AC04);                    // if not eof
013000000000      eCount += 1;                        // count records
013100000000
013200000000      detail.Action    = *zero;
013300000000      detail.JobStatus = AC04ds.JBSTAT;
013400000000      detail.JobName   = AC04ds.JBNAME;
013500000000      detail.JobTitle  = AC04ds.JBTITL;
013600000000      detail.LocSel    = AC04ds.JBLOC;
013700000000
013800000000      callp IBMUIM_AddListEntry( pAppHandle: detail: %len(detail)
013900000000                               : pRecName: pListName
014000000000                               : pOption: eHandle: ApiErrC );
014100000000      if ApiErrC.BytAvail > *zero;     // if an error occurred
014200000000        callp CancelProgram();         // cancel the program
014300000000      endif;
014400000000      pOption = 'NEXT';                // go for next entry in list
014500000000    endif;
014600000000  enddo;                               // end of file loop
014700000000
014800000000  if %eof(AC04);                       // at eof,
014900000000    if IBMUIM_ListAttrb.Content = 'TOP';  // if started at top of file
015000000000      IBMUIM_ListAttrb.Content = 'ALL';   // set entire list complete
015100000000    else;                                 // else
015200000000      IBMUIM_ListAttrb.Content = 'BOT';   // set bottom of list complete
015300000000    endif;
015400000000    callp IBMUIM_SetListAttributes( pAppHandle: pListName
015500000000                                  : IBMUIM_ListAttrb.Content
015600000000                                  : '*SAME': 'SAME': 'S': ApiErrC );
015700000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
015800000000      callp CancelProgram();           // cancel the program
015900000000    endif;
016000000000  endif;
016100000000
016200000000  pRecMax = eCount;                    // return the entry count
016300000000
016400000000  return;
016500000000end-proc;
016600000000
016700000000//******************************************************************************
016800000000// This procedure adds entries to the top of a UIM Incomplete List
016900000000//******************************************************************************
017000000000dcl-proc AddTopListEntries;
017100000000  dcl-pi *n;
017200000000    pAppHandle          char(8);
017300000000    pRecName            char(10);
017400000000    pListName           char(10);
017500000000    pOption             char(4);
017600000000    pRecMax             int(10);
017700000000  end-pi;
017800000000
017900000000  dcl-s  eCount         like(pRecMax);
018000000000  dcl-s  eHandle        like(pOption);
018100000000
018200000000  dou %eof(AC04)                       // loop on file records
018300000000  or eCount >= pRecMax;                // or recmax reached
018400000000    readp AC04rf AC04ds;                  // read previous record
018500000000    if not %eof(AC04);                    // if not eof
018600000000      eCount += 1;                        // count records
018700000000
018800000000      detail.Action    = *zero;
018900000000      detail.JobStatus = AC04ds.JBSTAT;
019000000000      detail.JobName   = AC04ds.JBNAME;
019100000000      detail.JobTitle  = AC04ds.JBTITL;
019200000000      detail.LocSel    = AC04ds.JBLOC;
019300000000
019400000000      callp IBMUIM_AddListEntry( pAppHandle: detail: %len(detail)
019500000000                               : pRecName: pListName
019600000000                               : pOption: eHandle: ApiErrC );
019700000000      if ApiErrC.BytAvail > *zero;     // if an error occurred
019800000000        callp CancelProgram();         // cancel the program
019900000000      endif;
020000000000      pOption = 'FRST';                // go for first entry in list
020100000000    endif;
020200000000  enddo;                               // end of file loop
020300000000
020400000000  if %eof(AC04);                       // at eof,
020500000000    if IBMUIM_ListAttrb.Content = 'BOT';  // if started at end of file
020600000000      IBMUIM_ListAttrb.Content = 'ALL';   // set entire list complete
020700000000    else;                                 // else
020800000000      IBMUIM_ListAttrb.Content = 'TOP';   // set top of list complete
020900000000    endif;
021000000000    callp IBMUIM_SetListAttributes( pAppHandle: pListName
021100000000                                  : IBMUIM_ListAttrb.Content
021200000000                                  : '*SAME': 'SAME': 'S': ApiErrC );
021300000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
021400000000      callp CancelProgram();           // cancel the program
021500000000    endif;
021600000000  endif;
021700000000
021800000000  pRecMax = eCount;                    // return the entry count
021900000000
022000000000  return;
022100000000end-proc;
022200000000
022300000000//******************************************************************************
022400000000// This procedure is a generic means of cancelling this program
022500000000//******************************************************************************
022600000000dcl-proc CancelProgram;
022700000000  dcl-pi *n;
022800000000  end-pi;
022900000000
023000000000  dcl-s msgf            char(10)  inz('QCPFMSG');
023100000000  dcl-s msgflib         char(10)  inz('*LIBL');
023200000000
023300000000  select;
023400000000    when %subst(ApiErrC.MsgId:1:3) = 'GUI';
023500000000      msgf = 'QGUIMSG';
023600000000    when %subst(ApiErrC.MsgId:1:3) = 'WSE';
023700000000      msgf = 'WSMSGF';
023800000000  endsl;
023900000000
024000000000  GenUtl_Escape( ApiErrC.MsgId
024100000000               : %subst(ApiErrC.MsgData: 1: ApiErrC.BytAvail - 16)
024200000000               : msgf: msgflib: iCaller );
024300000000  return;
024400000000end-proc;
024500000000
