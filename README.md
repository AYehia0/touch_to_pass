# TouchToPass

A simple cli tool written in swift which uses the TouchID on supported Mac devices to fetch, delete and update keys from the ICloud Keychain, and it also supports TOTP (Time-based one-time password).

## Installation

Make sure you're on a macos machine and have swift installed (it's installed with xcode)

1. Build for release: `swift build -c release`
2. Copy the bin to your $PATH, the bin is located in `.build/release`

## Usage

```
> touch-to-pass -h

USAGE: touch-to-pass <action> [<keys> ...] [--totp <totp> ...]

ARGUMENTS:
  <action>                The action to perform: get, set, delete
  <keys>                  Keys to get, set, or delete

OPTIONS:
  --totp <totp>           Generate TOTP for specified keys
  -h, --help              Show help information.
```

It's usually used as:
```
> touch-to-pass get key1 key2 key3 ... --totp keyX
{
    key1: pass1,
    key2: pass2,
    key3: pass3,
    ...,
    keyX: passX
}
```

## Todo
- [ ] Clean the code
- [ ] Write tests
- [ ] Asking for permission multiple times (apple thing, idk)
