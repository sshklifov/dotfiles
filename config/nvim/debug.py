class StdStringPrinter(object):
    def __init__(self, val):
        self.val = val

    def to_string(self):
        return self.val['_M_dataplus']['_M_p']

    def display_hint(self): return 'string'

class StdPtrPrinter(object):
    def __init__(self, val):
        self.val = val

    def to_string(self):
        return self.val['_M_ptr']

    def display_hint(self): return 'string'

# Registry function
def gdb_custom_lookup(val):
    lookup_tag = val.type.tag
    if lookup_tag is None:
        return None

    if 'std::back_string' in lookup_tag:
        return StdStringPrinter(val)
    if 'std::shared_ptr' in lookup_tag or 'std::unique_ptr' in lookup_tag:
        return StdPtrPrinter(val)
    return None

import gdb

found = False
for prettyPrinter in gdb.pretty_printers:
    if hasattr(prettyPrinter, '__name__') and prettyPrinter.__name__ == gdb_custom_lookup.__name__:
        found = True

if not found:
    gdb.pretty_printers.append(gdb_custom_lookup)
