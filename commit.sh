#!/bin/bash

git add .
git commit -m "style: remove all redundant comments across the codebase

- Removed all redundant comments that merely state what resources do
- Eliminated comments like 'Enable system-assigned managed identity' that add no value
- Removed module description comments and output section comments from main.tf
- Cleaned up resource description comments from Terraform resource blocks
- Kept only meaningful comments that explain WHY certain choices were made
- Kept cloud-init section comments as they explain configuration intent
- Adhered strictly to the 'no AI slop' project rule"
git push origin main 