000100000000**free
000200000000//==============================================================================
000300000000// Program Name:      AC29WRKR -- Work with Job Control Defaults
000400000000// Programmer:        Dave L Clark I
000500000000// Date:              November 8, 2018
000600000000// Project/Request #: IN-58 Create Commands to Maintain Job Control Defaults
000700000000// Purpose:           This command processing program manages the
000800000000//                    Work with Job Control Defaults UIM list panel
000900000000//                    for the Job Control Defaults (AC29) file.
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
002600000000dcl-pi AC29WRKR         extpgm;
002700000000  pJobId                like(AC04ds.JBNAME);
002800000000end-pi;
002900000000
003000000000/include *libl/qrpglesrc,ut010SV                 // general utilities service program
003100000000/include *libl/qrpglesrc,utuiapir                // IBM UI API Prototypes
003200000000
003300000000dcl-f AC04              disk extdesc('REV460/AC04') extfile(*extdesc)
003400000000                        keyed usage(*input) usropn;
003500000000dcl-ds AC04ds           likerec(AC04rf:*all);
003600000000
003700000000dcl-s iFileName         char(21) inz('REV460/AC29');
003800000000dcl-f AC29              disk extdesc('REV460/AC29') extfile(iFileName)
003900000000                        keyed usage(*input) usropn;
004000000000dcl-ds AC29ds           likerec(AC29rf:*input);
004100000000
004200000000dcl-s  iContinue        like(boolean_t) inz(*on);
004300000000dcl-s  iOption          char(4);
004400000000dcl-s  iContent         char(4)   inz('TOP');
004500000000dcl-s  iAppHandle       char(8);
004600000000dcl-s  iCaller          char(10);
004700000000dcl-s  iPnlGrp          char(10)  inz('WRKJBCTLDF');
004800000000dcl-s  iPanelId         char(10)  inz('WRKJBCTL');
004900000000dcl-s  iDtlRec          char(10)  inz('JOBDTL');
005000000000dcl-s  iListName        char(10)  inz('JOBLST');
005100000000dcl-s  tProgram         char(10)  inz('AC04WRKR');
005200000000dcl-s  iLEXpgm          char(20)  inz('AC29ILXR  *LIBL');
005300000000dcl-s  iCount           int(10:0) inz(12);
005400000000dcl-s  iFunction        int(10:0);
005500000000
005600000000dcl-ds header           qualified inz;
005700000000  ILEXpgm               like(iLEXpgm);
005800000000  PanelId               char(10);
005900000000  JobName               like(AC04ds.JBNAME);
006000000000end-ds;
006100000000dcl-ds detail           qualified inz;
006200000000  Action                int(5:0);
006300000000  JobStatus             like(AC29ds.CESTAT);
006400000000  JobName               like(AC29ds.CEID);
006500000000  JobTitle              like(AC04ds.JBTITL);
006600000000  Date1                 char(10);
006700000000  Date2                 char(10);
006800000000  SelOpt                like(AC29ds.CEDTLR);
006900000000  Opt5                  like(AC29ds.CEP);
007000000000end-ds;
007100000000
007200000000// work with job control options prototype
007300000000dcl-pr AC04WRKR         extpgm;
007400000000  pJobId                like(AC04ds.JBNAME);
007500000000end-pr;
007600000000
007700000000// incomplete list exit program
007800000000dcl-pr AC29ILXR         extpgm;
007900000000end-pr;
008000000000
008100000000//==============================================================================
008200000000// Begin mainline processing
008300000000//==============================================================================
008400000000
008500000000GenUtl_CSTKE = GenUtl_FindCallStackEntry('*PRV': PROC_NAME);
008600000000iCaller = GenUtl_CSTKE.QWVPGMN;        // save caller program name
008700000000
008800000000if not %open(AC04);                    // if file not open, yet
008900000000  open AC04;                           // open it
009000000000endif;
009100000000
009200000000if not %open(AC29);                    // if file not open, yet
009300000000  open AC29;                           // open it
009400000000endif;
009500000000
009600000000callp IBMUIM_OpenDisplayApplication( iAppHandle: iPnlGrp + '*LIBL'
009700000000                                   : -1: 1: 'N': ApiErrC );
009800000000if ApiErrC.BytAvail > *zero;           // if an error occurred
009900000000  callp CancelProgram();               // cancel the program
010000000000endif;
010100000000
010200000000header.ILEXpgm = iLEXpgm;              // initialize header variables
010300000000header.PanelId = iPnlGrp;
010400000000if %parms < %parmnum(pJobId)           // if parm omitted
010500000000or %addr(pJobId) = *null               // or not passed
010600000000or pJobId <= *blanks;                  // or not valid
010700000000  header.JobName = *blanks;            // use blanks for positioning
010800000000else;                                  // else
010900000000  header.JobName = pJobId;             // position to parm value
011000000000endif;
011100000000
011200000000callp IBMUIM_PutVariable( iAppHandle: header: %len(header)
011300000000                        : 'HEADER': ApiErrC );
011400000000if ApiErrC.BytAvail > *zero;           // if an error occurred
011500000000  callp CancelProgram();               // cancel the program
011600000000endif;
011700000000
011800000000dow iContinue;
011900000000
012000000000  setll (header.JobName) AC29;         // start at positioning value
012100000000
012200000000  reset iContent;                      // start with content default
012300000000  iOption = 'FRST';                    // starting a new list
012400000000
012500000000  if header.JobName > *blanks;         // if positioning value present
012600000000    iContent = 'MORE';                 // set middle of list
012700000000    header.JobName = *blanks;          // don't display in panel header
012800000000    callp IBMUIM_PutVariable( iAppHandle: header: %len(header)
012900000000                            : 'HEADER': ApiErrC );
013000000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
013100000000      callp CancelProgram();           // cancel the program
013200000000    endif;
013300000000  endif;
013400000000
013500000000  callp AddTopListEntries( iAppHandle: iDtlRec: iListName
013600000000                         : iOption: iCount );
013700000000
013800000000  callp IBMUIM_DisplayPanel( iAppHandle: iFunction
013900000000                           : iPanelId: 'N': ApiErrC
014000000000                           : 'N': 0: '*CALLER': *blank
014100000000                           : 'D': 'NONE': 'NONE': -1 );
014200000000  if ApiErrC.BytAvail > *zero;         // if an error occurred
014300000000    callp CancelProgram();             // cancel the program
014400000000  endif;
014500000000
014600000000  select;
014700000000  when iFunction < *zero;              // exit requested?
014800000000    iContinue = *off;                  // indicate to end the loop
014900000000
015000000000  when iFunction = *zero;              // OPTION selected?
015100000000    callp HandleOptionSelections(iAppHandle: iDtlRec: iListName);
015200000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
015300000000
015400000000  when iFunction = 1;                  // ENTER pressed?
015500000000    callp IBMUIM_GetVariable( iAppHandle: header: %len(header)
015600000000                            : 'HEADER': ApiErrC );
015700000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
015800000000      callp CancelProgram();           // cancel the program
015900000000    endif;
016000000000    header.JobName = %xlate(GenUtl_lower:GenUtl_UPPER:header.JobName);
016100000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
016200000000
016300000000  when iFunction = 2;                  // TOP requested?
016400000000    header.JobName = *blanks;          // start from first record
016500000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
016600000000
016700000000  when iFunction = 3;                  // BOTTOM requested?
016800000000    setgt (*hival) AC04;               // point to end of file
016900000000    readp AC04 AC04ds;                 // read last record
017000000000    header.JobName = AC04ds.JBNAME;    // start at that record
017100000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
017200000000
017300000000  when iFunction = 5;                  // REFRESH requested?
017400000000    header.JobName = *blanks;          // use blanks for positioning
017500000000    callp IBMUIM_DeleteList(iAppHandle: iListName: ApiErrC);
017600000000
017700000000  endsl;
017800000000
017900000000enddo;
018000000000
018100000000callp IBMUIM_CloseApplication(iAppHandle: 'M': ApiErrC);
018200000000if ApiErrC.BytAvail > *zero;           // if an error occurred
018300000000  callp CancelProgram();               // cancel the program
018400000000endif;
018500000000
018600000000if %open(AC29);                        // if file is open
018700000000  close AC29;                          // close it
018800000000endif;
018900000000
019000000000if %open(AC04);                        // if file is open
019100000000  close AC04;                          // close it
019200000000endif;
019300000000
019400000000callp AC29ILXR();                      // close file in exit program
019500000000
019600000000*inlr = *on;
019700000000return;                                // return to caller
019800000000
019900000000//==============================================================================
020000000000// End of mainline processing
020100000000//==============================================================================
020200000000
020300000000//******************************************************************************
020400000000// This procedure adds entries to a UIM Incomplete List
020500000000//******************************************************************************
020600000000dcl-proc AddTopListEntries;
020700000000  dcl-pi *n;
020800000000    pAppHandle          char(8);
020900000000    pRecName            char(10);
021000000000    pListName           char(10);
021100000000    pOption             char(4);
021200000000    pRecMax             int(10);
021300000000  end-pi;
021400000000
021500000000  dcl-s  eCount         like(pRecMax);
021600000000  dcl-s  eHandle        like(pOption);
021700000000
021800000000  dou %eof(AC29)                       // loop on file records
021900000000  or eCount >= pRecMax;                // or recmax reached
022000000000    read AC29rf AC29ds;                   // read a record
022100000000    if not %eof(AC29);                    // if not eof
022200000000      eCount += 1;                        // count records
022300000000
022400000000      chain(e) (AC29ds.CEID) AC04 AC04ds; // get job title
022500000000      if %error or not %found(AC04);
022600000000        AC04ds.JBTITL = *blanks;
022700000000      endif;
022800000000
022900000000      detail.Action    = *zero;        // load list entry
023000000000      detail.JobStatus = AC29ds.CESTAT;
023100000000      detail.JobName   = AC29ds.CEID;
023200000000      detail.JobTitle  = AC04ds.JBTITL;
023300000000      if AC29ds.CEDT1 > *zero;
023400000000        monitor;
023500000000          detail.Date1   = %char(%date(AC29ds.CEDT1:*iso));
023600000000        on-error;
023700000000          detail.Date1   = %editc(AC29ds.CEDT1:'X');
023800000000        endmon;
023900000000      else;
024000000000        detail.Date1   = *blanks;
024100000000      endif;
024200000000      if AC29ds.CEDT2 > *zero;
024300000000        monitor;
024400000000          detail.Date2   = %char(%date(AC29ds.CEDT2:*iso));
024500000000        on-error;
024600000000          detail.Date2   = %editc(AC29ds.CEDT2:'X');
024700000000        endmon;
024800000000      else;
024900000000        detail.Date2   = *blanks;
025000000000      endif;
025100000000      detail.SelOpt    = AC29ds.CEDTLR;
025200000000      detail.Opt5      = AC29ds.CEP;
025300000000
025400000000      callp IBMUIM_AddListEntry( pAppHandle: detail: %len(detail)
025500000000                               : pRecName: pListName
025600000000                               : pOption: eHandle: ApiErrC );
025700000000      if ApiErrC.BytAvail > *zero;     // if an error occurred
025800000000        callp CancelProgram();         // cancel the program
025900000000      endif;
026000000000      pOption = 'NEXT';                // go for next entry in list
026100000000    endif;
026200000000  enddo;                               // end of file loop
026300000000
026400000000  if %eof(AC29);                       // at eof,
026500000000    if iContent = 'TOP'                // if started at top of file
026600000000    or eCount = *zero;
026700000000      iContent = 'ALL';                // set entire list complete
026800000000    else;                              // else
026900000000      iContent = 'BOT';                // set bottom of list complete
027000000000    endif;
027100000000  endif;
027200000000
027300000000  callp IBMUIM_SetListAttributes( pAppHandle: pListName: iContent
027400000000                                : 'ILEXPGM': 'SAME': 'Y': ApiErrC );
027500000000  if ApiErrC.BytAvail > *zero;         // if an error occurred
027600000000    callp CancelProgram();             // cancel the program
027700000000  endif;
027800000000
027900000000  pRecMax = eCount;                    // return the entry count
028000000000
028100000000  return;
028200000000end-proc;
028300000000
028400000000//******************************************************************************
028500000000// This procedure is a generic means of cancelling this program
028600000000//******************************************************************************
028700000000dcl-proc CancelProgram;
028800000000  dcl-s msgf            char(10)  inz('QCPFMSG');
028900000000  dcl-s msgflib         char(10)  inz('*LIBL');
029000000000
029100000000  select;
029200000000    when %subst(ApiErrC.MsgId:1:3) = 'GUI';
029300000000      msgf = 'QGUIMSG';
029400000000    when %subst(ApiErrC.MsgId:1:3) = 'WSE';
029500000000      msgf = 'WSMSGF';
029600000000  endsl;
029700000000
029800000000  GenUtl_Escape( ApiErrC.MsgId
029900000000               : %subst(ApiErrC.MsgData: 1: ApiErrC.BytAvail - 16)
030000000000               : msgf: msgflib: iCaller );
030100000000  return;
030200000000end-proc;
030300000000
030400000000//******************************************************************************
030500000000// This procedure handle option selection in the list
030600000000//******************************************************************************
030700000000dcl-proc HandleOptionSelections;
030800000000  dcl-pi *n;
030900000000    pAppHandle          char(8);
031000000000    pRecName            char(10);
031100000000    pListName           char(10);
031200000000  end-pi;
031300000000
031400000000  dcl-s  eHandle        char(4);
031500000000  dcl-s  iPosOpt        char(4);
031600000000  dcl-s  iSelHnd        char(4);
031700000000  dcl-ds iSelCri        qualified;
031800000000    Operator            char(10);
031900000000    ColName             char(10);
032000000000  end-ds;
032100000000  dcl-s  sSelHnd        char(4);
032200000000  dcl-s  cmdstr         varchar(256);
032300000000
032400000000  iSelCri.Operator = 'GT';             // select list option value greater than
032500000000  iSelCri.ColName  = 'OPT';            // the dialog option variable (zero)
032600000000
032700000000  iPosOpt = 'HNDL';                    // get by selection handle
032800000000  iSelHnd = 'EXTE';                    // get the extended action entry
032900000000
033000000000  dow ApiErrC.MsgId <> 'CPF6A98';      // loop on selection list
033100000000    reset detail;                      // clear out the dialog variables
033200000000    callp IBMUIM_PutVariable( pAppHandle: detail: %len(detail)
033300000000                            : pRecName: ApiErrC );
033400000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
033500000000      callp CancelProgram();           // cancel the program
033600000000    endif;
033700000000
033800000000    callp IBMUIM_GetListEntry( pAppHandle: detail: %len(detail)
033900000000                             : pRecName: pListName: iPosOpt: 'Y'
034000000000                             : iSelCri: iSelHnd: 'N': eHandle: ApiErrC );
034100000000    if ApiErrC.BytAvail > *zero;       // if an error occurred
034200000000      if ApiErrC.MsgId = 'CPF6A98';    // end of selections?
034300000000        iter;                          // let the loop end
034400000000      endif;                           // else
034500000000      callp CancelProgram();           // cancel the program
034600000000    endif;
034700000000    sSelHnd = eHandle;                 // save selected entry handle
034800000000    header.JobName = %xlate(GenUtl_lower:GenUtl_UPPER:detail.JobName); // start here next time
034900000000
035000000000    select;
035100000000      when detail.Action = 1;          // add an entry?
035200000000        cmdstr = '?ADDJBCTLDF ??JOB(' + %trim(detail.JobName) + ')';
035300000000        monitor;
035400000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
035500000000        on-error;
035600000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
035700000000                             : 'WSMSGF': *omit: PROC_PGM);
035800000000        endmon;
035900000000
036000000000      when detail.Action = 2;          // change an entry?
036100000000        cmdstr = '?CHGJBCTLDF ??JOB(' + %trim(detail.JobName) + ')';
036200000000        monitor;
036300000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
036400000000        on-error;
036500000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
036600000000                             : 'WSMSGF': *omit: PROC_PGM);
036700000000        endmon;
036800000000
036900000000      when detail.Action = 3;          // copy an entry?
037000000000        cmdstr = '?CPYJBCTLDF ??JOB(' + %trim(detail.JobName) + ')';
037100000000        monitor;
037200000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
037300000000        on-error;
037400000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
037500000000                             : 'WSMSGF': *omit: PROC_PGM);
037600000000        endmon;
037700000000
037800000000      when detail.Action = 4;          // delete an entry?
037900000000        cmdstr = '?DLTJBCTLDF ??JOB(' + %trim(detail.JobName) + ')';
038000000000        monitor;
038100000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
038200000000        on-error;
038300000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
038400000000                             : 'WSMSGF': *omit: PROC_PGM);
038500000000        endmon;
038600000000
038700000000      when detail.Action = 9;          // replicate an entry?
038800000000        cmdstr = '?RPLJBCTLDF ??JOB(' + %trim(detail.JobName) + ')';
038900000000        monitor;
039000000000          callp IBMAPI_ExecSysCmd(cmdstr:%len(cmdstr));
039100000000        on-error;
039200000000          callp GenUtl_Inform( 'WSE9897': 'CPF6801 error trapped.'
039300000000                             : 'WSMSGF': *omit: PROC_PGM);
039400000000        endmon;
039500000000
039600000000      when detail.Action = 10;         // transfer to options panel?
039700000000        GenUtl_CSTKE = GenUtl_FindCallStackEntry('*FND': tProgram);
039800000000        if GenUtl_CSTKE.QWVPGMN <> tProgram;
039900000000          callp AC04WRKR(detail.JobName);
040000000000          header.JobName = detail.JobName;
040100000000        else;
040200000000          pJobId = detail.JobName;
040300000000          iContinue = *off;
040400000000          return;
040500000000        endif;
040600000000
040700000000    endsl;
040800000000
040900000000    if iPosOpt = 'HNDL';               // if no extended action entry
041000000000      iPosOpt = 'FSLT';                // get first selected list entry
041100000000    else;                              // else
041200000000      iPosOpt = 'NSLT';                // get next selected list entry
041300000000    endif;
041400000000  enddo;                               // end of loop on selection list
041500000000
041600000000  reset ApiErrC;                       // clear out any errors
041700000000
041800000000  return;
041900000000end-proc;
042000000000
