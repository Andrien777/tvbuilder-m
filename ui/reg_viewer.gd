extends Window

var proc = null
var ax_val
var bx_val
var cx_val
var dx_val
var cs_val
var ip_val
var sp_val
var bp_val
var si_val
var di_val
var ss_val
var ds_val
var es_val

var of_val
var df_val
var if_val
var tf_val
var sf_val
var zf_val
var acf_val
var pf_val
var cf_val

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_requested.connect(hide)
	ax_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer/AX_cont/Val")
	bx_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer/BX_cont/Val")
	cx_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer/CX_cont/Val")
	dx_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer/DX_cont/Val")
	cs_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer2/CS_cont/Val")
	ip_val = get_node("VBoxContainer/IP_cont/Val")
	sp_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer3/SP_cont/Val")
	bp_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer3/BP_cont/Val")
	si_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer3/SI_cont/Val")
	di_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer3/DI_cont/Val")
	ss_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer2/SS_cont/Val")
	ds_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer2/DS_cont/Val")
	es_val = get_node("VBoxContainer/HBoxContainer/VBoxContainer2/ES_cont/Val")
	
	of_val = get_node('VBoxContainer/GridContainer/of')
	df_val = get_node('VBoxContainer/GridContainer/df')
	if_val = get_node('VBoxContainer/GridContainer/if')
	tf_val = get_node('VBoxContainer/GridContainer/tf')
	sf_val = get_node('VBoxContainer/GridContainer/sf')
	zf_val = get_node('VBoxContainer/GridContainer/zf')
	acf_val = get_node('VBoxContainer/GridContainer/acf')
	pf_val = get_node('VBoxContainer/GridContainer/pf')
	cf_val = get_node('VBoxContainer/GridContainer/cf')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(proc) and visible:
		update()
	elif visible:
		ax_val.text = "\t????"
		bx_val.text = "\t????"
		cx_val.text = "\t????"
		dx_val.text = "\t????"
		cs_val.text = "\t????"
		ip_val.text = "\t????"
		si_val.text = "\t????"
		sp_val.text = "\t????"
		bp_val.text = "\t????"
		di_val.text = "\t????"
		ss_val.text = "\t????"
		ds_val.text = "\t????"
		es_val.text = "\t????"
		
		of_val.text = "\t?"
		df_val.text = "\t?"
		if_val.text = "\t?"
		tf_val.text = "\t?"
		sf_val.text = "\t?"
		zf_val.text = "\t?"
		acf_val.text = "\t?"
		pf_val.text = "\t?"
		cf_val.text = "\t?"

func set_proc(procc):
	proc = procc
	visible = true

func update():
	ax_val.text = "\t%04x" % proc.proc_impl.ax
	bx_val.text = "\t%04x" % proc.proc_impl.bx
	cx_val.text = "\t%04x" % proc.proc_impl.cx
	dx_val.text = "\t%04x" % proc.proc_impl.dx
	cs_val.text = "\t%04x" % proc.proc_impl.cs
	ip_val.text = "\t%04x" % proc.proc_impl.ip
	si_val.text = "\t%04x" % proc.proc_impl.si
	sp_val.text = "\t%04x" % proc.proc_impl.sp
	bp_val.text = "\t%04x" % proc.proc_impl.bp
	di_val.text = "\t%04x" % proc.proc_impl.di
	ss_val.text = "\t%04x" % proc.proc_impl.ss
	ds_val.text = "\t%04x" % proc.proc_impl.ds
	es_val.text = "\t%04x" % proc.proc_impl.es
	
	of_val.text = "\t%d" % (proc.proc_impl.of as int)
	df_val.text = "\t%d" % (proc.proc_impl.df as int)
	if_val.text = "\t%d" % (proc.proc_impl.if as int)
	tf_val.text = "\t%d" % (proc.proc_impl.tf as int)
	sf_val.text = "\t%d" % (proc.proc_impl.sf as int)
	zf_val.text = "\t%d" % (proc.proc_impl.zf as int)
	acf_val.text = "\t%d" % (proc.proc_impl.acf as int)
	pf_val.text = "\t%d" % (proc.proc_impl.pf as int)
	cf_val.text = "\t%d" % (proc.proc_impl.cf as int)
	
