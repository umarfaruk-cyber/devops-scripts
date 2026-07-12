# Use Ubuntu as base image
FROM ubuntu:22.04

# Set working directory
WORKDIR /app

# Copy all scripts into container
COPY *.sh ./

# Make scripts executble
RUN chmod +x *.sh

# Set default command to run sysinfo.sh
CMD ["./sysinfo.sh"]
