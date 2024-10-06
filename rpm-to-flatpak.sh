#!/bin/bash

# Log file name
log_file="flatpak_rpm_changes.log"

# Variables to track installed Flatpaks and removed RPMs
installed_flatpaks=()
removed_rpms=()

# Clear the previous log file (if it exists)
> "$log_file"

# List RPM packages
rpm_apps=$(rpm -qa --qf '%{NAME}\n')

# List system packages that cannot be found as Flatpak
excluded_apps=("kernel" "kernel-modules" "kernel-modules-extra" "xorg" "qemu" "netstandard" "alsa" "gnome-autoar" "ghc")

for app in $rpm_apps; do
    # Skip if the application is in the excluded_apps list
    if [[ " ${excluded_apps[@]} " =~ " ${app} " ]]; then
        echo "$app is a system package, skipping."
        continue
    fi

    echo "Found RPM installed application: $app"
    
    # Check if the application is available in the Fedora Flatpaks repository
    fedora_flatpak=$(flatpak search "$app" | grep -m 1 "$app")
    
    if [ ! -z "$fedora_flatpak" ]; then
        # Install from Fedora Flatpaks (if not already installed)
        if ! flatpak list --app | grep -q "$app"; then
            echo "Installing $app from the Fedora Flatpaks repository..."
            flatpak install -y fedora "$app"
            installed_flatpaks+=("$app")  # Save installed Flatpaks
        else
            echo "$app is already installed from Fedora Flatpaks."
        fi
    else
        # Search in Flathub if not found in Fedora Flatpaks
        flathub_flatpak=$(flatpak search "$app" | grep -m 1 "$app")
        
        if [ ! -z "$flathub_flatpak" ]; then
            # Install from Flathub (if not already installed)
            if ! flatpak list --app | grep -q "$app"; then
                echo "Installing $app from the Flathub repository..."
                flatpak install -y flathub "$app"
                installed_flatpaks+=("$app")  # Save installed Flatpaks
            else
                echo "$app is already installed from Flathub."
            fi
        else
            echo "$app was not found in either Fedora Flatpaks or Flathub."
        fi
    fi
    
    echo "$app has been processed."
    
    # Ask if the RPM version should be removed
    if [[ $(flatpak list --app | grep "$app") ]]; then
        read -p "Do you want to remove the RPM version for $app? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            echo "Removing RPM version of $app..."
            sudo dnf remove -y "$app"
            removed_rpms+=("$app")  # Save removed RPMs
        else
            echo "RPM version of $app was not removed."
        fi
    fi
done

# All processes are complete, write to log file
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
echo "All RPM applications have been checked and necessary Flatpaks have been installed."
