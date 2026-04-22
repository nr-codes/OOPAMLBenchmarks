WORK IN PROGRESS --- We'll clean this repository up as time permits.

This repo compares two trajectory optimization libraries.  They were chosen based on their programming paradigm.  The OOP-TOL is written in an object-oriented programming paradigm.  It uses a CasADi backend to compute functions and their derivatives for use in IPOPT.  The other library, AML-TOL, is written in a declarative programming paradigm in the algebraic modeling language AMPL.

To replicate our results, you will need Docker and an AMPL key.  We also provide the .csv files that we used to report our results.

We tested the OOP-TOL at v0.4.5 in its Docker image.
The image comes installed with python v3.6.9, CasADi
v3.5.5, Pinocchio v2.6.4, and IPOPT v3.12.3. The AML-
TOL runs in AMPL v4.0.1.202411072004, which comes
installed with IPOPT v3.12.13. The differences in IPOPT
versions are minor bug fixes. We ran both TOLs inside the
Docker image. Our benchmark code is available in GitHub.
Users will need an AMPL license to run the AML-TOL,
which may be free in certain cases.
