function [ f ] = mglinobj( m, r, phi, n, pi )
% Define the objective function for MILP. Vector phi contains coefficients
% of control signals in the power balance equation and dummy variables
% introduced to implement process constriant for each time interval in 
% the prediction horizon.  Vector pi contains cost coefficients corresponding
% to time intervals in the prediction horizon.

    % The objective function is represented by a vector of length m control
    % signals plus r dummy variables times n periods over the prediction
    % horizon
    f = zeros( m*n+r*n, 1 );
    for k = 0:n-1
        f(k*m+1:k*m+m) = pi(k+1) * phi(1:m);
        f(m*n+k*r+1:m*n+k*r+r) = pi(k+1) * phi(m+1:m+r);
    end

return

