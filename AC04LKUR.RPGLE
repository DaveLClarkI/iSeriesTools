000100888888**free
000200000000//==============================================================================
000300000000// Program Name:      AC04LKUR -- Job Control Options Lookup
000400000000// Programmer:        Dave L Clark I
000500000000// Date:              November 8, 2018
000600000000// Project/Request #: IN-57 Create Commands to Maintain Job Control Options
000700000000// Purpose:           This command prompt override program performs a lookup on
000800000000//                    the Job Control Options (AC04) file by job name and
000900000000//                    preloads command parameters accordingly.
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
002300000000ctl-opt MAIN(AC04LKUR) AlwNull(*UsrCtl) DatFmt(*ISO) TimFmt(*ISO)
002400000000        DftActGrp(*No) ActGrp(*Caller) BndDir('WSBNDDIR')
002500000000        Debug Option(*SrcStmt:*NoDebugIo);
002600000000
002700000000dcl-c normal            x'20';
002800000000dcl-c bright            x'22';
002900000000dcl-c bright_start      '{';
003000000000dcl-c normal_start      '}';
003100000000
003200000000/include *libl/qrpglesrc,ut010SV                 // general utilities service program
003300000000
003400000000//==============================================================================
003500000000// Begin main procedure definition
003600000000//==============================================================================
003700000000dcl-proc AC04LKUR;
003800000000  dcl-pi *n             extpgm;
003900000000    pQualCommand        char(20);
004000000000    pJobName            char(6);
004100000000    pCmdStr             varchar(32760);
004200000000  end-pi;
004300000000
004400000000  dcl-s iFileName       char(21) inz('REV460/AC04');
004500000000  dcl-f AC04            disk extdesc('REV460/AC04')
004600000000                        extfile(iFileName) keyed
004700000000                        usage(*input) usropn;
004800000000  dcl-ds AC04ds         likerec(AC04rf:*input);
004900000000
005000000000  pCmdStr = '';                        // initialize the cmd string
005100000000
005200000000  if not %open(AC04);                  // if file not open, yet
005300000000    open AC04;                         // open it
005400000000  endif;
005500000000
005600000000  chain (pJobName) AC04 AC04ds;        // is job name present?
005700000000
005800000000  select;
005900000000  when not %found(AC04)                // no, cannot change/copy/delete/display/replicate
006000000000  and GenUtl_inList(%subst(pQualCommand:1:3): 'CHG,CPY,DLT,DSP,RPL');
006100000000    pCmdStr += ' ?<TITLE(''...job not found...'')';
006200000000
006300000000  when %found(AC04)                    // yes, cannot add
006400000000  and %subst(pQualCommand:1:3) = 'ADD';
006500000000    if AC04ds.JBTITL > *blanks;
006600000000      pCmdStr += ' ?<TITLE(' + GenUtl_MakeQuotedString(AC04ds.JBTITL) + ')';
006700000000    else;
006800000000      pCmdStr += ' ?<TITLE(*NONE)';
006900000000    endif;
007000000000    pCmdStr += ' ?<DATE1(''...job already exists...'')';
007100000000
007200000000  when %found(AC04)                    // yes, build cmd parm overrides for change
007300000000  and %subst(pQualCommand:1:3) = 'CHG';
007400000000    if AC04ds.JBTITL > *blanks;
007500000000      pCmdStr += ' ??TITLE(' + GenUtl_MakeQuotedString(AC04ds.JBTITL) + ')';
007600000000    else;
007700000000      pCmdStr += ' ??TITLE(*NONE)';
007800000000    endif;
007900000000    if AC04ds.JBTX01 > *blanks;
008000000000      pCmdStr += ' ??DATE1(' + GenUtl_MakeQuotedString(
008100000000                                join_strings(AC04ds.JBTX01:'')
008200000000                                                      ) + ')';
008300000000    endif;
008400000000    if AC04ds.JBTX02 > *blanks;
008500000000      pCmdStr += ' ??DATE2(' + GenUtl_MakeQuotedString(
008600000000                                join_strings(AC04ds.JBTX02:'')
008700000000                                                      ) + ')';
008800000000    endif;
008900000000    if AC04ds.JBTX03 > *blanks
009000000000    or AC04ds.JBTX04 > *blanks;
009100000000      pCmdStr += ' ??SELOPT(' + GenUtl_MakeQuotedString(
009200000000                                  join_strings( AC04ds.JBTX03
009300000000                                              : AC04ds.JBTX04 )
009400000000                                                       ) + ')';
009500000000    endif;
009600000000    if AC04ds.JBTX05 > *blanks
009700000000    or AC04ds.JBTX06 > *blanks;
009800000000      pCmdStr += ' ??OPTION1(' + GenUtl_MakeQuotedString(
009900000000                                   join_strings( AC04ds.JBTX05
010000000000                                               : AC04ds.JBTX06 )
010100000000                                                        ) + ')';
010200000000    endif;
010300000000    if AC04ds.JBTX07 > *blanks
010400000000    or AC04ds.JBTX08 > *blanks;
010500000000      pCmdStr += ' ??OPTION2(' + GenUtl_MakeQuotedString(
010600000000                                   join_strings( AC04ds.JBTX07
010700000000                                               : AC04ds.JBTX08 )
010800000000                                                        ) + ')';
010900000000    endif;
011000000000    if AC04ds.JBTX09 > *blanks
011100000000    or AC04ds.JBTX10 > *blanks;
011200000000      pCmdStr += ' ??OPTION3(' + GenUtl_MakeQuotedString(
011300000000                                   join_strings( AC04ds.JBTX09
011400000000                                               : AC04ds.JBTX10 )
011500000000                                                        ) + ')';
011600000000    endif;
011700000000    if AC04ds.JBTX11 > *blanks
011800000000    or AC04ds.JBTX12 > *blanks;
011900000000      pCmdStr += ' ??OPTION4(' + GenUtl_MakeQuotedString(
012000000000                                   join_strings( AC04ds.JBTX11
012100000000                                               : AC04ds.JBTX12 )
012200000000                                                        ) + ')';
012300000000    endif;
012400000000    if AC04ds.JBTX13 > *blanks
012500000000    or AC04ds.JBTX14 > *blanks;
012600000000      pCmdStr += ' ??OPTION5(' + GenUtl_MakeQuotedString(
012700000000                                   join_strings( AC04ds.JBTX13
012800000000                                               : AC04ds.JBTX14 )
012900000000                                                        ) + ')';
013000000000    endif;
013100000000    if AC04ds.JBLOC > *blanks;
013200000000      pCmdStr += ' ??LOCSEL(' + GenUtl_MakeQuotedString(
013300000000                                  join_strings(AC04ds.JBLOC:'')
013400000000                                                       ) + ')';
013500000000    endif;
013600000000
013700000000  other;                               // else, build cmd parm overrides for everything else
013800000000    if AC04ds.JBTITL > *blanks;
013900000000      pCmdStr += ' ??TITLE(' + GenUtl_MakeQuotedString(AC04ds.JBTITL) + ')';
014000000000    else;
014100000000      pCmdStr += ' ??TITLE(*NONE)';
014200000000    endif;
014300000000  endsl;
014400000000
014500000000  if %open(AC04);                      // if file is open
014600000000    close AC04;                        // close it
014700000000  endif;
014800000000
014900000000  return;                              // return to caller
015000000000end-proc;
015100000000
015200000000//==============================================================================
015300000000// This procedure joins two strings together with special formatting.
015400000000//==============================================================================
015500000000dcl-proc join_strings;
015600000000  dcl-pi *n             varchar(98);
015700000000    pString1            char(50)       value;
015800000000    pString2            char(50)       value;
015900000000  end-pi;
016000000000
016100000000  if GenUtl_LeftString(pString1:1) = ' '; // blank signals indentation
016200000000    pString1 = '.' + %subst(pString1:2); // replace it with a period
016300000000  endif;
016400000000                                       // handle special highlighting
016500000000  pString1 = GenUtl_ScanAndReplace(bright: pString1: bright_start);
016600000000  pString1 = GenUtl_ScanAndReplace(normal: pString1: normal_start);
016700000000
016800000000  pString2 = GenUtl_ScanAndReplace(bright: pString2: bright_start);
016900000000  pString2 = GenUtl_ScanAndReplace(normal: pString2: normal_start);
017000000000
017100000000  return %trimr(pString1) + ' ' + %trim(pString2);
017200000000end-proc;
017300000000
