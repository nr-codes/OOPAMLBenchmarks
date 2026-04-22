############################################## START LIBRARY
# Model Name: Example Robotics-Focused Trajectory Optimization Library
# Purpose: Demonstrate common OOP-based trajectory optimization library features in an AML
# Author: Nelson Rosa Jr. (nr@illinoistech.edu)
# Version: 0.1
# Last Updated: 05 April 2026

#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Grid
#----------- grid parameters:
param N integer; # number of global grid points
param K integer; # number of RK stages

#----------- create global grid points
set GLOBAL_GRID ordered by [0, N] := 0..N;
set ODE_GRID ordered by [0, N] := 0..N - 1;

#----------- create local grid points (based on RK parameters)
set ODE_K := 1..K;
param ODE_AK {ODE_K, ODE_K}; # Butcher tableau parameters
param ODE_bK {ODE_K};
param ODE_cK {ODE_K};

# helper parameters and set for creating local grid points
param ODE_a0 = if 0 = sum {i1 in ODE_K} ODE_AK[1, i1] then 1;
param ODE_aK = if 0 = sum {i1 in ODE_K} (ODE_AK[K, i1] - ODE_bK[i1]) then 1;
set ODE_STAGES := setof {i1 in ODE_K: 1 + ODE_a0 <= i1 <= K - ODE_aK} i1;

# local grid points
set LOCAL_GRID ordered by [0, N] := 
  setof {i1 in ODE_GRID, i2 in ODE_STAGES} i1 + i2 / 10;

#----------- create grid (all grid points combined)
set GRID ordered by [0, N] := GLOBAL_GRID union LOCAL_GRID;
set INTRMDT_GRID ordered by [0, N] := ODE_GRID union LOCAL_GRID;
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Grid!

#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Decision Variables
#----------- parameters for decision variables
param nq integer; # degrees of freedom
param nf integer; # number of constraints

#----------- create decision variables
set Q := 1..nq;
set F := 1..nf;

var q {Q, GRID};
var v {Q, GRID};
var a {Q, INTRMDT_GRID};
var f {F, INTRMDT_GRID};

var t {GRID};
var h {ODE_GRID};
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Decision Variables!

#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* K-Stage Runge-Kutta Method
#----------- state variables
set X = 1..2*nq;

var x {i1 in X, i2 in GRID} =
  if i1 <= nq then q[i1, i2]
  else v[i1-nq, i2];

var xdot {i1 in X, i2 in INTRMDT_GRID} =
  if i1 <= nq then v[i1, i2]
  else a[i1-nq, i2];

#----------- ODE constraints
subject to ODE_GLOB {i1 in X, i2 in ODE_GRID} : 
  x[i1, next(i2, GLOBAL_GRID)] = x[i1, i2] + h[i2] * sum {i3 in ODE_K} 
    ODE_bK[i3] * xdot[i1, next(i2, GRID, i3 - ODE_a0)];

subject to ODE_LOC {i1 in X, i2 in ODE_GRID, i3 in ODE_STAGES} :
  x[i1, next(i2, GRID, i3 - ODE_a0)] = x[i1, i2] + h[i2] * sum {i4 in ODE_K}
    ODE_AK[i3,i4] * xdot[i1, next(i2, GRID, i4 - ODE_a0)];

#----------- time constraints
subject to ODE_GLOBTIME {i1 in ODE_GRID} : 
  t[next(i1, GLOBAL_GRID)] = t[i1] + h[i1];

subject to ODE_LOCTIME {i1 in ODE_GRID, i2 in ODE_STAGES} : 
    t[next(i1, GRID, i2 - ODE_a0)] = t[i1] + h[i1] * ODE_cK[i2];

#----------- step size constraints
subject to ODE_GLOBSTEP {i1 in ODE_GRID} : 
  h[i1] = (next(i1, GLOBAL_GRID) - i1) * (t[N] - t[0]) / (N - 0);
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* K-Stage Runge-Kutta Method!

#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Robot and Robot Constraints
#----------- robot parameters
set RBT_IDX  ordered = {'PARENT', 'S_RX', 'S_RY', 'S_RZ', 'S_PX', 'S_PY', 
  'S_PZ', 'Q_LB', 'Q_UB', 'F_RX', 'F_RY', 'F_RZ', 'F_PX', 'F_PY', 'F_PZ', 
  'F_TH', 'MASS', 'M_RX', 'M_RY', 'M_RZ', 'M_PX', 'M_PY', 'M_PZ', 'M_TH', 
  'IXX', 'IYY', 'IZZ', 'IXY', 'IXZ', 'IYZ'};
param robot {Q, RBT_IDX};

set CON_IDX  ordered = {'PHASE', 'TYPE', 'ROW', 'BODY', 'R_RX', 'R_RY', 'R_RZ', 
  'R_PX', 'R_PY', 'R_PZ', 'F_RX', 'F_RY', 'F_RZ', 'F_PX', 'F_PY', 'F_PZ', 
  'F_TH', 'F_O'};
param constraint {F, CON_IDX} symbolic;

#----------- kinematic tree
# -1 = leaves to base, 0 = base to leaves, 1 = 1 to leaves
set SPAT_LINK_MBRS := {-1, 0, 1};

set SPAT_L {i1 in SPAT_LINK_MBRS} ordered :=
  if i1 = -1 then nq..0 by -1
  else i1..nq;

# P = parent, C = child, S = subtree, K = path to base
set SPAT_TREE_P {i1 in SPAT_L[0]} ordered = 
  if i1 in SPAT_L[1] then {robot[i1, 'PARENT']}
  else {};

set SPAT_TREE_C {i1 in SPAT_L[0]} ordered = 
  setof {i2 in SPAT_L[1], i3 in SPAT_TREE_P[i2]: i1 = i3} i2;

set SPAT_TREE_S {i1 in SPAT_L[-1]} ordered = 
  {i1} union (union {i2 in SPAT_TREE_C[i1]} SPAT_TREE_S[i2]);

set SPAT_TREE_K {i1 in SPAT_L[0]} ordered = 
  {i1} union (union {i2 in SPAT_TREE_P[i1]: i1 in SPAT_L[1]} SPAT_TREE_K[i2]);

#----------- robot constraints
# mapping from i to k in J[i, j] = sum J[k[i], j]
set TJ_F {i2 in F} := setof {i3 in F: constraint[i3, 'ROW'] = i2} i3;

# rigid bodies used in computation of constraints (K = along path, B = leaves)
set TJ_K ordered by [0, nq] := 
  union {i2 in F, i3 in TJ_F[i2]} SPAT_TREE_K[constraint[i3, 'BODY']];

set TJ_B := setof {i2 in F, i3 in TJ_F[i2]} constraint[i3, 'BODY'];
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Robot and Robot Constraints!

#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Spatial Quantities
#----------- spatial vector parameter and indexing set
param nm = 6; # 6D spatial vector
set SPAT_M = 1..nm; # 6D spatial quantities indexing set

#----------- spatial transforms in robot and robot constraints
# common indices into spatial transform arrays spat_expcp and spat_expcv
param x_jp := 1; # RBT_F (frame from parent of j to body j)
param x_im := nq + 1; # RBT_M (frame from center-of-mass to body i)
param x_cb := 2*nq + 1; # CON_F (frame from body b to constrained point on b)
set SPAT_EXPC := 1..nm+1; # angle-axis/exponential coordinates indexing set

#----------- constant transforms
set SPAT_XP := 1..(2 * nq + nf);

param spat_expcp {i1 in SPAT_XP, i2 in SPAT_EXPC} :=
  if x_jp <= i1 < x_im then robot[i1 - x_jp + 1, next('F_RX', RBT_IDX, i2 - 1)]
  else if x_im <= i1 < x_cb then 
    robot[i1 - x_im + 1, next('M_RX', RBT_IDX, i2 - 1)]
  else constraint[i1 - x_cb + 1, next('F_RX', CON_IDX, i2 - 1)];

# << sptrp
param Ep {i1 in SPAT_XP, i2 in SPAT_M, i3 in SPAT_M: 
  i2 <= 3 and i3 <= 3} =
  if i2 = 1 and i3 = 1 then 
    1 + (1 - cos(spat_expcp[i1, 7]))
      *(-spat_expcp[i1, 2]^2 - spat_expcp[i1, 3]^2)
  else if i2 = 1 and i3 = 2 then 
    (1 - cos(spat_expcp[i1, 7]))*spat_expcp[i1, 1]*spat_expcp[i1, 2]
      + sin(spat_expcp[i1, 7])*spat_expcp[i1, 3]
  else if i2 = 1 and i3 = 3 then 
    -(sin(spat_expcp[i1, 7])*spat_expcp[i1, 2]) + (1 - cos(spat_expcp[i1, 7]))
      *spat_expcp[i1, 1]*spat_expcp[i1, 3]
  else if i2 = 2 and i3 = 1 then 
    (1 - cos(spat_expcp[i1, 7]))*spat_expcp[i1, 1]*spat_expcp[i1, 2] 
      - sin(spat_expcp[i1, 7])*spat_expcp[i1, 3]
  else if i2 = 2 and i3 = 2 then 
    1 + (1 - cos(spat_expcp[i1, 7]))
      *(-spat_expcp[i1, 1]^2 - spat_expcp[i1, 3]^2)
  else if i2 = 2 and i3 = 3 then 
    sin(spat_expcp[i1, 7])*spat_expcp[i1, 1] + (1 - cos(spat_expcp[i1, 7]))
      *spat_expcp[i1, 2]*spat_expcp[i1, 3]
  else if i2 = 3 and i3 = 1 then 
    sin(spat_expcp[i1, 7])*spat_expcp[i1, 2] + (1 - cos(spat_expcp[i1, 7]))
     *spat_expcp[i1, 1]*spat_expcp[i1, 3]
  else if i2 = 3 and i3 = 2 then 
    -(sin(spat_expcp[i1, 7])*spat_expcp[i1, 1]) + (1 - cos(spat_expcp[i1, 7]))
      *spat_expcp[i1, 2]*spat_expcp[i1, 3]
  else if i2 = 3 and i3 = 3 then 
    1 + (1 - cos(spat_expcp[i1, 7]))
      *(-spat_expcp[i1, 1]^2 - spat_expcp[i1, 2]^2);

# px = (p) x = skew-symmetric matrix of p = (-E r) x
param ppx {i1 in SPAT_XP, i2 in SPAT_M, i3 in SPAT_M: 
  i2 <= 3 and i3 <= 3} =
  if i2 = 1 and i3 = 2 then 
    -((1 - cos(spat_expcp[i1, 7]))*(-(spat_expcp[i1, 2]*spat_expcp[i1, 4]) 
      + spat_expcp[i1, 1]*spat_expcp[i1, 5])) 
      + spat_expcp[i1, 6]*spat_expcp[i1, 7] 
      - (-(spat_expcp[i1, 1]*spat_expcp[i1, 3]*spat_expcp[i1, 4]) 
      - spat_expcp[i1, 2]*spat_expcp[i1, 3]*spat_expcp[i1, 5] 
      - (-spat_expcp[i1, 1]^2 - spat_expcp[i1, 2]^2)*spat_expcp[i1, 6])
      *(-sin(spat_expcp[i1, 7]) + spat_expcp[i1, 7])
  else if i2 = 1 and i3 = 3 then 
    (1 - cos(spat_expcp[i1, 7]))*(spat_expcp[i1, 3]*spat_expcp[i1, 4] 
      - spat_expcp[i1, 1]*spat_expcp[i1, 6]) 
      - spat_expcp[i1, 5]*spat_expcp[i1, 7] 
      + (-(spat_expcp[i1, 1]*spat_expcp[i1, 2]*spat_expcp[i1, 4]) 
      - (-spat_expcp[i1, 1]^2 - spat_expcp[i1, 3]^2)*spat_expcp[i1, 5] 
      - spat_expcp[i1, 2]*spat_expcp[i1, 3]*spat_expcp[i1, 6])
      *(-sin(spat_expcp[i1, 7]) + spat_expcp[i1, 7])
  else if i2 = 2 and i3 = 1 then 
    (1 - cos(spat_expcp[i1, 7]))*(-(spat_expcp[i1, 2]*spat_expcp[i1, 4]) 
      + spat_expcp[i1, 1]*spat_expcp[i1, 5]) 
      - spat_expcp[i1, 6]*spat_expcp[i1, 7] 
      + (-(spat_expcp[i1, 1]*spat_expcp[i1, 3]*spat_expcp[i1, 4]) 
      - spat_expcp[i1, 2]*spat_expcp[i1, 3]*spat_expcp[i1, 5] 
      - (-spat_expcp[i1, 1]^2 - spat_expcp[i1, 2]^2)
      *spat_expcp[i1, 6])*(-sin(spat_expcp[i1, 7]) + spat_expcp[i1, 7])
  else if i2 = 2 and i3 = 3 then 
    -((1 - cos(spat_expcp[i1, 7]))*(-(spat_expcp[i1, 3]*spat_expcp[i1, 5]) 
    + spat_expcp[i1, 2]*spat_expcp[i1, 6])) 
    + spat_expcp[i1, 4]*spat_expcp[i1, 7] 
    - (-((-spat_expcp[i1, 2]^2 - spat_expcp[i1, 3]^2)*spat_expcp[i1, 4]) 
    - spat_expcp[i1, 1]*spat_expcp[i1, 2]*spat_expcp[i1, 5] 
    - spat_expcp[i1, 1]*spat_expcp[i1, 3]
    *spat_expcp[i1, 6])*(-sin(spat_expcp[i1, 7]) + spat_expcp[i1, 7])
  else if i2 = 3 and i3 = 1 then 
    -((1 - cos(spat_expcp[i1, 7]))*(spat_expcp[i1, 3]*spat_expcp[i1, 4] 
    - spat_expcp[i1, 1]*spat_expcp[i1, 6])) 
    + spat_expcp[i1, 5]*spat_expcp[i1, 7] 
    - (-(spat_expcp[i1, 1]*spat_expcp[i1, 2]*spat_expcp[i1, 4]) 
    - (-spat_expcp[i1, 1]^2 - spat_expcp[i1, 3]^2)*spat_expcp[i1, 5] 
    - spat_expcp[i1, 2]*spat_expcp[i1, 3]*spat_expcp[i1, 6])
    *(-sin(spat_expcp[i1, 7]) + spat_expcp[i1, 7])
  else if i2 = 3 and i3 = 2 then 
    (1 - cos(spat_expcp[i1, 7]))*(-(spat_expcp[i1, 3]*spat_expcp[i1, 5]) 
    + spat_expcp[i1, 2]*spat_expcp[i1, 6]) 
    - spat_expcp[i1, 4]*spat_expcp[i1, 7] 
    + (-((-spat_expcp[i1, 2]^2 - spat_expcp[i1, 3]^2)*spat_expcp[i1, 4]) 
    - spat_expcp[i1, 1]*spat_expcp[i1, 2]*spat_expcp[i1, 5] 
    - spat_expcp[i1, 1]*spat_expcp[i1, 3]*spat_expcp[i1, 6])
    *(-sin(spat_expcp[i1, 7]) + spat_expcp[i1, 7]);

# p x E = skew[-E.r].E = -E.skew[r].E^T.E = -E.skew[r]
param spat_Xp {i1 in SPAT_XP, i2 in SPAT_M, i3 in SPAT_M} =
  if i2 <= 3 and i3 <= 3 then Ep[i1, i2, i3]
  else if i2 > 3 and i3 > 3 then Ep[i1, i2 - 3, i3 - 3]
  else if 3 < i2 <= 6 and i3 <= 3 then 
    sum {i4 in SPAT_M: i4 <= 3} ppx[i1, i2 - 3, i4] * Ep[i1, i4, i3];

#----------- variable transforms
set SPAT_XV := 1..nq;

param spat_expcv {i1 in SPAT_XV, i2 in SPAT_M} :=
  robot[i1, next('S_RX', RBT_IDX, i2 - 1)];

# << sptrv
var Ev {i1 in SPAT_XV, i2 in SPAT_M, i3 in SPAT_M, i4 in GLOBAL_GRID: 
  i2 <= 3 and i3 <= 3} =
  if i2 = 1 and i3 = 1 then 
    1 + (1 - cos(q[i1, i4]))*(-spat_expcv[i1, 2]^2 - spat_expcv[i1, 3]^2)
  else if i2 = 1 and i3 = 2 then 
    (1 - cos(q[i1, i4]))*spat_expcv[i1, 1]*spat_expcv[i1, 2] + sin(q[i1, i4])
      *spat_expcv[i1, 3]
  else if i2 = 1 and i3 = 3 then 
    -(sin(q[i1, i4])*spat_expcv[i1, 2]) + (1 - cos(q[i1, i4]))
      *spat_expcv[i1, 1]*spat_expcv[i1, 3]
  else if i2 = 2 and i3 = 1 then 
    (1 - cos(q[i1, i4]))*spat_expcv[i1, 1]*spat_expcv[i1, 2] - sin(q[i1, i4])
      *spat_expcv[i1, 3]
  else if i2 = 2 and i3 = 2 then 
    1 + (1 - cos(q[i1, i4]))*(-spat_expcv[i1, 1]^2 - spat_expcv[i1, 3]^2)
  else if i2 = 2 and i3 = 3 then 
    sin(q[i1, i4])*spat_expcv[i1, 1] + (1 - cos(q[i1, i4]))
      *spat_expcv[i1, 2]*spat_expcv[i1, 3]
  else if i2 = 3 and i3 = 1 then 
    sin(q[i1, i4])*spat_expcv[i1, 2] + (1 - cos(q[i1, i4]))
      *spat_expcv[i1, 1]*spat_expcv[i1, 3]
  else if i2 = 3 and i3 = 2 then 
    -(sin(q[i1, i4])*spat_expcv[i1, 1]) + (1 - cos(q[i1, i4]))
      *spat_expcv[i1, 2]*spat_expcv[i1, 3]
  else if i2 = 3 and i3 = 3 then 
    1 + (1 - cos(q[i1, i4]))*(-spat_expcv[i1, 1]^2 - spat_expcv[i1, 2]^2);

# px = (p) x = skew-symmetric matrix of p = (-E r) x
var pvx {i1 in SPAT_XV, i2 in SPAT_M, i3 in SPAT_M, i4 in GLOBAL_GRID: 
  i2 <= 3 and i3 <= 3} =
  if i2 = 1 and i3 = 2 then 
    -((1 - cos(q[i1, i4]))*(-(spat_expcv[i1, 2]*spat_expcv[i1, 4]) 
      + spat_expcv[i1, 1]*spat_expcv[i1, 5])) + spat_expcv[i1, 6]*q[i1, i4] 
      - (-(spat_expcv[i1, 1]*spat_expcv[i1, 3]*spat_expcv[i1, 4]) 
      - spat_expcv[i1, 2]*spat_expcv[i1, 3]*spat_expcv[i1, 5] 
      - (-spat_expcv[i1, 1]^2 - spat_expcv[i1, 2]^2)
      *spat_expcv[i1, 6])*(-sin(q[i1, i4]) + q[i1, i4])
  else if i2 = 1 and i3 = 3 then 
    (1 - cos(q[i1, i4]))*(spat_expcv[i1, 3]*spat_expcv[i1, 4] 
      - spat_expcv[i1, 1]*spat_expcv[i1, 6]) - spat_expcv[i1, 5]*q[i1, i4] 
      + (-(spat_expcv[i1, 1]*spat_expcv[i1, 2]*spat_expcv[i1, 4]) 
      - (-spat_expcv[i1, 1]^2 - spat_expcv[i1, 3]^2)*spat_expcv[i1, 5] 
      - spat_expcv[i1, 2]*spat_expcv[i1, 3]*spat_expcv[i1, 6])
      *(-sin(q[i1, i4]) + q[i1, i4])
  else if i2 = 2 and i3 = 1 then 
    (1 - cos(q[i1, i4]))*(-(spat_expcv[i1, 2]*spat_expcv[i1, 4]) 
      + spat_expcv[i1, 1]*spat_expcv[i1, 5]) - spat_expcv[i1, 6]*q[i1, i4] 
      + (-(spat_expcv[i1, 1]*spat_expcv[i1, 3]*spat_expcv[i1, 4]) 
      - spat_expcv[i1, 2]*spat_expcv[i1, 3]*spat_expcv[i1, 5] 
      - (-spat_expcv[i1, 1]^2 - spat_expcv[i1, 2]^2)
      *spat_expcv[i1, 6])*(-sin(q[i1, i4]) + q[i1, i4])
  else if i2 = 2 and i3 = 3 then 
    -((1 - cos(q[i1, i4]))*(-(spat_expcv[i1, 3]*spat_expcv[i1, 5]) 
      + spat_expcv[i1, 2]*spat_expcv[i1, 6])) + spat_expcv[i1, 4]*q[i1, i4] 
      - (-((-spat_expcv[i1, 2]^2 - spat_expcv[i1, 3]^2)*spat_expcv[i1, 4]) 
      - spat_expcv[i1, 1]*spat_expcv[i1, 2]*spat_expcv[i1, 5] 
      - spat_expcv[i1, 1]*spat_expcv[i1, 3]*spat_expcv[i1, 6])
      *(-sin(q[i1, i4]) + q[i1, i4])
  else if i2 = 3 and i3 = 1 then 
    -((1 - cos(q[i1, i4]))*(spat_expcv[i1, 3]*spat_expcv[i1, 4] 
    - spat_expcv[i1, 1]*spat_expcv[i1, 6])) + spat_expcv[i1, 5]*q[i1, i4] 
    - (-(spat_expcv[i1, 1]*spat_expcv[i1, 2]*spat_expcv[i1, 4]) 
    - (-spat_expcv[i1, 1]^2 - spat_expcv[i1, 3]^2)*spat_expcv[i1, 5] 
    - spat_expcv[i1, 2]*spat_expcv[i1, 3]*spat_expcv[i1, 6])
    *(-sin(q[i1, i4]) + q[i1, i4])
  else if i2 = 3 and i3 = 2 then 
    (1 - cos(q[i1, i4]))*(-(spat_expcv[i1, 3]*spat_expcv[i1, 5]) 
      + spat_expcv[i1, 2]*spat_expcv[i1, 6]) - spat_expcv[i1, 4]*q[i1, i4] 
      + (-((-spat_expcv[i1, 2]^2 - spat_expcv[i1, 3]^2)*spat_expcv[i1, 4]) 
      - spat_expcv[i1, 1]*spat_expcv[i1, 2]*spat_expcv[i1, 5] 
      - spat_expcv[i1, 1]*spat_expcv[i1, 3]*spat_expcv[i1, 6])
      *(-sin(q[i1, i4]) + q[i1, i4]);

# p x E = skew[-E.r].E = -E.skew[r].E^T.E = -E.skew[r]
var spat_Xv {i1 in SPAT_XV, i2 in SPAT_M, i3 in SPAT_M, i4 in GLOBAL_GRID} =
  if i2 <= 3 and i3 <= 3 then Ev[i1, i2, i3, i4]
  else if i2 > 3 and i3 > 3 then Ev[i1, i2 - 3, i3 - 3, i4]
  else if 3 < i2 <= 6 and i3 <= 3 then 
    sum {i5 in SPAT_M: i5 <= 3} pvx[i1, i2 - 3, i5, i4] * Ev[i1, i5, i3, i4];

#----------- parent to child spatial transform
# indices into spatial transform array spat_X_ip
param x_ij := 1; # RBT_S

var spat_X_ip {i1 in SPAT_L[1], i2 in SPAT_M, i3 in SPAT_M, 
  i4 in GLOBAL_GRID} =
  sum {i5 in SPAT_M} spat_Xv[x_ij + i1 - 1, i2, i5, i4]
    * spat_Xp[x_jp + i1 - 1, i5, i3];

#----------- spatial constraints

#----------- body i to world frame rotation
var TJ_R_0i {i2 in TJ_K, i3 in SPAT_M, i4 in SPAT_M, i5 in GLOBAL_GRID} = 
  if i2 = 0 and i3 = i4 then 1
  else sum {i6 in SPAT_TREE_P[i2], i7 in SPAT_M: 
    (i3 <= 3 and i4 <= 3) or (i3 > 3 and i4 > 3)} 
      TJ_R_0i[i6, i3, i7, i5] * spat_X_ip[i2, i4, i7, i5];

#----------- body i to constrained body b spatial transform
var TJ_X_bi {i2 in TJ_B, i3 in SPAT_TREE_K[i2], i4 in SPAT_M, 
  i5 in SPAT_M, i6 in GLOBAL_GRID} = 
    if i2 = i3 and i4 = i5 then 1 
    else if i2 > i3 then sum {i7 in SPAT_M} 
      TJ_X_bi[i2, prev(i3), i4, i7, i6] * spat_X_ip[prev(i3), i7, i5, i6];

#----------- constrained body b to body o spatial transform
# X_ob = T_cb = frame with axes aligned relative to the body
#       -or-
# X_ob = R_0b * R_bc * T_cb = frame with axes aligned 
# with {0} located at {c} relative to b; 0cb => (0c)b
# R_0b * R_bc * R_cb = R_0b, so apply simplification in computation of SO(3)
# R_0b * R_bc * (p x R_cb) = -R_0b * R_bc * R_cb * rx = -R_0b rx, need to compute
var TJ_X_ob {i2 in F, i3 in TJ_F[i2], i4 in SPAT_M, i5 in SPAT_M, 
  i6 in GLOBAL_GRID} =
    if constraint[i3, 'F_O'] = constraint[i3, 'BODY'] then 
      spat_Xp[x_cb + i3 - 1, i4, i5]
    else if i4 <= 3 and i5 <= 3 then 
      TJ_R_0i[constraint[i3, 'BODY'], i4, i5, i6]
    else if i4 > 3 and i5 > 3 then 
      TJ_R_0i[constraint[i3, 'BODY'], i4 - 3, i5 - 3, i6]
    else if i4 > 3 and i5 <= 3 then 
      sum {i7 in SPAT_M, i8 in SPAT_M: i7 <= 3 and i8 <= 3} 
        TJ_R_0i[constraint[i3, 'BODY'], i4 - 3, i7, i6] 
          * Ep[x_cb + i3 - 1, i8, i7] * spat_Xp[x_cb + i3 - 1, i8 + 3, i5];

#----------- spatial vectors
# spatial acceleration due to gravity
param spat_ag {SPAT_M};

# joints (normalized spatial twists)
param spat_s_ii {i1 in SPAT_L[1], i2 in SPAT_M} =
  robot[i1, next('S_RX', RBT_IDX, i2 - 1)];

# spatial constraints
param TJ_r_oo {i1 in F, i2 in SPAT_M} = 
  constraint[i1, next('R_RX', CON_IDX, i2 - 1)];

#----------- spatial inertial
# center-of-mass in body's center-of-mass frame
param spat_I_mm {i1 in SPAT_L[1], i2 in SPAT_M, i3 in SPAT_M} =
  if i2 = i3 and i3 > 3 then robot[i1, 'MASS']
  else if i2 = i3 and i3 <= 3 then robot[i1, next('IXX', RBT_IDX, i2 - 1)]
  else if (i2 = 1 and i3 = 2) or (i2 = 2 and i3 = 1) then robot[i1, 'IXY']
  else if (i2 = 1 and i3 = 3) or (i2 = 3 and i3 = 1) then robot[i1, 'IXZ']
  else if (i2 = 2 and i3 = 3) or (i2 = 3 and i3 = 2) then robot[i1, 'IYZ'];

# center-of-mass in body frame
param spat_I_im {i1 in SPAT_L[1], i2 in SPAT_M, i3 in SPAT_M} = 
  sum {i4 in SPAT_M, i5 in SPAT_M} spat_Xp[x_im + i1 - 1, i4, i2] 
    * spat_I_mm[i1, i4, i5] * spat_Xp[x_im + i1 - 1, i5, i3];
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Spatial Quantities!

#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Recursive Newton-Euler Algorithm
#----------- compute spatial velocities (root to leaves)
var RNEA_v {i1 in SPAT_L[0], i2 in SPAT_M, i3 in ODE_GRID} = 
  if i1 = 0 then 0 
  else spat_s_ii[i1, i2] * v[i1, i3] + 
    sum {i4 in SPAT_TREE_P[i1], i5 in SPAT_M} 
      spat_X_ip[i1, i2, i5, i3] * RNEA_v[i4, i5, i3];

#----------- convert spatial velocity into a matrix version of vector cross product
var RNEA_vx {i1 in SPAT_L[1], i2 in SPAT_M, i3 in SPAT_M, i4 in ODE_GRID} =
  if i2 = 1 and i3 = 2 then -RNEA_v[i1, 3, i4]
  else if i2 = 1 and i3 = 3 then RNEA_v[i1, 2, i4]
  else if i2 = 2 and i3 = 1 then RNEA_v[i1, 3, i4]
  else if i2 = 2 and i3 = 3 then -RNEA_v[i1, 1, i4]
  else if i2 = 3 and i3 = 1 then -RNEA_v[i1, 2, i4]
  else if i2 = 3 and i3 = 2 then RNEA_v[i1, 1, i4]
  else if i2 = 4 and i3 = 2 then -RNEA_v[i1, 6, i4]
  else if i2 = 4 and i3 = 3 then RNEA_v[i1, 5, i4]
  else if i2 = 4 and i3 = 5 then -RNEA_v[i1, 3, i4]
  else if i2 = 4 and i3 = 6 then RNEA_v[i1, 2, i4]
  else if i2 = 5 and i3 = 1 then RNEA_v[i1, 6, i4]
  else if i2 = 5 and i3 = 3 then -RNEA_v[i1, 4, i4]
  else if i2 = 5 and i3 = 4 then RNEA_v[i1, 3, i4]
  else if i2 = 5 and i3 = 6 then -RNEA_v[i1, 1, i4]
  else if i2 = 6 and i3 = 1 then -RNEA_v[i1, 5, i4]
  else if i2 = 6 and i3 = 2 then RNEA_v[i1, 4, i4]
  else if i2 = 6 and i3 = 4 then -RNEA_v[i1, 2, i4]
  else if i2 = 6 and i3 = 5 then RNEA_v[i1, 1, i4];

#----------- compute spatial accelerations (root to leaves)
var RNEA_a {i1 in SPAT_L[0], i2 in SPAT_M, i3 in ODE_GRID} = 
  if i1 = 0 then spat_ag[i2] 
  else sum {i4 in SPAT_TREE_P[i1], i5 in SPAT_M} 
      spat_X_ip[i1, i2, i5, i3] * RNEA_a[i4, i5, i3]
    + spat_s_ii[i1, i2] * a[i1, i3]
    + (sum {i5 in SPAT_M} RNEA_vx[i1, i2, i5, i3] * spat_s_ii[i1, i5])
      * v[i1, i3];

#----------- compute net spatial force acting on body b (root's children to leaves)
var RNEA_fb {i1 in SPAT_L[1], i2 in SPAT_M, i3 in ODE_GRID} = 
  sum {i5 in SPAT_M} spat_I_im[i1, i2, i5] * RNEA_a[i1, i5, i3]
  + sum {i5 in SPAT_M, i6 in SPAT_M} 
    -RNEA_vx[i1, i5, i2, i3] * spat_I_im[i1, i5, i6] * RNEA_v[i1, i6, i3];

#----------- compute transmitted force from parent to body b  (leaves to root)
var RNEA_f {i1 in SPAT_L[-1], i2 in SPAT_M, i3 in ODE_GRID: i1 > 0} = 
  RNEA_fb[i1, i2, i3] + sum {i5 in SPAT_TREE_C[i1], i6 in SPAT_M} 
    spat_X_ip[i5, i6, i2, i3] * RNEA_f[i5, i6, i3];

#----------- compute generalized force at each joint (root's children to leaves)
# Mb = M(q)a + b(q, v), assuming robot dynamics: M(q)a + b(q, v) = tau + J^T(q)f
var Mb {i1 in SPAT_L[1], i3 in ODE_GRID} = 
  sum {i2 in SPAT_M} spat_s_ii[i1, i2] * RNEA_f[i1, i2, i3];
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Recursive Newton-Euler Algorithm!

#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Task Jacobian
# compute the Task (or constrant) Jacobian s.t. 
#  RNEA_v_constrained = J(q)v = 0 <= velocity at a point is zero, and
#  tau + J^T(q)f = M(q)a + b(q, v) <= constraints forces f resist constrained motion
var J {i2 in F, i3 in SPAT_L[1], i4 in GLOBAL_GRID} = 
  sum {i5 in TJ_F[i2], i6 in SPAT_M, i7 in SPAT_M, i8 in SPAT_M : 
    i3 in SPAT_TREE_K[constraint[i5, 'BODY']]} 
      TJ_r_oo[i5, i6] * TJ_X_ob[i2, i5, i6, i7, i4] 
        * TJ_X_bi[constraint[i5, 'BODY'], i3, i7, i8, i4] * spat_s_ii[i3, i8];

var Jtf {i2 in Q, i3 in ODE_GRID} = sum {i4 in F} J[i4,i2,i3]*f[i4,i3];
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Task Jacobian!
############################################## END LIBRARY

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

subject to ABNDS {i1 in Q, i2 in ODE_GRID} : 
  -a_lim[i1] <= a[i1, i2] <= a_lim[i1];

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

subject to FC_GROUND_3 {i1 in F_N, i2 in GRID_STANCE} : 
  -Infinity <= -f[i1, i2] <= 0;

#----------- time constraints
subject to T0 : t[0] = 0;
subject to DT {i1 in ODE_GRID} : h_min <= h[i1] <= h_max;

#----------- objective
# minimize velocity and contact forces
minimize JUMP : 3 * sum {i1 in Q, i2 in GLOBAL_GRID} v[i1, i2]^2
  + 0.02 * sum {i1 in F, i2 in ODE_GRID} f[i1, i2]^2;
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#* Spot!
