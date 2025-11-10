# ==============================================================================
# List Processes Using Network Ports
# ==============================================================================
# Usage: listports [OPTIONS]

function listports
    set -l show_help false
    set -l specific_port ""
    set -l protocol "both"

    # Colors
    set -l RED '\033[0;31m'
    set -l GREEN '\033[0;32m'
    set -l YELLOW '\033[1;33m'
    set -l BLUE '\033[0;34m'
    set -l CYAN '\033[0;36m'
    set -l NC '\033[0m'

    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -h --help
                set show_help true
            case -p --port
                set i (math $i + 1)
                set specific_port $argv[$i]
                # Validate port
                if not string match -qr '^[0-9]+$' $specific_port
                    echo -e "$RED""Error: Invalid port number '$specific_port'""$NC" >&2
                    return 1
                end
                if test $specific_port -lt 1 -o $specific_port -gt 65535
                    echo -e "$RED""Error: Port must be between 1 and 65535""$NC" >&2
                    return 1
                end
            case -t --tcp
                set protocol tcp
            case -u --udp
                set protocol udp
            case '*'
                echo -e "$RED""Error: Unknown option '$argv[$i]'""$NC" >&2
                echo "Use 'listports --help' for usage information."
                return 1
        end
        set i (math $i + 1)
    end

    if test "$show_help" = true
        echo "Usage: listports [OPTIONS]"
        echo ""
        echo "List all processes using network ports"
        echo ""
        echo "Options:"
        echo "  -h, --help         Show this help message"
        echo "  -p, --port PORT    Show only specific port"
        echo "  -t, --tcp          Show only TCP connections (default: both TCP/UDP)"
        echo "  -u, --udp          Show only UDP connections"
        echo ""
        echo "Examples:"
        echo "  listports                    # Show all ports"
        echo "  listports -p 3000           # Show only port 3000"
        echo "  listports -t                # Show only TCP ports"
        echo "  listports -u                # Show only UDP ports"
        echo "  listports -p 5173 -t        # Show port 5173 TCP only"
        return 0
    end

    # Build lsof arguments
    set -l lsof_args "-i"

    if test -n "$specific_port"
        if test "$protocol" = tcp
            set lsof_args "-iTCP:$specific_port"
        else if test "$protocol" = udp
            set lsof_args "-iUDP:$specific_port"
        else
            set lsof_args "-i:$specific_port"
        end
    else if test "$protocol" = tcp
        set lsof_args "-iTCP"
    else if test "$protocol" = udp
        set lsof_args "-iUDP"
    end

    echo -e "$CYAN""Active network connections:""$NC"
    echo -e "$BLUE""COMMAND    PID    USER   FD   TYPE   DEVICE   SIZE/OFF   NODE   NAME""$NC"

    lsof $lsof_args 2>/dev/null | tail -n +2 | while read -l line
        if string match -q '*LISTEN*' $line
            echo -e "$GREEN$line$NC"
        else
            echo $line
        end
    end

    if test -n "$specific_port"
        if not lsof $lsof_args 2>/dev/null | tail -n +2 | read
            echo -e "$YELLOW""No processes found using port $specific_port""$NC"
        end
    end
end
