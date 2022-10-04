/******************************************************************************/
/* Program Name:      UTRTVSPLFA -- Retrieve Spool File Attributes            */
/* Programmer:        Dave L Clark I                                          */
/* Date:              September 29, 2016                                      */
/* Project/Request #: JIRA IN-44 Retrieve Spool File Attributes               */
/* Purpose:           This command retrieves the spool file attributes for    */
/*                    a selected spool file entry.                            */
/******************************************************************************/
/* Technical Notes:                                                           */
/*                                                                            */
/* The Retrieve Spool File Attributes (UTRTVSPLFA) command opens a list of    */
/* selected spooled file entries and returns their attributes as directed.    */
/* The first invocation returns the attributes for the first entry selected.  */
/* Additional invocations are required if atttributes for any additional      */
/* entries are also required.                                                 */
/*                                                                            */
/* When there are no more entries to retrieve, the internal list is closed    */
/* automatically and an exception is raised.  If all entries are not to be    */
/* retrieved then an additional invocation is required in order to force the  */
/* internal list closed.  See the command help for more information.          */
/*                                                                            */
/* But, in short, the first parameter can be *NEXT or *CLOSE to control the   */
/* selection list of matched spooled file entries.  The other selection       */
/* parameters are not required for *NEXT and no other parms for *CLOSE.       */
/*                                                                            */
/* Finally, when compiling this command (since the command processing         */
/* program name doesn't match the CMD name) be sure to specify the            */
/* following TURNOVER create command override:                                */
/*                                                                            */
/*   PGM(UTRTSFAR)                                                            */
/*                                                                            */
/* Or, specify the following TURNOVER post-run command:                       */
/*                                                                            */
/*   CHGCMD CMD(UTRTVSPLFA) PGM(*LIBL/UTRTSFAR)                               */
/*                                                                            */
/******************************************************************************/
/* Modification Log:                                                          */
/*                                                                            */
/* Mod#    Date       User       Description                                  */
/* ---- ---------- ---------- ----------------------------------------------- */
/* M001                                                                       */
/******************************************************************************/
             CMD        PROMPT('Retrieve Spool File Attributes') +
                          TEXT('Retrieve Spool File Attributes') +
                          ALLOW(*BPGM *IPGM *BREXX *IREXX *BMOD +
                          *IMOD) HLPID(*CMD) HLPPNLGRP(UTRTVSPLFA)
/* --------- selection parameters ------------------------------------------- */
             PARM       KWD(FILE) TYPE(*GENERIC) LEN(10) +
                          SPCVAL((*SELECT) (*NEXT) (*CLOSE)) MIN(1) +
                          PROMPT('Spooled file')
             PARM       KWD(JOB) TYPE(QUALJOB) DFT(*ANY) SNGVAL((*) +
                          (*ANY)) PROMPT('Job name')
 QUALJOB:    QUAL       TYPE(*NAME) LEN(10)
             QUAL       TYPE(*NAME) LEN(10) PROMPT('User')
             QUAL       TYPE(*CHAR) LEN(6) RANGE(000000 999999) +
                          FULL(*YES) PROMPT('Number')
             PARM       KWD(SPLNBR) TYPE(*CHAR) LEN(6) DFT(*ANY) +
                          RANGE(1 999999) SPCVAL((*ONLY) (*LAST) +
                          (*ANY)) PROMPT('Spooled file number')
             PARM       KWD(SELECT) TYPE(SELECT) PROMPT('Select +
                          spooled files by')
 SELECT:     ELEM       TYPE(*NAME) LEN(10) DFT(*CURRENT) +
                          SPCVAL((*CURRENT) (*ALL)) PROMPT('User')
             ELEM       TYPE(*NAME) LEN(10) DFT(*ALL) SPCVAL((*ALL) +
                          (*OUTQ)) PROMPT('Print device')
             ELEM       TYPE(*CHAR) LEN(10) DFT(*ALL) SPCVAL((*ALL) +
                          (*STD)) CHOICE('Form type, *ALL, *STD') +
                          PROMPT('Form type')
             ELEM       TYPE(*CHAR) LEN(10) DFT(*ALL) SPCVAL((*ALL)) +
                          CHOICE('User data, generic*, *ALL') +
                          PROMPT('User data')
             ELEM       TYPE(*CHAR) LEN(7) DFT(*ALL) RANGE(1 32) +
                          SPCVAL((*ALL) (*ASPDEV)) PROMPT('ASP')
             PARM       KWD(ASPDEV) TYPE(*NAME) DFT(*) SPCVAL((*) +
                          (*SYSBAS) (*CURASPGRP)) PROMPT('ASP +
                          device')
 FILECTL:    PMTCTL     CTL(FILE) COND((*SPCFD))
/* --------- return parameter set 1 ----------------------------------------- */
             PARM       KWD(FILENAME) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Spooled file name         (10)')
             PARM       KWD(FILENBR)  TYPE(*DEC) LEN(6 0) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Spooled file number      (6,0)')
             PARM       KWD(JOBNAME)  TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Job name                  (10)')
             PARM       KWD(JOBUSER)  TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Job user                  (10)')
             PARM       KWD(JOBNBR)   TYPE(*CHAR) LEN(6)  +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Job number                 (6)')
             PARM       KWD(OUTQUENM) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Output queue name         (10)')
             PARM       KWD(OUTQUELB) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Output queue library      (10)')
             PARM       KWD(DEVICE)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Device                    (10)')
             PARM       KWD(DEVTYPE)  TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Device type               (10)')
             PARM       KWD(FORMTYPE) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Form type                 (10)')
             PARM       KWD(USERDATA) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('User data                 (10)')
             PARM       KWD(STATUS)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Status                    (10)')
             PARM       KWD(PRIORITY) TYPE(*CHAR) LEN(2)  +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Priority                   (2)')
             PARM       KWD(CREATED)  TYPE(*CHAR) LEN(8)  +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Created date (YYYYMMDD)    (8)')
             PARM       KWD(CREATET)  TYPE(*CHAR) LEN(6)  +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Created time (HHMMSS)      (6)')
             PARM       KWD(TOTPGS)   TYPE(*DEC) LEN(9 0) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Total pages              (9,0)')
             PARM       KWD(CURPGE)   TYPE(*DEC) LEN(9 0) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Current page             (9,0)')
             PARM       KWD(REMCPY)   TYPE(*DEC) LEN(3 0) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Remaining copies         (3,0)')
             PARM       KWD(ASPNBR)   TYPE(*DEC) LEN(3 0) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('ASP number               (3,0)')
             PARM       KWD(ASPDVN)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('ASP device name           (10)')
             PARM       KWD(JOBSYSN)  TYPE(*CHAR) LEN(8) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Job system name            (8)')
             PARM       KWD(FILESZ)  TYPE(*DEC) LEN(15 2) +
                          RTNVAL(*YES) PMTCTL(FILECTL) +
                          PROMPT('Spool file size (K)     (15,2)')
/* --------- return parameter set 2 ----------------------------------------- */
             PARM       KWD(AVAILABLE) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('File available            (10)')
             PARM       KWD(HOLD)     TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Hold spooled file         (10)')
             PARM       KWD(SAVE)     TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Save spooled file         (10)')
             PARM       KWD(RPLUNPRT) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Replace unprintable char   (1)')
             PARM       KWD(RPLCHAR)  TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Replacement character      (1)')
             PARM       KWD(DEVLIB)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Device library            (10)')
             PARM       KWD(PGMNAME)  TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Program created by        (10)')
             PARM       KWD(PGMLIB)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Program library           (10)')
             PARM       KWD(FORMDEF)  TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Form definition           (10)')
             PARM       KWD(FORMDEFL) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Form definition library   (10)')
             PARM       KWD(PAGEDEF)  TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Page definition           (10)')
             PARM       KWD(PAGEDEFL) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Page definition library   (10)')
             PARM       KWD(ACGCDE)   TYPE(*CHAR) LEN(15) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Accounting code           (15)')
             PARM       KWD(PRTTXT)   TYPE(*CHAR) LEN(30) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Print text                (30)')
             PARM       KWD(MAXRECS)  TYPE(*DEC) LEN(9 0) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Maximum records          (9,0)')
             PARM       KWD(RECLEN)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Record length             (10)')
             PARM       KWD(LPI)      TYPE(*DEC) LEN(5 1) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Lines per inch           (5,1)')
             PARM       KWD(CPI)      TYPE(*DEC) LEN(5 1) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Characters per inch      (5,1)')
             PARM       KWD(PAGELN)   TYPE(*DEC) LEN(3 0) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Page length              (3,0)')
             PARM       KWD(PAGEWD)   TYPE(*DEC) LEN(3 0) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Page width               (3,0)')
             PARM       KWD(PAGEMM)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Measurement method        (10)')
             PARM       KWD(UOM)      TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Unit of measure           (10)')
             PARM       KWD(OVRFLW)   TYPE(*DEC) LEN(3 0) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Overflow line            (3,0)')
             PARM       KWD(FILESEP)  TYPE(*DEC) LEN(3 0) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Number of separators     (3,0)')
             PARM       KWD(DRAWER)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Source drawer             (10)')
             PARM       KWD(PAGRTT)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Page rotation             (10)')
             PARM       KWD(JUSTIFY)  TYPE(*DEC) LEN(3 0) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Hardware justification   (3,0)')
             PARM       KWD(FONTIDNT) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Font identifier           (10)')
             PARM       KWD(FONTSIZE) TYPE(*DEC) LEN(5 2) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Point size               (5,2)')
             PARM       KWD(CHARIDNT) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Character identifier      (10)')
             PARM       KWD(CODEPAGE) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Code page                 (10)')
             PARM       KWD(DUPLEX)   TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Print on both sides       (10)')
             PARM       KWD(FOLD)     TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Fold records              (10)')
             PARM       KWD(CTLCHAR)  TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Control character         (10)')
             PARM       KWD(ALIGN)    TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Align page                (10)')
             PARM       KWD(FIDELITY) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Fidelity                  (10)')
             PARM       KWD(PRTQLTY)  TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Print quality             (10)')
             PARM       KWD(FORMFEED) TYPE(*CHAR) LEN(10) +
                          RTNVAL(*YES) PMTCTL(*PMTRQS) +
                          PROMPT('Form feed                 (10)')
 