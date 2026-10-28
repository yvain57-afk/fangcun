"""Apply reviewed exact-literal copy, never transform user content or storage keys.
The TSVs retain source copy for subsequent localization. No lexical replacement.
"""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[2]
mapping={}
for p in (ROOT/'docs/content/little-exhale-2').glob('*-copy.tsv'):
 for line in p.read_text().splitlines():
  if not line.strip():continue
  source,target=line.split('\t',1);mapping[source]=target
count=0
# Presentation files only; Core language changes are explicit elsewhere.
for base in ['InnerBalance/InnerBalanceApp','InnerBalance/InnerBalanceWatch']:
 for p in (ROOT/base).rglob('*.swift'):
  original=p.read_text()
  def sub(m):
   global count
   s=m.group(1)
   if s in mapping:
    count+=1;return '"'+mapping[s]+'"'
   return m.group(0)
  updated=re.sub(r'"((?:\\.|[^"\\])*)"',sub,original)
  if updated!=original:p.write_text(updated)
print('Exact authored literals updated:',count)
