#!/usr/bin/env python3
"""Generates PricePulse.xcodeproj/project.pbxproj by walking the PricePulse/ source
tree. Hand-writing 60+ UUIDs is error prone, so this script assigns them deterministically
and emits a classic (non-filesystem-synchronized) pbxproj for maximum Xcode compatibility.
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_ROOT = os.path.join(ROOT, "PricePulse")
PROJECT_NAME = "PricePulse"
BUNDLE_ID = "com.pricepulse.app"
DEPLOYMENT_TARGET = "17.0"

_counter = [0x1000]
def new_id():
    _counter[0] += 1
    return format(_counter[0], "024X")

SOURCE_EXT = {".swift"}
RESOURCE_EXT = {".storyboard"}

class FileRef:
    def __init__(self, path, name, kind):
        self.id = new_id()
        self.path = path          # path relative to project root (PricePulse.xcodeproj's parent)
        self.name = name
        self.kind = kind          # 'sources' | 'resources' | 'plist' | 'asset'
        self.build_file_id = new_id() if kind in ("sources", "resources", "asset") else None

class Group:
    def __init__(self, name, path=None):
        self.id = new_id()
        self.name = name
        self.path = path
        self.children = []  # list of Group or FileRef, in insertion order

def xcode_file_type(name):
    ext = os.path.splitext(name)[1]
    return {
        ".swift": "sourcecode.swift",
        ".plist": "text.plist.xml",
        ".storyboard": "file.storyboard",
        ".png": "image.png",
        ".md": "net.daringfireball.markdown",
    }.get(ext, "text")

all_file_refs = []
# `pricepulse_group` is the visible, on-disk "PricePulse" source folder (path="PricePulse").
# It's nested inside the invisible project root group (`root_group`, below) so file paths
# resolve as PricePulse/App/Foo.swift relative to the .xcodeproj, matching the real layout.
pricepulse_group = Group(PROJECT_NAME)
main_group = pricepulse_group

def build_tree(dir_path, parent_group):
    entries = sorted(os.listdir(dir_path))
    for entry in entries:
        full_path = os.path.join(dir_path, entry)
        rel_path = os.path.relpath(full_path, ROOT)

        if entry.endswith(".xcassets"):
            ref = FileRef(rel_path, entry, "asset")
            all_file_refs.append(ref)
            parent_group.children.append(ref)
            continue

        if os.path.isdir(full_path):
            sub_group = Group(entry, path=None)
            parent_group.children.append(sub_group)
            build_tree(full_path, sub_group)
            continue

        ext = os.path.splitext(entry)[1]
        if ext in SOURCE_EXT:
            kind = "sources"
        elif ext in RESOURCE_EXT:
            kind = "resources"
        elif entry == "Info.plist":
            kind = "plist"
        else:
            continue  # skip anything else (png inside non-asset folders, etc.)

        ref = FileRef(rel_path, entry, kind)
        all_file_refs.append(ref)
        parent_group.children.append(ref)

build_tree(SRC_ROOT, main_group)

sources_build_files = [f for f in all_file_refs if f.kind == "sources"]
resource_build_files = [f for f in all_file_refs if f.kind in ("resources", "asset")]
plist_ref = next(f for f in all_file_refs if f.kind == "plist")

# ---------------------------------------------------------------------------
# Top-level project structure ids
# ---------------------------------------------------------------------------
project_id = new_id()
root_group_id = new_id()
pricepulse_group_id = pricepulse_group.id
products_group_id = new_id()
frameworks_group_id = new_id()
app_product_id = new_id()

target_id = new_id()
target_build_config_list_id = new_id()
target_debug_config_id = new_id()
target_release_config_id = new_id()

project_build_config_list_id = new_id()
project_debug_config_id = new_id()
project_release_config_id = new_id()

sources_phase_id = new_id()
resources_phase_id = new_id()
frameworks_phase_id = new_id()

# SwiftSoup SPM package
package_ref_id = new_id()
package_product_id = new_id()
package_build_file_id = new_id()

scheme_container_proxy_id = new_id()

# ---------------------------------------------------------------------------
# Emit PBXBuildFile section
# ---------------------------------------------------------------------------
lines = []
lines.append("// !$*UTF8*$!")
lines.append("{")
lines.append("\tarchiveVersion = 1;")
lines.append("\tclasses = {")
lines.append("\t};")
lines.append("\tobjectVersion = 56;")
lines.append("\tobjects = {")

def emit(s=""):
    lines.append(s)

emit()
emit("/* Begin PBXBuildFile section */")
for f in sources_build_files:
    emit(f"\t\t{f.build_file_id} /* {f.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {f.id} /* {f.name} */; }};")
for f in resource_build_files:
    emit(f"\t\t{f.build_file_id} /* {f.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {f.id} /* {f.name} */; }};")
emit(f"\t\t{package_build_file_id} /* SwiftSoup in Frameworks */ = {{isa = PBXBuildFile; productRef = {package_product_id} /* SwiftSoup */; }};")
emit("/* End PBXBuildFile section */")

# ---------------------------------------------------------------------------
# PBXFileReference section
# ---------------------------------------------------------------------------
emit()
emit("/* Begin PBXFileReference section */")
emit(f"\t\t{app_product_id} /* {PROJECT_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {PROJECT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
for f in all_file_refs:
    if f.kind == "asset":
        emit(f"\t\t{f.id} /* {f.name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = \"{f.name}\"; sourceTree = \"<group>\"; }};")
    else:
        file_type = xcode_file_type(f.name)
        emit(f"\t\t{f.id} /* {f.name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = \"{f.name}\"; sourceTree = \"<group>\"; }};")
emit("/* End PBXFileReference section */")

# ---------------------------------------------------------------------------
# PBXFrameworksBuildPhase
# ---------------------------------------------------------------------------
emit()
emit("/* Begin PBXFrameworksBuildPhase section */")
emit(f"\t\t{frameworks_phase_id} /* Frameworks */ = {{")
emit("\t\t\tisa = PBXFrameworksBuildPhase;")
emit("\t\t\tbuildActionMask = 2147483647;")
emit("\t\t\tfiles = (")
emit(f"\t\t\t\t{package_build_file_id} /* SwiftSoup in Frameworks */,")
emit("\t\t\t);")
emit("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
emit("\t\t};")
emit("/* End PBXFrameworksBuildPhase section */")

# ---------------------------------------------------------------------------
# PBXGroup section (recursive)
# ---------------------------------------------------------------------------
emit()
emit("/* Begin PBXGroup section */")

def emit_group(group):
    emit(f"\t\t{group.id} /* {group.name} */ = {{")
    emit("\t\t\tisa = PBXGroup;")
    emit("\t\t\tchildren = (")
    for child in group.children:
        emit(f"\t\t\t\t{child.id} /* {child.name} */,")
    emit("\t\t\t);")
    emit(f"\t\t\tpath = \"{group.name}\";")
    emit("\t\t\tsourceTree = \"<group>\";")
    emit("\t\t};")
    for child in group.children:
        if isinstance(child, Group):
            emit_group(child)

# Products group
emit(f"\t\t{products_group_id} /* Products */ = {{")
emit("\t\t\tisa = PBXGroup;")
emit("\t\t\tchildren = (")
emit(f"\t\t\t\t{app_product_id} /* {PROJECT_NAME}.app */,")
emit("\t\t\t);")
emit("\t\t\tname = Products;")
emit("\t\t\tsourceTree = \"<group>\";")
emit("\t\t};")

# Frameworks (visual) group -- empty, SPM deps don't need a file entry here
emit(f"\t\t{frameworks_group_id} /* Frameworks */ = {{")
emit("\t\t\tisa = PBXGroup;")
emit("\t\t\tchildren = (")
emit("\t\t\t);")
emit("\t\t\tname = Frameworks;")
emit("\t\t\tsourceTree = \"<group>\";")
emit("\t\t};")

# Invisible project root group (this is what PBXProject.mainGroup points at). It has no
# path of its own -- it represents the directory the .xcodeproj lives in -- and contains
# the visible "PricePulse" source group (path="PricePulse") plus Products/Frameworks.
emit(f"\t\t{root_group_id} = {{")
emit("\t\t\tisa = PBXGroup;")
emit("\t\t\tchildren = (")
emit(f"\t\t\t\t{pricepulse_group_id} /* {PROJECT_NAME} */,")
emit(f"\t\t\t\t{products_group_id} /* Products */,")
emit(f"\t\t\t\t{frameworks_group_id} /* Frameworks */,")
emit("\t\t\t);")
emit("\t\t\tsourceTree = \"<group>\";")
emit("\t\t};")

# The visible "PricePulse" group itself (path="PricePulse") and everything under it.
emit_group(pricepulse_group)

emit("/* End PBXGroup section */")

# ---------------------------------------------------------------------------
# PBXNativeTarget
# ---------------------------------------------------------------------------
emit()
emit("/* Begin PBXNativeTarget section */")
emit(f"\t\t{target_id} /* {PROJECT_NAME} */ = {{")
emit("\t\t\tisa = PBXNativeTarget;")
emit(f"\t\t\tbuildConfigurationList = {target_build_config_list_id} /* Build configuration list for PBXNativeTarget \"{PROJECT_NAME}\" */;")
emit("\t\t\tbuildPhases = (")
emit(f"\t\t\t\t{sources_phase_id} /* Sources */,")
emit(f"\t\t\t\t{frameworks_phase_id} /* Frameworks */,")
emit(f"\t\t\t\t{resources_phase_id} /* Resources */,")
emit("\t\t\t);")
emit("\t\t\tbuildRules = (")
emit("\t\t\t);")
emit("\t\t\tdependencies = (")
emit("\t\t\t);")
emit(f"\t\t\tname = {PROJECT_NAME};")
emit("\t\t\tpackageProductDependencies = (")
emit(f"\t\t\t\t{package_product_id} /* SwiftSoup */,")
emit("\t\t\t);")
emit("\t\t\tproductName = PricePulse;")
emit(f"\t\t\tproductReference = {app_product_id} /* {PROJECT_NAME}.app */;")
emit("\t\t\tproductType = \"com.apple.product-type.application\";")
emit("\t\t};")
emit("/* End PBXNativeTarget section */")

# ---------------------------------------------------------------------------
# PBXProject
# ---------------------------------------------------------------------------
emit()
emit("/* Begin PBXProject section */")
emit(f"\t\t{project_id} /* Project object */ = {{")
emit("\t\t\tisa = PBXProject;")
emit("\t\t\tattributes = {")
emit("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
emit("\t\t\t\tLastSwiftUpdateCheck = 1600;")
emit("\t\t\t\tLastUpgradeCheck = 1600;")
emit("\t\t\t\tTargetAttributes = {")
emit(f"\t\t\t\t\t{target_id} = {{")
emit("\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
emit("\t\t\t\t\t};")
emit("\t\t\t\t};")
emit("\t\t\t};")
emit(f"\t\t\tbuildConfigurationList = {project_build_config_list_id} /* Build configuration list for PBXProject \"{PROJECT_NAME}\" */;")
emit("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
emit("\t\t\tdevelopmentRegion = en;")
emit("\t\t\thasScannedForEncodings = 0;")
emit("\t\t\tknownRegions = (")
emit("\t\t\t\ten,")
emit("\t\t\t\tBase,")
emit("\t\t\t);")
emit(f"\t\t\tmainGroup = {root_group_id};")
emit(f"\t\t\tproductRefGroup = {products_group_id} /* Products */;")
emit("\t\t\tprojectDirPath = \"\";")
emit("\t\t\tprojectRoot = \"\";")
emit("\t\t\ttargets = (")
emit(f"\t\t\t\t{target_id} /* {PROJECT_NAME} */,")
emit("\t\t\t);")
emit("\t\t\tpackageReferences = (")
emit(f"\t\t\t\t{package_ref_id} /* XCRemoteSwiftPackageReference \"SwiftSoup\" */,")
emit("\t\t\t);")
emit("\t\t};")
emit("/* End PBXProject section */")

# ---------------------------------------------------------------------------
# PBXResourcesBuildPhase
# ---------------------------------------------------------------------------
emit()
emit("/* Begin PBXResourcesBuildPhase section */")
emit(f"\t\t{resources_phase_id} /* Resources */ = {{")
emit("\t\t\tisa = PBXResourcesBuildPhase;")
emit("\t\t\tbuildActionMask = 2147483647;")
emit("\t\t\tfiles = (")
for f in resource_build_files:
    emit(f"\t\t\t\t{f.build_file_id} /* {f.name} in Resources */,")
emit("\t\t\t);")
emit("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
emit("\t\t};")
emit("/* End PBXResourcesBuildPhase section */")

# ---------------------------------------------------------------------------
# PBXSourcesBuildPhase
# ---------------------------------------------------------------------------
emit()
emit("/* Begin PBXSourcesBuildPhase section */")
emit(f"\t\t{sources_phase_id} /* Sources */ = {{")
emit("\t\t\tisa = PBXSourcesBuildPhase;")
emit("\t\t\tbuildActionMask = 2147483647;")
emit("\t\t\tfiles = (")
for f in sources_build_files:
    emit(f"\t\t\t\t{f.build_file_id} /* {f.name} in Sources */,")
emit("\t\t\t);")
emit("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
emit("\t\t};")
emit("/* End PBXSourcesBuildPhase section */")

# ---------------------------------------------------------------------------
# XCBuildConfiguration
# ---------------------------------------------------------------------------
COMMON_DEBUG = """\
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = %(deployment_target)s;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 6.0;
""" % {"deployment_target": DEPLOYMENT_TARGET}

COMMON_RELEASE = """\
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = %(deployment_target)s;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tVALIDATE_PRODUCT = YES;
""" % {"deployment_target": DEPLOYMENT_TARGET}

TARGET_COMMON = """\
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = PricePulse/Resources/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = %(bundle_id)s;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
""" % {"bundle_id": BUNDLE_ID}

emit()
emit("/* Begin XCBuildConfiguration section */")

emit(f"\t\t{project_debug_config_id} /* Debug */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(COMMON_DEBUG.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Debug;")
emit("\t\t};")

emit(f"\t\t{project_release_config_id} /* Release */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(COMMON_RELEASE.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Release;")
emit("\t\t};")

emit(f"\t\t{target_debug_config_id} /* Debug */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(TARGET_COMMON.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Debug;")
emit("\t\t};")

emit(f"\t\t{target_release_config_id} /* Release */ = {{")
emit("\t\t\tisa = XCBuildConfiguration;")
emit("\t\t\tbuildSettings = {")
emit(TARGET_COMMON.rstrip("\n"))
emit("\t\t\t};")
emit("\t\t\tname = Release;")
emit("\t\t};")

emit("/* End XCBuildConfiguration section */")

# ---------------------------------------------------------------------------
# XCConfigurationList
# ---------------------------------------------------------------------------
emit()
emit("/* Begin XCConfigurationList section */")
emit(f"\t\t{project_build_config_list_id} /* Build configuration list for PBXProject \"{PROJECT_NAME}\" */ = {{")
emit("\t\t\tisa = XCConfigurationList;")
emit("\t\t\tbuildConfigurations = (")
emit(f"\t\t\t\t{project_debug_config_id} /* Debug */,")
emit(f"\t\t\t\t{project_release_config_id} /* Release */,")
emit("\t\t\t);")
emit("\t\t\tdefaultConfigurationIsVisible = 0;")
emit("\t\t\tdefaultConfigurationName = Release;")
emit("\t\t};")
emit(f"\t\t{target_build_config_list_id} /* Build configuration list for PBXNativeTarget \"{PROJECT_NAME}\" */ = {{")
emit("\t\t\tisa = XCConfigurationList;")
emit("\t\t\tbuildConfigurations = (")
emit(f"\t\t\t\t{target_debug_config_id} /* Debug */,")
emit(f"\t\t\t\t{target_release_config_id} /* Release */,")
emit("\t\t\t);")
emit("\t\t\tdefaultConfigurationIsVisible = 0;")
emit("\t\t\tdefaultConfigurationName = Release;")
emit("\t\t};")
emit("/* End XCConfigurationList section */")

# ---------------------------------------------------------------------------
# XCRemoteSwiftPackageReference / XCSwiftPackageProductDependency
# ---------------------------------------------------------------------------
emit()
emit("/* Begin XCRemoteSwiftPackageReference section */")
emit(f"\t\t{package_ref_id} /* XCRemoteSwiftPackageReference \"SwiftSoup\" */ = {{")
emit("\t\t\tisa = XCRemoteSwiftPackageReference;")
emit("\t\t\trepositoryURL = \"https://github.com/scinfu/SwiftSoup.git\";")
emit("\t\t\trequirement = {")
emit("\t\t\t\tkind = upToNextMajorVersion;")
emit("\t\t\t\tminimumVersion = 2.7.0;")
emit("\t\t\t};")
emit("\t\t};")
emit("/* End XCRemoteSwiftPackageReference section */")

emit()
emit("/* Begin XCSwiftPackageProductDependency section */")
emit(f"\t\t{package_product_id} /* SwiftSoup */ = {{")
emit("\t\t\tisa = XCSwiftPackageProductDependency;")
emit(f"\t\t\tpackage = {package_ref_id} /* XCRemoteSwiftPackageReference \"SwiftSoup\" */;")
emit("\t\t\tproductName = SwiftSoup;")
emit("\t\t};")
emit("/* End XCSwiftPackageProductDependency section */")

# ---------------------------------------------------------------------------
emit("\t};")
emit(f"\trootObject = {project_id} /* Project object */;")
emit("}")
emit()

output_path = os.path.join(ROOT, f"{PROJECT_NAME}.xcodeproj", "project.pbxproj")
with open(output_path, "w") as fh:
    fh.write("\n".join(lines))

print(f"Wrote {output_path}")
print(f"Sources: {len(sources_build_files)}  Resources: {len(resource_build_files)}  Total file refs: {len(all_file_refs)}")
