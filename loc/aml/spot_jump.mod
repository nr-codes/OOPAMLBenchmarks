#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Spot
#----------- parameters
# grid
param n_lo >= 0, <= N; # start of jump
param n_td >= n_lo; # end of jump

param nc = 3; # number of contact forces per foot
param mu; # friction
param mu_lin = sqrt(2) * mu / 2;

# bounds
param h_min;
param h_max;
param x_0 {X};
param x_f {X};
param x_min {X};
param x_max {X};
param a_lim {X};
param tau_lim {X};
param f_min {F};
param f_max {F};

#----------- sets
set GRID_SWING = setof {i1 in ODE_GRID: i1 >= n_lo and i1 < n_td} i1;
set GRID_STANCE = ODE_GRID diff GRID_SWING;
set GRID_STANCE_VEL = GLOBAL_GRID diff GRID_SWING;
set F_N = {i1 in F : i1 mod nc = 0};
set F_T = 1..nc - 1;

#----------- (defined) variables
var tau {i1 in Q, i2 in ODE_GRID} = Mb[i1, i2] - Jtf[i1, i2];

#----------- constraints
# state constraints
subject to X0 {i1 in X} : x[i1, 0] = x_0[i1];
subject to XF {i1 in X} : x[i1, N] = x_f[i1];

#----------- simple bounds
subject to XBNDS {i1 in X, i2 in GRID} : x_min[i1] <= x[i1, i2] <= x_max[i1];

subject to ABNDS {i1 in Q, i2 in ODE_GRID} : -a_lim[i1] <= a[i1, i2] <= a_lim[i1];

subject to FBNDS {i1 in F, i2 in ODE_GRID} : 
  f_min[i1] <= f[i1, i2] <= f_max[i1];

subject to TAUBNDS {i1 in Q, i2 in ODE_GRID} : 
  -tau_lim[i1] <= tau[i1, i2] <= tau_lim[i1];

#----------- input constraints
subject to A_RK_LCL {i2 in Q, i3 in ODE_GRID, i4 in ODE_STAGES} : 
  a[i2, next(i3, GRID, i4 - ODE_a0)] = a[i2, i3];

subject to F_RK_LCL {i2 in F, i3 in ODE_GRID, i4 in ODE_STAGES} : 
  f[i2, next(i3, GRID, i4 - ODE_a0)] = f[i2, i3];

#----------- feet do not move when on ground
subject to NO_FOOT_VELOCITY_ON_GROUND {i2 in F, i3 in GRID_STANCE_VEL} : 
  sum {i4 in Q} J[i2,i4,i3]*v[i4,i3] = 0;

#----------- no contact forces during a jump
subject to NO_FORCE_DURING_JUMPING {i1 in F, i2 in GRID_SWING} : f[i1, i2] = 0;

#----------- friction constraints
# these constraints unroll into the friction constraints of reference code
subject to FC_GROUND_1 {i1 in F_N, i2 in F_T, i3 in GRID_STANCE} : 
  -Infinity <= f[i1 - i2, i3] - mu_lin * f[i1, i3] <= 0;

subject to FC_GROUND_2 {i1 in F_N, i2 in F_T, i3 in GRID_STANCE} : 
  -Infinity <= -f[i1 - i2, i3] - mu_lin * f[i1, i3] <= 0;

subject to FC_GROUND_3 {i1 in F_N, i2 in GRID_STANCE} : -Infinity <= -f[i1, i2] <= 0;

#----------- time constraints
subject to T0 : t[0] = 0;
subject to DT {i1 in ODE_GRID} : h_min <= h[i1] <= h_max;

#----------- objective
# minimize velocity and contact forces
minimize JUMP : 3 * sum {i1 in Q, i2 in GRID} v[i1, i2]^2
  + 0.02 * sum {i1 in F, i2 in INTRMDT_GRID} f[i1, i2]^2;
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Spot!
