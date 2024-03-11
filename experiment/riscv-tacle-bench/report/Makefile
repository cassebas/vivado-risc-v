DOC_NAME=execution-cycles
DOC_VERS=v1.0
DOC=$(DOC_NAME)-$(DOC_VERS).pdf
MAIN=execution-cycles
TEX=$(MAIN).tex
AUX=$(MAIN).aux
PDF=$(MAIN).pdf
BBL=$(MAIN).bbl
BIB=thebibliography.bib

$(PDF): $(TEX)
	latexmk -pdf -pdflatex="pdflatex -shell-escape -interaction=nonstopmode" -use-make $(TEX)
	cp -p $@ $(DOC)

.PHONY: clean
clean:
	latexmk -CA
