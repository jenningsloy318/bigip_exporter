%define debug_package %{nil}

Name:    bigip_exporter
Version: 1.0.0
Release: 1%{?dist}
Summary: Prometheus bigip exporter.
License: MIT
URL:     https://github.com/jenningsloy318/bigip_exporter

Source0: %{name}
Source1: %{name}.service
Source2: %{name}.yml


# distribution specific definitions
%define use_systemd ((0%{?rhel} && 0%{?rhel} >= 7) || (0%{?suse_version} == 1315)


%if 0%{?rhel} == 7
Requires(pre): shadow-utils
%endif

%if 0%{?suse_version} == 1315
Requires(pre): shadow
%endif

%description

This is an exporter that exposes information gathered from bigip   for use by the Prometheus monitoring system.

%prep
%build
/bin/true

%install
mkdir -vp %{buildroot}%{_sharedstatedir}/prometheus
mkdir -vp  %{buildroot}%{_sysconfdir}/prometheus
install -D -m 755 %{SOURCE0}  %{buildroot}%{_bindir}/%{name}
install -D -m 644 %{SOURCE1} %{buildroot}%{_unitdir}/%{name}.service
install -D -m 644 %{SOURCE2} %{buildroot}%{_sysconfdir}/prometheus

%pre
getent group prometheus >/dev/null || groupadd -r prometheus
getent passwd prometheus >/dev/null || \
  useradd -r -g prometheus -d %{_sharedstatedir}/prometheus -s /sbin/nologin \
          -c "Prometheus services" prometheus
exit 0

%post
if  ! getent group prometheus >/dev/null  ; then
    groupadd -r prometheus
fi

if  ! getent passwd prometheus  >/dev/null  ; then
    useradd -r -M -s /bin/false -d /etc/prometheus -g prometheus prometheus
fi

chown -R prometheus:prometheus /etc/prometheus
systemctl daemon-reload || true
systemctl enable bigip_exporter || true
systemctl start bigip_exporter
exit 0


%preun
%systemd_preun %{name}.service

%postun
%systemd_postun %{name}.service
userdel  prometheus || true
groupdel  prometheus  || true

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_unitdir}/%{name}.service
%config(noreplace) %{_sysconfdir}/prometheus/bigip_exporter.yml
%dir %attr(755, prometheus, prometheus)%{_sharedstatedir}/prometheus
