require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "initialization" do
  it "should fail while initializing with non-existing file" do
    lambda{PBXProject::PBXProject.new :file => 'nonsense'}.should raise_error
  end
  
  it "should have ready state when initializing done" do
    pbx = PBXProject::PBXProject.new :file => 'examples/project.pbxproj'
    pbx.state.should == :ready
  end
end

describe "parsing" do
  before :each do
    @pbx = PBXProject::PBXProject.new :file => 'examples/project.pbxproj'
  end
  
  it "should be successful" do
    @pbx.parse.should eql true
  end
  
  it "should return all required sections" do
    @pbx.parse.should eql true
    @pbx.sections.keys.should eql ["PBXBuildFile", "PBXFileReference", "PBXFrameworksBuildPhase",
      "PBXGroup", "PBXNativeTarget", "PBXProject", "PBXResourcesBuildPhase",
      "PBXShellScriptBuildPhase", "PBXSourcesBuildPhase", "PBXVariantGroup",
      "XCBuildConfiguration", "XCConfigurationList"]
  end
end

describe "finding" do
  before :each do
    @pbx = PBXProject::PBXProject.new :file => 'examples/project.pbxproj'
    @pbx.parse
  end
  
  it "target 'Foo'" do
    target = @pbx.find_item :name => 'Foo', :type => PBXProject::PBXTypes::PBXNativeTarget
    target.name.value.should eql 'Foo'
  end
  
  it "group 'iPhone'" do
    group = @pbx.find_item :name => 'iPhone', :type => PBXProject::PBXTypes::PBXGroup
    group.guid.should eql 'C0D293B4135FD66F001979A0'
    group.name.value.should eql 'iPhone'
  end
  
  it "shellScript" do
    script = @pbx.find_item :guid => 'C0D293C7135FD6D7001979A0', :type => PBXProject::PBXTypes::PBXShellScriptBuildPhase
    script.shellScript.value.should eql '"rake build:prepare"'
  end
end

describe "adding" do
  before :each do
    @pbx = PBXProject::PBXProject.new :file => 'examples/project.pbxproj'
    @pbx.parse
  end

  it "shellScript" do
    # Create shellScript
    shellScript = PBXProject::PBXTypes::PBXShellScriptBuildPhase.new :shellPath => "/bin/sh",
      :shellScript => '"(cd $PROJECT_DIR; rake build:prepare)"'
    
    @pbx.add_item(shellScript).should eql shellScript.guid
  end
  
  it "shellScript to target 'Foo'" do
    # Create shellScript
    shellScript = PBXProject::PBXTypes::PBXShellScriptBuildPhase.new :shellPath => "/bin/sh",
      :shellScript => '"(cd $PROJECT_DIR; rake build:prepare)"'
    
    @pbx.add_item(shellScript).should eql shellScript.guid
    
    # get our target
    target = @pbx.find_item :name => 'Foo', :type => PBXProject::PBXTypes::PBXNativeTarget
    target.name.value.should eql 'Foo'

    # and add it to target
    target.add_build_phase(shellScript)
    target.buildPhases.count.should be 5
  end
  
  it "source library to target 'Foo'" do
    # Add source files
    files = [['Action.m', 'lib/foo'], ['Action.h', 'lib/foo']]
    fileref = []
    
    files.each do |f|
      fileref.push PBXProject::PBXTypes::PBXFileReference.new(:name => f[0], :path => f[1], :sourceTree => '<group>')
      @pbx.add_item(fileref.last).should eql fileref.last.guid
    end
    
    buildfiles = []
    fileref.each do |f|
      # Add build files
      buildfiles.push PBXProject::PBXTypes::PBXBuildFile.new(:comment => f.name.value, :fileRef => f.guid)
      @pbx.add_item(buildfiles.last).should eql buildfiles.last.guid
      
      # Add fileref to group
      group = @pbx.find_item :comment => 'Foo', :type => PBXProject::PBXTypes::PBXGroup
      group.add_children(f)
    end
    
    @pbx.sections['PBXGroup'].each do |g|
      # puts g.to_pbx
    end
  end
end

describe "PBX format" do
  before :all do
    @expected = []
    File.open('examples/project.pbxproj', 'r').each_line do |line|
      @expected.push line
    end
  end
  
  before :each do
    @pbx = PBXProject::PBXProject.new :file => 'examples/project.pbxproj'
    @pbx.parse
  end
  
  it "PBXBuildFile" do
    @pbx.sections['PBXBuildFile'].first.to_pbx(2).should == @expected[9]
  end
  
  it "PBXFileReference" do
    @pbx.sections['PBXFileReference'].first.to_pbx(2).should == @expected[22]
  end
  
  it "PBXFrameworksBuildPhase" do
    pbx = @pbx.sections['PBXFrameworksBuildPhase'].first.to_pbx(2)
    pbx.should == @expected[41..50].join("")
  end
  
  it "PBXGroup" do
    pbx = @pbx.sections['PBXGroup'].first.to_pbx(2)
    pbx.should == @expected[54..62].join("")
  end
  
  it "PBXNativeTarget" do
    pbx = @pbx.sections['PBXNativeTarget'].first.to_pbx(2)
    pbx.should == @expected[127..144].join("")
  end
  
  it "PBXProject" do
    pbx = @pbx.sections['PBXProject'].first.to_pbx(2)
    pbx.should == @expected[148..167].join("")
  end
  
  it "PBXResourcesBuildPhase" do
    pbx = @pbx.sections['PBXResourcesBuildPhase'].first.to_pbx(2)
    pbx.should == @expected[171..180].join("")
  end
  
  it "PBXShellScriptBuildPhase" do
    pbx = @pbx.sections['PBXShellScriptBuildPhase'].first.to_pbx(2)
    pbx.should == @expected[184..197].join("")
  end
  
  it "PBXSourcesBuildPhase" do
    pbx = @pbx.sections['PBXSourcesBuildPhase'].first.to_pbx(2)
    pbx.should == @expected[201..211].join("")
  end
  
  it "PBXVariantGroup" do
    pbx = @pbx.sections['PBXVariantGroup'].first.to_pbx(2)
    pbx.should == @expected[215..222].join("")
  end
  
  it "XCBuildConfiguration" do
    pbx = @pbx.sections['XCBuildConfiguration'].first.to_pbx(2)
    pbx.should == @expected[242..268].join("")
  end
    
  it "XCConfigurationList" do
    pbx = @pbx.sections['XCConfigurationList'].first.to_pbx(2)
    pbx.should == @expected[316..324].join("")
  end
  
  it "PBXProject" do
    pbx = @pbx.to_pbx
    # pbx.should == @expected.join("")
  end
end

describe "save" do
  before :all do
    @expected = []
    File.open('examples/project.pbxproj', 'r').each_line do |line|
      @expected.push line.chomp!
    end
  end
  
  before :each do
    @pbx = PBXProject::PBXProject.new :file => 'examples/project.pbxproj'
    @pbx.parse
  end
  
  it "to file" do
    @pbx.write_to :file => 'examples/project.pbxproj.new'
    
    wrote = []
    File.open('examples/project.pbxproj.new', 'r').each_line do |line|
      wrote.push line.chomp!
    end
    
    wrote.should == @expected
  end
end