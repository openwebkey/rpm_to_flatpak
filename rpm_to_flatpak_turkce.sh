#!/bin/bash

# Log dosyasının ismi
log_file="flatpak_rpm_changes.log"

# Flatpak kurulumları ve RPM silinmelerini takip eden değişkenler
installed_flatpaks=()
removed_rpms=()

# Önceki log dosyasını temizleyin (varsa)
> "$log_file"

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
    
    # Tüm Flatpak depolarında uygulamanın olup olmadığını kontrol et
    flatpak_search=$(flatpak search --app "$app")
    fedora_flatpak=$(echo "$flatpak_search" | grep "fedora" | grep -m 1 "$app")
    flathub_flatpak=$(echo "$flatpak_search" | grep "flathub" | grep -m 1 "$app")
    
    if [ ! -z "$fedora_flatpak" ]; then
        # Fedora Flatpaks'dan kur (eğer daha önce yüklenmediyse)
        if ! flatpak list --app | grep -q "$app"; then
            echo "Fedora Flatpaks deposundan $app kuruluyor..."
            flatpak install -y fedora "$app"
            installed_flatpaks+=("$app")  # Kurulan Flatpak'leri kaydet
        else
            echo "$app zaten Fedora Flatpaks'dan yüklü."
        fi
    elif [ ! -z "$flathub_flatpak" ]; then
        # Flathub'dan kur (eğer daha önce yüklenmediyse)
        if ! flatpak list --app | grep -q "$app"; then
            echo "Flathub deposundan $app kuruluyor..."
            flatpak install -y flathub "$app"
            installed_flatpaks+=("$app")  # Kurulan Flatpak'leri kaydet
        else
            echo "$app zaten Flathub'dan yüklü."
        fi
    else
        echo "$app ne Fedora Flatpaks ne de Flathub'da bulunamadı."
    fi
    
    echo "$app işleme alındı."
    
    # RPM sürümünü silmek isteyip istemediğinizi sorun
    if [[ $(flatpak list --app | grep "$app") ]]; then
        read -p "$app için RPM sürümünü silmek istiyor musunuz? (e/h): " choice
        if [[ "$choice" == "e" ]]; then
            echo "$app RPM sürümü kaldırılıyor..."
            sudo dnf remove -y "$app"
            removed_rpms+=("$app")  # Silinen RPM'leri kaydet
        else
            echo "$app RPM sürümü silinmedi."
        fi
    fi
done

# Tüm işlemler bitti, log dosyasına yazalım
echo "Kurulan Flatpak uygulamaları:" >> "$log_file"
for flatpak in "${installed_flatpaks[@]}"; do
    echo "$flatpak" >> "$log_file"
done

echo "" >> "$log_file"

echo "Silinen RPM uygulamaları:" >> "$log_file"
for rpm in "${removed_rpms[@]}"; do
    echo "$rpm" >> "$log_file"
done

echo "Log dosyası $log_file olarak kaydedildi."
echo "Tüm RPM uygulamaları kontrol edildi ve gerekli Flatpak'ler kuruldu."
