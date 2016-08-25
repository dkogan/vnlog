# These 'xxx' markers are to be replaced by git_build_rpm
Name:           xxx
Version:        xxx
Release:        1%{?dist}
Summary:        Tools to manipulate whitespace-separated ASCII logs
BuildArch:      noarch

License:        Proprietary
URL:            https://github.jpl.nasa.gov/maritime-robotics/asciilog/
Source0:        https://github.jpl.nasa.gov/maritime-robotics/asciilog/archive/%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildRequires:  /usr/bin/pod2man

%description
We want to manipulate data logged in a very simple whitespace-separated ASCII
format. The format in compatible with the usual UNIX tools, and thus can be
processed with a multitude of existing methods. Some convenience tools and
library interfaces are provided to create new data in this format and manipulate
existing data

%prep
%setup -q

%build
pod2man -r '' --section 1 --center "ASCII-log filter tool" asciilog-filter asciilog-filter.1

%install
mkdir -p %{buildroot}%{_bindir}
cp asciilog-filter %{buildroot}%{_bindir}

mkdir -p %{buildroot}%{_mandir}/man1
cp *.1 %{buildroot}%{_mandir}/man1/

%clean
rm *.1

%files
%{_bindir}/*
%doc %{_mandir}
