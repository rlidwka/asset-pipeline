### Usage example with Express 3

This library can make view rendering just like building assets. You could write:

```javascript
app.render('view')
```

And `pipeline` will found a file `view.jade.ejs`, compile it with `embeddedjs` and then pipe it to jade.

**Warning:** If you are using this library, you should not pass file extension to render. Use `res.render('file')` instead of `res.render('file.jade')`. It will not be rendered otherwise.

If you're using older versions of Express see "connect".
