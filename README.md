pbxproject
==========

pbxproject offers more or less easy way to manage XCode 4 project files from ruby scripts.
By offering object-oriented approach to the file, adding custom build phases and/or files 
are as easy as creating new ruby objects.

Usage
-----

You can install PBXProject gem easy from your command line:

	$ gem install pbxproject

A top of your source file where you want to manage pbxproject files, you'll need to require `pbxproject` gem (obviously)

	require 'pbxproject'

After this using pbxproject files are as easy as managing ruby objects:

	# raises error if file is not found
	pbx = PBXProject::PBXProject.new :file => 'path/to/project.pbxproj'
	
	# parses project file
	pbx.parse
	
	# finds and returns named native target
	target = pbx.find_item :name => "MyGreatGame", :type => PBXProject::PBXTypes::PBXNativeTarget
	
	# create new shell script
	scrt = PBXProject::PBXTypes::PBXShellScriptBuildPhase :shellPath => '/bin/sh',
		:shellScript => "\"echo 'Hello world!' > foo.log\""
	
	# add it to target's build phase (by default to last item)
	target.add_build_phase scrt
	
	# save new project.pbxproj
	pbx.write_to :file => 'path/to/project.pbxproj'


Contributing to pbxproject
--------------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
---------

Copyright (c) 2011 Mikko Kokkonen. See LICENSE.txt for
further details.

