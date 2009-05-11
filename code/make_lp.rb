# load the relevant files
load 'mts_structures.rb'
load 'mts_utils.rb'
require 'yaml'

# $n is the number of states
$n = ARGV.shift.to_i

# $m is the "discretization" parameter
$m = ARGV.shift.to_i

# eqlist is the list of equations which will be input
# into the lpsolver
eqlist = []

# start and end states
startstate = State.new(Array.new($n,0))
endstate = State.new(Array.new($n,$m))

# start and end phi variables
phiinit = Var.new('phi', startstate)
phifin = Var.new('phi', endstate)

eqlist << Eqlty.new({phiinit => 1.0, $C => 0.0} )
eqlist << Eqlty.new({phifin => 1.0, cvar => -1.0, $C => 0.0})

state = startstate.clone # copy of start state

# we now run through all "allowable states" and
# include the relevant equalities/inequalities
# for all the phi's and the p_i's
begin
  next unless state.allowed? # skip this state if it's not allowed
  eqlist.concat(probability_inequalities(state)) # required prob. ineq's
  (0...$n).each do |ind| # for ind = 0...$n
    if state.canmove? ind
      eqlist << move_inequality(state, ind) 
    elsif state.criticalind? ind
      eqlist << boundary_equality(state,ind)
    elsif state.shiftable?
      eqlist.concat shift_inequality(state)
    end
  end
end while state = state.inc
$eqlist = eqlist

# puts "equations written"

objective = "min: #{cvar.get_name} ;"

final = feed_to_lp_solve(objective, eqlist)

File.open("out_mts_#{$n}_#{$m}.yml", "w") { |f| f.puts final.to_yaml }

