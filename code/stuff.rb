$x = (-20..20).map do |i|
  $final[Var.new('phi',State.new([i,0,0])).to_s]
end