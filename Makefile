.PHONY = all clean

all: Main

Main:
	ghc --make Main.hs

clean:
	rm site.hi site.o

