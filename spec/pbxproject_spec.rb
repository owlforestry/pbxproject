require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "initialization" do
  it "should fail while initializing with non-existing file" do
    lambda{PBXProject.new :file => 'nonsense'}.should raise_error
  end
  
  it "should have ready state when initializing done" do
    pbx = PBXProject.new :file => 'examples/project.pbxproj'
    pbx.state.should == :ready
  end
end

describe "parsing" do
  before :each do
    @pbx = PBXProject.new :file => 'examples/project.pbxproj'
  end
  
  it "should be succesful" do
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
    @pbx = PBXProject.new :file => 'examples/project.pbxproj'
    @pbx.parse
  end
  
  it "native target" do
    target = @pbx.find_item :name => 'Foo', :type => PBXTypes::PBXNativeTarget
    target.name.value.should eql 'Foo'
  end
end