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

# The application to be compiled
APP_NAME = PreMo

# Main model file
PreMo_MAIN_MODEL_FILE = MainMenu.gorm

# The Objective-C source files to be compiled
PreMo_OBJC_FILES = \
ApplicationDelegate.m \
main.m

# The Resource files to be copied into the app's resources directory
PreMo_RESOURCE_FILES = \
Info.plist \
SpecialAcronyms.plist \
TTSSuffixList.txt \
version.plist \
English.lproj/InfoPlist.strings \
English.lproj/locversion.plist \
English.lproj/MainMenu.gorm \
2.0eMainDictionary.dict

#PreMo_LIB_DIRS = -L../$(GNUSTEP_LIBRARIES_ROOT)

PreMo_LANGUAGES = English

#PreMo_LOCALIZED_RESOURCE_FILES = Localizable.strings

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
