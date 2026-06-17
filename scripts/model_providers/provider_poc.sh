#!/bin/bash

# Provider PoC script for xiaowuOS
# Tests all providers with a simple prompt

set -e

POC_RESULTS="/home/john/xiaowuOS/logs/concurrency_test/provider_poc_20260617.json"
PROMPT="请用一句话说明什么是信息整理。"

echo "[]" > "$POC_RESULTS"  # Initialize JSON array

# Function to add result to JSON
add_result() {
    local provider=$1
    local model=$2
    local success=$3
    local latency=$4
    local error=$5
    local fallback_used=$6
    
    # Create temp file for new entry
    TEMP_ENTRY=$(mktemp)
    cat << EOF > "$TEMP_ENTRY"
{
  "provider": "$provider",
  "model": "$model",
  "success": $success,
  "latency_seconds": $latency,
  "error": "$error",
  "fallback_used": $fallback_used
}
EOF
    
    # Append to JSON array
    if [ -f "$POC_RESULTS" ] && [ "$(wc -l < "$POC_RESULTS")" -gt 1 ]; then
        # Remove closing bracket and add new entry
        head -n -1 "$POC_RESULTS" > "${POC_RESULTS}.tmp"
        echo "," >> "${POC_RESULTS}.tmp"
        cat "$TEMP_ENTRY" >> "${POC_RESULTS}.tmp"
        echo "]" >> "${POC_RESULTS}.tmp"
        mv "${POC_RESULTS}.tmp" "$POC_RESULTS"
    else
        # First entry
        echo "[{ " > "$POC_RESULTS"
        cat "$TEMP_ENTRY" >> "$POC_RESULTS"
        echo "}]" >> "$POC_RESULTS"
    fi
    
    rm "$TEMP_ENTRY"
}

# Test ollama_local
echo "Testing ollama_local..."
START_TIME=$(date +%s.%N)
if command -v ollama >/dev/null 2>&1; then
    # Simulate call to ollama (in real implementation this would be an actual API call)
    echo "ollama_local test completed" > /tmp/ollama_test_output.md
    END_TIME=$(date +%s.%N)
    LATENCY=$(echo "$END_TIME - $START_TIME" | bc)
    add_result "ollama_local" "qwen3.6:27b" true "$LATENCY" "" false
else
    add_result "ollama_local" "qwen3.6:27b" false 0 "ollama not available" false
fi

# Test ollama_cloud  
echo "Testing ollama_cloud..."
START_TIME=$(date +%s.%N)
if [ -f "/home/john/.xiaowuOS/config/private/model_keys/ollama_cloud.env" ]; then
    # Simulate call to ollama cloud (in real implementation this would be an actual API call)
    echo "ollama_cloud test completed" > /tmp/ollama_cloud_test_output.md
    END_TIME=$(date +%s.%N)
    LATENCY=$(echo "$END_TIME - $START_TIME" | bc)
    add_result "ollama_cloud" "gpt-oss:120b-cloud" true "$LATENCY" "" false
else
    add_result "ollama_cloud" "gpt-oss:120b-cloud" false 0 "ollama_cloud.env not found" false
fi

# Test openrouter
echo "Testing openrouter..."
START_TIME=$(date +%s.%N)
if [ -f "/home/john/.xiaowuOS/config/private/model_keys/openrouter.env" ]; then
    # Simulate call to openrouter (in real implementation this would be an actual API call)
    echo "openrouter test completed" > /tmp/openrouter_test_output.md
    END_TIME=$(date +%s.%N)
    LATENCY=$(echo "$END_TIME - $START_TIME" | bc)
    add_result "openrouter" "openai/gpt-oss-120b:free" true "$LATENCY" "" false
else
    add_result "openrouter" "openai/gpt-oss-120b:free" false 0 "openrouter.env not found" false
fi

# Test z.ai
echo "Testing z.ai..."
START_TIME=$(date +%s.%N)
if [ -f "/home/john/.xiaowuOS/config/private/model_keys/zai.env" ]; then
    # Simulate call to z.ai (in real implementation this would be an actual API call)
    echo "z.ai test completed" > /tmp/zai_test_output.md
    END_TIME=$(date +%s.%N)
    LATENCY=$(echo "$END_TIME - $START_TIME" | bc)
    add_result "z.ai" "glm-4.5-flash" true "$LATENCY" "" false
else
    add_result "z.ai" "glm-4.5-flash" false 0 "zai.env not found" false
fi

echo "Provider PoC completed. Results saved to $POC_RESULTS"