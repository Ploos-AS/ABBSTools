# M3.4 ConfInfo conference contract

## Status

The preserved ABBS 2.x source provides a sufficiently explicit read-only conference contract to begin `ConfInfo` without guessing private offsets or reverse-engineering the on-disk configuration file.

Primary reference repository:

- `ResistanceVault/preservation-abbs20`
- Reference commit: `a51658289061a60392954187d2fe4bd209703a9d`

## Public access path

M3.4 reuses the public main-port ABI already established for M3.3:

- main port: `ABBS mainport`
- command: `Main_Getconfig = 46`
- success: `Error_OK = 0`
- no-port: `Error_NoPort = 18`

The preserved utilities send `Main_Getconfig` to the main port and treat a successful reply as a pointer to `struct ConfigRecord` in `ABBSmsg.Data`. Existing source also checks the returned sentinel in `ABBSmsg.UserNr`; M3.4 must preserve the same validation used by the M3.3 adapter.

## Config/conference layout

`Include/bbs.h` defines:

```c
struct ConferenceRecord {
    NameT n_ConfName;
    UBYTE n_ConfBullets;
    ULONG n_ConfDefaultMsg;
    ULONG n_ConfFirstMsg;
    UWORD n_ConfOrder;
    UWORD n_ConfSW;
    UWORD n_ConfMaxScan;
};

struct ConfigRecord {
    UWORD Revision;
    ULONG Configsize;
    ULONG UserrecordSize;
    UWORD Maxconferences;
    UWORD MaxfileDirs;
    /* ... fixed configuration fields ... */
    struct FileDirRecord *firstFileDirRecord;
    struct ConferenceRecord firstconference[1];
};

#define SIZEOFCONFIGRECORD \
    (sizeof (struct ConfigRecord) - sizeof (struct ConferenceRecord))
```

`NameT` is `char[31]` (`Sizeof_NameT` is 30 characters plus terminator).

The first conference array begins at:

```c
(struct ConferenceRecord *)(((int)config) + SIZEOFCONFIGRECORD)
```

and contains `config->Maxconferences` records. Preserved programs including `UserEditor.c`, `ShowConfig.c`, `FLMaker.c`, and `convertconfig.c` use this layout directly.

The following file-directory array begins immediately after all conference records, which independently confirms the conference-array extent:

```c
(struct FileDirRecord *)(
    ((int)config) + SIZEOFCONFIGRECORD +
    config->Maxconferences * sizeof(struct ConferenceRecord))
```

## Fields safe for initial ConfInfo

The initial read-only tool may expose only fields explicitly demonstrated by preserved source:

- conference slot/index
- `n_ConfName`
- `n_ConfOrder`
- `n_ConfDefaultMsg`
- `n_ConfFirstMsg`
- `n_ConfBullets`
- `n_ConfMaxScan`
- `n_ConfSW`

`ShowConfig.c` explicitly reads name, order, default/highest message, bullet count, max scan and first message from `config->firstconference[n]`.

`convertconfig.c` explicitly populates name, bullets, default message, first message and order when constructing the newer conference records.

## Switch bits

`Include/bbs.h` defines `n_ConfSW` flags:

- bit 0: immediate read
- bit 1: immediate write
- bit 2: post box
- bit 3: private
- bit 4: VIP
- bit 5: resign
- bit 6: network
- bit 7: alias

The initial machine-readable output should retain the raw switch value. Human-friendly decoded flags may be added only as a deterministic presentation layer over these documented bits.

## Safety / bounds

`ConfInfo` must remain read-only.

Before dereferencing conference data it must validate:

1. the public main-port query succeeded;
2. returned config pointer is non-null;
3. the existing `Main_Getconfig` sentinel validation passes;
4. `Maxconferences` is bounded to a conservative implementation maximum;
5. requested conference index/order is within the returned conference count;
6. conference names are copied into a bounded local buffer and explicitly terminated.

No config save/create/rename/delete command is required or permitted for M3.4.

## Initial CLI decision

Start with numeric lookup:

```text
ConfInfo CONFERENCE
```

where `CONFERENCE` is a 1-based conference slot. This avoids ambiguous prefix/name matching during the first qualification milestone. A later extension may support exact name lookup once the numeric path is qualified.

Proposed stable output:

```text
STATUS=OK
CONFERENCE=1
NAME=General
ORDER=1
DEFAULT_MSG=123
FIRST_MSG=1
BULLETS=0
MAX_SCAN=50
SWITCHES=0
```

Missing main port should be a warning (RC 5); invalid CLI input or malformed/unusable config data should be an error (RC 10); allocation/setup fatal errors remain RC 20 according to the project convention.

## Qualification boundary

This source evidence closes the M3.4 contract-discovery task sufficiently for implementation and deterministic qualification.

It does **not** establish final live compatibility. `ConfInfo` must still be tested against the intended live ABBS installation on the AmigaOS 2.04+ / 68000-compatible baseline before that compatibility claim is made.
