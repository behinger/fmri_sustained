installfolder = $(shell pwd)
all:
	@echo $(installfolder)

toolboxdir    = ${installfolder}/local/lib/toolboxes
toolbox_spm   = ${toolboxdir}/spm12
toolbox_tvm   = ${toolboxdir}/tvm_openfmrianalysis
toolbox_vista = ${toolboxdir}/vistalab

toolbox_artrepair = ${toolboxdir}/ArtRepair
toolbox_memolab = ${toolboxdir}/memolab
toolbox_exportfig = ${toolboxdir}/export_fig

toolbox_gramm = ${toolboxdir}/gramm

${toolboxdir}:
	mkdir -p ${toolboxdir}/../
	mkdir -p ${toolboxdir}

export PATH:=/opt/matlab/R2018a/bin/:$(PATH)


toolboxes: | $(toolbox_tvm) $(toolbox_vista) $(toolbox_spm) $(toolbox_memolab) $(toolbox_gramm)
	echo 'done'

$(toolbox_vista): | ${toolboxdir}
	git clone https://github.com/vistalab/vistasoft $(toolbox_vista)

$(toolbox_tvm): | ${toolboxdir}
	git clone https://github.com/TimVanMourik/OpenFmriAnalysis $(toolbox_tvm)

$(toolbox_spm): | ${toolboxdir}
	wget https://www.fil.ion.ucl.ac.uk/spm/download/restricted/eldorado/spm12.zip
	unzip -q spm12.zip -d ${toolboxdir} #spm12 folder is already in zip
	@echo $(PATH)
	cd ${toolbox_spm}/src && make && make_install
	rm spm12.zip

$(toolbox_memolab): | ${toolboxdir} $(toolbox_exportfig) $(toolbox_artrepair)
	git clone https://github.com/behinger/memolab-fmri-qa $(toolbox_memolab)


$(toolbox_artrepair): | ${toolboxdir}
	wget cibsr.stanford.edu/content/dam/sm/cibsr/documents/tools/methods/artrepair-software/ArtRepair_v5b3.zip
	unzip -q ArtRepair_v5b3.zip -d ${toolboxdir} # artrepair folder is already in zip
	rm ArtRepair_v5b3.zip

$(toolbox_exportfig): | ${toolboxdir} 
	git clone https://github.com/altmany/export_fig $(toolbox_exportfig)
 
$(toolbox_gramm): | ${toolboxdir}
	git clone https://github.com/piermorel/gramm $(toolbox_gramm)
