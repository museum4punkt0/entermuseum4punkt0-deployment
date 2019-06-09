# Die common-Rolle


## Konfigurationsvariablen

- `additional_filesystems`
  - eine Liste weiterer Pfade (neben `/`), die mit dem NRPE-Test `check_disk`
    überwacht werden sollen
  - per Default eine leere Liste
- `daily_reboot_time`
  - manche Dienste stehen besser täglich früh auf
  - per Default ein leerer String
- `extra_packages`
  - Softwarepakete, die auf einem Host installiert sein sollen
  - der Default ist eine leere Liste
- `reboot_time_after_security_upgrades`
  - kann verwendet werden, um eine Uhrzeit zu definieren, zu der ein Host
    gestartet wird sofern Sicherheitsaktualisierungen (automatisiert)
    eingespielt wurden
  - Default: `false`
