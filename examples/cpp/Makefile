# Example Makefile for building with static DLIB

CC = g++
CFLAGS = -std=c++14 -O3 -I../../root/usr/include
LDFLAGS = -L../../root/usr/lib -L../../root/usr/lib64 -static
LIBS = -ldlib -lpthread -llapack -lcblas -lblas -ljpeg -lgif -lpng -lz -lgfortran

TARGETS = face_detect

all: $(TARGETS)

face_detect: face_detect.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS) $(LIBS)

clean:
	rm -f $(TARGETS)

.PHONY: all clean
