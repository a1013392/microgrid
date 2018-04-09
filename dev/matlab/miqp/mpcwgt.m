function [ Lambda ] = mpcwgt( m, phi, n, pi )
% Defines the weighting matrix Lambda used to penalise process outputs in
% the optimisation of the performance index of state-space MPC controller.
% Vector phi contains coefficients applied to process outputs for each time 
% interval in the prediction horizon, while vector pi contains coefficients
% applied to time intervals in the prediction horizon.

    % The weighting matrix is square of dimension m process output variables
    % times n periods over the prediction horizon
    Lambda = zeros( m*n );
    for k = 0:n-1
        Lambda(k*m+1:k*m+m,k*m+1:k*m+m) = pi(k+1) * diag( phi );
    end

return

