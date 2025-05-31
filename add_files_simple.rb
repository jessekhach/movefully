#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'Movefully.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Movefully' }

# Get files from command line arguments
files_to_add = ARGV

if files_to_add.empty?
  puts "❌ No files provided to add"
  exit 1
end

files_to_add.each do |file_path|
  # Extract the directory structure to find the right group
  path_parts = file_path.split('/')
  
  # Find or create the appropriate group
  current_group = project.main_group.find_subpath('Movefully')
  
  # Navigate through the directory structure (skip 'Movefully' since we already have that)
  if path_parts.length > 2
    path_parts[1..-2].each do |part|
      subgroup = current_group.find_subpath(part)
      if subgroup.nil?
        subgroup = current_group.new_group(part)
      end
      current_group = subgroup
    end
  end
  
  # Get just the filename
  filename = path_parts.last
  
  # Check if file already exists in the project
  existing_file = current_group.files.find { |f| f.display_name == filename }
  if existing_file
    puts "⚠️  File #{filename} already exists in project, skipping"
    next
  end
  
  # Add file reference with just the filename (not full path)
  file_ref = current_group.new_reference(filename)
  
  # Add to target
  target.add_file_references([file_ref])
  
  puts "✅ Added #{filename} to project"
end

# Save the project
project.save

puts "✅ Added new view files to Xcode project successfully!" 