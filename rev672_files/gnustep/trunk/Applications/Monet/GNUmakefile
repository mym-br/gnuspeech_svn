#
#  Copyright (C) 2001, 2002
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

include $(GNUSTEP_MAKEFILES)/common.make

# Subprojects
SUBPROJECTS = Extensions

# The application to be compiled
APP_NAME = Monet

# Main model file
Monet_MAIN_MODEL_FILE = MainMenu.gorm

# The Objective-C source files to be compiled
Monet_OBJC_FILES = \
AppController.m \
EventListView.m \
main.m \
MAIntonationScaleView.m \
MAIntonationScrollView.m \
MAIntonationView.m \
MCommentCell.m \
MDataEntryController.m \
MExtendedTableView.m \
MMDisplayParameter.m \
MOutlineView.m \
MPostureCategoryController.m \
MPostureEditor.m \
MPrototypeManager.m \
MReleaseNotesController.m \
MRuleManager.m \
MRuleTester.m \
MSpecialTransitionEditor.m \
MSynthesisController.m \
MSynthesisParameterEditor.m \
MTransitionEditor.m \
MWindowController.m \
SpecialView.m \
TransitionView.m

# \
#Compatibility/FormulaExpression.m \
#Compatibility/FormulaTerminal.m \
#Compatibility/MMOldFormulaNode.m \
#Compatibility/ParameterList.m \
#Compatibility/RuleList.m \
#Compatibility/SymbolList.m \
#Compatibility/TargetList.m 

#Monet_C_FILES = driftGenerator.c \
#fir.c  \
#input.c \
#output.c \
#ring_buffer.c \
#tube.c \
#util.c \
#wavetable.c

# The Resource files to be copied into the app's resources directory
Monet_RESOURCE_FILES = \
Info.plist \
TODO.txt \
Default.mxml \
SpecialAcronyms.plist \
TTSSuffixList.txt \
2.0eMainDictionary.dict

#Monet_LIB_DIRS = -L../$(GNUSTEP_LIBRARIES_ROOT)

Monet_LANGUAGES = English

Monet_LOCALIZED_RESOURCE_FILES = \
DataEntry.gorm \
Info.gorm \
InfoPlist.strings \
Inspector.gorm \
MainMenu.gorm \
MONET.gorm \
PostureCategory.gorm \
Postures.gorm \
PrototypeManager.gorm \
ReleaseNotes.html \
ReleaseNotes.gorm \
RuleManager.gorm \
RuleTester.gorm \
SpecialTransitionEditor.gorm \
Synthesis.gorm \
SynthesisParameters.gorm \
TransitionEditor.gorm

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
