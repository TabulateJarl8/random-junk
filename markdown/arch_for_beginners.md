# Update the repositories
```sh
sudo pacman -Sy
```

# Install a package
```sh
sudo pacman -S <package>
```

# Remove a package
```sh
sudo pacman -R <package>
```

# Remove a package and all of its dependencies
```sh
sudo pacman -Rns <package>
```

# Update the system
```sh
sudo pacman -Syu
```

# Install an AUR package
```sh
git clone https://aur.archlinux.org/<package-name>.git
cd <package-name>
makepkg -si
cd ..
rm -rf <package-name>
```

# Minecraft
https://aur.archlinux.org/packages/prismlauncher

# Install Java for development
```sh
sudo pacman -S jdk-openjdk
```

# Install Python
```sh
sudo pacman -S python
```