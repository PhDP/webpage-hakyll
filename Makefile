.PHONY = all clean

all: Main

Main:
	ghc --make Main.hs

clean:
	rm Main.hi Main.o

