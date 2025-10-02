from copy import deepcopy
from topwrap.model.module import *
from topwrap.model.design import *
from topwrap.model.connections import *
from topwrap.model.hdl_types import *
from topwrap.model.interface import *
from topwrap.frontend.yaml.ip_core import InterfaceDescriptionFrontend


def b2(u: Union[str, int], l: Union[str, int]):
    return Bits(
        dimensions=[Dimensions(upper=ElaboratableValue(u), lower=ElaboratableValue(l))]
    )


def s(sf: StructField) -> LogicFieldSelect:
    return LogicFieldSelect(field=sf)


addr_chan = BitStruct(
    name="axi_addr_chan_t",
    fields=[
        (achan_id := StructField(name="id", type=b2(4, 0))),
        (achan_addr := StructField(name="addr", type=b2(31, 0))),
        (achan_len := StructField(name="len", type=b2(7, 0))),
        (achan_size := StructField(name="size", type=b2(2, 0))),
        (achan_burst := StructField(name="burst", type=b2(1, 0))),
        (achan_lock := StructField(name="lock", type=Bit())),
        (achan_cache := StructField(name="cache", type=b2(3, 0))),
        (achan_prot := StructField(name="prot", type=b2(2, 0))),
        (achan_qos := StructField(name="qos", type=b2(3, 0))),
        (achan_region := StructField(name="region", type=b2(3, 0))),
        (achan_atop := StructField(name="atop", type=b2(5, 0))),
        (achan_user := StructField(name="user", type=Bit())),
    ],
)

axi_req = BitStruct(
    name="axi_req_t",
    fields=[
        (req_aw_valid := StructField(name="aw_valid", type=Bit())),
        (req_w_valid := StructField(name="w_valid", type=Bit())),
        (req_b_ready := StructField(name="b_ready", type=Bit())),
        (req_ar_valid := StructField(name="ar_valid", type=Bit())),
        (req_r_ready := StructField(name="r_ready", type=Bit())),
        (req_aw := StructField(name="aw", type=deepcopy(addr_chan))),
        (req_ar := StructField(name="ar", type=addr_chan)),
        (
            req_w := StructField(
                name="w",
                type=BitStruct(
                    name="axi_w_chan_t",
                    fields=[
                        (w_data := StructField(name="data", type=b2(63, 0))),
                        (w_strb := StructField(name="strb", type=b2(7, 0))),
                        (w_last := StructField(name="last", type=Bit())),
                        (w_user := StructField(name="user", type=Bit())),
                    ]
                ),
            )
        ),
    ],
)

axi_resp = BitStruct(
    name="axi_resp_t",
    fields=[
        (resp_aw_ready := StructField(name="aw_ready", type=Bit())),
        (resp_ar_ready := StructField(name="ar_ready", type=Bit())),
        (resp_w_ready := StructField(name="w_ready", type=Bit())),
        (resp_b_valid := StructField(name="b_valid", type=Bit())),
        (resp_r_valid := StructField(name="r_valid", type=Bit())),
        (
            resp_b := StructField(
                name="b",
                type=BitStruct(
                    name="axi_b_chan_t",
                    fields=[
                        (b_id := StructField(name="id", type=b2(4, 0))),
                        (b_resp := StructField(name="resp", type=b2(1, 0))),
                        (b_user := StructField(name="user", type=Bit())),
                    ]
                ),
            )
        ),
        (
            resp_r := StructField(
                name="r",
                type=BitStruct(
                    name="axi_r_chan_t",
                    fields=[
                        (r_id := StructField(name="id", type=b2(4, 0))),
                        (r_data := StructField(name="data", type=b2(63, 0))),
                        (r_resp := StructField(name="resp", type=b2(1, 0))),
                        (r_last := StructField(name="last", type=Bit())),
                        (r_user := StructField(name="user", type=Bit())),
                    ]
                ),
            )
        ),
    ],
)

axi_guin = InterfaceDescriptionFrontend.from_loaded("AXIguin")
assert axi_guin is not None
axi_guin = axi_guin

eps = [
    Port(name="clk_i", direction=PortDirection.IN),
    Port(name="rst_ni", direction=PortDirection.IN),
    Port(name="axi_req_i", direction=PortDirection.IN, type=axi_req),
    Port(name="axi_resp_o", direction=PortDirection.OUT, type=axi_resp),
]

mod = Module(
    id=Identifier(name="guineveer_sram", vendor="antmicro.com", library="guineveer"),
    parameters=[
        Parameter(name="GUINEVEER_MEMORY_FILE", default_value=ElaboratableValue("")),
        Parameter(name="ADDR_WIDTH", default_value=ElaboratableValue(32)),
        Parameter(name="DATA_WIDTH", default_value=ElaboratableValue(64)),
        Parameter(name="ID_WIDTH", default_value=ElaboratableValue(1)),
        Parameter(name="AXI_REQ_T", default_value=ElaboratableValue("logic")),
        Parameter(name="AXI_RESP_T", default_value=ElaboratableValue("logic")),
    ],
    ports=eps,
    interfaces=[
        Interface(
            name="s_axi_sram",
            mode=InterfaceMode.SUBORDINATE,
            definition=axi_guin,
            signals={
                axi_guin.signals.find_by_name("AWVALID")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw_valid)]),
                ),
                axi_guin.signals.find_by_name("AWADDR")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_addr)]),
                ),
                axi_guin.signals.find_by_name("WVALID")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w_valid)]),
                ),
                axi_guin.signals.find_by_name("WDATA")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_data)]),
                ),
                axi_guin.signals.find_by_name("BREADY")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_b_ready)]),
                ),
                axi_guin.signals.find_by_name("ARVALID")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar_valid)]),
                ),
                axi_guin.signals.find_by_name("ARADDR")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_addr)]),
                ),
                axi_guin.signals.find_by_name("RREADY")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_r_ready)]),
                ),
                axi_guin.signals.find_by_name("AWREADY")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_aw_ready)]),
                ),
                axi_guin.signals.find_by_name("WREADY")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_w_ready)]),
                ),
                axi_guin.signals.find_by_name("BVALID")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b_valid)]),
                ),
                axi_guin.signals.find_by_name("ARREADY")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_ar_ready)]),
                ),
                axi_guin.signals.find_by_name("RVALID")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r_valid)]),
                ),
                axi_guin.signals.find_by_name("RDATA")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_data)]),
                ),
                axi_guin.signals.find_by_name("AWID")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_id)]),
                ),
                axi_guin.signals.find_by_name("ARID")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_id)]),
                ),
                axi_guin.signals.find_by_name("WSTRB")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_strb)]),
                ),
                axi_guin.signals.find_by_name("AWPROT")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_prot)]),
                ),
                axi_guin.signals.find_by_name("ARPROT")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_prot)]),
                ),
                axi_guin.signals.find_by_name("AWREGION")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_region)]),
                ),
                axi_guin.signals.find_by_name("AWLEN")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_len)]),
                ),
                axi_guin.signals.find_by_name("AWSIZE")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_size)]),
                ),
                axi_guin.signals.find_by_name("AWBURST")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_burst)]),
                ),
                axi_guin.signals.find_by_name("AWLOCK")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_lock)]),
                ),
                axi_guin.signals.find_by_name("AWCACHE")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_cache)]),
                ),
                axi_guin.signals.find_by_name("AWQOS")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_qos)]),
                ),
                axi_guin.signals.find_by_name("AWUSER")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_user)]),
                ),
                axi_guin.signals.find_by_name("AWATOP")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_atop)]),
                ),
                axi_guin.signals.find_by_name("WLAST")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_last)]),
                ),
                axi_guin.signals.find_by_name("WUSER")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_user)]),
                ),
                axi_guin.signals.find_by_name("ARREGION")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_region)]),
                ),
                axi_guin.signals.find_by_name("ARLEN")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_len)]),
                ),
                axi_guin.signals.find_by_name("ARSIZE")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_size)]),
                ),
                axi_guin.signals.find_by_name("ARBURST")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_burst)]),
                ),
                axi_guin.signals.find_by_name("ARLOCK")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_lock)]),
                ),
                axi_guin.signals.find_by_name("ARCACHE")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_cache)]),
                ),
                axi_guin.signals.find_by_name("ARQOS")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_qos)]),
                ),
                axi_guin.signals.find_by_name("ARUSER")._id: ReferencedPort.external(
                    eps[2],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_user)]),
                ),
                axi_guin.signals.find_by_name("BID")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b), s(b_id)]),
                ),
                axi_guin.signals.find_by_name("RID")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_id)]),
                ),
                axi_guin.signals.find_by_name("BRESP")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b), s(b_resp)]),
                ),
                axi_guin.signals.find_by_name("RRESP")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_resp)]),
                ),
                axi_guin.signals.find_by_name("BUSER")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b), s(b_user)]),
                ),
                axi_guin.signals.find_by_name("RLAST")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_last)]),
                ),
                axi_guin.signals.find_by_name("RUSER")._id: ReferencedPort.external(
                    eps[3],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_user)]),
                ),
            },
        )
    ],
)
