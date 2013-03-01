# Copies files from demo/ to build/. Any .html files are
# interpreted by GNU m4 and wrapped in a the GNU m4
# template. Common m4 macros may be stored in a macros
# file.

M4 		 := m4 -I etc -P
MACROS   := macros.m4
TEMPLATE := template.html.m4
SRC      := demo-src
DST      := build

# Build a list of all the files that should exist when the
# baking is done. We do this by getting a list of all the
# source files and rewriting pathnames and file suffixes as
# necessary.
#
# "pages" is the subset of these files which are pieces of
# content while "targets" include also files which collate
# or enumerate other pages (blog rollups, sitemaps, etc.)
#
# This mess temporarily renames whatevs.index to I/whatevs
# so that it can apply the same steps to convert the
# filenames to their target filenames to the indices and
# non-indices. Then it separates the indices into another
# vairable so we can have the indices depend on the
# completed processing of the non-indices.
#
# In words, we're doing this. "To obtain the list of all
# the files we want to generate,
# - collect the filenames of all files in the source
#   directory
# - remove temporary files like .inc and .swp
# - change the path so that they live in the same subpath
#   of the destination directory
# - mark those that have a .index suffix as indices
# - remove all .index suffixes
# - remove all .m4 suffixes
# - transform all .md suffixes into .html
# - split all the makred indices into their own variable
targets := $(shell find $(SRC) -type f)
targets := $(filter-out %.inc %.swp,$(targets))
targets := $(targets:$(SRC)/%=$(DST)/%)
targets := $(filter-out %.index,$(targets)) $(addprefix I/,$(filter %.index,$(targets)))
targets := $(targets:.index=)
targets := $(targets:.m4=)
targets := $(targets:.md=.html)
indices := $(filter I/%,$(targets))
indices := $(indices:I/%=%)
targets := $(filter-out I/%,$(targets))
#
# Maybe if you wanted to have a helper script that could
# process the list of files into the list of destinations,
# you could do this instead of all of the above:
#
# targets := $(shell find $(SRC) -type f -print0 | xargs -0 python list_targets.py
#
# But I avoid that because I still want this project to
# depend on GNU make and M4.
# 
# Or, you could do something like have an includable
# makefile snippet generated by some script:
#
# include targets_and_indices.mk
# targets_and_indices.mk: create_targets.py
# 	python create_targets.py > $@

all: $(targets) $(indices)

# First, all source files will be copied verbatim to the
# destination. I use the ubiquitous unix 'install' tool
# here because it creates any needed paths automatically.
# When Make is done compiling it will delete those copies.
$(DST)/%: $(SRC)/%
	install -m 644 -D $< $@

# Any files named '*.html.m4' will be interpreted by M4
# with the macros available, wrapped in the HTML template,
# and saved without the '.m4' extension. 
$(DST)/%.html: $(DST)/%.html.m4 $(MACROS) $(TEMPLATE)
	$(M4) $(MACROS) $< $(TEMPLATE) > $@

include etc/pandoc.mk

# Any files named '*.index' will depend on the rest of the
# pages having been processed before being processed
# themselves. In this way you can create automatic indices,
# sitemaps, etc. No processing occurs here, we just remove
# the extension.
$(DST)/%: $(DST)/%.index $(targets)
	cp $< $@

# Any other files named '*.m4' will be interpreted by M4
# with the macros available, saved without the '.m4'
# extension, but will not be wrapped in the HTML template.
# This lets you use M4 within .css, .js, etc. (Just name
# them blah.css.m4, blah.js.m4, etc.)
$(DST)/%: $(DST)/%.m4 $(MACROS)
	$(M4) $(MACROS) $< > $@

# By default, GNU Make will skip any source files that have
# not been modified since the last time they were rendered.
# Run 'make clean' to erase the destination directory for a
# complete rebuild. I do a 'mv' then 'rm' to reduce the
# chances of running an 'rm -rf /'.
clean:
	mv $(DST) .old_dst
	rm -rf .old_dst

# vim: tw=59 :
