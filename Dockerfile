# Build stage
FROM python:3.11-slim AS builder

WORKDIR /build

COPY Pipfile .

RUN pip install --no-cache-dir pipenv && \
    pipenv lock --python 3.11 && \
    pipenv requirements > requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM gcr.io/distroless/python3-debian12

WORKDIR /app

COPY --from=builder /usr/local/lib/python3.11/site-packages /app/site-packages
COPY code /app/code

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/site-packages

ENTRYPOINT ["/usr/bin/python3"]
CMD ["/app/code/main.py"]
