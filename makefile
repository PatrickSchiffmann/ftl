# disable default implicit rules
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

PLATFORM ?= gnu
BUILD    ?= debug
BUILDDIR = build.$(PLATFORM).$(BUILD)

ifeq ($(PLATFORM), gnu)
	COMPILER = gfortran
	FLAGS = -std=f2003 -ffree-line-length-none -Wall -Wextra -Wpedantic -Wno-target-lifetime -Wno-surprising -J$(BUILDDIR)
	CXXCOMPILER = g++
	CXXFLAGS = -std=c++11 -Ofast -march=native
else ifeq ($(PLATFORM), intel)
	COMPILER = ifort
	FLAGS = -stand f03 -warn -module $(BUILDDIR)
	CXXCOMPILER = icpc
	CXXFLAGS = -std=c++11 -fast -xHost
else
  $(error unrecognized PLATFORM)
endif

INCLUDES = -Isrc -Itests

ifeq ($(PLATFORM)$(BUILD), gnudebug)
	FLAGS += -g -O0 -fcheck=bounds,do,mem,pointer,recursion
else ifeq ($(PLATFORM)$(BUILD), inteldebug)
	FLAGS += -g -O0 -check all -debug all -traceback
else ifeq ($(PLATFORM)$(BUILD), gnurelease)
	FLAGS += -Ofast -march=native -flto
else ifeq ($(PLATFORM)$(BUILD), intelrelease)
	FLAGS += -fast -xHost
else
  $(error unrecognized BUILD)
endif

# option to disable the use of finalizers (in case your compiler can't handle them ...)
ifeq ($(FINALIZERS), skip)
	FLAGS += -DFTL_NO_FINALIZERS
endif


test: $(BUILDDIR)/tests
	./$(BUILDDIR)/tests

memcheck: $(BUILDDIR)/tests
	valgrind --leak-check=yes ./$(BUILDDIR)/tests

perftest: $(BUILDDIR)/perftest_sortVectorInt $(BUILDDIR)/perftest_sortVectorInt_ref $(BUILDDIR)/perftest_sortVectorBigType
	./$(BUILDDIR)/perftest_sortVectorBigType
	./$(BUILDDIR)/perftest_sortVectorInt
	./$(BUILDDIR)/perftest_sortVectorInt_ref

$(BUILDDIR):
	mkdir $(BUILDDIR)


$(BUILDDIR)/tests: tests/tests.F90 $(BUILDDIR)/ftlTestTools.o $(BUILDDIR)/ftlVectorTests.o $(BUILDDIR)/ftlListTests.o $(BUILDDIR)/ftlAlgorithmsTests.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) $< $(BUILDDIR)/*.o -o $@

$(BUILDDIR)/ftlTestTools.o: tests/ftlTestTools.F90 tests/ftlTestTools.inc | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/ftlVectorTests.o: tests/ftlVectorTests.F90 $(BUILDDIR)/ftlVectorInt.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/ftlVectorInt.o: instantiations/ftlVectorInt.F90 src/ftlVector.F90_template | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/ftlListTests.o: tests/ftlListTests.F90 $(BUILDDIR)/ftlListInt.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/ftlListInt.o: instantiations/ftlListInt.F90 src/ftlList.F90_template | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/ftlAlgorithmsTests.o: tests/ftlAlgorithmsTests.F90 $(BUILDDIR)/ftlVectorIntAlgorithms.o $(BUILDDIR)/ftlListIntAlgorithms.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/ftlVectorIntAlgorithms.o: instantiations/ftlVectorIntAlgorithms.F90 src/ftlAlgorithms.F90_template $(BUILDDIR)/ftlVectorInt.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/ftlListIntAlgorithms.o: instantiations/ftlListIntAlgorithms.F90 src/ftlAlgorithms.F90_template $(BUILDDIR)/ftlListInt.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/BigType.o: instantiations/derived_types/BigType.F90 $(BUILDDIR)/ftlTestTools.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/ftlVectorBigType.o: instantiations/ftlVectorBigType.F90 src/ftlVector.F90_template $(BUILDDIR)/BigType.o  | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILDDIR)/ftlVectorBigTypeAlgorithms.o: instantiations/ftlVectorBigTypeAlgorithms.F90 src/ftlAlgorithms.F90_template $(BUILDDIR)/ftlVectorBigType.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) -c $< -o $@


$(BUILDDIR)/perftest_sortVectorInt: perftests/sortVectorInt.F90 $(BUILDDIR)/ftlTestTools.o $(BUILDDIR)/ftlVectorIntAlgorithms.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) $< $(BUILDDIR)/*.o -o $@

$(BUILDDIR)/perftest_sortVectorInt_ref: perftests/sortVectorInt.cpp | $(BUILDDIR)
	$(CXXCOMPILER) $(CXXFLAGS) $< -o $@

$(BUILDDIR)/perftest_sortVectorBigType: perftests/sortVectorBigType.F90 $(BUILDDIR)/ftlTestTools.o $(BUILDDIR)/ftlVectorBigTypeAlgorithms.o | $(BUILDDIR)
	$(COMPILER) $(FLAGS) $(INCLUDES) $< $(BUILDDIR)/*.o -o $@


clean:
	rm -rf $(BUILDDIR)

cleanall:
	rm -rf build.*
