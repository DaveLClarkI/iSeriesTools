/******************************************************************************/
/* Program Name:      LOOKUPSQL -- SQL Lookup for CL/ILE with Returned Value  */
/* Programmer:        Dave L Clark I                                          */
/* Date:              February 16, 2018                                       */
/* Project/Request #: IN-53 Create a Command to Return an SQL Value in CL Pgm */
/* Purpose:           This command allows a CL/ILE program to pass the parts  */
/*                    of an SQL statement to an RPG/ILE program for the       */
/*                    purpose of getting back what is logically a one-column  */
/*                    value but can actually be multiple concatenated columns */
/*                    that were converted to character format, first.  The CL */
/*                    program can then use %SST to split it apart and CHGVAR  */
/*                    to convert character values back to decimal if needed.  */
/*                    Note that, internally, only a single SQL row will be    */
/*                    retrieved so the ORDER BY parameter could be important. */
/******************************************************************************/
/*                                                                            */
/* Original credit for this idea goes to Michael Sansoterra, as published at: */
/* https://www.mcpressonline.com/programming/sql/...                          */
/* ...using-dynamic-sql-in-cl-part-2retrieving-a-data-value                   */
/* on November 9, 2003                                                        */
/*                                                                            */
/******************************************************************************/
/* Modification Log:                                                          */
/*                                                                            */
/* Mod#    Date       User       Description                                  */
/* ---- ---------- ---------- ----------------------------------------------- */
/* M000 03/08/2018 DLCLARK    Initial design.                                 */
/******************************************************************************/
 LOOKUPSQL:  CMD        PROMPT('SQL Lookup with Returned Value') +
                          TEXT('SQL Lookup for CL/ILE with Returned +
                          Value') ALLOW(*BMOD *IMOD) +
                          HLPID(LOOKUPSQL) HLPPNLGRP(*LIBL/LOOKUPSQL)

             PARM       KWD(RTNVAL) TYPE(*CHAR) LEN(510) +
                          RTNVAL(*YES) MIN(1) +
                          PROMPT('Return value       (Char 510)')
             PARM       KWD(COLUMN) TYPE(*CHAR) LEN(510) MIN(1) +
                          EXPR(*YES) VARY(*YES *INT2) CASE(*MIXED) +
                          INLPMTLEN(132) PROMPT('Retrieve column or +
                          expression')
             PARM       KWD(TABLE) TYPE(*CHAR) LEN(510) MIN(1) +
                          EXPR(*YES) VARY(*YES *INT2) CASE(*MIXED) +
                          INLPMTLEN(132) PROMPT('Lookup table or +
                          expression')
             PARM       KWD(WHERE) TYPE(*CHAR) LEN(510) DFT(*NONE) +
                          SPCVAL((*NONE ' ')) EXPR(*YES) VARY(*YES +
                          *INT2) CASE(*MIXED) INLPMTLEN(132) +
                          PROMPT('SQL WHERE clause')
             PARM       KWD(ORDER) TYPE(*CHAR) LEN(510) DFT(*NONE) +
                          SPCVAL((*NONE ' ')) EXPR(*YES) VARY(*YES +
                          *INT2) CASE(*MIXED) INLPMTLEN(132) +
                          PROMPT('SQL ORDER BY clause')
 