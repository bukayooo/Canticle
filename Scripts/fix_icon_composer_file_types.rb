#!/usr/bin/env ruby
# Run this after every `xcodegen generate`. XcodeGen 2.43.0 predates Xcode's Icon
# Composer feature, so it has no extension mapping for `.icon` bundles - the
# `type: folder` override in project.yml's `sources:` entries for Icon1.icon...
# Icon8.icon makes XcodeGen fall back to the generic `lastKnownFileType = folder`,
# not the `folder.iconcomposer.icon` UTI. Without the specific UTI, actool can't
# recognize the bundles as app-icon sources and the build fails with "None of the
# input catalogs contained a matching ... app icon set ... named Icon1." This
# script patches the UTI back after each regenerate. Idempotent - safe to re-run.
require "xcodeproj"

project_path = File.join(__dir__, "..", "Canticle", "Canticle.xcodeproj")
project = Xcodeproj::Project.open(project_path)

fixed = 0
(1..8).each do |n|
  name = "Icon#{n}.icon"
  ref = project.files.find { |f| f.display_name == name }
  raise "#{name} file reference not found - did the icon file get renamed or removed?" unless ref
  ref.set_last_known_file_type("folder.iconcomposer.icon")
  fixed += 1
end

project.save
puts "Patched lastKnownFileType on #{fixed} icon file references."
