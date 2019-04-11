NAME = mcp

.PHONY: control

all: test

remove:
	rm -fr /usr/lib/lua/mcp

deploy: remove
	cp -a src/usr/* /usr
	ln -sf /usr/lib/lua/mcp/mcp.lua /usr/local/bin/mcp

test: deploy

