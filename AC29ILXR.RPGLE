000100888888**free
000200000000//==============================================================================
000300000000// Program Name:      AC29ILXR -- Job Control Defaults Incomplete List Exit Program
000400000000// Programmer:        Dave L Clark I
000500000000// Date:              November 8, 2018
000600000000// Project/Request #: IN-58 Create Commands to Maintain Job Control Defaults
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
002100000000ctl-opt Main(AC29ILXR) AlwNull(*UsrCtl) Debug Option(*SrcStmt:*NoDebugIo)
002200000000        DatFmt(*ISO) TimFmt(*ISO) DftActGrp(*No) ActGrp(*Caller) BndDir('WSBNDDIR');
002300000000
002400000000/include *libl/qrpglesrc,ut010SV                 // general utilities service program
002500000000/include *libl/qrpglesrc,utuiapir                // IBM UI API Prototypes
002600000000
002700000000dcl-f AC04              disk extdesc('REV460/AC04') extfile(*extdesc)
002800000000                        keyed usage(*input) usropn;
002900000000dcl-ds AC04ds           likerec(AC04rf:*all);
003000000000
003100000000dcl-s iFileName         char(21) inz('REV460/AC29');
003200000000dcl-f AC29              disk extdesc('REV460/AC29') extfile(iFileName)
003300000000                        keyed usage(*input) usropn;
003400000000dcl-ds AC29ds           likerec(AC29rf:*input);
003500000000
003600000000dcl-s  iCaller          char(10);
003700000000dcl-s  iDtlRec          char(10)  inz('JOBDTL');
003800000000dcl-s  iCount           int(10:0) inz(12);
003900000000
004000000000dcl-ds detail           qualified;
004100000000  Action                int(5:0);
004200000000  JobStatus             like(AC29ds.CESTAT);
004300000000  JobName               like(AC29ds.CEID);
004400000000  JobTitle              like(AC04ds.JBTITL);
004500000000  Date1                 char(10);
004600000000  Date2                 char(10);
004700000000  SelOpt                like(AC29ds.CEDTLR);
004800000000  Opt5                  like(AC29ds.CEP);
004900000000end-ds;
005000000000
005100000000//==============================================================================
005200000000// Begin mainline procedure
005300000000//==============================================================================
005400000000dcl-proc AC29ILXR;
005500000000  dcl-pi *n             extpgm;
005600000000    pCallType           int(10);
005700000000    pAppHandle          char(8);
005800000000    pListName           char(10);
005900000000    pListDir            int(10);
006000000000    pEntReq             int(10);
006100000000  end-pi;
006200000000
006300000000  dcl-s  iPosOpt        char(4);
006400000000  dcl-s  iSelCri        char(20);
006500000000  dcl-s  iSelHnd        char(4);
006600000000  dcl-s  eHandle        char(4);
006700000000  dcl-s  eOption        char(4);
006800000000
006900000000  if %parms < 1;                       // if not called as an exit program
007000000000    if %open(AC29);                    // and the file is open
007100000000      close AC29;                      // then close it
007200000000    endif;                             // and return to the caller
007300000000    if %open(AC04);                    // and the file is open
007400000000      close AC04;                      // then close it
007500000000    endif;                             // and return to the caller
007600000000    return;
007700000000  endif;
007800000000
007900000000  GenUtl_CSTKE = GenUtl_FindCallStackEntry('*PRV': PROC_NAME);
008000000000  iCaller = GenUtl_CSTKE.QWVPGMN;      // save caller program name
008100000000
008200000000  if not %open(AC04);                  // if file not open, yet
008300000000    open AC04;                         // open it
008400000000  endif;
008500000000
008600000000  if not %open(AC29);                  // if file not open, yet
008700000000    open AC29;                         // open it
008800000000  endif;
008900000000
009000000000  callp IBMUIM_RetrieveListAttributes( pAppHandle: pListName: IBMUIM_ListAttrb
009100000000                                     : %len(IBMUIM_ListAttrb): ApiErrC );
009200000000  if ApiErrC.BytAvail > *zero;         // if an error occurred
009300000000    callp CancelProgram();             // cancel the program
009400000000  endif;
009500000000
009600000000  if pListDir > *zero;                 // set up to retrieve
009700000000    iPosOpt = 'FRST';                  // the first list entry
009800000000  else;                                // or
009900000000    iPosOpt = 'LAST';                  // the last list entry
010000000000  endif;
010100000000
010200000000  callp IBMUIM_GetListEntry( pAppHandle: detail: %len(detail)
010300000000                           : iDtlRec: pListName: iPosOpt: 'Y'
010400000000                           : iSelCri: iSelHnd: 'N': eHandle: ApiErrC );
010500000000  if ApiErrC.BytAvail > *zero;         // if an error occurred
010600000000    callp CancelProgram();             // cancel the program
010700000000  endif;
010800000000
010900000000  chain (detail.JobName) AC04rf AC04ds; // read the referenced record
011000000000
011100000000  if pListDir > *zero;
011200000000    eOption = 'FRST';                  // add more previous entries
011300000000    callp AddTopListEntries( pAppHandle: iDtlRec: pListName
011400000000                           : eOption: pEntReq );
011500000000  else;
011600000000    eOption = 'LAST';                  // add more subsequent entries
011700000000    callp AddBtmListEntries( pAppHandle: iDtlRec: pListName
011800000000                           : eOption: pEntReq );
011900000000  endif;
012000000000
012100000000
012200000000  return;                              // return to the caller
012300000000end-proc;
012400000000
012500000000//******************************************************************************
012600000000// This procedure adds entries to the end of a UIM Incomplete List
012700000000//******************************************************************************
012800000000dcl-proc AddBtmListEntries;
012900000000  dcl-pi *n;
013000000000    pAppHandle          char(8);
013100000000    pRecName            char(10);
013200000000    pListName           char(10);
013300000000    pOption             char(4);
013400000000    pRecMax             int(10);
013500000000  end-pi;
013600000000
013700000000  dcl-s  eCount         like(pRecMax);
013800000000  dcl-s  eHandle        like(pOption);
013900000000
014000000000  dou %eof(AC29)                       // loop on file records
014100000000  or eCount >= pRecMax;                // or recmax reached
014200000000    read AC29rf AC29ds;                   // read next record
014300000000    if not %eof(AC29);                    // if not eof
014400000000      eCount += 1;                        // count records
014500000000
014600000000      chain(e) (AC29ds.CEID) AC04 AC04ds; // get job title
014700000000      if %error or not %found(AC04);
014800000000        AC04ds.JBTITL = *blanks;
014900000000      endif;
015000000000
015100000000      detail.Action    = *zero;        // load list entry
015200000000      detail.JobStatus = AC29ds.CESTAT;
015300000000      detail.JobName   = AC29ds.CEID;
015400000000      detail.JobTitle  = AC04ds.JBTITL;
015500000000      if AC29ds.CEDT1 > *zero;
015600000000        monitor;
015700000000          detail.Date1   = %char(%date(AC29ds.CEDT1:*iso));
015800000000        on-error;
015900000000          detail.Date1   = %editc(AC29ds.CEDT1:'X');
016000000000        endmon;
016100000000      else;
016200000000        detail.Date1   = *blanks;
016300000000      endif;
016400000000      if AC29ds.CEDT2 > *zero;
016500000000        monitor;
016600000000          detail.Date2   = %char(%date(AC29ds.CEDT2:*iso));
016700000000        on-error;
016800000000          detail.Date2   = %editc(AC29ds.CEDT2:'X');
016900000000        endmon;
017000000000      else;
017100000000        detail.Date2   = *blanks;
017200000000      endif;
017300000000      detail.SelOpt    = AC29ds.CEDTLR;
017400000000      detail.Opt5      = AC29ds.CEP;
017500000000
017600000000      callp IBMUIM_AddListEntry( pAppHandle: detail: %len(detail)
017700000000                               : pRecName: pListName
017800000000                               : pOption: eHandle: ApiErrC );
017900000000      if ApiErrC.BytAvail > *zero;     // if an error occurred
018000000000        callp CancelProgram();         // cancel the program
018100000000      endif;
018200000000      pOption = 'NEXT';                // go for next entry in list
018300000000    endif;
018400000000  enddo;                               // end of file loop
018500000000
018600000000  if %eof(AC29);                       // at eof,
018700000000    if IBMUIM_ListAttrb.Content = 'TOP';  // if started at top of file
018800000000      IBMUIM_ListAttrb.Content = 'ALL';   // set entire list complete
018900000000    else;                                 // else
019000000000      IBMUIM_ListAttrb.Content = 'BOT';   // set bottom of list complete
019100000000    endif;
019200000000    callp IBMUIM_SetListAttributes( pAppHandle: pListName
019300000000                                  : IBMUIM_ListAttrb.Content
019400000000                                  : '*SAME': 'SAME': 'S': ApiErrC );
019500000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
019600000000      callp CancelProgram();           // cancel the program
019700000000    endif;
019800000000  endif;
019900000000
020000000000  pRecMax = eCount;                    // return the entry count
020100000000
020200000000  return;
020300000000end-proc;
020400000000
020500000000//******************************************************************************
020600000000// This procedure adds entries to the top of a UIM Incomplete List
020700000000//******************************************************************************
020800000000dcl-proc AddTopListEntries;
020900000000  dcl-pi *n;
021000000000    pAppHandle          char(8);
021100000000    pRecName            char(10);
021200000000    pListName           char(10);
021300000000    pOption             char(4);
021400000000    pRecMax             int(10);
021500000000  end-pi;
021600000000
021700000000  dcl-s  eCount         like(pRecMax);
021800000000  dcl-s  eHandle        like(pOption);
021900000000
022000000000  dou %eof(AC29)                       // loop on file records
022100000000  or eCount >= pRecMax;                // or recmax reached
022200000000    readp AC29rf AC29ds;                  // read previous record
022300000000    if not %eof(AC29);                    // if not eof
022400000000      eCount += 1;                        // count records
022500000000
022600000000      chain(e) (AC29ds.CEID) AC04 AC04ds; // get job title
022700000000      if %error or not %found(AC04);
022800000000        AC04ds.JBTITL = *blanks;
022900000000      endif;
023000000000
023100000000      detail.Action    = *zero;        // load list entry
023200000000      detail.JobStatus = AC29ds.CESTAT;
023300000000      detail.JobName   = AC29ds.CEID;
023400000000      detail.JobTitle  = AC04ds.JBTITL;
023500000000      if AC29ds.CEDT1 > *zero;
023600000000        monitor;
023700000000          detail.Date1   = %char(%date(AC29ds.CEDT1:*iso));
023800000000        on-error;
023900000000          detail.Date1   = %editc(AC29ds.CEDT1:'X');
024000000000        endmon;
024100000000      else;
024200000000        detail.Date1   = *blanks;
024300000000      endif;
024400000000      if AC29ds.CEDT2 > *zero;
024500000000        monitor;
024600000000          detail.Date2   = %char(%date(AC29ds.CEDT2:*iso));
024700000000        on-error;
024800000000          detail.Date2   = %editc(AC29ds.CEDT2:'X');
024900000000        endmon;
025000000000      else;
025100000000        detail.Date2   = *blanks;
025200000000      endif;
025300000000      detail.SelOpt    = AC29ds.CEDTLR;
025400000000      detail.Opt5      = AC29ds.CEP;
025500000000
025600000000      callp IBMUIM_AddListEntry( pAppHandle: detail: %len(detail)
025700000000                               : pRecName: pListName
025800000000                               : pOption: eHandle: ApiErrC );
025900000000      if ApiErrC.BytAvail > *zero;     // if an error occurred
026000000000        callp CancelProgram();         // cancel the program
026100000000      endif;
026200000000      pOption = 'FRST';                // go for first entry in list
026300000000    endif;
026400000000  enddo;                               // end of file loop
026500000000
026600000000  if %eof(AC29);                       // at eof,
026700000000    if IBMUIM_ListAttrb.Content = 'BOT';  // if started at end of file
026800000000      IBMUIM_ListAttrb.Content = 'ALL';   // set entire list complete
026900000000    else;                                 // else
027000000000      IBMUIM_ListAttrb.Content = 'TOP';   // set top of list complete
027100000000    endif;
027200000000    callp IBMUIM_SetListAttributes( pAppHandle: pListName
027300000000                                  : IBMUIM_ListAttrb.Content
027400000000                                  : '*SAME': 'SAME': 'S': ApiErrC );
027500000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
027600000000      callp CancelProgram();           // cancel the program
027700000000    endif;
027800000000  endif;
027900000000
028000000000  pRecMax = eCount;                    // return the entry count
028100000000
028200000000  return;
028300000000end-proc;
028400000000
028500000000//******************************************************************************
028600000000// This procedure is a generic means of cancelling this program
028700000000//******************************************************************************
028800000000dcl-proc CancelProgram;
028900000000  dcl-pi *n;
029000000000  end-pi;
029100000000
029200000000  dcl-s msgf            char(10)  inz('QCPFMSG');
029300000000  dcl-s msgflib         char(10)  inz('*LIBL');
029400000000
029500000000  select;
029600000000    when %subst(ApiErrC.MsgId:1:3) = 'GUI';
029700000000      msgf = 'QGUIMSG';
029800000000    when %subst(ApiErrC.MsgId:1:3) = 'WSE';
029900000000      msgf = 'WSMSGF';
030000000000  endsl;
030100000000
030200000000  GenUtl_Escape( ApiErrC.MsgId
030300000000               : %subst(ApiErrC.MsgData: 1: ApiErrC.BytAvail - 16)
030400000000               : msgf: msgflib: iCaller );
030500000000  return;
030600000000end-proc;
030700000000
