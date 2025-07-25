FROM mcr.microsoft.com/dotnet/sdk:3.1-alpine as build
WORKDIR /src
COPY *.csproj ./
RUN dotnet restore
COPY . ./
RUN dotnet build . -o /app

# Use official .NET runtime on Alpine - 50% smaller than Ubuntu!
FROM mcr.microsoft.com/dotnet/runtime:3.1-alpine as runtime

# Install dependencies using Alpine package manager
RUN apk add --no-cache ffmpeg

# Conditionally install punctuation dependencies
ARG PUNCTUATION_ENABLED=false
RUN if [ "$PUNCTUATION_ENABLED" = "true" ]; then \
    echo "Installing punctuation dependencies..." && \
    apk add --no-cache python3 py3-pip git && \
    pip3 install git+https://huggingface.co/kontur-ai/sbert_punc_case_ru; \
    fi

# Copy application
COPY --from=build /app /app/tgaudio

# Copy punctuation files to the working directory
COPY ./punctuation /app/tgaudio/punctuation

# Copy entrypoint script and fix line endings + permissions
COPY ./docker-entrypoint.sh /app/tgaudio/docker-entrypoint.sh
RUN sed -i 's/\r$//' /app/tgaudio/docker-entrypoint.sh && \
    chmod +x /app/tgaudio/docker-entrypoint.sh

# Run punctuation setup if enabled
RUN if [ "$PUNCTUATION_ENABLED" = "true" ]; then \
    cd /app/tgaudio && python3 ./punctuation/punctuation-server-setup.py; \
    fi

# Set working directory to where the app and script are
WORKDIR /app/tgaudio

CMD ["./docker-entrypoint.sh"]