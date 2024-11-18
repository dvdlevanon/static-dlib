# Example Makefile for building with static DLIB

CC = g++
CFLAGS = -std=c++14 -O3 -I../../root/usr/include
LDFLAGS = -L../../root/usr/lib -L../../root/usr/lib64 -static
LIBS = -ldlib -lpthread -llapack -lcblas -lblas -ljpeg -lgif -lpng -lz -lgfortran

TARGETS = face_recognition

# Model files and URLs
SHAPE_PREDICTOR_URL = http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2
RECOGNITION_MODEL_URL = http://dlib.net/files/dlib_face_recognition_resnet_model_v1.dat.bz2
SHAPE_PREDICTOR = shape_predictor_68_face_landmarks.dat
RECOGNITION_MODEL = dlib_face_recognition_resnet_model_v1.dat

all: $(TARGETS) models

# Build targets
face_recognition: face_recognition.cpp
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS) $(LIBS)

# Model downloads
.downloaded_shape_predictor:
	wget -O $(SHAPE_PREDICTOR).bz2 $(SHAPE_PREDICTOR_URL)
	touch $@

.downloaded_recognition_model:
	wget -O $(RECOGNITION_MODEL).bz2 $(RECOGNITION_MODEL_URL)
	touch $@

$(SHAPE_PREDICTOR): .downloaded_shape_predictor
	if [ ! -f $(SHAPE_PREDICTOR) ]; then bunzip2 -k $(SHAPE_PREDICTOR).bz2; rm $(SHAPE_PREDICTOR).bz2; fi

$(RECOGNITION_MODEL): .downloaded_recognition_model
	if [ ! -f $(RECOGNITION_MODEL) ]; then bunzip2 -k $(RECOGNITION_MODEL).bz2; rm $(RECOGNITION_MODEL).bz2; fi

.PHONY: models
models: $(SHAPE_PREDICTOR) $(RECOGNITION_MODEL)

clean:
	rm -f $(TARGETS)
	rm -f *.dat *.bz2 .downloaded_*

.PHONY: all clean models
