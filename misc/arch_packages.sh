#!/bin/bash

sudo pacman -Syu

sudo pacman -S --noconfirm --needed wget cmake

# boost reqs
sudo pacman -S --noconfirm --needed base-devel python3 bzip2 zlib icu
