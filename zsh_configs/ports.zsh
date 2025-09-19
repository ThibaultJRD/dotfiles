# ==============================================================================
# Port Management Functions
# ==============================================================================
# This file provides utilities for managing processes using network ports.

# Colors for output (only define if not already set)
if [[ -z ${_KILLPORTS_RED+x} ]]; then
    readonly _KILLPORTS_RED='\033[0;31m'
    readonly _KILLPORTS_GREEN='\033[0;32m'
    readonly _KILLPORTS_YELLOW='\033[1;33m'
    readonly _KILLPORTS_BLUE='\033[0;34m'
    readonly _KILLPORTS_CYAN='\033[0;36m'
    readonly _KILLPORTS_NC='\033[0m' # No Color
fi

# Helper function to check if a port is valid
_is_valid_port() {
  local port="$1"
  [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
}

# Helper function to expand port ranges
_expand_port_range() {
  local range="$1"
  if [[ "$range" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    local start="${BASH_REMATCH[1]}"
    local end="${BASH_REMATCH[2]}"

    if ! _is_valid_port "$start" || ! _is_valid_port "$end"; then
      echo "Invalid port range: $range" >&2
      return 1
    fi

    if [ "$start" -gt "$end" ]; then
      echo "Invalid range: start port ($start) is greater than end port ($end)" >&2
      return 1
    fi

    seq "$start" "$end"
  elif _is_valid_port "$range"; then
    echo "$range"
  else
    echo "Invalid port: $range" >&2
    return 1
  fi
}

# List processes using network ports
listports() {
  local show_help=false
  local specific_port=""
  local protocol="both"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help=true
        shift
        ;;
      -p|--port)
        specific_port="$2"
        if ! _is_valid_port "$specific_port"; then
          echo -e "${_KILLPORTS_RED}Error: Invalid port number '$specific_port'${_KILLPORTS_NC}" >&2
          return 1
        fi
        shift 2
        ;;
      -t|--tcp)
        protocol="tcp"
        shift
        ;;
      -u|--udp)
        protocol="udp"
        shift
        ;;
      *)
        echo -e "${_KILLPORTS_RED}Error: Unknown option '$1'${_KILLPORTS_NC}" >&2
        echo "Use 'listports --help' for usage information."
        return 1
        ;;
    esac
  done

  if [ "$show_help" = true ]; then
    cat << 'EOF'
Usage: listports [OPTIONS]

List all processes using network ports

Options:
  -h, --help         Show this help message
  -p, --port PORT    Show only specific port
  -t, --tcp          Show only TCP connections (default: both TCP/UDP)  
  -u, --udp          Show only UDP connections

Examples:
  listports                    # Show all ports
  listports -p 3000           # Show only port 3000
  listports -t                # Show only TCP ports
  listports -u                # Show only UDP ports
  listports -p 5173 -t        # Show port 5173 TCP only

EOF
    return 0
  fi

  local lsof_args="-i"

  # Build lsof arguments based on options
  if [ -n "$specific_port" ]; then
    if [ "$protocol" = "tcp" ]; then
      lsof_args="-iTCP:$specific_port"
    elif [ "$protocol" = "udp" ]; then
      lsof_args="-iUDP:$specific_port"
    else
      lsof_args="-i:$specific_port"
    fi
  elif [ "$protocol" = "tcp" ]; then
    lsof_args="-iTCP"
  elif [ "$protocol" = "udp" ]; then
    lsof_args="-iUDP"
  fi
 
  echo -e "${_KILLPORTS_CYAN}Active network connections:${_KILLPORTS_NC}"
  echo -e "${_KILLPORTS_BLUE}COMMAND    PID    USER   FD   TYPE   DEVICE   SIZE/OFF   NODE   NAME${_KILLPORTS_NC}"
 
  lsof $lsof_args 2>/dev/null | tail -n +2 | while IFS= read -r line; do
    if [[ "$line" =~ LISTEN ]]; then
      echo -e "${_KILLPORTS_GREEN}$line${_KILLPORTS_NC}"
    else
      echo "$line"
    fi
  done
 
  if [ $? -ne 0 ] && [ -n "$specific_port" ]; then
    echo -e "${_KILLPORTS_YELLOW}No processes found using port $specific_port${_KILLPORTS_NC}"
  fi
}

# Remove any existing killports alias to avoid conflicts
unalias killports 2>/dev/null

# Kill processes using specified ports
killports() {
  local show_help=false
  local force_kill=false
  local list_before_kill=false
  local quiet=false
  local ports_to_kill=()
 
  if [ $# -eq 0 ]; then
    echo -e "${_KILLPORTS_RED}Error: No ports specified${_KILLPORTS_NC}" >&2
    echo "Use 'killports --help' for usage information."
    return 1
  fi
 
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help=true
        shift
        ;;
      -f|--force)
        force_kill=true
        shift
        ;;
      -l|--list)
        list_before_kill=true
        shift
        ;;
      -q|--quiet)
        quiet=true
        shift
        ;;
      -*)
        echo -e "${_KILLPORTS_RED}Error: Unknown option '$1'${_KILLPORTS_NC}" >&2
        echo "Use 'killports --help' for usage information."
        return 1
        ;;
      *)
        ports_to_kill+=("$1")
        shift
        ;;
    esac
  done
 
  if [ "$show_help" = true ]; then
    cat << 'EOF'
Usage: killports [OPTIONS] PORT...

Kill processes using specified ports

Arguments:
  PORT                Port number(s) or range(s) to kill

Options:
  -h, --help         Show this help message
  -f, --force        Skip SIGTERM, use SIGKILL directly
  -l, --list         List processes before killing
  -q, --quiet        Suppress output

Examples:
  killports 3000                    # Kill process on port 3000
  killports 3000 5173 8080         # Kill multiple ports
  killports 3000-3005              # Kill port range 3000 to 3005
  killports 5170-5180 3000         # Mix ranges and individual ports
  killports -f 3000                # Force kill immediately
  killports -l 5173                # Show process info before killing

Common development ports:
  3000, 3001...     # Next.js, Create React App
  5173, 5174...     # Vite dev server
  4173              # Vite preview
  8080, 8081...     # Various dev servers
  9000+             # Storybook, etc.

See also: listports

EOF
    return 0
  fi
 
  if [ ${#ports_to_kill[@]} -eq 0 ]; then
    echo -e "${_KILLPORTS_RED}Error: No ports specified${_KILLPORTS_NC}" >&2
    return 1
  fi
 
  # Expand all port ranges and validate
  local all_ports=()
  for port_arg in "${ports_to_kill[@]}"; do
    local expanded_ports
    if ! expanded_ports=$(_expand_port_range "$port_arg"); then
      return 1
    fi
    while IFS= read -r port; do
      all_ports+=("$port")
    done <<< "$expanded_ports"
  done
 
  # Remove duplicates and sort
  local unique_ports=($(printf '%s\n' "${all_ports[@]}" | sort -nu))
 
  [ "$quiet" = false ] && echo -e "${_KILLPORTS_CYAN}Processing ${#unique_ports[@]} port(s)...${_KILLPORTS_NC}"
 
  local killed_count=0
  local not_found_count=0
 
  for port in "${unique_ports[@]}"; do
    local pids
    pids=$(lsof -ti:"$port" 2>/dev/null)

    if [ -z "$pids" ]; then
      [ "$quiet" = false ] && echo -e "${_KILLPORTS_YELLOW}No process found on port $port${_KILLPORTS_NC}"
      ((not_found_count++))
      continue
    fi

    # Show process info if requested
    if [ "$list_before_kill" = true ] || [ "$quiet" = false ]; then
      echo -e "${_KILLPORTS_BLUE}Port $port processes:${_KILLPORTS_NC}"
      lsof -i:"$port" 2>/dev/null | tail -n +2 | while IFS= read -r line; do
        echo -e "${_KILLPORTS_GREEN}  $line${_KILLPORTS_NC}"
      done
    fi

    # Kill processes
    for pid in $pids; do
      local cmd_name
      cmd_name=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d '\n')

      if [ "$force_kill" = true ]; then
        [ "$quiet" = false ] && echo -e "${_KILLPORTS_RED}Force killing $cmd_name (PID: $pid) on port $port${_KILLPORTS_NC}"
        kill -9 "$pid" 2>/dev/null
      else
        [ "$quiet" = false ] && echo -e "${_KILLPORTS_YELLOW}Terminating $cmd_name (PID: $pid) on port $port${_KILLPORTS_NC}"
        kill -15 "$pid" 2>/dev/null

        # Wait a moment, then force kill if still alive
        sleep 0.5
        if kill -0 "$pid" 2>/dev/null; then
          [ "$quiet" = false ] && echo -e "${_KILLPORTS_RED}Force killing stubborn process (PID: $pid)${_KILLPORTS_NC}"
          kill -9 "$pid" 2>/dev/null
        fi
      fi

      ((killed_count++))
    done
  done
 
  if [ "$quiet" = false ]; then
    echo -e "${_KILLPORTS_GREEN}Summary: ${killed_count} process(es) killed, ${not_found_count} port(s) were already free${_KILLPORTS_NC}"
  fi
}

# Auto-completion for killports
_killports_completion() {
  local -a ports
  local current_word="${words[CURRENT]}"
 
  # Get currently listening ports
  while IFS= read -r line; do
    if [[ "$line" =~ :([0-9]+).*LISTEN ]]; then
      ports+=("${BASH_REMATCH[1]}")
    fi
  done < <(lsof -i -P -n 2>/dev/null | grep LISTEN)
 
  # Remove duplicates and sort
  ports=($(printf '%s\n' "${ports[@]}" | sort -nu))
 
  # Add options
  local -a options=(-h --help -f --force -l --list -q --quiet)
 
  _describe 'ports' ports
  _describe 'options' options
}

# Auto-completion for listports  
_listports_completion() {
  local -a options=(-h --help -p --port -t --tcp -u --udp)
  local -a ports
 
  # If previous word was -p or --port, suggest available ports
  if [[ "${words[CURRENT-1]}" == "-p" || "${words[CURRENT-1]}" == "--port" ]]; then
    while IFS= read -r line; do
      if [[ "$line" =~ :([0-9]+).*LISTEN ]]; then
        ports+=("${BASH_REMATCH[1]}")
      fi
    done < <(lsof -i -P -n 2>/dev/null | grep LISTEN)
    ports=($(printf '%s\n' "${ports[@]}" | sort -nu))
    _describe 'ports' ports
  else
    _describe 'options' options
  fi
}

# Register completions (only if not already registered)
if ! compdef -p killports >/dev/null 2>&1; then
    compdef _killports_completion killports
fi

if ! compdef -p listports >/dev/null 2>&1; then
    compdef _listports_completion listports
fi
