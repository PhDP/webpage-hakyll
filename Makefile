.PHONY = all clean

all: site

site:
	ghc --make site.hs

clean:
	rm site.hi site.o

