% Solver2 assumes diffusion of the charge carriers in the depth of the
% material as well as depth and wavelength dependence.

function deltaN=solver2(a,b,n,mob,tau)
global T k q Gwave depth
% Input: 
% a,b: two end points
% Here 0 and t.
% % % % ua, ub: Dirichlet boundary conditions at a and b
% % % % Here, since we have boundary conditions that are the first derivative,
% % % % the boundary condition inputted is n(0) = n(2), and n(n-2) = n(n), which
% % % % shows up in the coefficient matrix.
% % % % f: external function f(x) = u''(x)
% % % % Here inputting G(x) for f, since that's what the equation is equal to.
% n: number of grid points
% 
% Output
% x: x(1),x(2),...,x(n-1) are grid points
% deltaN is the approximate solutions at grid points

h = (b-a)/n; h1=h*h;
% where h is the truncation error

A = sparse(n-1,n-1);
% A is matrix of coefficients
F = zeros(n-1,1);
% F is the approximate solution using the interdependence of the three
% neighboring solution grid points

diffusion = mob .* k .* T./ q;
k1 = 1/tau;
% these are the two constants from the second-order differential equation
for i=2:n-3
    A(i,i) = (-2*diffusion/h1) - k1; A(i+1,i) = diffusion/h1; A(i,i+1)=diffusion/h1;
    % The indexing can be explained in the adjoined document.
end
% Because of boundary conditions, we have to define the following
% separately:
A(1,1) = (-2*diffusion/h1) - k1;
A(1,2)=2*diffusion/h1;A(2,1)=2*diffusion/h1;
A(n-1,n-1) = (-2*diffusion/h1) - k1;A(n-2,n-2) = (-2*diffusion/h1) - k1;
A(n-1,n-2)=2*diffusion/h1;A(n-2,n-1)=2*diffusion/h1;

% depth dependence
for i=1:n-1
    x(i) = a + i*h;
end

F = interp1(depth,Gwave,x);
% the known points are the x-coordinates depth with the associated y-values
% of Gwave (5000 points each), and we're looking for the values for points x

deltaN = A\F';
% it's the approximate function at the grid points

end