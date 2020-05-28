licenses(["notice"])  # Apache v2

load("@//:lex.bzl", "genlex")
load("@//:bison.bzl", "genyacc")

package(
    default_visibility = ["//visibility:public"],
)

P4C_BUILD_DEFAULT_COPTS = [
    "-DCONFIG_PKGDATADIR=\\\"external/p4lang_p4c\\\"",
    # This is a bit of a hack, but will work if the binary is executed by Bazel
    # For a more comprehensive solution, we need to make p4c aware of Bazel, specifically:
    # https://github.com/bazelbuild/bazel/blob/master/tools/cpp/runfiles/runfiles_src.h
]

genrule(
    name = "sed_config_h",
    srcs = ["cmake/config.h.cmake"],
    outs = ["config.h"],
    cmd = ("sed 's|cmakedefine|define|g' $< | " +
           "sed 's|define HAVE_LIBGC 1|undef HAVE_LIBGC|g' > $@"),
    visibility = ["//visibility:private"],
)

cc_library(
    name = "config_h",
    hdrs = [
        "config.h",
    ],
    includes = ["."],
    visibility = [":__subpackages__"],
)

genyacc(
    name = "p4_parser_yacc",
    src = "frontends/parsers/p4/p4parser.ypp",
    extra_outs = ["frontends/parsers/p4/stack.hh"],
    header_out = "frontends/parsers/p4/p4parser.hpp",
    source_out = "frontends/parsers/p4/p4parser.cc",
)

genyacc(
    name = "v1_parser_yacc",
    src = "frontends/parsers/v1/v1parser.ypp",
    extra_outs = ["frontends/parsers/v1/stack.hh"],
    header_out = "frontends/parsers/v1/v1parser.hpp",
    source_out = "frontends/parsers/v1/v1parser.cc",
)

genrule(
    name = "p4lexer_lex",
    srcs = ["frontends/parsers/p4/p4lexer.ll"],
    outs = ["frontends/parsers/p4/p4lexer.lex"],
    cmd = ("sed '/%option outfile=\"lex.yy.c\"/d' $< > $@"),
    visibility = ["//visibility:private"],
)

genlex(
    name = "p4lexer",
    src = "frontends/parsers/p4/p4lexer.lex",
    out = "frontends/parsers/p4/p4lexer.cc",
    prefix = "yy",
    visibility = ["//visibility:private"],
)

genrule(
    name = "v1lexer_lex",
    srcs = ["frontends/parsers/v1/v1lexer.ll"],
    outs = ["frontends/parsers/v1/v1lexer.lex"],
    cmd = ("sed '/%option outfile=\"lex.yy.c\"/d' $< > $@"),
    visibility = ["//visibility:private"],
)

genlex(
    name = "v1lexer",
    src = "frontends/parsers/v1/v1lexer.lex",
    out = "frontends/parsers/v1/v1lexer.cc",
    prefix = "yy",
    visibility = ["//visibility:private"],
)

cc_library(
    name = "p4c_includes",
    includes = [
        ".",
        "ir/",
        "lib/",
        "tools/ir-generator",
    ],
    visibility = [":__subpackages__"],
)

# This rule helps split some circular dependencies between subdirectories.
cc_library(
    name = "p4c_frontend_h",
    hdrs = [
        "frontends/p4/typeChecking/typeSubstitution.h",
    ] + glob([
        "frontends/p4/*.h",
    ]) + glob([
        "frontends/common/*.h",
    ]),
    visibility = ["//visibility:private"],
)

# The ir-generator tool uses a parser built by these genlex and
# genyacc rules.
genlex(
    name = "ir_generator_lex",
    src = "tools/ir-generator/ir-generator-lex.l",
    out = "tools/ir-generator/ir-generator-lex.c",
    includes = [
        "tools/ir-generator/ir-generator-yacc.hh",
    ],
    prefix = "yy",
)

genyacc(
    name = "ir_generator_yacc",
    src = "tools/ir-generator/ir-generator.ypp",
    header_out = "tools/ir-generator/ir-generator-yacc.hh",
    source_out = "tools/ir-generator/ir-generator-yacc.cc",
)

# This cc_library contains the ir-generator tool sources, including the
# ir-generator parser source from the lex/yacc output.  The srcs attribute
# excludes generator.cpp since it is part of the cc_binary.
cc_library(
    name = "p4c_ir_generator_lib",
    srcs = [
        "tools/ir-generator/ir-generator-yacc.cc",
    ] + glob(
        ["tools/ir-generator/*.cpp"],
        exclude = ["tools/ir-generator/generator.cpp"],
    ),
    hdrs = [
        "tools/ir-generator/ir-generator-lex.c",
        "tools/ir-generator/ir-generator-yacc.hh",
    ] + glob([
        "tools/ir-generator/*.h",
    ]),
    deps = [
        ":p4c_includes",
        ":p4c_toolkit",
    ],
)

# The next rule builds the ir-generator tool binary.
cc_binary(
    name = "irgenerator",
    srcs = ["tools/ir-generator/generator.cpp"],
    linkopts = ["-lgmp"],
    visibility = [":__subpackages__"],
    deps = [
        ":p4c_ir_generator_lib",
        ":p4c_toolkit",
    ],
)

genrule(
    name = "ir_generated_files",
    srcs = [
        "frontends/p4-14/ir-v1.def",
        "backends/bmv2/bmv2.def",
    ] + glob([
        "ir/*.def",
    ]),
    outs = [
        "ir/gen-tree-macro.h",
        "ir/ir-generated.cpp",
        "ir/ir-generated.h",
    ],
    cmd = ("$(location " +
           ":irgenerator) " +
           "-t $(@D)/ir/gen-tree-macro.h -i $(@D)/ir/ir-generated.cpp " +
           "-o $(@D)/ir/ir-generated.h " +
           "$(location ir/base.def) " +
           "$(location ir/type.def) " +
           "$(location ir/expression.def) " +
           "$(location ir/ir.def) " +
           "$(location ir/v1.def) " +
           "$(location frontends/p4-14/ir-v1.def) " +
           "$(locations backends/bmv2/bmv2.def )"),
    tools = [":irgenerator"],
)

# This library contains p4c's IR (Internal Representation) of the P4 spec.
cc_library(
    name = "p4c_ir",
    srcs = [
        "ir/ir-generated.cpp",
    ] + glob([
        "ir/*.cpp",
    ]),
    hdrs = [
        "ir/gen-tree-macro.h",
        "ir/ir-generated.h",
    ] + glob([
        "ir/*.h",
    ]),
    visibility = [":__subpackages__"],
    deps = [
        ":p4c_frontend_h",
        ":p4c_includes",
        ":p4c_toolkit",
    ],
)

# This library combines the frontend and midend sources plus the
# generated parser sources.
cc_library(
    name = "p4c_frontend_midend",
    srcs = [
        # These are the parser files from the genlex/genyacc rules, which
        # glob doesn't find.
        "frontends/parsers/p4/p4lexer.cc",
        "frontends/parsers/p4/p4parser.cc",
        "frontends/parsers/v1/v1lexer.cc",
        "frontends/parsers/v1/v1parser.cc",
    ] + glob([
        "frontends/*.cpp",
        "frontends/**/*.cpp",
        "midend/*.cpp",
    ]),
    hdrs = [
        "frontends/parsers/p4/p4lexer.hpp",
        "frontends/parsers/p4/p4AnnotationLexer.hpp",
        "frontends/parsers/p4/abstractP4Lexer.hpp",
        "frontends/parsers/p4/p4parser.hpp",
        "frontends/parsers/p4/stack.hh",
        "frontends/parsers/v1/stack.hh",
        "frontends/parsers/v1/v1lexer.hpp",
        "frontends/parsers/v1/v1parser.hpp",
        "ir/ir-generated.cpp",
    ] + glob([
        "frontends/*.h",
        "frontends/**/*.h",
        "midend/*.h",
    ]),
    copts = P4C_BUILD_DEFAULT_COPTS,
    data = glob([
        "p4include/*.p4",
    ]),
    visibility = [":__subpackages__"],
    deps = [
        ":control_plane_h",
        ":p4c_ir",
        ":p4c_toolkit",
        "@boost//:algorithm",
        "@boost//:functional",
        "@boost//:iostreams",
    ],
)

cc_library(
    name = "control_plane",
    srcs = glob([
        "control-plane/*.cpp",
    ]),
    copts = P4C_BUILD_DEFAULT_COPTS,
    deps = [
        ":control_plane_h",
        ":p4c_frontend_midend",
        ":p4c_ir",
        ":p4c_toolkit",
    ],
)

cc_library(
    name = "p4c_toolkit",
    srcs = glob([
        "lib/*.cpp",
    ]),
    hdrs = glob([
        "lib/*.h",
    ]),
    includes = ["."],
    deps = [
        ":config_h",
        "@boost//:format",
        "@p4c_gtest//:p4c_gtest_includes",
    ],
)

# The control-plane headers are in a separate cc_library to break the
# circular dependencies between control-plane and frontends/midend.
cc_library(
    name = "control_plane_h",
    hdrs = glob(
        ["control-plane/*.h"],
    ),
    deps = [
        ":p4c_frontend_h",
        ":p4c_ir",
        ":p4c_toolkit",
        "@p4lang_p4runtime//:p4info_cc_proto",
        "@p4lang_p4runtime//:p4runtime_cc_grpc_proto",
        "@p4lang_p4runtime//:p4types_cc_proto",
    ],
)

# These rules build p4c binaries with the bmv2 soft switch and PSA backends.
# These binaries are for example purposes.  Backends for Stratum production will
# be implemented elsewhere and build with dependencies on the libraries above.
# TODO(): Add rules for the PSA variation.
cc_library(
    name = "p4c_bmv2_common_lib",
    srcs = glob(
        ["backends/bmv2/common/*.cpp"],
    ),
    hdrs = glob([
        "backends/bmv2/common/*.h",
    ]),
    copts = P4C_BUILD_DEFAULT_COPTS,
    deps = [
        ":p4c_frontend_midend",
        ":p4c_ir",
        ":p4c_toolkit",
    ],
)

cc_library(
    name = "p4c_bmv2_simple_lib",
    srcs = glob(
        ["backends/bmv2/simple_switch/*.cpp"],
        exclude = ["backends/bmv2/simple_switch/main.cpp"],
    ),
    hdrs = glob([
        "backends/bmv2/simple_switch/*.h",
    ]),
    copts = P4C_BUILD_DEFAULT_COPTS,
    visibility = [":__subpackages__"],
    deps = [
        ":p4c_bmv2_common_lib",
        ":p4c_frontend_midend",
        ":p4c_ir",
        ":p4c_toolkit",
    ],
)

genrule(
    name = "p4c_bmv2_version",
    srcs = ["backends/bmv2/simple_switch/version.h.cmake"],
    outs = ["backends/bmv2/simple_switch/version.h"],
    cmd = ("sed 's|@P4C_VERSION@|0.0.0.0|g' $< > $@"),
    visibility = ["//visibility:private"],
)

cc_binary(
    name = "p4c_bmv2",
    srcs = [
        "backends/bmv2/simple_switch/main.cpp",
        "backends/bmv2/simple_switch/version.h",
    ],
    copts = P4C_BUILD_DEFAULT_COPTS,
    linkopts = [
        "-lgmp",
        "-lgmpxx",
    ],
    deps = [
        ":control_plane",
        ":control_plane_h",
        ":p4c_bmv2_common_lib",
        ":p4c_bmv2_simple_lib",
        ":p4c_frontend_midend",
        ":p4c_ir",
        ":p4c_toolkit",
    ],
)

# This builds the p4test backend
genrule(
    name = "p4c_p4test_version",
    srcs = ["backends/p4test/version.h.cmake"],
    outs = ["backends/p4test/version.h"],
    cmd = ("sed 's|@P4C_VERSION@|0.0.0.0|g' $< > $@"),
    #visibility = ["//visibility:private"],
)
