CC = /usr/bin/g++
CFLAGS = -lgsl -lgslcblas -DHAVE_INLINE -pthread -Wall -O3

all: hebe distance pair_distance

distance : distance.c 
	$(CC) distance.c -o distance $(CFLAGS)

pair_distance : pair_distance.c
	$(CC) pair_distance.c -o pair_distance $(CFLAGS)

hebe : hebe.c
	$(CC) hebe.c -o hebe $(CFLAGS)

clean:
	rm -rf hebe pair_distance distance
