000100000000**free
000200000000//==============================================================================
000300000000// Program Name:      AC04WRKR -- Work with Job Control Options
000400000000// Programmer:        Dave L Clark I
000500000000// Date:              November 8, 2018
000600000000// Project/Request #: IN-57 Create Commands to Maintain Job Control Options
000700000000// Purpose:           This command processing program manages the
000800000000//                    Work with Job Control Options UIM list panel
000900000000//                    for the Job Control Options (AC04) file.
001000000000//------------------------------------------------------------------------------
001100000000//         Special Programming Logic / Considerations
001200000000//
001300000000// NONE
001400000000//
001500000000//------------------------------------------------------------------------------
001600000000//         Modification Log
001700000000//
001800000000// Mod#    Date       User       Description
001900000000// ---- ---------- ---------- --------------------------------------------------
002000000000// M000 11/08/2018 DLCLARK    Initial design.
002100000000//==============================================================================
002200000000
002300000000ctl-opt AlwNull(*UsrCtl) Debug Option(*SrcStmt:*NoDebugIo)
002400000000        DatFmt(*ISO) TimFmt(*ISO) DftActGrp(*No) ActGrp(*Caller) BndDir('WSBNDDIR');
002500000000
002600000000dcl-pi AC04WRKR         extpgm;
002700000000  pJobId                like(AC04ds.JBNAME);
002800000000end-pi;
002900000000
003000000000/include *libl/qrpglesrc,ut010SV                 // general utilities service program
003100000000/include *libl/qrpglesrc,utuiapir                // IBM UI API Prototypes
003200000000
003300000000dcl-s iFileName         char(21) inz('REV460/AC04');
003400000000dcl-f AC04              disk extdesc('REV460/AC04') extfile(iFileName)
003500000000                        keyed usage(*input) usropn;
003600000000dcl-ds AC04ds           likerec(AC04rf:*input);
003700000000
003800000000dcl-s  iContinue        like(boolean_t) inz(*on);
003900000000dcl-s  iOption          char(4);
004000000000dcl-s  iContent         char(4)   inz('TOP');
004100000000dcl-s  iAppHandle       char(8);
004200000000dcl-s  iCaller          char(10);
004300000000dcl-s  iPnlGrp          char(10)  inz('WRKJBCTLOP');
004400000000dcl-s  iPanelId         char(10)  inz('WRKJBCTL');
004500000000dcl-s  iDtlRec          char(10)  inz('JOBDTL');
004600000000dcl-s  iListName        char(10)  inz('JOBLST');
004700000000dcl-s  tProgram         char(10)  inz('AC29WRKR');
004800000000dcl-s  iLEXpgm          char(20)  inz('AC04ILXR  *LIBL');
004900000000dcl-s  iCount           int(10:0) inz(12);
005000000000dcl-s  iFunction        int(10:0);
005100000000
005200000000dcl-ds varpool          qualified inz;
005300000000  OptView               int(5:0);
005400000000end-ds;
005500000000dcl-ds header           qualified inz;
005600000000  ILEXpgm               like(iLEXpgm);
005700000000  PanelId               char(10);
005800000000  JobName               like(AC04ds.JBNAME);
005900000000end-ds;
006000000000dcl-ds detail           qualified inz;
006100000000  Action                int(5:0);
006200000000  JobStatus             like(AC04ds.JBSTAT);
006300000000  JobName               like(AC04ds.JBNAME);
006400000000  JobTitle              like(AC04ds.JBTITL);
006500000000  LocSel                like(AC04ds.JBLOC);
006600000000end-ds;
006700000000
006800000000// incomplete list exit program
006900000000dcl-pr AC04ILXR         extpgm;
007000000000end-pr;
007100000000
007200000000// work with job control defaults prototype
007300000000dcl-pr AC29WRKR         extpgm;
007400000000  pJobId                like(AC04ds.JBNAME);
007500000000end-pr;
007600000000
007700000000//==============================================================================
007800000000// Begin mainline processing
007900000000//==============================================================================
008000000000
008100000000GenUtl_CSTKE = GenUtl_FindCallStackEntry('*PRV': PROC_NAME);
008200000000iCaller = GenUtl_CSTKE.QWVPGMN;        // save caller program name
008300000000
008400000000if not %open(AC04);                    // if file not open, yet
008500000000  open AC04;                           // open it
008600000000endif;
008700000000
008800000000callp IBMUIM_OpenDisplayApplication( iAppHandle: iPnlGrp + '*LIBL'
008900000000                                   : -1: 1: 'N': ApiErrC );
009000000000if ApiErrC.BytAvail > *zero;           // if an error occurred
009100000000  callp CancelProgram();               // cancel the program
009200000000endif;
009300000000
009400000000header.ILEXpgm = iLEXpgm;              // initialize header variables
009500000000header.PanelId = iPnlGrp;
009600000000if %parms < %parmnum(pJobId)           // if parm omitted
009700000000or %addr(pJobId) = *null               // or not passed
009800000000or pJobId <= *blanks;                  // or not valid
009900000000  header.JobName = *blanks;            // use blanks for positioning
010000000000else;                                  // else
010100000000  header.JobName = pJobId;             // position to parm value
010200000000endif;
010300000000
010400000000callp IBMUIM_PutVariable( iAppHandle: header: %len(header)
010500000000                        : 'HEADER': ApiErrC );
010600000000if ApiErrC.BytAvail > *zero;           // if an error occurred
010700000000  callp CancelProgram();               // cancel the program
010800000000endif;
010900000000
011000000000dow iContinue;
011100000000
011200000000  if iFunction <> 4;                   // rebuild the list?
011300000000    setll (header.JobName) AC04;       // start at positioning value
011400000000    reset iContent;                    // start with content default
011500000000    iOption = 'FRST';                  // starting a new list
011600000000    if header.JobName > *blanks;       // if positioning value present
011700000000      iContent = 'MORE';               // set middle of list
011800000000      header.JobName = *blanks;        // don't display in panel header
011900000000      callp IBMUIM_PutVariable( iAppHandle: header: %len(header)
012000000000                              : 'HEADER': ApiErrC );
012100000000      if ApiErrC.BytAvail > *zero;     // if an error occurred
012200000000        callp CancelProgram();         // cancel the program
012300000000      endif;
012400000000    endif;
012500000000    callp AddTopListEntries( iAppHandle: iDtlRec: iListName
012600000000                           : iOption: iCount );
012700000000  endif;
012800000000
012900000000  callp IBMUIM_DisplayPanel( iAppHandle: iFunction
013000000000                           : iPanelId: 'N': ApiErrC
013100000000                           : 'N': 0: '*CALLER': *blank
013200000000                           : 'D': 'NONE': 'NONE': -1 );
013300000000  if ApiErrC.BytAvail > *zero;         // if an error occurred
013400000000    callp CancelProgram();             // cancel the program
013500000000  endif;
013600000000
013700000000  select;
013800000000  when iFunction < *zero;              // exit requested?
013900000000    iContinue = *off;                  // indicate to end the loop
014000000000
014100000000  when iFunction = *zero;              // OPTION selected?
014200000000    callp HandleOptionSelections(iAppHandle: iDtlRec: iListName);
014300000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
014400000000
014500000000  when iFunction = 1;                  // ENTER pressed?
014600000000    callp IBMUIM_GetVariable( iAppHandle: header: %len(header)
014700000000                            : 'HEADER': ApiErrC );
014800000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
014900000000      callp CancelProgram();           // cancel the program
015000000000    endif;
015100000000    header.JobName = %xlate(GenUtl_lower:GenUtl_UPPER:header.JobName);
015200000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
015300000000
015400000000  when iFunction = 2;                  // TOP requested?
015500000000    header.JobName = *blanks;          // start from first record
015600000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
015700000000
015800000000  when iFunction = 3;                  // BOTTOM requested?
015900000000    setgt (*hival) AC04;               // point to end of file
016000000000    readp AC04 AC04ds;                 // read last record
016100000000    header.JobName = AC04ds.JBNAME;    // start at that record
016200000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
016300000000
016400000000  when iFunction = 4;                  // MORE OPTIONS requested?
016500000000    callp IBMUIM_GetVariable( iAppHandle: varpool: %len(varpool)
016600000000                            : 'VARPOOL': ApiErrC );
016700000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
016800000000      callp CancelProgram();           // cancel the program
016900000000    endif;
017000000000    if varpool.OptView = 1;            // toggle the
017100000000      varpool.OptView = *zero;         // option view
017200000000    else;
017300000000      varpool.OptView = 1;
017400000000    endif;
017500000000    callp IBMUIM_PutVariable( iAppHandle: varpool: %len(varpool)
017600000000                            : 'VARPOOL': ApiErrC );
017700000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
017800000000      callp CancelProgram();           // cancel the program
017900000000    endif;
018000000000
018100000000  when iFunction = 5;                  // REFRESH requested?
018200000000    header.JobName = *blanks;          // use blanks for positioning
018300000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
018400000000
018500000000  endsl;
018600000000
018700000000enddo;
018800000000
018900000000callp IBMUIM_CloseApplication(iAppHandle: 'M': ApiErrC);
019000000000if ApiErrC.BytAvail > *zero;           // if an error occurred
019100000000  callp CancelProgram();               // cancel the program
019200000000endif;
019300000000
019400000000if %open(AC04);                        // if file is open
019500000000  close AC04;                          // close it
019600000000endif;
019700000000
019800000000callp AC04ILXR();                      // close file in exit program
019900000000
020000000000*inlr = *on;
020100000000return;                                // return to caller
020200000000
020300000000//==============================================================================
020400000000// End of mainline processing
020500000000//==============================================================================
020600000000
020700000000//******************************************************************************
020800000000// This procedure adds entries to a UIM Incomplete List
020900000000//******************************************************************************
021000000000dcl-proc AddTopListEntries;
021100000000  dcl-pi *n;
021200000000    pAppHandle          char(8);
021300000000    pRecName            char(10);
021400000000    pListName           char(10);
021500000000    pOption             char(4);
021600000000    pRecMax             int(10);
021700000000  end-pi;
021800000000
021900000000  dcl-s  eCount         like(pRecMax);
022000000000  dcl-s  eHandle        like(pOption);
022100000000
022200000000  dou %eof(AC04)                       // loop on file records
022300000000  or eCount >= pRecMax;                // or recmax reached
022400000000    read AC04rf AC04ds;                   // read a record
022500000000    if not %eof(AC04);                    // if not eof
022600000000      eCount += 1;                        // count records
022700000000
022800000000      detail.Action    = *zero;        // load list entry
022900000000      detail.JobStatus = AC04ds.JBSTAT;
023000000000      detail.JobName   = AC04ds.JBNAME;
023100000000      detail.JobTitle  = AC04ds.JBTITL;
023200000000      detail.LocSel    = AC04ds.JBLOC;
023300000000
023400000000      callp IBMUIM_AddListEntry( pAppHandle: detail: %len(detail)
023500000000                               : pRecName: pListName
023600000000                               : pOption: eHandle: ApiErrC );
023700000000      if ApiErrC.BytAvail > *zero;     // if an error occurred
023800000000        callp CancelProgram();         // cancel the program
023900000000      endif;
024000000000      pOption = 'NEXT';                // go for next entry in list
024100000000    endif;
024200000000  enddo;                               // end of file loop
024300000000
024400000000  if %eof(AC04);                       // at eof,
024500000000    if iContent = 'TOP'                // if started at top of file
024600000000    or eCount = *zero;
024700000000      iContent = 'ALL';                // set entire list complete
024800000000    else;                              // else
024900000000      iContent = 'BOT';                // set bottom of list complete
025000000000    endif;
025100000000  endif;
025200000000
025300000000  callp IBMUIM_SetListAttributes( pAppHandle: pListName: iContent
025400000000                                : 'ILEXPGM': 'SAME': 'Y': ApiErrC );
025500000000  if ApiErrC.BytAvail > *zero;         // if an error occurred
025600000000    callp CancelProgram();             // cancel the program
025700000000  endif;
025800000000
025900000000  pRecMax = eCount;                    // return the entry count
026000000000
026100000000  return;
026200000000end-proc;
026300000000
026400000000//******************************************************************************
026500000000// This procedure is a generic means of cancelling this program
026600000000//******************************************************************************
026700000000dcl-proc CancelProgram;
026800000000  dcl-s msgf            char(10)  inz('QCPFMSG');
026900000000  dcl-s msgflib         char(10)  inz('*LIBL');
027000000000
027100000000  select;
027200000000    when %subst(ApiErrC.MsgId:1:3) = 'GUI';
027300000000      msgf = 'QGUIMSG';
027400000000    when %subst(ApiErrC.MsgId:1:3) = 'WSE';
027500000000      msgf = 'WSMSGF';
027600000000  endsl;
027700000000
027800000000  GenUtl_Escape( ApiErrC.MsgId
027900000000               : %subst(ApiErrC.MsgData: 1: ApiErrC.BytAvail - 16)
028000000000               : msgf: msgflib: iCaller );
028100000000  return;
028200000000end-proc;
028300000000
028400000000//******************************************************************************
028500000000// This procedure handle option selection in the list
028600000000//******************************************************************************
028700000000dcl-proc HandleOptionSelections;
028800000000  dcl-pi *n;
028900000000    pAppHandle          char(8);
029000000000    pRecName            char(10);
029100000000    pListName           char(10);
029200000000  end-pi;
029300000000
029400000000  dcl-s  eHandle        char(4);
029500000000  dcl-s  iPosOpt        char(4);
029600000000  dcl-s  iSelHnd        char(4);
029700000000  dcl-ds iSelCri        qualified;
029800000000    Operator            char(10);
029900000000    ColName             char(10);
030000000000  end-ds;
030100000000  dcl-s  sSelHnd        char(4);
030200000000  dcl-s  cmdstr         varchar(256);
030300000000
030400000000  iSelCri.Operator = 'GT';             // select list option value greater than
030500000000  iSelCri.ColName  = 'OPT';            // the dialog option variable (zero)
030600000000
030700000000  iPosOpt = 'HNDL';                    // get by selection handle
030800000000  iSelHnd = 'EXTE';                    // get the extended action entry
030900000000
031000000000  dow ApiErrC.MsgId <> 'CPF6A98';      // loop on selection list
031100000000    reset detail;                      // clear out the dialog variables
031200000000    callp IBMUIM_PutVariable( pAppHandle: detail: %len(detail)
031300000000                            : pRecName: ApiErrC );
031400000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
031500000000      callp CancelProgram();           // cancel the program
031600000000    endif;
031700000000
031800000000    callp IBMUIM_GetListEntry( pAppHandle: detail: %len(detail)
031900000000                             : pRecName: pListName: iPosOpt: 'Y'
032000000000                             : iSelCri: iSelHnd: 'N': eHandle: ApiErrC );
032100000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
032200000000      if ApiErrC.MsgId = 'CPF6A98';    // end of selections?
032300000000        iter;                          // let the loop end
032400000000      endif;                           // else
032500000000      callp CancelProgram();           // cancel the program
032600000000    endif;
032700000000    sSelHnd = eHandle;                 // save selected entry handle
032800000000    header.JobName = %xlate(GenUtl_lower:GenUtl_UPPER:detail.JobName); // start here next time
032900000000
033000000000    select;
033100000000      when detail.Action = 1;          // add an entry?
033200000000        cmdstr = '?ADDJBCTLOP ??JOB(' + %trim(detail.JobName) + ')';
033300000000        monitor;
033400000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
033500000000        on-error;
033600000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
033700000000                             : 'WSMSGF': *omit: PROC_PGM);
033800000000        endmon;
033900000000
034000000000      when detail.Action = 2;          // change an entry?
034100000000        cmdstr = '?CHGJBCTLOP ??JOB(' + %trim(detail.JobName) + ')';
034200000000        monitor;
034300000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
034400000000        on-error;
034500000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
034600000000                             : 'WSMSGF': *omit: PROC_PGM);
034700000000        endmon;
034800000000
034900000000      when detail.Action = 3;          // copy an entry?
035000000000        cmdstr = '?CPYJBCTLOP ??JOB(' + %trim(detail.JobName) + ')';
035100000000        monitor;
035200000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
035300000000        on-error;
035400000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
035500000000                             : 'WSMSGF': *omit: PROC_PGM);
035600000000        endmon;
035700000000
035800000000      when detail.Action = 4;          // delete an entry?
035900000000        cmdstr = '?DLTJBCTLOP ??JOB(' + %trim(detail.JobName) + ')';
036000000000        monitor;
036100000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
036200000000        on-error;
036300000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
036400000000                             : 'WSMSGF': *omit: PROC_PGM);
036500000000        endmon;
036600000000
036700000000      when detail.Action = 5;          // display an entry?
036800000000        cmdstr = '?DSPJBCTLOP ??JOB(' + %trim(detail.JobName) + ')';
036900000000        monitor;
037000000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
037100000000        on-error;
037200000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
037300000000                             : 'WSMSGF': *omit: PROC_PGM);
037400000000        endmon;
037500000000
037600000000      when detail.Action = 9;          // replicate an entry?
037700000000        cmdstr = '?RPLJBCTLOP ??JOB(' + %trim(detail.JobName) + ')';
037800000000        monitor;
037900000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
038000000000        on-error;
038100000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
038200000000                             : 'WSMSGF': *omit: PROC_PGM);
038300000000        endmon;
038400000000
038500000000      when detail.Action = 10;         // transfer to defaults panel?
038600000000        GenUtl_CSTKE = GenUtl_FindCallStackEntry('*FND': tProgram);
038700000000        if GenUtl_CSTKE.QWVPGMN <> tProgram;
038800000000          callp AC29WRKR(detail.JobName);
038900000000          header.JobName = detail.JobName;
039000000000        else;
039100000000          pJobId = detail.JobName;
039200000000          iContinue = *off;
039300000000          return;
039400000000        endif;
039500000000
039600000000    endsl;
039700000000
039800000000    if iPosOpt = 'HNDL';               // if no extended action entry
039900000000      iPosOpt = 'FSLT';                // get first selected list entry
040000000000    else;                              // else
040100000000      iPosOpt = 'NSLT';                // get next selected list entry
040200000000    endif;
040300000000  enddo;                               // end of loop on selection list
040400000000
040500000000  reset ApiErrC;                       // clear out any errors
040600000000
040700000000  return;
040800000000end-proc;
040900000000
