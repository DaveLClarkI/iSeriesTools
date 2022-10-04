000100888888**free
000200000000//==============================================================================
000300000000// Program Name:      AC29LKUR -- Job Control Defaults Lookup
000400000000// Programmer:        Dave L Clark I
000500000000// Date:              November 8, 2018
000600000000// Project/Request #: IN-58 Create Commands to Maintain Job Control Defaults
000700000000// Purpose:           This command prompt override program performs a lookup on
000800000000//                    the Job Control Defaults (AC29) file by job name and
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
002300000000ctl-opt MAIN(AC29LKUR) AlwNull(*UsrCtl) DatFmt(*ISO) TimFmt(*ISO)
002400000000        DftActGrp(*No) ActGrp(*Caller) BndDir('WSBNDDIR')
002500000000        Debug Option(*SrcStmt:*NoDebugIo);
002600000000
002700000000/include *libl/qrpglesrc,ut010SV                 // general utilities service program
002800000000
002900000000//==============================================================================
003000000000// Begin main procedure definition
003100000000//==============================================================================
003200000000dcl-proc AC29LKUR;
003300000000  dcl-pi *n             extpgm;
003400000000    pQualCommand        char(20);
003500000000    pJobName            char(6);
003600000000    pCmdStr             varchar(32760);
003700000000  end-pi;
003800000000
003900000000  dcl-f AC04            disk extdesc('REV460/AC04')
004000000000                        extfile(*extdesc) keyed
004100000000                        usage(*input) usropn;
004200000000  dcl-ds AC04ds         likerec(AC04rf:*input);
004300000000
004400000000  dcl-s iFileName       char(21) inz('REV460/AC29');
004500000000  dcl-f AC29            disk extdesc('REV460/AC29')
004600000000                        extfile(iFileName) keyed
004700000000                        usage(*input) usropn;
004800000000  dcl-ds AC29ds         likerec(AC29rf:*input);
004900000000
005000000000  pCmdStr = '';                        // initialize the cmd string
005100000000
005200000000  if not %open(AC04);                  // if file not open, yet
005300000000    open AC04;                         // open it
005400000000  endif;
005500000000  if not %open(AC29);                  // if file not open, yet
005600000000    open AC29;                         // open it
005700000000  endif;
005800000000
005900000000  chain (pJobName) AC04 AC04ds;        // is job name present?
006000000000  chain (pJobName) AC29 AC29ds;        // is job name present?
006100000000
006200000000  select;
006300000000  when not %found(AC29)                // no, cannot change/copy/delete/replicate
006400000000  and GenUtl_inList(%subst(pQualCommand:1:3): 'CHG,CPY,DLT,RPL');
006500000000    pCmdStr += ' ?<TITLE(''...job not found...'')';
006600000000
006700000000  when %found(AC29)                    // yes, cannot add
006800000000  and %subst(pQualCommand:1:3) = 'ADD';
006900000000    if %found(AC04)
007000000000    and AC04ds.JBTITL > *blanks;
007100000000      pCmdStr += ' ?<TITLE(' + GenUtl_MakeQuotedString(AC04ds.JBTITL) + ')';
007200000000    else;
007300000000      pCmdStr += ' ?<TITLE(''...job already exists...'')';
007400000000    endif;
007500000000    pCmdStr += ' ?<PROC(''{found}'')';
007600000000
007700000000  when %found(AC29)                    // yes, build cmd parm overrides for change
007800000000  and %subst(pQualCommand:1:3) = 'CHG';
007900000000    if %found(AC04)
008000000000    and AC04ds.JBTITL > *blanks;
008100000000      pCmdStr += ' ??TITLE(' + GenUtl_MakeQuotedString(AC04ds.JBTITL) + ')';
008200000000    else;
008300000000      pCmdStr += ' ??TITLE(*NONE)';
008400000000    endif;
008500000000    if AC29ds.CEPROC > *blanks;
008600000000      pCmdStr += ' ??PROC(' + GenUtl_MakeQuotedString(AC29ds.CEPROC) + ')';
008700000000    endif;
008800000000    if AC29ds.CEDT1 > *zero;
008900000000      pCmdStr += ' ??DATE1(' + GenUtl_MakeQuotedString(%char(%date(AC29ds.CEDT1:*iso):*usa)) + ')';
009000000000    endif;
009100000000    if AC29ds.CEDT2 > *zero;
009200000000      pCmdStr += ' ??DATE2(' + GenUtl_MakeQuotedString(%char(%date(AC29ds.CEDT2:*iso):*usa)) + ')';
009300000000    endif;
009400000000
009500000000    if AC29ds.CEDTLR > *blanks;
009600000000      pCmdStr += ' ??SELOPT(' + GenUtl_MakeQuotedString(AC29ds.CEDTLR) + ')';
009700000000    endif;
009800000000    if %subst(AC29ds.CEP:1:1) > *blanks;
009900000000      pCmdStr += ' ??OPTION1(' + %subst(AC29ds.CEP:1:1) + ')';
010000000000    endif;
010100000000    if %subst(AC29ds.CEP:2:1) > *blanks;
010200000000      pCmdStr += ' ??OPTION2(' + %subst(AC29ds.CEP:2:1) + ')';
010300000000    endif;
010400000000    if %subst(AC29ds.CEP:3:1) > *blanks;
010500000000      pCmdStr += ' ??OPTION3(' + %subst(AC29ds.CEP:3:1) + ')';
010600000000    endif;
010700000000    if %subst(AC29ds.CEP:4:1) > *blanks;
010800000000      pCmdStr += ' ??OPTION4(' + %subst(AC29ds.CEP:4:1) + ')';
010900000000    endif;
011000000000    if %subst(AC29ds.CEP:5:1) > *blanks;
011100000000      pCmdStr += ' ??OPTION5(' + %subst(AC29ds.CEP:5:1) + ')';
011200000000    endif;
011300000000    if AC29ds.CELOC > *blanks;
011400000000      pCmdStr += ' ??LOCSEL(' + AC29ds.CELOC + ')';
011500000000    endif;
011600000000
011700000000    if AC29ds.CEISS > *blanks;
011800000000      pCmdStr += ' ??ISSUE(' + GenUtl_MakeQuotedString(AC29ds.CEISS) + ')';
011900000000    endif;
012000000000    if AC29ds.CEUSE1 > *blanks;
012100000000      pCmdStr += ' ??USEOPT1(' + GenUtl_MakeQuotedString(AC29ds.CEUSE1) + ')';
012200000000    endif;
012300000000    if AC29ds.CEUSE2 > *blanks;
012400000000      pCmdStr += ' ??USEOPT2(' + GenUtl_MakeQuotedString(AC29ds.CEUSE2) + ')';
012500000000    endif;
012600000000    if AC29ds.CEUSE3 > *blanks;
012700000000      pCmdStr += ' ??USEOPT3(' + GenUtl_MakeQuotedString(AC29ds.CEUSE3) + ')';
012800000000    endif;
012900000000    if AC29ds.CEUSE4 > *blanks;
013000000000      pCmdStr += ' ??USEOPT4(' + GenUtl_MakeQuotedString(AC29ds.CEUSE4) + ')';
013100000000    endif;
013200000000    if AC29ds.CEUSE# > *zero;
013300000000      pCmdStr += ' ??USEOPTN(' + %char(AC29ds.CEUSE#) + ')';
013400000000    endif;
013500000000    if AC29ds.CEU > *blanks;
013600000000      pCmdStr += ' ??USRPWD(' + GenUtl_MakeQuotedString(AC29ds.CEU) + ')';
013700000000    endif;
013800000000
013900000000  other;                               // else, build cmd parm overrides for everything else
014000000000    if %found(AC04)
014100000000    and AC04ds.JBTITL > *blanks;
014200000000      pCmdStr += ' ??TITLE(' + GenUtl_MakeQuotedString(AC04ds.JBTITL) + ')';
014300000000    else;
014400000000      pCmdStr += ' ??TITLE(*NONE)';
014500000000    endif;
014600000000  endsl;
014700000000
014800000000  if %open(AC29);                      // if file is open
014900000000    close AC29;                        // close it
015000000000  endif;
015100000000  if %open(AC04);                      // if file is open
015200000000    close AC04;                        // close it
015300000000  endif;
015400000000
015500000000  return;                              // return to caller
015600000000end-proc;
015700000000
