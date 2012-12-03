.PHONY: pre-commit coffeescript

pre-commit: package.json coffeescript

# pre-commit hook for git that compiles package.js into package.json
# default package.json format is silly, it doesn't allow comments and so on
package.json: package.coffee
	node -e 'require("coffee-script");delete require.extensions[".json"];console.log(JSON.stringify(require("./package")));' > package.json
	git add package.json

coffeescript: src/*
	coffee -c -o lib src

