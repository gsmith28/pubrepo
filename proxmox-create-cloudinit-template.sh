# Create a new directory for our image building.
mkdir ubuntu-cloud-image
cd ubuntu-cloud-image

# Download the cloud image.
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Resize the image to 32GB. Feel free to change it to your desired size.
qemu-img resize jammy-server-cloudimg-amd64.img 32G

# Create a VM
qm create 8001 --name "ubuntu-2204-cloudinit-template" --ostype l26 \
    --memory 2048 \
    --agent 1 \
    --bios ovmf --machine q35 --efidisk0 local-lvm:0,pre-enrolled-keys=0 \
    --cpu host --socket 1 --cores 2 \
    --vga std,clipboard=vnc --serial0 socket  \
    --net0 virtio,bridge=vmbr0

# Attach the ubuntu cloud image onto the VM.
# Note that here ssd is my storage name. You'll need to replace it with yours.
qm importdisk 8001 jammy-server-cloudimg-amd64.img local-lvm

# Make the attached disk .
qm set 8001 \
     --scsihw virtio-scsi-pci \
     --virtio0 local-lvm:vm-8001-disk-1,discard=on

# Set  as the first boot device.
qm set 8001 \
     --boot order=virtio0


# Create a cloud-init drive.
qm set 8001 \
     --ide2 local-lvm:cloudinit

# make this directory if does not exist
mkdir /var/lib/vz/snippets/


# note needed to modify a differnt file for ssh logon to be allowed
cat << EOF | tee /var/lib/vz/snippets/vendor.yaml
#cloud-config
runcmd:
    - apt update
    - apt install -y avahi-daemon qemu-guest-agent
    - systemctl start qemu-guest-agent
    # Update to allow using password to log in over ssh
    - sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/10-cloudimg-settings.conf
    - reboot
timezone: America/Edmonton
EOF


# Configure your cloud-init drive. It will prompt you for a password

qm set 8001 \
     --cicustom "vendor=local:snippets/vendor.yaml"

qm set 8001 --ciuser $(read -p "What username do you want to create? " uservar; echo $uservar)

qm set 8001 \
     --cipassword $(openssl passwd -6 $CLEARTEXT_PASSWORD)
qm set 8001 \
     --sshkeys ~/.ssh/authorized_keys
qm set 8001 \
     --ipconfig0 ip=dhcp

qm template 8001

#cleanup

rm *
cd ..
rmdir ubuntu-cloud-image
