#!/usr/bin/env python3
"""
email-relay-api.py — Tiny HTTP API for managing email-relay room list.
Runs on port 8765. Caddy proxies /email-relay/* -> localhost:8765.

Endpoints:
  GET  /email-relay/rooms  -> {"rooms": [...]}
  PUT  /email-relay/rooms  -> body {"rooms": [...]} -> writes file, returns {"ok": true}

Auth: Authorization: Bearer <key>
      Key is stored in /home/ubuntu/email-relay-api.conf (one line, no trailing newline needed).
"""

import http.server
import json
import os
import sys

ROOMS_FILE = "/home/ubuntu/email-to-signal-rooms.json"
CONF_FILE = "/home/ubuntu/email-relay-api.conf"
PORT = 8765


def load_api_key():
    try:
        with open(CONF_FILE, "r") as f:
            return f.read().strip()
    except Exception as e:
        print(f"ERROR: Could not read API key from {CONF_FILE}: {e}", file=sys.stderr)
        sys.exit(1)


def load_rooms():
    try:
        with open(ROOMS_FILE, "r") as f:
            data = json.load(f)
        return data.get("rooms", [])
    except FileNotFoundError:
        return []
    except Exception as e:
        print(f"WARNING: Could not read rooms file: {e}", file=sys.stderr)
        return []


def save_rooms(rooms):
    tmp = ROOMS_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump({"rooms": rooms}, f, indent=2)
        f.write("\n")
    os.replace(tmp, ROOMS_FILE)


API_KEY = load_api_key()


class RelayAPIHandler(http.server.BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        # Use print so systemd captures it
        print(f"[email-relay-api] {self.address_string()} - {fmt % args}", file=sys.stderr)

    def send_json(self, code, obj):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def check_auth(self):
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            self.send_json(401, {"error": "unauthorized"})
            return False
        if auth[len("Bearer "):] != API_KEY:
            self.send_json(403, {"error": "forbidden"})
            return False
        return True

    def do_GET(self):
        if self.path == "/email-relay/rooms":
            if not self.check_auth():
                return
            rooms = load_rooms()
            self.send_json(200, {"rooms": rooms})
        else:
            self.send_json(404, {"error": "not found"})

    def do_PUT(self):
        if self.path == "/email-relay/rooms":
            if not self.check_auth():
                return
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
                rooms = data.get("rooms", [])
                if not isinstance(rooms, list):
                    self.send_json(400, {"error": "rooms must be an array"})
                    return
                # Validate each entry is a string
                for r in rooms:
                    if not isinstance(r, str):
                        self.send_json(400, {"error": "each room must be a string"})
                        return
                save_rooms(rooms)
                self.send_json(200, {"ok": True})
            except json.JSONDecodeError as ex:
                self.send_json(400, {"error": f"invalid JSON: {ex}"})
        else:
            self.send_json(404, {"error": "not found"})


if __name__ == "__main__":
    server = http.server.HTTPServer(("127.0.0.1", PORT), RelayAPIHandler)
    print(f"email-relay-api listening on 127.0.0.1:{PORT}", file=sys.stderr)
    server.serve_forever()
