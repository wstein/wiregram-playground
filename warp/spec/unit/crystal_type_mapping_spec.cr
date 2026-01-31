require "../spec_helper"

describe "Crystal Type Mapping" do
  it "maps primitive types to RBS" do
    Warp::Lang::Crystal::TypeMapping.to_rbs("Int32").should eq("Integer")
    Warp::Lang::Crystal::TypeMapping.to_rbs("Float64").should eq("Float")
    Warp::Lang::Crystal::TypeMapping.to_rbs("Bool").should eq("bool")
    Warp::Lang::Crystal::TypeMapping.to_rbs("Nil").should eq("nil")
  end

  it "maps nilable and union types to RBS" do
    Warp::Lang::Crystal::TypeMapping.to_rbs("String?").should eq("String?")
    Warp::Lang::Crystal::TypeMapping.to_rbs("Int32 | String").should eq("Integer | String")
  end

  it "maps generic types to RBS" do
    Warp::Lang::Crystal::TypeMapping.to_rbs("Array(Int32)").should eq("Array[Integer]")
    Warp::Lang::Crystal::TypeMapping.to_rbs("Hash(String, Int32)").should eq("Hash[String, Integer]")
    Warp::Lang::Crystal::TypeMapping.to_rbs("Set(String)").should eq("Set[String]")
  end

  it "maps primitive types to Sorbet" do
    Warp::Lang::Crystal::TypeMapping.to_sorbet("Int32").should eq("Integer")
    Warp::Lang::Crystal::TypeMapping.to_sorbet("Float64").should eq("Float")
    Warp::Lang::Crystal::TypeMapping.to_sorbet("Bool").should eq("T::Boolean")
    Warp::Lang::Crystal::TypeMapping.to_sorbet("Nil").should eq("NilClass")
  end

  it "maps nilable and union types to Sorbet" do
    Warp::Lang::Crystal::TypeMapping.to_sorbet("String?").should eq("T.nilable(String)")
    Warp::Lang::Crystal::TypeMapping.to_sorbet("Int32 | String").should eq("T.any(Integer, String)")
  end

  it "maps generic types to Sorbet" do
    Warp::Lang::Crystal::TypeMapping.to_sorbet("Array(Int32)").should eq("T::Array[Integer]")
    Warp::Lang::Crystal::TypeMapping.to_sorbet("Hash(String, Int32)").should eq("T::Hash[String, Integer]")
    Warp::Lang::Crystal::TypeMapping.to_sorbet("Set(String)").should eq("T::Set[String]")
  end
end

describe "Crystal Signature Builder" do
  it "generates Sorbet sig text" do
    sig = Warp::Lang::Ruby::Annotations::CrystalMethodSig.new(
      "greet",
      [
        Warp::Lang::Ruby::Annotations::CrystalMethodParam.new("name", "String"),
        Warp::Lang::Ruby::Annotations::CrystalMethodParam.new("age", "Int32"),
      ],
      "String",
    )

    text = Warp::Lang::Ruby::Annotations::CrystalSigBuilder.sorbet_sig_text(sig)
    text.should eq("sig { params(name: String, age: Integer).returns(String) }")
  end

  it "builds RBS definition from Crystal sig" do
    sig = Warp::Lang::Ruby::Annotations::CrystalMethodSig.new(
      "add",
      [
        Warp::Lang::Ruby::Annotations::CrystalMethodParam.new("a", "Int32"),
        Warp::Lang::Ruby::Annotations::CrystalMethodParam.new("b", "Int32"),
      ],
      "Int32",
    )

    info = Warp::Lang::Ruby::Annotations::CrystalSigBuilder.rbs_sig_info(sig)
    Warp::Lang::Ruby::Annotations::RbsGenerator.rbs_definition(info).should eq("def add: (Integer, Integer) -> Integer")
  end
end
