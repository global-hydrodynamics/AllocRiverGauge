#==========================================================
include   ../../../adm/Mkinclude

#=============================
TARGETS=\
allocate_flow_gauge \
allocate_level_gauge \
allocate_dam

all: $(TARGETS)

clean:
	$(RM) -rf *.o *.s core *~ *trace *.mod *.dSYM  $(TARGETS)

#=============================
.SUFFIXES : .F90
.F90:
	$(FC) $(FFLAGS) $(LFLAG) $(INC) $^ -o $@

.SUFFIXES : .f90
.f90:
	$(FC) ${FFLAGS} $^ -o $@
