	NOLIST
;  REVISION INFORMATION ****************************************************************
;
;  $Author: rao $
;  $Date: 2002-03-21 16:49:54 $
;  $Revision: 1.1 $
;  $Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/tube_module/synthesizer_white.asm,v $
;  $State: Exp $
;
;
;  $Log: not supported by cvs2svn $
;; Revision 1.1  1995/02/27  17:29:27  len
;; Added support for Intel MultiSound DSP.  Module now compiles FAT.
;;
;
;
;***************************************************************************************
;
;  Program:	synthesizer_white.asm
;
;  Author:	Leonard Manzara
;
;  Date:	January, 1995
;
;  Summary:	Master include file for the synthesizer on white
;               (Intel) hardware, using the Turtle Beach Multisound
;               DSP card.
;
;
;		Copyright (C) by Trillium Sound Research Inc. 1994
;		All Rights Reserved
;
;***************************************************************************************


;***************************************************************************************
;  COMPILATION FLAGS
;***************************************************************************************

BLACK		set	0
MSOUND		set	1
SSI_OUTPUT	set	0

;***************************************************************************************
;  INCLUDE FILES
;***************************************************************************************
	LIST
	include	'synthesizer.asm'

