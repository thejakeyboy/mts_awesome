$x = (1..20).map do |i|
  $final[Var.new('p',State.new([0,i,20]),0).to_s] - $final[Var.new('p',State.new([0,i-1,20]),0).to_s]
end