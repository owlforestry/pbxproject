require 'digest/sha1'

module PBXProject
  module PBXTypes
    
    class BasicValue
      attr_accessor :value, :comment
    
      def initialize(args = {})
        @value = args[:value]
        @comment = args[:comment]
      end
    
      def to_pbx ind = 0
        pbx = ''
        pbx += "#{@value}"
        pbx += " /* #{@comment} */" if @comment
      
        pbx
      end
    end
  
    class ISAType
      attr_accessor :guid, :isa, :comment

      def initialize args = {}
        @isa = basic_value(self.class.name.split("::").last)
        @guid = hashify(self)
      
        args.each do |k,v|
          instance_variable_set("@#{k}", basic_value(v)) unless v.nil?
        end
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
          
          define_method("#{f}=") do |val|
            instance_variable_set("@#{f}", val)
          end
        end

        define_method("pbxfields") do
          _fields
        end
      end

      def self.has_format(format)
        _format = format
      
        define_method("format") do
          _format
        end
      end
    
      def _pbx_indent(ind = 0)
        "\t" * ind
      end
    
      def _pbx_format
        return nil unless defined? format
        format
      end
    
      def _pbx_newline
        case _pbx_format
        when :oneline
          nil
        else
          "\n"
        end
      end
    
      def to_pbx(ind = 0)
        pbx = ''
        pbx += _pbx_indent(ind) + "#{@guid}"
        pbx += " /* #{@comment} */" if @comment
        pbx += " = {%s" % _pbx_newline
      
        ind += 1

        # PBX fields
        pbxfields.each do |fld|
          field = self.instance_variable_get("@#{fld}")
          case field.class.name
          when "String"
            pbx += (_pbx_format == :multiline ? _pbx_indent(ind) : "") + "%s = %s;%s%s" % [fld, field, (_pbx_newline == nil ? " " : ""),_pbx_newline]
          when 'PBXProject::PBXTypes::BasicValue'
            pbx += (_pbx_format == :multiline ? _pbx_indent(ind) : "") + "%s = %s;%s%s" % [fld, field.to_pbx, (_pbx_newline == nil ? " " : ""), _pbx_newline]
          when "Array"
            pbx += _pbx_indent(ind) + "%s = (%s" % [fld, _pbx_newline]

            ind += 1
            field.each do |item|
              pbx += _pbx_indent(ind) + "%s,%s" % [item.to_pbx, _pbx_newline]
            end
            ind -= 1
            pbx += _pbx_indent(ind) + ");%s" % _pbx_newline
          when "NilClass"
          when "Hash"
            pbx += _pbx_indent(ind) + "%s = {%s" % [fld, _pbx_newline]
          
            ind += 1
            field.each do |name, d|
              case d.class.name
              when "PBXProject::PBXTypes::BasicValue"
                pbx += _pbx_indent(ind) + "%s = %s;%s%s" % [name, d.to_pbx, (_pbx_newline == nil ? " " : ""), _pbx_newline]
              when "Array"
                pbx += _pbx_indent(ind) + "%s = (%s" % [name, _pbx_newline]
              
                ind += 1
                d.each do |item|
                  pbx += _pbx_indent(ind) + "%s,%s" % [item.to_pbx, _pbx_newline]
                end
                ind -= 1
              
                pbx += _pbx_indent(ind) + ");%s" % _pbx_newline
              end
            end
            ind -= 1
          
            pbx += _pbx_indent(ind) + "};%s" % _pbx_newline
          else
            puts "WHAT? #{field.class}"
            puts "#{field}"
          end

        end
        ind -= 1

        # ind.times{print"\t"}; pbx += "};%s" % _pbx_newline
        if (_pbx_newline)
          pbx += "\t" * ind + "};\n"
        else
          pbx += "};\n"
        end
      
        pbx
      end
    end
  
    class PBXBuildFile < ISAType
      has_fields :isa, :fileRef
      has_format :oneline
    end
    
    class PBXReferenceProxy < ISAType
      has_fields :isa, :fileType, :path, :remoteRef, :sourceTree
      has_format :multiline
    end
    
    class PBXContainerItemProxy < ISAType
      has_fields :isa, :containerPortal, :proxyType, :remoteGlobalIDString, :remoteInfo
      has_format :multiline
    end
    
    class PBXFileReference < ISAType
      has_fields :isa, :fileEncoding, :explicitFileType, :lastKnownFileType, :includeInIndex, :name, :path, :sourceTree
      has_format :oneline
    end

    class PBXFrameworksBuildPhase < ISAType
      has_fields :isa, :buildActionMask, :files, :runOnlyForDeploymentPostprocessing
      has_format :multiline
    end

    class PBXGroup < ISAType
      has_fields :isa, :children, :name, :path, :sourceTree
      has_format :multiline
    
      def add_children(fileref)
        @children.push BasicValue.new(:value => fileref.guid, :comment => fileref.comment)
      
        fileref.guid
      end
    end

    class PBXNativeTarget < ISAType
      has_fields :isa, :buildConfigurationList, :buildPhases, :buildRules, :dependencies, :name,
        :productName, :productReference, :productType
      has_format :multiline

      def add_build_phase build_phase, position = -1
        @buildPhases.insert(position, BasicValue.new(:value => build_phase.guid, :comment => build_phase.comment))
      end
    end

    class PBXProject < ISAType
      has_fields :isa, :attributes, :buildConfigurationList, :compatibilityVersion, :developmentRegion, 
        :hasScannedForEncodings, :knownRegions, :mainGroup, :productRefGroup, :projectDirPath, :projectRoot,
        :targets
      has_format :multiline
    end

    class PBXResourcesBuildPhase < ISAType
      has_fields :isa, :buildActionMask, :files, :runOnlyForDeploymentPostprocessing
      has_format :multiline
    end

    class PBXShellScriptBuildPhase < ISAType
      has_fields :isa, :buildActionMask, :files, :inputPaths, :name, :outputPaths, :runOnlyForDeploymentPostprocessing,
        :shellPath, :shellScript, :showEnvVarsInLog
      has_format :multiline

      def initialize args = {}
        super

        # Defaults
        @comment = "ShellScript"
        @buildActionMask = basic_value(2147483647)
        @files = []
        @inputPaths = []
        @outputPaths = []
        @runOnlyForDeploymentPostprocessing = basic_value(0)
      end
    end

    class PBXSourcesBuildPhase < ISAType
      has_fields :isa, :buildActionMask, :files, :runOnlyForDeploymentPostprocessing
      has_format :multiline
    end

    class PBXTargetDependency < ISAType
      has_fields :isa, :target, :targetProxy
      has_format :multiline
    end
    
    class PBXVariantGroup < ISAType
      has_fields :isa, :children, :name, :sourceTree
      has_format :multiline
    end

    class XCBuildConfiguration < ISAType
      has_fields :isa, :buildSettings, :name
      has_format :multiline
    end

    class XCConfigurationList < ISAType
      has_fields :isa, :buildConfigurations, :defaultConfigurationIsVisible, :defaultConfigurationName
      has_format :multiline
    end
    
    class XCVersionGroup < ISAType
      has_fields :isa, :children, :currentVersion, :name, :path, :sourceTree, :versionGroupType
      has_format :multiline
    end
  end
end