
DEPEND=graphviz

.PHONY: help
help:
	echo $(DEPEND)
	@echo "avail targets:"
	@echo "    help"
	@echo "    all"
	@echo "    install-dep"

.PHONY: install-dep
install-dep:
	for p in $(DEPEND); do dpkg -s $$p > /dev/null 2>&1 || apt install -y $$p ; done

.PHONY: all
all: install-dep
	make all -C doc/graph
	echo done
