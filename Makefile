.PHONY: new

new:
	mkdir -p $(name)
	cp .template/* $(name)
