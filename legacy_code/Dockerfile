FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    gnucobol \
    libcob4 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY requirements.txt ./
RUN pip wheel --no-cache-dir --wheel-dir=/wheels -r requirements.txt

COPY main.cob ./
RUN cobc -x -o main.bin main.cob

FROM python:3.11-slim

WORKDIR /app

RUN useradd --create-home appuser

COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels /wheels/*

COPY --from=builder /workspace/main.bin ./
COPY app.py index.html accounts.txt interest.txt ./

# Install runtime library and Create wrapper script
RUN apt-get update && \
    # Install GnuCOBOL for main.bin
    apt-get install -y --no-install-recommends libcob4 && \
    rm -rf /var/lib/apt/lists/* && \
    # Create "main" wrapper script that the Python app will execute
    echo '#!/bin/sh' > main && \
    echo 'exec /app/main.bin ${COBOL_ARGS}' >> main && \
    # Make the wrapper script executable
    chmod +x main && \
    # Give the non-root user ownership of all application files
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]