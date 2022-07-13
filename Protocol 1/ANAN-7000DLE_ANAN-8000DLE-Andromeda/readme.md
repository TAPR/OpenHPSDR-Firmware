All 7000DLE and Andromeda's shipped from Apache after 1 July 2022, those with serial numbers DX8300497A and higher, are shipped with, and require, different firmware than all other 7000 variants.

This was caused by parts availability/obsolescence issues that forced a change to the FPGA part number.

The older boards used an EP4CGX150F896. The new boards use an EP4CE115F29C8N.

The newer boards are known as the Orion MKIII. There were also part number changes associated with the PHY and VCXO chips but that does not affect firmware. The boards are otherwise identical to the MKII

For Protocol 1, you MUST use the MKIII firmware.

There aren't any functional changes in this firmware, but it had to be recompiled/rebuilt to work with the new part number.
