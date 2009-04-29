require 'yaml'

$n = 3
$m = 10
$C = "CONSTANT"

class Var
  
  @@s_to_var = Hash.new
  @@varids = Hash.new
  @@curid = 0
  
  attr_reader :name, :index, :state
  
  def initialize(name,state=false,index = false)
    @name = name
    @index = index
    @state = state
    @id = @@varids[self.to_s] || @@curid += 1
    @@varids[self.to_s] = @id
    @@s_to_var[self.to_s] = self
  end
  
  def to_s
    out = @name.clone
    out << "_#{@index}" if @index
    out << "(" + @state.join(',') + ")" if @state
    out
  end 
  
  def hash
    to_s
  end
  
  def eql? x
    x.to_s == self.to_s
  end
  
  def == x
    x.to_s == self.to_s
  end
  
  def self.varids
    @@varids
  end

  def self.make_name_from_id id
    "x_#{id}"
  end
  
  def get_name
    Var.make_name_from_id @id
  end


  def self.get_var name
    id = name.match(/[0-9]+/)[0].to_i
    @@s_to_var[@@varids.index(id)]
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


class Equation < Hash

  attr_accessor :constant

  def initialize()
    @constant = 0.0
    super
  end

  def set (coeff,var)
    self[var] = (self[var] || 0.0) + coeff
  end 

  def to_s
    out = ""
    map do |var,coeff|
      coeff.to_s + "*" + var.to_s
    end.join(" + ") + " #{@RELATION} " + @constant.to_s
  end
  
  def to_lpformat
    out = ""
    map do |var,coeff|
      coeff.to_s + " " + var.get_name
    end.join(" + ") + " #{@RELATION} #{@constant.to_s}"
  end  

end


class Ineq < Equation
  def initialize
    @RELATION = "<="
  end
end

class Eqlty < Equation
  def initialize
    @RELATION = "="
  end
end

def cvar
  Var.new('C')
end

def move_inequality state, ind
  eq = Eqlty.new
  nextstate = state.next(ind) # w + 1/m e_i
  phi =Var.new('phi', state) # Phi(w)
  phinext = Var.new('phi', nextstate) # Phi(w + 1/m e_i)
  p_i = Var.new('p', state, ind) # p_i(w)
  p_inext = Var.new('p', nextstate,ind) # p_i(w + 1/m e_i)
  eq.set -1.0, phinext
  eq.set 1.0, phi
  eq.set 1.0, p_i
  eq.set((-1.0 + 1.0/$m), p_inext) 
  eq.constant = 0.0
  return eq
end

def boundary_equality state,ind
  eq = Eqlty.new
  p_i = Var.new('p', state, ind)
  eq.set 1.0, p_i
  eq.constant = 0.0
  return eq
end

def shift_inequality state
  # Phi boundary inequality
  eq = Eqlty.new
  shiftedstate = state.shiftdown
  phi = Var.new('phi',state)
  phidown = Var.new('phi',shiftedstate)
  eq.constant = 0.0
  eq.set -1.0, phidown
  eq.set 1.0, phi
  eq.set( (-1.0/$m), cvar)
  eq
  peqs = (0...$n).map do |ind|
    p_i = Var.new('p',state,ind)
    p_i_shifted = Var.new('p',shiftedstate,ind)
    peq = Eqlty.new
    peq.set -1.0, p_i
    peq.set 1.0, p_i_shifted
    peq.constant = 0.0
    peq
  end
  peqs + [eq]
end

def probability_inequalities state
  eqs = []
  sumeq = Eqlty.new
  (0...$n).each do |i|
    p_i = Var.new('p',state,i)
    sumeq.set(1.0, p_i)
    poseq = Ineq.new
    poseq.set -1.0, p_i
    poseq.constant = 0.0
    eqs << poseq
  end
  sumeq.constant = 1.0
  eqs << sumeq
end

def plot x,y
  Gnuplot.open do |gp|
    Gnuplot::Plot.new( gp ) do |plot|

      plot.title  "Array Plot Example"
      plot.ylabel "x"
      plot.xlabel "x^2"
      
      plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
        ds.with = "linespoints"
        ds.notitle
      end
    end
  end
  
end

eqlist = []

startstate = State.new(Array.new($n,0))
endstate = State.new(Array.new($n,$m))

phiinit = Var.new('phi', startstate)
eqinit = Eqlty.new
eqinit.set(1.0,phiinit)
eqinit.constant = 0.0
eqlist << eqinit

phifin = Var.new('phi', endstate)
eqfin = Ineq.new
eqfin.set(1.0,phifin)
eqfin.set(-1.0,cvar)
eqfin.constant = 0.0
eqlist << eqfin

state = startstate.clone
begin
  next unless state.allowed?
  eqlist.concat(probability_inequalities state)
  # puts state.join('-')
  (0...$n).each do |ind|
    if state.canmove? ind
      eqlist << move_inequality(state, ind) 
    elsif state.criticalind? ind
      eqlist << boundary_equality(state,ind)
    elsif state.shiftable?
      eqlist.concat shift_inequality(state)
    end
  end
end while state = state.inc

test = IO.popen("lp_solve",'r+')

objective = "min: #{cvar.get_name} ;"
test.puts objective

eqlist.each do |eq|
  test.puts eq.to_lpformat + ";"
  puts eq.to_s + ";"
end

test.close_write

4.times {test.gets}
$final = {}
while line = test.gets
  var_s, val_s = line.split(" ")
  var = Var.get_var var_s
  val = val_s.to_f
  $final[var.to_s] = val
  puts "#{val}\t#{var}" if var == cvar
end

test.close

$eqlist = eqlist
