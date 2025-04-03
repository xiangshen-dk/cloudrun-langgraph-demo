FROM python:3.13-slim-bookworm AS builder

# Install uv using pip
RUN pip install uv

# Set the working directory
WORKDIR /app

# Copy only the files needed
COPY README.md *.py pyproject.toml uv.lock* ./
COPY src/ ./src/

# Install dependencies using uv based on pyproject.toml
RUN VIRTUAL_ENV=./venv uv sync --active --frozen

# Stage 2: Runtime Stage - Copy only necessary artifacts
# Use the same Python 3.13 base image as the builder
FROM python:3.13-slim-bookworm AS runtime

# Create a non-root user and group
RUN groupadd --system app && useradd --system --gid app appuser

# Set the working directory
WORKDIR /app

# Copy installed packages and code from the builder stage's site-packages
COPY --from=builder /app/ .

# Switch to the non-root user
USER appuser

# Set the path and entrypoint
ENV PATH="/app/venv/bin:$PATH"
ENTRYPOINT ["python", "run_streamlit.py"]
