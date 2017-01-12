class BasicObject
  def self.delegate *methods, to:
    methods.each do |meth|
      define_method(meth.to_sym) do |*args, &block|
        send(to).send meth, *args, &block
      end
    end
  end
end
