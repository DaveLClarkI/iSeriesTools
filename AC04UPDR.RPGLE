000100888888**free
000200000000//==============================================================================
000300000000// Program Name:      AC04UPDR -- Job Control Options Update
000400000000// Programmer:        Dave L Clark I
000500000000// Date:              November 8, 2018
000600000000// Project/Request #: IN-57 Create Commands to Maintain Job Control Options
000700000000// Purpose:           This command processing program performs maintenance on
000800000000//                    the Job Control Options (AC04) file by job name.
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
002200000000ctl-opt MAIN(AC04UPDR) AlwNull(*UsrCtl) Debug Option(*SrcStmt:*NoDebugIo)
002300000000        DatFmt(*ISO) TimFmt(*ISO) DftActGrp(*No) ActGrp(*Caller) BndDir('WSBNDDIR');
002400000000
002500000000dcl-c normal            x'20';
002600000000dcl-c bright            x'22';
002700000000dcl-c bright_start      '{';
002800000000dcl-c normal_start      '}';
002900000000
003000000000/include *libl/qrpglesrc,ut010SV                 // general utilities service program
003100000000
003200000000//==============================================================================
003300000000// Begin main procedure definition
003400000000//==============================================================================
003500000000dcl-proc AC04UPDR;
003600000000  dcl-pi *n             extpgm;
003700000000    pJobName            char(6);
003800000000    pAction             char(10);
003900000000    pTitle              char(25);
004000000000    pDate1              char(50);
004100000000    pDate2              char(50);
004200000000    pSelOpt             char(98);
004300000000    pOption1            char(98);
004400000000    pOption2            char(98);
004500000000    pOption3            char(98);
004600000000    pOption4            char(98);
004700000000    pOption5            char(98);
004800000000    pLocOpt             char(18);
004900000000  end-pi;
005000000000
005100000000  dcl-s iFileName       char(21) inz('REV460/AC04');
005200000000  dcl-f AC04            disk extdesc('REV460/AC04') extfile(iFileName)
005300000000                        keyed usage(*update:*output:*delete) usropn;
005400000000  dcl-ds AC04ds         likerec(AC04rf:*all);
005500000000  dcl-s  iCaller        char(10);
005600000000  dcl-s  msgdata        varchar(100);
005700000000
005800000000  GenUtl_CSTKE = GenUtl_FindCallStackEntry('*PRV': PROC_NAME);
005900000000  iCaller = GenUtl_CSTKE.QWVPGMN;      // save caller program name
006000000000
006100000000  if not %open(AC04);                  // if file not open, yet
006200000000    open AC04;                         // open it
006300000000  endif;
006400000000
006500000000  chain (pJobName) AC04 AC04ds;        // check for job name
006600000000
006700000000  select;
006800000000  when not %found(AC04)                // none found for change/copy/delete
006900000000  and GenUtl_inList(pAction: '*CHG,*CPY,*DLT');
007000000000    msgdata = '0000' + pJobName + iFileName;
007100000000    GenUtl_Escape( 'ACJ0001': msgdata: 'WSMSGF': '*LIBL': iCaller );
007200000000
007300000000  when %found(AC04)                    // already there for add
007400000000  and pAction = '*ADD';
007500000000    msgdata = '0000' + pJobName + iFileName;
007600000000    GenUtl_Escape( 'ACJ0002': msgdata: 'WSMSGF': '*LIBL': iCaller );
007700000000
007800000000  other;                               // ready to maintain...
007900000000    select;
008000000000    when pAction = '*DLT';             // for delete
008100000000      if AC04ds.JBSTAT = '1';          // if record active
008200000000        AC04ds.JBSTAT = '0';           // inactivate it
008300000000        update(e) AC04rf AC04ds;
008400000000      else;                            // else, delete it
008500000000        delete(e) AC04rf;
008600000000      endif;
008700000000      if %error;                       // handle file errors
008800000000        msgdata = '0000' + pJobName + iFileName + %editc(%status:'X') + 'delete    ';
008900000000        GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': iCaller );
009000000000      endif;
009100000000
009200000000    when pAction = '*CPY';             // for copy
009300000000      AC04ds.JBSTAT = '1';             // activate record
009400000000      AC04ds.JBNAME = pTitle;          // new job name
009500000000      AC04ds.JBTITL = pDate1;          // new job title
009600000000      write(e) AC04rf AC04ds;
009700000000      if %error;                       // handle file errors
009800000000        msgdata = '0000' + pJobName + iFileName + %editc(%status:'X') + 'copy      ';
009900000000        GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': iCaller );
010000000000      endif;
010100000000
010200000000    other;                             // for add/change/create
010300000000      AC04ds.JBSTAT = '1';             // activate record
010400000000      AC04ds.JBNAME = pJobName;        // save field data
010500000000      AC04ds.JBTITL = pTitle;
010600000000      AC04ds.JBTX01 = formatted(pDate1);
010700000000      AC04ds.JBTX02 = formatted(pDate2);
010800000000      callp split_strings(formatted(pSelOpt): AC04ds.JBTX03: AC04ds.JBTX04);
010900000000      callp split_strings(formatted(pOption1): AC04ds.JBTX05: AC04ds.JBTX06);
011000000000      callp split_strings(formatted(pOption2): AC04ds.JBTX07: AC04ds.JBTX08);
011100000000      callp split_strings(formatted(pOption3): AC04ds.JBTX09: AC04ds.JBTX10);
011200000000      callp split_strings(formatted(pOption4): AC04ds.JBTX11: AC04ds.JBTX12);
011300000000      callp split_strings(formatted(pOption5): AC04ds.JBTX13: AC04ds.JBTX14);
011400000000      AC04ds.JBLOC = formatted(pLocOpt);
011500000000
011600000000      if %found(AC04);                 // if job name was found
011700000000        update(e) AC04rf AC04ds;       // replace existing job name
011800000000        if %error;                     // handle file errors
011900000000          msgdata = '0000' + pJobName + iFileName + %editc(%status:'X') + 'update    ';
012000000000          GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': iCaller );
012100000000        endif;
012200000000      else;                            // else
012300000000        write(e) AC04rf AC04ds;        // write the new job name
012400000000        if %error;                     // handle file errors
012500000000          msgdata = '0000' + pJobName + iFileName + %editc(%status:'X') + 'write     ';
012600000000          GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': iCaller );
012700000000        endif;
012800000000      endif;
012900000000
013000000000    endsl;
013100000000
013200000000  endsl;
013300000000
013400000000  if %open(AC04);                      // if file is open
013500000000    close AC04;                        // close it
013600000000  endif;
013700000000
013800000000  select;
013900000000    when pAction = '*ADD';
014000000000      GenUtl_Complete( 'WSE9897': 'Options added.'
014100000000                     : 'WSMSGF': '*LIBL': iCaller );
014200000000    when pAction = '*CHG';
014300000000      GenUtl_Complete( 'WSE9897': 'Options changed.'
014400000000                     : 'WSMSGF': '*LIBL': iCaller );
014500000000    when pAction = '*CPY';
014600000000      GenUtl_Complete( 'WSE9897': 'Options copied.'
014700000000                     : 'WSMSGF': '*LIBL': iCaller );
014800000000    when pAction = '*CRT';
014900000000      GenUtl_Complete( 'WSE9897': 'Options created.'
015000000000                     : 'WSMSGF': '*LIBL': iCaller );
015100000000    when pAction = '*DLT';
015200000000      GenUtl_Complete( 'WSE9897': 'Options deleted.'
015300000000                     : 'WSMSGF': '*LIBL': iCaller );
015400000000    other;
015500000000  endsl;
015600000000
015700000000  return;                              // return to caller
015800000000end-proc;
015900000000
016000000000//==============================================================================
016100000000// This procedure handles special formatting for indenting and highlighting.
016200000000//==============================================================================
016300000000dcl-proc formatted;
016400000000  dcl-pi *n             char(100);
016500000000    pInput              char(100)      value;
016600000000  end-pi;
016700000000
016800000000  dcl-s iOutput         like(pInput);
016900000000
017000000000  iOutput = pInput;                    // copy to output buffer
017100000000
017200000000  if GenUtl_LeftString(iOutput:1) = '.'; // period signals indentation
017300000000    iOutput = ' ' + %subst(iOutput:2); // replace it with a space
017400000000  endif;
017500000000                                       // handle special highlighting
017600000000  iOutput = GenUtl_ScanAndReplace(bright_start: iOutput: bright);
017700000000  iOutput = GenUtl_ScanAndReplace(normal_start: iOutput: normal);
017800000000
017900000000  return iOutput;                      // return specially-formatted string
018000000000end-proc;
018100000000
018200000000//==============================================================================
018300000000// This procedure splits two strings apart with special formatting.
018400000000//==============================================================================
018500000000dcl-proc split_strings;
018600000000  dcl-pi *n;
018700000000    pInput              char(100)      value;
018800000000    pString1            char(50);
018900000000    pString2            char(50);
019000000000  end-pi;
019100000000
019200000000  dcl-s pos             packed(3);
019300000000  dcl-s len             packed(3)      inz(%len(pString1));
019400000000
019500000000  pos = scanr(' ' :pInput :len + 1);   // find where to split the string
019600000000
019700000000  if pos <= *zero;                     // nothing found?
019800000000    pString1 = %subst(pInput:1:len);   // nope, take the default split
019900000000    pString2 = '  ' + %triml(%subst(pInput:len+1));
020000000000  else;                                // else
020100000000    pString1 = %subst(pInput:1:pos-1); // split at the indicated position
020200000000    pString2 = '  ' + %triml(%subst(pInput:pos+1));
020300000000  endif;
020400000000
020500000000  return;
020600000000end-proc;
020700000000
020800000000//==============================================================================
020900000000// This procedure does a reverse scan for a 1-char needle in a haystack starting
021000000000// at a specified (or defaulted) position for a specified (or defaulted) length.
021100000000//==============================================================================
021200000000dcl-proc scanr;
021300000000  dcl-pi *n             packed(5);
021400000000    pNeedle             char(1)        value;
021500000000    pHaystack           varchar(8192)  value;
021600000000    pStartAt            packed(5)      value options(*nopass);
021700000000    pLength             packed(5)      value options(*nopass);
021800000000  end-pi;
021900000000
022000000000  dcl-s iStartAt        packed(5);
022100000000  dcl-s iLength         packed(5);
022200000000  dcl-s iPos            packed(5);
022300000000
022400000000  if %parms < %parmnum(pStartAt)       // if parm not passed
022500000000  or %addr(pStartAt) = *null           // or was omitted
022600000000  or pStartAt < 1                      // or is invalid
022700000000  or pStartAt > %len(pHaystack);
022800000000    iStartAt = %len(pHaystack);        // then use the default
022900000000  else;                                // else
023000000000    iStartAt = pStartAt;               // use the passed value
023100000000  endif;
023200000000
023300000000  if %parms < %parmnum(pLength)        // if parm not passed
023400000000  or %addr(pLength) = *null            // or was omitted
023500000000  or pLength < 1                       // or is invalid
023600000000  or pLength > %len(pHaystack);
023700000000    iLength = %len(pHaystack);         // then use the default
023800000000  else;                                // else
023900000000    iLength = pLength;                 // use the passed value
024000000000  endif;
024100000000
024200000000  iPos = iStartAt;                     // get starting position
024300000000
024400000000  dow iPos > *zero                     // while needle not found
024500000000  and iLength > *zero
024600000000  and %subst(pHaystack:iPos:1) <> pNeedle;
024700000000    iLength -= 1;                         // decrement scan length
024800000000    iPos -= 1;                            // decrement scan position
024900000000  enddo;                               // repeat
025000000000
025100000000  return iPos;                         // return needle position
025200000000end-proc;
025300000000
