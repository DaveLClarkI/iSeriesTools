**free
//==============================================================================
// Program:           LOOKUPSQL -- SQL Lookup for CL/ILE with Returned Value
// Programmer:        Dave L Clark I
// Date:              February 16, 2018
// Project/Request #: IN-53 Create a Command to Return an SQL Value in CL Program
// Purpose:           This command allows a CL/ILE program to pass the parts
//                    of an SQL statement to an RPG/ILE program for the
//                    purpose of getting back what is logically a one-column
//                    value but can actually be multiple concatenated columns
//                    that were converted to character format, first.  The CL
//                    program can then use %SST to split it apart and CHGVAR
//                    to convert character values back to decimal if needed.
//                    Note that, internally, only a single SQL row will be
//                    retrieved so the ORDER BY parameter could be important.
//------------------------------------------------------------------------------
//         Special Programming Logic / Considerations
//
// NONE
//
//------------------------------------------------------------------------------
//         Modification Log
//
// Mod#    Date       User       Description
// ---- ---------- ---------- --------------------------------------------------
// M000 03/08/2018 DLCLARK    Initial design.
//==============================================================================

ctl-opt MAIN(LOOKUPSQL) AlwNull(*UsrCtl) DatFmt(*ISO) TimFmt(*ISO)
        DftActGrp(*No) ActGrp(*Caller) Debug Option(*SrcStmt:*NoDebugIo);

// general copybooks
/include *libl/qrpglesrc,utsqlutsv          // SQL utilities service program

//==============================================================================
// Enter all global data definitions before this point
//==============================================================================

exec sql set option ALWBLK = *ALLREAD, CLOSQLCSR = *ENDACTGRP,
                    COMMIT = *NONE,    DATFMT = *ISO,
                    EXTIND = *YES,     LANGID = ENU,
                    NAMING = *SYS,     SRTSEQ = *HEX,
                    USRPRF = *USER,    DYNUSRPRF = *USER;

//==============================================================================
// Begin main procedure definition
//==============================================================================
dcl-proc LOOKUPSQL;
  dcl-pi *n                  extpgm;
    pReturnedValue           char(510);
    pColumnExpression        varchar(510);
    pTableExpression         varchar(510);
    pWhereClause             varchar(510);
    pOrderByClause           varchar(510);
  end-pi;

  dcl-c  loc_info            'LOOKUPSQL_Main_Procedure';
  dcl-s  sql_ind             like(NULL_VALUE);
  dcl-s  sqlstmt             varchar(3072);

  sqlstmt  = 'Values(';
  sqlstmt += 'Select Cast(' + pColumnExpression
                            + ' as Char(' + %char(%len(pReturnedValue))
                            + '))';
  sqlstmt += ' from ' + pTableExpression;

  pWhereClause = %trim(pWhereClause);
  if %len(pWhereClause) > *zero;
    sqlstmt += ' where ' + pWhereClause;
  endif;

  pOrderByClause = %trim(pOrderByClause);
  if %len(pOrderByClause) > *zero;
    sqlstmt += ' order by ' + pOrderByClause;
  endif;

  sqlstmt += ' ' + FETCH_FIRST + FETCH_ROW_ONLY;
  sqlstmt += ') into ?';

  exec sql prepare LOOKUPSQL_Statement
           attributes :FOR_READ_ONLY
                 from :sqlstmt;
  if not SqlUtl_SqlCompleted(sqlstate);     // did prepare fail?
    GenUtl_MsgInfo = SqlUtl_LogSqlFailure( Sql_Prepare_Error: '*ESCAPE'
                                         : sqlca: loc_info: sqlstmt );
  endif;

  exec sql execute LOOKUPSQL_Statement
             using :pReturnedValue :sql_ind;
  if not SqlUtl_SqlCompleted(sqlstate);     // did execute fail?
    select;
    when SqlUtl_SqlWarning(sqlstate);
      callp GenUtl_Escape('ACL0006': 'SQLWRN');
    when SqlUtl_SqlNoData(sqlstate);
      callp GenUtl_Escape('ACL0006': 'SQLNTF');
    other;
      GenUtl_MsgInfo = SqlUtl_LogSqlFailure( Sql_Execute_Error: '*ESCAPE'
                                           : sqlca: loc_info: sqlstmt );
    endsl;
  endif;

  if sql_ind = NULL_VALUE;                  // if null
    pReturnedValue = *blanks;               // return blanks
  endif;

  return;                                   // return to caller
end-proc;
 