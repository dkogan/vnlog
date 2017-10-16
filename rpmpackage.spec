# These 'xxx' markers are to be replaced by git_build_rpm
Name:           xxx
Version:        xxx
Release:        1%{?dist}
Summary:        Tools to manipulate whitespace-separated ASCII logs

License:        Proprietary
URL:            https://github.jpl.nasa.gov/maritime-robotics/asciilog/
Source0:        https://github.jpl.nasa.gov/maritime-robotics/asciilog/archive/%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildRequires: /usr/bin/pod2man
BuildRequires: mrbuild >= 0.43
BuildRequires: perl-IPC-Run
BuildRequires: perl-Text-Diff
BuildRequires: perl-String-ShellQuote
BuildRequires: perl-List-MoreUtils


# for tests
BuildRequires: mawk

%description
We want to manipulate data logged in a very simple whitespace-separated ASCII
format. The format in compatible with the usual UNIX tools, and thus can be
processed with a multitude of existing methods. Some convenience tools and
library interfaces are provided to create new data in this format and manipulate
existing data

%package devel
Requires:       %{name}%{_isa} = %{version}-%{release}
Summary:        Development files for asciilog

Requires: perl-String-ShellQuote

%description devel
The library needed for the asciilog C interface and the asciilog-gen-header
tool needed to define the fields

%package tools
Requires:       %{name}%{_isa} = %{version}-%{release}
Summary:        Tools for manipulating asciilogs
Requires:       mawk
Requires:       perl-Text-Table


%description tools
Various helper tools to make working with asciilogs easier

%prep
%setup -q

%build
make %{?_smp_mflags} all doc

%check
make check

%install
%make_install

%clean
make clean

%files
%doc
%{_libdir}/*.so.*
%doc %{_mandir}/man3/*
%{_datadir}/perl5

%files devel
%{_libdir}/*.so
%{_includedir}/*
%{_bindir}/asciilog-gen-header
%doc %{_mandir}/man1/asciilog-gen-header.1.gz

%files tools
%{_bindir}/asciilog-filter
%{_bindir}/asciilog-tailf
%{_bindir}/asciilog-make-matrix
%doc %{_mandir}/man1/asciilog-filter.1.gz
%doc %{_mandir}/man1/asciilog-tailf.1.gz
%doc %{_mandir}/man1/asciilog-make-matrix.1.gz
