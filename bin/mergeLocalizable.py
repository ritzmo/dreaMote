#!/bin/python

DEBUG = False

import re
import os
pattern = re.compile('^"(.*?)" = "(.*?)";.*?')

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
	sourcefiles = find("Classes", True, 'm')
	try: removeUpdateTemplate()
	except Exception: pass
	os.system("genstrings -bigEndian -o . %s" % ' '.join(sourcefiles))
	os.system("iconv -t UTF-8 -f UTF-16BE < Localizable.strings > Localizable.strings.utf8")
	os.rename("Localizable.strings.utf8" , "Localizable.strings")

def removeUpdateTemplate():
	os.unlink("Localizable.strings")

def updateLanguage(lang):
	print "Updating", lang

	# Read current strings
	orig = open('%s.lproj/Localizable.strings' % lang, 'r')
	translated = {}
	for line in orig.readlines():
		match = pattern.match(line)
		if match and match.group(2): # ignore empty translations
			translated[match.group(1)] = match.group(2)
	if DEBUG:
		print "Found the following translated strings:"
		for key, value in translated.iteritems():
			print key, "=", value
	orig.close()

	# Read "new" strings and format
	update = open('Localizable.strings', 'r')
	newtext = update.readlines()
	update.close()
	idx = 0
	for line in newtext[:]:
		match = pattern.match(line)
		if match:
			key = match.group(1)
			if translated.has_key(key):
				if DEBUG:
					print "Found match:", key
				value = translated[key]
				del translated[key]
				newtext[idx] = '"%s" = "%s";\n' % (key, value)
			else:
				value = match.group(2)
				print "Found untranslated string:", key, "=", value
				# TODO: add interactive translation mechanism
				newtext[idx] = '/*"%s" = "%s";*/\n' % (key, value)

		idx += 1
	if translated:
		print "There are remaining strings:"
		newtext.append("\n\n/* old strings */\n")
		for key, value in translated.iteritems():
			newtext.append('"%s" = "%s";\n' % (key, value))
			print key, "=", value

	# Save merged file
	new = open('%s.lproj/Localizable.strings' % lang, 'w')
	new.writelines(newtext)
	new.close()

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
