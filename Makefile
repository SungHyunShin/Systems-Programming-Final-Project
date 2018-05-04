CC=		gcc
CFLAGS=		-g -gdwarf-2 -Wall -Werror -std=gnu99
LD=		gcc
LDFLAGS=	-L.
AR=		ar
ARFLAGS=	rcs
TARGETS=	spidey

all:		$(TARGETS)

clean:
	@echo Cleaning...
	@rm -f $(TARGETS) *.o *.log *.input

.SUFFIXES:


%.o : %.c 	spidey.h
	@echo Compiling $@...
	@$(CC) $(CFLAGS) -o $@ -c $<


spidey: forking.o handler.o request.o single.o socket.o spidey.o utils.o
	@echo Compiling $@...
	@$(LD) $(LDFLAGS) -o $@ $^




.PHONY:		all test benchmark clean
