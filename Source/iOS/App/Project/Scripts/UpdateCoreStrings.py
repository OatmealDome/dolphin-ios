import os
import polib
import re
import sys

# This tool writes the contents of the "po" files to the required ".strings" format
# for iOS.
#
# UpdateDolphinStrings.py <po files directory> <localizables directory>

loaded_pos = {}

def convert_string(str):
  # Strip (&X) for Japanese
  str = re.sub("\(&(\S)\)", "", str)
  
  # Remove & in &X
  str = re.sub("&(\S)", "\g<1>", str)
  
  # Strip trailing : and ： (full-width)
  if str.endswith(':') or str.endswith('：'):
    str = str[:-1]
  
  return str

for root, dirs, files in os.walk(sys.argv[1]):
  for po_path in files:
    # Skip the template file
    if po_path.endswith('.pot'):
      continue
      
    language = os.path.splitext(os.path.basename(po_path))[0]
    
    # Manual overrides
    if language == "pt":
      language = "pt-BR"
    elif language == "zh_CN":
      language = "zh-Hans"
    
    po = polib.pofile(os.path.join(sys.argv[1], po_path))
    
    po_entries = {}
    
    # Load the po and its strings into a dictionary
    for entry in po:
      msgstr = entry.msgstr
      if not entry.msgstr:
        msgstr = entry.msgid
        
      msgid = convert_string(entry.msgid)
      msgstr = convert_string(msgstr)
      
      po_entries[msgid] = msgstr
      
    loaded_pos[language] = po_entries

for language, entries in loaded_pos.items():
    strings_path = os.path.join(sys.argv[2], language + '.lproj', 'Core.strings')
    
    # Skip unsupported languages
    if not os.path.exists(strings_path):
      continue
    
    print('Processing ' + language + ' for ' + strings_path)
    
    with open(strings_path, 'w') as strings_file:
      for msgid, msgstr in entries.items():
        strings_file.write('"' + msgid.replace(r'"', r'\"') + '" = "' + msgstr.replace(r'\"', r'\\"').replace(r'"', r'\"') + '";\n')
