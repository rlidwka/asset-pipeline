
This is tests suite for asset-pipeline. All tests are running on the client side using jquery-unit.

To run it you need to install all developer dependencies (run `npm install .` on a parent directory containing package.json) and run `./server.coffee`. To clean all temporary files run `./clean.sh`.

It is also an example how you can use this module. Tests itself are located in tests/NUMBER/ and they are quite a mess, but all other stuff it a good usage example IMHO.

**WARNING**: This test suite provides an API to set an arbitrary file on the server, and server can execute it. Do not give access to this to anybody you don't trust.

This ascii-art shows how all assets in this suite are compiled:

```
User requests for /tests.html
`- compiling /tests.haml to /tests.html
   `- compiling /tests.haml.ejs to /tests.haml
      `.
       |- resolving URL for /js/jquery-1.7.1.min.js
       |  `- compiling /js/jquery-1.7.1.min.js
       |
       |- resolving URL for /js/qunit-git.js
       |  `- compiling /js/qunit-git.js
       |
       |- resolving URL for /js/async.min.js
       |  `- compiling /js/async.min.js
       |
       |- resolving URL for /tests/run-all.js
       |  `- compiling /tests/run-all.coffee to /tests/run-all.js
       |     `- compiling /tests/run-all.coffee.ejs to /tests/run-all.coffee
       |        `.
       |         |- including /tests/01/run.js
       |         |  `- compiling /tests/01/run.coffee to /tests/01/run.js
       |         |
       |         |- including /tests/02/run.js
       |         |  `- compiling /tests/02/run.coffee to /tests/02/run.js
       |         |
       |         |- including /tests/03/run.js
       |         |  `- compiling /tests/03/run.coffee to /tests/03/run.js
       |         `.
       |           `- ..... and so on ...
       |
       `- resolving URL for /css/qunit-git.css
          `- compiling /css/qunit-git.css
```
