#
# Generated by the NeXT Project Builder.
#
# NOTE: Do NOT change this file -- Project Builder maintains it.
#
# Put all of your customizations in files called Makefile.preamble
# and Makefile.postamble (both optional), and Makefile will include them.
#

NAME = PrEditor

PROJECTVERSION = 1.1
LANGUAGE = English

APPICON = app.tiff
DOCICONS = dict.tiff

LOCAL_RESOURCES = Document.nib Help.nib Info.nib Inspector.nib\
                  PrDictViewer.nib PrEditor.nib PrefMgr.nib

GLOBAL_RESOURCES = app.tiff Delete.tiff DeleteH.tiff dict.tiff\
                   help.tiff left.tiff max.tiff min.tiff\
                   preditor_logo.tiff right.tiff Shift.tiff ShiftH.tiff\
                   Speak.tiff SpeakH.tiff Store.tiff StoreH.tiff

CLASSES = CustSlider.m CustSliderCell.m EnglishText.m Help.m InfoMgr.m\
          InspectorMgr.m KeyboardController.m KeyboardText.m MyText.m\
          NiftyMatrix.m NiftyMatrixCat.m NiftyMatrixCell.m PrDict.m\
          PrDictViewer.m PrEditorApp.m PrEditorDocument.m PrefMgr.m\
          Speech.m TextFieldCat.m

HFILES = conversion.h hash.h objc-debug.h phone_conversion.h\
         word_types.h CustSlider.h CustSliderCell.h EnglishText.h\
         Help.h InfoMgr.h InspectorMgr.h KeyboardController.h\
         KeyboardText.h MyText.h NiftyMatrix.h NiftyMatrixCat.h\
         NiftyMatrixCell.h PrDict.h PrDictViewer.h PrEditorApp.h\
         PrEditorDocument.h PrefMgr.h Speech.h TextFieldCat.h

MFILES = PrEditor_main.m

CFILES = conversion.c hash.c

OTHERSRCS = AATOC ChangeLog TAGS words


MAKEFILEDIR = /NextDeveloper/Makefiles/app
MAKEFILE = app.make
INSTALLDIR = $(HOME)/Apps
INSTALLFLAGS = -c -s -m 755
SOURCEMODE = 444

ICONSECTIONS =	-sectcreate __ICON app app.tiff \
		-sectcreate __ICON dict dict.tiff

LIBS = -lMedia_s -lNeXT_s -lTextToSpeech -lTextToSpeechPron
DEBUG_LIBS = $(LIBS)
PROF_LIBS = $(LIBS)


-include Makefile.preamble

include $(MAKEFILEDIR)/$(MAKEFILE)

-include Makefile.postamble

-include Makefile.dependencies
