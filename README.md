This script automatically creates a backup archive with Mondo.
Makes ISO file(s), uploads the file(s) to a FTP server, and supports backup rotation.

## Installation
For first use AND to migrate from previous versions.
```bash
sh +x install.sh
```

## Usage

```bash
Usage: mondobackup OPTIONS

General options:

  -c, --client               Client name (prefix of ISO file).
  -d, --dir                  Directory name (matches FTP folder).
  -r, --rotate               Amount of backups to keep (backup rotation) [default=2].
  -u, --username             Username for FTP upload.
  -p, --password             Password for FTP upload.
  -U, --url                  FTP location to upload (FQDN only).
  -R, --rate                 Bandwidth to allocate upload, check curl manual.
                             Put number followed with K (KB) or M (MB), no space, small letters OK.
  -h, --help                 Display this help and exit.
```

## Uninstall

```bash
sh +x install.sh --uninstall
```