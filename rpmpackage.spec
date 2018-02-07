# These 'xxx' markers are to be replaced by git_build_rpm
Name:           xxx
Version:        xxx
Release:        1%{?dist}
Summary:        Tools to manipulate whitespace-separated ASCII logs

License:        LGPL-2.1+
URL:            https://github.com/dkogan/vanillog/
Source0:        https://github.com/dkogan/vanillog/archive/%{version}.tar.gz#/%{name}-%{version}.tar.gz

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
Summary:        Development files for vanillog

Requires: perl-String-ShellQuote

%description devel
The library needed for the vanillog C interface and the vnl-gen-header
tool needed to define the fields

%package tools
Requires:       %{name}%{_isa} = %{version}-%{release}
Summary:        Tools for manipulating vanillogs
Requires:       mawk
Requires:       perl-Text-Table


%description tools
Various helper tools to make working with vanillogs easier

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
%{_bindir}/vnl-gen-header
%doc %{_mandir}/man1/vnl-gen-header.1.gz

%files tools
%{_bindir}/vnl-filter
%{_bindir}/vnl-tailf
%{_bindir}/vnl-make-matrix
%{_bindir}/vnl-align
%doc %{_mandir}/man1/vnl-filter.1.gz
%doc %{_mandir}/man1/vnl-tailf.1.gz
%doc %{_mandir}/man1/vnl-make-matrix.1.gz
%doc %{_mandir}/man1/vnl-align.1.gz
