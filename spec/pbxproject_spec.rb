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
  
  it "target 'Foo'" do
    target = @pbx.find_item :name => 'Foo', :type => PBXTypes::PBXNativeTarget
    target.name.value.should eql 'Foo'
  end
  
  it "group 'iPhone'" do
    group = @pbx.find_item :name => 'iPhone', :type => PBXTypes::PBXGroup
    group.guid.should eql 'C0D293B4135FD66F001979A0'
    group.name.value.should eql 'iPhone'
  end
  
  it "shellScript" do
    script = @pbx.find_item :guid => 'C0D293C7135FD6D7001979A0', :type => PBXTypes::PBXShellScriptBuildPhase
    script.shellScript.value.should eql '"rake build:prepare"'
  end
end

describe "adding" do
  before :each do
    @pbx = PBXProject.new :file => 'examples/project.pbxproj'
    @pbx.parse
  end

  it "shellScript" do
    # Create shellScript
    shellScript = PBXTypes::PBXShellScriptBuildPhase.new :shellPath => "/bin/sh",
      :shellScript => '"(cd $PROJECT_DIR; rake build:prepare)"'
    
    @pbx.add_item(shellScript).should eql shellScript.guid
  end
  
  it "shellScript to target 'Foo'" do
    # Create shellScript
    shellScript = PBXTypes::PBXShellScriptBuildPhase.new :shellPath => "/bin/sh",
      :shellScript => '"(cd $PROJECT_DIR; rake build:prepare)"'
    
    @pbx.add_item(shellScript).should eql shellScript.guid
    
    # get our target
    target = @pbx.find_item :name => 'Foo', :type => PBXTypes::PBXNativeTarget
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
      fileref.push PBXTypes::PBXFileReference.new(:name => f[0], :path => f[1], :sourceTree => '<group>')
      @pbx.add_item(fileref.last).should eql fileref.last.guid
    end
    
    buildfiles = []
    fileref.each do |f|
      # Add build files
      buildfiles.push PBXTypes::PBXBuildFile.new(:comment => f.name.value, :fileRef => f.guid)
      @pbx.add_item(buildfiles.last).should eql buildfiles.last.guid
      
      # Add fileref to group
      group = @pbx.find_item :comment => 'Foo', :type => PBXTypes::PBXGroup
      group.add_children(f)
    end
    
    @pbx.sections['PBXGroup'].each do |g|
      # puts g.to_pbx
    end
  end
end

describe "PBX format" do
  before :each do
    @pbx = PBXProject.new :file => 'examples/project.pbxproj'
    @pbx.parse
  end
  
  it "PBXBuildFile" do
    @pbx.sections['PBXBuildFile'].first.to_pbx.should == 'C0D293A3135FD66E001979A0 /* UIKit.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = C0D293A2135FD66E001979A0 /* UIKit.framework */; };'
  end
  
  it "PBXFileReference" do
    @pbx.sections['PBXFileReference'].first.to_pbx.should == 'C0D2939E135FD66E001979A0 /* Foo.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Foo.app; sourceTree = BUILT_PRODUCTS_DIR; };'
  end
  
  it "PBXFrameworksBuildPhase" do
    pbx = @pbx.sections['PBXFrameworksBuildPhase'].first.to_pbx
    
    expected = 'C0D2939B135FD66E001979A0 /* Frameworks */ = {
	isa = PBXFrameworksBuildPhase;
	buildActionMask = 2147483647;
	files = (
		C0D293A3135FD66E001979A0 /* UIKit.framework in Frameworks */,
		C0D293A5135FD66E001979A0 /* Foundation.framework in Frameworks */,
		C0D293A7135FD66E001979A0 /* CoreGraphics.framework in Frameworks */,
	);
	runOnlyForDeploymentPostprocessing = 0;
};
'
  pbx.should == expected
  end
  
  it "PBXGroup" do
    pbx = @pbx.sections['PBXGroup'].first.to_pbx
    expected = 'C0D29393135FD66E001979A0 = {
	isa = PBXGroup;
	children = (
		C0D293A8135FD66E001979A0 /* Foo */,
		C0D293A1135FD66E001979A0 /* Frameworks */,
		C0D2939F135FD66E001979A0 /* Products */,
	);
	sourceTree = "<group>";
};
'
    pbx.should == expected
  end
  
  it "PBXNativeTarget" do
    pbx = @pbx.sections['PBXNativeTarget'].first.to_pbx
    
    expected = 'C0D2939D135FD66E001979A0 /* Foo */ = {
	isa = PBXNativeTarget;
	buildConfigurationList = C0D293C4135FD66F001979A0 /* Build configuration list for PBXNativeTarget "Foo" */;
	buildPhases = (
		C0D293C7135FD6D7001979A0 /* ShellScript */,
		C0D2939A135FD66E001979A0 /* Sources */,
		C0D2939B135FD66E001979A0 /* Frameworks */,
		C0D2939C135FD66E001979A0 /* Resources */,
	);
	buildRules = (
	);
	dependencies = (
	);
	name = Foo;
	productName = Foo;
	productReference = C0D2939E135FD66E001979A0 /* Foo.app */;
	productType = "com.apple.product-type.application";
};
'
    pbx.should == expected
  end
  
  it "PBXProject" do
    pbx = @pbx.sections['PBXProject'].first.to_pbx
    
    expected = 'C0D29395135FD66E001979A0 /* Project object */ = {
	isa = PBXProject;
	attributes = {
		ORGANIZATIONNAME = "Owl Forestry";
	};
	buildConfigurationList = C0D29398135FD66E001979A0 /* Build configuration list for PBXProject "Foo" */;
	compatibilityVersion = "Xcode 3.2";
	developmentRegion = English;
	hasScannedForEncodings = 0;
	knownRegions = (
		en,
	);
	mainGroup = C0D29393135FD66E001979A0;
	productRefGroup = C0D2939F135FD66E001979A0 /* Products */;
	projectDirPath = "";
	projectRoot = "";
	targets = (
		C0D2939D135FD66E001979A0 /* Foo */,
	);
};
'
    
    pbx.should == expected
  end
  
  it "PBXResourcesBuildPhase" do
    pbx = @pbx.sections['PBXResourcesBuildPhase'].first.to_pbx
    
    expected = 'C0D2939C135FD66E001979A0 /* Resources */ = {
	isa = PBXResourcesBuildPhase;
	buildActionMask = 2147483647;
	files = (
		C0D293AD135FD66E001979A0 /* InfoPlist.strings in Resources */,
		C0D293BA135FD66F001979A0 /* MainWindow_iPhone.xib in Resources */,
		C0D293C1135FD66F001979A0 /* MainWindow_iPad.xib in Resources */,
	);
	runOnlyForDeploymentPostprocessing = 0;
};
'
    
    pbx.should == expected
  end
  
  it "PBXShellScriptBuildPhase" do
    pbx = @pbx.sections['PBXShellScriptBuildPhase'].first.to_pbx
    
    expected = 'C0D293C7135FD6D7001979A0 /* ShellScript */ = {
	isa = PBXShellScriptBuildPhase;
	buildActionMask = 2147483647;
	files = (
	);
	inputPaths = (
	);
	outputPaths = (
	);
	runOnlyForDeploymentPostprocessing = 0;
	shellPath = /bin/sh;
	shellScript = "rake build:prepare";
	showEnvVarsInLog = 0;
};
'
    pbx.should == expected
  end
  
  it "PBXSourcesBuildPhase" do
    pbx = @pbx.sections['PBXSourcesBuildPhase'].first.to_pbx
    
    expected = 'C0D2939A135FD66E001979A0 /* Sources */ = {
	isa = PBXSourcesBuildPhase;
	buildActionMask = 2147483647;
	files = (
		C0D293B0135FD66E001979A0 /* main.m in Sources */,
		C0D293B3135FD66E001979A0 /* FooAppDelegate.m in Sources */,
		C0D293B7135FD66F001979A0 /* FooAppDelegate_iPhone.m in Sources */,
		C0D293BE135FD66F001979A0 /* FooAppDelegate_iPad.m in Sources */,
	);
	runOnlyForDeploymentPostprocessing = 0;
};
'
    pbx.should == expected
  end
  
  it "PBXVariantGroup" do
    pbx = @pbx.sections['PBXVariantGroup'].first.to_pbx
    expected = 'C0D293AB135FD66E001979A0 /* InfoPlist.strings */ = {
	isa = PBXVariantGroup;
	children = (
		C0D293AC135FD66E001979A0 /* en */,
	);
	name = InfoPlist.strings;
	sourceTree = "<group>";
};
'
    pbx.should == expected
  end
  
  it "XCBuildConfiguration" do
    pbx = @pbx.sections['XCBuildConfiguration'].first.to_pbx
    expected = 'C0D293C2135FD66F001979A0 /* Debug */ = {
	isa = XCBuildConfiguration;
	buildSettings = {
		ARCHS = "$(ARCHS_STANDARD_32_BIT)";
		"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";
		GCC_C_LANGUAGE_STANDARD = gnu99;
		GCC_OPTIMIZATION_LEVEL = 0;
		GCC_PREPROCESSOR_DEFINITIONS = DEBUG;
		GCC_SYMBOLS_PRIVATE_EXTERN = NO;
		GCC_VERSION = com.apple.compilers.llvmgcc42;
		GCC_WARN_ABOUT_RETURN_TYPE = YES;
		GCC_WARN_UNUSED_VARIABLE = YES;
		IPHONEOS_DEPLOYMENT_TARGET = 4.3;
		LIBRARY_SEARCH_PATHS = (
			"$(inherited)",
			"\"$(SRCROOT)\"",
			"\"$(SRCROOT)/iOS/Ads\"",
			"\"$(SRCROOT)/iOS/Ads/Google AdMob\"",
			"\"$(SRCROOT)/iOS/Ads/Greystripe\"",
			"\"$(SRCROOT)/iOS/libs/FlurryLib\"",
			"\"$(SRCROOT)/iOS/Ads/InMobi iOS SDK Bundle\"",
		);
		SDKROOT = iphoneos;
		TARGETED_DEVICE_FAMILY = "1,2";
	};
	name = Debug;
};
'
    pbx.should == expected
  end
    
  it "XCConfigurationList" do
    pbx = @pbx.sections['XCConfigurationList'].first.to_pbx
    expected = 'C0D29398135FD66E001979A0 /* Build configuration list for PBXProject "Foo" */ = {
	isa = XCConfigurationList;
	buildConfigurations = (
		C0D293C2135FD66F001979A0 /* Debug */,
		C0D293C3135FD66F001979A0 /* Release */,
	);
	defaultConfigurationIsVisible = 0;
	defaultConfigurationName = Release;
};
'
    pbx.should == expected
  end
  
  it "PBXProject" do
    puts @pbx.to_pbx
  end
end