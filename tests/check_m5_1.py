#!/usr/bin/env python3
from pathlib import Path

src = Path('src/tools/tcpinfo/main.c').read_text()
contract = Path('docs/M5_1_TCPINFO_CONTRACT.md').read_text()
makefile = Path('Makefile').read_text()

checks = {
    'source exists': 'TCPInfo' in src,
    'default device': 'abbstcp.device' in src,
    'default unit zero': 'DEFAULT_UNIT 0UL' in src,
    'OpenDevice probe': 'OpenDevice' in src,
    'CloseDevice on success': 'CloseDevice' in src,
    'message port allocation': 'CreateMsgPort' in src,
    'IORequest allocation': 'CreateIORequest' in src,
    'warn on unavailable': 'emit_open_result("WARN", device, unit, "NO"' in src,
    'stable open error': 'OPEN_ERROR=' in src,
    'explicit open failure reason': 'DEVICE_OPEN_FAILED' in src,
    'fatal setup remains explicit': 'LOCAL_SETUP_FAILED' in src,
    'no socket guessing': 'socket(' not in src and 'Socket(' not in src,
    'no telnet guessing': 'telnet' not in src.lower(),
    'contract no socket state guess': 'socket state' in contract.lower() and 'does not claim or infer' in contract.lower(),
    'contract device probe': 'OpenDevice' in contract,
    'contract stable open error': 'OPEN_ERROR=' in contract,
    'make target planned': 'tcpinfo' in makefile.lower(),
}

failed = []
for name, ok in checks.items():
    if ok:
        print(f'PASS: {name}')
    else:
        print(f'FAIL: {name}')
        failed.append(name)

if failed:
    raise SystemExit(1)
print('M5_1_STATIC=PASS')
