/etc/redis/shard_groups.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://redis-sentinel/files/shard_groups.conf
    - context:
      sentinel_port: {{ salt['pillar.get']('redis_sentinel:sentinel_port', '26379') }}
      shard_groups: {{ salt['pillar.get']('redis_sentinel:shard_groups', {}) }}

