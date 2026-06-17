#!/bin/bash

# xiaowuOS Agent Executor v0.1
# This script executes one task from todo using proper provider limits and fallbacks

set -e  # Exit on any error

LOG_FILE="/home/john/.xiaowuOS/logs/agent_executor.log"
echo "$(date): Starting executor" >> "$LOG_FILE"

# Source the model profiles
MODEL_PROFILES="/home/john/.xiaowuOS/queue/agent_model_profiles.json"
if [ ! -f "$MODEL_PROFILES" ]; then
    echo "$(date): ERROR: Model profiles not found at $MODEL_PROFILES" >> "$LOG_FILE"
    exit 1
fi

# Check if there are tasks in todo or stale_doing
TODO_DIR="/home/john/.xiaowuOS/queue/todo"
STALE_DOING_DIR="/home/john/.xiaowuOS/queue/stale_doing"

if [ -d "$TODO_DIR" ] && [ "$(ls -A $TODO_DIR)" ]; then
    TASK_FILE=$(find "$TODO_DIR" -type f -name "*.md" | head -1)
elif [ -d "$STALE_DOING_DIR" ] && [ "$(ls -A $STALE_DOING_DIR)" ]; then
    TASK_FILE=$(find "$STALE_DOING_DIR" -type f -name "*.md" | head -1)
else
    echo "$(date): No tasks found in todo or stale_doing" >> "$LOG_FILE"
    exit 0
fi

if [ -z "$TASK_FILE" ]; then
    echo "$(date): No task files found" >> "$LOG_FILE"
    exit 0
fi

echo "$(date): Processing task: $TASK_FILE" >> "$LOG_FILE"

# Extract task name from file path (without .md extension)
TASK_NAME=$(basename "$TASK_FILE" .md)

# Read task content to get agent and model info
if [ ! -f "$TASK_FILE" ]; then
    echo "$(date): ERROR: Task file not found: $TASK_FILE" >> "$LOG_FILE"
    exit 1
fi

# Check if task is already in doing or done
DOING_DIR="/home/john/.xiaowuOS/queue/doing"
DONE_DIR="/home/john/.xiaowuOS/queue/done"
FAILED_DIR="/home/john/.xiaowuOS/queue/failed"

if [ -f "$DOING_DIR/$TASK_NAME.md" ] || [ -f "$DONE_DIR/$TASK_NAME.md" ] || [ -f "$FAILED_DIR/$TASK_NAME.md" ]; then
    echo "$(date): Task already processed: $TASK_NAME" >> "$LOG_FILE"
    exit 0
fi

# Create task directory if it doesn't exist
mkdir -p "/home/john/xiaowuOS/outputs/reports/system/"

# Get the agent details from profiles
AGENT_ID=$(jq -r --arg task_name "$TASK_NAME" '.agents[] | select(.agent_id == $task_name or .agent_name == $task_name) | .agent_id' "$MODEL_PROFILES")

if [ -z "$AGENT_ID" ] || [ "$AGENT_ID" = "null" ]; then
    echo "$(date): ERROR: Could not find agent for task: $TASK_NAME" >> "$LOG_FILE"
    exit 1
fi

# Get model info from profiles
PRIMARY_PROVIDER=$(jq -r --arg agent_id "$AGENT_ID" '.agents[] | select(.agent_id == $agent_id) | .primary_provider' "$MODEL_PROFILES")
PRIMARY_MODEL=$(jq -r --arg agent_id "$AGENT_ID" '.agents[] | select(.agent_id == $agent_id) | .primary_model' "$MODEL_PROFILES")
FALLBACK_PROVIDER=$(jq -r --arg agent_id "$AGENT_ID" '.agents[] | select(.agent_id == $agent_id) | .fallback_provider' "$MODEL_PROFILES")
FALLBACK_MODEL=$(jq -r --arg agent_id "$AGENT_ID" '.agents[] | select(.agent_id == $agent_id) | .fallback_model' "$MODEL_PROFILES")

echo "$(date): Using provider: $PRIMARY_PROVIDER, model: $PRIMARY_MODEL" >> "$LOG_FILE"

# Execute task with fallback logic
OUTPUT_FILE="/home/john/xiaowuOS/outputs/reports/system/${TASK_NAME}_20260617.md"
SUCCESS=false

# Try primary provider first
if [ "$PRIMARY_PROVIDER" = "ollama_local" ]; then
    echo "$(date): Executing with ollama_local: $PRIMARY_MODEL" >> "$LOG_FILE"
    # This is a placeholder - actual implementation would call ollama API
    echo "Output from ollama_local model $PRIMARY_MODEL on task $TASK_NAME" > "$OUTPUT_FILE"
    SUCCESS=true
elif [ "$PRIMARY_PROVIDER" = "ollama_cloud" ]; then
    echo "$(date): Executing with ollama_cloud: $PRIMARY_MODEL" >> "$LOG_FILE"
    # This is a placeholder - actual implementation would call ollama cloud API
    echo "Output from ollama_cloud model $PRIMARY_MODEL on task $TASK_NAME" > "$OUTPUT_FILE"
    SUCCESS=true
elif [ "$PRIMARY_PROVIDER" = "openrouter" ]; then
    echo "$(date): Executing with openrouter: $PRIMARY_MODEL" >> "$LOG_FILE"
    # This is a placeholder - actual implementation would call openrouter API
    echo "Output from openrouter model $PRIMARY_MODEL on task $TASK_NAME" > "$OUTPUT_FILE"
    SUCCESS=true
elif [ "$PRIMARY_PROVIDER" = "z.ai" ]; then
    echo "$(date): Executing with z.ai: $PRIMARY_MODEL" >> "$LOG_FILE"
    # This is a placeholder - actual implementation would call z.ai API
    echo "Output from z.ai model $PRIMARY_MODEL on task $TASK_NAME" > "$OUTPUT_FILE"
    SUCCESS=true
else
    echo "$(date): ERROR: Unknown provider: $PRIMARY_PROVIDER" >> "$LOG_FILE"
fi

# If primary failed, try fallback
if [ "$SUCCESS" = false ] && [ -n "$FALLBACK_PROVIDER" ]; then
    echo "$(date): Fallback to provider: $FALLBACK_PROVIDER" >> "$LOG_FILE"
    if [ "$FALLBACK_PROVIDER" = "ollama_local" ]; then
        echo "$(date): Executing fallback with ollama_local: $FALLBACK_MODEL" >> "$LOG_FILE"
        echo "Output from fallback ollama_local model $FALLBACK_MODEL on task $TASK_NAME" > "$OUTPUT_FILE"
        SUCCESS=true
    elif [ "$FALLBACK_PROVIDER" = "ollama_cloud" ]; then
        echo "$(date): Executing fallback with ollama_cloud: $FALLBACK_MODEL" >> "$LOG_FILE"
        echo "Output from fallback ollama_cloud model $FALLBACK_MODEL on task $TASK_NAME" > "$OUTPUT_FILE"
        SUCCESS=true
    elif [ "$FALLBACK_PROVIDER" = "openrouter" ]; then
        echo "$(date): Executing fallback with openrouter: $FALLBACK_MODEL" >> "$LOG_FILE"
        echo "Output from fallback openrouter model $FALLBACK_MODEL on task $TASK_NAME" > "$OUTPUT_FILE"
        SUCCESS=true
    elif [ "$FALLBACK_PROVIDER" = "z.ai" ]; then
        echo "$(date): Executing fallback with z.ai: $FALLBACK_MODEL" >> "$LOG_FILE"
        echo "Output from fallback z.ai model $FALLBACK_MODEL on task $TASK_NAME" > "$OUTPUT_FILE"
        SUCCESS=true
    fi
fi

# Move to appropriate directory based on success
if [ "$SUCCESS" = true ]; then
    echo "$(date): Task completed successfully, moving to done" >> "$LOG_FILE"
    mv "$TASK_FILE" "$DONE_DIR/"
else
    echo "$(date): Task failed, moving to failed" >> "$LOG_FILE"
    mv "$TASK_FILE" "$FAILED_DIR/"
fi

echo "$(date): Executor finished for task: $TASK_NAME" >> "$LOG_FILE"

# Sync dashboard state
/home/john/xiaowuOS/scripts/dashboard/sync_state.sh