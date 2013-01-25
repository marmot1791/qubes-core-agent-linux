RPMS_DIR=rpm/

VERSION_DOM0 := $(shell cat version_dom0)
VERSION_VAIO_FIXES := $(shell cat version_vaio_fixes)
VERSION_VM := $(shell cat version_vm)
VERSION_LIBS := $(shell cat version_libs)

DIST_DOM0 ?= fc13

help:
	@echo "make rpms                  -- generate binary rpm packages"
	@echo "make rpms-vm               -- generate binary rpm packages for VM"
	@echo "make rpms-dom0             -- generate binary rpm packages for Dom0"
	@echo "make update-repo-current   -- copy newly generated rpms to qubes yum repo"
	@echo "make update-repo-current-testing  -- same, but to -current-testing repo"
	@echo "make update-repo-unstable  -- same, but to -testing repo"
	@echo "make update-repo-installer -- copy dom0 rpms to installer repo"
	@echo "make clean                 -- cleanup"

rpms: rpms-vm rpms-dom0

rpms-libs:
	rpmbuild --define "_rpmdir $(RPMS_DIR)" -bb rpm_spec/core-libs.spec
	rpm --addsign $(RPMS_DIR)/x86_64/qubes-core-libs-$(VERSION_LIBS)*.rpm

rpms-vm: rpms-libs
	rpmbuild --define "_rpmdir $(RPMS_DIR)" -bb rpm_spec/core-vm.spec
	rpmbuild --define "_rpmdir $(RPMS_DIR)" -bb rpm_spec/core-vm-kernel-placeholder.spec
	rpm --addsign \
		$(RPMS_DIR)/x86_64/qubes-core-vm-*$(VERSION_VM)*.rpm \
		$(RPMS_DIR)/x86_64/qubes-core-vm-kernel-placeholder-*.rpm

rpms-dom0: rpms-libs rpms-vaio-fixes
	rpmbuild --define "_rpmdir $(RPMS_DIR)" -bb rpm_spec/core-dom0.spec
	rpm --addsign \
		$(RPMS_DIR)/x86_64/qubes-core-dom0-$(VERSION_DOM0)*.rpm

rpms-vaio-fixes:
	rpmbuild --define "_rpmdir $(RPMS_DIR)" -bb rpm_spec/core-dom0-vaio-fixes.spec
	rpm --addsign $(RPMS_DIR)/x86_64/qubes-core-dom0-vaio-fixes-$(VERSION_VAIO_FIXES)*.rpm 

update-repo-current:
	ln -f $(RPMS_DIR)/x86_64/qubes-core-dom0-$(VERSION_DOM0)*$(DIST_DOM0)*.rpm ../yum/current-release/current/dom0/rpm/
	ln -f $(RPMS_DIR)/x86_64/qubes-core-dom0-vaio-fixes-$(VERSION_VAIO_FIXES)*$(DIST_DOM0)*.rpm ../yum/current-release/current/dom0/rpm/
	ln -f $(RPMS_DIR)/x86_64/qubes-core-libs-$(VERSION_LIBS)*$(DIST_DOM0)*.rpm ../yum/current-release/current/dom0/rpm/
	for vmrepo in ../yum/current-release/current/vm/* ; do \
		dist=$$(basename $$vmrepo) ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-vm-*$(VERSION_VM)*$$dist*.rpm $$vmrepo/rpm/ ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-vm-kernel-placeholder-*$$dist*.rpm $$vmrepo/rpm/ ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-libs-$(VERSION_LIBS)*$$dist*.rpm $$vmrepo/rpm/;\
	done

update-repo-current-testing:
	ln -f $(RPMS_DIR)/x86_64/qubes-core-dom0-$(VERSION_DOM0)*$(DIST_DOM0)*.rpm ../yum/current-release/current-testing/dom0/rpm/
	ln -f $(RPMS_DIR)/x86_64/qubes-core-dom0-vaio-fixes-$(VERSION_VAIO_FIXES)*$(DIST_DOM0)*.rpm ../yum/current-release/current-testing/dom0/rpm/
	ln -f $(RPMS_DIR)/x86_64/qubes-core-libs-$(VERSION_LIBS)*$(DIST_DOM0)*.rpm ../yum/current-release/current-testing/dom0/rpm/
	for vmrepo in ../yum/current-release/current-testing/vm/* ; do \
		dist=$$(basename $$vmrepo) ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-vm-*$(VERSION_VM)*$$dist*.rpm $$vmrepo/rpm/ ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-vm-kernel-placeholder-*$$dist*.rpm $$vmrepo/rpm/ ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-libs-$(VERSION_LIBS)*$$dist*.rpm $$vmrepo/rpm/;\
	done

update-repo-unstable:
	ln -f $(RPMS_DIR)/x86_64/qubes-core-dom0-$(VERSION_DOM0)*$(DIST_DOM0)*.rpm ../yum/current-release/unstable/dom0/rpm/
	ln -f $(RPMS_DIR)/x86_64/qubes-core-dom0-vaio-fixes-$(VERSION_VAIO_FIXES)*$(DIST_DOM0)*.rpm ../yum/current-release/unstable/dom0/rpm/
	ln -f $(RPMS_DIR)/x86_64/qubes-core-libs-$(VERSION_LIBS)*$(DIST_DOM0)*.rpm ../yum/current-release/current-testing/dom0/rpm/
	for vmrepo in ../yum/current-release/unstable/vm/* ; do \
		dist=$$(basename $$vmrepo) ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-vm-*$(VERSION_VM)*$$dist*.rpm $$vmrepo/rpm/ ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-vm-kernel-placeholder-*$$dist*.rpm $$vmrepo/rpm/ ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-libs-$(VERSION_LIBS)*$$dist*.rpm $$vmrepo/rpm/;\
	done

update-repo-installer:
	ln -f $(RPMS_DIR)/x86_64/qubes-core-dom0-*$(VERSION_DOM0)*$(DIST_DOM0)*.rpm ../installer/yum/qubes-dom0/rpm/
	ln -f $(RPMS_DIR)/x86_64/qubes-core-libs-$(VERSION_LIBS)*fc18*.rpm ../installer/yum/qubes-dom0/rpm/

update-repo-template:
	for vmrepo in ../template-builder/yum_repo_qubes/* ; do \
		dist=$$(basename $$vmrepo) ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-vm-*$(VERSION_VM)*$$dist*.rpm $$vmrepo/rpm/ ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-vm-kernel-placeholder-*$$dist*.rpm $$vmrepo/rpm/ ;\
		ln -f $(RPMS_DIR)/x86_64/qubes-core-libs-$(VERSION_LIBS)*$$dist*.rpm $$vmrepo/rpm/;\
	done

clean:
	make -C dom0/qmemman clean
	make -C dom0/restore clean
	make -C misc clean
	make -C qrexec clean
	make -C u2mfn clean
	make -C vchan -f Makefile.linux clean
