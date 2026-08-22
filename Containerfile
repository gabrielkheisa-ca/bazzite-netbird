FROM ghcr.io/ublue-os/bazzite-gnome:stable

# Copy build script into the container
COPY build_files /tmp/build_files

# Run customization script and remove temporary script in the SAME layer
RUN chmod +x /tmp/build_files/build.sh && \
    /tmp/build_files/build.sh && \
    rm -rf /tmp/build_files

# Perform standard bootc lint check
RUN bootc container lint