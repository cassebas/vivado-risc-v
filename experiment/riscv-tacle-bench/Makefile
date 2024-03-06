CSV = $(patsubst %.log,%.csv,$(wildcard *.log)) 

default: $(CSV)

%.csv: %.log
	cat $< | awk -f cycles_log2csv.awk > $@

.PHONY: clean
clean:
	@rm -rf $(CSV)
