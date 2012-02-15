module PBXProject
  # PBXProject class is main class for whole project file.
  # Initializer takes one named argument, `file` which defines pbxproject
  # file to be parsed.
  class PBXProject
    # Filename of pbxproj file
    attr_reader :filename
    # Current state of parser, either nil, :ready, :parsed
    attr_reader :state
    
    attr_accessor :archiveVersion, :objectVersion, :sections
  
    def initialize(args = {})
      return unless args[:file]
      raise "Project file cannot be read" unless File.file?(args[:file])

      @filename = args[:file]
    
      # initialize our class
      # make sure that our sections are on proper order
      @sections = {
        # "PBXBuildFile" => nil,
        # "PBXReferenceProxy" => nil,
        # "PBXContainerItemProxy" => nil,
        # "PBXFileReference" => nil,
        # "PBXFrameworksBuildPhase" => nil,
        # "PBXGroup" => nil,
        # "PBXHeadersBuildPhase" => nil,
        # "PBSLegacyTarget" => nil,
        # "PBXNativeTarget" => nil,
        # "PBXProject" => nil,
        # "PBXResourcesBuildPhase" => nil,
        # "PBXShellScriptBuildPhase" => nil,
        # "PBXSourcesBuildPhase" => nil,
        # "PBXTargetDependency" => nil,
        # "PBXVariantGroup" => nil,
        # "XCBuildConfiguration" => nil,
        # "XCConfigurationList" => nil,
        # "XCVersionGroup" => nil
      }
    
      # and set that we're ready for parsing
      @state = :ready
      
    end
  
    # This is one big parser
    def parse
      raise "Not ready for parsing" unless @state == :ready
      pbx = File.open(@filename, 'r')
    
      line_num = 0
      group_name = []
      # group = []
      section_type = nil
      section = nil
      item = nil
      list_name = nil
      list = nil
      grouplist_name = nil
      grouplist = nil
    
      # Read our file
      pbx.each_line do |line|
        if (line_num == 0 && !line.match(Regexp.new(Regexp.escape('// !$*UTF8*$!'))))
          raise "Unknown file format"
        end
      
        # Main level Attributes
        if (group_name.count == 0 && !section_type && m = line.match(/\s+(.*?) = (.*?)( \/\* (.*) \*\/)?;/))
          # d = { :value => m[2], :comment => m[4] }
          self.instance_variable_set("@#{m[1]}", PBXTypes::BasicValue.new(:value => m[2], :comment => m[4]))
        
          next
        end
      
        # Begin object group
        if (m = line.match(/\s+(.*) = \{/))
          group_name.push m[1]
          # group.push {}
        end
      
        # End our object group
        if (line.match(/\s+\};/))
          group_name.pop
          # group.pop
        
          if (item && group_name.count < 2)
            @sections[section_type].push item
            item = nil
          end
        end
      
        # Begin section
        if (m = line.match(/\/\* Begin (.*) section \*\//))
          section_type = m[1]
          @sections[section_type] = []

          next
        end
      
        # One line section data, simple. huh?
        if (section_type && group_name.count < 3 && m = line.match(/\s+(.*?) (\/\* (.*?) \*\/ )?= \{(.*?)\};/))
          begin
            # cls = PBXProject::PBXProject::const_get(section_type)
            # item = cls.new
            item = eval("PBXTypes::#{section_type}").new
        
            item.guid = m[1]
            item.comment = m[3]
            m[4].scan(/(.*?) = (.*?)( \/\* (.*) \*\/)?; ?/).each do |v|
              if (v[3])
                # d = { :value => v[1], :comment => v[3]}
                item.instance_variable_set("@#{v[0]}", PBXTypes::BasicValue.new(:value => v[1], :comment => v[3]))
              else
                item.instance_variable_set("@#{v[0]}", v[1])
              end
            end
        
            @sections[section_type].push item
            item = nil
          rescue NameError => e
            puts e.inspect
          end
        
          next
        end
      
        # Multiline with lists
        if (section_type && group_name.count < 3 && m = line.match(/\s+(.*?) (\/\* (.*?) \*\/ )?= \{/))
          begin
            # cls = PBXProject::PBXProject::const_get(section_type)
            # item = cls.new
            item = eval("PBXTypes::#{section_type}").new
          
            item.guid = m[1]
            item.comment = m[3]
          
            # puts item.inspect
          rescue NameError => e
            puts e.inspect
          end
        
          next
        end
      
        # Next line in multiline
        if (item && m = line.match(/^\s*(.*?) = (.*?)(?: \/\* (.*) \*\/)?;$/))
          if (group_name.count < 3)
            # i = { :value => m[2], :comment => m[3] }
            item.instance_variable_set("@#{m[1]}", PBXTypes::BasicValue.new(:value => m[2], :comment => m[3]))
          else
            grp = item.instance_variable_get("@#{group_name.last}")
            if (!grp.kind_of?(Hash))
              grp = {}
            end
            # grp[m[1]] = { :value => m[2], :comment => m[3] }
            grp[m[1]] = PBXTypes::BasicValue.new :value => m[2], :comment => m[3]
            item.instance_variable_set("@#{group_name.last}", grp)
          end
        
          next
        end
      
        # And the multiline list begin
        if (item && m = line.match(/\s+(.*?) = \(/))
          if (group_name.count < 3)
            list_name = m[1]
            list = []
          else
            grouplist_name = m[1]
            grouplist = []
          end
        
          next
        end
      
        # And list items
        if (item && m = line.match(/\s+(.*?)( \/\* (.*?) \*\/)?,/))
          if (group_name.count < 3)
            # i = { :item => m[1], :comment => m[3] }
            list.push PBXTypes::BasicValue.new :value => m[1], :comment => m[3]
          else
            # i = { :item => m[1], :comment => m[3] }
            grouplist.push PBXTypes::BasicValue.new :value => m[1], :comment => m[3]
          end
        
          next
        end
      
        if (item && line.match(/\s+\);/))
          if (group_name.count < 3)
            item.instance_variable_set("@#{list_name}", list)
            list = nil
            list_name = nil
          else
            grp = item.instance_variable_get("@#{group_name.last}")
            if (!grp.kind_of?(Hash))
              grp = {}
            end
            grp[grouplist_name] = grouplist
            item.instance_variable_set("@#{group_name.last}", grp)
            grouplist_name = nil
            grouplist = nil
          end
        
          next
        end
      
        # End section
        if (m = line.match(/\/\* End (.*) section \*\//))
          section_type = nil
          section = nil
        end
      
        # Increse our line counter
        line_num += 1
      end
    
      @state = :parsed
    
      true
    end
  
    def find_item args = {}
      type = args[:type]
      type_name = type.name.split('::').last || ''
      args.delete(:type)
      @sections.each do |t, arr|
        next unless t == type_name
        
        # Return all if we searched only for item type
        return arr if args.count == 0
        
        arr.each do |item|
          args.each do |k,v|
            val = item.instance_variable_get("@#{k}")
            val = (val.respond_to?(:value) ? val.value : val)
            
            next unless val
            
            if (val.match(Regexp.new("\"?#{v}\"?")))
              return item
            end
          end
        end
      end
    
      nil
    end
  
    def add_item item, position = -1
      type = item.class.name.split('::').last || ''
    
      # Ensure that we have array
      @sections[type] ||= []
      @sections[type].insert(position, item)
    
      item.guid
    end
  
    def to_pbx ind = 0
      ind = 2
      pbx = ''
    
      pbx += "// !$*UTF8*$!\n{\n"
      pbx += "\tarchiveVersion = %s;\n" % @archiveVersion.to_pbx
      pbx += "\tclasses = {\n\t};\n"
      pbx += "\tobjectVersion = %s;\n" % @objectVersion.to_pbx
      pbx += "\tobjects = {\n"
    
      @sections.each do |type, val|
        next if val.nil?  # skip section if it's empty
        pbx += "\n/* Begin %s section */\n" % type

        val.each do |item|
          pbx += item.to_pbx ind
        end
      
        pbx += "/* End %s section */\n" % type
      end
    
      pbx += "\t};\n"
      pbx += "\trootObject = %s;\n" % @rootObject.to_pbx
      pbx += "}\n"
    
      pbx
    end

    def write_to args = {}
      # Get our serialized format first
      pbx = self.to_pbx
      
      # Open file
      File.open(args[:file], 'w') {|f| f.write(pbx) }
      
      args[:file]
    end
    
  end
end
