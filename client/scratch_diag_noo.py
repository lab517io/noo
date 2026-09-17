#!/usr/bin/env python3
"""Read-only diagnostic: can the bundled SQLCipher open ~/Documents/my.noo
with the app's key derivation?  Password is read via a hidden prompt and is
never printed. Run this in your own Terminal:

    python3 scratch_diag_noo.py
"""
import ctypes, hashlib, base64, os, glob, getpass, sys

# Find the bundled SQLCipher framework binary (any build flavor).
cands = []
for pat in [
    "build/macos/Build/Products/*/noo.app/Contents/Frameworks/SQLCipher.framework/Versions/A/SQLCipher",
    os.path.expanduser("~/Applications/noo.app/Contents/Frameworks/SQLCipher.framework/Versions/A/SQLCipher"),
    "/Applications/noo.app/Contents/Frameworks/SQLCipher.framework/Versions/A/SQLCipher",
]:
    cands += glob.glob(pat)
if not cands:
    print("!! Could not find a built SQLCipher.framework. Build the macOS app first.")
    sys.exit(1)
DY = cands[0]
print("Using SQLCipher at:", DY)

lib = ctypes.CDLL(DY)
lib.sqlite3_open.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p)]
lib.sqlite3_close.argtypes = [ctypes.c_void_p]
lib.sqlite3_exec.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.POINTER(ctypes.c_char_p)]
lib.sqlite3_libversion.restype = ctypes.c_char_p

_cipher = {}
@ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_char_p), ctypes.POINTER(ctypes.c_char_p))
def _cb(arg, ncol, vals, names):
    if ncol and vals[0]:
        _cipher['v'] = vals[0].decode()
    return 0

def ex(db, sql, cb=None):
    err = ctypes.c_char_p()
    rc = lib.sqlite3_exec(db, sql.encode(), cb, None, ctypes.byref(err))
    return rc, (err.value.decode() if err.value else None)

def derive(pw):
    return base64.b64encode(hashlib.sha256(pw.encode("utf-8")).digest()).decode("ascii")

PATH = os.path.expanduser("~/Documents/my.noo")
print("Target DB:", PATH, "exists:", os.path.exists(PATH), "size:", os.path.getsize(PATH) if os.path.exists(PATH) else "-")
print("underlying sqlite version:", lib.sqlite3_libversion().decode())

pw = getpass.getpass("Enter the database password (hidden): ")
key = derive(pw)

def attempt(label, compat=None):
    db = ctypes.c_void_p()
    lib.sqlite3_open(PATH.encode(), ctypes.byref(db))
    ex(db, "PRAGMA key = '%s'" % key)
    if compat is not None:
        ex(db, "PRAGMA cipher_compatibility = %d" % compat)
    _cipher.clear()
    ex(db, "PRAGMA cipher_version", _cb)
    rc, m = ex(db, "SELECT count(*) FROM sqlite_master")
    lib.sqlite3_close(db)
    ok = (rc == 0)
    print(f"[{label}] cipher_version={_cipher.get('v')!r}  open={'OK' if ok else 'FAIL'}  rc={rc} {m or ''}")
    return ok

print("--- trying current SQLCipher defaults (v4) ---")
ok4 = attempt("v4 default")
print("--- trying SQLCipher 3 compatibility ---")
ok3 = attempt("compat=3")
print()
if ok4:
    print("RESULT: file opens with the app's derivation + SQLCipher 4 defaults.")
    print("        => the file is fine; the app is loading the WRONG sqlite at open time.")
elif ok3:
    print("RESULT: file opens only with cipher_compatibility=3.")
    print("        => it was written by an older SQLCipher; app needs a compat pragma.")
else:
    print("RESULT: file does NOT open with either scheme + this password.")
    print("        => wrong password, OR different key derivation than the current code.")
