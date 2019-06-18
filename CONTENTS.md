# Contents of this repository

Some of the mentioned files contain sensible information and are thus not
included in the repository but to be delivered directly.

## `group_vars`

Contains variable definitions for the host groups defined in `hosts.yml`

## `host_vars`

Contains variable definitions for the hosts defined in `hosts.yml`

## `roles`

Roles provide declarations and assets to configure a host in order to fulfil a
certain, well, functional role. See
[this resource](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_reuse_roles.html)
for a general introduction.

### `roles/assets-webserver`

Deploys a simple web server to host static asset files.

### `roles/backups`

Facilitates backups with [BorgBackup](https://borgbackup.readthedocs.io) on an
FTP host.

### `roles/common`

Various general configurations of the host's operating system.

### `roles/deck-chores`

A service that acts as task scheduler for services that run in Docker
containers.

### `roles/docker`

Sets up a Docker daemon and Docker-Compose.

### `roles/researchspace`

Deploys [ResearchSpace](https://www.researchspace.org/) instances.

### `roles/traefik`

Deploys [træfik](https://traefik.io/) to act as reverse proxy, including
automated certificate acquisition from
[Let's encrypt](https://letsencrypt.org).

### `roles/users`

Configures users on all hosts.

## `ansible.cfg`

Ansible's configuration for this context.

## `hosts.yml`

Ansible's inventory of hosts.

## `janitor_id`, `janitor_setup.sh`

Identification file and setup of the user that executes Ansible's tasks on the
hosts.

## `researchspace.yml`

The Ansible playbook to deploy ResearchSpace instances.

## `setup-base-system.yml`

The Ansible playbook to configure a host for ResearchSpace deployments.

## `sync-assets.yml`

The Ansible playbook to mirror the static asset files from the workstation to
the host.

## `Vagrantfile`

Can be used to setup a test host with [Vagrant](https://www.vagrantup.com/).
