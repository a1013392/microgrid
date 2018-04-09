%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% State-space model predictive control (MPC) optimises energy usage of a 
% microgrid where each constituent household is equipped with rooftop solar 
% panels and a residential battery facilitating distributed power generation and
% energy storage.  The microgrid is connected to the state-wide electricity grid 
% by a thin gateway connection.  Mixed integer quadratic programming (MILP) 
% determines battery charge and discharge control signals that minimise power 
% imported from, or exported to, the grid over a control horizon for which 
% rooftop PV generation and load forecasts are available.
%
% Author:  Silvio Tarca
% Date:    March 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
timesta = tic;  % Record start time for execution of program

ny = 2;     % Length of single-period process output vector
nx = 2;     % Length of single-period state vector 
nu = 4;     % Length of single-period control signal vector
nb = 1;     % Number of dummy variables introduced to implement process 
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
% p_i(t+k) Power imported from, or exported to, the grid by household i during 
%          time interval t+k, where power is imported whenever p_i(t+k) > 0 and
%          power is exported whenever p_i(t+k) < 0
% e_i(t+k) State of charge (SOC) of the battery of ...

% Argument u that minimises the objective function:
% b_i(t+k-1) Control signal (power) to charge battery of household i resolved
%            at time t-k-1 and applied during interval t-k
% d_i(t+k-1) Control signal (power) to discharge the battery of ...
% l_i(t+k-1) Load control signal for ...
% g_i(t+k-1) Rooftop PV generaton control signal for ...
% (Note that load and generation control signals are fixed to forecasts produced
% for time interval t-k)
% w_i(k) Binary variable ensuring linear complementarity of battery charge
%        and discharge control signals for household i resolved at time t-k-1
%        and applied during interval t-k

% Residential battery specifications based on Telsa Powerwall 2 DC:
% energy capacity 13.5 kWh; power 5 kW continous, 7 kW peak; depth of 
% discharge 100%; roundtrip efficiency 91.8%; warranty 10 years.
% Simulation sets energy capacity = 11.5 kWh, the mid-point assuming decay
% to 70% of its original capacity over its lifetime; DOD = 80%; round-trip
% efficiency = 88% when coupled to solar inverter
battcap = 11.5;                 % Battery energy capacity (kWh)
if ( mgoptm )
    battcap = battcap * hh;
end    
socmin = 0.10 * battcap;        % Minimum SOC of the battery (kWh)
socmax = 0.90 * battcap;        % Maximum SOC of the battery (kWh)
                                % i.e., 80% DOD
e0 = (socmax + socmin ) / 2.0;  % Initial SOC of the battery (kWh)
battrt = 5.0;                   % Power charge/discharge rating (kW)
if ( mgoptm )
    battrt = battrt * hh;
end
eta = sqrt(0.88);   % One-way battery charge/discharge efficiency
delta = 0.50;       % Conversion factor from power (kW) to energy (kWh)

% Define matrices describing single-period state-space model
A = [ 0.0 0.0; 
      0.0 1.0 ];
B = [ 1.0       -1.0       1.0 -1.0;
      delta*eta -delta/eta 0.0  0.0 ];
C = [ 1.0 0.0;
      0.0 1.0 ];
% Recursively apply single-period state-space equations to generate
% matrices describing multi-period state-space model
[ K, L ] = mpckl( ny, nx, nu, nb, n, A, B, C );
% Define weighting coefficients for penalising predicted process outputs,  
% p_i(t+k) and e_i(t+k), for each time interval in the prediction horizon
phi = [ 1.0; 0.0 ];

% Set upper and lower bounds on relevant control signals and state variables:
% b_i(t+k-1), d_i(t+k-1), and e_i(t+k) for k = 1,...,n
lb = [ 0.00*battrt; 0.00*battrt; socmin ];
ub = [ 1.00*battrt; 1.00*battrt; socmax ];

% Set options for MATLAB/CPLEX mixed integer quadratic program (MIQP)
%options = cplexoptimset( 'Display', 'off', 'TolFun', 1e-12, 'TolX', 1e-12 );
% Set type (continuous, integer or binary) for each variable in argument vector
% of CPLEX solver MIQP
ctype = cplextype( nu, 0, nb, n );

% Specify simulation input and output filenames
if ( mgoptm )
    infile = sprintf( ...
'/Users/starca/projects/microgrid/dev/data/in/mg_power_mg75hh.csv' );
    outfile = sprintf( ...
'/Users/starca/projects/microgrid/dev/data/out/mg75hh_miqp_16prd.csv' );
else
    infile = sprintf( ...
'/Users/starca/projects/microgrid/dev/data/in/hh_power_mg75hh.csv' );
    outfile = sprintf( ...
'/Users/starca/projects/microgrid/dev/data/out/75hh_miqp_16prd.csv' );
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
'/Users/starca/projects/microgrid/dev/data/out/multiprd/miqp_16prd_%s.csv', mghh );
    mghhfid = fopen( mghhfile, 'w' );
    fprintf( mghhfid, ...
'#MGHH,DATEACT,TIMEACT,CHRGKW,DCHRGKW,LOADKW,GENPVKW,PGRIDKW,PGIRD$,SOCKWH\n' );
    % Define format specification of columns of microgrid/household output:
    % mghh, dtact(t+k-1), b(t+k-1), d(t+k-1), l(t+k-1), g(t+k-1), p(t+k), c(t+k), e(t+k)
    mghhfrmt = '%s,%s,%f,%f,%f,%f,%f,%f,%f\n';

    for k = 1:N     % For each time interval of simulation horizon
        % Construct vectors of household data for optimisation of performance
        % index for kth time interval
        g = genpv(k:k+n-1);
        l = load(k:k+n-1);
        pi = price(k:k+n-1);
        % Define weighting matrix for penalising predicted process outputs, 
        % p_i(t+k) and e_i(t+k) for k = 1,...,n.  Vector phi contains 
        % coefficients applied to process outputs, while vector pi contains 
        % coefficients applied to time intervals in the prediction horizon
        Lambda = mpcwgt( ny, phi, n, pi );
        % Define Hessian (quadratic term) of performance index (objective function)
        H = transpose(L)*Lambda*L;
        % Define linear term of performance index
        f = transpose(K*x0)*Lambda*L;
        % Set linear constraints for optimisation of performance index
        [ G, h ] = mgcstr( nu, nb, n, lb, ub, l, g, x0, delta, eta );
        % Optimise performance index using CPLEX mixed integer quadratic program
        [u, fval, exitflag, output] = cplexmiqp( ...
            H, f, G, h, [], [], [], [], [], [], [], ctype );
        % Check for optimization errors/ warnings
        if ( exitflag < 1 )
            fprintf( 'Error: Solver terminated with exitflag = %d ', exitflag );
            fprintf( 'at time step %d of simulation.\n', k);
            return; % Exit script
        end

        % Calculate power imported from (+), or exported to (-) the grid
        % p(t+1) = b(t) - d(t) + l(t) - g(t)
        p = u(1) - u(2) + u(3) - u(4);
        % Calculate cost of importing power or revenue from exporting power
        if ( p > 0.0 )
            c = p * price(k) * delta;
        else
            c = p * feedin(k) * delta;
        end
        % Update SOC of the battery
        % e(t+1) = e(t) + delta*eta*b(t) - delta/eta*d(t)
        e = x0(2) + delta*eta*u(1) - delta/eta*u(2);
        % Write microgrid output from simulation iteration to file
        fprintf( mghhfid, mghhfrmt, ...
            mghh, dtact(k), u(1), u(2), u(3), u(4), p, c, e );
        
        % Accumulate microgrid/household totals
        bkwh = bkwh + u(1)*delta;
        dkwh = dkwh + u(2)*delta;
        lkwh = lkwh + u(3)*delta;
        gkwh = gkwh + u(4)*delta;
        if ( p > 0.0 )
            pkwh = pkwh + p*delta;
            cost = cost + c;
        else 
            qkwh = qkwh - p*delta;
            rev = rev - c;   
        end
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
