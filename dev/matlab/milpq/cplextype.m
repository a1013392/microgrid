function [ ctype ] = cplextype( nc, ni, nb, n )
% Returns a string identifying the type for each variable in the argument
% vector of the CPLEX solver: continuous (C), integer (I), and binary (B)

    ctype = blanks( (nc+ni+nb)*n );
    for k = 1:nc*n
        ctype(k) = 'C';
    end
    for k = 1:ni*n
        ctype(nc*n+k) = 'I';
    end
    for k = 1:nb*n
        ctype(nc*n+ni*n+k) = 'B';
    end

return

