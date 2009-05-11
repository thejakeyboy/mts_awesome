load 'mts_structures.rb'

def move_inequality state, ind
  nextstate = state.next(ind) # w + 1/m e_i
  phi =Var.new('phi', state) # Phi(w)
  phinext = Var.new('phi', nextstate) # Phi(w + 1/m e_i)
  p_i = Var.new('p', state, ind) # p_i(w)
  p_inext = Var.new('p', nextstate,ind) # p_i(w + 1/m e_i)
  Eqlty.new({phinext => -1.0, phi => 1.0, p_i => 1.0, 
    p_inext => (-1.0 + 1.0/$m), $C => 0.0})
end

def boundary_equality state,ind
  p_i = Var.new('p', state, ind)
  Eqlty.new({p_i => 1.0, $C => 0.0})
end

def shift_inequality state
  # Phi boundary inequality
  shiftedstate = state.shiftdown
  phi = Var.new('phi',state)
  phidown = Var.new('phi',shiftedstate)
  eq = Eqlty.new({phidown => -1.0, phi => 1.0, cvar => -1.0/$m, $C => 0.0})
  peqs = (0...$n).map do |ind|
    p_i = Var.new('p',state,ind)
    p_i_shifted = Var.new('p',shiftedstate,ind)
    Eqlty.new({p_i => -1.0, p_i_shifted => 1.0, $C => 0.0})
  end + [eq]
end

def probability_inequalities state
  eqs = []
  sumeq = Eqlty.new({$C => 1.0})
  (0...$n).each do |i|
    p_i = Var.new('p',state,i)
    sumeq.set({p_i => 1.0})
    eqs << Ineq.new({p_i => -1.0, $C => 0.0})
  end
  eqs << sumeq
end

def plot(y)
  x = (0...(y.length)).to_a
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

def plot(y)
  x = (0...(y.length)).to_a
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

def feed_to_lp_solve objective, eqlist
  test = IO.popen("lp_solve",'r+')
  test.puts objective
  eqlist.each do |eq|
    test.puts eq.to_lpformat + ";"
  end
  test.close_write

  4.times {test.gets}
  final = {}
  while line = test.gets
    var_s, val_s = line.split(" ")
    var,val = Var.get_var(var_s), val_s.to_f
    final[var.to_s] = val
    puts "#{val}\t#{var}" if var.eql? cvar
  end
  test.close
  return final
end
