require 'spec_helper'

module My; end
class My::User
  attr_accessor :name, :age, :gender
  attr_accessor :taken_degree
  attr_accessor :books

  def initialize
    self.books = []
  end
end
class My::Book
  attr_accessor :name
  def initialize(name)
    self.name = name
  end
end
class My::UserDegree
  attr_accessor :faculty
  attr_accessor :degree_name

  def to_s
    "#{degree_name} at #{faculty}"
  end
end

describe Jsoning do
  before(:each) do
    Jsoning.clear
  end

  it 'has a version number' do
    expect(Jsoning::VERSION).not_to be nil
  end

  describe "DSL" do
    it "allow 'parallel_variable' to be specified implicitly" do
      Jsoning.for(My::User) do
        key :name
      end

      protocol = Jsoning.protocol_for(My::User)
      expect(protocol.mapper_for(:name)).to_not be_nil

      name_mapper = protocol.mapper_for(:name)
      expect(name_mapper.name).to eq("name")
      expect(name_mapper.parallel_variable).to eq(:name)
    end

    it "can define dsl with specifying default value" do
      Jsoning.for(My::User) do
        key :name, default: "Adam Pahlevi"
      end

      protocol = Jsoning.protocol_for(My::User)
      name_mapper = protocol.mapper_for(:name)
      expect(name_mapper.name).to eq("name")
      expect(name_mapper.default_value).to eq("Adam Pahlevi")
    end

    it "can define dsl with specifying nullable value" do
      Jsoning.for(My::User) do
        key :name, null: false
      end

      protocol = Jsoning.protocol_for(My::User)
      name_mapper = protocol.mapper_for(:name)
      expect(name_mapper.name).to eq("name")
      expect(name_mapper.nullable).to eq(false)
    end
  end # dsl

  describe "Generator" do
    let(:user) do
      user = My::User.new
      user.name = "Adam Baihaqi"
      user.age = 21
      user.books << My::Book.new("Quiet: The Power of Introvert")
      user.books << My::Book.new("Harry Potter and the Half-Blood Prince")
      user
    end

    it "can generate json" do
      Jsoning.for(My::User) do
        key :name
        key :years_old, from: :age
        key :gender, default: "male"
        key :books
        key :degree_detail, from: :taken_degree
      end

      Jsoning.for(My::Book) do
        key :name
      end

      Jsoning.for(My::UserDegree) do
        key :faculty
        key :degree, from: :degree_name
      end

      json = Jsoning(user)
      expect(JSON.parse(json)).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>nil})

      degree = My::UserDegree.new
      degree.faculty = "School of IT"
      degree.degree_name = "B.Sc. (Hons) Computer Science"
      user.taken_degree = degree

      json = Jsoning(user)
      expect(JSON.parse(json)).to eq({"name"=>"Adam Baihaqi", "years_old"=>21, "gender"=>"male", "books"=>[{"name"=>"Quiet: The Power of Introvert"}, {"name"=>"Harry Potter and the Half-Blood Prince"}], "degree_detail"=>{"faculty"=>"School of IT", "degree"=>"B.Sc. (Hons) Computer Science"}})
    end
  end
end