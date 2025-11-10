# ==============================================================================
# Kill Processes Using Specified Ports
# ==============================================================================
# Usage: killports [OPTIONS] PORT...

function killports
    set -l show_help false
    set -l force_kill false
    set -l list_before_kill false
    set -l quiet false
    set -l ports_to_kill

    # Colors
    set -l RED '\033[0;31m'
    set -l GREEN '\033[0;32m'
    set -l YELLOW '\033[1;33m'
    set -l BLUE '\033[0;34m'
    set -l CYAN '\033[0;36m'
    set -l NC '\033[0m'

    # Helper function to validate port
    function _is_valid_port
        set -l port $argv[1]
        if string match -qr '^[0-9]+$' $port
            if test $port -ge 1 -a $port -le 65535
                return 0
            end
        end
        return 1
    end

    # Helper function to expand port range
    function _expand_port_range
        set -l range $argv[1]
        if string match -qr '^([0-9]+)-([0-9]+)$' $range
            set -l parts (string split - $range)
            set -l start $parts[1]
            set -l end $parts[2]

            if not _is_valid_port $start; or not _is_valid_port $end
                echo "Invalid port range: $range" >&2
                return 1
            end

            if test $start -gt $end
                echo "Invalid range: start port ($start) is greater than end port ($end)" >&2
                return 1
            end

            seq $start $end
        else if _is_valid_port $range
            echo $range
        else
            echo "Invalid port: $range" >&2
            return 1
        end
    end

    # Check if no arguments provided
    if test (count $argv) -eq 0
        echo -e "$RED""Error: No ports specified""$NC" >&2
        echo "Use 'killports --help' for usage information."
        return 1
    end

    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -h --help
                set show_help true
            case -f --force
                set force_kill true
            case -l --list
                set list_before_kill true
            case -q --quiet
                set quiet true
            case '-*'
                echo -e "$RED""Error: Unknown option '$argv[$i]'""$NC" >&2
                echo "Use 'killports --help' for usage information."
                return 1
            case '*'
                set -a ports_to_kill $argv[$i]
        end
        set i (math $i + 1)
    end

    if test "$show_help" = true
        echo "Usage: killports [OPTIONS] PORT..."
        echo ""
        echo "Kill processes using specified ports"
        echo ""
        echo "Arguments:"
        echo "  PORT                Port number(s) or range(s) to kill"
        echo ""
        echo "Options:"
        echo "  -h, --help         Show this help message"
        echo "  -f, --force        Skip SIGTERM, use SIGKILL directly"
        echo "  -l, --list         List processes before killing"
        echo "  -q, --quiet        Suppress output"
        echo ""
        echo "Examples:"
        echo "  killports 3000                    # Kill process on port 3000"
        echo "  killports 3000 5173 8080         # Kill multiple ports"
        echo "  killports 3000-3005              # Kill port range 3000 to 3005"
        echo "  killports 5170-5180 3000         # Mix ranges and individual ports"
        echo "  killports -f 3000                # Force kill immediately"
        echo "  killports -l 5173                # Show process info before killing"
        echo ""
        echo "Common development ports:"
        echo "  3000, 3001...     # Next.js, Create React App"
        echo "  5173, 5174...     # Vite dev server"
        echo "  4173              # Vite preview"
        echo "  8080, 8081...     # Various dev servers"
        echo "  9000+             # Storybook, etc."
        echo ""
        echo "See also: listports"
        return 0
    end

    if test (count $ports_to_kill) -eq 0
        echo -e "$RED""Error: No ports specified""$NC" >&2
        return 1
    end

    # Expand all port ranges and validate
    set -l all_ports
    for port_arg in $ports_to_kill
        set -l expanded (_expand_port_range $port_arg)
        if test $status -ne 0
            return 1
        end
        set -a all_ports $expanded
    end

    # Remove duplicates and sort
    set -l unique_ports (printf '%s\n' $all_ports | sort -nu)

    test "$quiet" = false; and echo -e "$CYAN""Processing "(count $unique_ports)" port(s)...""$NC"

    set -l killed_count 0
    set -l not_found_count 0

    for port in $unique_ports
        set -l pids (lsof -ti:$port 2>/dev/null)

        if test -z "$pids"
            test "$quiet" = false; and echo -e "$YELLOW""No process found on port $port""$NC"
            set not_found_count (math $not_found_count + 1)
            continue
        end

        # Show process info if requested
        if test "$list_before_kill" = true; or test "$quiet" = false
            echo -e "$BLUE""Port $port processes:""$NC"
            lsof -i:$port 2>/dev/null | tail -n +2 | while read -l line
                echo -e "$GREEN  $line$NC"
            end
        end

        # Kill processes
        for pid in $pids
            set -l cmd_name (ps -p $pid -o comm= 2>/dev/null | string trim)

            if test "$force_kill" = true
                test "$quiet" = false; and echo -e "$RED""Force killing $cmd_name (PID: $pid) on port $port""$NC"
                kill -9 $pid 2>/dev/null
            else
                test "$quiet" = false; and echo -e "$YELLOW""Terminating $cmd_name (PID: $pid) on port $port""$NC"
                kill -15 $pid 2>/dev/null

                # Wait a moment, then force kill if still alive
                sleep 0.5
                if kill -0 $pid 2>/dev/null
                    test "$quiet" = false; and echo -e "$RED""Force killing stubborn process (PID: $pid)""$NC"
                    kill -9 $pid 2>/dev/null
                end
            end

            set killed_count (math $killed_count + 1)
        end
    end

    if test "$quiet" = false
        echo -e "$GREEN""Summary: $killed_count process(es) killed, $not_found_count port(s) were already free""$NC"
    end
end
