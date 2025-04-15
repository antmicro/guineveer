from pathlib import Path
from topwrap.model.misc import Identifier
from topwrap.frontend.yaml.frontend import YamlFrontend
from topwrap.backend.sv.backend import SystemVerilogBackend
from ipcores.axi_cdc import mod as axi_cdc
from ipcores.guineveer_sram import mod as guineveer_sram

# Load IP cores defined directly in Python,
# since they need features unavailable in YAML
raw_cores = [axi_cdc, guineveer_sram]

# Load the guineveer IR module from YAML design description
front = YamlFrontend(raw_cores)
[guineveer] = front.parse_files([Path("design.yaml")])
guineveer.id = Identifier(name=guineveer.id.name, vendor="antmicro", library="guineveer")

# Add independent signals to VeeR's memory interfaces
# since they do not get automatically added when parsed
# from IP core description YAML
veer = guineveer.hierarchy().find_by(lambda m: m.id.name == "el2_veer_wrapper")
for i in ("el2_mem_export", "el2_icache_export"):
    intf = veer.interfaces.find_by_name(i)
    intf.signals = { s._id: None for s in intf.definition.signals }


back = SystemVerilogBackend(raw_cores, all_pins=True)
repr = back.represent(guineveer)

# Save the wrapper, but ignore any interface definitions
# since external definitions are used
repr.interfaces.clear()
[file] = back.serialize(repr, combine=True)
file.save(Path("../hw/guineveer.sv"))
