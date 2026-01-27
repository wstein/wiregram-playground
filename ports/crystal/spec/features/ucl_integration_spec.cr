require "../spec_helper"

describe "UCL language integration" do
  it "processes libucl test case 1 input" do
    input = <<-UCL
{
"key1": value;
"key1": value2;
"key1": "value;"
"key1": 1.0,
"key1": -0xdeadbeef
"key1": 0xdeadbeef.1
"key1": 0xreadbeef
"key1": -1e-10,
"key1": 1
"key1": true
"key1": no
"key1": yes
}
UCL
    input = "#{input}\n"

    result = WireGram::Languages::Ucl.process(input)
    output = result[:output].as(String)

    [
      "key1 = \"value\";",
      "key1 = \"value2\";",
      "key1 = \"value;\";",
      "key1 = 1.0;",
      "key1 = -3735928559;",
      "key1 = \"0xdeadbeef.1\";",
      "key1 = \"0xreadbeef\";",
      "key1 = -1e-10;",
      "key1 = 1;",
      "key1 = true;",
      "key1 = false;",
      "key1 = true;"
    ].each do |fragment|
      expect(output.includes?(fragment)).to be_true
    end
  end
end
