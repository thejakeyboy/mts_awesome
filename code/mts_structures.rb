
class Var
  
  @@varids = Hash.new
  @@curid = 0
  @s = nil
  
  def self.varids
    @@varids
  end
  
  def self.curid
    @@curid
  end
  
  attr_reader :name, :index, :state
  
  def initialize(name,state=false,index = false)
    @name = name
    @index = index
    @state = state
    @hashnum = nil
    @id = @@varids[self] || @@curid += 1
    @@varids[self] = @id
  end
  
  def to_s
    return @s if @s
    out = @name.clone
    out << "_#{@index}" if @index
    out << "(" + @state.join(',') + ")" if @state
    @s = out
  end 
  
  def hash
    to_s.hash
  end
  
  def eql? x
    self.hash == x.hash
  end

  def self.make_name_from_id id
    "x_#{id}"
  end
  
  def get_name
    Var.make_name_from_id @id
  end


  def self.get_var name
    id = name.match(/[0-9]+/)[0].to_i
    @@varids.index(id)
  end
end

class State < Array
  
  def shiftzero
    newstate = clone
    min = newstate.min
    newstate.each_with_index{|v,i| newstate[i] = v-min}
    newstate
  end
  def initialize(arg)
    super(arg)
  end

  def next i
    # return false if at(i) == $m
    newstate = clone
    newstate[i] += 1
    newstate
  end

  def inc
    ind=-1
    news = self.clone
    while ind += 1 do 
      return false if ind >= length
      if news[ind] <= $m
        news[ind] += 1
        return news
      else news[ind] = 0
      end
    end
  end

  def canmove? ind
    self[ind] < $m
  end

  def criticalind? ind
    self[ind] == $m && self.min == 0
  end
  def shiftable?
    self.min > 0
  end

  def shiftdown
    State.new(self.map {|x| x - 1})
  end

  def allowed?
    self.max - self.min <= $m
  end

end

$C = Var.new('constant')



class Equation 
  
  attr_accessor :coeffs

  def initialize(arg)
    @coeffs = {}
    @coeffs[$C] = 0.0
    set(arg)
  end

  def set(coeffhash)
    @coeffs.merge! coeffhash
  end 

  def to_s
    @coeffs.select {|k,v| k != $C}.map do |var,coeff|
      coeff.to_s + "*" + var.to_s
    end.join(" + ") + " #{@RELATION} " + @coeffs[$C].to_s
  end
  
  def to_lpformat
    @coeffs.select {|k,v| k != $C}.map do |var,coeff|
      coeff.to_s + " " + var.get_name
    end.join(" + ") + " #{@RELATION} #{@coeffs[$C].to_s}"
  end  

end


class Ineq < Equation
  def initialize(*args)
    @RELATION = "<="
    super(*args)
  end
end

class Eqlty < Equation
  def initialize(*args)
    @RELATION = "="
    super(*args)
  end
end

def cvar
  Var.new('C')
end