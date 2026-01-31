module Warp
  module Lang
    module Ruby
      module Annotations
        struct CrystalMethodParam
          getter name : String
          getter type : String?

          def initialize(@name : String, @type : String? = nil)
          end
        end

        struct CrystalMethodSig
          getter method_name : String
          getter params : Array(CrystalMethodParam)
          getter return_type : String?
          getter is_void : Bool
          getter def_start : Int32
          getter def_indent : String

          def initialize(
            @method_name : String,
            @params : Array(CrystalMethodParam) = [] of CrystalMethodParam,
            @return_type : String? = nil,
            @is_void : Bool = false,
            @def_start : Int32 = 0,
            @def_indent : String = "",
          )
          end

          def param_list : Array(String)
            @params.map(&.name)
          end
        end

        class CrystalSigBuilder
          def self.sorbet_sig_text(sig : CrystalMethodSig) : String
            parts = [] of String
            if sig.params.size > 0
              param_parts = sig.params.map do |param|
                type = Warp::Lang::Crystal::TypeMapping.to_sorbet(param.type)
                "#{param.name}: #{type}"
              end
              parts << "params(#{param_parts.join(", ")})"
            end

            if sig.is_void || sig.return_type.nil?
              parts << "void"
            else
              parts << "returns(#{Warp::Lang::Crystal::TypeMapping.to_sorbet(sig.return_type)})"
            end

            "sig { #{parts.join(".")} }"
          end

          def self.sorbet_sig_info(sig : CrystalMethodSig) : SigInfo
            params_map = {} of String => String
            sig.params.each do |param|
              params_map[param.name] = Warp::Lang::Crystal::TypeMapping.to_sorbet(param.type)
            end

            SigInfo.new(
              sorbet_sig_text(sig),
              sig.method_name,
              params_map,
              sig.return_type ? Warp::Lang::Crystal::TypeMapping.to_sorbet(sig.return_type) : nil,
              sig.is_void || sig.return_type.nil?,
              sig.param_list,
              sig.def_start,
              sig.def_indent,
            )
          end

          def self.rbs_sig_info(sig : CrystalMethodSig) : SigInfo
            params_map = {} of String => String
            sig.params.each do |param|
              params_map[param.name] = Warp::Lang::Crystal::TypeMapping.to_rbs(param.type)
            end

            SigInfo.new(
              "",
              sig.method_name,
              params_map,
              sig.return_type ? Warp::Lang::Crystal::TypeMapping.to_rbs(sig.return_type) : nil,
              sig.is_void || sig.return_type.nil?,
              sig.param_list,
              sig.def_start,
              sig.def_indent,
            )
          end
        end
      end
    end
  end
end
