# st - simple terminal
# See LICENSE file for copyright and license details.
.POSIX:

include config.mk

SRC_DIR := src
SRC     := $(SRC_DIR)/st.c $(SRC_DIR)/x.c $(SRC_DIR)/boxdraw.c $(SRC_DIR)/hb.c
OBJ     := $(notdir $(SRC:.c=.o))
UNAME   := $(shell uname)

ifeq ($(UNAME), Linux)
	INSTALL_TARGET := install_linux
else
	INSTALL_TARGET := install_openbsd
endif

.PHONY: all
all: options st

.PHONY: options
options:
	@echo st build options:
	@echo "CFLAGS  = $(STCFLAGS)"
	@echo "LDFLAGS = $(STLDFLAGS)"
	@echo "CC      = $(CC)"

%.o : $(SRC_DIR)/%.c
	$(CC) $(STCFLAGS) -c $<

st.o: src/config.h src/st.h src/win.h
x.o: src/arg.h src/config.h src/st.h src/win.h src/hb.h
hb.o: src/st.h
boxdraw.o: src/config.h src/st.h src/boxdraw_data.h

$(OBJ): src/config.h config.mk

st: $(OBJ)
	$(CC) -o $@ $(OBJ) $(STLDFLAGS)

.PHONY: clean
clean:
	rm -f st $(OBJ) st-$(VERSION).tar.gz *.o *.orig *.rej

.PHONY: dist
dist: clean
	@echo "Packaging tarball for release: st-$(VERSION)"
	mkdir -p st-$(VERSION)
	cp -R LICENSE Makefile README.md config.mk\
		st.info st.1 src/arg.h src/st.h src/win.h $(SRC)\
		st-$(VERSION)
	tar -cf - st-$(VERSION) | gzip > st-$(VERSION).tar.gz
	rm -rf st-$(VERSION)
	@echo "Created new dist tarball: $(shell readlink -f st-$(VERSION).tar.gz)"

.PHONY: install
install:
	make $(INSTALL_TARGET)

.PHONY: install_linux
install_linux: st
	@echo "Installing using Linux flags"
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f st $(DESTDIR)$(PREFIX)/bin
	cp -f st-copyout $(DESTDIR)$(PREFIX)/bin
	cp -f st-urlhandler $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/st
	chmod 755 $(DESTDIR)$(PREFIX)/bin/st-copyout
	chmod 755 $(DESTDIR)$(PREFIX)/bin/st-urlhandler
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	sed "s/VERSION/$(VERSION)/g" < st.1 > $(DESTDIR)$(MANPREFIX)/man1/st.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/st.1
	tic -sx st.info
	@echo "Please see the README.md file regarding the terminfo entry of st."

.PHONY: install_openbsd
install_openbsd: st
	@echo "Installing using OpenBSD flags"
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f st $(DESTDIR)$(PREFIX)/bin
	cp -f st-copyout $(DESTDIR)$(PREFIX)/bin
	cp -f st-urlhandler $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/st
	chmod 755 $(DESTDIR)$(PREFIX)/bin/st-copyout
	chmod 755 $(DESTDIR)$(PREFIX)/bin/st-urlhandler
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	sed "s/VERSION/$(VERSION)/g" < st.1 > $(DESTDIR)$(MANPREFIX)/man1/st.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/st.1
	sed 's/st\([^t].*\)/st-git\1/g' st.info > st-git.info
	tic -s st-git.info
	@echo "Please see the README file regarding the terminfo entry of st."

.PHONY: uninstall
uninstall:
	@echo "Uninstalling st."
	rm -f $(DESTDIR)$(PREFIX)/bin/st
	rm -f $(DESTDIR)$(PREFIX)/bin/st-copyout
	rm -f $(DESTDIR)$(PREFIX)/bin/st-urlhandler
	rm -f $(DESTDIR)$(MANPREFIX)/man1/st.1
	@echo "Uninstallation complete!"
