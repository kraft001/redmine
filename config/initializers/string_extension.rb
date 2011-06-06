class String
  def to_utf8(encoding)
    converter = Iconv.new('UTF-8', encoding)
    converter.iconv(self)
  end
end

