#!/usr/bin/env python3
# email-to-signal.py — polls a Gmail inbox and forwards unread messages to Matrix/Signal
# Runs on the Oracle VM. Any email that lands in the inbox gets forwarded to Signal.
# Use a dedicated throwaway Gmail account — nothing else should send to it.
#
# Deploy:  cp email-to-signal.py /home/ubuntu/email-to-signal.py
#          chmod 700 /home/ubuntu/email-to-signal.py
# Cron:    */5 * * * * /usr/bin/python3 /home/ubuntu/email-to-signal.py >> /var/log/email-to-signal.log 2>&1

import email
import email.header
import imaplib
import json
import ssl
import urllib.parse
import urllib.request
import uuid
from datetime import datetime

# ── Configuration ─────────────────────────────────────────────────────────────
IMAP_HOST = "imap.gmail.com"
IMAP_PORT = 993
IMAP_USER = "polymonbot@gmail.com"
IMAP_PASS = "xxxx xxxx xxxx xxxx"        # Gmail App Password (Settings → Security → App Passwords)

MATRIX_HOMESERVER = "https://matrix.thebuildist.com"
MATRIX_TOKEN      = "your-matrix-access-token"
MATRIX_ROOM_IDS   = [
    "!your-room-id",       # Bob (room ID only, no server suffix — Conduit requirement)
    # "!another-room-id",  # Coworker
]
# ─────────────────────────────────────────────────────────────────────────────


def matrix_send(room_id, text):
    txn_id = str(uuid.uuid4())
    room_encoded = urllib.parse.quote(room_id, safe="")
    url = f"{MATRIX_HOMESERVER}/_matrix/client/v3/rooms/{room_encoded}/send/m.room.message/{txn_id}"
    payload = json.dumps({"msgtype": "m.text", "body": text}).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=payload,
        method="PUT",
        headers={
            "Authorization": f"Bearer {MATRIX_TOKEN}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return resp.status == 200


def matrix_send_all(text):
    all_ok = True
    for room_id in MATRIX_ROOM_IDS:
        try:
            if not matrix_send(room_id, text):
                print(f"  Matrix returned non-200 for room {room_id}")
                all_ok = False
        except Exception as e:
            print(f"  ERROR sending to room {room_id}: {e}")
            all_ok = False
    return all_ok


def decode_header(value):
    parts = email.header.decode_header(value or "")
    out = []
    for part, charset in parts:
        if isinstance(part, bytes):
            out.append(part.decode(charset or "utf-8", errors="replace"))
        else:
            out.append(part)
    return "".join(out)


def get_text_body(msg):
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                charset = part.get_content_charset() or "utf-8"
                return part.get_payload(decode=True).decode(charset, errors="replace")
    else:
        charset = msg.get_content_charset() or "utf-8"
        return msg.get_payload(decode=True).decode(charset, errors="replace")
    return ""


def main():
    ctx = ssl.create_default_context()
    with imaplib.IMAP4_SSL(IMAP_HOST, IMAP_PORT, ssl_context=ctx) as imap:
        imap.login(IMAP_USER, IMAP_PASS)
        imap.select("INBOX")

        _, data = imap.search(None, "UNSEEN")
        ids = data[0].split()

        if not ids:
            return

        print(f"{datetime.now().isoformat()}  {len(ids)} unread message(s)")

        for msg_id in ids:
            _, raw_data = imap.fetch(msg_id, "(RFC822)")
            msg = email.message_from_bytes(raw_data[0][1])

            subject = decode_header(msg.get("Subject", "(no subject)"))
            sender  = decode_header(msg.get("From", ""))
            body    = get_text_body(msg).strip()

            # Format for Signal readability
            matrix_text = f"{subject}"
            if body:
                matrix_text += f"\n\n{body}"

            if matrix_send_all(matrix_text):
                imap.store(msg_id, "+FLAGS", "\\Seen")
                print(f"  forwarded: {subject}")
            else:
                # Leave unread — will retry next run
                print(f"  partial/failed forward, leaving unread: {subject}")


if __name__ == "__main__":
    main()
