# DrClaw Dockerfile
FROM python:3.11-slim-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user BEFORE copying files (required for --chown)
RUN useradd -m -u 1000 drclaw

WORKDIR /app

# Copy project files with proper ownership
COPY --chown=drclaw:drclaw pyproject.toml uv.lock ./
COPY --chown=drclaw:drclaw drclaw ./drclaw
COPY --chown=drclaw:drclaw assets ./assets
COPY --chown=drclaw:drclaw scripts ./scripts

# Install Python dependencies
RUN pip install --no-cache-dir -e .

# Make entrypoint executable
RUN chmod +x /app/scripts/docker-entrypoint.sh

# Create data directory with proper ownership
RUN mkdir -p /data && chown drclaw:drclaw /data

# Expose web port
EXPOSE 8081

# Switch to non-root user
USER drclaw

CMD ["bash", "/app/scripts/docker-entrypoint.sh", "daemon"]
