# Makefile used to build mex files

TARGETS = all clean
.PHONY: $(TARGETS)

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
endif

MATMEX = mex
MEX = $(MATMEX)
CXXFLAGS = -O

LIBRT=

MEXSUFFIX=$(shell mexext)

all: rgbselect.$(MEXSUFFIX) 

16a: MATMEX=/Applications/MATLAB_R2016a.app/bin/mex
16a: all

16b: MATMEX=/Applications/MATLAB_R2016b.app/bin/mex
16b: all

15b: MATMEX=/Applications/MATLAB_R2015b.app/bin/mex
15b: all

15a: MATMEX=/Applications/MATLAB_R2015a.app/bin/mex
15a: all

14a: MATMEX=/Applications/MATLAB_R2014a.app/bin/mex
14a: all

14b: MATMEX=/Applications/MATLAB_R2014b.app/bin/mex
14b: all

13a: MATMEX=/Applications/MATLAB_R2013a.app/bin/mex
13a: all

13b: MATMEX=/Applications/MATLAB_R2013b.app/bin/mex
13b: all

%.$(MEXSUFFIX): %.cc
	$(MEX) $(CXXFLAGS) $<

%.$(MEXSUFFIX): %.c
	$(MEX) $(CXXFLAGS) $<

rgbselect.$(MEXSUFFIX): rgbselect.cc 
	$(MEX) $(CXXFLAGS) $^ $(LIBRT)

clean:
	rm -f *.$(MEXSUFFIX) *.o
