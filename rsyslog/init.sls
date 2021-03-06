{% from "rsyslog/map.jinja" import rsyslog with context %}

{% if 'selinux' in grains and grains.selinux.enabled == True %}
rsyslog_remote_logging_selinux:
  selinux.boolean:
    - name: nis_enabled
    - value: True
    - persist: True
{% endif %}

rsyslog:
  pkg.installed:
    - name: {{ rsyslog.package }}
  file.managed:
    - name: {{ rsyslog.config }}
    - template: jinja
    - source: salt://rsyslog/templates/rsyslog.conf.jinja
    - context:
      config: {{ salt['pillar.get']('rsyslog', {}) }}
  service.running:
    - enable: True
    - name: {{ rsyslog.service }}
    - require:
      {% if 'selinux' in grains and grains.selinux.enabled == True %}
      - selinux: rsyslog_remote_logging_selinux
      {% endif %}
      - pkg: {{ rsyslog.package }}
    - watch:
      - file: {{ rsyslog.config }}

workdirectory:
  file.directory:
    - name: {{ rsyslog.workdirectory }}
    - user: {{ rsyslog.runuser }}
    - group: {{ rsyslog.rungroup }}
    - mode: 755
    - makedirs: True

{% for filename in salt['pillar.get']('rsyslog:custom', ["50-default.conf"]) %}
{% set basename = filename.split('/')|last %}
rsyslog_custom_{{basename}}:
  file.managed:
    - name: {{ rsyslog.custom_config_path }}/{{ basename|replace(".jinja", "") }}
    {% if basename != filename %}
    - source: {{ filename }}
    {% else %}
    - source: salt://rsyslog/files/{{ filename }}
    {% endif %}
    {% if filename.endswith('.jinja') %}
    - template: jinja
    {% endif %}
    - watch_in:
      - service: {{ rsyslog.service }}
{% endfor %}
