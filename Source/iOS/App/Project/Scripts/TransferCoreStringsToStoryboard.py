import os
import re
import sys

loaded_core_strings = {}

def get_core_strings(language):
  if language in loaded_core_strings:
    return loaded_core_strings[language]
  
  strings = {}
  
  with open(os.path.join(sys.argv[2], language + ".lproj", "Core.strings"), 'r+') as f:
    content = f.read()
  
    for match_obj in re.finditer(r'"(.*)" = "(.*)";\n', content):
      strings[match_obj.group(1)] = match_obj.group(2)
  
  loaded_core_strings[language] = strings
  
  return strings

found_files = []

for root, dirs, files in os.walk(sys.argv[1]):
  for file in files:
    if not file.endswith(".strings"):
      continue
    
    found_files.append(os.path.join(root, file))

for file in found_files:
  language = os.path.splitext(file.split('/')[-2])[0]
  
  if language == "en":
    continue
  
  strings = get_core_strings(language)
  
  with open(file, 'r+') as f:
    content = f.read()
    
    # Replace all matches
    for key, value in strings.items():
      content = content.replace('"' + key + '";\n', '"' + value + '";\n')
      
    f.seek(0)
    f.write(content)
    f.truncate()
  
  
  
  
