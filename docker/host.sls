{% from "docker/map.jinja" import host with context %}
{%- if host.enabled %}

include:
- .containers

docker_packages:
  pkg.latest:
  - pkgs: {{ host.pkgs }}

network.ipv4.ip_forward:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1

{%- if grains.os == 'Ubuntu' %}

/etc/default/docker:
  file.managed:
  - source: salt://docker/files/default
  - template: jinja
  - require:
    - pkg: docker_packages
  - watch_in:
    - service: docker_service

{%- endif %}

docker_service:
  service.running:
  - name: {{ host.service }}
  - require:
    - pkg: docker_packages

{% if host.install_docker_py %}
docker-py-requirements:
  pkg.installed:
    - name: python-pip
  pip.installed:
    - name: pip
    - upgrade: True

docker-py:
  pip.installed:
    {%- if "pip_version" in host %}
    - name: docker-py {{ host.pip_version }}
    {%- else %}
    - name: docker-py
    {%- endif %}
    - require:
      - pkg: docker_packages
      - pip: docker-py-requirements
    - reload_modules: True
{% endif %}

{%- if host.registry is defined %}

{%- for name,registry in host.registry.iteritems() %}

docker_{{ registry.address }}_login:
  cmd.run:
  - name: 'docker login -u {{ registry.user }} -p {{ registry.password }} {{ registry.address }}'
  - unless: grep {{ registry.address }} /root/.docker/config.json

{%- endfor %}

{%- endif %}

{%- endif %}