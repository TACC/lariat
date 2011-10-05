CC  := mpicc
CXX := mpicxx
F77 := mpif77
F90 := mpif90
FC  := mpif90

OBJ := $(TARG)/


EXEC := $(OBJ)helloCXX $(OBJ)helloC $(OBJ)helloF90 $(OBJ)helloF77



all: $(OBJ) $(EXEC)

$(OBJ):
	mkdir -p $(OBJ)

$(OBJ)helloC: helloC.o
	$(LINK.C)  -o $@ $<

$(OBJ)helloC.o: helloC.c
	$(COMPILE.c)  -o $@ $<

$(OBJ)helloCXX: $(OBJ)helloCXX.o
	$(LINK.cc) -o $@ $<

$(OBJ)helloCXX.o: helloCXX.C
	$(COMPILE.cc) -o $@ $<

$(OBJ)helloF90: $(OBJ)helloF90.o
	$(LINK.f) -o $@ $<

$(OBJ)helloF77: $(OBJ)helloF77.o
	$(F77) -o $@ $<

$(OBJ)helloF90.o: helloF90.f90
	$(F90) -FR -o $@ -c $<

$(OBJ)helloF77.o: helloF77.f
	$(F77) -o $@ -c $< 

neat:
	$(RM) *~
clean: neat
	$(RM) $(OBJ)*.o
clobber: clean
	$(RM) $(EXEC)




