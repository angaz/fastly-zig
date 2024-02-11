const std = @import("std");
const zigly = @import("zigly");

const HandlerFunc = *const fn (std.mem.Allocator, *zigly.Downstream, zigly.Uri) anyerror!void;

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
    mk_handler("/hello", hello_handler),
    mk_handler("/proxy", proxy_handler),
    mk_handler("/redirect", redirect_handler),
    mk_handler("/ip", client_ip_handler),
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
    const alloc = std.heap.page_allocator;

    try serve(alloc, not_found_handler);
}

fn index_handler(_: std.mem.Allocator, downstream: *zigly.Downstream, _: zigly.Uri) !void {
    var response = downstream.response;
    try response.body.writeAll(
        \\/hello     - Responds with Hello, World!
        \\/ip        - Responds with the client's IP address
        \\/proxy     - Proxies the name given by the `backend` query parameter
        \\/redirect  - Redirects to this repo's URL
        \\
    );
    try response.finish();
}

fn hello_handler(_: std.mem.Allocator, downstream: *zigly.Downstream, _: zigly.Uri) !void {
    var response = downstream.response;
    try response.body.writeAll("Hello, World!\n");
    try response.finish();
}

fn redirect_handler(_: std.mem.Allocator, downstream: *zigly.Downstream, _: zigly.Uri) !void {
    try downstream.redirect(302, "https://github.com/angaz/fastly-zig");
}

fn proxy_handler(alloc: std.mem.Allocator, downstream: *zigly.Downstream, uri: zigly.Uri) !void {
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

fn client_ip_handler(alloc: std.mem.Allocator, downstream: *zigly.Downstream, _: zigly.Uri) !void {
    const ip = try downstream.request.geClientIpAddr();
    const ip_str = try ip.print(alloc);

    var response = downstream.response;
    try response.body.writeAll(ip_str);
    try response.body.writeAll("\n");
    try response.finish();
}

fn not_found_handler(_: std.mem.Allocator, downstream: *zigly.Downstream, _: zigly.Uri) !void {
    var response = downstream.response;
    try response.setStatus(404);
    try response.body.writeAll("Not found\n");
    try response.finish();
}
