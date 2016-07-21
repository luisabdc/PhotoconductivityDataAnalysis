% Solver1 assumes depth-dependence and wavelength dependence for the generation 
% rate. Since G has been previously calculated in main as wavelength and
% depth dependent, it's a simple multiplication to get deltaN.
%deltaN in terms of depth, so a vector
function deltaN=solver1(tau)

global Gwave 

deltaN=Gwave' .* tau;

end
