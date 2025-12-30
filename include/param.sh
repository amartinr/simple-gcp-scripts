usage() {
    cat <<EOF
Usage: $0 [-m|--machine=<machine-type>] [-d|--disk[=][standard|balanced]] [-s|--disk-size=<disk size in GB>] [-g|--gpu[=][k80|t4]]
EOF
}
log() { printf '%s\n' "$*"; }
error() { log "ERROR: $*" >&2; }
fatal() { error "$*"; exit 1; }
usage_fatal() { error "$*"; usage >&2; exit 1; }

DATA_DISK_TYPE="none"
DATA_DISK_SIZE=30
GPU_TYPE="none"

while [ "$#" -gt 0 ]; do
    arg=$1
    case $1 in
        # convert "--opt=the value" to --opt "the value".
        # the quotes around the equals sign is to work around a
        # bug in emacs' syntax parsing
        --*'='*) shift; set -- "${arg%%=*}" "${arg#*=}" "$@"; continue;;
        -m|--machine) shift; MACHINE_TYPE=$1; shift || usage_fatal "option '${arg}' requires a value";;
        -d|--disk) shift; if [ -n "$1" ] && [[ ! "$1" =~ ^- ]]; then DATA_DISK_TYPE=$1; shift; else DATA_DISK_TYPE="standard"; fi;;
        -s|--disk-size) shift; DATA_DISK_SIZE=$1; shift || usage_fatal "option '${arg}' requires a value";;
        -p|--persistent) shift; if [ -n "$1" ] && [[ ! "$1" =~ ^- ]]; then DISK_PERSISTENT=$1; shift; else DISK_PERSISTENT="true"; fi;;
        -g|--gpu) shift; if [ -n "$1" ] && [[ ! "$1" =~ ^- ]]; then GPU_TYPE=$1; shift; else GPU_TYPE="t4"; fi;;
        -h|--help) usage; exit 0;;
        --) shift; break;;
        -*) usage_fatal "unknown option: '$1'";;
        *) break;;
    esac
done
