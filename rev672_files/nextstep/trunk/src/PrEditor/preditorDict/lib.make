#*
#*    Filename:	lib-make
#*    Created :	Mon Feb 24 00:07:05 1992 
#*    Author  :	Vince DeMarco
#*		<vince@whatnxt.cuc.ab.ca>
#*
#* LastEditDate was "Sat Mar 28 21:47:50 1992"

.c.o: ; $(CC) $(CFLAGS) -c $*.c -o $(OFILE_DIR)/$*.o
.m.o: ; $(CC) $(CFLAGS) -c $*.m -o $(OFILE_DIR)/$*.o

CFLAGS    = -pipe -O -g -Wall
ETAGS     = etags 
OFILE_DIR = obj
VPATH     = $(OFILE_DIR)

$(LIBNAME) : $(OFILE_DIR) $(OFILES)
	ar rc $@ $(OFILES); ranlib -s $@

$(OFILE_DIR) : $(OFILE_DIR)
	@mkdir $(OFILE_DIR)

clean ::
	@rm -rf $(OFILE_DIR) $(LIBNAME) 

TAGS : $(CLASSES) $(MFILES) $(CFILES) $(HFILES)
	$(ETAGS) -tw $(CLASSES) $(MFILES) $(CFILES) $(HFILES)

depend : Makefile.dependencies

Makefile.dependencies::  $(CLASSES) $(MFILES) $(CFILES)
	$(CC) -MM $(CFLAGS) $(CLASSES) $(MFILES) $(CFILES) | \
	awk '{ if ($$1 != prev) { if (rec != "") print rec; \
	rec = $$0; prev = $$1; } \
	else { if (length(rec $$2) > 78) { print rec; rec = $$0; } \
	else rec = rec " " $$2 } } \
	END { print rec }' > Makefile.dependencies
