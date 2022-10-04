     *========================================================================*
      * Program:           UTRTSFAR -- Retrieve Spool File Attributes
      * Programmer:        Dave L Clark I
      * Date:              September 30, 2016
      * Project/Request #: JIRA IN-44 Retrieve Spool File Attributes
      * Purpose:           The UTRTVSPLFA command retrieves spool file attributes
      *                    for one or more selected spool file entries.
      *------------------------------------------------------------------------+
      *         Special Programming Logic / Considerations
      *
      * The Retrieve Spool File Attributes (UTRTVSPLFA) command opens a list
      * of selected spooled file entries and returns their attributes as
      * directed.  The first invocation returns the attributes for the first
      * entry selected.  Additional invocations are required if atttributes
      * for any additional entries are also required.
      *
      * When there are no more entries to retrieve, the internal list is closed
      * automatically and an exception is raised.  If all entries are not to be
      * retrieved then an additional invocation is required in order to force
      * the internal list closed.  See the command help for more information.
      *
      * But, in short, the first parameter can be *NEXT or *CLOSE to control
      * the selection list of matched spooled file entries.  The other selection
      * parameters are not required for *NEXT and no other parms for *CLOSE.
      *
      *------------------------------------------------------------------------+
      *         Modification Log
      *
      * Mod#    Date    Pgmr Id    Description
      * ---- ---------- ---------- --------------------------------------------+
M001  * M001 03/17/2020 DLCLARK    Increase User Space size.
M001  *      (OPBE-1263) CPA0702 CPF34C4 received by procedure AR21CL. (C D I R)
     *========================================================================*

       ctl-opt Main(UTRTSFAR) AlwNull(*USRCTL) DatFmt(*ISO) TimFmt(*ISO)
               BndDir('WSBNDDIR') Dftactgrp(*no) Actgrp(*caller)
               Debug Option(*SRCSTMT:*NODEBUGIO);

       // general copybooks
      /include *libl/qrpglesrc,utrtvsplfa        // shared variable definitions
      /include *libl/qrpglesrc,prstdedits        // cross-application service program
M001  /include *libl/qrpglesrc,utquslspl         // list spooled files api
M001  /include *libl/qrpglesrc,utqusrspla        // retrieve spl file attrs api
M001  /include *libl/qrpglesrc,utqusxxxus        // user space apis

M001  *========================================================================*
M001  * IBM API to Test a Parameter for a Valid Address
M001  *
M001  * DOCUMENTATION:
M001  * https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_71/apis/CEETSTA.htm
M001  *========================================================================*
M001   dcl-pr CEETSTA;
M001     pValParmAdr         int(10);
M001     pParmPosNbr         int(10)   const;
M001     pFeedback           char(12)  options(*nopass);
M001   end-pr;

       // program variables
       dcl-c CompareList     '201,202,203,204,205,206,207,208,209,214,224,226';
       dcl-s Caller          like(PROC_PGM);

       dcl-s ListIsOpen      like(boolean_t) inz;
       dcl-s RTSFA_Space     like(char20_t)  inz;
       dcl-s RTSFA_SpcPtr    like(pointer_t) inz;

       dcl-s RTSFA_Entry     packed(9:0)     inz;
       dcl-s RTSFA_Data      like(char30_t)  inz;
       dcl-s RTSFA_Int4      like(integer_t) inz;
       dcl-s RTSFA_PDec      packed(15:5)    inz;

       dcl-s ParmNumb        like(integer_t) inz;
       dcl-s ValidParm       like(integer_t) inz;
       dcl-s iFeedback       like(char12_t)  inz;

       dcl-s RTSFA_CCnt      packed(3:0)     inz;
       dcl-s RTSFA_Codes     zoned(3:0)      dim(25) ctdata perrcd(1);
       dcl-s RTSFA_FCnt      packed(3:0)     inz;
       dcl-s RTSFA_KCnt      like(integer_t) inz;
       dcl-s RTSFA_Keys      like(integer_t) dim(30) inz;

       dcl-s RTSFA_IntJob    char(16);
       dcl-s RTSFA_IntSpl    char(16);

       dcl-ds Selection      qualified;
         File                like(char10_t)  inz;
         Job                 likeds(RTSFA_QualJob) inz;
         SplNbr              like(char6_t)   inz;
         Selctn              likeds(RTSFA_Select) inz;
         AspDev              like(char10_t)  inz;
       end-ds;

      * data structures to map the spooled file list user space
       dcl-s  RTSFA_Gen_Ptr  like(pointer_t);
       dcl-ds RTSFA_Gen_DS   likeds(QUSH0100) based(RTSFA_Gen_Ptr); // generic header
       dcl-s  RTSFA_Inp_Ptr  like(pointer_t);
       dcl-ds RTSFA_Inp_DS   likeds(QUSPLFI2) based(RTSFA_Inp_Ptr); // input parms
       dcl-s  RTSFA_Hdr_Ptr  like(pointer_t);
       dcl-ds RTSFA_Hdr_DS   likeds(QUSSPLFH) based(RTSFA_Hdr_Ptr); // api header
       dcl-s  RTSFA_Lst_Ptr  like(pointer_t);
       dcl-ds RTSFA_Lst_DS   likeds(QUSF0200) based(RTSFA_Lst_Ptr); // list section
       dcl-s  RTSFA_Fld_Ptr  like(pointer_t);
       dcl-ds RTSFA_Fld_DS   likeds(QUSSPLKI) based(RTSFA_Fld_Ptr); // field section
       dcl-s  RTSFA_Dta_Ptr  like(pointer_t);
       dcl-ds RTSFA_Dta_DS   qualified        based(RTSFA_Dta_Ptr); // data section
         Int4                like(integer_t);
         PDec                packed(15:5)     pos(1);
         Str                 like(char30_t)   pos(1);
       end-ds;

      * global structure for return parameters
       dcl-ds RTSFA_Return_Values inz;
         gFileName           like(char10_t);
         gFileNbr            packed(6:0);
         gJobName            like(char10_t);
         gJobUser            like(char10_t);
         gJobNbr             like(char6_t);
         gOutQueNm           like(char10_t);
         gOutQueLb           like(char10_t);
         gDevice             like(char10_t);
         gDevType            like(char10_t);
         gFormType           like(char10_t);
         gUserData           like(char10_t);
         gStatus             like(char10_t);
         gPriority           like(char2_t);
         gCreDate            like(char8_t);
         gCreTime            like(char6_t);
         gTotPgs             packed(9:0);
         gCurPge             packed(9:0);
         gRemCpy             packed(3:0);
         gAspNbr             packed(3:0);
         gAspDvN             like(char10_t);
         gJobSysN            like(char8_t);
         gFileSz             packed(15:2);
       end-ds;

     *========================================================================*
     *                M a i n l i n e   P r o c e d u r e                     *
     *========================================================================*
       dcl-proc UTRTSFAR;
         dcl-pi *n           extpgm;
         // selection set
           pFile             like(char10_t) const;
           pJob              likeds(RTSFA_QualJob) const options(*nopass:*omit);
           pSplNbr           like(char6_t)  const options(*nopass:*omit);
           pSelect           likeds(RTSFA_Select) options(*nopass:*omit);
           pAspDev           like(char10_t) const options(*nopass:*omit);
         // return set 1 -- best performance
           pFileName         like(char10_t) options(*nopass:*omit);
           pFileNbr          packed(6:0)    options(*nopass:*omit);
           pJobName          like(char10_t) options(*nopass:*omit);
           pJobUser          like(char10_t) options(*nopass:*omit);
           pJobNbr           like(char6_t)  options(*nopass:*omit);
           pOutQueNm         like(char10_t) options(*nopass:*omit);
           pOutQueLb         like(char10_t) options(*nopass:*omit);
           pDevice           like(char10_t) options(*nopass:*omit);
           pDevType          like(char10_t) options(*nopass:*omit);
           pFormType         like(char10_t) options(*nopass:*omit);
           pUserData         like(char10_t) options(*nopass:*omit);
           pStatus           like(char10_t) options(*nopass:*omit);
           pPriority         like(char2_t)  options(*nopass:*omit);
           pCreDate          like(char8_t)  options(*nopass:*omit);
           pCreTime          like(char6_t)  options(*nopass:*omit);
           pTotPgs           packed(9:0)    options(*nopass:*omit);
           pCurPge           packed(9:0)    options(*nopass:*omit);
           pRemCpy           packed(3:0)    options(*nopass:*omit);
           pAspNbr           packed(3:0)    options(*nopass:*omit);
           pAspDvN           like(char10_t) options(*nopass:*omit);
           pJobSysN          like(char8_t)  options(*nopass:*omit);
           pFileSz           packed(15:2)   options(*nopass:*omit);
         // return set 2 -- additional time required
           pFAvailbl         like(char10_t) options(*nopass:*omit);
           pHoldFile         like(char10_t) options(*nopass:*omit);
           pSaveFile         like(char10_t) options(*nopass:*omit);
           pRepUnprt         like(char1_t)  options(*nopass:*omit);
           pReplChar         like(char1_t)  options(*nopass:*omit);
           pDeviceLb         like(char10_t) options(*nopass:*omit);
           pProgName         like(char10_t) options(*nopass:*omit);
           pProgLibr         like(char10_t) options(*nopass:*omit);
           pFormDefN         like(char10_t) options(*nopass:*omit);
           pFormDefL         like(char10_t) options(*nopass:*omit);
           pPageDefN         like(char10_t) options(*nopass:*omit);
           pPageDefL         like(char10_t) options(*nopass:*omit);
           pAcctCode         like(char15_t) options(*nopass:*omit);
           pPrintTxt         like(char30_t) options(*nopass:*omit);
           pMaxRecs          packed(9:0)    options(*nopass:*omit);
           pRecLen           like(char10_t) options(*nopass:*omit);
           pLinesPI          packed(5:1)    options(*nopass:*omit);
           pCharsPI          packed(5:1)    options(*nopass:*omit);
           pPageLeng         packed(3:0)    options(*nopass:*omit);
           pPageWdth         packed(3:0)    options(*nopass:*omit);
           pPageMsrM         like(char10_t) options(*nopass:*omit);
           pUnitMsr          like(char10_t) options(*nopass:*omit);
           pOvflLine         packed(3:0)    options(*nopass:*omit);
           pNbrSeprt         packed(3:0)    options(*nopass:*omit);
           pSrcDrawr         like(char10_t) options(*nopass:*omit);
           pPageRot          like(char10_t) options(*nopass:*omit);
           pPageJust         packed(3:0)    options(*nopass:*omit);
           pFontIdnt         like(char10_t) options(*nopass:*omit);
           pFontSize         packed(5:2)    options(*nopass:*omit);
           pCharIdnt         like(char10_t) options(*nopass:*omit);
           pCodePage         like(char10_t) options(*nopass:*omit);
           pPrntDplx         like(char10_t) options(*nopass:*omit);
           pFoldRecs         like(char10_t) options(*nopass:*omit);
           pCtrlChar         like(char10_t) options(*nopass:*omit);
           pAlgnForm         like(char10_t) options(*nopass:*omit);
           pPrintFid         like(char10_t) options(*nopass:*omit);
           pPrntQual         like(char10_t) options(*nopass:*omit);
           pFormFeed         like(char10_t) options(*nopass);
         end-pi;

         GenUtl_CStkE = GenUtl_FindCallStackEntry('*PRV': PROC_PGM); // get caller info
         Caller = GenUtl_CStkE.QWVPGMN; // save name of calling program

         select;
         when pFile = '*CLOSE';             // if selection list force-close requested
           callp CloseSelectionList();      // do it
           return;                          // return to caller

         when pFile = '*NEXT';              // if next selection list entry requested
           callp NextSelectionEntry();      // do it

         other;                             // start a new selection list requested
           if %parms < %parmnum(pFileName); // has to be at least 1 return field
             GenUtl_Escape( *omit: 'Too few parameters supplied.'
                          : *omit: *omit : Caller );
           endif;
           // build minimum fields (by key) to satisfy request
           RTSFA_KCnt = 2;                  // at least two keys required
           RTSFA_Keys(1) = RTSFA_Codes(1);  // key code for internal job ident
           RTSFA_Keys(2) = RTSFA_Codes(2);  // key code for internal splf ident
           for RTSFA_CCnt = 3 by 1 to (%elem(RTSFA_Codes) - 1);
             ParmNumb = RTSFA_CCnt + 3;     // match to a parm number
             callp CEETSTA(ValidParm: ParmNumb: iFeedback); // test it
             if %parms >= ParmNumb          // if parm passed
             and ValidParm > *zero          // and not omitted
             or GenUtl_inList(%char(RTSFA_Codes(RTSFA_CCnt)):CompareList); // or in compare list
               RTSFA_KCnt += 1;             // increment key count
               RTSFA_Keys(RTSFA_KCnt) = RTSFA_Codes(RTSFA_CCnt);
               if RTSFA_Codes(RTSFA_CCnt) = 223; // special key code
                 RTSFA_KCnt += 1;           // increment key count
                 RTSFA_Keys(RTSFA_KCnt) = 222; // for matching key pair
               endif;
             endif;
           endfor;
           // ok, go get 'em
           callp StartSelectionList( pFile: pJob: pSplNbr
                                   : pSelect: pAspDev );
         endsl;

       // begin return set 1 -- best performance

         if %parms < %parmnum(pFileName)    // if parm not passed
         or %addr(pFileName) = *null;       // or was omitted
         else;                              // skip it, else
           pFileName = gFileName;           // pass back requested value
         endif;

         if %parms < %parmnum(pFileNbr)     // if parm not passed
         or %addr(pFileNbr) = *null;        // or was omitted
         else;                              // skip it, else
           pFileNbr = gFileNbr;             // pass back requested value
         endif;

         if %parms < %parmnum(pJobName)     // if parm not passed
         or %addr(pJobName) = *null;        // or was omitted
         else;                              // skip it, else
           pJobName = gJobName;             // pass back requested value
         endif;

         if %parms < %parmnum(pJobUser)     // if parm not passed
         or %addr(pJobUser) = *null;        // or was omitted
         else;                              // skip it, else
           pJobUser = gJobUser;             // pass back requested value
         endif;

         if %parms < %parmnum(pJobNbr)      // if parm not passed
         or %addr(pJobNbr) = *null;         // or was omitted
         else;                              // skip it, else
           pJobNbr = gJobNbr;               // pass back requested value
         endif;

         if %parms < %parmnum(pOutQueNm)    // if parm not passed
         or %addr(pOutQueNm) = *null;       // or was omitted
         else;                              // skip it, else
           pOutQueNm = gOutQueNm;           // pass back requested value
         endif;

         if %parms < %parmnum(pOutQueLb)    // if parm not passed
         or %addr(pOutQueLb) = *null;       // or was omitted
         else;                              // skip it, else
           pOutQueLb = gOutQueLb;           // pass back requested value
         endif;

         if %parms < %parmnum(pDevice)      // if parm not passed
         or %addr(pDevice) = *null;         // or was omitted
         else;                              // skip it, else
           pDevice = gDevice;               // pass back requested value
         endif;

         if %parms < %parmnum(pDevType)     // if parm not passed
         or %addr(pDevType) = *null;        // or was omitted
         else;                              // skip it, else
           pDevType = gDevType;             // pass back requested value
         endif;

         if %parms < %parmnum(pFormType)    // if parm not passed
         or %addr(pFormType) = *null;       // or was omitted
         else;                              // skip it, else
           pFormType = gFormType;           // pass back requested value
         endif;

         if %parms < %parmnum(pUserData)    // if parm not passed
         or %addr(pUserData) = *null;       // or was omitted
         else;                              // skip it, else
           pUserData = gUserData;           // pass back requested value
         endif;

         if %parms < %parmnum(pStatus)      // if parm not passed
         or %addr(pStatus) = *null;         // or was omitted
         else;                              // skip it, else
           pStatus = gStatus;               // pass back requested value
         endif;

         if %parms < %parmnum(pPriority)    // if parm not passed
         or %addr(pPriority) = *null;       // or was omitted
         else;                              // skip it, else
           pPriority = gPriority;           // pass back requested value
         endif;

         if %parms < %parmnum(pCreDate)     // if parm not passed
         or %addr(pCreDate) = *null;        // or was omitted
         else;                              // skip it, else convert and
           pCreDate = gCreDate;             // pass back requested value
         endif;

         if %parms < %parmnum(pCreTime)     // if parm not passed
         or %addr(pCreTime) = *null;        // or was omitted
         else;                              // skip it, else
           pCreTime = gCreTime;             // pass back requested value
         endif;

         if %parms < %parmnum(pTotPgs)      // if parm not passed
         or %addr(pTotPgs) = *null;         // or was omitted
         else;                              // skip it, else
           pTotPgs = gTotPgs;               // pass back requested value
         endif;

         if %parms < %parmnum(pCurPge)      // if parm not passed
         or %addr(pCurPge) = *null;         // or was omitted
         else;                              // skip it, else
           pCurPge = gCurPge;               // pass back requested value
         endif;

         if %parms < %parmnum(pRemCpy)      // if parm not passed
         or %addr(pRemCpy) = *null;         // or was omitted
         else;                              // skip it, else
           pRemCpy = gRemCpy;               // pass back requested value
         endif;

         if %parms < %parmnum(pAspNbr)      // if parm not passed
         or %addr(pAspNbr) = *null;         // or was omitted
         else;                              // skip it, else
           pAspNbr = gAspNbr;               // pass back requested value
         endif;

         if %parms < %parmnum(pAspDvN)      // if parm not passed
         or %addr(pAspDvN) = *null;         // or was omitted
         else;                              // skip it, else
           pAspDvN = gAspDvN;               // pass back requested value
         endif;

         if %parms < %parmnum(pFileSz)      // if parm not passed
         or %addr(pFileSz) = *null;         // or was omitted
         else;                              // skip it, else
           pFileSz = gFileSz;               // pass back requested value
         endif;

         if %parms <= %parmnum(pFileSz);    // for performance reasons, if no more parms
           return;                          // then take a shortcut out of the program
         endif;

       // begin return set 2 -- additional time required

         if  (%parms < %parmnum(pFAvailbl)  // if all other parms not passed
         or   %addr(pFAvailbl) = *null)     // or all other parms omitted
         and (%parms < %parmnum(pHoldFile)
         or   %addr(pHoldFile) = *null)
         and (%parms < %parmnum(pSaveFile)
         or   %addr(pSaveFile) = *null)
         and (%parms < %parmnum(pRepUnprt)
         or   %addr(pRepUnprt) = *null)
         and (%parms < %parmnum(pReplChar)
         or   %addr(pReplChar) = *null)
         and (%parms < %parmnum(pDeviceLb)
         or   %addr(pDeviceLb) = *null)
         and (%parms < %parmnum(pProgName)
         or   %addr(pProgName) = *null)
         and (%parms < %parmnum(pProgLibr)
         or   %addr(pProgLibr) = *null)
         and (%parms < %parmnum(pFormDefN)
         or   %addr(pFormDefN) = *null)
         and (%parms < %parmnum(pFormDefL)
         or   %addr(pFormDefL) = *null)
         and (%parms < %parmnum(pPageDefN)
         or   %addr(pPageDefN) = *null)
         and (%parms < %parmnum(pPageDefL)
         or   %addr(pPageDefL) = *null)
         and (%parms < %parmnum(pAcctCode)
         or   %addr(pAcctCode) = *null)
         and (%parms < %parmnum(pPrintTxt)
         or   %addr(pPrintTxt) = *null)
         and (%parms < %parmnum(pMaxRecs )
         or   %addr(pMaxRecs ) = *null)
         and (%parms < %parmnum(pRecLen  )
         or   %addr(pRecLen  ) = *null)
         and (%parms < %parmnum(pLinesPI )
         or   %addr(pLinesPI ) = *null)
         and (%parms < %parmnum(pCharsPI )
         or   %addr(pCharsPI ) = *null)
         and (%parms < %parmnum(pPageLeng)
         or   %addr(pPageLeng) = *null)
         and (%parms < %parmnum(pPageWdth)
         or   %addr(pPageWdth) = *null)
         and (%parms < %parmnum(pPageMsrM)
         or   %addr(pPageMsrM) = *null)
         and (%parms < %parmnum(pUnitMsr )
         or   %addr(pUnitMsr ) = *null)
         and (%parms < %parmnum(pOvflLine)
         or   %addr(pOvflLine) = *null)
         and (%parms < %parmnum(pNbrSeprt)
         or   %addr(pNbrSeprt) = *null)
         and (%parms < %parmnum(pSrcDrawr)
         or   %addr(pSrcDrawr) = *null)
         and (%parms < %parmnum(pPageRot )
         or   %addr(pPageRot ) = *null)
         and (%parms < %parmnum(pPageJust)
         or   %addr(pPageJust) = *null)
         and (%parms < %parmnum(pFontIdnt)
         or   %addr(pFontIdnt) = *null)
         and (%parms < %parmnum(pFontSize)
         or   %addr(pFontSize) = *null)
         and (%parms < %parmnum(pCharIdnt)
         or   %addr(pCharIdnt) = *null)
         and (%parms < %parmnum(pCodePage)
         or   %addr(pCodePage) = *null)
         and (%parms < %parmnum(pPrntDplx)
         or   %addr(pPrntDplx) = *null)
         and (%parms < %parmnum(pFoldRecs)
         or   %addr(pFoldRecs) = *null)
         and (%parms < %parmnum(pCtrlChar)
         or   %addr(pCtrlChar) = *null)
         and (%parms < %parmnum(pAlgnForm)
         or   %addr(pAlgnForm) = *null)
         and (%parms < %parmnum(pPrintFid)
         or   %addr(pPrintFid) = *null)
         and (%parms < %parmnum(pPrntQual)
         or   %addr(pPrntQual) = *null)
         and (%parms < %parmnum(pFormFeed)
         or   %addr(pFormFeed) = *null);
         else;                              // skip them, else
                                            // retrieve additional spool file attributes
           callp IBMAPI_RtvSplFileAttrs( QUSA010001: %len(QUSA010001)
                                       : 'SPLA0100': '*INT'
                                       : RTSFA_IntJob: RTSFA_IntSpl
                                       : '*INT': *zero: ApiErrC );
           if ApiErrC.BytAvail > *zero;     // if API error, report it
             GenUtl_Escape( ApiErrC.MsgId: ApiErrC.MsgData
                          : 'QCPFMSG': *omit : Caller );
           endif;

           if %parms < %parmnum(pFAvailbl)  // if parm not passed
           or %addr(pFAvailbl) = *null;     // or was omitted
           else;                            // skip it, else
             pFAvailbl = QUSFILA03;         // pass back requested value
           endif;

           if %parms < %parmnum(pHoldFile)  // if parm not passed
           or %addr(pHoldFile) = *null;     // or was omitted
           else;                            // skip it, else
             pHoldFile = QUSHFIL;           // pass back requested value
           endif;

           if %parms < %parmnum(pSaveFile)  // if parm not passed
           or %addr(pSaveFile) = *null;     // or was omitted
           else;                            // skip it, else
             pSaveFile = QUSSFIL03;         // pass back requested value
           endif;

           if %parms < %parmnum(pRepUnprt)  // if parm not passed
           or %addr(pRepUnprt) = *null;     // or was omitted
           else;                            // skip it, else
             pRepUnprt = QUSRU;             // pass back requested value
           endif;

           if %parms < %parmnum(pReplChar)  // if parm not passed
           or %addr(pReplChar) = *null;     // or was omitted
           else;                            // skip it, else
             pReplChar = QUSRC00;           // pass back requested value
           endif;

           if %parms < %parmnum(pDeviceLb)  // if parm not passed
           or %addr(pDeviceLb) = *null;     // or was omitted
           else;                            // skip it, else
             pDeviceLb = QUSDFILL02;        // pass back requested value
           endif;

           if %parms < %parmnum(pProgName)  // if parm not passed
           or %addr(pProgName) = *null;     // or was omitted
           else;                            // skip it, else
             pProgName = QUSPN;             // pass back requested value
           endif;

           if %parms < %parmnum(pProgLibr)  // if parm not passed
           or %addr(pProgLibr) = *null;     // or was omitted
           else;                            // skip it, else
             pProgLibr = QUSPL00;           // pass back requested value
           endif;

           if %parms < %parmnum(pFormDefN)  // if parm not passed
           or %addr(pFormDefN) = *null;     // or was omitted
           else;                            // skip it, else
             pFormDefN = QUSFDN;            // pass back requested value
           endif;

           if %parms < %parmnum(pFormDefL)  // if parm not passed
           or %addr(pFormDefL) = *null;     // or was omitted
           else;                            // skip it, else
             pFormDefL = QUSFDL;            // pass back requested value
           endif;

           if %parms < %parmnum(pPageDefN)  // if parm not passed
           or %addr(pPageDefN) = *null;     // or was omitted
           else;                            // skip it, else
             pPageDefN = QUSPD03;           // pass back requested value
           endif;

           if %parms < %parmnum(pPageDefL)  // if parm not passed
           or %addr(pPageDefL) = *null;     // or was omitted
           else;                            // skip it, else
             pPageDefL = QUSPDL;            // pass back requested value
           endif;

           if %parms < %parmnum(pAcctCode)  // if parm not passed
           or %addr(pAcctCode) = *null;     // or was omitted
           else;                            // skip it, else
             pAcctCode = QUSCC;             // pass back requested value
           endif;

           if %parms < %parmnum(pPrintTxt)  // if parm not passed
           or %addr(pPrintTxt) = *null;     // or was omitted
           else;                            // skip it, else
             pPrintTxt = QUSPT00;           // pass back requested value
           endif;

           if %parms < %parmnum(pMaxRecs )  // if parm not passed
           or %addr(pMaxRecs ) = *null;     // or was omitted
           else;                            // skip it, else
             pMaxRecs  = QUSMR;             // pass back requested value
           endif;

           if %parms < %parmnum(pRecLen  )  // if parm not passed
           or %addr(pRecLen  ) = *null;     // or was omitted
           else;                            // skip it, else
             if QUSRL05 = -1;               // special value?
               pRecLen = '*RCDFMT';         // pass back translated value
             else;                          // else
               pRecLen = %char(QUSRL05);    // pass back requested value
             endif;
           endif;

           if %parms < %parmnum(pLinesPI )  // if parm not passed
           or %addr(pLinesPI ) = *null;     // or was omitted
           else;                            // skip it, else
             pLinesPI  = QUSLPI / 10.0;     // pass back requested value
           endif;

           if %parms < %parmnum(pCharsPI )  // if parm not passed
           or %addr(pCharsPI ) = *null;     // or was omitted
           else;                            // skip it, else
             pCharsPI  = QUSCPI / 10.0;     // pass back requested value
           endif;

           if %parms < %parmnum(pPageLeng)  // if parm not passed
           or %addr(pPageLeng) = *null;     // or was omitted
           else;                            // skip it, else
             pPageLeng = QUSPL01;           // pass back requested value
           endif;

           if %parms < %parmnum(pPageWdth)  // if parm not passed
           or %addr(pPageWdth) = *null;     // or was omitted
           else;                            // skip it, else
             pPageWdth = QUSPW;             // pass back requested value
           endif;

           if %parms < %parmnum(pPageMsrM)  // if parm not passed
           or %addr(pPageMsrM) = *null;     // or was omitted
           else;                            // skip it, else
             pPageMsrM = QUSMM;             // pass back requested value
           endif;

           if %parms < %parmnum(pUnitMsr )  // if parm not passed
           or %addr(pUnitMsr ) = *null;     // or was omitted
           else;                            // skip it, else
             pUnitMsr  = QUSUM;             // pass back requested value
           endif;

           if %parms < %parmnum(pOvflLine)  // if parm not passed
           or %addr(pOvflLine) = *null;     // or was omitted
           else;                            // skip it, else
             pOvflLine = QUSOLN;            // pass back requested value
           endif;

           if %parms < %parmnum(pNbrSeprt)  // if parm not passed
           or %addr(pNbrSeprt) = *null;     // or was omitted
           else;                            // skip it, else
             pNbrSeprt = QUSNBRS01;         // pass back requested value
           endif;

           if %parms < %parmnum(pSrcDrawr)  // if parm not passed
           or %addr(pSrcDrawr) = *null;     // or was omitted
           else;                            // skip it, else
             select;                        // special value?
             when QUSSD06 = -2;
               pSrcDrawr = '*FORMDF';       // pass back translated value
             when QUSSD06 = -1;
               pSrcDrawr = '*E1';           // pass back translated value
             other;
               pSrcDrawr = %char(QUSSD06);  // pass back requested value
             endsl;
           endif;

           if %parms < %parmnum(pPageRot )  // if parm not passed
           or %addr(pPageRot ) = *null;     // or was omitted
           else;                            // skip it, else
             select;                        // special value?
             when QUSPR = -3;
               pPageRot = '*COR';           // pass back translated value
             when QUSPR = -2;
               pPageRot = '*DEVD';          // pass back translated value
             when QUSPR = -1;
               pPageRot = '*AUTO';          // pass back translated value
             other;
               pPageRot  = %char(QUSPR);    // pass back requested value
             endsl;
           endif;

           if %parms < %parmnum(pPageJust)  // if parm not passed
           or %addr(pPageJust) = *null;     // or was omitted
           else;                            // skip it, else
             pPageJust = QUSATION;          // pass back requested value
           endif;

           if %parms < %parmnum(pFontIdnt)  // if parm not passed
           or %addr(pFontIdnt) = *null;     // or was omitted
           else;                            // skip it, else
             pFontIdnt = QUSPF00;           // pass back requested value
           endif;

           if %parms < %parmnum(pFontSize)  // if parm not passed
           or %addr(pFontSize) = *null;     // or was omitted
           else;                            // skip it, else
             pFontSize = QUSPS;             // pass back requested value
           endif;

           if %parms < %parmnum(pCharIdnt)  // if parm not passed
           or %addr(pCharIdnt) = *null;     // or was omitted
           else;                            // skip it, else
             pCharIdnt = QUSGCS;            // pass back requested value
           endif;

           if %parms < %parmnum(pCodePage)  // if parm not passed
           or %addr(pCodePage) = *null;     // or was omitted
           else;                            // skip it, else
             pCodePage = QUSCP00;           // pass back requested value
           endif;

           if %parms < %parmnum(pPrntDplx)  // if parm not passed
           or %addr(pPrntDplx) = *null;     // or was omitted
           else;                            // skip it, else
             pPrntDplx = QUSUPLEX;          // pass back requested value
           endif;

           if %parms < %parmnum(pFoldRecs)  // if parm not passed
           or %addr(pFoldRecs) = *null;     // or was omitted
           else;                            // skip it, else
             pFoldRecs = QUSFOLD;           // pass back requested value
           endif;

           if %parms < %parmnum(pCtrlChar)  // if parm not passed
           or %addr(pCtrlChar) = *null;     // or was omitted
           else;                            // skip it, else
             pCtrlChar = QUSCC00;           // pass back requested value
           endif;

           if %parms < %parmnum(pAlgnForm)  // if parm not passed
           or %addr(pAlgnForm) = *null;     // or was omitted
           else;                            // skip it, else
             pAlgnForm = QUSAF;             // pass back requested value
           endif;

           if %parms < %parmnum(pPrintFid)  // if parm not passed
           or %addr(pPrintFid) = *null;     // or was omitted
           else;                            // skip it, else
             pPrintFid = QUSPF;             // pass back requested value
           endif;

           if %parms < %parmnum(pPrntQual)  // if parm not passed
           or %addr(pPrntQual) = *null;     // or was omitted
           else;                            // skip it, else
             pPrntQual = QUSPQ;             // pass back requested value
           endif;

           if %parms < %parmnum(pFormFeed)  // if parm not passed
           or %addr(pFormFeed) = *null;     // or was omitted
           else;                            // skip it, else
             pFormFeed = QUSFF;             // pass back requested value
           endif;

         endif;

         return;                            // return to caller
       end-proc;
     *========================================================================*
     * End of mainline procedure -- subprocedures follow                      *
     *========================================================================*

      **************************************************************************
      * This procedure closes the current selection list.                      *
      **************************************************************************
       dcl-proc CloseSelectionList;
         dcl-pi *n;
         end-pi;

         if not ListIsOpen;                 // if no selection list is open
           return;                          // return to caller
         endif;

         reset Selection;                   // values no longer needed
         reset RTSFA_SpcPtr;

         ListIsOpen = *off;                 // signal that list is closed
         reset ApiErrC;                     // prepare for errors

         callp IBMAPI_DltUsrSpace(RTSFA_Space: ApiErrC); // close the list
         if ApiErrC.BytAvail > *zero;       // if API error, report it
           GenUtl_Escape(  ApiErrC.MsgId: ApiErrC.MsgData
                        : 'QCPFMSG': *omit : Caller );
         endif;

         reset RTSFA_Space;                 // value no longer needed

         return;                            // return to caller
       end-proc;

      **************************************************************************
      * This procedure retrieves an entry from the current selection list.     *
      **************************************************************************
       dcl-proc GetSelectionEntry;
         dcl-pi *n;
         end-pi;

         dcl-s entry_not_selected like(boolean_t) inz(*on);

         if not ListIsOpen;                 // if no selection list is open
           GenUtl_Escape( 'UTR9801': *omit       // raise exception
                        : *omit: *omit : Caller );
         endif;

         dow entry_not_selected             // loop until entry selected
         and RTSFA_Entry <= RTSFA_Gen_DS.QUSNBRLE; // or end of list
           reset RTSFA_Return_Values;       // prepare to save the data
           RTSFA_Fld_Ptr = RTSFA_Lst_Ptr + 4; // point to first field
         // extract all fields for this entry
           for RTSFA_FCnt = 1 by 1 to RTSFA_Lst_DS.QUSNBRFR00; // loop on fields
             RTSFA_Dta_Ptr = RTSFA_Fld_Ptr + %len(QUSSPLKI); // point to the data
           // extract data for this field -- by data type
             select;
             when RTSFA_Fld_DS.QUSTOD02 = 'P';   // packed decimal?
               RTSFA_PDec = RTSFA_Dta_DS.PDec;   // get decimal data for field
             when RTSFA_Fld_DS.QUSTOD02 = 'C'    // Date file was opened (created)?
             and  RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(16);
               RTSFA_Data = %char( %date( %subst( RTSFA_Dta_DS.Str: 1
                                                : RTSFA_Fld_DS.QUSDL02 )
                                        : *CYMD0 )
                                 : *ISO0 );      // convert string date for field
             when RTSFA_Fld_DS.QUSTOD02 = 'C';   // character string?
               RTSFA_Data = %subst( RTSFA_Dta_DS.Str: 1
                                  : RTSFA_Fld_DS.QUSDL02 ); // get string data for field
             when RTSFA_Fld_DS.QUSTOD02 = 'B';   // binary integer?
               RTSFA_Int4 = RTSFA_Dta_DS.Int4;   // get binary data for field
             endsl;
           // save extracted data in global fields for further testing
             select;
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(1);
               RTSFA_IntJob = RTSFA_Data;   // internal job identifier
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(2);
               RTSFA_IntSpl = RTSFA_Data;   // internal spooled file ident
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(3);
               gFileName    = RTSFA_Data;   // Spooled file name
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(4);
               gFileNbr     = RTSFA_Int4;   // Spooled file number
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(5);
               gJobName     = RTSFA_Data;   // Job name
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(6);
               gJobUser     = RTSFA_Data;   // User name
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(7);
               gJobNbr      = RTSFA_Data;   // Job number
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(8);
               gOutQueNm    = RTSFA_Data;   // Output queue name
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(9);
               gOutQueLb    = RTSFA_Data;   // Output queue library name
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(10);
               gDevice      = RTSFA_Data;   // Device
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(11);
               gDevType     = RTSFA_Data;   // Device type
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(12);
               gFormType    = RTSFA_Data;   // Form type
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(13);
               gUserData    = RTSFA_Data;   // User-specified data
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(14);
               gStatus      = RTSFA_Data;   // Status
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(15);
               gPriority    = RTSFA_Data;   // Priority
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(16);
               gCreDate     = RTSFA_Data;   // Date file was opened (created)
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(17);
               gCreTime     = RTSFA_Data;   // Time file was opened (created)
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(18);
               gTotPgs      = RTSFA_Int4;   // Total pages
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(19);
               gCurPge      = RTSFA_Int4;   // Current page
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(20);
               gRemCpy      = RTSFA_Int4;   // Copies left to produce
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(21);
               gAspNbr      = RTSFA_Int4;   // Auxiliary storage pool
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(22);
               gAspDvN      = RTSFA_Data;   // Auxiliary storage pool device name
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(23);
               gJobSysN     = RTSFA_Data;   // Job system name
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(24);
               gFileSz      = RTSFA_Int4;   // Size of spooled file
             when RTSFA_Fld_DS.QUSKFFFR00 = RTSFA_Codes(25);
               gFileSz = gFileSz * RTSFA_Int4 / 1024.00; // Spooled file size multiplier
             endsl;
             RTSFA_Fld_Ptr += RTSFA_Fld_DS.QUSLFIR02; // point to next field
           endfor;
           RTSFA_Lst_Ptr += RTSFA_Gen_DS.QUSSEE; // point to next entry
         // apply any additional selection criteria
           if  SelectedFileNameMatches()
           and SelectedQualJobMatches()
           and SelectedSplNbrMatches()
           and SelectedPrtDevMatches()
           and SelectedFormTypeMatches()
           and SelectedUserDataMatches()
           and SelectedAspNbrMatches()
           and SelectedAspDevMatches();
             entry_not_selected = *off;     // then, caller requested this entry
           else;
             RTSFA_Entry += 1;              // else, increment to next entry
           endif;
         enddo;

         if RTSFA_Entry > RTSFA_Gen_DS.QUSNBRLE; // end of list?
           callp CloseSelectionList();      // close the list
           GenUtl_Escape( 'UTR9801': *omit       // raise exception
                        : *omit: *omit : Caller );
         endif;

         return;                            // return to caller
       end-proc;

      **************************************************************************
      * This procedure retrieves the next selection list entry.                *
      **************************************************************************
       dcl-proc NextSelectionEntry;
         dcl-pi *n;
         end-pi;

         RTSFA_Entry += 1;                  // increment entry number
         callp GetSelectionEntry();

         return;                            // return to caller
       end-proc;

      **************************************************************************
      * This procedure opens a new selection list.                             *
      **************************************************************************
       dcl-proc OpenSelectionList;
         dcl-pi *n;
           pFile             like(char10_t) const;
           pJob              likeds(RTSFA_QualJob) const options(*omit);
           pSplNbr           like(char6_t)  const options(*omit);
           pSelect           likeds(RTSFA_Select) options(*omit);
           pAspDev           like(char10_t) const options(*omit);
         end-pi;

         dcl-ds iJob         likeds(pJob);
         dcl-s  iSplNbr      like(pSplNbr);
         dcl-ds iSelect      likeds(pSelect);
         dcl-s  iAspDev      like(pAspDev);

         if %addr(pJob) = *null;       // if qualified job parameter ommitted
           iJob = '*ANY';              // supply default value
         else;                         // else
           iJob = pJob;                // copy supplied value
         endif;

         if %addr(pSplNbr) = *null;    // if spool number parameter ommitted
           iSplNbr = '*ANY';           // supply default value
         else;                         // else
           iSplNbr = pSplNbr;          // copy supplied value
         endif;

         if %addr(pSelect) = *null;    // if selection fields parameter ommitted
           iSelect.Count = 5;          // supply default values
           iSelect.User = '*CURRENT';
           iSelect.PDev = '*ALL';
           iSelect.Form = '*ALL';
           iSelect.Data = '*ALL';
           iSelect.ASP  = '*ALL';
         else;                         // else
           iSelect = pSelect;          // copy supplied values
         endif;

         if %addr(pAspDev) = *null;    // if ASP device name parameter ommitted
           iAspDev = '*';              // supply default value
         else;                         // else
           iAspDev = pAspDev;          // copy supplied value
         endif;

         RTSFA_Space = PROC_PGM + 'QTEMP';  // set the user space name/lib

         callp IBMAPI_CrtUsrSpace( RTSFA_Space: 'SPLFLIST'
M001   //                        : 256 * 1024: x'00': '*EXCLUDE'
M001                             : 16773120: x'00': '*EXCLUDE'
                                 : 'List of Selected Spool Files'
                                 : '*YES': ApiErrC); // open a space for list
         if ApiErrC.BytAvail > *zero;       // if API error, report it
           GenUtl_Escape( ApiErrC.MsgId: ApiErrC.MsgData
                        : 'QCPFMSG': *omit : Caller );
         endif;

         ListIsOpen = *on;                  // signal that list is open

         callp IBMAPI_RtvPtrUsrSpace(RTSFA_Space: RTSFA_SpcPtr: ApiErrC);
         if ApiErrC.BytAvail > *zero;       // if API error, report it
           GenUtl_Escape( ApiErrC.MsgId: ApiErrC.MsgData
                        : 'QCPFMSG': *omit : Caller );
         endif;

         clear QUSPLFI2;                         // initialize input parameters
         if iJob.Name <> '*ANY';                 // specific job?
           QUSQJN = iJob;                        // job selection
           QUSASP08 = -1;                        // no ASP selection
           QUSJSNS = '*ALL';                     // job system selection
           QUSSSCDS = '*ALL';                    // no create date selection
           QUSSPDNS = iAspDev;                   // ASPDEV selection
         else;                                   // else, all jobs
           QUSUN16 = iSelect.User;               // user selection
           if iSelect.PDev = '*ALL'
           or iSelect.PDev = '*OUTQ';
             QUSOQN01 = '*ALL';                  // all outq selection
             QUSOQL02 = *blanks;
           else;
             QUSOQN01 = iSelect.PDev;            // specific outq selection
             QUSOQL02 = '*LIBL';
           endif;
           QUSFT08 = iSelect.Form;               // form type selection
           if GenUtl_SuffixString(iSelect.Data:1) <> '*'; // user data not generic?
             QUSUD03 = iSelect.Data;             // user data filter
           else;
             QUSUD03 = '*ALL';
           endif;
           QUSQJN = *blanks;                     // all jobs
           select;
           when iSelect.ASP = '*ALL';
             QUSASP08 = *zero;                   // all ASP selection
           when iSelect.ASP = '*ASPDEV';
             QUSASP08 = -2;                      // ASPDEV selection
           other;
             QUSASP08 = %int(iSelect.ASP);       // specific ASP selection
           endsl;
           QUSJSNS = '*ALL';                     // job system selection
           QUSSSCDS = '*ALL';                    // no create date selection
           QUSSPDNS = iAspDev;                   // ASPDEV selection
         endif;

         callp IBMAPI_ListSpooledFiles( RTSFA_Space: 'SPLF0200': QUSUN16
                                      : QUSOQN01 + QUSOQL02: QUSFT08
                                      : QUSUD03: ApiErrC: QUSQJN
                                      : RTSFA_Keys: RTSFA_KCnt
                                      : QUSASP08: QUSJSNS
                                      : QUSSSCDS: QUSSSCTS
                                      : QUSESCDS: QUSESCTS
                                      : QUSSPDNS );
         if ApiErrC.BytAvail > *zero;       // if API error, report it
           GenUtl_Escape( ApiErrC.MsgId: ApiErrC.MsgData
                        : 'QCPFMSG': *omit : Caller );
         endif;

         RTSFA_Gen_Ptr = RTSFA_SpcPtr + 0;  // point to user space
         RTSFA_Inp_Ptr = RTSFA_SpcPtr + RTSFA_Gen_DS.QUSOIP; // input area
         RTSFA_Hdr_Ptr = RTSFA_SpcPtr + RTSFA_Gen_DS.QUSOHS; // header area
         RTSFA_Lst_Ptr = RTSFA_SpcPtr + RTSFA_Gen_DS.QUSOLD; // list area

         Selection.File   = pFile;          // save for *NEXT
         Selection.Job    = iJob;
         Selection.SplNbr = iSplNbr;
         Selection.Selctn = iSelect;
         Selection.AspDev = iAspDev;

         return;                            // return to caller
       end-proc;

      **************************************************************************
      * This procedure determines if the current list entry matches caller     *
      * selection criteria for Spooled ASP Device.                             *
      **************************************************************************
       dcl-proc SelectedAspDevMatches;
         dcl-pi *n           like(boolean_t);
         end-pi;

         if  Selection.AspDev = '*CURASPGRP' // if selected ASP device matches
         or  Selection.AspDev = '*SYSBAS'
         or  Selection.AspDev = '*'
         or  Selection.AspDev <> '*CURASPGRP'
         and Selection.AspDev <> '*SYSBAS'
         and Selection.AspDev <> '*'
         and Selection.AspDev = gAspDvN;
           return *on;                      // return positive result to caller
         endif;

         return *off;                       // return negative result to caller
       end-proc;

      **************************************************************************
      * This procedure determines if the current list entry matches caller     *
      * selection criteria for Spooled ASP Number.                             *
      **************************************************************************
       dcl-proc SelectedAspNbrMatches;
         dcl-pi *n           like(boolean_t);
         end-pi;

         if  Selection.Selctn.ASP = '*ALL'  // if selected ASP number matches
         or  Selection.Selctn.ASP = '*ASPDEV'
         or  Selection.Selctn.ASP <> '*ALL'
         and Selection.Selctn.ASP <> '*ASPDEV'
         and %int(Selection.Selctn.ASP) = gAspNbr;
           return *on;                      // return positive result to caller
         endif;

         return *off;                       // return negative result to caller
       end-proc;

      **************************************************************************
      * This procedure determines if the current list entry matches caller     *
      * selection criteria for Spooled File Name.                              *
      **************************************************************************
       dcl-proc SelectedFileNameMatches;
         dcl-pi *n           like(boolean_t);
         end-pi;

         if  Selection.File = '*SELECT'     // if selected file name matches
         or  Selection.File <> '*SELECT'
         and ((GenUtl_SuffixString(Selection.File:1) <> '*'
         and Selection.File = gFileName)
         or  (GenUtl_SuffixString(Selection.File:1) = '*'
         and GenUtl_isGenericMatch(Selection.File:gFileName)));
           return *on;                      // return positive result to caller
         endif;

         return *off;                       // return negative result to caller
       end-proc;

      **************************************************************************
      * This procedure determines if the current list entry matches caller     *
      * selection criteria for Spooled Form Type.                              *
      **************************************************************************
       dcl-proc SelectedFormTypeMatches;
         dcl-pi *n           like(boolean_t);
         end-pi;

         if  Selection.Selctn.Form = '*ALL' // if selected form type matches
         or  Selection.Selctn.Form = '*STD'
         and Selection.Selctn.Form = gFormType
         or  Selection.Selctn.Form <> '*ALL'
         and Selection.Selctn.Form <> '*STD'
         and Selection.Selctn.Form = gFormType;
           return *on;                      // return positive result to caller
         endif;

         return *off;                       // return negative result to caller
       end-proc;

      **************************************************************************
      * This procedure determines if the current list entry matches caller     *
      * selection criteria for Spooled Printer Device.                         *
      **************************************************************************
       dcl-proc SelectedPrtDevMatches;
         dcl-pi *n           like(boolean_t);
         end-pi;

         if  Selection.Selctn.PDev = '*ALL' // if selected print device matches
         or  Selection.Selctn.PDev = '*OUTQ'
         and gDevice <= *blanks
         or  Selection.Selctn.PDev <> '*ALL'
         and Selection.Selctn.PDev <> '*OUTQ'
         and Selection.Selctn.PDev = gDevice;
           return *on;                      // return positive result to caller
         endif;

         return *off;                       // return negative result to caller
       end-proc;

      **************************************************************************
      * This procedure determines if the current list entry matches caller     *
      * selection criteria for Qualified Job Name.                             *
      **************************************************************************
       dcl-proc SelectedQualJobMatches;
         dcl-pi *n           like(boolean_t);
         end-pi;

         if  Selection.Job = '*ANY'         // if selected qualified job matches
         or  Selection.Job <> '*ANY'
         and ((Selection.Job <> '*'
         and gJobName = Selection.Job.Name
         and gJobUser = Selection.Job.User
         and gJobNbr  = Selection.Job.Nmbr)
         or  (Selection.Job = '*'
         and gJobName = JOB_NAME
         and gJobUser = USERNAME
         and %int(gJobNbr) = JOB_NUM));
           return *on;                      // return positive result to caller
         endif;

         return *off;                       // return negative result to caller
       end-proc;

      **************************************************************************
      * This procedure determines if the current list entry matches caller     *
      * selection criteria for Spooled File Number.                            *
      **************************************************************************
       dcl-proc SelectedSplNbrMatches;
         dcl-pi *n           like(boolean_t);
         end-pi;

         if  Selection.SplNbr = '*ANY'      // if selected file number matches
         or  Selection.SplNbr = '*ONLY'
         and RTSFA_Entry = 1
         or  Selection.SplNbr = '*LAST'
         and RTSFA_Entry = RTSFA_Gen_DS.QUSNBRLE
         or  Selection.SplNbr <> '*ANY'
         and Selection.SplNbr <> '*ONLY'
         and Selection.SplNbr <> '*LAST'
         and %int(Selection.SplNbr) = gFileNbr;
           return *on;                      // return positive result to caller
         endif;

         return *off;                       // return negative result to caller
       end-proc;

      **************************************************************************
      * This procedure determines if the current list entry matches caller     *
      * selection criteria for Spooled User Data.                              *
      **************************************************************************
       dcl-proc SelectedUserDataMatches;
         dcl-pi *n           like(boolean_t);
         end-pi;

         if  Selection.Selctn.Data = '*ALL' // if selected user data matches
         or  Selection.Selctn.Data <> '*ALL'
         and ((GenUtl_SuffixString(Selection.Selctn.Data:1) <> '*'
         and Selection.Selctn.Data = gUserData)
         or  (GenUtl_SuffixString(Selection.Selctn.Data:1) = '*'
         and GenUtl_isGenericMatch(Selection.Selctn.Data:gUserData)));
           return *on;                      // return positive result to caller
         endif;

         return *off;                       // return negative result to caller
       end-proc;

      **************************************************************************
      * This procedure starts a new request and retrieves the first entry.     *
      **************************************************************************
       dcl-proc StartSelectionList;
         dcl-pi *n;
           pFile             like(char10_t) const;
           pJob              likeds(RTSFA_QualJob) const options(*omit);
           pSplNbr           like(char6_t)  const options(*omit);
           pSelect           likeds(RTSFA_Select) options(*omit);
           pAspDev           like(char10_t) const options(*omit);
         end-pi;

         callp CloseSelectionList();        // start a new request

         callp OpenSelectionList( pFile: pJob: pSplNbr
                                : pSelect: pAspDev );

         RTSFA_Entry = 1;                   // initialize entry number
         callp GetSelectionEntry();

         return;                            // return to caller
       end-proc;

     *========================================================================*
     * End of subprocedures -- compile-time data may follow                   *
     *========================================================================*

**CTDATA RTSFA_Codes
218      Internal job identifier
219      Internal spooled file identifier
201      Spooled file name                  // from here down same order as return set 1
205      Spooled file number
202      Job name
203      User name
204      Job number
206      Output queue name
207      Output queue library name
208      Device
220      Device type
214      Form type
209      User-specified data
210      Status
215      Priority
216      Date file was opened (created)
217      Time file was opened (created)
211      Total pages
212      Current page
213      Copies left to produce
224      Auxiliary storage pool
226      Auxiliary storage pool device name
225      Job system name
223      Size of spooled file
222      Spooled file size multiplier 