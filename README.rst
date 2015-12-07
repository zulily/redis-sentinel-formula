==============
redis-sentinel
==============

The redis-sentinel formula may be used to bring up highly available redis clusters of any size and sharding complexity, which futhermore takes advantage of multiple cores.  All in a matter of minutes.

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``redis-sentinel``
------------------
The main entry point, including all of the necessary state files to get a new redis + sentinel cluster built, assuming pillar data has first been created.  This is generally the only state that should ever be run, although, running subsequent runs is not believed to have any impact on a running cluster – the sentinel.conf file is not overwritten for example, sentinel maintains this file after redis is first started.

``config``
----------
The configuration states maintain separate redis configuration files for each redis server instance.  It also serves a couple of additional purposes which are to create instance working directories as specified in instance configuration files, and to ensure the redis user and group exist, so that permissions for the configuration files and working directories may be set appropriately.

``server``
----------
Installs redis-server.  It also overwrites the init.d script with a custom script that is multi-instance and shard group aware, removes the redis.conf (unused), creates /var/run/redis, and restarts redis with the replaced init script, post-first-install.

``sentinel``
------------
Creates the initial sentinel.conf file (only at install time), which is maintained exclusively by sentinel itself thereafter.  Installs a redis-sentinel upstart script and fires up the sentinel after the first install only.

``client``
----------
Installs client tools.

``shard_groups``
----------------
Creates /etc/redis/shard_groups.conf, a yaml file that may be used by apps to determine, in conjunction with sentinel, the current master and password for a particular shard index.  This configuration file is likely only useful for simple installs where a local sentinel is running that monitors all shard groups and indexes.  Note that this file is world-readable and contains passwords, using group permissions is an option for being able to unset the other read bit.

``performance``
---------------
Linux-specific performance tuning settings, currently just vm.overcommit_memory.  It is not currently possible to override or extend these in pillar data, but that might be a future enhancement to consider.


Definition of Terms Used in this Document
=========================================
+ **shard_group** - the ensemble of shards related a particular redis data store, such as sessions, or cached sql query results
+ **shard_index** - a single redis instance/partition that is a member of a shard_group, either running as a master or as a slave.  Stores a roughly equivalent amount of data as other shard_indexes with the same shard_group, depending on the sharding algorithm implemented
+ **instance_id** - the shard group name and shard index, for example, sessions_0, sessions_1


General Information and Tips
============================
+ The formula takes advantage of more than one core (redis is single-threaded), running a user-configurable number of instances on a node
+ The formula allows for running different shard groups on a single node.  For example, a single node could host shards for sessions and cached query results sets, within different instances
+ A "shard_group" is made up of one or more shard indexes.  A single node may be either a master or slave for multiple shard indexes making up a single shard_group
+ Redis clients may determine the current master by interacting with a sentinel that monitors a shard group
+ Redis has very little security baked in, passwords are used for client, slave and sentinel communication, but sentinel does not have users and does not use SSL.
+ Init scripts allow for easily performing an action on the sentinel, a single redis instance hosting a shard, all instances that are part of a shard_group and all instances configured to run on a server
+ redis and redis-server are never restarted following an initial install, even when configuration changes occur
+ If running on a masterless salt setup, make sure file_client: local is set, as well as file_roots and pillar_roots.


Getting Started
===============

+ Bring up any instances that will be part of the cluster, with base installs.
+ Make sure all cluster members have resolvable DNS records.
+ Update pillar data, setting passwords and configuring shard groups and indexes
+ Run the states on instances, e.g.:

::

  salt-call state.sls redis-sentinel -l debug

+ Verify the setup is correct:

::

  redis-cli -p 26379 sentinel masters
  redis-cli -p 26379 info

+ If it becomes necessary to re-run redis-sentinel states as if run during an initial install, run the following:

::

  killall redis-server
  rm -rf /etc/redis /etc/init.d/redis-server
  salt-call saltutil.refresh_pillar
  salt-call state.sls core/redis_sentinel -l debug


ToDo / Known Issues
===================
+ Add support for non-Debian-based distributions.
+ Add support for systemd.  Currently init and upstart are required -- the formula is only known to work on Ubuntu 14.04 at present.
+ Only short hostnames are presently used, having the option to use the fqdn may be a future enhancement.

License
=======

Apache License, version 2.0.  Please see LICENSE
