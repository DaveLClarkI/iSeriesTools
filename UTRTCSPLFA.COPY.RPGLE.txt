     *========================================================================*
      * Program:           UTRTVSPLFA -- Retrieve Spool File Attributes
      * Programmer:        Dave L Clark I
      * Date:              September 30, 2016
      * Project/Request #: JIRA IN-44 Retrieve Spool File Attributes
      * Purpose:           The UTRTVSPLFA command retrieves spool file attributes
      *                    for one or more selected spool file entries.
      *------------------------------------------------------------------------+
      *         Special Programming Logic / Considerations
      *
      * NONE
      *
      *------------------------------------------------------------------------+
      *         Modification Log
      *
      * Mod#    Date    Pgmr Id    Description
      * ---- ---------- ---------- --------------------------------------------+
      * M000
     *========================================================================*

      /include *libl/qrpglesrc,utcmvarr          // common template variables

       dcl-s char1_t         char(1)   template;
       dcl-s char2_t         char(2)   template;
       dcl-s char6_t         char(6)   template;
       dcl-s char7_t         char(7)   template;
       dcl-s char12_t        char(12)  template;
       dcl-s char15_t        char(15)  template;
       dcl-s char30_t        char(30)  template;

       dcl-ds RTSFA_QualJob  qualified template;
         Name                like(char10_t);
         User                like(char10_t);
         Nmbr                like(char6_t);
       end-ds;

       dcl-ds RTSFA_Select   qualified template;
         Count               uns(5)    inz;
         User                like(char10_t);
         PDev                like(char10_t);
         Form                like(char10_t);
         Data                like(char10_t);
         ASP                 like(char7_t);
       end-ds;

      **************************************************************************
      * The Retrieve Spool File Attributes (UTRTVSPLFA) command opens a list   *
      * of selected spooled file entries and returns their attributes as       *
      * directed.  The first invocation returns the attributes for the first   *
      * entry selected.  Additional invocations are required if atttributes    *
      * for any additional entries are also required.                          *
      *                                                                        *
      * When there are no more entries to retrieve, the internal list is closed*
      * automatically and an exception is raised.  If all entries are not to be*
      * retrieved then an additional invocation is required in order to force  *
      * the internal list closed.  See the command help for more information.  *
      *                                                                        *
      * But, in short, the first parameter can be *NEXT or *CLOSE to control   *
      * the selection list of matched spooled file entries.  Other selection   *
      * parameters are not required for *NEXT and no other parms for *CLOSE.   *
      **************************************************************************
       dcl-pr RetrieveSpoolFileAttributes   extpgm('UTRTSFAR');
       // selection set
         pFile               like(char10_t) const;
         pJob                likeds(RTSFA_QualJob) const options(*nopass:*omit);
         pSplNbr             like(char6_t)  const options(*nopass:*omit);
         pSelect             likeds(RTSFA_Select) options(*nopass:*omit);
         pAspDev             like(char10_t) const options(*nopass:*omit);
       // return set 1 -- best performance
         pFileName           like(char10_t) options(*nopass:*omit);
         pFileNbr            packed(6:0)    options(*nopass:*omit);
         pJobName            like(char10_t) options(*nopass:*omit);
         pJobUser            like(char10_t) options(*nopass:*omit);
         pJobNbr             like(char6_t)  options(*nopass:*omit);
         pOutQueNm           like(char10_t) options(*nopass:*omit);
         pOutQueLb           like(char10_t) options(*nopass:*omit);
         pDevice             like(char10_t) options(*nopass:*omit);
         pDevType            like(char10_t) options(*nopass:*omit);
         pFormType           like(char10_t) options(*nopass:*omit);
         pUserData           like(char10_t) options(*nopass:*omit);
         pStatus             like(char10_t) options(*nopass:*omit);
         pPriority           like(char2_t)  options(*nopass:*omit);
         pCreDate            like(char8_t)  options(*nopass:*omit);
         pCreTime            like(char6_t)  options(*nopass:*omit);
         pTotPgs             packed(9:0)    options(*nopass:*omit);
         pCurPge             packed(9:0)    options(*nopass:*omit);
         pRemCpy             packed(3:0)    options(*nopass:*omit);
         pAspNbr             packed(3:0)    options(*nopass:*omit);
         pAspDvN             like(char10_t) options(*nopass:*omit);
         pJobSysN            like(char8_t)  options(*nopass:*omit);
         pFileSz             packed(15:2)   options(*nopass:*omit);
       // return set 2 -- additional time required
         pFAvailbl           like(char10_t) options(*nopass:*omit);
         pHoldFile           like(char10_t) options(*nopass:*omit);
         pSaveFile           like(char10_t) options(*nopass:*omit);
         pRepUnprt           like(char1_t)  options(*nopass:*omit);
         pReplChar           like(char1_t)  options(*nopass:*omit);
         pDeviceLb           like(char10_t) options(*nopass:*omit);
         pProgName           like(char10_t) options(*nopass:*omit);
         pProgLibr           like(char10_t) options(*nopass:*omit);
         pFormDefN           like(char10_t) options(*nopass:*omit);
         pFormDefL           like(char10_t) options(*nopass:*omit);
         pPageDefN           like(char10_t) options(*nopass:*omit);
         pPageDefL           like(char10_t) options(*nopass:*omit);
         pAcctCode           like(char15_t) options(*nopass:*omit);
         pPrintTxt           like(char30_t) options(*nopass:*omit);
         pMaxRecs            packed(9:0)    options(*nopass:*omit);
         pRecLen             like(char10_t) options(*nopass:*omit);
         pLinesPI            packed(5:1)    options(*nopass:*omit);
         pCharsPI            packed(5:1)    options(*nopass:*omit);
         pPageLeng           packed(3:0)    options(*nopass:*omit);
         pPageWdth           packed(3:0)    options(*nopass:*omit);
         pPageMsrM           like(char10_t) options(*nopass:*omit);
         pUnitMsr            like(char10_t) options(*nopass:*omit);
         pOvflLine           packed(3:0)    options(*nopass:*omit);
         pNbrSeprt           packed(3:0)    options(*nopass:*omit);
         pSrcDrawr           like(char10_t) options(*nopass:*omit);
         pPageRot            like(char10_t) options(*nopass:*omit);
         pPageJust           packed(3:0)    options(*nopass:*omit);
         pFontIdnt           like(char10_t) options(*nopass:*omit);
         pFontSize           packed(5:2)    options(*nopass:*omit);
         pCharIdnt           like(char10_t) options(*nopass:*omit);
         pCodePage           like(char10_t) options(*nopass:*omit);
         pPrntDplx           like(char10_t) options(*nopass:*omit);
         pFoldRecs           like(char10_t) options(*nopass:*omit);
         pCtrlChar           like(char10_t) options(*nopass:*omit);
         pAlgnForm           like(char10_t) options(*nopass:*omit);
         pPrintFid           like(char10_t) options(*nopass:*omit);
         pPrntQual           like(char10_t) options(*nopass:*omit);
         pFormFeed           like(char10_t) options(*nopass);
       end-pr;
 