#==========================================================
include   ../adm/Mkinclude

#=============================
TARGETS=\
alloc_gauge_latlon_area \
alloc_gauge_latlon_only \
check_gauge_latlon_area \
alloc_gauge_latlon_areamix \

all: $(TARGETS)

#=============================
clean:
	$(RM) -rf *.o *.s core *~ *trace *.mod *.dSYM  $(TARGETS)

.SUFFIXES : .f90
.f90:
	$(FC) ${FFLAGS} $^ -o $@
