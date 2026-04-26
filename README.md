# Quickstart
* Install Docker and the docker image *francescoruscelli/horizon*: `docker pull francescoruscelli/horizon`.
* Create an AMPL account, obtain a key, and download the CLI tarball to [./docker/src/ampl.linux64.tgz](./docker/src/ampl.linux64.tgz).  Do not extract the tarball.  Keep it compressed with the filename *ampl.linux64.tgz*.
* Are you in Windows?
  * Install WSL and Ubuntu 22.04 (or other Linux variant with a bash shell).
  * Run `cloc-mecc2026.cmd` in the [loc](./loc) folder.
  * Run `docker_local_cmd.bat --key YOUR_AMPL_KEY --runs NUM_OF_RUNS` in the [docker](./docker) folder.
* Are you in Ubuntu 22.04 (or other Linux variant with a bash shell)?
  * Run `docker_local_bash.sh --key YOUR_AMPL_KEY --runs NUM_OF_RUNS` in the [docker](./docker) folder.

Then explore the output files, like *docker/ipopt_output.xlsx* which is available after a successful run.

# Overview
How do programming paradigms affect the design of robotics-focused trajectory optimization libraries (TOLs) when it comes to library features, lines of code (LOC), reproducibility, and performance?  This repository explores this question through a case study that compares two trajectory optimization libraries, one written in an object-oriented programming paradigm (OOP-TOL) and the other in a declarative programming paradigm (AML-TOL).

In particular, the repository contains the code we used to benchmark each TOL across two trajectory optimization problems: the cart-pole swing-up and Spot jump-twist optimal trajectory tasks.

The OOP-TOL is written in python and uses CasADi as a backend to compute functions and their derivatives.  The AML-TOL is written in the algebraic modeling language (AML) AMPL.  Each library generates an NLP that is then sent to IPOPT.

We benchmarked both TOLs and their dependencies inside the OOP-TOL’s Docker image. The image is installed with the OOP-TOL v0.4.5, python v3.6.9, CasADi v3.5.5, and Pinocchio v2.6.4. We copied the AML-TOL with AMPL v20250901 into a running container. CasADi and AMPL each come with their own versions of IPOPT at v3.12.3 and v3.12.13, respectively. The differences between versions are minor updates and bug fixes.

The code was developed in Windows 11 and tested in WSL's Ubuntu 22.04.5 LTS and in a native Ubuntu 24.04.4
LTS build (i.e. running on a laptop directly, not virtualized).  Because of the Windows 11 development environment, the code is a bit like the monster in Frankenstein.  A few of the parts only run in Windows (the LOC code) and the rest in a Linux OS (the performance code).

# LOC Code
The LOC code runs in a Windows command shell.  All necessary files are in the [loc](./loc) folder.  It should be straightforward to port the code to other scripting languages.

## Pre-Requisites
None

## Running the Code
In a Windows Command or Powershell, run `cloc-mecc2026.cmd` in the [loc](./loc) folder.

# Performance Code
The performance code runs in a bash shell.  We tried to only call Linux built-in shell command with the exception of Docker.  All necessary files are in the [docker](./docker) folder.

## Pre-Requisite
* Install Docker in your target OS.
  * Are you in Windows?  Then install Docker for Windows.
  * Are you in Linux/MacOS?  Then install Docker for Linux/MacOS.
* Install the OOP-TOL docker image: `docker pull francescoruscelli/horizon`.
  * Further instructions are here: https://advrhumanoids.github.io/horizon/docker.html.
* Download and place AMPL's command-line interface tarball in the [src/](./docker/src/) folder.
  * The file must be called *ampl.linux64.tgz* with path *docker/src/ampl.linux64.tgz* relative to the top-level repository directory.
  * You download the Linux tarball from the AMPL portal: https://portal.ampl.com/account/ampl/.
    * You will need an AMPL account and key from the AMPL portal.  Academic and Community Edition licenses are currently free.  Make sure to read the license restrictions.  Our code needs the ability to activate your key at least once per run.
* You may potentially also need an active Internet connection, so that AMPL can ping the mothership.  Several licenses only work as always-on DRM.
* Are you in Windows? Then install Ubuntu 22.04 in WSL.  Other Linux distros should also work, but have not been tested.

# Running the Code
* Are you in Windows? Then run `docker_local_cmd.bat --key YOUR_AMPL_KEY --runs NUM_OF_RUNS` in the [docker/](./docker) folder in a Command or Powershell.  This will launch an instance of WSL, which will then launch a Docker container.  Make sure the default WSL has a bash shell.
* Are you in Ubuntu 22.04? Then run `docker_local_bash.sh --key YOUR_AMPL_KEY --runs NUM_OF_RUNS` in the [docker/](./docker) folder in a bash shell.  This will directly launch a Docker container.
  * MacOS and other Linux distros should also work, but have not been tested.
* After the script has successfully completed, explore the output file *docker/ipopt_output.xlsx*.
  * The file is linked to any file named *ipopt_output.csv* in the same directory.  You may have to *Enable Content* in the Excel spreadsheet and/or *Refresh* the data source (*Query -> Refresh*) to see updated changes.  If the file does not exist, an empty table will result.
  * You'll probably be prompted to save the .xslx even if you didn't make any changes.  If no changes were made to the file, then it doesn't matter which option you choose.  The prompt is due to the sheet always reloading the .csv file on start up.
