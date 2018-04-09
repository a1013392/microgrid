function [ G, h ] = mgcstr( nu, nb, n, lb, ub, l, g, x0, delta, eta )
% Define constraints on the optimisation of energy usage of a microgrid with
% with distributed energy generation and storage.  Contraints take the form of
% G*x <= h, where G is a matrix of constraint coefficients, x is the argument 
% vector, and h is a vector of constraint thresholds.

    % n = number of time intervals in control/prediction horizon
    % delta = conversion factor from power to energy
    % eta = one-way battery charge/discharge efficiency
    % lb = lower bounds on [ b; d; e; M ] where 
    %      b is battery charge rate,
    %      d is battery discharge rate, 
    %      e is state of charge (SOC) of the battery, and
    %      M is power (load, generation, imported from/ exported to the grid)
    % ub = upper bounds on [ b; d; e; M ]
    % l = vector of n load forecasts
    % g = vector of n rooftop PV generation forecasts
    % x0 = initial value of state variables [ p0; e0 ] where
    %      p0 is power imported from (+) / exported to (-) the grid, and
    %      e0 is SOC of the battery

    % Number of columns in constraint coefficient matrix (control signals plus
    % binary variables) for each time interval of control horizon
    m = nu + nb;

	% Set upper and lower bounds on battery charge rate:
    % lb(1) <= b(t+k-1) <= ub(1)
    r = 2;  % Number of rows of coefficients and thresholds required to 
            % implement constraints for each time interval
    G0 = zeros( r*n, m*n );
    h0 = zeros( r*n, 1 );
    for i = 0:n-1
        G0(i*r+1:i*r+r,i*nu+1:i*nu+nu) = [  1.0 0.0 0.0 0.0 0.0;
                                           -1.0 0.0 0.0 0.0 0.0 ];
        h0(i*r+1:i*r+r) = [ ub(1); lb(1) ];
    end
    
    % Set upper and lower bounds on battery discharge rate:
    % lb(2) <= d(t+k-1) <= ub(2)
    r = 2;
    G1 = zeros( r*n, m*n );
    h1 = zeros( r*n, 1 );
    for i = 0:n-1
        G1(i*r+1:i*r+r,i*nu+1:i*nu+nu) = [ 0.0  1.0 0.0 0.0 0.0;
                                           0.0 -1.0 0.0 0.0 0.0 ];
        h1(i*r+1:i*r+r) = [ ub(2); lb(2) ];
    end
    
    % Set upper and lower bounds on load
    % l(k) <= l(t+k-1) <= l(k)
    r = 2;
    G2 = zeros( r*n, m*n );
    h2 = zeros( r*n, 1 );
    for i = 0:n-1
        G2(i*r+1:i*r+r,i*nu+1:i*nu+nu) = [ 0.0 0.0  1.0 0.0 0.0;
                                           0.0 0.0 -1.0 0.0 0.0 ];
        h2(i*r+1:i*r+r) = [ l(i+1); -l(i+1) ];
    end
    
    % Set upper and lower bounds on rooftop PV generation
    % g(k) <= g(t+k-1) <= g(k)
    r = 2;
    G3 = zeros( r*n, m*n );
    h3 = zeros( r*n, 1 );
    for i = 0:n-1
        G3(i*r+1:i*r+r,i*nu+1:i*nu+nu) = [ 0.0 0.0 0.0  1.0 0.0 ;
                                           0.0 0.0 0.0 -1.0 0.0 ];
        h3(i*r+1:i*r+r) = [ g(i+1); -g(i+1) ];
    end
    
    % Set upper and lower bounds on power exported to the grid 
    % lb(4) <= q(t+k) <= ub(4)
    r = 2;
    G4 = zeros( r*n, m*n );
    h4 = zeros( r*n, 1 );
    for i = 0:n-1
        G4(i*r+1:i*r+r,i*nu+1:i*nu+nu) = [ 0.0 0.0 0.0 0.0  1.0 ;
                                           0.0 0.0 0.0 0.0 -1.0 ];
        h4(i*r+1:i*r+r) = [ ub(4); lb(4) ];
    end
	
    % Set upper and lower bounds on power imported from the grid 
    % lb(4) <= p(t+k) <= ub(4), where 
    % p(t+k) = b(t+k-1) - d(t+k-1) + l(t+k-1) - g(t+k-1) + q(t+k)
    r = 2;
    G5 = zeros( r*n, m*n );
    h5 = zeros( r*n, 1 );
    for i = 0:n-1
        G5(i*r+1:i*r+r,i*nu+1:i*nu+nu) = [  1.0 -1.0  1.0 -1.0  1.0 ;
                                           -1.0  1.0 -1.0  1.0 -1.0 ];
        h5(i*r+1:i*r+r) = [ ub(4); lb(4) ];
    end
    
    
	% Set upper and lower bounds on SOC of the battery
	% lb(3) <= e0 + delta*eta*b(t) - delta/eta*d(t) <= ub(3), ..., 
    % lb(3) <= e0 + delta*eta*b(t) - delta/eta*d(t) + ... +
    %          delta*eta*b(t+n-1) - delta/eta*d(t+n-1)       <= ub(3)
    r = 2;
    G6 = zeros( r*n, m*n );
    h6 = zeros( r*n, 1 );
    for i = 0:n-1
        j = 0;
        while ( j <= i )
            G6(i*r+1:i*r+r,j*nu+1:j*nu+nu) = ...
                [  delta*eta -delta/eta 0.0 0.0 0.0; 
                  -delta*eta  delta/eta 0.0 0.0 0.0 ];
            j = j + 1;
        end
        h6(i*r+1:i*r+r) = [ ub(3) - x0(2); x0(2) - lb(3)];
    end

    % Linear complementarity of battery charge and discharge control signals
    % b(t+k-1) <= ub(1) * w(2k-1)       ==> b(t+k-1) - ub(1)*w(2k-1) <= 0
    % d(t+k-1) <= ub(2) * (1 - w(2k-1)) ==> d(t+k-1) + ub(2)*w(2k-1) <= ub(2)
    r = 2;
    G7 = zeros( r*n, m*n );
    h7 = zeros( r*n, 1 );
    for i = 0:n-1
        G7(i*r+1:i*r+r,i*nu+1:i*nu+nu) = [ 1.0 0.0 0.0 0.0 0.0;
                                           0.0 1.0 0.0 0.0 0.0 ];
        G7(i*r+1:i*r+r,n*nu+i*nb+1:n*nu+i*nb+nb) = [ -ub(1) 0.0 ;
                                                      ub(2) 0.0 ];
        h7(i*r+1:i*r+r) = [ 0.0; ub(2) ];
    end
    
    % Linear complementarity of power imported from and exported to the grid
    % q(t+k) <= ub(4) * w(2k)       ==> q(t+k) - ub(4)*w(2k) <= 0
    % b(t+k-1) - d(t+k-1) + l(t+k-1) - g(t+k-1) + q(t+k) <= ub(4) * (1-w(2k))      
    % ==> b(t+k-1) - d(t+k-1) + l(t+k-1) - g(t+k-1) + q(t+k) + ub(4)*w(2k) <= ub(4)
    r = 2;
    G8 = zeros( r*n, m*n );
    h8 = zeros( r*n, 1 );
    for i = 0:n-1
        G8(i*r+1:i*r+r,i*nu+1:i*nu+nu) = [ 0.0  0.0 0.0  0.0 1.0
                                           1.0 -1.0 1.0 -1.0 1.0 ];
        G8(i*r+1:i*r+r,n*nu+i*nb+1:n*nu+i*nb+nb) = [ 0.0 -ub(4);
                                                     0.0  ub(4) ];
        h8(i*r+1:i*r+r) = [ 0.0; ub(4) ];
    end
    
    % Concatenate constraints
	G = [ G0; G1; G2; G3; G4; G5; G6; G7; G8 ];
	h = [ h0; h1; h2; h3; h4; h5; h6; h7; h8 ];

return