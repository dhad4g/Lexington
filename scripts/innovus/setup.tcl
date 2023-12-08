##########################################################################################
#                           CDNS INNOVUS FOUNDATION FLOW
#-----------------------------------------------------------------------------------------
# This is the foundation flow setup.tcl file.  It contains all the necessary information
# to run the Innovus digital implementation flow. 
##########################################################################################
set vars(script_root)      ../../scripts/innovus/SCRIPTS
set vars(design_root)      [pwd]/../synth/core
set vars(lib_root)         /opt/cadence_roy/library/fsd0a_90nm_generic_core
# set vars(plug_dir)         PLUG
set vars(plug_dir)         [pwd]
set vars(dbs_dir)          DBS
set vars(rpt_dir)          RPT
set vars(flow)             mmmc
########################################################################################
# Define required design data ...
########################################################################################
set vars(design)           core
set vars(netlist)          $vars(design_root)/core_netlist.v
set vars(fp_file)          $vars(script_root)/../core.fp
#set vars(def_files)      "<def_files>"
#set vars(generate_tracks) <true or false>
#set vars(scan_def)        <scan_def>
# set vars(cts_spec)         "$vars(design_root)/DATA/chip_top.ctstch"
# set vars(scan_def)         $vars(design_root)/DATA/chip_top.scandef
# set vars(io_file)          $vars(design_root)/DATA/chip_top.io
set vars(process)          90nm
set vars(max_route_layer)  8
########################################################################################
# Define lef files ...
########################################################################################
set vars(lef_files) "\
   $vars(lib_root)/lef/header8m026_V55.lef \
   $vars(lib_root)/lef/fsd0a_a_generic_core.lef \
"
########################################################################################
# Define library sets ...
# set vars(library_sets) <list of library sets>
# set vars(<set>,timing) <list of lib files>
# set vars(<set>,si) <list of cdb/udn files>
########################################################################################
set vars(library_sets) "lib_slow lib_typ lib_fast"
set vars(lib_slow,timing) "\
   $vars(lib_root)/timing/fsd0a_a_generic_core_ff1p1vm40c.lib \
"
set vars(lib_typ,timing) "\
   $vars(lib_root)/timing/fsd0a_a_generic_core_tt1v25c.lib \
"
set vars(lib_fast,timing) "\
   $vars(lib_root)/timing/fsd0a_a_generic_core_ss0p9v125c.lib \
"
########################################################################################
# Define rc corners ...
# set vars(rc_corners) <list of rc corners>
# set vars(<rc_corner>,T) <temperature>
# set vars(<rc_corner>,cap_table) <cap table for corner>
########################################################################################
set vars(rc_corners)       "rc_min rc_typ rc_max"
set vars(rc_min,T)          0
# set vars(rc_min,cap_table) $vars(design_root)/LIBS/TECHNOLOGY/CAP_TABLES/cbest/cbest.CapTbl
set vars(rc_typ,T)          40
# set vars(rc_typ,cap_table) $vars(design_root)/LIBS/TECHNOLOGY/CAP_TABLES/cnom/cnom.CapTbl
set vars(rc_max,T)          90
# set vars(rc_max,cap_table) $vars(design_root)/LIBS/TECHNOLOGY/CAP_TABLES/cworst/cworst.CapTbl
########################################################################################
# Optionally define QRC technology information
#---------------------------------------------------------------------------------------
# set vars(<rc_corner>,qx_tech_file) <qx_tech_file for corner>
# set vars(<rc_corner>,qx_lib_file) <qx_lib_file for corner>
# set vars(<rc_corner>,qx_conf_file) <qx_conf_file for corner>
########################################################################################
# set vars(rc_min,qx_tech_file) $vars(design_root)/LIBS/TECHNOLOGY/TECH_FILES/QRC/cbest/qrcTechFile
# set vars(rc_min,qx_conf_file) $vars(design_root)/DATA/min_qrc.conf
# set vars(rc_max,qx_tech_file) $vars(design_root)/LIBS/TECHNOLOGY/TECH_FILES/QRC/cworst/qrcTechFile
# set vars(rc_max,qx_conf_file) $vars(design_root)/DATA/max_qrc.conf
########################################################################################
# Scale factors are also optional but are strongly encouraged for 
# obtaining the best flow convergence and QoR.  Scaling factors
# are applied per rc corner
#---------------------------------------------------------------------------------------
# set vars(<rc_corner>,def_res_factor)     <pre-route resistance scale factor>
# set vars(<rc_corner>,def_clk_res_factor) <pre-route clock resistance scale factor>
# set vars(<rc_corner>,det_res_factor)     <post-route resistance scale factor>
# set vars(<rc_corner>,det_clk_res_factor) <post-route clock resistance scale factor>
# set vars(<rc_corner>,def_cap_factor)     <pre-route capacitance scale factor>
# set vars(<rc_corner>,def_clk_cap_factor) <pre-route clock capacitance scale factor>
# set vars(<rc_corner>,det_cap_factor)     <post-route capacitance scale factor>
# set vars(<rc_corner>,det_clk_cap_factor) <post-route clock capacitance scale factor>
# set vars(<rc_corner>,xcap_factor)        <post-route coupling capacitance scale factor>
########################################################################################
set vars(rc_min,def_res_factor)         1.0000
set vars(rc_min,def_clk_res_factor)     0.0000
set vars(rc_min,det_res_factor)         1.0000
set vars(rc_min,det_clk_res_factor)     0.0000
set vars(rc_min,def_cap_factor)         1.0000
set vars(rc_min,def_clk_cap_factor)     0.0000
set vars(rc_min,det_cap_factor)         1.0000
set vars(rc_min,det_clk_cap_factor)     0.0000
set vars(rc_min,xcap_factor)            1.0000

set vars(rc_typ,def_res_factor)         1.0000
set vars(rc_typ,def_clk_res_factor)     0.0000
set vars(rc_typ,det_res_factor)         1.0000
set vars(rc_typ,det_clk_res_factor)     0.0000
set vars(rc_typ,def_cap_factor)         1.0000
set vars(rc_typ,def_clk_cap_factor)     0.0000
set vars(rc_typ,det_cap_factor)         1.0000
set vars(rc_typ,det_clk_cap_factor)     0.0000
set vars(rc_typ,xcap_factor)            1.0000

set vars(rc_max,def_res_factor)         0.9500
set vars(rc_max,def_clk_res_factor)     0.0000
set vars(rc_max,det_res_factor)         1.2700
set vars(rc_max,det_clk_res_factor)     0.0000
set vars(rc_max,def_cap_factor)         1.0900
set vars(rc_max,def_clk_cap_factor)     0.0000
set vars(rc_max,det_cap_factor)         1.1000
set vars(rc_max,det_clk_cap_factor)     1.0500
set vars(rc_max,xcap_factor)            1.5300

########################################################################################
# Define operating conditions (optional)
# set vars(opconds) <list of operating conditions>
# set vars(<opcond>,library_file) <library file >
# set vars(<opcond>,P) <process scale factor>
# set vars(<opcond>,V) <voltage>
# set vars(<opcond>,T) <temperature>
########################################################################################
########################################################################################
# Define delay corners ...
# set vars(delay_corners) <list of delay corners>
# set vars(<delay_corner>,library_set) <library_set> (previously defined)
# set vars(<delay_corner>,opcond) <opcond> (previously defined) (optional)
# set vars(<delay_corner>,rc_corner) library_set> (previously defined)
########################################################################################
# set vars(delay_corners) "AVdefault_WC_dc AVdvfs2_BC_dc AVdefault_BC_dc AVdvfs2_WC_dc"
# set vars(AVdefault_WC_dc,library_set)   1v080
# set vars(AVdefault_WC_dc,rc_corner)     rc_max
# set vars(AVdvfs2_BC_dc,library_set) 	1v056
# set vars(AVdvfs2_BC_dc,rc_corner)     	rc_min
# set vars(AVdefault_BC_dc,library_set) 	1v320
# set vars(AVdefault_BC_dc,rc_corner) 	rc_min
# set vars(AVdvfs2_WC_dc,library_set) 	0v864
# set vars(AVdvfs2_WC_dc,rc_corner) 	    rc_max
set vars(delay_corners)          "dc_slow dc_typ dc_fast"
set vars(dc_slow,library_set)    lib_slow
set vars(dc_slow,rc_corner)      rc_max
set vars(dc_typ,library_set)     lib_typ
set vars(dc_typ,rc_corner)       rc_typ
set vars(dc_fast,library_set)    lib_fast
set vars(dc_fast,rc_corner)      rc_min
########################################################################################
# Optionally define derating factors for OCV here (clock and data). 
# Derating factors are applied per delay corner
########################################################################################
#set vars(<delay_corner>,data_cell_late) <float>
#set vars(<delay_corner>,data_cell_early) <float>
#set vars(<delay_corner>,data_net_late) <float>
#set vars(<delay_corner>,data_net_early) <float>
#set vars(<delay_corner>,clock_cell_late) <float>
#set vars(<delay_corner>,clock_cell_early) <float>
#set vars(<delay_corner>,clock_net_late) <float>
#set vars(<delay_corner>,clock_net_early) <float>
set vars(dc_slow,data_cell_early)      0.97
set vars(dc_slow,data_cell_late)       1.03
set vars(dc_slow,clock_cell_early)     0.97
set vars(dc_slow,clock_cell_late)      1.03
set vars(dc_slow,data_net_early)       0.97
set vars(dc_slow,data_net_late)        1.03
set vars(dc_slow,clock_net_early)      0.97
set vars(dc_slow,clock_net_late)       1.03

set vars(dc_typ,data_cell_early)       0.97
set vars(dc_typ,data_cell_late)        1.03
set vars(dc_typ,clock_cell_early)      0.97
set vars(dc_typ,clock_cell_late)       1.03
set vars(dc_typ,data_net_early)        0.97
set vars(dc_typ,data_net_late)         1.03
set vars(dc_typ,clock_net_early)       0.97
set vars(dc_typ,clock_net_late)        1.03

set vars(dc_fast,data_cell_early)      0.97
set vars(dc_fast,data_cell_late)       1.03
set vars(dc_fast,clock_cell_early)     0.97
set vars(dc_fast,clock_cell_late)      1.03
set vars(dc_fast,data_net_early)       0.97
set vars(dc_fast,data_net_late)        1.03
set vars(dc_fast,clock_net_early)      0.97
set vars(dc_fast,clock_net_late)       1.03
########################################################################################
# Define constraint modes ... 
# set vars(constraint_modes) <list of constraint modes>
# set vars(<mode>,pre_cts_sdc) <pre cts constraint file>
# set vars(<mode>,post_cts_sdc) <post cts constraint file> (optional)
########################################################################################
set vars(constraint_modes)       "sdc_typ"
set vars(sdc_typ,pre_cts_sdc)  "$vars(design_root)/core.sdc"
########################################################################################
# Define setup and hold analysis views ... each analysis view requires
# a delay corner and a constraint mode
########################################################################################
set vars(view_slow,delay_corner)       dc_slow
set vars(view_slow,constraint_mode)    sdc_typ
set vars(view_typ,delay_corner)        dc_typ
set vars(view_typ,constraint_mode)     sdc_typ
set vars(view_fast,delay_corner)       dc_fast
set vars(view_fast,constraint_mode)    sdc_typ
########################################################################################
# EDIT/VERIFY THESE LISTS!!
########################################################################################
set vars(setup_analysis_views) "view_slow view_typ view_fast"
set vars(hold_analysis_views)  "view_slow view_typ view_fast"
########################################################################################
# Define active setup and hold analysis view lists and default views
########################################################################################
set vars(default_setup_view)   [lindex $vars(setup_analysis_views) 0]
set vars(default_hold_view)    [lindex $vars(hold_analysis_views) 0]
set vars(active_setup_views)   $vars(setup_analysis_views)
set vars(active_hold_views)    $vars(hold_analysis_views)

Puts "<FF> Finished loading setup.tcl file"
