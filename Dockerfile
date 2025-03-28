FROM python:3.13-slim-bookworm AS builder

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=off \
    UV_SYSTEM_PYTHON=1

# Install uv using pip
RUN pip install uv

# Set the working directory
WORKDIR /app

# Copy only the files needed for dependency installation first to leverage caching
COPY *.py pyproject.toml uv.lock* ./
# If uv.lock doesn't exist yet, create an empty one so Docker doesn't complain
# RUN touch uv.lock

# Install runtime dependencies using uv based on pyproject.toml
# --system installs into the global site-packages
# This installs ONLY the dependencies listed in [project.dependencies]
RUN uv pip install --system --no-cache --only-deps .

# Copy the rest of the project source code
COPY src/ ./src/

# Install the project itself into the system site-packages
# --no-deps because dependencies were already installed in the previous step
RUN uv pip install --system --no-cache --no-deps .

# Stage 2: Runtime Stage - Copy only necessary artifacts
# Use the same Python 3.13 base image as the builder
FROM python:3.13-slim-bookworm AS runtime

# Set environment variables for Python (same as builder)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create a non-root user and group
RUN groupadd --system app && useradd --system --gid app appuser

# Set the working directory
WORKDIR /app

# Copy installed packages from the builder stage's site-packages
# *** IMPORTANT: Update the python version path here to 3.13 ***
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages

# Switch to the non-root user
USER appuser

ENTRYPOINT ["python", "run_streamlit.py"]
