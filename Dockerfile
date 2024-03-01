# Arch Audio Container - Docker/containerfile for running pro-audio applications for distrobox 
# Copyright (C) 2023 Brandon Hale.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

FROM archlinux:latest

RUN echo "[multilib]" >> /etc/pacman.conf
RUN echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
RUN echo "MAKEFLAGS=\"-j$(nproc)\"" >> /etc/makepkg.conf

# ARG pacman=pacman --noconfirm
RUN pacman -Syu --noconfirm

# Make pacman run faster
RUN pacman -S pacman-mirrorlist pacman-contrib --noconfirm
RUN cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup && sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup && rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

# This will make sure to use pipewire instead of jack
# Remove if you want the defaults of pro-audio
RUN pacman -S pipewire-jack --noconfirm

# Install all of the pro audio stuff and wanted packages
# Aspell is used for flyspell-mode in emacs
RUN pacman -S --needed pro-audio emacs aspell-en aspell-pt wofi --noconfirm 

# I need to fix this part as makepkg blocks building as root
# Install yay
RUN pacman -S base-devel wget git --noconfirm 
RUN useradd builder
RUN su builder bash -c 'cd /tmp && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -sr --needed --noconfirm'
RUN pacman -U /tmp/yay-bin/*.zst --noconfirm

# Make makepkg run really fast
RUN pacman -S zstd xz pigz pbzip2 lzlib --noconfirm

## Haven't worked on this, as it can be complicated to install
## yay doesn't work because it needs systemd for some reason
# Going to install plzip manually
#RUN su builder bash -c 'cd /tmp && git clone https://aur.archlinux.org/plzip.git && cd plzip && makepkg -sr --needed --noconfirm'
#RUN pacman -U /tmp/plzip/*.zst --noconfirm
#RUN echo "COMPRESSLZ=(plzip -c -f)" >> /etc/makepkg.conf

RUN echo "COMPRESSZST=(zstd -c -z -q --threads=0 -)" >> /etc/makepkg.conf
RUN echo "COMPRESSXZ=(xz -c -z --threads=0 -)" >> /etc/makepkg.conf
RUN echo "COMPRESSGZ=(pigz -c -f -n)" >> /etc/makepkg.conf
RUN echo "COMPRESSBZ2=(pbzip2 -c -f)" >> /etc/makepkg.conf

## I was originally going to do this, but
## it installs everything to the container's /root
## Not good, so I think it would be better to just download the script
## and then allow th user to install.
# Install cm-incudine
# from https://github.com/brandflake11/cm-incudine-docker/blob/main/Dockerfile
# Install cm-incudine, run my script after commenting out parts needed
# RUN git clone https://github.com/brandflake11/install-cm-incudine.git
# RUN cd install-cm-incudine && \
#     sed -i 's/^EMACS$/#EMACS/' install-cm-incudine.sh && \
#     sed -i 's/^PRO-AUDIO$/#PRO-AUDIO/' install-cm-incudine.sh && \
#     sed -i 's/^FOMUS-SETUP$/#FOMUS-SETUP/' install-cm-incudine.sh && \
#     sed -i 's/sudo pacman/pacman/' install-cm-incudine.sh && \
#     sed -i 's/    JACK/    #JACK/' install-cm-incudine.sh && \
#     chmod +x install-cm-incudine.sh && ./install-cm-incudine.sh && \
#     cp -i fomus ~/.fomus

# Download the install-cm-incudine script, perfect for running later. :)
RUN git clone https://github.com/brandflake11/install-cm-incudine.git

# Enable Color for pacman
RUN sed -i 's/^#Color/Color/' /etc/pacman.conf

# Enables some extra pipewire stuff
RUN pacman -S pipewire-alsa lib32-pipewire lib32-pipewire-jack lib32-pipewire-v4l2 pipewire-pulse pipewire-v4l2 --noconfirm
