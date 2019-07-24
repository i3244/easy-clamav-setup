# easy-clamav-setup
A shell-script to install minimal Clam AntiVirus packages, and to setup schedule for scanning job.

## Description
Setup virus protection to Linux is not so difficult, but it takes much time.

Even if I follow manuals, it's hard to identify the causes of unexpected behaviors, or to find correct settings.

Therefore, I focused on simple virus protection only for scheduled scan, and made a shell-script to automate setup.

It's not realtime scanning, but the process doesn't resident in memory, so it may fit to servers that are concerned impact on other processes, or also to powerless machines.

Free [Clam AntiVirus](http://www.clamav.net/) is used as anti-virus software via the script.

## Features

* Automate installing minimal packages to be used, scheduling scanning job, and setting moving infected files and logging.
* It's easy to customize scheduling, and directories/files to be excluded.
* If proxy is used, proxy settings are configured automatically.
* If SELinux is enforced, settings to be allowed scanning are configured automatically.
* The setup is idempotence.
* Only ClamAV is used, other extra softwares are not used.

## Requirement
CentOS 7

## Usage
The scanning job runs automatically after install, so you can know logged results with the following command.  
`journalctl -e -t easyclamav`

If infected files are found, you can find them moved into the $MOVE_DIRECTORY. The default location is `/var/tmp/infected_files`.

## Install
1. Clone from the following repository.  
[https://github.com/i3244/easy-clamav-setup.git](https://github.com/i3244/easy-clamav-setup.git)

2. Check and customize the settings in `easyclamav.conf` if you need.

3. Run `easyclamav_setup.sh` with root authority to setup.

4. `'Completed.'` is expected to display when finished normally.

## Contribution

## Licence

[MIT](https://github.com/tcnksm/tool/blob/master/LICENCE)

## Author

[i3244](https://github.com/i3244)
