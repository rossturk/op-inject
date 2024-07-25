_op=${_op:-@op@}
_op=${_op//@/}

op_auth() {
    local config_file="$HOME/.cache/1p-session"
    
    [[ -f "$config_file" ]] && source "$config_file"
    
    if [[ -n "${OP_SESSION_TOKEN}" ]]; then
        if "$_op" whoami --session "${OP_SESSION_TOKEN}" >/dev/null 2>&1; then
            echo "Found valid 1Password session."
            return 0
        else
            echo "Existing 1Password session is invalid. Re-authenticating..."
            unset OP_SESSION_TOKEN
        fi
    else
        echo "No 1Password session. Authenticating..."
    fi
    
    max_retries=5
    retry_count=0
    while true; do
        OP_SESSION_TOKEN=$("$_op" signin --raw 2>&1)
        if [[ $? -eq 0 ]]; then
            echo "OP_SESSION_TOKEN=${OP_SESSION_TOKEN}" > "$config_file"
            echo "Authentication successful."
            break
        else
            retry_count=$((retry_count + 1))
            if [[ ${retry_count} -ge ${max_retries} ]]; then
                echo "Authentication failed."
                return 1
            else
                echo "Invalid password. Please try again."
            fi
        fi
    done
    
    export OP_SESSION_TOKEN
}

op_inject() {
    local env_var_name="$1"
    local vault="$2"
    local item="$3"
    local field="$4"
    
    if [ -z "$env_var_name" ] || [ -z "$vault" ] || [ -z "$item" ] || [ -z "$field" ]; then
        echo "Usage: inject_op_secret <env_var_name> <vault> <item> <field>"
        return 1
    fi
    
    if [ -z "$OP_SESSION_TOKEN" ]; then
        echo "Error: No 1Password session found"
        return 1
    fi
    
    local secret_value
    secret_value=$("$_op" --session "$OP_SESSION_TOKEN" item get "$item" --field "$field" --vault "$vault")
    
    if [ -z "$secret_value" ]; then
        echo "op '$item' -> not set"
        return 1
    fi
    
    export "$env_var_name=$secret_value"
    echo "op '$item' -> '$env_var_name'"
}

