#!/bin/bash

# Log file name
log_file="flatpak_rpm_changes.log"

# Variables to track Flatpak installations and RPM removals
installed_flatpaks=()
removed_rpms=()

# Clear the previous log file (if exists)
> "$log_file"

# List RPM packages
rpm_apps=$(rpm -qa --qf '%{NAME}\n')

# List system packages that won't be touched or available as Flatpaks
excluded_apps=("kernel" "kernel-core" "kernel-modules" "kernel-modules-extra" "xorg" "qemu" "netstandard" "alsa" "gnome-autoar" "ghc" "glibc" "dbus" "systemd" "gdm")

for app in $rpm_apps; do
    # Skip if the app is in the excluded_apps list (system packages)
    if [[ " ${excluded_apps[@]} " =~ " ${app} " ]]; then
        echo "$app is a system package, skipping."
        continue
    fi

    echo "Found application installed via RPM: $app"
    
    # Check if the application is available in any Flatpak repository
    flatpak_search=$(flatpak search --app "$app")
    fedora_flatpak=$(echo "$flatpak_search" | grep "fedora" | grep -m 1 "$app")
    flathub_flatpak=$(echo "$flatpak_search" | grep "flathub" | grep -m 1 "$app")
    
    if [ ! -z "$fedora_flatpak" ]; then
        # Install from Fedora Flatpaks (if not already installed)
        if ! flatpak list --app | grep -q "$app"; then
            echo "Installing $app from Fedora Flatpaks repository..."
            flatpak install -y fedora "$app"
            installed_flatpaks+=("$app")  # Save installed Flatpaks
        else
            echo "$app is already installed from Fedora Flatpaks."
        fi
    elif [ ! -z "$flathub_flatpak" ]; then
        # Install from Flathub (if not already installed)
        if ! flatpak list --app | grep -q "$app"; then
            echo "Installing $app from Flathub repository..."
            flatpak install -y flathub "$app"
            installed_flatpaks+=("$app")  # Save installed Flatpaks
        else
            echo "$app is already installed from Flathub."
        fi
    else
        echo "$app not found in either Fedora Flatpaks or Flathub."
    fi
    
    echo "$app has been processed."
    
    # Ask if you want to remove the RPM version
    if [[ $(flatpak list --app | grep "$app") ]]; then
        read -p "Do you want to remove the RPM version of $app? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            echo "Removing RPM version of $app..."
            sudo dnf remove -y "$app"
            removed_rpms+=("$app")  # Save removed RPMs
        else
            echo "RPM version of $app was not removed."
        fi
    fi
done

# Write to the log file after all operations
echo "Installed Flatpak applications:" >> "$log_file"
for flatpak in "${installed_flatpaks[@]}"; do
    echo "$flatpak" >> "$log_file"
done

echo "" >> "$log_file"

echo "Removed RPM applications:" >> "$log_file"
for rpm in "${removed_rpms[@]}"; do
    echo "$rpm" >> "$log_file"
done

echo "Log file saved as $log_file."
echo "All RPM applications were checked, and necessary Flatpaks were installed."
