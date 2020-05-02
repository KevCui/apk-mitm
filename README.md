apk-mitm
========

A Bash script modifies app networks configurations and makes any apk MITM-ready.

## Dependency

- [apktool](https://ibotpeaches.github.io/Apktool/): Decompile and build apk
- [keytool](https://docs.oracle.com/javase/7/docs/technotes/tools/solaris/keytool.html): Generate keystore
- [jarsigner](https://docs.oracle.com/javase/7/docs/technotes/tools/windows/jarsigner.html): Sign akp

## Usage

```
Usage:
  ./apkmitm.sh <apk>

Options:
  <apk>          target apk file
  --help         display this help message
```

## Why this script is needed?

Since Android 7 (API level 24), secure connections from apps won't trust user-added CA store by default. It means, in many cases, simply adding proxy CA on the device won't be enough to intercept HTTPS requests from proxy tool. In additional, some network security configurations are required to be added in app source code, in order to enable the trust of user-added proxy CA store. This script automates the process to add these additional network configurations and recompile apk, ready for MITM.

## What this script does exactly?

1. Decompile target apk with apktool

2. Add `res/xml/network_security_config`, which enables app trusts user-added CA

3. Modify `AndroidManifest.xml` to apply network configurations from `res/xml/network_security_config.xml`

4. Build apk with the changes above

5. Generate a new keystore

6. Sign apk with self-signed keystore
