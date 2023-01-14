OPTIONAL ASSETS for NULL
========================

1. Introduction
2. Merging Files


____________________________________________________________________________________________________
1. INTRODUCTION

This folder contains the assets for mods and features that are optional in BULL.
Each one has a readme detailing the compiler flag you need to define in your makefile
to enable the feature and how to merge in the files to your Assets folder.


____________________________________________________________________________________________________
2. MERGING FILES

Each file in the readmes has a letter code next to it telling you how to merge it
into your Assets folder.

A - Added file

  Add this new file. It will not exist in BTS, BUG, or BULL already.

R - Replaced file

  Replace the same file with the one here. If you made changes to the original BTS
  file, you will need to merge your changes into the one in BULL.

M - Modified file

  Merge the marked changes into your file. If BUG and your mod don't have this file,
  use the one from BTS. You *must* merge this file's contents into another file;
  it will not work alone.
