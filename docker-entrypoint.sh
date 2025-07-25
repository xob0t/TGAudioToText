#!/bin/bash

echo "Starting TGAudioToText..."
echo "Punctuation enabled: ${TG_PUNCTUATION_ENABLED}"

# Function to handle shutdown
cleanup() {
    echo "Shutting down..."
    jobs -p | xargs -r kill
    exit
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Start punctuation server only if enabled
if [ "${TG_PUNCTUATION_ENABLED}" = "true" ] || [ "${TG_PUNCTUATION_ENABLED}" = "True" ]; then
    echo "Starting punctuation server..."
    if [ -f "./punctuation/punctuation-server.py" ]; then
        python3 ./punctuation/punctuation-server.py &
        PUNCT_PID=$!
        echo "Punctuation server started with PID: $PUNCT_PID"
    else
        echo "Warning: Punctuation enabled but server script not found!"
    fi
else
    echo "Punctuation server disabled, skipping..."
fi

# Start the main application
echo "Starting TGAudioToText application..."
./tgaudio/TGAudioToText &
MAIN_PID=$!
echo "Main application started with PID: $MAIN_PID"

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit_code=$?
echo "Process exited with code: $exit_code"
exit $exit_code