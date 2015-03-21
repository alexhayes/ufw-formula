# UFW management module
{%- set ufw = pillar.get('ufw', {}) %}
{%- if ufw.get('enabled', False) %}
{% set default_template = ufw.get('default_template', 'salt://ufw/templates/default.jinja') -%}
{% set sysctl_template = ufw.get('sysctl_template', 'salt://ufw/templates/sysctl.jinja') -%}

ufw:
  pkg:
    - installed
  service.running:
    - enable: True
    - watch:
      - file: /etc/default/ufw
      - file: /etc/ufw/sysctl.conf
  ufw:
    - enabled
    - require:
      - pkg: ufw

/etc/default/ufw:
  file.managed:
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - source: {{ default_template }}

/etc/ufw/sysctl.conf:
  file.managed:
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - source: {{ sysctl_template }}

  {%- for service_name, service_details in ufw.get('services', {}).items() %}

    {%- for from_addr in service_details.get('from_addr', [None]) %}

      {%- set protocol  = service_details.get('protocol', None) %}
      {%- set from_port = service_details.get('from_port', None) %}
      {%- set to_addr   = service_details.get('to_addr', None) %}

ufw-svc-{{service_name}}-{{from_addr}}:
  ufw.allowed:
    - protocol: {{protocol}}
    {%- if from_addr != None %}
    - from_addr: {{from_addr}}
    {%- endif %}
    {%- if from_port != None %}
    - from_port: "{{from_port}}"
    {%- endif %}
    {%- if to_addr != None %}
    - to_addr: {{to_addr}}
    {%- endif %}
    - to_port: "{{service_name}}"
    - require:
      - pkg: ufw

    {%- endfor %}

  {%- endfor %}

  # Applications
  {%- for app_name in ufw.get('applications', []) %}

ufw-app-{{app_name}}:
  ufw.allowed:
    - app: {{app_name}}
    - require:
      - pkg: ufw

  {%- endfor %}
  
  # Interfaces
  {%- for interface in ufw.get('interfaces', []) %}

ufw-interface-{{interface}}:
  ufw.allowed:
    - interface: {{interface}}
    - require:
      - pkg: ufw

  {%- endfor %}

{% else %}
  #ufw:
    #ufw:
      #- disabled
{% endif %}
