#!/usr/bin/env python3
"""Generates a minimal but complete StartupApp.xcodeproj"""

import os, uuid, plistlib

def uid():
    return uuid.uuid4().hex[:24].upper()

# ── File UUIDs ──────────────────────────────────────────────────────────────
IDS = {
    "proj":           uid(),
    "main_group":     uid(),
    "sources_group":  uid(),
    "views_group":    uid(),
    "vm_group":       uid(),
    "res_group":      uid(),
    "products_group": uid(),
    "target":         uid(),
    "config_list_proj": uid(),
    "config_list_tgt":  uid(),
    "debug_proj":     uid(),
    "release_proj":   uid(),
    "debug_tgt":      uid(),
    "release_tgt":    uid(),
    "sources_phase":  uid(),
    "resources_phase": uid(),
    "frameworks_phase": uid(),
    # file refs
    "StartupApp_swift":      uid(),
    "ContentView_swift":     uid(),
    "AuthViewModel_swift":   uid(),
    "OnboardingView_swift":  uid(),
    "SignInView_swift":      uid(),
    "MainTabView_swift":     uid(),
    "ProfileView_swift":     uid(),
    "ColorExtension_swift":       uid(),
    "GoogleSignInManager_swift":  uid(),
    "Info_plist":                 uid(),
    "app_product":                uid(),
    # build file refs
    "bf_StartupApp":              uid(),
    "bf_ContentView":             uid(),
    "bf_AuthViewModel":           uid(),
    "bf_OnboardingView":          uid(),
    "bf_SignInView":               uid(),
    "bf_MainTabView":              uid(),
    "bf_ProfileView":              uid(),
    "bf_ColorExtension":           uid(),
    "bf_GoogleSignInManager":      uid(),
    "bf_InfoPlist":                uid(),
}

SOURCE_FILES = [
    ("StartupApp_swift",     "StartupApp/StartupApp.swift",                 "bf_StartupApp"),
    ("ContentView_swift",    "StartupApp/ContentView.swift",                "bf_ContentView"),
    ("AuthViewModel_swift",  "StartupApp/ViewModels/AuthViewModel.swift",   "bf_AuthViewModel"),
    ("OnboardingView_swift", "StartupApp/Views/OnboardingView.swift",       "bf_OnboardingView"),
    ("SignInView_swift",     "StartupApp/Views/SignInView.swift",           "bf_SignInView"),
    ("MainTabView_swift",    "StartupApp/Views/MainTabView.swift",          "bf_MainTabView"),
    ("ProfileView_swift",    "StartupApp/Views/ProfileView.swift",          "bf_ProfileView"),
    ("ColorExtension_swift",      "StartupApp/Resources/ColorExtension.swift",          "bf_ColorExtension"),
    ("GoogleSignInManager_swift", "StartupApp/Managers/GoogleSignInManager.swift",       "bf_GoogleSignInManager"),
]

def pbxproj():
    lines = ['// !$*UTF8*$!', '{', '\tarchiveVersion = 1;', '\tclasses = {', '\t};',
             '\tobjectVersion = 56;', '\tobjects = {', '']

    def section(name): lines.extend([f'\n/* Begin {name} section */', ''])
    def end_section(name): lines.extend(['', f'/* End {name} section */', ''])

    # ── PBXBuildFile ──────────────────────────────────────────────────────
    section("PBXBuildFile")
    for ref_key, path, bf_key in SOURCE_FILES:
        name = os.path.basename(path)
        lines.append(f'\t\t{IDS[bf_key]} /* {name} in Sources */ = '
                     f'{{isa = PBXBuildFile; fileRef = {IDS[ref_key]} /* {name} */; }};')
    end_section("PBXBuildFile")

    # ── PBXFileReference ─────────────────────────────────────────────────
    section("PBXFileReference")
    for ref_key, path, _ in SOURCE_FILES:
        name = os.path.basename(path)
        lines.append(f'\t\t{IDS[ref_key]} /* {name} */ = '
                     f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
                     f'name = "{name}"; path = "{path}"; sourceTree = SOURCE_ROOT; }};')
    lines.append(f'\t\t{IDS["Info_plist"]} /* Info.plist */ = '
                 f'{{isa = PBXFileReference; lastKnownFileType = text.plist.xml; '
                 f'name = "Info.plist"; path = "StartupApp/Info.plist"; sourceTree = SOURCE_ROOT; }};')
    lines.append(f'\t\t{IDS["app_product"]} /* StartupApp.app */ = '
                 f'{{isa = PBXFileReference; explicitFileType = wrapper.application; '
                 f'includeInIndex = 0; path = StartupApp.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    end_section("PBXFileReference")

    # ── PBXFrameworksBuildPhase ───────────────────────────────────────────
    section("PBXFrameworksBuildPhase")
    lines += [
        f'\t\t{IDS["frameworks_phase"]} /* Frameworks */ = {{',
        f'\t\t\tisa = PBXFrameworksBuildPhase;',
        f'\t\t\tbuildActionMask = 2147483647;',
        f'\t\t\tfiles = (',
        f'\t\t\t);',
        f'\t\t\trunOnlyForDeploymentPostprocessing = 0;',
        f'\t\t}};',
    ]
    end_section("PBXFrameworksBuildPhase")

    # ── PBXGroup ──────────────────────────────────────────────────────────
    section("PBXGroup")

    # main group
    lines += [
        f'\t\t{IDS["main_group"]} = {{',
        '\t\t\tisa = PBXGroup;',
        '\t\t\tchildren = (',
        f'\t\t\t\t{IDS["sources_group"]} /* StartupApp */,',
        f'\t\t\t\t{IDS["products_group"]} /* Products */,',
        '\t\t\t);',
        '\t\t\tsourceTree = "<group>";',
        '\t\t};',
    ]

    # sources group
    lines += [
        f'\t\t{IDS["sources_group"]} /* StartupApp */ = {{',
        '\t\t\tisa = PBXGroup;',
        '\t\t\tchildren = (',
        f'\t\t\t\t{IDS["StartupApp_swift"]} /* StartupApp.swift */,',
        f'\t\t\t\t{IDS["ContentView_swift"]} /* ContentView.swift */,',
        f'\t\t\t\t{IDS["views_group"]} /* Views */,',
        f'\t\t\t\t{IDS["vm_group"]} /* ViewModels */,',
        f'\t\t\t\t{IDS["res_group"]} /* Resources */,',
        f'\t\t\t\t{IDS["Info_plist"]} /* Info.plist */,',
        '\t\t\t);',
        '\t\t\tname = StartupApp;',
        '\t\t\tsourceTree = "<group>";',
        '\t\t};',
    ]

    # views group
    view_files = ["OnboardingView_swift", "SignInView_swift", "MainTabView_swift", "ProfileView_swift"]
    view_names = ["OnboardingView.swift", "SignInView.swift", "MainTabView.swift", "ProfileView.swift"]
    lines += [f'\t\t{IDS["views_group"]} /* Views */ = {{', '\t\t\tisa = PBXGroup;', '\t\t\tchildren = (']
    for k, n in zip(view_files, view_names):
        lines.append(f'\t\t\t\t{IDS[k]} /* {n} */,')
    lines += ['\t\t\t);', '\t\t\tname = Views;', '\t\t\tsourceTree = "<group>";', '\t\t};']

    # viewmodels group
    lines += [
        f'\t\t{IDS["vm_group"]} /* ViewModels */ = {{',
        '\t\t\tisa = PBXGroup;',
        '\t\t\tchildren = (',
        f'\t\t\t\t{IDS["AuthViewModel_swift"]} /* AuthViewModel.swift */,',
        '\t\t\t);',
        '\t\t\tname = ViewModels;',
        '\t\t\tsourceTree = "<group>";',
        '\t\t};',
    ]

    # resources group
    lines += [
        f'\t\t{IDS["res_group"]} /* Resources */ = {{',
        '\t\t\tisa = PBXGroup;',
        '\t\t\tchildren = (',
        f'\t\t\t\t{IDS["ColorExtension_swift"]} /* ColorExtension.swift */,',
        f'\t\t\t\t{IDS["GoogleSignInManager_swift"]} /* GoogleSignInManager.swift */,',
        '\t\t\t);',
        '\t\t\tname = Resources;',
        '\t\t\tsourceTree = "<group>";',
        '\t\t};',
    ]

    # products group
    lines += [
        f'\t\t{IDS["products_group"]} /* Products */ = {{',
        '\t\t\tisa = PBXGroup;',
        '\t\t\tchildren = (',
        f'\t\t\t\t{IDS["app_product"]} /* StartupApp.app */,',
        '\t\t\t);',
        '\t\t\tname = Products;',
        '\t\t\tsourceTree = "<group>";',
        '\t\t};',
    ]
    end_section("PBXGroup")

    # ── PBXNativeTarget ───────────────────────────────────────────────────
    section("PBXNativeTarget")
    lines += [
        f'\t\t{IDS["target"]} /* StartupApp */ = {{',
        '\t\t\tisa = PBXNativeTarget;',
        f'\t\t\tbuildConfigurationList = {IDS["config_list_tgt"]} /* Build configuration list for PBXNativeTarget "StartupApp" */;',
        '\t\t\tbuildPhases = (',
        f'\t\t\t\t{IDS["sources_phase"]} /* Sources */,',
        f'\t\t\t\t{IDS["frameworks_phase"]} /* Frameworks */,',
        f'\t\t\t\t{IDS["resources_phase"]} /* Resources */,',
        '\t\t\t);',
        '\t\t\tbuildRules = (',
        '\t\t\t);',
        '\t\t\tdependencies = (',
        '\t\t\t);',
        '\t\t\tname = StartupApp;',
        '\t\t\tpackageProductDependencies = (',
        '\t\t\t);',
        f'\t\t\tproductFileReference = {IDS["app_product"]} /* StartupApp.app */;',
        '\t\t\tproductName = StartupApp;',
        '\t\t\tproductType = "com.apple.product-type.application";',
        '\t\t};',
    ]
    end_section("PBXNativeTarget")

    # ── PBXProject ────────────────────────────────────────────────────────
    section("PBXProject")
    lines += [
        f'\t\t{IDS["proj"]} /* Project object */ = {{',
        '\t\t\tisa = PBXProject;',
        '\t\t\tattributes = {',
        '\t\t\t\tBuildIndependentTargetsInParallel = 1;',
        '\t\t\t\tLastSwiftUpdateCheck = 1600;',
        '\t\t\t\tLastUpgradeCheck = 1600;',
        '\t\t\t\tTargetAttributes = {',
        f'\t\t\t\t\t{IDS["target"]} = {{',
        '\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;',
        '\t\t\t\t\t};',
        '\t\t\t\t};',
        '\t\t\t};',
        f'\t\t\tbuildConfigurationList = {IDS["config_list_proj"]} /* Build configuration list for PBXProject "StartupApp" */;',
        '\t\t\tcompatibilityVersion = "Xcode 14.0";',
        '\t\t\tdevelopmentRegion = en;',
        '\t\t\thasScannedForEncodings = 0;',
        '\t\t\tknownRegions = (en, Base);',
        f'\t\t\tmainGroup = {IDS["main_group"]};',
        f'\t\t\tproductRefGroup = {IDS["products_group"]} /* Products */;',
        '\t\t\tprojectDirPath = "";',
        '\t\t\tprojectRoot = "";',
        '\t\t\ttargets = (',
        f'\t\t\t\t{IDS["target"]} /* StartupApp */,',
        '\t\t\t);',
        '\t\t};',
    ]
    end_section("PBXProject")

    # ── PBXResourcesBuildPhase ────────────────────────────────────────────
    section("PBXResourcesBuildPhase")
    lines += [
        f'\t\t{IDS["resources_phase"]} /* Resources */ = {{',
        '\t\t\tisa = PBXResourcesBuildPhase;',
        '\t\t\tbuildActionMask = 2147483647;',
        '\t\t\tfiles = (',
        '\t\t\t);',
        '\t\t\trunOnlyForDeploymentPostprocessing = 0;',
        '\t\t};',
    ]
    end_section("PBXResourcesBuildPhase")

    # ── PBXSourcesBuildPhase ──────────────────────────────────────────────
    section("PBXSourcesBuildPhase")
    lines += [
        f'\t\t{IDS["sources_phase"]} /* Sources */ = {{',
        '\t\t\tisa = PBXSourcesBuildPhase;',
        '\t\t\tbuildActionMask = 2147483647;',
        '\t\t\tfiles = (',
    ]
    for ref_key, path, bf_key in SOURCE_FILES:
        name = os.path.basename(path)
        lines.append(f'\t\t\t\t{IDS[bf_key]} /* {name} in Sources */,')
    lines += ['\t\t\t);', '\t\t\trunOnlyForDeploymentPostprocessing = 0;', '\t\t};']
    end_section("PBXSourcesBuildPhase")

    # ── XCBuildConfiguration ──────────────────────────────────────────────
    section("XCBuildConfiguration")

    common_proj = [
        'ALWAYS_SEARCH_USER_PATHS = NO',
        'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES',
        'CLANG_ANALYZER_NONNULL = YES',
        'CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE',
        'CLANG_CXX_LANGUAGE_STANDARD = "gnu++20"',
        'CLANG_ENABLE_MODULES = YES',
        'CLANG_ENABLE_OBJC_ARC = YES',
        'CLANG_ENABLE_OBJC_WEAK = YES',
        'CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES',
        'CLANG_WARN_BOOL_CONVERSION = YES',
        'CLANG_WARN_COMMA = YES',
        'CLANG_WARN_CONSTANT_CONVERSION = YES',
        'CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES',
        'CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR',
        'CLANG_WARN_DOCUMENTATION_COMMENTS = YES',
        'CLANG_WARN_EMPTY_BODY = YES',
        'CLANG_WARN_ENUM_CONVERSION = YES',
        'CLANG_WARN_INFINITE_RECURSION = YES',
        'CLANG_WARN_INT_CONVERSION = YES',
        'CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES',
        'CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES',
        'CLANG_WARN_OBJC_LITERAL_CONVERSION = YES',
        'CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR',
        'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES',
        'CLANG_WARN_RANGE_LOOP_ANALYSIS = YES',
        'CLANG_WARN_STRICT_PROTOTYPES = YES',
        'CLANG_WARN_SUSPICIOUS_MOVE = YES',
        'CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE',
        'CLANG_WARN_UNREACHABLE_CODE = YES',
        'CLANG_WARN__DUPLICATE_METHOD_MATCH = YES',
        'COPY_PHASE_STRIP = NO',
        'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"',
        'ENABLE_STRICT_OBJC_MSGSEND = YES',
        'ENABLE_TESTABILITY = YES',
        'GCC_C_LANGUAGE_STANDARD = gnu17',
        'GCC_NO_COMMON_BLOCKS = YES',
        'GCC_WARN_64_TO_32_BIT_CONVERSION = YES',
        'GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR',
        'GCC_WARN_UNDECLARED_SELECTOR = YES',
        'GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE',
        'GCC_WARN_UNUSED_FUNCTION = YES',
        'GCC_WARN_UNUSED_VARIABLE = YES',
        'IPHONEOS_DEPLOYMENT_TARGET = 17.0',
        'LOCALIZATION_PREFERS_STRING_CATALOGS = YES',
        'MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE',
        'MTL_FAST_MATH = YES',
        'ONLY_ACTIVE_ARCH = YES',
        'SDKROOT = iphoneos',
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG AI"',
        'SWIFT_OPTIMIZATION_LEVEL = "-Onone"',
    ]

    # Debug proj
    lines += [f'\t\t{IDS["debug_proj"]} /* Debug */ = {{', '\t\t\tisa = XCBuildConfiguration;',
              '\t\t\tbuildSettings = {']
    for s in common_proj:
        lines.append(f'\t\t\t\t{s};')
    lines += ['\t\t\t};', '\t\t\tname = Debug;', '\t\t};']

    # Release proj
    release_overrides = [
        'COPY_PHASE_STRIP = YES',
        'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"',
        'ENABLE_NS_ASSERTIONS = NO',
        'MTL_ENABLE_DEBUG_INFO = NO',
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS = ""',
        'SWIFT_OPTIMIZATION_LEVEL = "-Owholemodule"',
        'VALIDATE_PRODUCT = YES',
    ]
    release_proj = [s for s in common_proj if not any(s.startswith(r.split(' = ')[0]) for r in release_overrides)]
    release_proj += release_overrides

    lines += [f'\t\t{IDS["release_proj"]} /* Release */ = {{', '\t\t\tisa = XCBuildConfiguration;',
              '\t\t\tbuildSettings = {']
    for s in release_proj:
        lines.append(f'\t\t\t\t{s};')
    lines += ['\t\t\t};', '\t\t\tname = Release;', '\t\t};']

    # Debug target
    tgt_settings = [
        'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon',
        'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor',
        'CODE_SIGN_STYLE = Automatic',
        'CURRENT_PROJECT_VERSION = 1',
        'DEVELOPMENT_ASSET_PATHS = ""',
        'ENABLE_PREVIEWS = YES',
        'GENERATE_INFOPLIST_FILE = NO',
        'INFOPLIST_FILE = StartupApp/Info.plist',
        'IPHONEOS_DEPLOYMENT_TARGET = 17.0',
        'LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks"',
        'MARKETING_VERSION = 1.0',
        'PRODUCT_BUNDLE_IDENTIFIER = "com.yourcompany.startupapp"',
        'PRODUCT_NAME = "$(TARGET_NAME)"',
        'SWIFT_EMIT_LOC_STRINGS = YES',
        'SWIFT_VERSION = 5.0',
        'TARGETED_DEVICE_FAMILY = "1,2"',
    ]
    lines += [f'\t\t{IDS["debug_tgt"]} /* Debug */ = {{', '\t\t\tisa = XCBuildConfiguration;',
              '\t\t\tbuildSettings = {']
    for s in tgt_settings:
        lines.append(f'\t\t\t\t{s};')
    lines += ['\t\t\t};', '\t\t\tname = Debug;', '\t\t};']

    lines += [f'\t\t{IDS["release_tgt"]} /* Release */ = {{', '\t\t\tisa = XCBuildConfiguration;',
              '\t\t\tbuildSettings = {']
    for s in tgt_settings:
        lines.append(f'\t\t\t\t{s};')
    lines += ['\t\t\t};', '\t\t\tname = Release;', '\t\t};']

    end_section("XCBuildConfiguration")

    # ── XCConfigurationList ───────────────────────────────────────────────
    section("XCConfigurationList")
    lines += [
        f'\t\t{IDS["config_list_proj"]} /* Build configuration list for PBXProject "StartupApp" */ = {{',
        '\t\t\tisa = XCConfigurationList;',
        '\t\t\tbuildConfigurations = (',
        f'\t\t\t\t{IDS["debug_proj"]} /* Debug */,',
        f'\t\t\t\t{IDS["release_proj"]} /* Release */,',
        '\t\t\t);',
        '\t\t\tdefaultConfigurationIsVisible = 0;',
        '\t\t\tdefaultConfigurationName = Release;',
        '\t\t};',
        f'\t\t{IDS["config_list_tgt"]} /* Build configuration list for PBXNativeTarget "StartupApp" */ = {{',
        '\t\t\tisa = XCConfigurationList;',
        '\t\t\tbuildConfigurations = (',
        f'\t\t\t\t{IDS["debug_tgt"]} /* Debug */,',
        f'\t\t\t\t{IDS["release_tgt"]} /* Release */,',
        '\t\t\t);',
        '\t\t\tdefaultConfigurationIsVisible = 0;',
        '\t\t\tdefaultConfigurationName = Release;',
        '\t\t};',
    ]
    end_section("XCConfigurationList")

    lines += ['\t};', f'\trootObject = {IDS["proj"]} /* Project object */;', '}']
    return '\n'.join(lines)


# ── Write files ──────────────────────────────────────────────────────────────
proj_dir = os.path.join(os.path.dirname(__file__), "StartupApp.xcodeproj")
os.makedirs(proj_dir, exist_ok=True)

pbxproj_path = os.path.join(proj_dir, "project.pbxproj")
with open(pbxproj_path, "w") as f:
    f.write(pbxproj())

# workspace data
ws_dir = os.path.join(proj_dir, "project.xcworkspace")
os.makedirs(ws_dir, exist_ok=True)
with open(os.path.join(ws_dir, "contents.xcworkspacedata"), "w") as f:
    f.write("""<?xml version="1.0" encoding="UTF-8"?>
<Workspace version = "1.0">
   <FileRef location = "self:">
   </FileRef>
</Workspace>
""")

print(f"✅  Generated: {proj_dir}")
print("   Open in Xcode with:")
print(f"   open StartupApp.xcodeproj")
