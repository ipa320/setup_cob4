<a id="top"/>

# Contents
- [robmuxinator](#robmuxinator)
  * [Usage](#usage)
  * [YAML file definiton](#yaml-file-definiton)

# robmuxinator
This script is a replacement for the `cob-command` script. The main focus was faster bootup and shutdown times. But it also adds more flexibility by more configuration options. It mainly offers the same functionality as `cob-command` with some additions like, waiting for slave pc's for boot up, shutting down slaves, wait for certain services to come up on slaves (useful for e.g. UR).

The script currently offers two main communication modes:
1. SSH communication over plain SSH commands via python `subprocess` (slower)
1. SSH communication over the python lib `paramiko` (faster - not stable yet)

`subprocess` is currently enabled by default but it is way slower than `paramiko`.

## Usage
### Basic Usage
start all sessions
```
sudo robmuxinator start
```
stop all unlocked sessions
```
sudo robmuxinator stop
```
restart all sessions - **without** `rosnode cleanup`
```
sudo robmuxinator restart
```
shutdown and restart robot
```
sudo robmuxinator shutdown
```

### Alias Usage
The common aliases still exist:

start all sessions
```
sudo cob-start
```
stop all unlocked sessions
```
sudo cob-stop
```
restart all sessions - **including** `rosnode cleanup`
```
sudo cob-restart
```
shutdown and restart robot
```
sudo cob-shutdown
```
Additional options can be passed to the aliases whith then get forwarded to `robmuxinator`.
E.g. it is possible to pass `-f` to `cob-stop` to also stop locked sessions.

### Robmuxinator Options
Stopping a particular session is easy, just name the session that you like to close together with the `-s / --sessions` option:
```
sudo robmuxinator -s session_to_stop stop
```

When you define a session as locked in the `cob.yaml` (i.e. `locked=true`), than a `cob-stop/robmuximator stop` will not stop the session. You can force shutting down a locked session with the `-f / --force` option:
```
sudo robmuxinator -f -s roscore stop
```

A different YAML file than the default `/etc/ros/cob.yaml` can be used with the `-c / --config` option:
```
sudo robmuxinator -c /path/to/cob.yaml start
```
### Help
To get the available commands and options with a brief description use
```
robmuxinator -h
```
or
```
robmuxinator --help
```
## YAML file definiton
The yaml file is defined in three sections

- global options
- hosts of the robot
- sessions of the hosts

### Example
```
# global options
timeout: 120

# hosts of robot
hosts:
  b1:
    os: linux
    user: robot
    port: 22
    check_nfs: false

# sessions of the hosts
sessions:
  roscore:
    host: b1
    user: robot
    command: "roscore"
    prio: 0
    wait_for_core: false
    locked: true
  bringup:
    host: b1
    user: robot
    command: "roslaunch cob_bringup robot.launch"
    prio: 1
```

### global options

    timeout: int 

(mandatory) Seconds to wait for a host on startup.


### hosts of robot

    os: string                      {linux, windows}

(mandatory) Operating system of the host.

    user: string                    default: robot

(optinal) User on the host machine. This user is used for sending ssh commands.
    
    port: int                       default: none

(optional) The port that is checked to determine if a service on the host already up
    
    check_nfs: bool                 default: true

(optinal) Host should be checked for NFS status. Only supported on linux.

### sessions of the hosts

    command: string

(mandatory) Bash command that is executed in the `tmux` session. A sessions without the `command` key will result in an exception.

    host: string                    default: hostname of localhost

(optional) Target host of the `tmux` session.

    user: string                    default: robot

(optional) Target user of the `tmux` session.

    wait_for_core: bool             default: true

(optional) Starts session only after `roscore` is available.

    prio: int                       default: 10

(optional) The priority of the session. Sessions with the same prio will be started concurrently. Smaller numbers have higher priority.

    locked: bool                    default: false

(optional) Locked sessions will not be closed on `stop` or `restart` (only if forced)

    pre_condition: string

(optional) A Basch command used as condition that needs to be fullfilled before the session can be started




<a href="#top">top</a>
