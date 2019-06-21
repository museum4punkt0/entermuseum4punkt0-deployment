# ResearchSpace @ museum4punkt0

*General hints and terminology:*

- In this document the machine where administrative tasks are performed is
  called *workstation*, the one(s) that are administered *host(s)*.
- The directory where you found this document on the workstation will be
  referred to as *project folder*.
- Most command examples in this document require that the current working
  directory is that project folder.
- Command and configuration examples in this document contain value placeholders
  enclosed by angle brackets, e.g. `<ip of host>` would be substituted with the
  IP address of a host.
- The project folder contains sensible information that would allow anyone who
  gains access to it to tamper with the administered hosts.
  - Encrypting hard disks, SSDs and other storage media is generally a good
    idea and supported by all major Desktop operating systems.
- There's also the document [CONTENTS.md](./CONTENS.md) that contain brief
  descriptions of the project folder's contents.


## Setting up Ansible

In order to administer a remote host, the workstation must have Ansible
installed. Instructions for common workstation operating systems are coming up.
Note that Windows is not supported, but [it is usable]([1]) from the
[Windows Subsystem for Linux (WSL)]([2]). You may also refer to
[Ansible's Installation Guide]([3]).

[1]: https://docs.ansible.com/ansible/2.8/user_guide/windows_faq.html#can-ansible-run-on-windows
[2]: https://docs.microsoft.com/en-us/windows/wsl/about
[3]: https://docs.ansible.com/ansible/2.8/installation_guide/intro_installation.html

### Ubuntu

    sudo add-apt-repository ppa:ansible/ansible
    sudo apt-get update
    sudo apt-get install ansible=2.7

### MacOS

An installation via [brew](https://brew.sh) is recommended:

    brew install ansible@2.7


### Useful Resources

- the [Ansible documentation](https://docs.ansible.com/ansible/2.8/index.html)
- the [Ansible module index](https://docs.ansible.com/ansible/2.8/modules_by_category.html)
- Ansible's [YAML reference](https://docs.ansible.com/ansible/2.8/YAMLSyntax.html)


## Initial setup of a remote host

The Docker daemon will be configured to use the `btrfs` volume driver and thus
the directory `/var/lib/docker` must reside on a filesystem of that type. The
necessary data volume should be configured during the installation of a host
operating system or as one of the very first post-installation steps.

Before Ansible can be used to configure a host, a target host needs to be
prepared *once*. This folder contains a script `janitor_setup.sh` that you can
transfer to the target, log into the machine and execute with administration
privileges. Given that you have the credentials to connect via `ssh`, you may do
that with one command from your workstation:

    ssh <user>@<host> 'sudo bash -s' < janitor_setup.sh


## Configuring users

*Additional user accounts are not required to execute Ansible playbooks, but it
is a good idea to have at least one person available to login on the hosts for
anything that is not automated with playbooks.*

Users that can login to the host must be configured by creating authentication
keys and adapting the project's configuration.

### Authentication keys

#### Linux / Unix / MacOS / WSL

1. The user creates a folder `~/.ssh` if not existant: `mkdir ~/.ssh`
2. S/he changes the working directory: `cd ~/.ssh`
3. A pair of keys for authentication is created.
  - `ssh-keygen -t ed25519 -f <username>_id`
  - as a result two files, `<username>_id` and `<username>_id.pub` are created
    in the current working directory
4. The configuration file `~/.ssh/config` is created or amended with such
  section:

```
Host <hostname>
    HostName <ip or resolvable name of the host>
    Port <sshd_port>
    User <username>
    IdentityFile ~/.ssh/<username>_id
    IdentitiesOnly yes
```

For the addresses refer to `HOSTS.md`.

The value for `<hostname>` can be arbritrary and later be used as destination
when invoking `ssh`:

    ssh <hostname>

#### Adapting the project configuration

In a suited variables file (e.g. `group_vars/all.yml`), the list of the `users`
variable is extended with a mapping that contains the user name in the field
with the same name and the *content* of the previously created
`<username>_id.pub` asssigned to the `pub_key` field.

Note that more specific variable files override the values of less specific
ones, they do not extend a list from a broader scope.


### Applying the configuration and connecting

The configured users are created on a host when the `setup-base-system`
playbook is applied (see next section).

The newly created users can then login to a shell with the `Host`'s value
from `.ssh/config`:

    ssh <hostname>

The first time a user logs into the host, s/he is required to change the
predefined user password (`ChangeMe`) to an individual one that must be at least
twelve characters long.

A common reason that may cause connection failures are too permissive access
rights on the workstation that can be fixed with:

    chmod u=rwx,go= ~/.ssh
    chmod u=rw,go= ~/.ssh/*

Users that are removed from `roles/users/vars/main.yml` are not automatically
deleted on the hosts, to do so a remaining user must execute

    ssh -t <hostname> sudo deluser <username>

## Setting up the base system

A host must be configured with the `setup-base-system.yml` playbook, it includes
the configuration of:

- users on the host operating system
- a repository for backups with [BorgBackup](https://borgbackup.readthedocs.io/)
  on an FTP server
- a local firewall and `sshd` hardening
- automated security updates of OS packages
- a Docker daemon
- a reverse proxy/load balancer (including an ACME client) and a task scheduler
  for other Docker services
- a variety of good practices and tools

A host's connection parameters must be set in the `hosts.yml` file (refer
[here](https://docs.ansible.com/ansible/2.8/user_guide/intro_inventory.html)
for details), and these variables can or must be set in either
`group_vars/all.yml` or `host_vars/<ansible_host>.yml`:

- `acme_email` (mandatory) - an email address that will be associated with the
  TLS certificates issued by [Let's encrypt](https://letsencrypt.org
- `backups_storage_path` (mandatory) - the path where an FTP resource is mounted
  for storing backup data
- `borg_repokey` (mandatory) - a password to unlock an encrypted BorgBackup
  respository, used on initialization and backup creation, can be changed
  manually on the repository and needs to be adjusted subsequently in the
  variables file
- `daily_reboot_time` (defaults to an empty string) - when a string in the form
  of `HH:MM` is provided, the host will be configured to reboot daily at that
  time
- `docker_compose_version` (default: `1.24.0`) - the desired compatibility
  version of Docker-Compose, compatibility here means that e.g it would be
  upgraded to `1.24.1` etc. but not `1.25.0`
- `docker_hub_token` (mandatory) - An authorization token for `hub.docker.com`
  that allows to pull all the desired images
- `docker_images_path` (mandatory) - the root path for image sources
- `docker_services_path` (mandatory) - the root path in which the configuration
  files of Docker-Compose project are stored
- `extra_packages` (defaults to an empty list) - a list of package names that
  shall be installed
- `ftp_host`, `ftp_user` and `ftp_password` (all mandatory) are the credentials
  for the FTP resource that is mounted to `backups_storage_path`
- `reboot_time_after_security_upgrades` (defaults to an empty string) - the host
  will be rebooted at this time (`HH:MM`) after security updates have been
  applied
- `sshd_port` (default: `22`) - the port on which the `sshd` is listening,
  if a change is desired, adjustments should be done manually on the host first,
  mind that the entry in `hosts.yml` needs to be adapted as well
  (`ansible_port`)
- `traefik_acme_storage_path` (default: `/var/lib/traefik/acme.json`) - the
  file where træfik's builtin ACME client stores its data
- `traefik_log_folder` (default: `/var/log/traefik`) - the location where
  træfik's access log files are written and rotated
- `ufw_allowed_incoming_ports` (defaults to `["80", "443"]`) - ports that other
  machines can connect to from the internet, the `sshd_port` is allowed (though
  throttled) in any case
- `users` (mandatory) - a list of mappings where the fields `name` and `pub_key`
  define a user by the desired name and the public part of an `ssh` key pair

The configuration can the be applied with from the workstation:

    ansible-playbook setup-base-system.yml

Or limited to one host, e.g. `msm40rs1`:

    ansible-playbook -l msm40rs1 setup-base-system.yml


## Deploying ResearchSpace instances

Once a host is prepared, any number of ResearchSpace instances can be
configured. Therefore the variable `researchspace_instances` of a host's
variable file needs to be added / amended. That variable is a list of mappings
where each mapping describes a desired instance. A mapping has these fields:

- `name_suffix` - a possibly arbritrary string that is used to distinguish the
  instance's configuration in the filesystem
- `web_domain` - the domain that this instance shall serve
- TODO document variables for image tags


Similarly to the base system configuration, this is apllied with:

    ansible-playbook researchspace.yml

Removing a mapping will not remove the instance configuration and data from the
host. To do so, log into the machine and:

    cd <docker_services_path>/researchspace-<name_suffix>
    docker-compose down

## Asssorted knowledge that may prove useful at some point

- All system users share the same access token that was created by logging in
  with the credentials of a user on `hub.docker.com` that has the privilege to
  access the image repository that contains the ResearchSpace image.
  - As a result any `docker login` or `docker logout` is effective for all
    users.
