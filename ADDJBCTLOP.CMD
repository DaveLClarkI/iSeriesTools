000100000000/******************************************************************************/
000200000000/* Program Name:      ADDJBCTLOP -- Add Job Control Options                   */
000300000000/* Programmer:        Dave L Clark I                                          */
000400000000/* Date:              November 8, 2018                                        */
000500000000/* Project/Request #: IN-57 Create Commands to Maintain Job Control Options   */
000600000000/* Purpose:           This command allows Job Control Options (AC04) to be    */
000700000000/*                    added.                                                  */
000800000000/******************************************************************************/
000900000000/* Technical Notes:                                                           */
001000000000/*                                                                            */
001100000000/* CRTCMD CMD(ADDJBCTLOP) PGM(AC04UPDR)                                       */
001200000000/*                                                                            */
001300000000/******************************************************************************/
001400000000/* Modification Log:                                                          */
001500000000/*                                                                            */
001600000000/* Mod#    Date       User       Description                                  */
001700000000/* ---- ---------- ---------- ----------------------------------------------- */
001800000000/* M000 11/08/2018 DLCLARK    Initial design.                                 */
001900000000/******************************************************************************/
002000000000 ADDJBCTLOP: CMD        PROMPT('Add Job Control Options') +
002100000000                          TEXT('Add Job Control Options') +
002200000000                          MAXPOS(1) PMTOVRPGM(AC04LKUR) +
002300000000                          HLPID(*CMD) HLPPNLGRP(ADDJBCTLOP)
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
003600000000             PARM       KWD(DATE1) TYPE(*CHAR) LEN(50) CASE(*MIXED) +
003700000000                          PMTCTL(JOBNAME) PROMPT('Date parameter 1')
003800000000             PARM       KWD(DATE2) TYPE(*CHAR) LEN(50) CASE(*MIXED) +
003900000000                          PMTCTL(JOBNAME) PROMPT('Date parameter 2')
004000000000
004100000000             PARM       KWD(SELOPT) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
004200000000                          PMTCTL(JOBNAME) PROMPT('Selection option')
004300000000
004400000000             PARM       KWD(OPTION1) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
004500000000                          PMTCTL(JOBNAME) PROMPT('Processing option 1')
004600000000             PARM       KWD(OPTION2) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
004700000000                          PMTCTL(JOBNAME) PROMPT('Processing option 2')
004800000000             PARM       KWD(OPTION3) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
004900000000                          PMTCTL(JOBNAME) PROMPT('Processing option 3')
005000000000             PARM       KWD(OPTION4) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
005100000000                          PMTCTL(JOBNAME) PROMPT('Processing option 4')
005200000000             PARM       KWD(OPTION5) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
005300000000                          PMTCTL(JOBNAME) PROMPT('Processing option 5')
005400000000
005500000000             PARM       KWD(LOCSEL) TYPE(*CHAR) LEN(18) CASE(*MIXED) +
005600000000                          PMTCTL(*PMTRQS) PROMPT('Location selection')
005700000000
