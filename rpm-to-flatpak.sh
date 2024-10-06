#!/bin/bash

# RPM paketlerini listele
rpm_apps=$(rpm -qa --qf '%{NAME}\n')

# Flatpak olarak bulunamayacak sistem paketlerini listele
excluded_apps=("kernel" "kernel-modules" "kernel-modules-extra" "xorg" "qemu" "netstandard" "alsa" "gnome-autoar" "ghc")

for app in $rpm_apps; do
    # Uygulama excluded_apps listesindeyse atla
    if [[ " ${excluded_apps[@]} " =~ " ${app} " ]]; then
        echo "$app sistem paketi olduğundan atlandı."
        continue
    fi

    echo "RPM ile yüklü uygulama bulundu: $app"
    
    # Fedora Flatpaks deposunda uygulamanın olup olmadığını kontrol et
    fedora_flatpak=$(flatpak search "$app" | grep -m 1 "$app")
    
    if [ ! -z "$fedora_flatpak" ]; then
        # Fedora Flatpaks'dan kur (eğer daha önce yüklenmediyse)
        if ! flatpak list --app | grep -q "$app"; then
            echo "Fedora Flatpaks deposundan $app kuruluyor..."
            flatpak install -y fedora "$app"
        else
            echo "$app zaten Fedora Flatpaks'dan yüklü."
        fi
    else
        # Fedora Flatpaks'ta bulunamazsa Flathub'dan arama
        flathub_flatpak=$(flatpak search "$app" | grep -m 1 "$app")
        
        if [ ! -z "$flathub_flatpak" ]; then
            # Flathub'dan kur (eğer daha önce yüklenmediyse)
            if ! flatpak list --app | grep -q "$app"; then
                echo "Flathub deposundan $app kuruluyor..."
                flatpak install -y flathub "$app"
            else
                echo "$app zaten Flathub'dan yüklü."
            fi
        else
            echo "$app ne Fedora Flatpaks ne de Flathub'da bulunamadı."
        fi
    fi
    
    echo "$app işleme alındı."
done

echo "Tüm RPM uygulamaları kontrol edildi ve gerekli Flatpak'ler kuruldu."

