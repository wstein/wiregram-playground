# typed: true
class Object
  sig { params(x: T.any(Integer, String), y: T.nilable(String)).returns(T::Boolean) }
  def check(x, y); end
end
