#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Cart-Pole
#----------- parameters
param tf;
param x_0 {X};
param x_f {i1 in X: i1 > 1}; # ignore horizontal direction
param x_min {X};
param x_max {X};
param a_lim {X};
param tau_lim {X};

#----------- (defined) variables
var tau {i1 in Q, i2 in ODE_GRID} = Mb[i1, i2] - Jtf[i1, i2];

#----------- constraints
# state constraints
subject to X0 {i1 in X} : x[i1, 0] = x_0[i1];
subject to XF {i1 in X: i1 > 1} : x[i1, N] = x_f[i1];

#----------- simple bounds
subject to XBNDS {i1 in X, i2 in GLOBAL_GRID} : x_min[i1] <= x[i1, i2] <= x_max[i1];

subject to ABNDS {i1 in Q, i2 in ODE_GRID} :
  -a_lim[i1] <= a[i1, i2] <= a_lim[i1];

subject to TAUBNDS {i1 in Q, i2 in ODE_GRID} :
  -tau_lim[i1] <= tau[i1, i2] <= tau_lim[i1];

#----------- input constraints
subject to A_RK_LCL {i2 in Q, i3 in ODE_GRID, i4 in ODE_STAGES} : 
  a[i2, next(i3, GRID, i4 - ODE_a0)] = a[i2, i3];

#----------- time constraints
subject to T0 : t[0] = 0;
subject to TF : t[N] = tf;

#----------- objective
minimize SWING_UP : sum {i1 in Q, i2 in ODE_GRID} a[i1, i2]^2;
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Cart-Pole!
