000100000000/******************************************************************************/
000200000000/* Program Name:      ADDJBCTLDF -- Add Job Control Defaults                  */
000300000000/* Programmer:        Dave L Clark I                                          */
000400000000/* Date:              November 8, 2018                                        */
000500000000/* Project/Request #: IN-58 Create Commands to Maintain Job Control Defaults  */
000600000000/* Purpose:           This command allows Job Control Defaults (AC29) to be   */
000700000000/*                    added.                                                  */
000800000000/******************************************************************************/
000900000000/* Technical Notes:                                                           */
001000000000/*                                                                            */
001100000000/* CRTCMD CMD(ADDJBCTLDF) PGM(AC29UPDR)                                       */
001200000000/*                                                                            */
001300000000/******************************************************************************/
001400000000/* Modification Log:                                                          */
001500000000/*                                                                            */
001600000000/* Mod#    Date       User       Description                                  */
001700000000/* ---- ---------- ---------- ----------------------------------------------- */
001800000000/* M000 11/08/2018 DLCLARK    Initial design.                                 */
001900000000/******************************************************************************/
002000000000 ADDJBCTLDF: CMD        PROMPT('Add Job Control Defaults') +
002100000000                          TEXT('Add Job Control Defaults') +
002200000000                          MAXPOS(1) PMTOVRPGM(AC29LKUR) +
002300000000                          HLPID(*CMD) HLPPNLGRP(ADDJBCTLDF)
002400000000
002500000000             PARM       KWD(JOB) TYPE(*NAME) LEN(6) MIN(1) +
002600000000                          KEYPARM(*YES) PROMPT('Job name')
002700000000 JOBNAME:    PMTCTL     CTL(JOB) COND((*NE ' '))
002800000000
002900000000             PARM       KWD(ACTION) TYPE(*NAME) LEN(10) +
003000000000                          CONSTANT(*ADD) SPCVAL((*ADD))
003100000000
003200000000             PARM       KWD(TITLE) TYPE(*CHAR) LEN(25) DFT(*NONE) +
003300000000                          SPCVAL((*NONE ' ')) CASE(*MIXED) +
003400000000                          PMTCTL(JOBNAME) PROMPT('Job title')
003500000000
003600000000             PARM       KWD(PROC) TYPE(*CHAR) LEN(7) +
003700000000                          PMTCTL(JOBNAME) PROMPT('Procedure id')
003800000000
003900000000             PARM       KWD(DATE1) TYPE(*DATE) PMTCTL(JOBNAME) +
004000000000                          PROMPT('Date parameter 1')
004100000000             PARM       KWD(DATE2) TYPE(*DATE) PMTCTL(JOBNAME) +
004200000000                          PROMPT('Date parameter 2')
004300000000
004400000000             PARM       KWD(SELOPT) TYPE(*CHAR) LEN(6) +
004500000000                          PMTCTL(JOBNAME) PROMPT('Selection option')
004600000000
004700000000             PARM       KWD(OPTION1) TYPE(*CHAR) LEN(1) +
004800000000                          PMTCTL(JOBNAME) PROMPT('Processing option 1')
004900000000             PARM       KWD(OPTION2) TYPE(*CHAR) LEN(1) +
005000000000                          PMTCTL(JOBNAME) PROMPT('Processing option 2')
005100000000             PARM       KWD(OPTION3) TYPE(*CHAR) LEN(1) +
005200000000                          PMTCTL(JOBNAME) PROMPT('Processing option 3')
005300000000             PARM       KWD(OPTION4) TYPE(*CHAR) LEN(1) +
005400000000                          PMTCTL(JOBNAME) PROMPT('Processing option 4')
005500000000             PARM       KWD(OPTION5) TYPE(*CHAR) LEN(1) +
005600000000                          PMTCTL(JOBNAME) PROMPT('Processing option 5')
005700000000
005800000000             PARM       KWD(LOCSEL) TYPE(*CHAR) LEN(3) +
005900000000                          PMTCTL(*PMTRQS) PROMPT('Location selection')
006000000000
006100000000             PARM       KWD(ISSUE) TYPE(*CHAR) LEN(10) +
006200000000                          PMTCTL(*PMTRQS) PROMPT('Issue to')
006300000000             PARM       KWD(USEOPT1) TYPE(*CHAR) LEN(1) +
006400000000                          PMTCTL(*PMTRQS) PROMPT('Use option 1')
006500000000             PARM       KWD(USEOPT2) TYPE(*CHAR) LEN(1) +
006600000000                          PMTCTL(*PMTRQS) PROMPT('Use option 2')
006700000000             PARM       KWD(USEOPT3) TYPE(*CHAR) LEN(1) +
006800000000                          PMTCTL(*PMTRQS) PROMPT('Use option 3')
006900000000             PARM       KWD(USEOPT4) TYPE(*CHAR) LEN(1) +
007000000000                          PMTCTL(*PMTRQS) PROMPT('Use option 4')
007100000000             PARM       KWD(USEOPTN) TYPE(*DEC) LEN(5 0) +
007200000000                          PMTCTL(*PMTRQS) PROMPT('Use number')
007300000000             PARM       KWD(USRPWD) TYPE(*CHAR) LEN(48) +
007400000000                          PMTCTL(*PMTRQS) PROMPT('User passwords')
007500000000
