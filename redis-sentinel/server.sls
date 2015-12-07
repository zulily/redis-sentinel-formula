{% from "redis-sentinel/map.jinja" import redis with context %}

{% set is_initial_install = salt['cmd.run']('/usr/bin/test -e /etc/init.d/redis-server || echo True')|default('False') %}

{{ redis.package }}:
  pkg.installed:
    - hold: true
    - service:
      - enable: true


/etc/init.d/redis-server:
  file.managed:
    - template: jinja
    - source: salt://redis-sentinel/files/redis-server
    - user: root
    - group: root
    - mode: 755
    - require:
      - pkg: {{ redis.package }}


/etc/redis/redis.conf:
  file.absent:
    - require:
      - pkg: {{ redis.package }}


/var/run/redis:
  file.directory:
    - user: redis
    - group: redis
    - dir_mode: 755
    - file_mode: 644
    - recurse:
        - user
        - group
        - mode
{%- if is_initial_install == 'True' %}
    - require:
      - pkg: {{ redis.package }}
{%- endif %}


/etc/init/redis-server-instance.conf:
  file.managed:
    - user: redis
    - group: redis
    - mode: 644
    - source: salt://redis-sentinel/files/redis-server-instance.conf
    - template: jinja
    - require:
      - pkg: {{ redis.package }}


{#
   redis-server should normally only be restarted for an initial install
#}
{% if is_initial_install == 'True' %}
redis_server_restart:
  cmd.run:
    - name: "killall -9 redis-server ; service redis-server start"
    - require:
      - file: /etc/init/redis-server-instance.conf
{% endif %}
