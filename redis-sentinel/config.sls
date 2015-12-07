{#
   User and group redis must exist for config ownership to be setup properly
#}

redis_user_group:
  user:
    - present
    - name: redis
    - system: True
    - shell: /bin/false
    - gid_from_name: True
    - fullname: "redis server"


{#-
   Go through our shard groups (from pillar), add instance config files, tied to shards, only
   if the current minion is a member
#}
{% set shard_groups = salt['pillar.get']('redis_sentinel:shard_groups', {}) %}
{%- for shard_group in shard_groups %}
  {%- for shard_group_name, shards in shard_group.iteritems() %}
    {%- for shard in shards %}
      {%- set shard_index = shard.keys()[0] %}
      {%- if grains['host'] in shard[shard_index]['members'] %}
/etc/redis/redis_{{ shard_group_name }}_{{ shard_index }}.conf:
  file.managed:
    - user: redis
    - group: redis
    - mode: 640
    - template: jinja
    - source: salt://redis-sentinel/files/redis_instance.conf
    - makedirs: true
    - context:
      shard_groups: {{ salt['pillar.get']('redis_sentinel:shard_groups', {}) }}
      instance_id: {{ shard_group_name }}_{{ shard_index }}
      port: {{ shard[shard_index]['port'] }}
      bind_ip: {{ shard[shard_index]['bind_ip'] }}
      redis_conf: {{ shard[shard_index]['redis_conf'] }}
      first_master: {{ shard[shard_index]['first_master'] }}

{#
   Each instance for which there is a configuration needs
   its own /var/lib/redis/<instance_id> directory
#}
/var/lib/redis/{{ shard_group_name }}_{{ shard_index }}:
  file.directory:
    - user: redis
    - group: redis
    - mode: 755
    - dir_mode: 755
    - file_mode: 660
    - makedirs: true
    - recurse:
        - user
        - group
        - mode

      {%- endif %}
    {%- endfor %}
  {%- endfor %}
{%- endfor %}

