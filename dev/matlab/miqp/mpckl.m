function [ K, L ] = mpckl( m, s, q, r, n, A, B, C )
% Constructs matrices K and L defining the multi-period state-space model
% for a physical process.

    % Initialise mn-by-s matrix K (i.e., m process output variables times
    % n intervals over the prediction horizon, and s state variabes).
    K = zeros( m*n, s );
    for i = 0:n-1
        K(i*m+1:i*m+m,1:s) = C * mpower( A, i+1 );
    end
    % Initialise mn-by-(q+r)n matrix L (i.e., m process output variables
    % times n intervals over the control horizon, and q control increments
    % times n intervals plus r binary/slack variables times n intervals).
    L = zeros( m*n, (q+r)*n ); 
    for i = 0:n-1
        j = 0;
        while ( j <= i )
            L(i*m+1:i*m+m,j*q+1:j*q+q) = C * mpower( A, i-j ) * B;
            j = j + 1;
        end
    end
    
return

