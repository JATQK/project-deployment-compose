#!/bin/bash

# GitLotus Deployment Guide - Gum Terminal Interface
# This script provides a user-friendly terminal interface for deploying the GitLotus Docker Compose project

set -euo pipefail

# This compose function is a great addition!
compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose -p "$PROJECT_NAME" \
                   -f "$DOCKER_COMPOSE_FILE" \
                   --env-file "$ENV_FILE" \
                   "$@"
  elif command -v docker-compose >/dev/null; then
    docker-compose -p "$PROJECT_NAME" \
                   -f "$DOCKER_COMPOSE_FILE" \
                   --env-file "$ENV_FILE" \
                   "$@"
  else
    print_error "Neither 'docker compose' (plugin) nor 'docker-compose' (v1) was found. Please install Docker Compose."
    exit 1
  fi
}

# --- Configuration ---
DEFAULT_ENV_FILE="./.env.local"
DOCKER_COMPOSE_FILE="docker-compose.yaml"
PROJECT_NAME="gitlotus"
ENV_CACHE_FILE=".deploy_cache"
REQUIRED_ENV_VARS=("GITHUB_LOGIN_APP_ID" "GITHUB_LOGIN_APP_INSTALLATION_ID" "GITHUB_LOGIN_KEY" "GITHUB_LOGIN_SYSTEM_USER_NAME" "GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN")
ANALYSIS_SERVICE_VAR="OPENROUTER_API_KEY"

# --- Globals ---
ENV_FILE="$DEFAULT_ENV_FILE"
ANALYSIS_ENABLED=false
SERVICES=()
SERVICES_ARE_RUNNING=false

# --- UI Functions ---
print_status() { gum style --foreground 6 --bold "[INFO]" "$1"; }
print_error() { gum style --foreground 1 --bold "[ERROR]" "$1"; }
print_warning() { gum style --foreground 3 --bold "[WARNING]" "$1"; }
print_success() { gum style --foreground 2 --bold --border normal --padding "1 2" --margin "1 0" "✅ $1"; }

# --- Prerequisite Checks ---
check_gum() { if ! command -v gum &> /dev/null; then echo "Error: gum is not installed." && exit 1; fi; }
check_docker() { if ! command -v docker &> /dev/null || ! docker info >/dev/null 2>&1; then print_error "Docker is not installed or the daemon is not running." && exit 1; fi; }
check_docker_compose() { if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then print_error "Docker Compose is not installed." && exit 1; fi; }


# --- Environment and Service Initialization ---
get_docker_platform_arch() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64) echo "linux/amd64" ;;
        aarch64|arm64) echo "linux/arm64" ;;
        *)
            print_warning "Could not automatically determine Docker architecture for '$arch'. Defaulting to 'linux/amd64'."
            echo "linux/amd64"
            ;;
    esac
}

init_env_file() {
    gum spin --spinner dot --title "Creating environment file..." -- sleep 1
    local detected_arch
    detected_arch=$(get_docker_platform_arch)

    cat > "$ENV_FILE" << EOF
# Docker Platform Architecture (auto-detected)
DOCKER_PLATFORM=${detected_arch}

# App environment variables
POSTGRES_PASSWORD=your_postgres_password
GITHUB_LOGIN_APP_ID=your_github_app_id
GITHUB_LOGIN_APP_INSTALLATION_ID=your_installation_id
GITHUB_LOGIN_KEY=your_github_key
GITHUB_LOGIN_SYSTEM_USER_NAME=your_username
GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN=your_token

# Analysis environment variables (OPTIONAL - leave as placeholder to disable analysis-service)
OPENROUTER_API_KEY=your_openrouter_key_here
GEMINI_API_KEY=your_gemini_key
OPENROUTER_API_URL=your_openrouter_url
LMSTUDIO_API_URL=your_lmstudio_url
GEMINI_API_URL=your_gemini_url
EOF
    print_success "Environment file created: $ENV_FILE"
    print_status "Automatically set DOCKER_PLATFORM to '$detected_arch'."
    gum style --foreground 3 --bold --border normal --padding "1 2" --margin "1 0" \
        "⚠️ Please edit this file and configure your remaining values."
}

ensure_architecture_is_set() {
    if ! grep -q "^DOCKER_PLATFORM=" "$ENV_FILE" || grep -q "your_architecture" "$ENV_FILE"; then
        local detected_arch
        detected_arch=$(get_docker_platform_arch)
        print_status "DOCKER_PLATFORM is missing or not set; updating $ENV_FILE."

        if grep -q "^DOCKER_PLATFORM=" "$ENV_FILE"; then
            sed -i.bak "s|^DOCKER_PLATFORM=.*|DOCKER_PLATFORM=${detected_arch}|" "$ENV_FILE"
        else
            echo -e "\n# Docker Platform Architecture (auto-detected)\nDOCKER_PLATFORM=${detected_arch}" >> "$ENV_FILE"
        fi
    fi
}

purge_containers() {
    clear
    gum style --foreground 1 --bold --border normal --padding "1 2" \
        "🗑️ Container Purge" "" \
        "This will:" \
        "1. Stop all running containers" \
        "2. Deleting all rating rdf files" \
        "3. Remove all containers (running and stopped)" \
        "" "⚠️  This is irreversible!"

    if gum confirm "Really remove every Docker container?" --default=false; then
        print_status "Stopping any running containers…"
        docker container stop $(docker container ls -q) 2>/dev/null || true

        print_status "Clearing output RDF folder…"
        # adjust the path below if your RDF output directory lives elsewhere
        rm -rf "./output/rdf/"* 2>/dev/null || true
        print_success "✅ Output RDF folder cleared."

        print_status "Removing all containers…"
        docker container rm -f $(docker container ls -aq) 2>/dev/null || true

        print_success "✅ All containers have been removed."
        gum style --foreground 6 "Press any key to continue…"; read -n 1 -s
    else
        print_warning "Purge cancelled."
        sleep 1
    fi
}

find_env_files() {
    local env_files=()
    while IFS= read -r -d '' file; do
        local rel_path
        rel_path=$(realpath --relative-to="." "$file" 2>/dev/null || echo "$file")
        env_files+=("$rel_path")
    done < <(find . -type f -iname "*env*" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./scripts/*" -not -path "./${ENV_CACHE_FILE}" -print0 2>/dev/null)
    printf '%s\n' "${env_files[@]}"
}

select_env_file() {
    clear # Clear screen before showing a new full-screen prompt
    gum style --foreground 6 --bold --border normal --padding "1 2" "🔍 Environment File Configuration"
    local env_files
    env_files=$(find_env_files)

    local menu_options=()
    local file_paths=()

    if [ -n "$env_files" ]; then
        print_status "Found existing environment files."
        while IFS= read -r file; do
            if [ -n "$file" ]; then
                local basename_file=$(basename "$file")
                local dirname_file=$(dirname "$file")
                if [ "$dirname_file" = "." ]; then
                    menu_options+=("$basename_file")
                else
                    menu_options+=("$basename_file $(gum style --foreground 8 "($dirname_file)")")
                fi
                file_paths+=("$file")
            fi
        done <<< "$env_files"
    else
        print_warning "No existing environment files found."
    fi

    menu_options+=("📁 Use default path $(gum style --foreground 8 "($DEFAULT_ENV_FILE)")")
    menu_options+=("✏️  Enter custom path")

    local choice
    choice=$(gum choose --header "Select an environment file:" "${menu_options[@]}")

    if [[ "$choice" == *"📁 Use default path"* ]]; then
        ENV_FILE="$DEFAULT_ENV_FILE"
    elif [[ "$choice" == *"✏️  Enter custom path"* ]]; then
        ENV_FILE=$(gum input --placeholder "Enter path to your .env file" --value "$DEFAULT_ENV_FILE")
    else
        local selected_index=-1
        for i in "${!menu_options[@]}"; do
            if [[ "${menu_options[$i]}" == "$choice" ]]; then
                selected_index=$i
                break
            fi
        done
        ENV_FILE="${file_paths[$selected_index]}"
    fi

    if [ -z "$ENV_FILE" ]; then
        print_error "Environment file path cannot be empty."
        exit 1
    fi

    local env_dir
    env_dir=$(dirname "$ENV_FILE")
    [ ! -d "$env_dir" ] && mkdir -p "$env_dir"

    if [ ! -f "$ENV_FILE" ]; then
        print_warning "Environment file does not exist at: $ENV_FILE"
        if gum confirm "Do you want to create it now?" --default=true; then
            init_env_file
        else
            print_error "Environment file is required for deployment."
            exit 1
        fi
    fi
    
    print_success "Using new environment file: $ENV_FILE"
    echo "$ENV_FILE" > "$ENV_CACHE_FILE"
    print_status "Saved environment path for the next session."
    
    ensure_architecture_is_set
}

load_or_select_env_file() {
    if [ -f "$ENV_CACHE_FILE" ]; then
        local cached_path
        cached_path=$(cat "$ENV_CACHE_FILE")
        if [ -f "$cached_path" ]; then
            ENV_FILE="$cached_path"
            ensure_architecture_is_set
            return
        fi
    fi
    select_env_file
}

validate_env_variables() {
    local missing_vars=()
    local placeholder_vars=()
    set -o allexport
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +o allexport

    for var in "${REQUIRED_ENV_VARS[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        elif [[ "${!var}" == *"your_"* ]] || [[ "${!var}" == *"_here"* ]]; then
            placeholder_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ] || [ ${#placeholder_vars[@]} -gt 0 ]; then
        clear
        gum spin --spinner dot --title "Validating environment variables..." -- sleep 1
        gum style --foreground 1 --bold --border normal --padding "1 2" "Environment Configuration Issues Found"
        [ ${#missing_vars[@]} -gt 0 ] && echo "" && gum style --foreground 1 --bold "Missing variables:" && printf "  • %s\n" "${missing_vars[@]}"
        [ ${#placeholder_vars[@]} -gt 0 ] && echo "" && gum style --foreground 3 --bold "Variables with placeholder values:" && printf "  • %s\n" "${placeholder_vars[@]}"

        echo ""
        gum style --foreground 6 "Please edit your environment file: $ENV_FILE"
        if gum confirm "Edit the file now?" --default=true; then
            ${VISUAL:-${EDITOR:-nano}} "$ENV_FILE"
            validate_env_variables
        else
            return 1
        fi
    else
        return 0
    fi
}

initialize_services() {
    local base_services="worker-service query-service listener-service"
    local key_value="${!ANALYSIS_SERVICE_VAR:-}"
    if [[ -n "$key_value" && "$key_value" != *"your_"* && "$key_value" != *"_here"* ]]; then
      ANALYSIS_ENABLED=true
      SERVICES=($base_services "analysis-service")
    else
      if [[ "$key_value" == *"your_"* || "$key_value" == *"_here"* ]]; then
        print_warning "OPENROUTER_API_KEY is a placeholder. The 'analysis-service' will be skipped."
      fi
      ANALYSIS_ENABLED=false
      SERVICES=($base_services)
    fi
}

check_docker_images() {
    local images_to_build=()
    local images_to_pull=()
    local service_config

    service_config=$(compose config 2>/dev/null)

    for service in "${SERVICES[@]}"; do
        if echo "$service_config" | awk -v srv="$service" '$1 == srv":" {f=1} f&&/build:/{print "build";exit} f&&!/^[[:space:]]/{f=0}' | grep -q "build"; then
            images_to_build+=("$service")
        else
            local image_name
            image_name=$(echo "$service_config" | awk -v srv="$service" '$1==srv":"{f=1} f&&/image:/{print $2;exit} f&&!/^[[:space:]]/{f=0}')
            if [ -n "$image_name" ] && ! docker image inspect "$image_name" &>/dev/null; then
                images_to_pull+=("$service ($image_name)")
            fi
        fi
    done

    if [ ${#images_to_build[@]} -gt 0 ] || [ ${#images_to_pull[@]} -gt 0 ]; then
        clear
        gum style --foreground 6 --bold --border normal --padding "1 2" "Docker Image Status"
        if [ ${#images_to_build[@]} -gt 0 ]; then
            echo ""; gum style --foreground 2 "The following services will be built from source:"
            printf "  • %s\n" "${images_to_build[@]}"
        fi
        if [ ${#images_to_pull[@]} -gt 0 ]; then
            echo ""; gum style --foreground 3 "The following images will be pulled from a remote registry:"
            printf "  • %s\n" "${images_to_pull[@]}"
        fi
        echo ""
        gum style --foreground 6 "Press any key to continue..."; read -n 1 -s
    fi
}

check_service_status_state() {
    local running_services
    running_services=$(compose ps --services --filter "status=running" 2>/dev/null || true)
    
    if [ -n "$running_services" ]; then
        SERVICES_ARE_RUNNING=true
    else
        SERVICES_ARE_RUNNING=false
    fi
}


# --- Deployment Actions ---

build_from_scratch() {
    clear
    gum style --foreground 3 --bold --border normal --padding "1 2" "Build from Scratch" "" "This will:" "1. Stop and remove all existing containers" "2. Build fresh images for all services" "3. Start all services" "" "⚠️  This is a destructive action and may take several minutes."
    if gum confirm "Continue with build from scratch?" --default=false; then
        
        local cache_option=""
        local cache_choice
        cache_choice=$(gum choose "Build with Cache (Faster)" "Build without Cache (Force Rebuild)")
        
        if [[ "$cache_choice" == *"without Cache"* ]]; then
            cache_option="--no-cache"
            print_warning "Building without cache. This will be slower."
        else
            print_status "Building with cache."
        fi

        echo ""
        print_status "Building infrastructure from scratch..."
        compose down --remove-orphans
        compose build $cache_option "${SERVICES[@]}"
        compose up -d "${SERVICES[@]}"
        echo ""
        print_success "Infrastructure built and started successfully!"
        local analysis_msg=""
        $ANALYSIS_ENABLED && analysis_msg="• Analysis Service: http://localhost:9080"
        gum style --foreground 2 --bold --border normal --padding "1 2" --margin "1 0" "🚀 Services are now running:" "" "• Query Service: http://localhost:7080" "$analysis_msg" "• Other services running in background."
        gum style --foreground 6 "Press any key to continue..."; read -n 1 -s
    fi
}

restart_apis() {
    clear
    gum style --foreground 6 --bold "Select services to restart:"
    local selected_services
    selected_services=$(gum choose --no-limit "${SERVICES[@]}")

    if [ -n "$selected_services" ]; then
        local cache_option=""
        local cache_choice
        cache_choice=$(gum choose "Rebuild with Cache (Faster)" "Rebuild without Cache (Force Rebuild)")

        if [[ "$cache_choice" == *"without Cache"* ]]; then
            cache_option="--no-cache"
            print_warning "Rebuilding without cache. This will be slower."
        else
            print_status "Rebuilding with cache."
        fi

        echo ""
        print_status "Restarting selected services..."
        while IFS= read -r service; do
            print_status "Restarting $service..."
            compose stop "$service"
            compose build $cache_option "$service"
            compose up -d "$service"
            print_success "$service restarted"
        done <<< "$selected_services"
        echo ""
        print_success "All selected services have been restarted!"
    else
        print_warning "No services selected."
    fi
    sleep 1
}

show_service_status() {
    clear
    gum style --foreground 6 --bold --border normal --padding "1 2" "Service Status"
    echo ""
    print_status "Checking service status..."
    compose ps
    echo ""
    gum style --foreground 6 "Press any key to return to the menu..."
    read -n 1 -s
}

start_services() {
    clear
    print_status "Starting all services with 'docker-compose up -d'..."
    compose up -d "${SERVICES[@]}"
    print_success "Start command issued successfully!"
    sleep 1
}

stop_services() {
    clear
    gum style --foreground 3 --bold --border normal --padding "1 2" "Stop All Services" \
        "" "This will stop all running services without removing them."

    if ! gum confirm "Are you sure you want to stop all services?" --default=false; then
        return
    fi

    local running
    running=$(compose ps --services --filter "status=running")

    if [ -z "$running" ]; then
        print_warning "No services appear to be running under project '$PROJECT_NAME'."
        sleep 1
        return
    fi

    print_status "Stopping services: $running"
    compose stop $running

    local after
    after=$(compose ps --services --filter "status=running" || true)
    if [ -z "$after" ]; then
        print_success "All services stopped successfully!"
    else
        print_error "Failed to stop all services. Still running: $after"
    fi

    sleep 1
}

# --------------------- NEW: Restart analysis-service without cache ---------
restart_analysis_no_cache() {
  clear
  gum style --foreground 6 --bold --border normal --padding "1 2" "♻️  Restart analysis-service (No Cache)"

  if ! $ANALYSIS_ENABLED; then
    print_warning "analysis-service is disabled (no \$OPENROUTER_API_KEY). Nothing to restart."
    sleep 2
    return
  fi

  print_status "Stopping analysis-service…"
  compose stop analysis-service || true

  print_status "Pruning builder cache (optional)…"
  docker builder prune -f || true

  print_status "Rebuilding analysis-service WITHOUT cache, pulling latest bases…"
  compose build --no-cache --pull analysis-service

  print_status "Starting analysis-service (force recreate)…"
  compose up -d --force-recreate analysis-service

  print_success "analysis-service restarted without cache! 🚀"
  sleep 2
}

# --- Main Application Flow ---

main_menu() {
    while true; do
        # MODIFIED: Added clear command
        clear
        check_service_status_state

        local service_status_text="[ Services: $(gum style --foreground 1 STOPPED) ]"
        local toggle_option="▶️ Start All Services"
        if $SERVICES_ARE_RUNNING; then
            service_status_text="[ Services: $(gum style --foreground 2 RUNNING) ]"
            toggle_option="⏹️  Stop All Services"
        fi
        local env_status_text="[ Env: $(gum style --bold "$ENV_FILE") ]"

        echo ""
        gum style --foreground 6 --bold --border double --padding "1 2" --margin "1 0" "🐳 GitLotus Deployment - Main Menu"
        gum style --align center "$env_status_text" "$service_status_text"

        local choice
        choice=$(gum choose --header "Select an option:" \
            "$toggle_option" \
            "♻️ Restart analysis-service (No Cache)" \
            "🚀 Build from Scratch" \
            "🔄 Restart APIs" \
            "📊 Show Service Status" \
            "💣 Nuclear Purge" \
            "⚙️  Change Environment File" \
            "🚪 Exit")

        case "$choice" in
            "▶️ Start All Services") start_services ;;
            "⏹️  Stop All Services") stop_services ;;
            "🚀 Build from Scratch") build_from_scratch ;;
            "♻️ Restart analysis-service (No Cache)") restart_analysis_no_cache ;;
            "🔄 Restart APIs") restart_apis ;;
            "📊 Show Service Status") show_service_status ;;
            "💣 Nuclear Purge") purge_containers ;;  
            "⚙️  Change Environment File")
                select_env_file
                print_status "Re-validating new environment..."
                if ! validate_env_variables; then
                    print_error "The new environment file is invalid. Please fix it and try again."
                    sleep 3
                else
                    initialize_services
                    check_docker_images
                    print_success "Environment changed successfully!"
                    sleep 1
                fi
                ;;

            *) clear; gum style --foreground 6 --bold "Thank you for using the GitLotus Deployment Guide! 👋"; exit 0 ;;
        esac
    done
}

main() {
    # MODIFIED: Added clear command
    clear
    gum style --foreground 6 --bold --border double --padding "2 4" --margin "2 0" \
        "🌟 Welcome to the GitLotus Deployment Guide! 🌟"

    # Minimal output on startup
    check_gum
    check_docker
    check_docker_compose

    load_or_select_env_file

    if ! validate_env_variables; then
        print_error "Environment configuration is incomplete. Exiting."
        exit 1
    fi

    initialize_services
    check_docker_images
    
    # MODIFIED: Added clear command
    clear
    main_menu
}

main "$@"