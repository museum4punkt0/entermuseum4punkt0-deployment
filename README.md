# ResearchSpace @ museum4punkt0

*General hints and terminology:*

- In this document the machine where administrative tasks are performed is
  called *workstation*, the one(s) that are administered *host(s)*.
- The directory where you found this document on the workstation will be
  referred to as *project folder*.
- Most command examples in this document require that the current *working
  directory* is that project folder.
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
  TLS certificates issued by [Let's encrypt](https://letsencrypt.org)
- `assets_root_dir` (mandatory) - the directory path on the host where file
  assets are located
- `assets_web_domain` (mandatory) - the domain name that shall serve the asset
  files
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
- `docker_services_path` (default: `/opt/services`) - the root path in which the
  configuration files of Docker-Compose project are stored
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
- `blazegraph_image_tag` - the tag of the `metaphacts/blazegraph-basic` image
  that shall be used for the Blazegraph service
- `researchspace_image_tag` - the tag of the `metaphacts/researchspace` image
  that shall be used
- `extra_properties` - this *optional* field can contain a space-separated
  sequence of arbritrary Java configuration properties that are passed to the
  platform on invokation, e.g.
  `-Dconfig.environment.securityConfigStorageId=myapp`

Along with it a *single* web server for static assets is deployed.
These variables must be configured for it:

- `assets_root_dir` (mandatory) - the directory path on the host system that
  contains the assets
- `assets_web_domain` (mandatory) - the domain where the assets shall be
  retrieved from

Similarly to the base system configuration, this is apllied with:

    ansible-playbook researchspace.yml

Removing a mapping will not remove the instance configuration and data from the
host. To do so, log into the machine and:

    cd <docker_services_path>/researchspace-<name_suffix>
    docker-compose down --volumes

This can also be used when an instance has been corrupted, *all data is lost*.

There's also a script to synchronize a local folder on the workstation to the
assets folder on the host. It can be invoked from the *project folder* as
*working directory*:

    ./upload-folder <path>

where `<path>` is the folder that is to be synchronized. It's the last name
component of `<path>` that will be the top-level folder on the web server, e.g.
`./upload-folder ~/Downloads/yadda/yay` would result in a publicly available
`https://objects.example.org/yay/`.

IMPORTANT! The assets are mirrored *from* the workstation to the host. Any
changes to files on the host are lost by a synchronization. Also mind that
synchronization includes the deletion of files on the target that do not exist
in the source.


## Deploying ResearchSpace Apps

With the default configuration settings, one directory per instance will be
created at `/opt/services/researchspace-<name_suffix>`. This will contain a
directory names `apps` where
[ResearchSpace apps](http://researchspace.metaphacts.cloud/resource/Help:Apps)
can be added, e.g. by cloning from a `git` repository.

If a changed app requires a restart of the ResearchSpace platform, it can be
facilitated with:

    # first, all changed and added, but unneeded files *must* be removed, e.g.
    # with this very broad command. BEWARE that this might delete data that is
    # actually still needed. hence more specific deletion targets are highly
    # recommended.
    docker-compose exec platform sh -c "rm -r /runtime-data/*"

    docker-compose build --no-cache
    docker-compose up -d

(executed with the aforementioned directory as working directory.)


## Asssorted knowledge that may prove useful at some point

### Copying the 'runtime' app from a ResearchSpace instance

ResearchSpace facilitates the development of apps via a web-interface. The
resulting files are stored in the `/runtime-data` folder of the executing
environment. Here, that environment is a Docker managed container.
The ResearchSpace platform has an export function to download a zip-file with
the contents. In order to retrieve such contents, first the relevant container's
name must be figured out, best by running `docker-compose ps` in the designated
instance's definition directory on the host. The resulting list contains one
item that ends with `_platform_1`, the whole name is to be used in the command
to copy the contents to the user's directory:

    docker cp <container_name>:/runtime-data ~/<some_folder_name>

The result can then be copied to the workstation (where this command is invoked)
as well:

    scp -r <host>:~/<some_folder_name> <local_target_folder>

Be aware that the result has also other contents than just the changed
application files (`/runtime-data` *is not* an application) and the relevant
files must be selected manually for inclusion into the application's source
tree.


### Troubleshooting 101

As there is no monitoring system to watch the state and resource usage, trouble
may arise out of the blue. Here are some advices what to check in order to
determine the source:

Stay calm and carry on.

Are the domain names properly resolved? This is best answered by asking this
question from a client that cannot connect to a website from the command line
with `dig <domain name>` (or `nslookup …` on Windows). The answer should
contain the known IP addresses.

Can I login via `ssh`?
If not, use an RDP client to connect to the machine with the parameters that
are provided in `HOSTS.md`. If you can't login with your account at that point,
logging in with the `root` user's credentials is the last resort.

Though one measure might still be helping when none of these access attempts
are working: Login to the provider's website, navigate to the control panel
and restart the host. If that let's you access the system again, a further
inspection is necessary. If not, contact the support of your choice, contacting
the provider might be a good idea at this point.

Is there enough space on in the filesystems?
`df -h` can tell us. If none of the values in the `Use%` is as high as 98%,
there should be enough space. Nonetheless a value of 80% tells that the disk
usage should be investigated soon and steps be taken accordingly, a value of
90% makes that an immediate matter.

A general overview of the system's workload can be accessed with `sudo glances`.
Press `h` to show/hide all available keyboard shortcuts.

To check whether the network interface configuration is still valid, an
`ifconfig eth0` should also show the expected IP addresses. `route` should also
show that the `eth0` interface is used to connect to the default gateway.

At this point a reboot might solve any system hickups: `sudo reboot`

`docker ps` shows all running containers, `docker ps -a` includes those that
are not running and they may point to problems. Containers whose `STATUS` is
`Restarting` are likely to be failing continuously and must be investigated in
detail.

To get more detail, it is best to change to a service's project folder (e.g.
`/opt/services/traefik`). There the state of the services can be inspected with
`docker-compose ps`, the logs can be viewed in a pager with
`docker-compose --no-color | less`.

When a web application is malfunctioning it might be useful to watch all
HTTP requests - best in a separate terminal window - with
`sudo tail -f /var/log/traefik/access.log`. There can be some helpful indicators
there, like properly formed paths, returned status codes and response times.
Oh, on the other side, all major web browser have something like a "Developer
Tools" window for web pages that can tell their point of view on the request-
response-story in a tab often called "Network".

## Genesis, credits, license and re-use

This set of configuration declarations and related assets is part of the project
museum4punkt0 - Digital Strategies for the Museum of the Future. Further
information: https://www.museum4punkt0.de/en/

It has been developed by Martin Wagner on behalf of the Stiftung Preußischer
Kulturbesitz.

The project museum4punkt0 is funded by the Federal Government Commissioner
for Culture and the Media in accordance with a resolution issued by the German
Bundestag (Parliament of the Federal Republic of Germany).

The contents of this repository are licensed under the terms of
[CreativeCommons BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
See [LICENSE.txt](./LICENSE.txt).
