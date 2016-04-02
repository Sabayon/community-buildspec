# -*- mode: ruby -*-
# vi: set ft=ruby :
file_to_disk='./docker_disk.vdi'
Vagrant.configure(2) do |config|
  config.vm.box = "Sabayon/spinbase-amd64"
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
     vb.gui = false
     vb.memory = "6096"
     vb.cpus = 3
  end

config.persistent_storage.enabled = true
config.persistent_storage.location = file_to_disk
config.persistent_storage.size = 210000
config.persistent_storage.format = false
config.persistent_storage.use_lvm = false
unless File.exist?(file_to_disk)
config.vm.provision "shell", inline: <<-SHELL
  set -e
  set -x
  if [ -f /etc/provision_env_disk_added_date ]
  then
   vgscan
   vgchange -a y
   echo "Provision runtime already done."
   exit 0
  fi
  dd if=/dev/zero of=/dev/sdb bs=512 count=1 conv=notrunc
  sudo pvcreate /dev/sdb
  vgcreate vg-docker /dev/sdb
  lvcreate -n datapool -L 190G vg-docker
  lvcreate -n metapool -L 10 vg-docker

  lvconvert -y --zero n --thinpool vg-docker/datapool --poolmetadata vg-docker/metapool

  date > /etc/provision_env_disk_added_date
SHELL
end

config.vm.provision "shell", inline: <<-SHELL
vgscan
vgchange -a y
  mkdir -p /usr/portage/licenses/
  rsync -av -H -A -X --delete-during "rsync://rsync.at.gentoo.org/gentoo-portage/licenses/" "/usr/portage/licenses/"
  ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept

  equo up && sudo equo u
  echo -5 | equo conf update
  equo i docker sabayon-devkit vixie-cron git wget curl ansifilter md5deep dev-perl/JSON dev-perl/libwww-perl dev-python/pip sys-fs/btrfs-progs
  pip install shyaml


  # docker expects device mapper device and not lvm device. Do the conversion.
  eval $( lvs --nameprefixes --noheadings -o lv_name,kernel_major,kernel_minor vg-docker | while read line; do
    eval $line
    if [ "$LVM2_LV_NAME" = "datapool" ]; then
      echo POOL_DEVICE_PATH=/dev/mapper/$( cat /sys/dev/block/${LVM2_LV_KERNEL_MAJOR}:${LVM2_LV_KERNEL_MINOR}/dm/name )
    fi
  done )

  mkdir /etc/systemd/system/docker.service.d/
  echo "[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --storage-driver=devicemapper --storage-opt dm.thinpooldev=${POOL_DEVICE_PATH} --storage-opt dm.basesize=200G -H fd://
  " > /etc/systemd/system/docker.service.d/vagrant_mount.conf


  systemctl daemon-reload

  systemctl enable docker
  systemctl start docker

  systemctl enable vixie-cron
  systemctl start vixie-cron
  crontab /vagrant/confs/crontab
  [ ! -d /vagrant/repositories ] && git clone https://github.com/Sabayon/community-repositories.git /vagrant/repositories
  timedatectl set-ntp true
  echo "@@@@ Provision finished, ensure everything is set up for deploy, suggestion is to reboot the machine to ensure docker is working correctly"
SHELL

config.vm.provision :shell, run: "always", inline: <<-SHELL
  vgscan
  vgchange -a y
  systemctl restart docker
SHELL

end
