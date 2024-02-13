# fastly-zig
POC for using Zig on Fastly Compute

## Test server

The nix flake defines a `serve` command which will compile the zig WASM
executable and start the [Viceroy][viceroy] test server.

## Examples

```sh
$ curl 'http://127.0.0.1:7676/'
/favicon.ico  - Responds with a lightning bolt favicon
/hello        - Responds with Hello, World!
/ip           - Responds with the client's IP address
/ok           - Responds with 200 OK
/proxy        - Proxies the name given by the `backend` query parameter
/redirect     - Redirects to this repo's URL
/teapot       - Responds with 418 I'm a teapot
/weather      - Uses Fastly's geo lookup to get location and proxies the request to wttr.in
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

```sh
$curl -v 'http://127.0.0.1:7676/weather'
> GET /weather HTTP/1.1
> Host: 127.0.0.1:7676
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< access-control-allow-origin: *
< date: Tue, 13 Feb 2024 23:45:38 GMT
< content-type: text/plain; charset=utf-8
< content-length: 8864
<
Weather report: San Francisco

     \  /       Partly cloudy
   _ /"".-.     +13(12) °C
     \_(   ).   → 7 km/h
     /(___(__)  16 km
                0.0 mm
                                                       ┌─────────────┐
┌──────────────────────────────┬───────────────────────┤  Tue 13 Feb ├───────────────────────┬──────────────────────────────┐
│            Morning           │             Noon      └──────┬──────┘     Evening           │             Night            │
├──────────────────────────────┼──────────────────────────────┼──────────────────────────────┼──────────────────────────────┤
│    \  /       Partly Cloudy  │     \   /     Sunny          │               Cloudy         │    \  /       Partly Cloudy  │
│  _ /"".-.     11 °C          │      .-.      13 °C          │      .--.     +13(12) °C     │  _ /"".-.     12 °C          │
│    \_(   ).   ↖ 1-2 km/h     │   ― (   ) ―   ↑ 2-3 km/h     │   .-(    ).   → 12-16 km/h   │    \_(   ).   ↗ 6-10 km/h    │
│    /(___(__)  10 km          │      `-’      10 km          │  (___.__)__)  10 km          │    /(___(__)  10 km          │
│               0.0 mm | 0%    │     /   \     0.0 mm | 0%    │               0.0 mm | 0%    │               0.0 mm | 0%    │
└──────────────────────────────┴──────────────────────────────┴──────────────────────────────┴──────────────────────────────┘
                                                       ┌─────────────┐
┌──────────────────────────────┬───────────────────────┤  Wed 14 Feb ├───────────────────────┬──────────────────────────────┐
│            Morning           │             Noon      └──────┬──────┘     Evening           │             Night            │
├──────────────────────────────┼──────────────────────────────┼──────────────────────────────┼──────────────────────────────┤
│               Overcast       │    \  /       Partly Cloudy  │      .-.      Moderate rain  │      .-.      Light drizzle  │
│      .--.     +11(10) °C     │  _ /"".-.     +14(12) °C     │     (   ).    +12(9) °C      │     (   ).    +11(9) °C      │
│   .-(    ).   ↖ 14-22 km/h   │    \_(   ).   ↖ 20-28 km/h   │    (___(__)   ↗ 23-33 km/h   │    (___(__)   → 11-16 km/h   │
│  (___.__)__)  10 km          │    /(___(__)  10 km          │   ‚‘‚‘‚‘‚‘    7 km           │     ‘ ‘ ‘ ‘   2 km           │
│               0.0 mm | 0%    │               0.0 mm | 0%    │   ‚’‚’‚’‚’    3.1 mm | 100%  │    ‘ ‘ ‘ ‘    0.4mm | 100%   │
└──────────────────────────────┴──────────────────────────────┴──────────────────────────────┴──────────────────────────────┘
                                                       ┌─────────────┐
┌──────────────────────────────┬───────────────────────┤  Thu 15 Feb ├───────────────────────┬──────────────────────────────┐
│            Morning           │             Noon      └──────┬──────┘     Evening           │             Night            │
├──────────────────────────────┼──────────────────────────────┼──────────────────────────────┼──────────────────────────────┤
│  _`/"".-.     Light rain sho…│  _`/"".-.     Patchy rain ne…│    \  /       Partly Cloudy  │     \   /     Clear          │
│   ,\_(   ).   +11(9) °C      │   ,\_(   ).   +12(11) °C     │  _ /"".-.     +12(11) °C     │      .-.      11 °C          │
│    /(___(__)  ↑ 14-20 km/h   │    /(___(__)  ↑ 13-18 km/h   │    \_(   ).   ↗ 10-14 km/h   │   ― (   ) ―   → 6-10 km/h    │
│      ‘ ‘ ‘ ‘  10 km          │      ‘ ‘ ‘ ‘  10 km          │    /(___(__)  10 km          │      `-’      10 km          │
│     ‘ ‘ ‘ ‘   0.3 mm | 100%  │     ‘ ‘ ‘ ‘   0.0 mm | 79%   │               0.0 mm | 0%    │     /   \     0.0mm | 0%     │
└──────────────────────────────┴──────────────────────────────┴──────────────────────────────┴──────────────────────────────┘
Location: SF, California, United States of America [37.7792808,-122.4192362]

Follow @igor_chubin for wttr.in updates
```

[viceroy]: https://github.com/fastly/Viceroy
