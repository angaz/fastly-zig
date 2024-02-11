# fastly-zig
POC for using Zig on Fastly Compute

## Test server

The nix flake defines a command which will compile the zig WASM executable and
start the [Viceroy][viceroy] test server.

## Examples

```sh
$ curl 'http://127.0.0.1:7676/'
/hello     - Responds with Hello, World!
/ip        - Responds with the client's IP address
/ok        - Responds with 200 OK
/proxy     - Proxies the name given by the `backend` query parameter
/redirect  - Redirects to this repo's URL
/teapot    - Responds with 418 I'm a teapot
```

```sh
$ curl 'http://127.0.0.1:7676/hello'
Hello, World!
```

```sh
$ curl 'http://127.0.0.1:7676/ip'
127.0.0.1
```

```sh
$ curl -v 'http://127.0.0.1:7676/ok'
> GET /ok HTTP/1.1
> Host: 127.0.0.1:7676
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< content-length: 0
< date: Sun, 11 Feb 2024 23:12:51 GMT
<
```

```sh
$ curl -v 'http://127.0.0.1:7676/proxy'
> GET /proxy HTTP/1.1
> Host: 127.0.0.1:7676
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 400 Bad Request
< content-length: 31
< date: Sun, 11 Feb 2024 23:13:48 GMT
<
"backend" query param required
```

```sh
$ curl -v 'http://127.0.0.1:7676/proxy?backend=example'
> GET /proxy?backend=example HTTP/1.1
> Host: 127.0.0.1:7676
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 404 Not Found
< content-type: text/html
< date: Sun, 11 Feb 2024 23:14:32 GMT
< server: ECS (dce/26AD)
< content-length: 345
<
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
        <head>
                <title>404 - Not Found</title>
        </head>
        <body>
                <h1>404 - Not Found</h1>
        </body>
</html>
```

```sh
$ curl -v 'http://127.0.0.1:7676/redirect'
> GET /redirect HTTP/1.1
> Host: 127.0.0.1:7676
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 302 Found
< location: https://github.com/angaz/fastly-zig
< content-length: 0
< date: Sun, 11 Feb 2024 23:15:29 GMT
<
```

```sh
$ curl -v 'http://127.0.0.1:7676/teapot'
> GET /teapot HTTP/1.1
> Host: 127.0.0.1:7676
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 418 I'm a teapot
< content-length: 0
< date: Sun, 11 Feb 2024 23:16:22 GMT
<
```

[viceroy]: https://github.com/fastly/Viceroy
