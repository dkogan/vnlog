# These 'xxx' markers are to be replaced by git_build_rpm
Name:           xxx
Version:        xxx
Release:        1%{?dist}
Summary:        Tools to manipulate ASCII logs
BuildArch:      noarch

License:        Proprietary
URL:            https://github.jpl.nasa.gov/maritime-robotics/asciilog/
Source0:        https://github.jpl.nasa.gov/maritime-robotics/asciilog/archive/%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildRequires:  /usr/bin/pod2man

%description
We provide tools to manipulate ASCII logged data.

%prep
%setup -q

%build
pod2man -r '' --section 1 --center "ASCII-log filter tool" asciilog_filter.pl asciilog_filter.1

%install
mkdir -p %{buildroot}%{_bindir}
cp asciilog_filter.pl %{buildroot}%{_bindir}

mkdir -p %{buildroot}%{_mandir}/man1
cp *.1 %{buildroot}%{_mandir}/man1/

%clean
rm *.1

%files
%{_bindir}/*
%doc %{_mandir}
