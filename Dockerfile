# DrClaw Dockerfile
FROM python:3.10-slim-bookworm

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY pyproject.toml uv.lock ./
COPY drclaw ./drclaw
COPY assets ./assets
COPY scripts ./scripts

# Install Python dependencies
RUN pip install --no-cache-dir -e .

# Make entrypoint executable
RUN chmod +x /app/scripts/docker-entrypoint.py

# Expose web port
EXPOSE 8081

USER root

CMD ["python", "/app/scripts/docker-entrypoint.py", "daemon"]
