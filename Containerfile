FROM ghcr.io/ublue-os/bazzite-gnome:stable

# Copy build script into the container
COPY build_files /tmp/build_files

# Run the customization script
RUN /tmp/build_files/build.sh

# Perform standard bootc lint check
RUN bootc container lint