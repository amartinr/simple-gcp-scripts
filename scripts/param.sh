usage() {
    cat <<EOF
Usage: $0 [-t|--type=<machine-type>] [-d|--disk[=][standard|balanced]]
EOF
}
log() { printf '%s\n' "$*"; }
error() { log "ERROR: $*" >&2; }
fatal() { error "$*"; exit 1; }
usage_fatal() { error "$*"; usage >&2; exit 1; }

DISK_TYPE="none"
while [ "$#" -gt 0 ]; do
    arg=$1
    case $1 in
        # convert "--opt=the value" to --opt "the value".
        # the quotes around the equals sign is to work around a
        # bug in emacs' syntax parsing
        --*'='*) shift; set -- "${arg%%=*}" "${arg#*=}" "$@"; continue;;
        -t|--type) shift; MACHINE_TYPE=$1; shift || usage_fatal "option '${arg}' requires a value";;
        -d|--disk) shift; if [ -n $1 ]; then DISK_TYPE=$1; else DISK_TYPE="standard"; fi;;
        -h|--help) usage; exit 0;;
        --) shift; break;;
        -*) usage_fatal "unknown option: '$1'";;
        *) break;;
    esac
done

MACHINE_TYPE=${MACHINE_TYPE:-"n2d-highcpu-16"}
case $DISK_TYPE in
    standard|s|std|"") DISK_TYPE="pd-standard";;
    balanced|b|bal) DISK_TYPE="pd-balanced";;
    none) DISK_TYPE="";;
    *) usage_fatal "invalid disk type: '$DISK_TYPE'";;
esac
