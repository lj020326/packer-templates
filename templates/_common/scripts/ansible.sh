#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-packer}

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    id=$ID
    os_version_id=$VERSION_ID

elif [ -f /etc/redhat-release ]; then
    id="$(awk '{ print tolower($1) }' /etc/redhat-release | sed 's/"//g')"
    os_version_id="$(awk '{ print $3 }' /etc/redhat-release | sed 's/"//g' | awk -F. '{ print $1 }')"
fi

if [[ $id == "ol" ]]; then
    os_version_id_short="$(echo $os_version_id | cut -f1 -d".")"
else
    os_version_id_short="$(echo $os_version_id | cut -f1-2 -d".")"
fi

#
#echo "==> Add packer user to sudoers."
#echo "${SSH_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${SSH_USER} && chmod 440 /etc/sudoers.d/${SSH_USER}
#
echo "==> Setup Ansible pipelining+sudo support"
sudo echo "Defaults !requiretty" >> /etc/sudoers.d/${SSH_USER} && sudo chmod 440 /etc/sudoers.d/${SSH_USER}
sudo sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

## ref: https://github.com/hashicorp/packer/issues/4623#issuecomment-315489018

## These SSH configuration values are set when the server comes up so that Packer can
## maintain a hanging, trafficless SSH connection. They're reverted by the ssh recipe.
##
#sed -i -e '/ClientAliveInterval 300/{ s/.*/ClientAliveInterval 1000/ }' /etc/ssh/sshd_config
#sed -i -e '/ClientAliveCountMax 0/{ s/.*/ClientAliveCountMax 3/ }'      /etc/ssh/sshd_config
#sed -i -e '/#TCPKeepAlive yes/{ s/.*/TCPKeepAlive yes/ }'               /etc/ssh/sshd_config
sudo echo "ClientAliveInterval 1000" >> /etc/ssh/sshd_config
sudo echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config
sudo service sshd restart

echo "==> Install latest ansible"
#pip3 install --upgrade pip ansible virtualenv
#pip3 install --upgrade pip ansible
## ref: https://github.com/pyca/pyopenssl/issues/559
#pip3 install --upgrade pip ansible virtualenv cryptography pyopenssl
#pip3 install --upgrade pip ansible cryptography pyopenssl
pip3 install --upgrade pip
pip3 install --upgrade ansible
#pip3 install --upgrade cryptography pyopenssl

pip3 install --upgrade netaddr

#ln -s /usr/local/bin/ansible /usr/bin/ansible
#ln -s /usr/local/bin/ansible-galaxy /usr/bin/ansible-galaxy
#ln -s /usr/local/bin/ansible-playbook /usr/bin/ansible-playbook
#ln -s /usr/local/bin/virtualenv /usr/bin/virtualenv

### setup ansible vault password
### ref: https://github.com/hashicorp/packer/issues/555#issuecomment-145749614
#echo {{user `ansible_vault_password`}} > ~/.vault_pass
#chmod 600 ~/.vault_pass

#echo "export PATH=$PATH:~/.local/bin" >> ~/.bash_profile

