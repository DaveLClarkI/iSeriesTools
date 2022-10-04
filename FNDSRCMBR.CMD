/******************************************************************************/
/* Program Name:      FNDSRCMBR -- Find Source Member                         */
/* Programmer:        Dave L Clark I                                          */
/* Date:              June 17, 2016                                           */
/* Project/Request #: JIRA IN-40 -- Create command to find source members     */
/* Purpose:           This command searches the specified libraries for a     */
/*                    matching source file and member name.  The resulting    */
/*                    list displays in a subfile for option processing.       */
/*----------------------------------------------------------------------------*/
/* Create as follows:                                                         */
/*                                                                            */
/*   CRTCMD CMD(*CURLIB/FNDSRCMBR) PGM(*LIBL/FNDSRCMBR)                       */
/*                                                                            */
/*----------------------------------------------------------------------------*/
/* Modification Log:                                                          */
/*                                                                            */
/* Mod#    Date       User       Description                                  */
/* ---- ---------- ---------- ----------------------------------------------- */
/* M000                                                                       */
/******************************************************************************/
 FNDSRCMBR:  CMD        PROMPT('Find Source Member') TEXT('Find +
                          Source Member') HLPID(*CMD) +
                          HLPPNLGRP(FNDSRCMBR)
             PARM       KWD(SRCMBR) TYPE(*GENERIC) LEN(10) MIN(1) +
                          SPCVAL(('*')) PROMPT('Source member')
             PARM       KWD(SRCFILE) TYPE(SRCF) PROMPT('Source file')
 SRCF:       QUAL       TYPE(*NAME) LEN(10) DFT(QRPGLESRC)
             QUAL       TYPE(*NAME) LEN(10) DFT(*CURLIB) +
                          SPCVAL((*ALL) (*ALLUSR) (*USRLIBL) +
                          (*CURLIB)) PROMPT('Library')
 