# vSPC.py #

## OVERVIEW ##

**vSPC.py** is a _Virtual Serial Port Concentrator_ (also known as a virtual serial port proxy) that makes use of the
[VMware telnet extensions][1].


### Features ###

- Point any number of virtual serial ports to a single vSPC.py server (great for cloned VMs)
- Multiplexed client connects: Multiple entities can interact with the same console. Also allows for gdb connections
  while monitoring the console.
- **Port mappings are "sticky"** - port number will stay constant as long as the VM or a client is connected, with a set
   expiration timer after all connections terminate
- vMotion is fully supported
- Query interface allows you to see VM name, UUID, port mappings on the vSPC.py server
- Clients can connect using standard telnet, binary mode is negotiated automatically


### Project History ###

This began as a fork of the **vSPC.py project**, hosted at [SourceForge][2], and written by **Zach Loafman** while at
**EMC Isilon**. It languished until it was forked by **Kevan Carstensen** on [GitHub][3] and extensively refactored
and enhanced.


#### Improvements ####

Changes introduced since the "SourceForge fork" include:
- SSL support for connections between ESX hosts and vSPC.py
- console activity logging
- a variety of other minor improvements

Kevan's fork _(at [GitHub][3a])_ was re-forked by **EMC Isilon** to address various bugs, as we began using it heavily
in our environment once more.


## System Requirements ##

At the time of the initial implementation _(circa 2011)_, **Python 2.5** or better is/_was_ required, due to use of the
``with`` statement and other syntax that was introduced in **Python 2.5**. It's being developed against **Python 2.6**,
however, since that's the currently-shipping version for **RHEL/CentOS 6**. Though **RHEL/CentOS 6** may still be used
"_in the wild_", the **Python 2.7** branch is probably the best recommendation in terms of **Python** -- it's shipping
with _(essentially)_ all "modern" distributions of "UNIX-like" operating systems.

**AS AN IMPORTANT NOTE:**
  _It's been witnessed that the **Python 3.x** series of releases **DO NOT** work._

**ADDITIONALLY:**
  _Due to the use of ``epoll`` in the server implementation_, **Linux is required**. Beyond the ``epoll`` requirement,
  there may be other issues associated with using **vSPC.py** on "_other OSs_", as large parts of **vSPC.py** were only
  developed, tested, and therefore **known to work** on Linux.


### VMware ESXi ###

At the time this documentation was originally created, **VMWare ESXi 4.1** through **5.5** are confirmed supported.


## USAGE ##

### Building the distribution ###

**NOTE**: _There remains some incomplete infomration in this section._ At some point, it is likely that this section
           will be "spun off" into a dedicated file _(think "**INSTALL.md**)_.

- building the **source** distribution
  ```
  ./setup.py sdist
  ```
- building the **binary** distribution
  ```
  ./setup.py bdist
  ```
- building **all** _(the "**python2-setuptools**" way)_
  ```
  ./setup.py build
  ```
- building an **rpm** package
  ```
  ./setup.py sdist
  rpmbuild -ta vSPC-<version>.tar.gz
  ```


### Running the Concentrator ###

You run the concentrator through the vSPCServer program. The vSPCServer
program is configurable with a number of options, documented below and
in the program's usage text. Without options, the program will listen
for VM connections on port 13770, listen for admin protocol connections
on port 13371, and, for each connected VM, starts a telnet server that
listens for and serves connections from clients to the VM end of the
virtual serial port. By default, the program listens for incoming proxy
connections on 0.0.0.0, and listens for incoming admin protocol & client
to VM connections on 127.0.0.1. Use the --proxy-port, --admin-port, and
--port-range-start to change the default port settings; use
--proxy-iface, --admin-iface, and --interface to change the default
interface settings.

As mentioned, vSPCServer starts a telnet server for each connected VM by
default; by connecting to these servers with a telnet client, one can
interact with connected VMs. vSPCServer also knows how to open
connections on demand to a specific VM; you can take advantage of this
behavior with the vSPCClient program. These connections do everything
that the automatically opened telnet servers do, and also allow clients
to lock VMs. The --no-vm-ports option disables automatically opened
telnet servers, forcing all client-to-VM traffic to use the vSPCClient
program. This may be desirable if you don't want a bunch of unused
network servers open on the same system as the concentrator, or if
locking is important to your use case (automatically opened telnet
server connections are incompatible with locking and will ignore it).

vSPCServer makes a best effort to keep VM to port number mappings
stable, based on the UUID of the connecting VM. Even if a VM
disconnects, client connections are maintained in anticipation of the VM
reconnecting (e.g. if the VM is rebooting). The UUID<->port mapping is
maintained as long as there are either client connections or as long as
the VM is connected, and even after this condition is no longer met, the
mapping is retained for --vm-expire-time seconds (default 24*3600, or
one day).

The backend of vSPCServer serves three major purposes:
- On initial load, all port mappings are retrieved from the backend.
The main thread maintains the port mappings after initial load, but the
backend is responsible for setting the initial map. (This design was
chosen to avoid blocking on the backend when a new VM connects.)
- The backend serves all admin connections (because it has full knowledge
of the mappings)
- The backend can fire off customizable hooks as VMs come and go, allowing
for persistence, or database tracking, or whatever.

By default, vSPCServer uses the "Memory" backend, which really just
means that no initial mappings are loaded on startup and all state is
retained in memory alone. The other builtin backend is the "File"
backend, which can be configured like so: --backend File -f /tmp/vSPC.

If '--backend Foo' is given but no builtin backend Foo exists, vSPC.py
tries to import module vSPCBackendFoo, looking for class vSPCBackendFoo.
Use --help with the desired --backend for help using that backend.

### Configuring VMs to connect to the concentrator ###

In order to configure a VM to use the virtual serial port concentrator, you must be running **ESXi 4.1+**. You must also
have a software license level that allows you to use networked serial ports.

First, add a networked virtual serial port to the VM. Configure it as follows:

```
    (*) Use Network
      (*) Server
      Port URI: vSPC.py
      [X] Use Virtual Serial Port Concentrator:
      vSPC: telnet://hostname:proxy_port
```
**NOTE**: Direction MUST be Server, and Port URI MUST be vSPC.py. 

where hostname is the FQDN (or IP address) of the machine running the
virtual serial port concentrator, and proxy_port is the port that you've
configured the concentrator to listen for VM connections on. Virtual
serial ports support TLS/SSL on connections to a concentrator.  To use
TLS/SSL, configure the serial port as above, except for the vSPC field,
which should specify telnets instead of telnet. For this to work
correctly, you'll also need to launch the server with the --ssl, --cert,
and possibly --key options.


## Authors ##

**As another point of note**: This section will likely be "_spun off_" into its own file, as well.
                              _(think **AUTHORS.md** or **CONTRIBUTORS.md**)_

- **Zach Loafman**
  + _initial implementation_
- **Kevan Carstensen**
  + _SSL support_
  + _logging backend_
  + _lazy client connections to VMs_
    * _internal work necessary to support lazy connections to VMs_
- **Dave Johnson**
  + _fixes for missing ``getopt`` modules and missing ``shelf.sync()`` calls_
- **Fabien Wernli**
  + _add options to configure listen interface_
  + _fix broken ``-f`` option_
  + _packaging improvements_
- **Casey Peel**
  + _simplified backend argument parsing_
  + _fixed various connection leaks_
  + _improved logging performance_
- **Gerad Munsch** <<gmunsch@unforgivendevelopment.com>>
  + _converted **shebangs** to prefer use of **Python 2.x**_
    * _improves compatibility with most any **POSIX**-based OS_
	  - _most notably, **Arch Linux**_
	  - _should work on pretty much anything -- **Debian 8**, **Arch Linux ARM**, etc..._
  +  _added **systemd** startup handlers and configuration_
  + _reformatted **markdown** documents, such as this one_




[1]:	<http://www.vmware.com/support/developer/vc-sdk/visdk41pubs/vsp41_usingproxy_virtual_serial_ports.pdf>
[2]:	<http://sourceforge.net/p/vspcpy/home/Home/>
[3]:	<https://github.com/isnotajoke>
[3a]:	<https://github.com/isnotajoke/vSPC.py>
