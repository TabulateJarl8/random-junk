# Basic Web Server in Assembly

I was bored and wanted to write some more assembly so I decided a web server would be a pretty interesting thing to write. I was able to learn how web servers actually work at an operating system level which I've never actually bothered to learn, so that was pretty cool.

- `web_server.asm` - this contains the actual web server that I wrote. It currently has the ability to bind to 127.0.0.1:8000 and serve an `index.html` in the same directory. If the `index.html` isn't present, the client is presented with an nginx-like 404 page. There is also support for a 500 error if something else goes wrong when reading the file, and a 400 error if trying to POST. In the future, I may add:

  - [x] Specifying a port as an argument
  - [x] Ability to render all HTML files in a `pages/` folder dynamically from the URL
    - This feature has now been implemented. Any files in the `pages/` directory will be served on the web root. In addition, the web server automatically resolves any paths with a trailing `/` to `/index.html`. For example, `/super/` will resolve to `pages/super/index.html`, allowing for more readable web addresses.
    - NOTE: This is very secure and definitely does not expose the entire filesystem. I couldn't seem to get a webbrowser to do it, but I was able to use netcat to request files relatively using `..`.
  - [x] Better error reporting (error messages and exit with errno code)
  - [x] Automatic `Content-Type` response header setting. This allows for any files to be correctly rendered by the browser, such as stylesheets, images, or anything else

    - Supported filetypes:

      | Extension | Mimetype           |
      | --------- | ------------------ |
      | `.html`   | `text/html`        |
      | `.woff`   | `font/woff`        |
      | `.woff2`  | `font/woff2`       |
      | `.ttf`    | `font/ttf`         |
      | `.css`    | `text/css`         |
      | `.js`     | `text/javascript`  |
      | `.ico`    | `image/x-icon`     |
      | `.txt`    | `text/plain`       |
      | `.xml`    | `application/xml`  |
      | `.pdf`    | `application/pdf`  |
      | `.png`    | `image/png`        |
      | `.jpg`    | `image/jepg`       |
      | `.jpeg`   | `image/jepg`       |
      | `.svg`    | `image/svg+xml`    |
      | `.json`   | `application/json` |
      | `.mp4`    | `video/mp4`        |
      | `.mp3`    | `audio/mp3`        |

- `web_server_better.asm` - this contains a super cool and super complex web server that just runs `nginx`, as suggested by a member of the JMU Unix Users Group.

## Compiling

```properties
nasm web_server.asm -f elf64
ld web_server.o -o web_server
```
