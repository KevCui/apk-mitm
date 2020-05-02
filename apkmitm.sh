#!/usr/bin/env bash
#
# Prepare apk and ready go mitm!
#
#/ Usage:
#/   ./apkmitm.sh <apk>
#/
#/ Options:
#/   <apk>          target apk file
#/   --help         display this help message

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" >&2 && exit 1
}

set_command() {
    _APKTOOL=$(command -v apktool) || command_not_found "apktool" "https://ibotpeaches.github.io/Apktool/"
    _KEYTOOL=$(command -v keytool) || command_not_found "keytool" "https://docs.oracle.com/javase/7/docs/technotes/tools/solaris/keytool.html"
    _JARSIGNER=$(command -v jarsigner) || command_not_found "jarsigner" "https://docs.oracle.com/javase/7/docs/technotes/tools/windows/jarsigner.html"
}

set_var() {
    _TIME_STAMP=$(date +%s)
    _OUTPUT_DIR=${_APK// /_}_$_TIME_STAMP
    _MANIFEST_XML="$_OUTPUT_DIR/AndroidManifest.xml"
    _KEYSTORE_NAME="apkmitm_${_TIME_STAMP}.keystore"
    _KEYSTORE_ALIAS="apkmitm"
    _STORE_PASSWORD="passwo"
    _KEY_PASSWORD="passwo"
    _APK_PREFIX="prepared-"
    _OUTPUT_APK_NAME="${_APK_PREFIX}${_APK// /_}"
}

set_args() {
    expr "$*" : ".*--help" > /dev/null && usage
    [[ -z ${1:-} ]] && usage
    _APK="$1"
}

print_info() {
    # $1: info message
    printf "%b\n" "\033[32m[INFO]\033[0m $1" >&2
}

print_error() {
    # $1: error message
    printf "%b\n" "\033[31m[ERROR]\033[0m $1" >&2
    exit 1
}

command_not_found() {
    # $1: command name
    # $2: installation URL
    if [[ -n "${2:-}" ]]; then
        print_error "$1 command not found! Install from $2"
    else
        print_error "$1 command not found!"
    fi
}

build_apk() {
    # $1: apk name
    # $2: app path
    print_info "Building ${1}..."
    $_APKTOOL build -o "./$1" "$2" >&2
}

decompile_apk() {
    # $1: apk file
    # $2: output dir
    print_info "Decompiling apk..."
    $_APKTOOL decode -s -o "$2" "$1" >&2
}

modify_manifest() {
    # $1: AndroidManifest.xml file
    [[ ! -f "$1" ]] && print_error "$1 not found!"
    if grep -q "networkSecurityConfig" "$1"; then
        print_info "$1 has already been modified! No change."
    else
        print_info "Modifying ${1}..."
        cp "$1" "${1}.orig"
        sed -E "/<application/a\\
android\:networkSecurityConfig=\"@xml\/network_security_config\"" < "${1}.orig" > "$1"
    fi
}

add_network_config() {
    # $1: app path
    local d f
    d="${1}/res/xml"
    f="${d}/network_security_config.xml"

    mkdir -p "$d"
    rm -f "$f"
    print_info "Adding ${f}..."

echo '<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config>
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
</network-security-config>' > "$f"
}

generate_keystore() {
    print_info "Generating ${_KEYSTORE_NAME}..."
    [[ -f "$_KEYSTORE_NAME" ]] && rm -f "$_KEYSTORE_NAME"
    yes | $_KEYTOOL -genkey -keystore "$_KEYSTORE_NAME" -alias "$_KEYSTORE_ALIAS" -keyalg RSA -keysize 2048 -validity 10000 -storepass "$_STORE_PASSWORD" -keypass "$_KEY_PASSWORD"
}

sign_apk() {
    # $1: apk name
    print_info "Signing ${1}..."
    $_JARSIGNER -keystore "$_KEYSTORE_NAME" -storepass "$_STORE_PASSWORD" -keypass "$_KEY_PASSWORD" "$1" "$_KEYSTORE_ALIAS" >&2
}

main() {
    set_args "$@"
    set_command
    set_var

    decompile_apk "$_APK" "$_OUTPUT_DIR"
    add_network_config "$_OUTPUT_DIR"
    modify_manifest "$_MANIFEST_XML"
    build_apk "$_OUTPUT_APK_NAME" "$_OUTPUT_DIR"
    generate_keystore
    sign_apk "$_OUTPUT_APK_NAME"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
