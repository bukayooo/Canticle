#!/usr/bin/env ruby
# One-off: registers Canticle/Canticle/Resources/BibleOriginal as a single
# Xcode "folder reference" (a blue folder, not a yellow group), which Xcode
# copies into the bundle as a real nested subdirectory during Copy Bundle
# Resources. This matters because the existing Resources/Bible group is a
# plain PBXGroup with each file listed individually - Xcode flattens those to
# the bundle root (hence BibleStore's fallback lookup with no subdirectory).
# BibleOriginal's files share the same basenames as Bible's (genesis.json,
# matthew.json, ...), so registering it the same way collides at the bundle
# root ("Multiple commands produce .../genesis.json"). A folder reference
# avoids that by keeping BibleOriginal/*.json nested under BibleOriginal/ in
# the compiled bundle, matching BibleStore's `subdirectory: "BibleOriginal"`
# lookup.
require "xcodeproj"

project_path = File.join(__dir__, "..", "Canticle", "Canticle.xcodeproj")
project = Xcodeproj::Project.open(project_path)

resources_group = project.main_group.find_subpath("Canticle/Resources", false)
raise "Resources group not found" unless resources_group

if resources_group.children.any? { |c| c.display_name == "BibleOriginal" }
  raise "A BibleOriginal reference already exists - aborting to avoid duplicates"
end

target = project.targets.find { |t| t.name == "Canticle" }
raise "Canticle target not found" unless target

folder_ref = resources_group.new_reference("BibleOriginal")
folder_ref.name = nil # let Xcode display it by its path, consistent with sibling groups
folder_ref.set_last_known_file_type("folder")
folder_ref.source_tree = "<group>"
target.resources_build_phase.add_file_reference(folder_ref)

project.save
puts "Added Resources/BibleOriginal as a folder reference on the Canticle target."
