000100000000/******************************************************************************/
000200000000/* Program Name:      CPYJBCTLDF -- Copy Job Control Defaults                 */
000300000000/* Programmer:        Dave L Clark I                                          */
000400000000/* Date:              November 8, 2018                                        */
000500000000/* Project/Request #: IN-58 Create Commands to Maintain Job Control Defaults  */
000600000000/* Purpose:           This command allows Job Control Defaults (AC29) to be   */
000700000000/*                    copied.                                                 */
000800000000/******************************************************************************/
000900000000/* Technical Notes:                                                           */
001000000000/*                                                                            */
001100000000/* CRTCMD CMD(CPYJBCTLDF) PGM(AC29UPDR)                                       */
001200000000/*                                                                            */
001300000000/******************************************************************************/
001400000000/* Modification Log:                                                          */
001500000000/*                                                                            */
001600000000/* Mod#    Date       User       Description                                  */
001700000000/* ---- ---------- ---------- ----------------------------------------------- */
001800000000/* M000 11/08/2018 DLCLARK    Initial design.                                 */
001900000000/******************************************************************************/
002000000000 CPYJBCTLDF: CMD        PROMPT('Copy Job Control Defaults') +
002100000000                          TEXT('Copy Job Control Defaults') +
002200000000                          MAXPOS(1) PMTOVRPGM(AC29LKUR) +
002300000000                          HLPID(*CMD) HLPPNLGRP(CPYJBCTLDF)
002400000000
002500000000             PARM       KWD(JOB) TYPE(*NAME) LEN(6) MIN(1) +
002600000000                          KEYPARM(*YES) PROMPT('Job name')
002700000000 JOBNAME:    PMTCTL     CTL(JOB) COND((*NE ' '))
002800000000
002900000000             PARM       KWD(ACTION) TYPE(*NAME) LEN(10) +
003000000000                          CONSTANT(*CPY) SPCVAL((*CPY))
003100000000
003200000000             PARM       KWD(TOJOB) TYPE(*NAME) LEN(6) +
003300000000                          PMTCTL(JOBNAME) PROMPT('To job name')
003400000000             PARM       KWD(TITLE) TYPE(*CHAR) LEN(25) DFT(*NONE) +
003500000000                          SPCVAL((*NONE ' ')) CASE(*MIXED) +
003600000000                          PMTCTL(JOBNAME) PROMPT('New job title')
003700000000
