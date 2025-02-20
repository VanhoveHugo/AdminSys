#!/bin/bash

# Mise à jour et installation de SSH + firewall
apt-get update && apt-get install -y openssh-server ufw iputils-ping

# Création de l'utilisateur non root
useradd -m -s /bin/bash monuser
echo "monuser:password" | chpasswd
mkdir -p /home/monuser/.ssh
chown -R monuser:monuser /home/monuser/.ssh

# Configuration du SSH sur le port 2222
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
echo "AllowUsers monuser" >> /etc/ssh/sshd_config

# Redémarrer SSH seulement si la configuration est valide
mkdir -p /run/sshd
/usr/sbin/sshd -t
if [ $? -ne 0 ]; then
  echo "Erreur dans la configuration SSH"
  exit 1
fi

# Configuration du firewall (UFW)
ufw allow 2222/tcp
ufw --force enable

# Blocage de la communication entre VM2 et VM3
if [ "$(hostname)" == "vm2" ]; then
  ufw deny out to 192.168.1.30
  ufw deny in from 192.168.1.30
elif [ "$(hostname)" == "vm3" ]; then
  ufw deny out to 192.168.1.20
  ufw deny in from 192.168.1.20
fi

mkdir -p /run/sshd  # Créer le dossier nécessaire à SSH
ssh-keygen -A        # Générer les clés SSH si absentes
exec /usr/sbin/sshd -D