module PBXTypes
  class BasicValue
    attr_accessor :value, :comment
    
    def initialize(args = {})
      @value = args[:value]
      @comment = args[:comment]
    end
  end
  
  class ISAType
    attr_accessor :guid, :isa, :comment

    def initialize args = {}
      @isa = basic_value(self.class.name)
      @guid = hashify(self)
    end

    def basic_value(value = nil, comment = nil)
      # { :value => value, :comment => comment }
      BasicValue.new :value => value, :comment => comment
    end

    def hashify to_hash
      # example
      ex = 'C01713D713462F35007665FA'
      "OEF" + (Digest::SHA1.hexdigest to_hash.to_s).upcase[4..ex.length]    
    end

    def self.has_fields(*fields)
      _fields = []
      fields.each do |f|
        _fields.push f.id2name
        
        define_method(f) do
          instance_variable_get("@#{f}")
        end
      end

      define_method("pbxfields") do
        _fields
      end
    end

    def self.has_format(format)
      define_method("format") do
        format
      end
    end
    
    def to_pbx(ind)
      print "#{@guid}"
      print " /* #{@comment} */" if @comment
      print " = {\n"
      ind += 1

      # PBX fields
      pbxfields.each do |field|
        case self.instance_variable_get("@#{field}").class.name
        when "Hash"
          h = self.instance_variable_get("@#{field}")
          if (h[:value])
            # We have value-comment hash
            h[:comment] = " /* #{h[:comment]} */" if h[:comment] != nil

            ind.times{print"\t"}; printf "%s = %s%s;\n", field, h[:value], h[:comment]
          else
            # We have dictionary
            ind.times{print"\t"}; printf "%s = {\n", field
            ind += 1
            h.each do |name, d|
              case d.class.name
              when "Hash"
                ind.times{print"\t"}
                d[:comment] = " /* #{d[:comment]} */" if d[:comment] != nil
                printf "%s = %s%s;\n", name, d[:value], d[:comment]
              when "Array"
                ind.times{print"\t"}
                print "#{name} = (\n"
                ind += 1
                d.each do |r|
                  ind.times{print"\t"}
                  r[:comment] = " /* #{r[:comment]} */" if r[:comment] != nil
                  printf "%s%s,\n", r[:name], r[:item], r[:comment]
                end
                ind -= 1
                ind.times{print"\t"}
                print ");\n"
              end
            end
            ind -= 1
            ind.times{print"\t"}; puts "};"
          end
        when "Array"
          a = self.instance_variable_get("@#{field}")
          ind.times{print"\t"}; printf "%s = (\n", field
          ind += 1
          a.each do |r|
            ind.times{print"\t"}
            r[:comment] = " /* #{r[:comment]} */" if r[:comment] != nil

            printf "%s%s,\n", r[:item], r[:comment]
          end
          ind -= 1
          ind.times{print"\t"}; print ");\n"
        end
      end
      ind -= 1

      ind.times{print"\t"}; print "};\n"
    end
  end
  
  class PBXBuildFile < ISAType
    has_fields :isa, :fileRef
    has_format :oneline
    
    def to_pbx(ind)
      print "#{@guid}"
      print " /* #{@comment} */" if @comment
      print " = {isa = #{@isa}; "
      if (@fileRef.kind_of?(Hash))
        print "fileRef = #{@fileRef[:value]} /* #{@fileRef[:comment]} */"
      else
        print "fileRef = #{@fileRef}"
      end
      puts "; };"
    end
  end

  class PBXFileReference < ISAType
    has_fields :isa, :fileEncoding, :explicitFileType, :lastKnownFileType, :includeInIndex, :name, :path, :sourceTree
    has_format :oneline
    
    def to_pbx(ind)
      print "#{@guid}"
      print " /* #{@comment} */" if @comment
      print " = {"
      ["isa", "fileEncoding", "explicitFileType", "lastKnownFileType", "includeInIndex", "name", "path", "sourceTree"].each do |var|
        printf "%s = %s; ", var, self.instance_variable_get("@#{var}") if self.instance_variable_get("@#{var}") != nil
      end
      puts "};"
    end
  end

  class PBXFrameworksBuildPhase < ISAType
    has_fields :isa, :buildActionMask, :files, :runOnlyForDeploymentPostprocessing
  end

  class PBXGroup < ISAType
    has_fields :isa, :children, :name, :path, :sourceTree
  end

  class PBXNativeTarget < ISAType
    has_fields :isa, :buildConfigurationList, :buildPhases, :buildRules, :dependencies, :name,
      :productName, :productReference, :productType

    def add_build_phase build_phase, position = -1
      @buildPhases.insert(position, { :item => build_phase.guid, :comment => build_phase.comment })
    end
  end

  class PBXProject < ISAType
    has_fields :isa, :attributes, :buildConfigurationList, :compatibilityVersion, :developmentRegion, 
      :hasScannedForEncodings, :knownRegions, :mainGroup, :productRefGroup, :projectDirPath, :projectRoot,
      :targets
  end

  class PBXResourcesBuildPhase < ISAType
    has_fields :isa, :buildActionMask, :files, :runOnlyForDeploymentPostprocessing
  end

  class PBXShellScriptBuildPhase < ISAType
    has_fields :isa, :buildActionMask, :files, :inputPaths, :outputPaths, :runOnlyForDeploymentPostprocessing,
      :shellPath, :shellScript, :showEnvVarsInLog

      def initialize args = {}
        super

        # Defaults
        @comment = "ShellScript"
        @buildActionMask = basic_value(2147483647)
        @files = []
        @inputPaths = []
        @outputPaths = []
        @runOnlyForDeploymentPostprocessing = basic_value(0)

        args.each do |k,v|
          instance_variable_set("@#{k}", basic_value(v)) unless v.nil?
        end
      end
  end

  class PBXSourcesBuildPhase < ISAType
    has_fields :isa, :buildActionMask, :files, :runOnlyForDeploymentPostprocessing
  end

  class PBXVariantGroup < ISAType
    has_fields :isa, :children, :name, :sourceTree
  end

  class XCBuildConfiguration < ISAType
    has_fields :isa, :buildSettings, :name
  end

  class XCConfigurationList < ISAType
    has_fields :isa, :buildConfigurations, :defaultConfigurationIsVisible, :defaultConfigurationName
  end
  
end