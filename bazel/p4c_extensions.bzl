"""Defines a mechanism for building p4c with custom backends.

To build p4c with additional IR definitions, define a target
"@com_github_p4lang_p4c_extension//:ir_extensions" that exports additional p4c
IR .def files. Consult the bazel/examples folder for an example of how to do
this.
"""

def ir_extensions():
  """Returns list of additional IR definition files, if any."""
  if native.existing_rule("com_github_p4lang_p4c_extension"):
    return ["@com_github_p4lang_p4c_extension//:ir_extensions"]
  return []
