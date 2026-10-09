# Use the local mrbuild or the system mrbuild or tell the user how to download
# it

ifneq (,$(wildcard mrbuild/))
  MRBUILD_MK=mrbuild
  MRBUILD_BIN=mrbuild/bin
else ifneq (,$(wildcard /usr/include/mrbuild/Makefile.common.header))
  MRBUILD_MK=/usr/include/mrbuild
  MRBUILD_BIN=/usr/bin
else ifneq (,$(wildcard $(HOMEBREW_PREFIX)/include/mrbuild/Makefile.common.header))
  MRBUILD_MK=$(HOMEBREW_PREFIX)/include/mrbuild
  MRBUILD_BIN=$(HOMEBREW_PREFIX)/bin
else
  V      := 1.21
  SHA512 := 9edafde4f442e90a805d9327cfc4d3c1dfa2cd6d2697dc65fba4a548403c464a1b1d3272539cbd7d0ef8144d98229d9b1cf3788f4b06d4101aa0af8bcd35c652
  URL   := https://github.com/dkogan/mrbuild/archive/refs/tags/v$V.tar.gz
  TARGZ := mrbuild-$V.tar.gz

  cmd := curl -L -o $(TARGZ) ${URL} && echo "$(SHA512)  $(TARGZ)" | shasum -a 512 -c && tar xvfz $(TARGZ) && ln -fs mrbuild-$V mrbuild

  $(error mrbuild not found. Either 'apt install mrbuild' or 'brew install mrbuild' or get it locally like this: '${cmd}')
endif
