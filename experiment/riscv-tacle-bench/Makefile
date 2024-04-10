REPORT_DIR = report
DATA_DIR   = $(REPORT_DIR)/data

BENCHMARKS = adpcm_dec \
             adpcm_enc \
             ammunition \
             anagram \
             audiobeam \
             cjpeg_transupp \
             cjpeg_wrbmp \
             dijkstra \
             epic \
             fmref \
             g723_enc \
             gsm_dec \
             gsm_enc \
             h264_dec \
             huff_dec \
             huff_enc \
             mpeg2 \
             ndes \
             petrinet \
             rijndael_dec \
             rijndael_enc \
             statemate \
             susan

CSV_RAW = $(patsubst %.log,%.csv,$(wildcard *.log))
CSV_COMPLETE = $(wildcard $(DATA_DIR)/rv32-complete-*.csv)
CSV_EXP1 = $(foreach bench,$(BENCHMARKS),$(DATA_DIR)/rv32-experiment-$(bench)-1-i128b.csv)
CSV_EXP2 = $(foreach bench,$(BENCHMARKS),$(DATA_DIR)/rv32-experiment-$(bench)-2-d128b.csv)
CSV_EXP3 = $(foreach bench,$(BENCHMARKS),$(DATA_DIR)/rv32-experiment-$(bench)-3.csv)
CSV_EXP4 = $(foreach bench,$(BENCHMARKS),$(DATA_DIR)/rv32-experiment-$(bench)-4-i128b.csv)
CSV_PROCESSED = $(CSV_COMPLETE) $(CSV_EXP1) $(CSV_EXP2) $(CSV_EXP3) $(CSV_EXP4)
CSV_ALL = $(CSV_RAW) $(CSV_PROCESSED)

TEX_EXP1 = $(patsubst %-i128b.csv,%.tex,$(CSV_EXP1))
TEX_EXP2 = $(patsubst %-d128b.csv,%.tex,$(CSV_EXP2))
TEX_EXP3 = $(patsubst %.csv,%.tex,$(CSV_EXP3))
TEX_EXP1_CW = $(patsubst %-i128b.csv,%_cw.tex,$(CSV_EXP1))
TEX_EXP2_CW = $(patsubst %-d128b.csv,%_cw.tex,$(CSV_EXP2))
TEX_EXP4_CWA = $(patsubst %-i128b.csv,%_cwa.tex,$(CSV_EXP4))

TEX_EXP1_FIGURES=$(REPORT_DIR)/figures-experiment1.tex
TEX_EXP2_FIGURES=$(REPORT_DIR)/figures-experiment2.tex
TEX_EXP1_FIGURES_CW=$(REPORT_DIR)/figures-experiment1_cw.tex
TEX_EXP2_FIGURES_CW=$(REPORT_DIR)/figures-experiment2_cw.tex
TEX_EXP4_FIGURES_CWA=$(REPORT_DIR)/figures-experiment4_cwa.tex
TEX_EXP_FIGURES=$(TEX_EXP1_FIGURES) $(TEX_EXP2_FIGURES) $(TEX_EXP1_FIGURES_CW) $(TEX_EXP2_FIGURES_CW) $(TEX_EXP4_FIGURES_CWA)

TEX_ALL = $(TEX_EXP1) $(TEX_EXP1_CW) $(TEX_EXP2) $(TEX_EXP2_CW) $(TEX_EXP3) $(TEX_EXP4_CWA) $(TEX_EXP_FIGURES)

default: $(TEX_EXP_FIGURES)

$(CSV_PROCESSED) &: $(CSV_RAW) $(DATA_DIR)
	python split-benchmarks.py --input-dir=. --output-dir=$(DATA_DIR)
	python select-measurements.py --input-dir=$(DATA_DIR) --output-dir=$(DATA_DIR)

%.csv: %.log
	cat $< | awk -f cycles_log2csv.awk > $@

$(TEX_EXP1): $(CSV_EXP1)
	$(eval TEX := $(patsubst %-i128b.csv,%.tex,$@))
	$(eval BENCH := `echo $(TEX)|sed 's/^.*-experiment-\([^-]*\)-.*/\1/'`)
	@echo "Working on experiment 1, benchmark=$(BENCH)"
	m4 -Dbenchmark=$(BENCH) \
	   -Dcachesize=128b     \
	   -Dexp_nr=1           \
	   cycles2pgfplots.m4 > $@

$(TEX_EXP2): $(CSV_EXP2)
	$(eval TEX := $(patsubst %-d128b.csv,%.tex,$@))
	$(eval BENCH := `echo $(TEX)|sed 's/^.*-experiment-\([^-]*\)-.*/\1/'`)
	@echo "Working on experiment 2, benchmark=$(BENCH)"
	m4 -Dbenchmark=$(BENCH) \
	   -Dcachesize=128b     \
	   -Dexp_nr=2           \
	   cycles2pgfplots.m4 > $@

$(TEX_EXP1_CW): $(CSV_EXP1)
	$(eval TEX := $(patsubst %-i128b.csv,%_cw.tex,$@))
	$(eval BENCH := `echo $(TEX)|sed 's/^.*-experiment-\([^-]*\)-.*/\1/'`)
	@echo "Working on experiment 1 cold-warm, benchmark=$(BENCH)"
	m4 -Dbenchmark=$(BENCH) \
	   -Dcachesize=4k       \
	   -Dexp_nr=1           \
	   cycles2pgfplots_coldwarm.m4 > $@

$(TEX_EXP2_CW): $(CSV_EXP2)
	$(eval TEX := $(patsubst %-d128b.csv,%_cw.tex,$@))
	$(eval BENCH := `echo $(TEX)|sed 's/^.*-experiment-\([^-]*\)-.*/\1/'`)
	@echo "Working on experiment 2 cold-warm, benchmark=$(BENCH)"
	m4 -Dbenchmark=$(BENCH) \
	   -Dcachesize=4k       \
	   -Dexp_nr=2           \
	   cycles2pgfplots_coldwarm.m4 > $@

$(TEX_EXP3): $(CSV_EXP3)
	$(eval TEX := $(patsubst %.csv,%.tex,$@))
	$(eval BENCH := `echo $(TEX)|sed 's/^.*-experiment-\([^-]*\)-.*/\1/'`)
	@echo "Working on experiment 3, benchmark=$(BENCH)"
	m4 -Dbenchmark=$(BENCH) \
	   -Dcachesize=128b     \
	   -Dexp_nr=1           \
	   cycles2pgfplots.m4 > $@

$(TEX_EXP4_CWA): $(CSV_EXP4)
	$(eval TEX := $(patsubst %-i128b.csv,%_cwa.tex,$@))
	$(eval BENCH := `echo $(TEX)|sed 's/^.*-experiment-\([^-]*\)-.*/\1/'`)
	@echo "Working on experiment 4 cold-warm-attack, benchmark=$(BENCH)"
	m4 -Dbenchmark=$(BENCH) \
	   -Dcachesize=128b     \
	   -Dexp_nr=4           \
	   cycles2pgfplots_coldwarmattack.m4 > $@

$(TEX_EXP1_FIGURES): $(TEX_EXP1)
	@echo $^ | \
		tr " " "\n" | \
		sed 's/^report\///' | \
		awk '{printf("\\input{%s}\n", $$1)}' | sort -n | \
		awk '{printf("%s\n\\clearpage\n", $$0)}' > $@

$(TEX_EXP2_FIGURES): $(TEX_EXP2)
	@echo $^ | \
		tr " " "\n" | \
		sed 's/^report\///' | \
		awk '{printf("\\input{%s}\n", $$1)}' | sort -n | \
		awk '{printf("%s\n\\clearpage\n", $$0)}' > $@

$(TEX_EXP1_FIGURES_CW): $(TEX_EXP1_CW)
	@echo $^ | \
		tr " " "\n" | \
		sed 's/^report\///' | \
		awk '{printf("\\input{%s}\n", $$1)}' | sort -n | \
		awk '{printf("%s\n\\clearpage\n", $$0)}' > $@

$(TEX_EXP2_FIGURES_CW): $(TEX_EXP2_CW)
	@echo $^ | \
		tr " " "\n" | \
		sed 's/^report\///' | \
		awk '{printf("\\input{%s}\n", $$1)}' | sort -n | \
		awk '{printf("%s\n\\clearpage\n", $$0)}' > $@

$(TEX_EXP4_FIGURES_CWA): $(TEX_EXP4_CWA)
	@echo $^ | \
		tr " " "\n" | \
		sed 's/^report\///' | \
		awk '{printf("\\input{%s}\n", $$1)}' | sort -n | \
		awk '{printf("%s\n\\clearpage\n", $$0)}' > $@

$(DATA_DIR):
	@mkdir -p $@

.PHONY: clean
clean:
	@rm -rf $(CSV_ALL) $(TEX_ALL)
