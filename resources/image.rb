actions :add, :delete

def initialize(*args)
  super
  @actions = :add
end

attribute :name, :kind_of => String, :name_attribute => true
attribute :registry, :kind_of => String, :default => nil
attribute :tag, :kind_of => String, :default => nil
