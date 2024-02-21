# Use the official Ubuntu 22.04 LTS image from Docker Hub
FROM ubuntu:22.04

# Update package lists and install necessary packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        wget \
        curl \
        unzip \
        sudo \
        git \
        cmake \
        ninja-build \
        gperf \
        ccache \
        dfu-util \
        device-tree-compiler \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-tk \
        python3-wheel \
        xz-utils \
        file \
        make \
        gcc \
        gcc-multilib \
        g++-multilib \
        libsdl2-dev \
        libmagic1

# Download and execute kitware-archive.sh
RUN wget https://apt.kitware.com/kitware-archive.sh && \
    chmod +x kitware-archive.sh && \
    sudo bash kitware-archive.sh

# Install West using pip3
RUN pip3 install --user -U west

# Update PATH to include ~/.local/bin
RUN echo 'export PATH=~/.local/bin:"$PATH"' >> ~/.bashrc && \
    /bin/bash -c "source ~/.bashrc"

# Create a directory for the Zephyr project
RUN mkdir -p ~/zephyrproject

# Initialize West and update the Zephyr project
RUN west init ~/zephyrproject && \
    cd ~/zephyrproject && \
    west update

# Export Zephyr using West
RUN cd ~/zephyrproject && \
    west zephyr-export

# Install requirements for Zephyr
RUN pip3 install --user -r ~/zephyrproject/zephyr/scripts/requirements.txt

# Download Zephyr SDK and verify checksum
RUN wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5/zephyr-sdk-0.16.5_linux-x86_64.tar.xz && \
    wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5/sha256.sum | shasum --check --ignore-missing

# Extract Zephyr SDK
RUN tar xvf zephyr-sdk-0.16.5_linux-x86_64.tar.xz

# Change directory to the extracted SDK
WORKDIR /root/zephyr-sdk-0.16.5

# Run setup.sh script
RUN ./setup.sh

# Copy openocd rules to /etc/udev/rules.d and reload udev rules
RUN sudo cp /root/zephyr-sdk-0.16.5/sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d && \
    sudo udevadm control --reload

# Check versions of installed tools
RUN cmake --version && \
    python3 --version && \
    dtc --version
