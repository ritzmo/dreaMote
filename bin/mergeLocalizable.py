#!/bin/python

DEBUG = False

import re
import os
pattern = re.compile('^"(.*?)" = "(.*?)";.*?')
tables = "Localizable", "AutoTimer", "EPGRefresh"

def find(dirname, recursive, *args):
	files = []
	for file in os.listdir(dirname):
		filename = os.path.join(dirname, file)
		if os.path.isfile(filename):
			if not args or os.path.splitext(filename)[1][1:] in args:
				files.append(filename)
		elif recursive and os.path.isdir(filename):
			files.extend(find(filename, recursive, *args))
	return files

def generateUpdateTemplate():
	print "Updating template"
	sourcefiles = find("Classes", True, 'm', 'h')
	try: removeUpdateTemplate()
	except Exception: pass
	os.system("genstrings -bigEndian -o . %s" % ' '.join(sourcefiles))
	for table in tables:
		os.system("iconv -t UTF-8 -f UTF-16BE < %s.strings > %s.strings.utf8" % (table, table))
		os.rename("%s.strings.utf8" % (table,) , "%s.strings" % (table,))

def removeUpdateTemplate():
	for table in tables:
		os.unlink("%s.strings" % (table,))

def updateLanguage(lang):
	print "Updating", lang

	# Read current strings
	translated = {}
	for table in tables:
		try:
			orig = open('%s.lproj/%s.strings' % (lang, table), 'r')
		except IOError, ioe:
			print '%s.lproj/%s.strings does not exist, starting from scratch.' % (lang, table)
		else:
			for line in orig.readlines():
				match = pattern.match(line)
				if match and match.group(2): # ignore empty translations
					translated.setdefault(match.group(1), {})[table] = match.group(2)
			if DEBUG:
				print "Found the following translated strings:"
				for key, value in translated.iteritems():
					print key, "=", value
			orig.close()

	for table in tables:
		# Read "new" strings and format
		update = open('%s.strings' % (table,), 'r')
		newtext = update.readlines()
		update.close()
		idx = 0
		for line in newtext[:]:
			match = pattern.match(line)
			if match:
				key = match.group(1)
				if key in translated:
					if DEBUG:
						print "Found match:", key, "("+repr(translated[key])+")"
					if table in translated[key]:
						value = translated[key][table]
						del translated[key][table]
					else:
						tempTable = translated[key].keys()[1]
						value = translated[key][tempTable]
						print "Accepting %s from table %s for %s in table %s" % (value, tempTable, key, table)
						del translated[key][tempTable]
						del tempTable
					if not translated[key]:
						del translated[key]
					newtext[idx] = '"%s" = "%s";\n' % (key, value)
				else:
					value = match.group(2)
					print "Found untranslated string:", key
					# TODO: add interactive translation mechanism
					newtext[idx] = '/*"%s" = "%s";*/\n' % (key, value)

			idx += 1

		# Save merged file
		new = open('%s.lproj/%s.strings' % (lang, table), 'w')
		new.writelines(newtext)
		new.close()

	if translated:
		print "There are remaining strings:"
		for key, value in translated.iteritems():
			print key, "=", value

def main():
	import sys
	langs = sys.argv[1:]
	if not langs: langs = ('de', 'en', 'fr')

	generateUpdateTemplate()
	for lang in langs:
		print "\n\n"
		updateLanguage(lang)
	removeUpdateTemplate()

if __name__ == '__main__':
	main()
