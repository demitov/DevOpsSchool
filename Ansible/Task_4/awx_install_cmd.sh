#!/usr/bin/env sh

# клонирую awx 17.1.0 из git репозитория
git clone -b 17.1.0 https://github.com/ansible/awx.git

# добавляю репозитории CentOS: EPEL и Docker-CE
sudo dnf install epel-release
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf check-update
sudo dnf update

# Устанавливаю Docker
sudo dnf install docker-ce docker-ce-cli containerd.io

# Устанавливаю необходимые пакеты
sudo dnf install make git curl

# Обновляю глобальный pip3
sudo pip3 install --upgrade pip setuptools
sudo pip3 install ansible


# Добавляю репозиторий NodeJS и устанавливаю его
sudo curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash 
sudo yum install -y nodejs

# Включаю службу Docker и устанавливаю docker-compose с использование pip
sudo systemctl enable docker
sudo pip3 install docker-compose

# добавляю пользователя в группу docker
sudo newgrp docker
sudo usermod -aG docker $(whoami)

# запускаю сервис docker
sudo systemctl start docker

# оключаю SElinux
sudo nano /etc/selinux/config
# SELINUX=disabled

# анстраиваю необходимые параметры AWX перед установкой
cd awx/installer/
nano inventory 
# set passwords
# uncomment project_data_dir

# запускаю установку AWX
ansible-playbook -i inventory install.yml 
