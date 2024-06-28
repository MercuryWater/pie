
DOT=$(wildcard *.dot)
GRAPH=$(foreach f, $(DOT), $(f:.dot=.png))
DOT_FIX_FORMAT=$(foreach f, $(DOT), .$(f).format)

.PHONY: help
help:
	@echo "avail targets:"
	@echo "    help"
	@echo "    all"
	@echo "    clean"
	@echo "    check"

%.png: %.dot
	dot -T png -o $@ $<

.%.dot.format: %.dot
	nop $< > $@

.PHONY: .check-%.dot
.check-%.dot: %.dot
	diff $< .$<.format
	@echo "check ok"

.PHONY: check-format
check: $(DOT_FIX_FORMAT) $(foreach f, $(DOT), .check-$(f))
	@echo done

.PHONY: clean
clean:
	rm -f $(GRAPH) $(DOT_FIX_FORMAT)

.PHONY: all
all: $(GRAPH)
	@echo done
