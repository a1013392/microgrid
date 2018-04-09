%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A controller optimises energy usage of a microgrid where each constituent 
% household is equipped with rooftop solar panels and a residential battery 
% facilitating distributed power generation and energy storage.  The microgrid 
% is connected to the state-wide electricity grid by a thin gateway connection.
% Mixed integer linear programming (MILP) determines battery charge and 
% discharge control signals that minimise power imported from the grid over
% a control horizon for which rooftop PV generation and load forecasts are
% available.
%
% Author:  Silvio Tarca
% Date:    March 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
timesta = tic;  % Record start time for execution of program
 
nu = 5;     % Length of single-period control signal vector
nb = 2;     % Number of dummy variables introduced to implement process 
            % constraints for each time interval 
n = 16;     % Number of time intervals in prediction/control horizon
N = 5378;   % Number of time intervals in simulation horizon
tau = 5426; % Number of rows (time intervals) per household in data file,
            % tau >= N+n-1
hh = 75;    % Number of households in microgrid

% Set boolean variable indicating whether optimisation is performed at the
% microgrid (1 - TRUE) or household (0 - FALSE) level, and set number of 
% simulations accordingly
mgoptm = 0; 
if ( mgoptm )
    rho = 1;
else 
    rho = hh;
end

% Process outputs:
% p_i(t+k) Power imported from the grid by household i during time interval t+k,
% e_i(t+k) State of charge (SOC) of the battery of ...

% Argument u that minimises the objective function:
% b_i(t+k-1) Control signal (power) to charge battery of household i resolved
%            at time t-k-1 and applied during interval t-k
% d_i(t+k-1) Control signal (power) to discharge the battery of ...
% l_i(t+k-1) Load control signal for ...
% g_i(t+k-1) Rooftop PV generaton control signal for ...
% (Note that load and generation control signals are set to forecasts produced
% for time interval t-k)
% q_i(t+k) Power exported to the grid by household i during time interval t+k,
% w_i(2k-1) Binary variable ensuring linear complementarity of battery charge
%           and discharge control signals for household i resolved at time t-k-1
%           and applied during interval t-k
% w_i(2k) Binary variable ensuring linear complementarity of power imported from
%         and exported to the grid for household i during interval t-k

% Residential battery specifications based on Telsa Powerwall 2 DC:
% energy capacity 13.5 kWh; power 5 kW continous, 7 kW peak; depth of 
% discharge 100%; roundtrip efficiency 91.8%; warranty 10 years.
% Simulation sets energy capacity = 11.5 kWh, the mid-point assuming decay
% to 70% of its original capacity over its lifetime; DOD = 80%; round-trip
% efficiency = 88% when coupled to solar inverter
battcap = 11.5;                 % Battery energy capacity (kWh)
%battcap = 5.5;                  % Powerwall 1 DC
if ( mgoptm )
    battcap = battcap * hh;
end
socmin = 0.10 * battcap;        % Minimum SOC of the battery (kWh)
socmax = 0.90 * battcap;        % Maximum SOC of the battery (kWh)
                                % i.e., 80% DOD
e0 = (socmax + socmin ) / 2.0;  % Initial SOC of the battery (kWh)
battrt = 5.0;                   % Power charge/discharge rating (kW)
%battrt = 3.3;                   % Powerwall 1 DC
if ( mgoptm )
    battrt = battrt * hh;
end
eta = sqrt(0.88);   % One-way battery charge/discharge efficiency
delta = 0.50;       % Conversion factor from power (kW) to energy (kWh)

% Upper bound on power (load, generation, imported from /exported to grid)
% used to linearise process constraints
M = 50.0;           % (kW)
if ( mgoptm )
    M = M * hh;
end

% Define vector describing the power balance, in terms of control signals, for
% a single period:
% p(t+1) = b(t) - d(t) + l(t) - g(t) + q(t+1),
% where the coefficients of binary (dummy) variables are zero.  Observe
% that the linear objective function minimises power imported from the
% grid, where p(t+1) >= 0 and q(t+1) >= 0.  By contrast the corresponding 
% quadratic objective function (see ../miqp/mgmpc.m) minimises the square of
% power imported from or exported to the grid, where p(t+1) \in R and 
% p(t+1)^2 >= 0.
phi = [ 1.0; -1.0; 1.0; -1.0; 1.0; 0.0; 0.0 ];
% (Note that the objective function of MILP is the result of a vector operation
% of the power balance and cost coefficients)

% Set upper and lower bounds on relevant control signals and state variables:
% b_i(t+k-1), d_i(t+k-1) and e_i(t+k) for k = 1,...,n, and M
lb = [ 0.00*battrt; 0.00*battrt; socmin; 0.0 ];
ub = [ 1.00*battrt; 1.00*battrt; socmax; M ];

% Set options for MATLAB/CPLEX mixed integer linear program (MILP)
%options = cplexoptimset( 'Display', 'off', 'TolFun', 1e-12, 'TolX', 1e-12 );
% Set type (continuous, integer or binary) for each variable in argument vector 
% of CPLEX solver MILP
ctype = cplextype( nu, 0, nb, n );

% Specify simulation input and output filenames
if ( mgoptm )
    infile = sprintf( ...
'/Users/starca/projects/microgrid/dev/data/in/mg_power_mg75hh.csv' );
    outfile = sprintf( ...
'/Users/starca/projects/microgrid/dev/data/out/mg75hh_milp_16prd.csv' );
else
    infile = sprintf( ...
'/Users/starca/projects/microgrid/dev/data/in/hh_power_mg75hh.csv' );
    outfile = sprintf( ...
'/Users/starca/projects/microgrid/dev/data/out/75hh_milp_16prd.csv' );
end
% Open input and output files
infid = fopen( infile, 'r' );
outfid = fopen( outfile, 'w' );
% Write header row of output file
fprintf( outfid, ...
'#MGHH,CHRGKWH,DCHRGKWH,LOADKWH,GENPVKWH,PIMPKWH,PEXPKWH,PCOST$,PREV$,SOCCHRG,SOCDCHRG\n' );
% Define format specification of columns of input and output files
if ( mgoptm )
    infrmt = '%s %s %s %f %f %*s %f %f';
else
    infrmt = '%u %s %s %f %f %*s %f %f';
end
outfrmt = '%s %f %f %f %f %f %f %f %f %f %f\n';

for r = 1:rho
    % Read data for first household from input file and populate arrays
    M = textscan( infid, infrmt, tau, 'Delimiter', ',' );
    if ( mgoptm )
        mghh = M{1}{1};
    else
        mghh = sprintf( 'HH%.4d', M{1}(1) );
    end
 fprintf( 'MG/HH CODE: %s\n', mghh );
    dtutc = datetime( M{2} );   % Datetime -- UTC
    dtact = datetime( M{3} );   % Datetime -- Australian Central Time
    load = M{4};                % Load, kWh
    genpv = M{5};               % Solar PV power generation, kWh
    price = M{6};               % Price of energy imported from the grid ($/kWh)
    feedin = M{7};              % Feed-in tariff for energy exported to the grid ($/kWh)
    % Initialise state variables, p_i(t+k-1) and e_i(t+k-1)
    x0 = [ 0.0; e0 ];
    e = e0;
    % Initialise totals for household accumulated over simulation horizon 
    bkwh = 0.0;         % Energy supplied to charge the battery
    dkwh = 0.0;         % Energy discharged from the battery
    lkwh = 0.0;         % Energy dissipated by loads
    gkwh = 0.0;         % Energy generated by solar PV
    pkwh = 0.0;         % Energy imported from the grid
    qkwh = 0.0;         % Energy exported to the grid
    cost = 0.0;         % Cost of energy imported from the grid
    rev = 0.0;          % Revenue from energy exported to the grid
    ebkwh = 0.0;        % Change in SOC when charging the battery
    edkwh = 0.0;        % Change in SOC when discharging the battery

    % Specify filename for microgrid/household output, open file and write header
    mghhfile = sprintf( ...
'/Users/starca/projects/microgrid/dev/data/out/milp/multiprd/milp_16prd_%s.csv', mghh );
    mghhfid = fopen( mghhfile, 'w' );
    fprintf( mghhfid, ...
'#MGHH,DATEACT,TIMEACT,CHRGKW,DCHRGKW,LOADKW,GENPVKW,PIMPKW,PEXPKW,PIMP$,PEXP$,SOCKWH\n' );
    % Define format specification of columns of microgrid/household output:
    % mghh, dtact(t+k-1), b(t+k-1), d(t+k-1), l(t+k-1), g(t+k-1), p(t+k), c(t+k), e(t+k)
    mghhfrmt = '%s,%s,%f,%f,%f,%f,%f,%f,%f,%f,%f\n';
    
    for k = 1:N     % For each time interval of simulation horizon
        % Construct vectors of household data for optimisation of performance
        % index for kth time interval
        g = genpv(k:k+n-1);
        l = load(k:k+n-1);
        pi = price(k:k+n-1);
        % Define objective function for MILP. Vector phi contains coefficients
        % of control signals in the power balance equation for each time
        % interval in the prediction horizon, while vector pi contains cost
        % coefficients corresponding to time intervals in the prediction horizon
        f = mglinobj( nu, nb, phi, n, pi );
        %f = mglinobj( nu, nb, phi, n, ones(n,1) );
        % Set linear constraints for optimisation of performance index
        [ G, h ] = mgcstr( nu, nb, n, lb, ub, l, g, x0, delta, eta );
        % Optimise objective function using CPLEX mixed integer linear program
        [u, fval, exitflag, output] = cplexmilp( ...
            f, G, h, [], [], [], [], [], [], [], ctype );
        % Check for optimization errors/ warnings
        if ( exitflag < 1 )
            fprintf( 'Error: Solver terminated with exitflag = %d ', exitflag );
            fprintf( 'at time step %d of simulation.\n', k);
            return; % Exit script
        end

        % Calculate power imported from the grid and its cost
        % p(t+1) = b(t) - d(t) + l(t) - g(t) + q(t+1)
        p = u(1) - u(2) + u(3) - u(4) + u(5);
        cp = p * price(k) * delta;
        % Calculated power exported to the grid and revenue earned
        q = u(5);
        cq = q * feedin(k) * delta;
        % Update SOC of the battery
        % e(t+1) = e(t) + delta*eta*b(t) - delta/eta*d(t)
        e = x0(2) + delta*eta*u(1) - delta/eta*u(2);
        % Write microgrid output from simulation iteration to file
        fprintf( mghhfid, mghhfrmt, ...
            mghh, dtact(k), u(1), u(2), u(3), u(4), p, q, cp, cq, e );
        
        % Accumulate microgrid/household totals
        bkwh = bkwh + u(1)*delta;
        dkwh = dkwh + u(2)*delta;
        lkwh = lkwh + u(3)*delta;
        gkwh = gkwh + u(4)*delta;
        pkwh = pkwh + p*delta;
        qkwh = qkwh + q*delta;
        cost = cost + cp;
        rev = rev + cq;
        if ( e - x0(2) > 0.0 )
            ebkwh = ebkwh + (e - x0(2));
        else 
            edkwh = edkwh + (x0(2) - e);
        end

        % Reset intial state for next simulation iteration
        x0 = [ p; e ];
    end
    % Write microgrid/household totals to file
    fprintf( outfid, outfrmt, ...
        mghh, bkwh, dkwh, lkwh, gkwh, pkwh, qkwh, cost, rev, ebkwh, edkwh );
    % Close microgrid/household output file
    fclose( mghhfid );
    
end

% Close input and output files
fclose( infid );
fclose( outfid );

runtime = toc( timesta );  % Measure elapsed time for execution of program
fprintf( 'Simulation runtime: %.1f seconds\n', runtime );
