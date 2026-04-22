#!/usr/bin/awk -f

BEGIN {
    FS = "[[:space:]]+"
    print "run,status,variables,equality_constraints,inequality_constraints,iterations," \
          "objective_unscaled,constraint_violation_unscaled,ipopt_cpu_secs,nlp_cpu_secs," \
          "python_wall,ampl_wall,solve_wall,nvars,snvars,ncons,sncons,total_wall,run_date,run_start_time"
}

# ---------- Per-file reset ----------
FNR == 1 {
    run = FILENAME
    sub(/^.*\//, "", run)
    split(run, a, "_")
    run = a[1] "_" a[2] "_" a[3] "_" a[4] "_" a[5]
    run_date = a[6]
    run_time = a[7]
    sub(/\.txt$/, "", run_time)
    vars = eq = ineq = iters = obj = viol = ipopt_time = nlp_time = ""
    python_elapsed_time = ampl_elapsed_time = solve_elapsed_time = nvars = snvars = ncons = sncons = ""
}

# ---------- Parse fields ----------
/^Total number of variables/ {
    vars = $NF
}
/^Total number of equality constraints/ {
    eq = $NF
}
/^Total number of inequality constraints/ {
    ineq = $NF
}
/^Number of Iterations/ {
    iters = $NF
}
/^Objective\.+:/ {
    obj = $NF
}
/^Constraint violation\.+:/ {
    viol = $NF
}
/^Total CPU secs in IPOPT/ {
    ipopt_time = $NF
}
/^Total CPU secs in NLP function evaluations/ {
    nlp_time = $NF
}
/^EXIT:/ {
    status = substr($0, index($0,$2))
}
/^Python3 Elapsed:/ {
    python_elapsed_time = $3
}
/^AMPL/ {
    ampl_elapsed_time = $2
}
/^SOLVE/ {
    solve_elapsed_time = $2
}
/^VARS/ {
    nvars = $2
    snvars = $3
}
/^CONS/ {
    ncons = $2
    sncons = $3
}

# ---------- End-of-file output ----------
ENDFILE {
    total_elapsed = python_elapsed_time + ampl_elapsed_time + solve_elapsed_time
    printf run "," status "," vars "," eq "," ineq "," iters "," obj "," viol "," ipopt_time "," nlp_time "," 
    printf python_elapsed_time "," ampl_elapsed_time "," solve_elapsed_time "," nvars "," snvars "," ncons "," sncons ","
    print total_elapsed "," run_date "," run_time
}
