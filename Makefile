.PHONY: all coffeescript

export PATH := node_modules/.bin:$(PATH)

all: package.json coffeescript

package.json: package.yaml
	js-yaml -j package.yaml > package.json

coffeescript: src/*
	coffee -c -o lib src

