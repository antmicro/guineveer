from topwrap.model.module import *
from topwrap.model.design import *
from topwrap.model.connections import *
from topwrap.model.hdl_types import *
from topwrap.model.interface import *
from .guineveer_sram import *

eps = [
    Port(name="src_clk_i", direction=PortDirection.IN),
    Port(name="src_rst_ni", direction=PortDirection.IN),
    Port(name="dst_clk_i", direction=PortDirection.IN),
    Port(name="dst_rst_ni", direction=PortDirection.IN),
    Port(name="src_req_i", direction=PortDirection.IN, type=axi_req),
    Port(name="src_resp_o", direction=PortDirection.OUT, type=axi_resp),
    Port(name="dst_req_o", direction=PortDirection.OUT, type=axi_req),
    Port(name="dst_resp_i", direction=PortDirection.IN, type=axi_resp)
]

mod = Module(
    id=Identifier(name="axi_cdc", vendor="PULP", library="pulp_axi"),
    parameters=[
        Parameter(name="LogDepth", default_value=ElaboratableValue(1)),
        Parameter(name="SyncStages", default_value=ElaboratableValue(2)),
        Parameter(name="ID_WIDTH", default_value=ElaboratableValue(1)),
        Parameter(name="aw_chan_t", default_value=ElaboratableValue("logic")),
        Parameter(name="w_chan_t", default_value=ElaboratableValue("logic")),
        Parameter(name="b_chan_t", default_value=ElaboratableValue("logic")),
        Parameter(name="ar_chan_t", default_value=ElaboratableValue("logic")),
        Parameter(name="r_chan_t", default_value=ElaboratableValue("logic")),
        Parameter(name="axi_req_t", default_value=ElaboratableValue("logic")),
        Parameter(name="axi_resp_t", default_value=ElaboratableValue("logic"))
    ],
    ports=eps,
    interfaces=[
        Interface(
            name="s_axi_src",
            mode=InterfaceMode.SUBORDINATE,
            definition=axi_guin,
            signals={
                axi_guin.signals.find_by_name("AWVALID")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw_valid)]),
                ),
                axi_guin.signals.find_by_name("AWADDR")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_addr)]),
                ),
                axi_guin.signals.find_by_name("WVALID")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w_valid)]),
                ),
                axi_guin.signals.find_by_name("WDATA")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_data)]),
                ),
                axi_guin.signals.find_by_name("BREADY")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_b_ready)]),
                ),
                axi_guin.signals.find_by_name("ARVALID")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar_valid)]),
                ),
                axi_guin.signals.find_by_name("ARADDR")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_addr)]),
                ),
                axi_guin.signals.find_by_name("RREADY")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_r_ready)]),
                ),
                axi_guin.signals.find_by_name("AWREADY")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_aw_ready)]),
                ),
                axi_guin.signals.find_by_name("WREADY")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_w_ready)]),
                ),
                axi_guin.signals.find_by_name("BVALID")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b_valid)]),
                ),
                axi_guin.signals.find_by_name("ARREADY")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_ar_ready)]),
                ),
                axi_guin.signals.find_by_name("RVALID")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r_valid)]),
                ),
                axi_guin.signals.find_by_name("RDATA")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_data)]),
                ),
                axi_guin.signals.find_by_name("AWID")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_id)]),
                ),
                axi_guin.signals.find_by_name("ARID")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_id)]),
                ),
                axi_guin.signals.find_by_name("WSTRB")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_strb)]),
                ),
                axi_guin.signals.find_by_name("AWPROT")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_prot)]),
                ),
                axi_guin.signals.find_by_name("ARPROT")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_prot)]),
                ),
                axi_guin.signals.find_by_name("AWREGION")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_region)]),
                ),
                axi_guin.signals.find_by_name("AWLEN")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_len)]),
                ),
                axi_guin.signals.find_by_name("AWSIZE")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_size)]),
                ),
                axi_guin.signals.find_by_name("AWBURST")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_burst)]),
                ),
                axi_guin.signals.find_by_name("AWLOCK")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_lock)]),
                ),
                axi_guin.signals.find_by_name("AWCACHE")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_cache)]),
                ),
                axi_guin.signals.find_by_name("AWQOS")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_qos)]),
                ),
                axi_guin.signals.find_by_name("AWUSER")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_user)]),
                ),
                axi_guin.signals.find_by_name("AWATOP")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_atop)]),
                ),
                axi_guin.signals.find_by_name("WLAST")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_last)]),
                ),
                axi_guin.signals.find_by_name("WUSER")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_user)]),
                ),
                axi_guin.signals.find_by_name("ARREGION")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_region)]),
                ),
                axi_guin.signals.find_by_name("ARLEN")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_len)]),
                ),
                axi_guin.signals.find_by_name("ARSIZE")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_size)]),
                ),
                axi_guin.signals.find_by_name("ARBURST")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_burst)]),
                ),
                axi_guin.signals.find_by_name("ARLOCK")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_lock)]),
                ),
                axi_guin.signals.find_by_name("ARCACHE")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_cache)]),
                ),
                axi_guin.signals.find_by_name("ARQOS")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_qos)]),
                ),
                axi_guin.signals.find_by_name("ARUSER")._id: ReferencedPort.external(
                    eps[4],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_user)]),
                ),
                axi_guin.signals.find_by_name("BID")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b), s(b_id)]),
                ),
                axi_guin.signals.find_by_name("RID")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_id)]),
                ),
                axi_guin.signals.find_by_name("BRESP")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b), s(b_resp)]),
                ),
                axi_guin.signals.find_by_name("RRESP")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_resp)]),
                ),
                axi_guin.signals.find_by_name("BUSER")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b), s(b_user)]),
                ),
                axi_guin.signals.find_by_name("RLAST")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_last)]),
                ),
                axi_guin.signals.find_by_name("RUSER")._id: ReferencedPort.external(
                    eps[5],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_user)]),
                ),
            },
        ),
        Interface(
            name="m_axi_dst",
            mode=InterfaceMode.MANAGER,
            definition=axi_guin,
            signals={
                axi_guin.signals.find_by_name("AWVALID")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw_valid)]),
                ),
                axi_guin.signals.find_by_name("AWADDR")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_addr)]),
                ),
                axi_guin.signals.find_by_name("WVALID")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w_valid)]),
                ),
                axi_guin.signals.find_by_name("WDATA")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_data)]),
                ),
                axi_guin.signals.find_by_name("BREADY")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_b_ready)]),
                ),
                axi_guin.signals.find_by_name("ARVALID")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar_valid)]),
                ),
                axi_guin.signals.find_by_name("ARADDR")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_addr)]),
                ),
                axi_guin.signals.find_by_name("RREADY")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_r_ready)]),
                ),
                axi_guin.signals.find_by_name("AWREADY")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_aw_ready)]),
                ),
                axi_guin.signals.find_by_name("WREADY")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_w_ready)]),
                ),
                axi_guin.signals.find_by_name("BVALID")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b_valid)]),
                ),
                axi_guin.signals.find_by_name("ARREADY")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_ar_ready)]),
                ),
                axi_guin.signals.find_by_name("RVALID")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r_valid)]),
                ),
                axi_guin.signals.find_by_name("RDATA")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_data)]),
                ),
                axi_guin.signals.find_by_name("AWID")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_id)]),
                ),
                axi_guin.signals.find_by_name("ARID")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_id)]),
                ),
                axi_guin.signals.find_by_name("WSTRB")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_strb)]),
                ),
                axi_guin.signals.find_by_name("AWPROT")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_prot)]),
                ),
                axi_guin.signals.find_by_name("ARPROT")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_prot)]),
                ),
                axi_guin.signals.find_by_name("AWREGION")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_region)]),
                ),
                axi_guin.signals.find_by_name("AWLEN")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_len)]),
                ),
                axi_guin.signals.find_by_name("AWSIZE")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_size)]),
                ),
                axi_guin.signals.find_by_name("AWBURST")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_burst)]),
                ),
                axi_guin.signals.find_by_name("AWLOCK")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_lock)]),
                ),
                axi_guin.signals.find_by_name("AWCACHE")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_cache)]),
                ),
                axi_guin.signals.find_by_name("AWQOS")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_qos)]),
                ),
                axi_guin.signals.find_by_name("AWUSER")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_user)]),
                ),
                axi_guin.signals.find_by_name("AWATOP")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_aw), s(achan_atop)]),
                ),
                axi_guin.signals.find_by_name("WLAST")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_last)]),
                ),
                axi_guin.signals.find_by_name("WUSER")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_w), s(w_user)]),
                ),
                axi_guin.signals.find_by_name("ARREGION")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_region)]),
                ),
                axi_guin.signals.find_by_name("ARLEN")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_len)]),
                ),
                axi_guin.signals.find_by_name("ARSIZE")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_size)]),
                ),
                axi_guin.signals.find_by_name("ARBURST")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_burst)]),
                ),
                axi_guin.signals.find_by_name("ARLOCK")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_lock)]),
                ),
                axi_guin.signals.find_by_name("ARCACHE")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_cache)]),
                ),
                axi_guin.signals.find_by_name("ARQOS")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_qos)]),
                ),
                axi_guin.signals.find_by_name("ARUSER")._id: ReferencedPort.external(
                    eps[6],
                    select=LogicSelect(logic=axi_req, ops=[s(req_ar), s(achan_user)]),
                ),
                axi_guin.signals.find_by_name("BID")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b), s(b_id)]),
                ),
                axi_guin.signals.find_by_name("RID")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_id)]),
                ),
                axi_guin.signals.find_by_name("BRESP")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b), s(b_resp)]),
                ),
                axi_guin.signals.find_by_name("RRESP")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_resp)]),
                ),
                axi_guin.signals.find_by_name("BUSER")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_b), s(b_user)]),
                ),
                axi_guin.signals.find_by_name("RLAST")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_last)]),
                ),
                axi_guin.signals.find_by_name("RUSER")._id: ReferencedPort.external(
                    eps[7],
                    select=LogicSelect(logic=axi_resp, ops=[s(resp_r), s(r_user)]),
                ),
            },
        )
    ]
)
