000100000000/******************************************************************************/
000200000000/* Program Name:      CRTJBCTLOP -- Create Job Control Options                */
000300000000/* Programmer:        Dave L Clark I                                          */
000400000000/* Date:              November 8, 2018                                        */
000500000000/* Project/Request #: IN-57 Create Commands to Maintain Job Control Options   */
000600000000/* Purpose:           This command allows Job Control Options (AC04) to be    */
000700000000/*                    created.  If the specified job name does not exist,     */
000800000000/*                    then it is added.  If it exists, then it is updated.    */
000900000000/******************************************************************************/
001000000000/* Technical Notes:                                                           */
001100000000/*                                                                            */
001200000000/* CRTCMD CMD(CRTJBCTLOP) PGM(AC04UPDR)                                       */
001300000000/*                                                                            */
001400000000/******************************************************************************/
001500000000/* Modification Log:                                                          */
001600000000/*                                                                            */
001700000000/* Mod#    Date       User       Description                                  */
001800000000/* ---- ---------- ---------- ----------------------------------------------- */
001900000000/* M000 11/08/2018 DLCLARK    Initial design.                                 */
002000000000/******************************************************************************/
002100000000 CRTJBCTLOP: CMD        PROMPT('Create Job Control Options') +
002200000000                          TEXT('Create Job Control Options') +
002300000000                          MAXPOS(1) HLPID(*CMD) HLPPNLGRP(CRTJBCTLOP)
002400000000
002500000000             PARM       KWD(JOB) TYPE(*NAME) LEN(6) MIN(1) +
002600000000                          PROMPT('Job name')
002700000000
002800000000             PARM       KWD(ACTION) TYPE(*NAME) LEN(10) +
002900000000                          CONSTANT(*CRT) SPCVAL((*CRT))
003000000000
003100000000             PARM       KWD(TITLE) TYPE(*CHAR) LEN(25) CASE(*MIXED) +
003200000000                          PROMPT('Job title')
003300000000
003400000000             PARM       KWD(DATE1) TYPE(*CHAR) LEN(50) CASE(*MIXED) +
003500000000                          PROMPT('Date parameter 1')
003600000000             PARM       KWD(DATE2) TYPE(*CHAR) LEN(50) CASE(*MIXED) +
003700000000                          PROMPT('Date parameter 2')
003800000000
003900000000             PARM       KWD(SELOPT) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
004000000000                          PROMPT('Selection option')
004100000000
004200000000             PARM       KWD(OPTION1) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
004300000000                          PROMPT('Processing option 1')
004400000000             PARM       KWD(OPTION2) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
004500000000                          PROMPT('Processing option 2')
004600000000             PARM       KWD(OPTION3) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
004700000000                          PROMPT('Processing option 3')
004800000000             PARM       KWD(OPTION4) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
004900000000                          PROMPT('Processing option 4')
005000000000             PARM       KWD(OPTION5) TYPE(*CHAR) LEN(98) CASE(*MIXED) +
005100000000                          PROMPT('Processing option 5')
005200000000
005300000000             PARM       KWD(LOCSEL) TYPE(*CHAR) LEN(18) CASE(*MIXED) +
005400000000                          PMTCTL(*PMTRQS) PROMPT('Location selection')
005500000000
