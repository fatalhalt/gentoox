subarch: amd64
target: stage1
version_stamp: 20200101.graphite
rel_type: default
profile: default/linux/amd64/17.1
snapshot: latest
source_subpath: default/stage3-amd64-latest
compression_mode: pixz_x
decompressor_search_order: tar pixz xz lbzip2 bzip2 gzip
update_seed: yes
update_seed_command: --update --deep @world
portage_confdir: /root/releng/releases/weekly/portage/stages
portage_prefix: releng
