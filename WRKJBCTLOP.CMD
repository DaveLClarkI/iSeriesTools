000100000000/******************************************************************************/
000200000000/* Program Name:      WRKJBCTLOP -- Work with Job Control Options             */
000300000000/* Programmer:        Dave L Clark I                                          */
000400000000/* Date:              November 8, 2018                                        */
000500000000/* Project/Request #: IN-57 Create Commands to Maintain Job Control Options   */
000600000000/* Purpose:           This command allows Job Control Options (REV460/AC04)   */
000700000000/*                    to be managed from a UIM List Panel.                    */
000800000000/******************************************************************************/
000900000000/* Technical Notes:                                                           */
001000000000/*                                                                            */
001100000000/* CRTCMD CMD(WRKJBCTLOP) PGM(AC04WRKR)                                       */
001200000000/*                                                                            */
001300000000/******************************************************************************/
001400000000/* Modification Log:                                                          */
001500000000/*                                                                            */
001600000000/* Mod#    Date       User       Description                                  */
001700000000/* ---- ---------- ---------- ----------------------------------------------- */
001800000000/* M000 11/08/2018 DLCLARK    Initial design.                                 */
001900000000/******************************************************************************/
002000000000 WRKJBCTLOP: CMD        PROMPT('Work with Job Control Options') +
002100000000                          TEXT('Work with Job Control Options') +
002200000000                          HLPID(*CMD) HLPPNLGRP(WRKJBCTLOP)
002300000000
002400000000             PARM       KWD(JOBID) TYPE(*NAME) LEN(6) +
002500000000                          PROMPT('Position to job')
002600000000
