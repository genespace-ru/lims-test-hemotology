#!/bin/bash

# 1. удалить лишние файлы вида [0-9]+-[0-9]+.*\.gz

# 2. отфильтровать файл all_vars
awk '$5+0 > start && $5+0 < end' tmp && mv tmp all_vars

# 3. заархивировать all_vars
bgzip all_vars

# 4. проиндексировать архив
tabix -C -s 1 -b 5 -e 5 all_vars.gz
