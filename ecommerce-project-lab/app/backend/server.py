#!/usr/bin/env python3
"""Small dependency-free product API for the Kubernetes mini-shop lab."""

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PRODUCTS = [
    {"id": 1, "name": "Canvas Backpack", "price": 39.99, "category": "Bags"},
    {"id": 2, "name": "Desk Lamp", "price": 24.50, "category": "Home"},
    {"id": 3, "name": "Coffee Mug", "price": 12.00, "category": "Kitchen"},
    {"id": 4, "name": "Notebook Set", "price": 9.75, "category": "Stationery"},
]


class Handler(BaseHTTPRequestHandler):
    def _send_json(self, status, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802 - BaseHTTPRequestHandler API name
        if self.path == "/healthz":
            self._send_json(200, {"status": "ok"})
        elif self.path == "/readyz":
            self._send_json(200, {"status": "ready"})
        elif self.path == "/api/products":
            self._send_json(200, {"products": PRODUCTS, "served_by": os.getenv("HOSTNAME", "unknown")})
        else:
            self._send_json(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} - {fmt % args}", flush=True)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8000), Handler).serve_forever()