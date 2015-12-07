{% from "redis-sentinel/map.jinja" import redis with context %}


{% set is_initial_install = salt['cmd.run']('/usr/bin/test -e ' + redis.sentinel_conf_file + ' || echo True')|default('False') %}

/etc/init/redis-sentinel.conf:
  file.managed:
    - user: redis
    - group: redis
    - mode: 644
    - source: salt://redis-sentinel/files/redis-sentinel.conf
    - template: jinja
    - context:
      redis_server_bin: {{ redis.redis_server_bin }}
      sentinel_conf_file: {{ redis.sentinel_conf_file }}
      user: {{ redis.user }}
      group: {{ redis.group }}

{#
   sentinel maintains the sentinel.conf file after the initial install, so this state
   should not normally be run again unless sentinel is turned down for a cluster.  It
   will not recreate the file unless it has first been removed
#}
{% if is_initial_install == 'True' %}
{{ redis.sentinel_conf_file }}:
  file.managed:
    - source: salt://redis-sentinel/files/sentinel.conf
    - template: jinja
    - mode: 640
    - user: redis
    - group: redis
    - context:
      sentinel_port: {{ salt['pillar.get']('redis_sentinel:sentinel_port', '26379') }}
      shard_groups: {{ salt['pillar.get']('redis_sentinel:shard_groups', {}) }}

{#
   sentinel should normally only be started for an initial install
#}
sentinel_start:
  cmd.run:
    - name: "start redis-sentinel"
    - onlyif: salt-call test.sleep 15
    - require:
      - file: {{ redis.sentinel_conf_file }}
{#
#}
{% endif %}
