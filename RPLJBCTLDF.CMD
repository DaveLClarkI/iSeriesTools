000100000000/******************************************************************************/
000200000000/* Program Name:      RPLJBCTLDF -- Replicate Job Control Defaults            */
000300000000/* Programmer:        Dave L Clark I                                          */
000400000000/* Date:              November 8, 2018                                        */
000500000000/* Project/Request #: IN-58 Create Commands to Maintain Job Control Defaults  */
000600000000/* Purpose:           This command allows Job Control Defaults (AC29) to be   */
000700000000/*                    replicated across companies.                            */
000800000000/******************************************************************************/
000900000000/* Technical Notes:                                                           */
001000000000/*                                                                            */
001100000000/* CRTCMD CMD(RPLJBCTLDF) PGM(AC29RPLR)                                       */
001200000000/*                                                                            */
001300000000/******************************************************************************/
001400000000/* Modification Log:                                                          */
001500000000/*                                                                            */
001600000000/* Mod#    Date       User       Description                                  */
001700000000/* ---- ---------- ---------- ----------------------------------------------- */
001800000000/* M000 11/08/2018 DLCLARK    Initial design.                                 */
001900000000/******************************************************************************/
002000000000 RPLJBCTLDF: CMD        PROMPT('Replicate Job Control Defaults') +
002100000000                          MSGF(SHR460/WSMSGF) TEXT('Replicate Job +
002200000000                          Control Defaults') MAXPOS(1) +
002300000000                          PMTOVRPGM(AC29LKUR) HLPID(*CMD) +
002400000000                          HLPPNLGRP(RPLJBCTLDF)
002500000000
002600000000             PARM       KWD(JOB) TYPE(*NAME) LEN(6) MIN(1) +
002700000000                          KEYPARM(*YES) PROMPT('Job name')
002800000000 JOBNAME:    PMTCTL     CTL(JOB) COND((*NE ' '))
002900000000
003000000000             PARM       KWD(ACTION) TYPE(*NAME) LEN(10) +
003100000000                          CONSTANT(*RPL) SPCVAL((*RPL))
003200000000
003300000000             PARM       KWD(TITLE) TYPE(*CHAR) LEN(25) CASE(*MIXED) +
003400000000                          PMTCTL(JOBNAME) PROMPT('Job title')
003500000000
003600000000             PARM       KWD(COMPANY) TYPE(CORANGE) PMTCTL(JOBNAME) +
003700000000                          PROMPT('Company number range')
003800000000 CORANGE:    ELEM       TYPE(*CHAR) LEN(5) RANGE('00001' '99999') +
003900000000                          SPCVAL((*ALL) (*LIBL)) ALWUNPRT(*NO) FULL(*YES) +
004000000000                          PROMPT('From (or only)')
004100000000             ELEM       TYPE(*CHAR) LEN(5) RANGE('00001' '99999') +
004200000000                          ALWUNPRT(*NO) FULL(*YES) PROMPT('Thru +
004300000000                          (optional)')
004400000000
004500000000             PARM       KWD(COLIST) TYPE(*CHAR) LEN(5) RANGE('00001' +
004600000000                          '99999') MAX(99) ALWUNPRT(*NO) FULL(*YES) +
004700000000                          PMTCTL(JOBNAME) PROMPT('or Company number +
004800000000                          list')
004900000000             DEP        CTL(*ALWAYS) PARM((&JOB *GT ' ') (COMPANY) +
005000000000                          (COLIST)) NBRTRUE(*LT 3) MSGID(IMX0010)
005100000000
005200000000             PARM       KWD(FILTER) TYPE(FILTER) PMTCTL(JOBNAME) +
005300000000                          PROMPT('Company selection filters')
005400000000 FILTER:     ELEM       TYPE(*NAME) LEN(15) RSTD(*YES) DFT(*ALL) +
005500000000                          SPCVAL((*ACTIVE) (*APPROVED) (*CLOSED) +
005600000000                          (*CONSOLIDATED) (*DISSOLVED) (*EXTERNAL) +
005700000000                          (*INACTIVE) (*MERGED) (*PROSPECTIVE) (*TOTALED)) +
005800000000                          SNGVAL((*ALL)) MAX(5) PROMPT('Company status')
005900000000             ELEM       TYPE(*NAME) LEN(4) RSTD(*YES) DFT(*ALL) +
006000000000                          SPCVAL((*CAM) (*CAR) (*COO) (*NOL) (*SEC) (*WIN) +
006100000000                          (*WYT)) SNGVAL((*ALL)) MAX(5) PROMPT('Entity +
006200000000                          type')
006300000000             ELEM       TYPE(*CHAR) LEN(4) RANGE('00' '99') ALWUNPRT(*NO) +
006400000000                          DFT(*ALL) SNGVAL((*ALL)) MAX(5) PROMPT('Service +
006500000000                          region')
006600000000             ELEM       TYPE(*NAME) LEN(15) RSTD(*YES) DFT(*ALL) +
006700000000                          SPCVAL((*AREA) (*COMPLEX) (*CONSULTING) +
006800000000                          (*INVESTMENT) (*LOCALOPER) (*SERVICE) +
006900000000                          (*SOURCING) (*OTHER)) SNGVAL((*ALL)) MAX(5) +
007000000000                          PROMPT('Organization type')
007100000000
