const std = @import("std");
const zigly = @import("zigly");
const favicon = @embedFile("favicon.ico");

const HandlerFunc = *const fn (std.mem.Allocator, *zigly.http.Downstream, zigly.Uri) anyerror!void;

const Handler = struct {
    path: []const u8,
    func: HandlerFunc,
};

fn mk_handler(path: []const u8, func: HandlerFunc) Handler {
    return .{
        .path = path,
        .func = func,
    };
}

const handlers = [_]Handler{
    mk_handler("/", index_handler),
    mk_handler("/favicon.ico", favicon_handler),
    mk_handler("/hello", hello_handler),
    mk_handler("/ip", client_ip_handler),
    mk_handler("/ok", ok_handler),
    mk_handler("/proxy", proxy_handler),
    mk_handler("/redirect", redirect_handler),
    mk_handler("/teapot", teapot_handler),
    mk_handler("/weather", weather_handler),
};

fn serve(
    alloc: std.mem.Allocator,
    not_found: HandlerFunc,
) !void {
    var downstream = try zigly.downstream();

    var buff = [_]u8{0} ** 1024;
    const uri_str = try downstream.request.getUriString(buff[0..]);
    const uri = try zigly.Uri.parse(uri_str, true);

    for (handlers) |handler| {
        if (std.mem.eql(u8, uri.path, handler.path)) {
            try handler.func(alloc, &downstream, uri);

            return;
        }
    }

    try not_found(alloc, &downstream, uri);
}

pub fn main() !void {
    const alloc = std.heap.wasm_allocator;

    try serve(alloc, not_found_handler);
}

fn index_handler(_: std.mem.Allocator, downstream: *zigly.http.Downstream, _: zigly.Uri) !void {
    var response = downstream.response;
    try response.body.writeAll(
        \\/favicon.ico  - Responds with a lightning bolt favicon
        \\/hello        - Responds with Hello, World!
        \\/ip           - Responds with the client's IP address
        \\/ok           - Responds with 200 OK
        \\/proxy        - Proxies the name given by the `backend` query parameter
        \\/redirect     - Redirects to this repo's URL
        \\/teapot       - Responds with 418 I'm a teapot
        \\/weather      - Uses Fastly's geo lookup to get location and proxies the request to wttr.in
        \\
    );
    try response.finish();
}

fn ok_handler(_: std.mem.Allocator, downstream: *zigly.http.Downstream, _: zigly.Uri) !void {
    var response = downstream.response;
    try response.setStatus(200);
    try response.finish();
}

fn teapot_handler(_: std.mem.Allocator, downstream: *zigly.http.Downstream, _: zigly.Uri) !void {
    var response = downstream.response;
    try response.setStatus(418);
    try response.finish();
}

fn hello_handler(_: std.mem.Allocator, downstream: *zigly.http.Downstream, _: zigly.Uri) !void {
    var response = downstream.response;
    try response.body.writeAll("Hello, World!\n");
    try response.finish();
}

fn redirect_handler(_: std.mem.Allocator, downstream: *zigly.http.Downstream, _: zigly.Uri) !void {
    try downstream.redirect(302, "https://github.com/angaz/fastly-zig");
}

fn favicon_handler(_: std.mem.Allocator, downstream: *zigly.http.Downstream, _: zigly.Uri) !void {
    var response = downstream.response;
    try response.headers.set("Content-Type", "image/x-icon");
    try response.body.writeAll(favicon);
    try response.finish();
}

fn get_weather(allocator: std.mem.Allocator) !zigly.http.IncomingResponse {
    const ip = try zigly.http.Downstream.getClientIpAddr();

    var location_buf = [_]u8{0} ** 4096;
    const location_json = try zigly.geo.lookup(allocator, ip, location_buf[0..]);
    defer location_json.deinit();
    const location = location_json.value;

    const base_url = "https://wttr.in/";
    const city = try std.Uri.escapeString(allocator, location.city);
    defer allocator.free(city);

    var weather_url = try allocator.alloc(u8, base_url.len + city.len);
    defer allocator.free(weather_url);
    std.mem.copyForwards(u8, weather_url[0..], base_url);
    std.mem.copyForwards(u8, weather_url[base_url.len..], city);

    var weather_req = try zigly.http.Request.new("GET", weather_url);
    try weather_req.headers.set("Accept", "text/plain");
    try weather_req.headers.set("User-Agent", "curl/8.5.0");
    const weather_resp = try weather_req.send("weather");

    return weather_resp;
}

fn weather_handler(allocator: std.mem.Allocator, downstream: *zigly.http.Downstream, _: zigly.Uri) !void {
    var weather_resp = try get_weather(allocator);

    try downstream.response.pipe(&weather_resp, true, true);
}

fn proxy_handler(alloc: std.mem.Allocator, downstream: *zigly.http.Downstream, uri: zigly.Uri) !void {
    var query = try zigly.Uri.mapQuery(
        alloc,
        uri.query,
    );
    defer query.deinit();

    const query_backend = query.get("backend");

    if (query_backend) |backend| {
        try downstream.proxy(backend, null);
    } else {
        var response = downstream.response;
        try response.setStatus(400);
        try response.body.writeAll("\"backend\" query param required\n");
        try response.finish();
    }
}

fn client_ip_handler(alloc: std.mem.Allocator, downstream: *zigly.http.Downstream, _: zigly.Uri) !void {
    const ip = try zigly.http.Downstream.getClientIpAddr();
    const ip_str = try ip.print(alloc);

    var response = downstream.response;
    try response.body.writeAll(ip_str);
    try response.body.writeAll("\n");
    try response.finish();
}

fn not_found_handler(_: std.mem.Allocator, downstream: *zigly.http.Downstream, _: zigly.Uri) !void {
    var response = downstream.response;
    try response.setStatus(404);
    try response.body.writeAll("Not found\n");
    try response.finish();
}
