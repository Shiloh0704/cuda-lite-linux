import re

config_path = '/var/tmp/kernel-src/.config'
with open(config_path, 'r') as f:
    content = f.read()

settings = {
    'CONFIG_LOCALVERSION': '"-cuda-lite"',
    'CONFIG_BLK_DEV_LOOP': 'y',
    'CONFIG_SQUASHFS': 'y',
    'CONFIG_SQUASHFS_XZ': 'y',
    'CONFIG_SQUASHFS_ZSTD': 'y',
    'CONFIG_OVERLAY_FS': 'y',
    'CONFIG_ISO9660_FS': 'y',
    'CONFIG_BLK_DEV_SR': 'y',
    'CONFIG_ATA': 'y',
    'CONFIG_ATA_PIIX': 'y',
    'CONFIG_SATA_AHCI': 'y',
    'CONFIG_SCSI': 'y',
    'CONFIG_BLK_DEV_SD': 'y',
    'CONFIG_VIRTIO_BLK': 'y',
    'CONFIG_VIRTIO_PCI': 'y',
    'CONFIG_ZLIB_INFLATE': 'y',
    'CONFIG_XZ_DEC': 'y',
    'CONFIG_ZSTD_DECOMPRESS': 'y'
}

for k, v in settings.items():
    pattern = re.compile(rf'^(# )?{k}[= ].*$', re.MULTILINE)
    replacement = f'{k}={v}'
    if pattern.search(content):
        content = pattern.sub(replacement, content)
    else:
        content += f'\n{replacement}\n'

with open(config_path, 'w') as f:
    f.write(content)

print("Updated kernel config with built-in live storage flags and LOCALVERSION=-cuda-lite.")
