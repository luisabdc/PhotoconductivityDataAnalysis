function RlightCalculated = calculateRlight(deltaN,mob)

global s t L N Rlight Rdark e h c G depth Nmu Ntau Nsrv 
    funcInt = mob .* deltaN ;
    int = trapz(depth,funcInt');
    RlightCalculated = 1/(1/Rdark + (e.*s./L).*int);
  
end