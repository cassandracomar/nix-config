#!/usr/bin/env bash

exec pinnacle client <<-EOT
Tag.get("$1"):switch_to()
EOT
