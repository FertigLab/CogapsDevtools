# CoGAPS Developers Guide

# Table of Contents

1. [Devtools Setup](#devtools-setup)
2. [GitHub](#GitHub)
    1. [Installing Git](#installing-git)
    2. [Getting CoGAPS from GitHub](#getting-cogaps-from-github)
    3. [Installing CoGAPS from Source](#installing-cogaps-from-source)
    4. [Switching to a Different Branch](#switching-to-a-different-branch)
3. [Running CoGAPS on MARCC](#running-cogaps-on-marcc)
4. [Making Changes to CoGAPS](#making-changes-to-cogaps)
    1. [Creating Your Own Branch](#creating-your-own-branch)
    2. [Making Changes in Your Branch](#making-changes-in-your-branch)
    3. [Resolving Merge Conflicts](#resolving-merge-conflicts)
    4. [Review Process](#review-process)
    5. [Incrementing the Version](#incrementing-the-version)
5. [CoGAPS Devtools](#cogaps-devtools)
    1. [Settin up the Repository](#setting-up-the-repository)
6. [Coding Style Guide](#coding-style-guide)

# GitHub

## Installing Git

Before getting CoGAPS from GitHub you need to install Git on your computer. Try running `git --version` to see if it is already installed. If you need to install it follow the instructions [here](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

# Devtools Setup

```
git clone --recurse-submodules https://github.com/FertigLab/CoGAPS_devtools.git
cd CoGAPS_devtools/R_Package
git checkout master
cd ../Standalone_CLI
git checkout master
cd src/Rpackage
git checkout master
```

## Getting CoGAPS from GitHub

The main repository for CoGAPS is located in the FertigLab group on github [here](https://github.com/FertigLab/CoGAPS). In order to clone the repository run `git clone https://github.com/FertigLab/CoGAPS.git`. This will create a folder called `CoGAPS` that contains the package source code and data.

## Installing CoGAPS from Source

Now that you have the source code cloned, you can install it directly by running

```
R CMD build --no-build-vignettes CoGAPS
R CMD INSTALL CoGAPS_*.tar.gz
```

## Switching to a Different Branch

By default, when you clone the CoGAPS repository you will be on the `master` branch. This branch is kept in sync with the bioconductor development version. If you want to switch to a different version of CoGAPS you need to switch branches. To see what branch you are currently on use `git branch`. To switch to a different branch use `git checkout <branch-name>`, e.g. to use the internal development version of CoGAPS, run `git checkout develop` to switch to the `develop` branch and install CoGAPS from source. The `develop` branch should always been in stable condition and contains the latest changes and bug fixes.

# Running CoGAPS on MARCC

First you need to set up your environment to install R packages locally, instructions [here](https://www.marcc.jhu.edu/getting-started/local-r-packages/). Now you can follow the steps previously outlined for installing packages from source. To use `git` on Marcc run `module load git`.

## Command Line Version

When building the command line version of CoGAPS you need to link against the
boost library. The command `make configure_CLI` handles the configuration of
cogaps, but on MARCC we need to pass it the location of boost. So instead use,

```
make configure_CLI CONFIG_ARGS=--with-boost=/cm/shared/apps/boost/1.66.0/gcc/5.4/openmpi/2.1
```

If you see the lines

```
checking whether the Boost::Program_Options library is available... yes
checking for exit in -lboost_program_options... yes
``` 

Then it has been configured correctly, if you see

```
checking for boostlib >= 1.32... configure: We could not detect the boost libraries (version 1.32 or higher). If you have a staged boost library (still not installed) please specify $BOOST_ROOT in your environment and do not give a PATH to --with-boost option.  If you are sure you have boost installed, then check your version number looking in <boost/version.hpp>. See http://randspringer.de/boost for more documentation.
```

That means that the configure script can't find the boost libraries and
something has gone wrong.

Once cogaps is configured correctly, run `make build_CLI` to create the program
`cogaps` located in the `CLI_build` folder.

In order to run `cogaps` we need to make sure it can find the boost libraries
at runtime. This is done with the command,

```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/cm/shared/apps/boost/1.66.0/gcc/5.4/openmpi/2.1/lib
```

If you don't want to type this every session, add that line to the bottom of your
`~/.bashrc` file and it will run every time you login.

Run `make example_CLI` to see if it has installed correctly.

# Making Changes to CoGAPS

## Creating Your Own Branch

Before making a change to CoGAPS, you must set up a separate branch to track your changes. Once your changes are completed then you can open a pull request on github to merge your branch. Any changes should be based off of the develop branch.

To create a new branch and push it to github:

```
git checkout develop
git checkout -b <your-branch-name>
git push origin <your-branch-name>
```

## Making Changes in Your Branch

Use `git branch` to ensure you are in the correct branch. After making changes to your code use `git status` to see what files have been changed. If you want to commit those changes to your branch use `git add -A` and `git commit -m "<your-message>"`. Now if you use `git status` you will see that your local branch is ahead of the remote branch (github). If you want to sync your local changes with github, first make sure (using `git status`) that all recent changes have been committed, then use `git pull origin <your-branch-name>` to update your local branch with any changes others have made. If no conflicts are present you are free to push your changes to github with `git push origin <your-branch-name>`.

## Resolving Merge Conflicts

If your changes conflict with any changes other have made, then you need to resolve the conflicts in each file and commit the resolution. Git should prompt you with all the file names that have conflicts. Open each one up in a text editor and search for areas like:

```
non-conflicting code
<<<<<<< HEAD
"HEAD" version of conflicting code
=======
"some-branch-name" version of conflicting code
>>>>>>> some-branch-name
```

Resolve the conflict by keeping changes from one branch or another, or possibly writing your own merged solution. Once this is done, commit your merged changes with `git add -A` and `git commit -m "<commit-message>"` just as before. You can now run `git push origin <your-branch-name>`.

## Review Process

Once your branch is ready to be merged back into develop, follow these steps for verifying the branch is in good shape.

1) Open Pull Request on GitHub (developer)
2) Verify branch is passing TravisCI (developer)
3) Run complete package checks on MARCC (reviewer)
4) Comments about results and code (reviewer)
5) Commit fixes (developer)
6) Merge Pull Request (reviewer)

**1) Open Pull Request on GitHub**

The first step to merge your branch back into develop is to open a pull request. Go to **https://github.com/FertigLab/CoGAPS/tree/your-branch-name** to see the homepage for your branch. Select "New Pull Request" next to the branch drop down menu (top left). Make sure the base branch is set to `develop`. From here add any initial comments and select "Create Pull Request". This will create a page for your branch under "Pull Requests".

**2) Verify branch is passing TravisCI**

In the Pull Request page for your branch, you should see the result of our automatic package checks. If any of them have failed, click on the status message to see the cause of failure. Before moving on with the review, these checks need to be passing since they reflect the checks that BioConductor runs to see if CoGAPS is fit to stay on the repository.

**6) Commit fixes**
To commit any fixes regarding the Pull Request feedback or to get the package tests passing, simply commit your changes to the branch as normal. The Pull Request page will automatically detect any new changes to the branch and re-run the tests.

## Incrementing the version

The last step after a change has been made is to increment the package version,
here's a checklist of the things that need to be done:

1) change version number and date in DESCRIPTION
2) change version number in README
3) update Changelog with a description about the new version
4) (optional - not critical) rebuild configure script to pull in new version

# CoGAPS Devtools

The devtools repository (FertigLab/CoGAPS_devtools) contains various tools for checking, benchmarking, profiling, etc. that are helpful when developing CoGAPS. Most of these tools are accessed from the top level Makefile, i.e. `make install` will build the package and install it, `make check` will run `R CMD check` and `R CMD BiocCheck` on the pacage, for a full list of Makefile commands use `make help`.

## Setting up the repository

```
git clone https://github.com/FertigLab/CoGAPS_devtools.git
mv CoGAPS_devtools CoGAPS
cd CoGAPS
git clone https://github.com/FertigLab/CoGAPS.git
mv CoGAPS Repo
```

This creates a top-level directory `CoGAPS` with all the development tools and a sub-directory `Repo` the contains the package repository. This configuration is expected for the tools to work.

# Coding Style Guide

