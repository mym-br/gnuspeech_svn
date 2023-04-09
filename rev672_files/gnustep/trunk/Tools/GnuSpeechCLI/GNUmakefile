
include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = GnuSpeechCLI
GnuSpeechCLI_HAS_RESOURCE_BUNDLE = yes

GnuSpeechCLI_OBJC_FILES = \
main.m \
PhoneToSpeech.m \
TextToPhone.m \
TextToSpeech.m

GnuSpeechCLI_RESOURCE_FILES = \
2.0eMainDictionary.dict \
SpecialAcronyms.plist \
TTSSuffixList.txt \
diphones.mxml \
config.plist \
gnuspeechcli.sh

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
