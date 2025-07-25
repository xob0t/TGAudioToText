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

# Copy application to /app/tgaudio (matching working structure)
COPY --from=build /app /app/tgaudio

# Set working directory to /app (NOT /app/tgaudio)
WORKDIR /app

# Copy entrypoint script to /app/ (matching working structure)
COPY ./docker-entrypoint.sh /app/docker-entrypoint.sh
RUN sed -i 's/\r$//' /app/docker-entrypoint.sh && \
    chmod +x /app/docker-entrypoint.sh

# Copy punctuation files to /app/punctuation (matching working structure)
COPY ./punctuation /app/punctuation

# Run punctuation setup if enabled
RUN if [ "$PUNCTUATION_ENABLED" = "true" ]; then \
    python3 ./punctuation/punctuation-server-setup.py; \
    fi

CMD ["./docker-entrypoint.sh"]