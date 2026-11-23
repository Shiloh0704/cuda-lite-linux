import sys

base_cfg = "/mnt/c/Users/shilo/OneDrive/OS_Project/kernel/configs/config-6.12.117-stock.config"
out_cfg = "/mnt/c/Users/shilo/OneDrive/OS_Project/kernel/configs/config-6.12-custom-tailored.config"

with open(base_cfg, "r") as f:
    lines = f.readlines()

updates = {
    "CONFIG_GENERIC_CPU": "# CONFIG_GENERIC_CPU is not set\n",
    "CONFIG_MCORE2": "CONFIG_MCORE2=y\n",
    "CONFIG_X86_64_VERSION_3": "CONFIG_X86_64_VERSION_3=y\n",
    "CONFIG_MATH_EMULATION": "# CONFIG_MATH_EMULATION is not set\n",
    "CONFIG_IA32_EMULATION": "# CONFIG_IA32_EMULATION is not set\n",
    "CONFIG_X86_X32": "# CONFIG_X86_X32 is not set\n",
    "CONFIG_PREEMPT_NONE": "# CONFIG_PREEMPT_NONE is not set\n",
    "CONFIG_PREEMPT": "CONFIG_PREEMPT=y\n",
    "CONFIG_HZ_1000": "CONFIG_HZ_1000=y\n",
    "CONFIG_HZ_250": "# CONFIG_HZ_250 is not set\n",
    "CONFIG_HZ": "CONFIG_HZ=1000\n",
    "CONFIG_NO_HZ_FULL": "CONFIG_NO_HZ_FULL=y\n",
    "CONFIG_ZONE_DEVICE": "CONFIG_ZONE_DEVICE=y\n",
    "CONFIG_DEVICE_PRIVATE": "CONFIG_DEVICE_PRIVATE=y\n",
    "CONFIG_HMM_MIRROR": "CONFIG_HMM_MIRROR=y\n",
    "CONFIG_DMABUF_MOVE_NOTIFY": "CONFIG_DMABUF_MOVE_NOTIFY=y\n",
    "CONFIG_SYNC_FILE": "CONFIG_SYNC_FILE=y\n",
    "CONFIG_PCI_P2PDMA": "CONFIG_PCI_P2PDMA=y\n",
    "CONFIG_IOMMU_SUPPORT": "CONFIG_IOMMU_SUPPORT=y\n",
    "CONFIG_INTEL_IOMMU": "CONFIG_INTEL_IOMMU=y\n",
    "CONFIG_INTEL_IOMMU_DEFAULT_ON": "CONFIG_INTEL_IOMMU_DEFAULT_ON=y\n",
}

new_lines = []
seen = set()
for line in lines:
    matched = False
    for k, v in updates.items():
        if line.startswith(k + "=") or line.startswith("# " + k + " "):
            new_lines.append(v)
            seen.add(k)
            matched = True
            break
    if not matched:
        new_lines.append(line)

for k, v in updates.items():
    if k not in seen:
        new_lines.append(v)

with open(out_cfg, "w") as f:
    f.writelines(new_lines)

print(f"Tailored configuration successfully generated ({len(seen)} directives updated).")
