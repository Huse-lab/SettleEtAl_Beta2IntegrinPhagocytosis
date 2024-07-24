# DAAMP_Phagocytosis
Repository for code used to analyze data for Settle et al, 2024.
Within this repository are packages for analyzing imaging data to reproduce analyses presented by Settle et al in the manuscript "Beta2 Integrins Impose a Mechanical Checkpoint On Phagocytosis" for publication in...

Critical Note: This repository is strictly for the purpose of reproducing results from Settle et al 2024 (https://doi.org/10.1101/2024.02.20.580845). Some analysis parameters, such as thresholding defaults, channel identities, and meta-data parsing are specifically tailored to the experiments and analysis presented in the manuscript. For applied use to new datasets or experiments, adjustments will be required. Contact authors for assisstance if needed.  


## Contents Overview

- Widefield Phagocytosis Analysis Code
- Widefield Phagocytosis Test Data
- Phagocytic Cup Polarization Analysis Code
- Phagocytic Cup Polarization Test Data

##  Widefield Phagocytosis Analysis Instructions
Main Script: Phagocytosis_BatchProcess_v3.m

Dependencies: Contained within Functions Folder

  - bfmatlab
  - createCirclesMask
  - labelParticles.m
  - makeSampleReport.m
  - processFrame.m
MATLAB Version: Developed and tested in MATALB 2022b, not tested on future versions

Raw Data Requirements:
Analysis code is written to specifically analyze live 2D (XYCT) microscopy datasets of macrophages engulfing DAAM paritcles labeled with FITC and LRB, captured and recorded using Zeiss software Zen Blue, output as a .czi files. It relies on four captured channels in this order: DAPI, FITC, TRITC and Brightfield. It can also handle data three-channel in order: FITC, TRITC, Brightfield, in which case it will only analyze particle statistics and not count macrophages.
Multiple .czi files can be processed in series, given they are deposited in the same directory.

To Run Analysis:
- Open MATLAB (2022b) and Set Path to include all folders in this repository
- Move .czi files of interest into the working directory
- Run first section: Select Folder For Processing
  * Select directory containing the .czi files of interest
- Run second section: Initialize Settings/Parameters
  * Input the time interval (120 for experiments presented)
  * Input the interval to be analysed (For faster processing of long movies, every 10 frames were analyzed. For particle tracking, in which every frame is analyzed, input 1. For demo purposes, choose 5)
  * Input the number of channels (3 or 4)
- Run Main Loop. This will take 1 minute per sample being analyzed. It will take significantly longer for longer movies or if analyzing every frame.
  * This will generate a MATLAB struct for each movie labeled "frameStruct" with the following data for each frame analyzed
    * xDim,yDim - size of image, in pixels
    * Circles2: a list of all identified particles in the frame with their location and size
    * LabeledImage: a matrix matching the xDim x yDim image with each identified particle labeled with a unique integer
    * TimeStamp: Time stamp in seconds
    * Num_Cells: Number of cells identified in frame using DAPI channel
    * Stats: sub structure with fluoresence values of Red (LRB) and Green (FITC) intensities of each identified particle in frame.
  * This structure will be used to analyze overall phagocytic efficiency and index (as in Figure 2B,C or Supp Figure 2).  The Stats sub-structure can be mined for additional insight on individual particle statistics over time (as in Supp Fig 4C)
- Run Sample Report 
  * This creates a .png with information on the before-and-after results, used for quality control and quick inspection of results. Upper Left: first frame analyzed, each particle identified colored according to FITC/LRB ratio. Upper Right: Final frame analyzed, colored according to FITC/LRB ratio. Middle left: Histogram of each particles FITC/LRB ratio during first and final frames. Middle Right: Histogram of all analyzed frames, with identified threshold as red line.
- Generate Output Tables
  * This will generate an individual csv file for each of thhe following four calculated values:
    * NumCells - total cells identified in frame
    * TotalParticles - total number of DAAM particles identified in frame
    * Acidified Particles - Number of DAAM particles with FITC/LRB ratios below calculated threshold in frame
    * Phagocytic Efficiency - Acidified Particles divided by Total Particles
  * Phagocytic index can also be calculated as Acidified Particles / Num Cells
  * Rows in each table represent time points analyzed, each column represents a sample analyzed. For single sample analyses, there will only be one column.
