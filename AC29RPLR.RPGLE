000100888888**free
000200000000//==============================================================================
000300000000// Program Name:      AC29RPLR -- Job Control Defaults Replication
000400000000// Programmer:        Dave L Clark I
000500000000// Date:              November 8, 2018
000600000000// Project/Request #: IN-58 Create Commands to Maintain Job Control Defaults
000700000000// Purpose:           This command processing program performs replication of
000800000000//                    the Job Control Defaults (AC29) file, by job name, across
000900000000//                    the selected companies.
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
002600000000dcl-pi AC29RPLR         extpgm;
002700000000  gJobName              char(6);
002800000000  gAction               char(10);
002900000000  gTitle                char(25);
003000000000  gCoRange              likeds(CoRange_t);
003100000000  gCoList               likeds(CoList_t);
003200000000  gFilters              likeds(Filters_t);
003300000000end-pi;
003400000000
003500000000/include *libl/qrpglesrc,ut010SV                 // general utilities service program
003600000000
003700000000dcl-s  gFileName        char(21) inz('REV460/AC29');
003800000000dcl-f  AC29             disk extdesc('REV460/AC29') extfile(gFileName)
003900000000                        keyed usage(*update:*output:*delete) usropn;
004000000000dcl-ds AC29master       likerec(AC29rf:*all);
004100000000dcl-ds AC29ds           likerec(AC29rf:*all);
004200000000
004300000000dcl-f  CICOMPLF         disk(*ext) keyed usage(*input) usropn;
004400000000dcl-ds COMPds           likerec(CICOMPrf:*input);
004500000000dcl-s  iComp            like(COMPds.CIORGKY);
004600000000dcl-s  iTimes           like(gCoRange.Count);
004700000000
004800000000dcl-s  gCaller          char(10);
004900000000dcl-s  gLibrary         char(10) inz('DTA110');
005000000000dcl-s  msgdata          varchar(100);
005100000000
005200000000dcl-ds CoRange_t        qualified template;
005300000000  Count                 int(5);
005400000000  FromCompany           char(5);
005500000000  ThruCompany           char(5);
005600000000end-ds;
005700000000
005800000000dcl-ds CoList_t         qualified template;
005900000000  Count                 int(5);
006000000000  Elem                  char(5)   dim(99);
006100000000end-ds;
006200000000
006300000000dcl-ds Filters_t        qualified template;
006400000000  Count                 int(5);
006500000000  Buffer                char(198);
006600000000    Elem1               int(5)    overlay(Buffer);
006700000000    Elem2               int(5)    overlay(Buffer:*next);
006800000000    Elem3               int(5)    overlay(Buffer:*next);
006900000000    Elem4               int(5)    overlay(Buffer:*next);
007000000000end-ds;
007100000000
007200000000dcl-s  nStatus          pointer   inz(*null);
007300000000dcl-ds gStatus          qualified based(nStatus);
007400000000  Count                 int(5);
007500000000  Elem                  char(15)  dim(5);
007600000000end-ds;
007700000000
007800000000dcl-s  nEntity          pointer   inz(*null);
007900000000dcl-ds gEntity          qualified based(nEntity);
008000000000  Count                 int(5);
008100000000  Elem                  char(4)   dim(5);
008200000000end-ds;
008300000000
008400000000dcl-s  nRegion          pointer   inz(*null);
008500000000dcl-ds gRegion          qualified based(nRegion);
008600000000  Count                 int(5);
008700000000  Elem                  char(4)   dim(5);
008800000000end-ds;
008900000000
009000000000dcl-s  nOrgTyp          pointer   inz(*null);
009100000000dcl-ds gOrgTyp          qualified based(nOrgTyp);
009200000000  Count                 int(5);
009300000000  Elem                  char(15)  dim(5);
009400000000end-ds;
009500000000
009600000000//==============================================================================
009700000000// Begin mainline code
009800000000//==============================================================================
009900000000
010000000000if gFilters.Count >= 1;                // resolve parameter relative positioning
010100000000  nStatus = %addr(gFilters) + gFilters.Elem1;
010200000000  if gFilters.Count >= 2;
010300000000    nEntity = %addr(gFilters) + gFilters.Elem2;
010400000000  endif;
010500000000  if gFilters.Count >= 3;
010600000000    nRegion = %addr(gFilters) + gFilters.Elem3;
010700000000  endif;
010800000000  if gFilters.Count >= 4;
010900000000    nOrgTyp = %addr(gFilters) + gFilters.Elem4;
011000000000  endif;
011100000000endif;
011200000000
011300000000GenUtl_CSTKE = GenUtl_FindCallStackEntry('*PRV': PROC_NAME);
011400000000gCaller = GenUtl_CSTKE.QWVPGMN;        // save caller program name
011500000000
011600000000if %open(AC29);                        // if file left open
011700000000  close AC29;                          // close it
011800000000endif;
011900000000
012000000000reset gFileName;                       // point to master file
012100000000open AC29;                             // open the master file
012200000000chain(n) (gJobName) AC29 AC29master;   // check for job name
012300000000if not %found(AC29);                   // error if not found
012400000000  msgdata = '0000' + gJobName + gFileName;
012500000000  GenUtl_Escape( 'ACJ0001': msgdata: 'WSMSGF': '*LIBL': gCaller );
012600000000endif;
012700000000close AC29;                            // close the master file
012800000000
012900000000open CICOMPLF;                         // open company master
013000000000
013100000000if gCoRange.FromCompany > *blanks      // if a company range specified
013200000000and gCoRange.FromCompany <> '*ALL';    // and not all companies
013300000000  setll (gCoRange.FromCompany) CICOMPLF; // start at specified company number
013400000000  if gCoRange.ThruCompany <= *blanks;    // if thru company not specified
013500000000    gCoRange.ThruCompany = gCoRange.FromCompany; // default to from company
013600000000  endif;
013700000000endif;
013800000000
013900000000dou %eof(CICOMPLF);                    // loop on company records until eof
014000000000  read CICOMPLF COMPds;                // get a company record
014100000000  if not %eof(CICOMPLF);               // if we got a record...
014200000000
014300000000    if gCoRange.ThruCompany > *blanks  // if company "thru" range completed
014400000000    and COMPds.CIORGKY > gCoRange.ThruCompany;
014500000000      leave;                           // leave the loop
014600000000    endif;
014700000000
014800000000    if filtered_out_by_company(COMPds.CIORGKY) // if company filtered out
014900000000    or filtered_out_by_status(COMPds.CISTAT)
015000000000    or filtered_out_by_entity(COMPds.CICRPTYP)
015100000000    or filtered_out_by_region(COMPds.CISKEY)
015200000000    or filtered_out_by_orgtyp(COMPds.CITYPID);
015300000000      iter;                            // next iteration
015400000000    endif;
015500000000
015600000000    iComp = CrsApp_isCompanyNumber(COMPds.CIORGKY: *omit: gLibrary);
015700000000    if iComp > *blanks                 // is company valid
015800000000    and gLibrary > *blanks;            // and has a data library assigned?
015900000000
016000000000      gFileName = %trimr(gLibrary) + '/AC29'; // point to local file
016100000000      open(e) AC29;                    // open the local file
016200000000      if %error;                       // if no file present
016300000000        iter;                          // skip it
016400000000      endif;
016500000000
016600000000      iTimes += 1;                     // count the number of replications performed
016700000000      GenUtl_Inform( 'WSE9897': 'Replicating to ' + %trimr(gLibrary) + ' library.'
016800000000                   : 'WSMSGF': '*LIBL': PROC_NAME );
016900000000
017000000000      chain (gJobName) AC29 AC29ds;    // check for job name
017100000000      AC29ds = AC29master;             // replicate from master
017200000000      if %found(AC29);                 // if job name was found
017300000000        update(e) AC29rf AC29ds;       // replace existing job name
017400000000        if %error;                     // handle file errors
017500000000          msgdata = '0000' + gJobName + gFileName + %editc(%status:'X') + 'update    ';
017600000000          GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': gCaller );
017700000000        endif;
017800000000      else;                            // else
017900000000        write(e) AC29rf AC29ds;        // write the new job name
018000000000        if %error;                     // handle file errors
018100000000          msgdata = '0000' + gJobName + gFileName + %editc(%status:'X') + 'write     ';
018200000000          GenUtl_Escape( 'ACJ0003': msgdata: 'WSMSGF': '*LIBL': gCaller );
018300000000        endif;
018400000000      endif;
018500000000
018600000000      close AC29;                      // close the local file
018700000000
018800000000    endif;
018900000000  endif;
019000000000enddo;                                 // end loop on company records
019100000000
019200000000close CICOMPLF;                        // close company master
019300000000
019400000000GenUtl_Complete( 'WSE9897': 'Defaults replicated ' + %char(iTimes) + ' times.'
019500000000               : 'WSMSGF': '*LIBL': gCaller );
019600000000
019700000000*inlr = *on;                           // clear memory
019800000000return;                                // return to caller
019900000000
020000000000//==============================================================================
020100000000// This procedure filters out company records by company number
020200000000//==============================================================================
020300000000dcl-proc filtered_out_by_company;
020400000000  dcl-pi *n             like(boolean_t);
020500000000    pCompany            like(COMPds.CIORGKY);
020600000000  end-pi;
020700000000
020800000000  dcl-s  idx            like(gCoList.Count);
020900000000
021000000000  if gCoRange.Count > *zero            // if all companies
021100000000  and gCoRange.FromCompany = '*ALL';
021200000000    return *off;                       // no filtering by company number
021300000000  endif;
021400000000
021500000000  if gCoRange.FromCompany > *blanks;   // if a company range specified
021600000000    if pCompany < gCoRange.FromCompany    // and out of range
021700000000    or gCoRange.ThruCompany > *blanks
021800000000    and pCompany > gCoRange.ThruCompany;
021900000000      return *on;                         // filter it out
022000000000    endif;
022100000000    return *off;                          // use this company number
022200000000  endif;
022300000000
022400000000  for idx = 1 to gCoList.Count;        // loop on company list
022500000000    if pCompany = gCoList.Elem(idx);   // if this company is in list
022600000000      return *off;                     // use this company number
022700000000    endif;
022800000000  endfor;                              // end loop on company list
022900000000
023000000000  return *on;                          // not in list, filter it out
023100000000end-proc;
023200000000
023300000000//==============================================================================
023400000000// This procedure filters out company records by company status
023500000000//==============================================================================
023600000000dcl-proc filtered_out_by_status;
023700000000  dcl-pi *n             like(boolean_t);
023800000000    pStatus             like(COMPds.CISTAT);
023900000000  end-pi;
024000000000
024100000000  dcl-s  idx            like(gStatus.Count);
024200000000
024300000000  if  nStatus = *null                  // if no status list
024400000000  or  gStatus.Count > *zero            // or all statuses
024500000000  and gStatus.Elem(1) = '*ALL';
024600000000    return *off;                       // no filtering by company status
024700000000  endif;
024800000000
024900000000  for idx = 1 to gStatus.Count;        // loop on status list
025000000000    if gStatus.Elem(idx) = ('*'
025100000000                           + %xlate(GenUtl_lower:GenUtl_UPPER:pStatus)
025200000000                           )           // if this status is in list
025300000000    or pStatus = 'Test';               // or is a test company
025400000000      return *off;                     // use this company number
025500000000    endif;
025600000000  endfor;                              // end loop on status list
025700000000
025800000000  return *on;                          // not in list, filter it out
025900000000end-proc;
026000000000
026100000000//==============================================================================
026200000000// This procedure filters out company records by corporate entity
026300000000//==============================================================================
026400000000dcl-proc filtered_out_by_entity;
026500000000  dcl-pi *n             like(boolean_t);
026600000000    pEntity             like(COMPds.CICRPTYP);
026700000000  end-pi;
026800000000  dcl-s  idx            like(gEntity.Count);
026900000000
027000000000  if  nEntity = *null                  // if no entity list
027100000000  or  gEntity.Count > *zero            // or all entities
027200000000  and gEntity.Elem(1) = '*ALL';
027300000000    return *off;                       // no filtering by entity
027400000000  endif;
027500000000
027600000000  for idx = 1 to gEntity.Count;        // loop on entity list
027700000000    if  gEntity.Elem(idx) = ('*' + pEntity); // if this entity is in list
027800000000      return *off;                     // use this company number
027900000000    endif;
028000000000  endfor;                              // end loop on entity list
028100000000
028200000000  return *on;                          // not in list, filter it out
028300000000end-proc;
028400000000
028500000000//==============================================================================
028600000000// This procedure filters out company records by service region
028700000000//==============================================================================
028800000000dcl-proc filtered_out_by_region;
028900000000  dcl-pi *n             like(boolean_t);
029000000000    pRegion             like(COMPds.CISKEY);
029100000000  end-pi;
029200000000
029300000000  dcl-s  idx            like(gRegion.Count);
029400000000
029500000000  if  nRegion = *null                  // if no region list
029600000000  or  gRegion.Count > *zero            // or all regions
029700000000  and gRegion.Elem(1) = '*ALL';
029800000000    return *off;                       // no filtering by region
029900000000  endif;
030000000000
030100000000  for idx = 1 to gRegion.Count;        // loop on region list
030200000000    if  gRegion.Elem(idx) = pRegion;   // if this region is in list
030300000000      return *off;                     // use this company number
030400000000    endif;
030500000000  endfor;                              // end loop on region list
030600000000
030700000000  return *on;                          // not in list, filter it out
030800000000end-proc;
030900000000
031000000000//==============================================================================
031100000000// This procedure filters out company records by organization type
031200000000//==============================================================================
031300000000dcl-proc filtered_out_by_orgtyp;
031400000000  dcl-pi *n             like(boolean_t);
031500000000    pOrgTyp             like(COMPds.CITYPID);
031600000000  end-pi;
031700000000
031800000000  dcl-s  idx            like(gOrgTyp.Count);
031900000000
032000000000  if  nOrgTyp = *null                  // if no org type list
032100000000  or  gOrgTyp.Count > *zero            // or all org types
032200000000  and gOrgTyp.Elem(1) = '*ALL';
032300000000    return *off;                       // no filtering by org type
032400000000  endif;
032500000000
032600000000  for idx = 1 to gOrgTyp.Count;        // loop on org type list
032700000000    if  pOrgTyp = 'AREA'               // if this org type is in list
032800000000    and gOrgTyp.Elem(idx) = '*AREA'
032900000000    or  pOrgTyp = 'CPLX'
033000000000    and gOrgTyp.Elem(idx) = '*COMPLEX'
033100000000    or  pOrgTyp = 'CSLT'
033200000000    and gOrgTyp.Elem(idx) = '*CONSULTING'
033300000000    or  pOrgTyp = 'INVS'
033400000000    and gOrgTyp.Elem(idx) = '*INVESTMENT'
033500000000    or  pOrgTyp = 'LOCO'
033600000000    and gOrgTyp.Elem(idx) = '*LOCALOPER'
033700000000    or  pOrgTyp = 'SRVC'
033800000000    and gOrgTyp.Elem(idx) = '*SERVICE'
033900000000    or  pOrgTyp = 'SRCG'
034000000000    and gOrgTyp.Elem(idx) = '*SOURCING'
034100000000    or  pOrgTyp = 'OTHR'
034200000000    and gOrgTyp.Elem(idx) = '*OTHER';
034300000000      return *off;                     // use this company number
034400000000    endif;
034500000000  endfor;                              // end loop on org type list
034600000000
034700000000  return *on;                          // not in list, filter it out
034800000000end-proc;
034900000000
