#!/usr/bin/env bash

set -e

SSH_ALIAS="real-incus-host"

echo "Setting up incus test vm"
ssh $SSH_ALIAS "incus delete outervm --force 2>/dev/null || true "
ssh $SSH_ALIAS "incus launch images:debian/13 outervm --vm -c limits.cpu=4 -c limits.memory=8GiB -d root,size=50GiB"

echo "Creating network if not created"
ssh $SSH_ALIAS "incus network create homebr0 --type=macvlan parent=enp1s0 2>/dev/null || true"

sleep 3
echo "Adding outervm to network"
ssh $SSH_ALIAS "incus config device add outervm eth0 nic network=homebr0"

sleep 3
echo "Installing open-ssh and sudo user"
ssh $SSH_ALIAS "incus exec outervm -- bash -c 'apt update && apt full-upgrade -y && apt install openssh-server sudo -y'"
ssh $SSH_ALIAS "incus exec outervm -- bash -c 'sudo useradd -m -s /bin/bash chris && sudo usermod -aG sudo chris && echo \"chris ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/chris_nopasswd'"
echo "Adding authorized keys to outervm"
ssh $SSH_ALIAS "incus file push ~/.ssh/authorized_keys outervm/home/chris/.ssh/authorized_keys --create-dirs"

ssh $SSH_ALIAS "incus exec outervm -- ip a"

echo "Host setup complete!"
