#
#    Filename:	Makefile 
#    Created :	Fri Aug  6 14:03:15 1993 
#    Author  :	Dale Brisinda
#		<dale@pegasus.cuc.ab.ca>
#
#    Last modified on "Fri Nov 17 12:36:26 1995"
#

# Copying a library results in the time for the library being newer than the
# time for the linkable object code files. Therefore, we must run ranlib on the
# library to update it. We use the -t option to simply touch the object code
# files with the current time, thus updating the entire library. Alternatively,
# we can use libtool which is intended to replace ar and ranlib.

# Note: We use the strip options to remove all local symbols and save any 
# undefined symbols.

# Note: Be careful when modifying macros. The macros that one may have reason
# to change are set apart from the macro definition and appear first. The
# remaining macros should not be changed unless you know *precisely* what the
# effects will be.

TK_DEMO	    = 	TabletKit-1.1_DEMO
TK_LICENSE  =   TabletKit-1.1
ARCHS       =   -arch m68k -arch i386 #-arch hppa -arch sparc
PATH        =	/Users/dale/Projects/TabletKit

#
# Macros beyond this point should not be changed. Invoke "make dist" for a
# licensed distribution and "make dist-demo" for a demo distribution.
#

MAIN        =	TabletKit
DEMO   	    =	NO
RM_DEMO	    =	README_Demo
RM_INSTALL  = 	README_Install
HDIR        =	tabletkit
MM          =	SummaMMBinaryReader
UIOF        =	SummaUIOFBinaryReader
LIB	    =	libtabletkit.a
CLASSES     =	TabletDriver.m
HFILES	    =	TabletDriver.h TabletReader.h
OFILES	    = 	
CFLAGS	    =	-g -O -c -Wall -ObjC $(ARCHS)
LIBS	    =	
EXAMPLE_APP =	PenDraw
BUNDLE_PREF =	Summa

$(MAIN)::	$(MFILES) $(HFILES) $(CFILES)
		cc $(CFLAGS) $(CLASSES)
		/bin/libtool -o $(LIB) *.o

install::	$(MAIN)
		strip -A -u -x $(LIB) ; \
		if [ "$(DEMO)" = "NO" ] ; then \
			cp $(LIB) $(MAIN).root/LocalDeveloper/Libraries ; \
		fi ; \
		cp *.h $(MAIN).root/LocalDeveloper/Headers/$(HDIR)
#
# make and install tablet reader bundles (strip options taken from PB Makefile.postamble)
#
		cd $(MM) ; make bundle "OTHER_CFLAGS = $(ARCHS)" ; strip -x -u $(MM).bundle/$(MM)
		cd $(UIOF) ; make bundle "OTHER_CFLAGS = $(ARCHS)" ; strip -x -u $(UIOF).bundle/$(UIOF)
		chmod 755 $(MM) \
			  $(UIOF) \
			  $(BUNDLE_PREF)*/$(BUNDLE_PREF)*.bundle \
			  $(BUNDLE_PREF)*/$(BUNDLE_PREF)*.bundle/English.lproj \
			  $(BUNDLE_PREF)*/$(BUNDLE_PREF)*.bundle/$(BUNDLE_PREF)* ; \
		cp -r $(BUNDLE_PREF)*/$(BUNDLE_PREF)*.bundle $(MAIN).root/LocalLibrary/TabletReaders ; \
		cp -r $(BUNDLE_PREF)* $(MAIN).root/LocalDeveloper/Examples/TabletKit
#
# install documentation
#
		/bin/rm -f Documentation/*~ \
			   Documentation/Classes/*~ \
			   Documentation/Protocols/*~ ; \
		chmod 755 Documentation \
			  Documentation/Classes \
			  Documentation/Protocols ; \
		cp -r Documentation/* $(MAIN).root/LocalDeveloper/Documentation/$(MAIN)
#
# install example application source code (include stripped executable for demo version)
#
		cd $(EXAMPLE_APP) ; make clean
		if [ "$(DEMO)" = "YES" ] ; then \
			cd $(EXAMPLE_APP) ; make app "OTHER_CFLAGS = $(ARCHS)" ; \
			strip -A -n $(EXAMPLE_APP).app/$(EXAMPLE_APP) ; \
			/bin/rm -rf ./*_obj ./sym ; \
		fi
		cp -r $(EXAMPLE_APP) $(MAIN).root/LocalDeveloper/Examples/TabletKit
#
# remove unnecessary directories and files from root installation
#
		/bin/rm -rf $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(BUNDLE_PREF)*/Backup \
			    $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(BUNDLE_PREF)*/RCS \
			    $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(BUNDLE_PREF)*/*_obj \
			    $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(BUNDLE_PREF)*/sym \
			    $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(BUNDLE_PREF)*/$(BUNDLE_PREF)*.bundle \
			    $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(EXAMPLE_APP)/Backup \
			    $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(EXAMPLE_APP)/NeXTanswer \
			    $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(EXAMPLE_APP)/TIFF \
			    $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(EXAMPLE_APP)/RCS ; \
		if [ "$(DEMO)" = "NO" ] ; then \
			/bin/rm -rf $(MAIN).root/LocalDeveloper/Examples/TabletKit/$(EXAMPLE_APP)/$(EXAMPLE_APP).app ; \
		elif [ "$(DEMO)" = "YES" ] ; then \
			/bin/rm -rf $(MAIN).root/LocalDeveloper/Libraries/$(LIB) ; \
		fi

package::	install
		chmod -R a+r $(MAIN).root ; \
		if [ "$(DEMO)" = "NO" ] ; then \
			/bin/rm -rf $(MAIN).pkg ; \
		elif [ "$(DEMO)" = "YES" ] ; then \
			/bin/rm -rf $(MAIN)_DEMO.pkg ; \
		fi ; \
		/NextAdmin/Installer.app/package -B $(MAIN).root $(MAIN).info $(MAIN).tiff -d . ; \
                chmod 755 $(MAIN).pre_*; \
		chmod 755 $(MAIN).post_* ; \
                cp $(MAIN).pre_* $(MAIN).pkg; \
		cp $(MAIN).post_* $(MAIN).pkg ; \
		if [ "$(DEMO)" = "YES" ] ; then \
			mv $(MAIN).pkg $(MAIN)_DEMO.pkg ; \
			cd $(MAIN)_DEMO.pkg ; \
                        mv $(MAIN).pre_install $(MAIN)_DEMO.pre_install; \
			mv $(MAIN).post_delete $(MAIN)_DEMO.post_delete ; \
			mv $(MAIN).post_install $(MAIN)_DEMO.post_install ; \
			mv $(MAIN).bom $(MAIN)_DEMO.bom ; \
			mv $(MAIN).sizes $(MAIN)_DEMO.sizes ; \
			mv $(MAIN).tiff $(MAIN)_DEMO.tiff ; \
			mv $(MAIN).info $(MAIN)_DEMO.info ; \
			mv $(MAIN).tar.Z $(MAIN)_DEMO.tar.Z ; \
		fi

package-demo::
		if [ -d "$(MAIN).pkg" ] ; then \
			mv $(MAIN).pkg $(MAIN).pkg.tmp ; \
			make package "DEMO = YES" ; \
			mv $(MAIN).pkg.tmp $(MAIN).pkg ; \
		else \
			make package "DEMO = YES" ; \
		fi

#
# This is the target for the full (licensed) package distribution.
#
dist::		package
		/bin/rm -rf $(TK_LICENSE) ; \
		/bin/mkdir $(TK_LICENSE) ; \
		cp -r $(MAIN).pkg $(TK_LICENSE) ; \
		cp $(RM_INSTALL) $(TK_LICENSE) ; \
		/usr/bin/gnutar cvf $(TK_LICENSE).NIHS.tar $(TK_LICENSE)
		/usr/bin/gzip $(TK_LICENSE).NIHS.tar
#
# This is the target for the DEMO package distribution.
#
dist-demo::	package-demo
		/bin/rm -rf $(TK_DEMO) ; \
		/bin/mkdir $(TK_DEMO) ; \
		cp -r $(MAIN)_DEMO.pkg $(TK_DEMO) ; \
		cp $(RM_DEMO) $(TK_DEMO) ; \
		cp $(RM_INSTALL) $(TK_DEMO) ; \
		/usr/bin/gnutar cvf $(TK_DEMO).NIHS.tar $(TK_DEMO) ; \
		/usr/bin/gzip $(TK_DEMO).NIHS.tar ; \
		cp $(RM_DEMO) $(TK_DEMO).NIHS.README

clean::
		/bin/rm -f *.o *.a \
			   $(MAIN).root/LocalDeveloper/Headers/$(HDIR)/* \
			   $(MAIN).root/LocalDeveloper/Libraries/* ; \
		/bin/rm -rf $(MAIN).root/LocalDeveloper/Examples/$(MAIN)/* \
			    $(MAIN).root/LocalDeveloper/Documentation/$(MAIN)/* \
			    $(MAIN).root/LocalLibrary/TabletReaders/*
		/bin/rm -rf $(MAIN).pkg $(MAIN)_DEMO.pkg $(TK_DEMO) $(TK_LICENSE)
		cd $(MM) ; make clean
		cd $(UIOF) ; make clean
		cd $(EXAMPLE_APP); make clean
